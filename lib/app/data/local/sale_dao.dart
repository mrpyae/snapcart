import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/sale_order_model.dart';
import '../models/item_price_history_model.dart';
import 'db_helper.dart';

class SaleDao {
  final dbHelper = DBHelper.instance;

  Future<void> saveSaleOrder(SaleOrderModel order) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 1. Insert Sales Order header
      await txn.insert(
        'sales_orders',
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Insert items and reduce product stock
      for (var item in order.items) {
        await txn.insert(
          'sales_order_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.rawUpdate(
          'UPDATE products SET stock_qty = stock_qty - ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
          [item.quantity, item.productId],
        );
      }

      // 3. Update customer debt if credit sale (also mark as unsynced so it's pushed to server)
      if (order.customerId != null && order.dueAmount > 0) {
        await txn.rawUpdate(
          'UPDATE customers SET current_debt = current_debt + ?, sync_status = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
          [order.dueAmount, order.customerId],
        );
      }

      // 4. Update delivery service COD receivable if COD delivery
      if (order.isCod && order.deliveryServiceId != null && order.codAmount > 0) {
        await txn.rawUpdate(
          'UPDATE delivery_services SET receivable_balance = receivable_balance + ?, sync_status = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
          [order.codAmount, order.deliveryServiceId],
        );
      }
    });
  }

  /// Get a single sale order with its items by ID
  Future<SaleOrderModel?> getSaleOrderById(String orderId) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'sales_orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );
    if (res.isEmpty) return null;
    final itemsRes = await db.query(
      'sales_order_items',
      where: 'sale_order_id = ?',
      whereArgs: [orderId],
    );
    final items = itemsRes.map((i) => SaleOrderItemModel.fromJson(i)).toList();
    return SaleOrderModel.fromJson(res.first, items: items);
  }

  /// Void/Delete a sale order: restores product stock, reverses customer credit debt, and reverses courier COD
  Future<void> deleteSaleOrder(String orderId) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 1. Fetch order header
      final orderRows = await txn.query(
        'sales_orders',
        where: 'id = ?',
        whereArgs: [orderId],
        limit: 1,
      );
      if (orderRows.isEmpty) return;
      final orderRow = orderRows.first;

      // 2. Fetch order items
      final itemRows = await txn.query(
        'sales_order_items',
        where: 'sale_order_id = ?',
        whereArgs: [orderId],
      );

      // 3. Reverse product stock (add item quantities back to inventory)
      for (var item in itemRows) {
        final double qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
        final productId = item['product_id']?.toString();
        if (productId != null && qty > 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock_qty = stock_qty + ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [qty, productId],
          );
        }
      }

      // 4. Reverse customer debt if credit sale was involved
      final customerId = orderRow['customer_id']?.toString();
      final double dueAmount = double.tryParse(orderRow['due_amount']?.toString() ?? '0') ?? 0.0;
      if (customerId != null && customerId.isNotEmpty && dueAmount > 0) {
        await txn.rawUpdate(
          'UPDATE customers SET current_debt = MAX(0.0, current_debt - ?), sync_status = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
          [dueAmount, customerId],
        );
      }

      // 5. Reverse delivery service COD receivable if COD delivery was involved
      final int isCod = int.tryParse(orderRow['is_cod']?.toString() ?? '0') ?? 0;
      final deliveryServiceId = orderRow['delivery_service_id']?.toString();
      final double codAmount = double.tryParse(orderRow['cod_amount']?.toString() ?? '0') ?? 0.0;
      if (isCod == 1 && deliveryServiceId != null && deliveryServiceId.isNotEmpty && codAmount > 0) {
        await txn.rawUpdate(
          'UPDATE delivery_services SET receivable_balance = MAX(0.0, receivable_balance - ?), sync_status = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
          [codAmount, deliveryServiceId],
        );
      }

      // 6. Delete order items and header
      await txn.delete(
        'sales_order_items',
        where: 'sale_order_id = ?',
        whereArgs: [orderId],
      );
      await txn.delete(
        'sales_orders',
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }

  /// Update an existing sale order header (payment method, customer, paid amount, due amount, notes)
  Future<void> updateSaleOrderHeader({
    required String orderId,
    required String paymentMethod,
    required double paidAmount,
    required double dueAmount,
    required String saleStatus,
    String? customerId,
    String? notes,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final existingRows = await txn.query('sales_orders', where: 'id = ?', whereArgs: [orderId], limit: 1);
      if (existingRows.isEmpty) return;
      final existing = existingRows.first;

      final oldCustomerId = existing['customer_id']?.toString();
      final double oldDue = double.tryParse(existing['due_amount']?.toString() ?? '0') ?? 0.0;

      // Reconcile customer debt
      if (oldCustomerId != null && oldCustomerId.isNotEmpty && oldDue > 0) {
        await txn.rawUpdate(
          'UPDATE customers SET current_debt = MAX(0.0, current_debt - ?), sync_status = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
          [oldDue, oldCustomerId],
        );
      }
      if (customerId != null && customerId.isNotEmpty && dueAmount > 0) {
        await txn.rawUpdate(
          'UPDATE customers SET current_debt = current_debt + ?, sync_status = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
          [dueAmount, customerId],
        );
      }

      await txn.update(
        'sales_orders',
        {
          'payment_method': paymentMethod,
          'paid_amount': paidAmount,
          'due_amount': dueAmount,
          'sale_status': saleStatus,
          'customer_id': customerId,
          'notes': notes,
          'sync_status': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }

  Future<List<SaleOrderModel>> getDailySales({required String date, String businessId = 'default_biz'}) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'sales_orders',
      where: 'business_id = ? AND sale_date LIKE ?',
      whereArgs: [businessId, '$date%'],
      orderBy: 'sale_date DESC',
    );

    List<SaleOrderModel> orders = [];
    for (var r in res) {
      final itemsRes = await db.query(
        'sales_order_items',
        where: 'sale_order_id = ?',
        whereArgs: [r['id']],
      );
      final items = itemsRes.map((i) => SaleOrderItemModel.fromJson(i)).toList();
      orders.add(SaleOrderModel.fromJson(r, items: items));
    }
    return orders;
  }

  Future<List<SaleOrderModel>> getFilteredSales({
    DateTime? startDate,
    DateTime? endDate,
    String? query,
    String? paymentMethod,
    String? saleStatus,
    String businessId = 'default_biz',
  }) async {
    final db = await dbHelper.database;
    final isDefault = businessId == 'default_biz' || businessId.isEmpty;
    String sql = '''
      SELECT s.*, c.name as customer_name, c.phone as customer_phone
      FROM sales_orders s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE (s.business_id = ? ${isDefault ? "OR s.business_id IS NULL OR s.business_id = ''" : ""})
    ''';
    List<dynamic> args = [businessId];

    if (startDate != null) {
      final startStr = startDate.toIso8601String().substring(0, 10);
      sql += ' AND SUBSTR(s.sale_date, 1, 10) >= ?';
      args.add(startStr);
    }

    if (endDate != null) {
      final endStr = endDate.toIso8601String().substring(0, 10);
      sql += ' AND SUBSTR(s.sale_date, 1, 10) <= ?';
      args.add(endStr);
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      sql += ' AND (s.voucher_no LIKE ? OR c.name LIKE ? OR c.phone LIKE ? OR s.user_name LIKE ?)';
      args.addAll([q, q, q, q]);
    }

    if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod != 'ALL') {
      sql += ' AND s.payment_method = ?';
      args.add(paymentMethod);
    }

    if (saleStatus != null && saleStatus.isNotEmpty && saleStatus != 'ALL') {
      sql += ' AND s.sale_status = ?';
      args.add(saleStatus);
    }

    sql += ' ORDER BY s.sale_date DESC';

    final res = await db.rawQuery(sql, args);
    List<SaleOrderModel> orders = [];
    for (var r in res) {
      final orderId = r['id'].toString();
      final itemsRes = await db.query(
        'sales_order_items',
        where: 'sale_order_id = ?',
        whereArgs: [orderId],
      );
      final items = itemsRes.map((i) => SaleOrderItemModel.fromJson(i)).toList();
      orders.add(SaleOrderModel.fromJson(r, items: items));
    }
    return orders;
  }

  /// Retrieve item price history with optional customer filtering, date range, and urgent limit (default 10)
  Future<List<ItemPriceHistoryModel>> getProductPriceHistory({
    required String productId,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
    String businessId = 'default_biz',
  }) async {
    final db = await dbHelper.database;
    final isDefault = businessId == 'default_biz' || businessId.isEmpty;

    String sql = '''
      SELECT 
        soi.id,
        soi.product_id,
        soi.product_name,
        soi.price as unit_price,
        soi.quantity,
        soi.unit,
        soi.total,
        so.id as sale_order_id,
        so.voucher_no,
        so.sale_date,
        so.payment_method,
        so.customer_id,
        COALESCE(c.name, 'Walk-in Customer') as customer_name,
        COALESCE(c.phone, '') as customer_phone,
        'POS_SALE' as source_type
      FROM sales_order_items soi
      INNER JOIN sales_orders so ON soi.sale_order_id = so.id
      LEFT JOIN customers c ON so.customer_id = c.id
      WHERE soi.product_id = ? 
        AND (so.business_id = ? ${isDefault ? "OR so.business_id IS NULL OR so.business_id = ''" : ""})
    ''';
    List<dynamic> args = [productId, businessId];

    if (customerId != null && customerId.isNotEmpty && customerId != 'ALL') {
      sql += ' AND so.customer_id = ?';
      args.add(customerId);
    }

    if (startDate != null) {
      final startStr = startDate.toIso8601String().substring(0, 10);
      sql += ' AND SUBSTR(so.sale_date, 1, 10) >= ?';
      args.add(startStr);
    }

    if (endDate != null) {
      final endStr = endDate.toIso8601String().substring(0, 10);
      sql += ' AND SUBSTR(so.sale_date, 1, 10) <= ?';
      args.add(endStr);
    }

    sql += ' ORDER BY so.sale_date DESC, soi.created_at DESC';

    if (limit > 0) {
      sql += ' LIMIT ?';
      args.add(limit);
    }

    final res = await db.rawQuery(sql, args);
    return res.map((r) => ItemPriceHistoryModel.fromMap(r)).toList();
  }

  /// Quickly retrieve the latest selling price of a product for a specific customer
  Future<double?> getLastPriceForCustomer({
    required String productId,
    required String customerId,
    String businessId = 'default_biz',
  }) async {
    final history = await getProductPriceHistory(
      productId: productId,
      customerId: customerId,
      limit: 1,
      businessId: businessId,
    );
    if (history.isNotEmpty) {
      return history.first.unitPrice;
    }
    return null;
  }
}

