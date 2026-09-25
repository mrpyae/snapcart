import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/customer_model.dart';
import 'db_helper.dart';

class CustomerDao {
  final dbHelper = DBHelper.instance;

  Future<void> insertOrUpdateCustomer(CustomerModel customer) async {
    final db = await dbHelper.database;
    await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> batchSaveCustomers(List<dynamic> customers) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var c in customers) {
      final model = CustomerModel.fromJson(c);
      // Use a safe merge upsert:
      // - Profile fields (name, phone, etc.) are always updated from server.
      // - current_debt and advance_balance use MAX() so a stale server zero
      //   never silently erases locally-recorded debt that hasn't synced yet.
      batch.rawInsert('''
        INSERT INTO customers
          (id, business_id, name, phone, address, customer_type,
           credit_limit, current_debt, advance_balance, sync_status, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name            = excluded.name,
          phone           = excluded.phone,
          address         = excluded.address,
          customer_type   = excluded.customer_type,
          credit_limit    = excluded.credit_limit,
          current_debt    = MAX(current_debt, excluded.current_debt),
          advance_balance = MAX(advance_balance, excluded.advance_balance),
          updated_at      = excluded.updated_at
      ''', [
        model.id,
        model.businessId,
        model.name,
        model.phone,
        model.address,
        model.customerType,
        model.creditLimit,
        model.currentDebt,
        model.advanceBalance,
        model.syncStatus,
        model.toMap()['updated_at'],
      ]);
    }
    await batch.commit(noResult: true);
  }

  Future<List<CustomerModel>> getCustomers({String query = '', String businessId = 'default_biz'}) async {
    final db = await dbHelper.database;
    String whereClause = 'business_id = ?';
    List<dynamic> whereArgs = [businessId];

    if (query.isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR phone LIKE ?)';
      final q = '%$query%';
      whereArgs.addAll([q, q]);
    }

    final res = await db.query(
      'customers',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return res.map((e) => CustomerModel.fromJson(e)).toList();
  }

  Future<void> adjustCustomerDebt(String customerId, double debtChange) async {
    final db = await dbHelper.database;
    await db.rawUpdate(
      'UPDATE customers SET current_debt = MAX(0, current_debt + ?), sync_status = 0, updated_at = ? WHERE id = ?',
      [debtChange, DateTime.now().toIso8601String(), customerId],
    );
  }

  Future<void> adjustCustomerAdvance(String customerId, double advanceChange) async {
    final db = await dbHelper.database;
    await db.rawUpdate(
      'UPDATE customers SET advance_balance = MAX(0, advance_balance + ?), sync_status = 0, updated_at = ? WHERE id = ?',
      [advanceChange, DateTime.now().toIso8601String(), customerId],
    );
  }
}
