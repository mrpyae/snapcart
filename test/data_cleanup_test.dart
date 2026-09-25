import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/data/local/data_cleanup_dao.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DBHelper.instance.close();
  });

  test('Data Cleanup Dao preserves default Admin user and accounts while clearing selected data', () async {
    final db = await DBHelper.instance.database;
    final cleanupDao = DataCleanupDao();

    // 1. Seed dummy non-admin cashier and a product
    await db.insert('users', {
      'id': 'usr-test-cashier',
      'name': 'Test Cashier',
      'username': 'testcashier',
      'phone': '099999999',
      'password_hash': '123456',
      'is_active': 1,
      'sync_status': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('user_accounts', {
      'id': 'acc-test-cashier',
      'user_id': 'usr-test-cashier',
      'business_id': 'default_biz',
      'branch_name': 'Test Branch',
      'role_name': 'cashier',
      'is_default': 1,
      'is_active': 1,
      'sync_status': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('products', {
      'id': 'prod-cleanup-test-01',
      'business_id': 'default_biz',
      'name': 'Test Shirt',
      'retail_price': 15000.0,
      'is_active': 1,
      'sync_status': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // 2. Run deleteSelectedData for 'products' and 'users'
    final res = await cleanupDao.deleteSelectedData(['products', 'users']);

    expect(res.containsKey('products'), isTrue);
    expect(res.containsKey('users'), isTrue);

    // 3. Verify product is deleted
    final prodCheck = await db.query('products', where: "id = 'prod-cleanup-test-01'");
    expect(prodCheck.isEmpty, isTrue);

    // 4. Verify test cashier is deleted
    final cashierCheck = await db.query('users', where: "id = 'usr-test-cashier'");
    expect(cashierCheck.isEmpty, isTrue);

    // 5. Verify default Admin user 'usr-admin-001' / 'admin' is KEPT!
    final adminUserCheck = await db.query('users', where: "id = 'usr-admin-001' OR username = 'admin'");
    expect(adminUserCheck.isNotEmpty, isTrue, reason: 'Admin user must be preserved');
    expect(adminUserCheck.first['username'], 'admin');

    // 6. Verify default Admin account 'acc-admin-main' is KEPT!
    final adminAccCheck = await db.query('user_accounts', where: "user_id = 'usr-admin-001'");
    expect(adminAccCheck.isNotEmpty, isTrue, reason: 'Admin user accounts must be preserved');
  });
}
