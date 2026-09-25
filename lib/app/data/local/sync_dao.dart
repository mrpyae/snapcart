import 'db_helper.dart';

class SyncDao {
  final dbHelper = DBHelper.instance;

  // Get all pending records to push to server
  Future<Map<String, dynamic>> getPendingPushPayload({String businessId = 'default_biz'}) async {
    final db = await dbHelper.database;

    // 1. Pending Sales
    final salesRes = await db.query('sales_orders', where: 'sync_status = 0');
    List<Map<String, dynamic>> pendingSales = [];
    for (var s in salesRes) {
      final items = await db.query('sales_order_items', where: 'sale_order_id = ?', whereArgs: [s['id']]);
      var saleMap = Map<String, dynamic>.from(s);
      saleMap['items'] = items;
      pendingSales.add(saleMap);
    }

    // 2. Pending Customers
    final pendingCustomers = await db.query('customers', where: 'sync_status = 0');

    // 3. Pending Products
    final pendingProducts = await db.query('products', where: 'sync_status = 0');

    // 4. Pending Debt Repayments
    final pendingRepayments = await db.query('debt_repayments', where: 'sync_status = 0');

    // 5. Pending Expenses
    final pendingExpenses = await db.query('expenses', where: 'sync_status = 0');

    // 6. Pending Categories
    final pendingCategories = await db.query('categories', where: 'sync_status = 0');

    // 6b. Pending Supplier Categories
    final pendingSupplierCategories = await db.query('supplier_categories', where: 'sync_status = 0');

    // 7. Pending Suppliers
    final pendingSuppliers = await db.query('suppliers', where: 'sync_status = 0');

    // 8. Pending Purchases
    final purchasesRes = await db.query('purchases', where: 'sync_status = 0');
    List<Map<String, dynamic>> pendingPurchases = [];
    for (var p in purchasesRes) {
      final items = await db.query('purchase_items', where: 'purchase_id = ?', whereArgs: [p['id']]);
      var pMap = Map<String, dynamic>.from(p);
      pMap['items'] = items;
      pendingPurchases.add(pMap);
    }

    // 9. Pending Supplier Payments
    final pendingSupplierPayments = await db.query('supplier_payments', where: 'sync_status = 0');

    // 10. Pending Delivery Services
    final pendingDeliveryServices = await db.query('delivery_services', where: 'sync_status = 0');

    // 11. Pending Delivery Payments
    final pendingDeliveryPayments = await db.query('delivery_payments', where: 'sync_status = 0');

    // 12. Pending Customer Orders (Custom Textile / Loom Weaving Orders)
    List<Map<String, dynamic>> pendingCustomerOrders = [];
    try {
      final custOrdersRes = await db.query('customer_orders', where: 'sync_status = 0');
      for (var co in custOrdersRes) {
        final items = await db.query('customer_order_items', where: 'customer_order_id = ?', whereArgs: [co['id']]);
        var coMap = Map<String, dynamic>.from(co);
        coMap['items'] = items;
        pendingCustomerOrders.add(coMap);
      }
    } catch (_) {}

    return {
      'sales_orders': pendingSales,
      'customers': pendingCustomers,
      'products': pendingProducts,
      'debt_repayments': pendingRepayments,
      'expenses': pendingExpenses,
      'categories': pendingCategories,
      'supplier_categories': pendingSupplierCategories,
      'suppliers': pendingSuppliers,
      'purchases': pendingPurchases,
      'supplier_payments': pendingSupplierPayments,
      'delivery_services': pendingDeliveryServices,
      'delivery_payments': pendingDeliveryPayments,
      'customer_orders': pendingCustomerOrders,
    };
  }

  // Mark records as synced after server acknowledgement
  Future<void> markSynced(Map<String, dynamic> syncedIds) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    if (syncedIds['sales_orders'] != null) {
      for (var id in syncedIds['sales_orders']) {
        batch.rawUpdate('UPDATE sales_orders SET sync_status = 1 WHERE id = ?', [id]);
        batch.rawUpdate('UPDATE sales_order_items SET sync_status = 1 WHERE sale_order_id = ?', [id]);
      }
    }

    if (syncedIds['customers'] != null) {
      for (var id in syncedIds['customers']) {
        batch.rawUpdate('UPDATE customers SET sync_status = 1 WHERE id = ?', [id]);
      }
    }

    if (syncedIds['products'] != null) {
      for (var id in syncedIds['products']) {
        batch.rawUpdate('UPDATE products SET sync_status = 1 WHERE id = ?', [id]);
      }
    }

    if (syncedIds['debt_repayments'] != null) {
      for (var id in syncedIds['debt_repayments']) {
        batch.rawUpdate('UPDATE debt_repayments SET sync_status = 1 WHERE id = ?', [id]);
      }
    }

    if (syncedIds['expenses'] != null) {
      for (var id in syncedIds['expenses']) {
        batch.rawUpdate('UPDATE expenses SET sync_status = 1 WHERE id = ?', [id]);
      }
    }

    if (syncedIds['categories'] != null) {
      for (var id in syncedIds['categories']) {
        batch.rawUpdate('UPDATE categories SET sync_status = 1 WHERE id = ?', [id]);
      }
    }

    if (syncedIds['supplier_categories'] != null) {
      for (var id in syncedIds['supplier_categories']) {
        batch.rawUpdate('UPDATE supplier_categories SET sync_status = 1 WHERE id = ?', [id]);
      }
    }

    if (syncedIds['suppliers'] != null) {
      for (var id in syncedIds['suppliers']) {
        batch.rawUpdate('UPDATE suppliers SET sync_status = 1 WHERE id = ?', [id]);
      }
    }

    if (syncedIds['purchases'] != null) {
      for (var id in syncedIds['purchases']) {
        batch.rawUpdate('UPDATE purchases SET sync_status = 1 WHERE id = ?', [id]);
        batch.rawUpdate('UPDATE purchase_items SET sync_status = 1 WHERE purchase_id = ?', [id]);
      }
    }

    if (syncedIds['supplier_payments'] != null) {
      for (var id in syncedIds['supplier_payments']) {
        batch.rawUpdate('UPDATE supplier_payments SET sync_status = 1 WHERE id = ?', [id]);
      }
    }

    if (syncedIds['delivery_services'] != null) {
      for (var id in syncedIds['delivery_services']) {
        batch.rawUpdate('UPDATE delivery_services SET sync_status = 1 WHERE id = ?', [id]);
      }
    }

    if (syncedIds['delivery_payments'] != null) {
      for (var id in syncedIds['delivery_payments']) {
        batch.rawUpdate('UPDATE delivery_payments SET sync_status = 1 WHERE id = ?', [id]);
      }
    }

    if (syncedIds['customer_orders'] != null) {
      for (var id in syncedIds['customer_orders']) {
        batch.rawUpdate('UPDATE customer_orders SET sync_status = 1 WHERE id = ?', [id]);
        batch.rawUpdate('UPDATE customer_order_items SET sync_status = 1 WHERE customer_order_id = ?', [id]);
      }
    }

    await batch.commit(noResult: true);
  }
}
