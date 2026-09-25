import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/utils/backup_restore_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DBHelper.instance.closeDatabase();
  });

  test('BackupRestoreService can create, inspect, restore, and delete SQLite backups', () async {
    final db = await DBHelper.instance.database;
    final service = BackupRestoreService.instance;

    // 1. Seed a unique test product
    final testProductId = 'prod-backup-test-${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('products', {
      'id': testProductId,
      'business_id': 'default_biz',
      'name': 'Backup Test Product',
      'retail_price': 25000.0,
      'is_active': 1,
      'sync_status': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // 2. Create backup
    final backupResult = await service.createBackup();
    expect(backupResult.success, isTrue);
    expect(backupResult.filePath, isNotNull);

    final backupPath = backupResult.filePath!;

    // 3. Inspect backup file
    final inspection = await service.inspectBackupFile(backupPath);
    expect(inspection.isValid, isTrue);
    expect(inspection.productsCount, greaterThan(0));

    // 4. Delete the test product from the active database
    await db.delete('products', where: 'id = ?', whereArgs: [testProductId]);
    final deletedCheck = await db.query('products', where: 'id = ?', whereArgs: [testProductId]);
    expect(deletedCheck.isEmpty, isTrue);

    // 5. Restore from backup
    final restoreResult = await service.restoreDatabase(backupPath);
    expect(restoreResult.success, isTrue);

    // 6. Verify restored data
    final restoredDb = await DBHelper.instance.database;
    final restoredCheck = await restoredDb.query('products', where: 'id = ?', whereArgs: [testProductId]);
    expect(restoredCheck.isNotEmpty, isTrue);
    expect(restoredCheck.first['name'], 'Backup Test Product');

    // 7. Cleanup test backup file
    final deleteResult = await service.deleteBackup(backupPath);
    expect(deleteResult, isTrue);
  });
}
