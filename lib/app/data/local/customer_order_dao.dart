import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/customer_order_model.dart';
import 'db_helper.dart';

class CustomerOrderDao {
  final dbHelper = DBHelper.instance;

  Future<void> saveCustomerOrder(CustomerOrderModel order) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        'customer_orders',
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Replace existing items
      await txn.delete('customer_order_items', where: 'customer_order_id = ?', whereArgs: [order.id]);

      for (var item in order.items) {
        await txn.insert(
          'customer_order_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> batchSaveCustomerOrders(List<dynamic> orders) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    for (var o in orders) {
      final orderMap = Map<String, dynamic>.from(o as Map);
      final rawItems = orderMap['items'];

      // Remove items array from header map for table insertion
      final headerMap = Map<String, dynamic>.from(orderMap);
      headerMap.remove('items');
      headerMap['sync_status'] = 1;

      batch.insert(
        'customer_orders',
        headerMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (rawItems != null && rawItems is List) {
        for (var item in rawItems) {
          final itemMap = Map<String, dynamic>.from(item as Map);
          itemMap['customer_order_id'] = headerMap['id'];
          itemMap['sync_status'] = 1;
          batch.insert(
            'customer_order_items',
            itemMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    }

    await batch.commit(noResult: true);
  }


  Future<List<CustomerOrderModel>> getCustomerOrders({
    String? status,
    String? orderSource,
    String? query,
    String? supplierId,
    DateTime? appointmentDate,
    String? businessId,
  }) async {
    final db = await dbHelper.database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (businessId != null && businessId.isNotEmpty && businessId != 'default_biz') {
      whereClause += ' AND (business_id = ? OR business_id = "default_biz")';
      whereArgs.add(businessId);
    }

    if (status != null && status.isNotEmpty && status != 'ALL') {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    if (orderSource != null && orderSource.isNotEmpty && orderSource != 'ALL') {
      whereClause += ' AND order_source = ?';
      whereArgs.add(orderSource);
    }

    if (supplierId != null && supplierId.isNotEmpty && supplierId != 'ALL') {
      whereClause += ' AND (supplier_id = ? OR id IN (SELECT customer_order_id FROM customer_order_items WHERE supplier_id = ?))';
      whereArgs.add(supplierId);
      whereArgs.add(supplierId);
    }

    if (query != null && query.isNotEmpty) {
      whereClause += ' AND (customer_name LIKE ? OR customer_phone LIKE ? OR order_no LIKE ? OR lead_account LIKE ? OR supplier_name LIKE ?)';
      final q = '%$query%';
      whereArgs.addAll([q, q, q, q, q]);
    }

    if (appointmentDate != null) {
      final dateStr = appointmentDate.toIso8601String().substring(0, 10);
      whereClause += ' AND appointment_date LIKE ?';
      whereArgs.add('$dateStr%');
    }

    final orderRows = await db.query(
      'customer_orders',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    List<CustomerOrderModel> result = [];
    for (var row in orderRows) {
      final orderId = row['id'].toString();
      final itemRows = await db.query('customer_order_items', where: 'customer_order_id = ?', whereArgs: [orderId]);
      final items = itemRows.map((i) => CustomerOrderItemModel.fromJson(i)).toList();
      result.add(CustomerOrderModel.fromJson(row, items: items));
    }

    return result;
  }

  Future<CustomerOrderModel?> getCustomerOrderById(String id) async {
    final db = await dbHelper.database;
    final orderRows = await db.query('customer_orders', where: 'id = ?', whereArgs: [id], limit: 1);
    if (orderRows.isEmpty) return null;

    final itemRows = await db.query('customer_order_items', where: 'customer_order_id = ?', whereArgs: [id]);
    final items = itemRows.map((i) => CustomerOrderItemModel.fromJson(i)).toList();
    return CustomerOrderModel.fromJson(orderRows.first, items: items);
  }

  Future<void> updateOrderStatus(String id, String newStatus) async {
    final db = await dbHelper.database;
    await db.update(
      'customer_orders',
      {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> rescheduleAppointment(String id, String newAppointmentDate, {String? appointmentType}) async {
    final db = await dbHelper.database;
    final Map<String, dynamic> updates = {
      'appointment_date': newAppointmentDate,
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 0,
    };
    if (appointmentType != null) {
      updates['appointment_type'] = appointmentType;
    }
    await db.update(
      'customer_orders',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> recordOrderPayment(
    String orderId,
    double paymentAmount, {
    String paymentMethod = 'cash',
    bool markCompleted = false,
    String deliveryType = 'SELF_COLLECT',
    String? deliveryServiceId,
    String? deliveryServiceName,
    double deliveryFee = 0.0,
    double riderCommissionAmount = 0.0,
    bool isCod = false,
    double codAmount = 0.0,
  }) async {
    final db = await dbHelper.database;
    final order = await getCustomerOrderById(orderId);
    if (order == null) return;

    final newAdvance = order.advanceAmount + paymentAmount;
    final newDue = (order.totalAmount - newAdvance).clamp(0.0, double.infinity);
    final updates = <String, dynamic>{
      'advance_amount': newAdvance,
      'due_amount': newDue,
      'payment_method': paymentMethod,
      'delivery_type': deliveryType,
      'delivery_fee': deliveryFee,
      'rider_commission_amount': riderCommissionAmount,
      'is_cod': isCod ? 1 : 0,
      'cod_amount': codAmount,
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 0,
    };
    if (deliveryServiceId != null) updates['delivery_service_id'] = deliveryServiceId;
    if (deliveryServiceName != null) updates['delivery_service_name'] = deliveryServiceName;
    if (deliveryType == 'DELIVERY') {
      updates['delivery_status'] = 'PENDING';
      updates['cod_settlement_status'] = isCod ? 'PENDING' : 'N/A';
    }

    if (markCompleted || newDue <= 0.0) {
      updates['status'] = 'COMPLETED';
    }

    await db.update(
      'customer_orders',
      updates,
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> deleteCustomerOrder(String id) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('customer_order_items', where: 'customer_order_id = ?', whereArgs: [id]);
      await txn.delete('customer_orders', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Retrieve all customer orders that contain a specific product
  Future<List<CustomerOrderModel>> getOrdersForProduct(
    String productId, {
    bool activeOnly = true,
    String? businessId,
  }) async {
    final db = await dbHelper.database;
    String sql = '''
      SELECT DISTINCT co.*
      FROM customer_orders co
      INNER JOIN customer_order_items coi ON coi.customer_order_id = co.id
      WHERE coi.product_id = ?
    ''';
    List<dynamic> args = [productId];

    if (businessId != null && businessId.isNotEmpty && businessId != 'default_biz') {
      sql += ' AND (co.business_id = ? OR co.business_id = "default_biz")';
      args.add(businessId);
    }

    if (activeOnly) {
      sql += " AND co.status NOT IN ('COMPLETED', 'CANCELLED')";
    }

    sql += ' ORDER BY co.created_at DESC';

    final orderRows = await db.rawQuery(sql, args);
    List<CustomerOrderModel> result = [];
    for (var row in orderRows) {
      final orderId = row['id'].toString();
      final itemRows = await db.query(
        'customer_order_items',
        where: 'customer_order_id = ?',
        whereArgs: [orderId],
      );
      final items = itemRows.map((i) => CustomerOrderItemModel.fromJson(i)).toList();
      result.add(CustomerOrderModel.fromJson(row, items: items));
    }
    return result;
  }

  /// Get aggregated order summary for a product (active order count, total reserved qty, total pending amount)
  Future<Map<String, dynamic>> getProductOrderSummary(
    String productId, {
    String? businessId,
  }) async {
    final activeOrders = await getOrdersForProduct(productId, activeOnly: true, businessId: businessId);
    double totalReservedQty = 0.0;
    double totalPendingAmount = 0.0;

    for (final order in activeOrders) {
      for (final item in order.items) {
        if (item.productId == productId) {
          totalReservedQty += item.quantity;
          totalPendingAmount += item.subtotal;
        }
      }
    }

    return {
      'activeOrderCount': activeOrders.length,
      'totalReservedQty': totalReservedQty,
      'totalPendingAmount': totalPendingAmount,
      'orders': activeOrders,
    };
  }

  /// Get pending customer orders & appointments waiting for a list of products
  Future<Map<String, List<Map<String, dynamic>>>> getPendingCustomerOrdersForProducts(
    List<String> productIds, {
    String? businessId,
  }) async {
    if (productIds.isEmpty) return {};
    final db = await dbHelper.database;
    final placeholders = List.filled(productIds.length, '?').join(',');

    String sql = '''
      SELECT 
        co.id as order_id,
        co.order_no,
        co.customer_name,
        co.customer_phone,
        co.order_source,
        co.appointment_date,
        co.appointment_type,
        co.status as order_status,
        co.supplier_id,
        co.supplier_name,
        coi.product_id,
        coi.item_name,
        coi.quantity,
        coi.unit,
        coi.unit_price,
        coi.subtotal
      FROM customer_order_items coi
      INNER JOIN customer_orders co ON co.id = coi.customer_order_id
      WHERE coi.product_id IN ($placeholders)
        AND co.status NOT IN ('COMPLETED', 'CANCELLED')
    ''';
    List<dynamic> args = [...productIds];

    if (businessId != null && businessId.isNotEmpty && businessId != 'default_biz') {
      sql += ' AND (co.business_id = ? OR co.business_id = "default_biz")';
      args.add(businessId);
    }

    sql += ' ORDER BY co.created_at DESC';

    final rows = await db.rawQuery(sql, args);
    final Map<String, List<Map<String, dynamic>>> map = {};

    for (final pId in productIds) {
      map[pId] = [];
    }

    for (final r in rows) {
      final pId = r['product_id']?.toString() ?? '';
      if (map.containsKey(pId)) {
        map[pId]!.add(Map<String, dynamic>.from(r));
      }
    }

    return map;
  }
}

