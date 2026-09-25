import 'db_helper.dart';

class DataCleanupDao {
  final dbHelper = DBHelper.instance;

  /// Deletes selected local SQLite modules while strictly preserving
  /// the default Admin account ('usr-admin-001' / 'admin').
  Future<Map<String, int>> deleteSelectedData(List<String> modules) async {
    final db = await dbHelper.database;
    final Map<String, int> results = {};

    await db.transaction((txn) async {
      // 1. Sales & Invoices
      if (modules.contains('sales')) {
        await txn.delete('sales_order_items');
        await txn.delete('debt_repayments');
        try {
          await txn.delete('held_orders');
        } catch (_) {}
        final count = await txn.delete('sales_orders');
        results['sales'] = count;
      }

      // 2. Custom Customer Orders
      if (modules.contains('customer_orders')) {
        try {
          await txn.delete('customer_order_items');
          final count = await txn.delete('customer_orders');
          results['customer_orders'] = count;
        } catch (_) {
          results['customer_orders'] = 0;
        }
      }

      // 3. Purchases & Supplier POs
      if (modules.contains('purchases')) {
        try {
          await txn.delete('purchase_items');
          await txn.delete('supplier_payments');
          final count = await txn.delete('purchases');
          results['purchases'] = count;
        } catch (_) {
          results['purchases'] = 0;
        }
      }

      // 4. Products & Stock
      if (modules.contains('products')) {
        try {
          await txn.delete('product_suppliers');
        } catch (_) {}
        final count = await txn.delete('products');
        results['products'] = count;
      }

      // 5. Categories
      if (modules.contains('categories')) {
        final count = await txn.delete('categories');
        results['categories'] = count;
      }

      // 6. Customers & Debts
      if (modules.contains('customers')) {
        await txn.delete('debt_repayments');
        final count = await txn.delete('customers');
        results['customers'] = count;
      }

      // 7. Suppliers & Payables
      if (modules.contains('suppliers')) {
        try {
          await txn.delete('product_suppliers');
          await txn.delete('supplier_payments');
        } catch (_) {}
        final count = await txn.delete('suppliers');
        results['suppliers'] = count;
      }

      // 8. Expenses
      if (modules.contains('expenses')) {
        final count = await txn.delete('expenses');
        results['expenses'] = count;
      }

      // 9. Delivery Services & Remittances
      if (modules.contains('delivery_services')) {
        try {
          await txn.delete('delivery_payments');
          final count = await txn.delete('delivery_services');
          results['delivery_services'] = count;
        } catch (_) {
          results['delivery_services'] = 0;
        }
      }

      // 10. Staff / Cashier Accounts (Strictly EXCLUDING default Admin account)
      if (modules.contains('users')) {
        final accCount = await txn.delete(
          'user_accounts',
          where: "user_id != 'usr-admin-001' AND role_name != 'owner'",
        );
        final userCount = await txn.delete(
          'users',
          where: "id != 'usr-admin-001' AND username != 'admin'",
        );
        results['users'] = userCount + accCount;
      }
    });

    return results;
  }
}
