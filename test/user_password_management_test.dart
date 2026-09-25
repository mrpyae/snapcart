import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/data/local/user_dao.dart';

void main() {
  late UserDao userDao;
  late DBHelper dbHelper;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dbHelper = DBHelper.instance;
    userDao = UserDao();

    // Ensure database is initialized with default tables and seeds
    final db = await dbHelper.database;
    await db.execute('SELECT COUNT(*) FROM users');
  });

  group('Plain-Text Password & Owner Passcode Management Test Suite', () {
    test('Plain-text password verification: exact match works, incorrect fails', () async {
      // Admin account usr-admin-001 has default password 123456
      final isValid = await userDao.verifyOfflinePassword('usr-admin-001', '123456');
      expect(isValid, isTrue, reason: 'Correct plain-text password should be verified successfully');

      final isWrong = await userDao.verifyOfflinePassword('usr-admin-001', 'wrong_password_999');
      expect(isWrong, isFalse, reason: 'Incorrect password should fail');
    });

    test('updateUserPassword stores plain text without encryption and takes effect immediately', () async {
      const newPlainPassword = 'MySecretPlainPass2026';
      await userDao.updateUserPassword('usr-admin-001', newPlainPassword);

      // Verify directly from SQLite database table
      final db = await dbHelper.database;
      final res = await db.query(
        'users',
        columns: ['password_hash'],
        where: 'id = ?',
        whereArgs: ['usr-admin-001'],
      );

      expect(res.isNotEmpty, isTrue);
      final rawStored = res.first['password_hash']?.toString();
      expect(rawStored, equals(newPlainPassword),
          reason: 'Password MUST be stored as pure plain text (unencrypted), not hashed with bcrypt or md5');

      // Verify authentication method works with new plain password
      final canLoginNew = await userDao.verifyOfflinePassword('usr-admin-001', newPlainPassword);
      expect(canLoginNew, isTrue);

      final cannotLoginOld = await userDao.verifyOfflinePassword('usr-admin-001', '123456');
      expect(cannotLoginOld, isFalse);

      // Restore to default
      await userDao.updateUserPassword('usr-admin-001', '123456');
    });

    test('updateUserAccountPasscode updates Owner authorization code', () async {
      // Default owner passcode is 1234
      final initialOwnerCheck = await userDao.verifyOwnerPasscode('1234');
      expect(initialOwnerCheck, isTrue);

      // Change owner passcode to 9876
      const newPasscode = '9876';
      await userDao.updateUserAccountPasscode('acc-admin-main', newPasscode);

      // Database verification
      final db = await dbHelper.database;
      final res = await db.query(
        'user_accounts',
        columns: ['passcode'],
        where: 'id = ?',
        whereArgs: ['acc-admin-main'],
      );
      expect(res.first['passcode']?.toString(), equals('9876'));

      // verifyOwnerPasscode should now accept 9876 and reject 1234
      final newCodeCheck = await userDao.verifyOwnerPasscode(newPasscode);
      expect(newCodeCheck, isTrue, reason: 'New passcode 9876 should authorize owner access');

      final oldCodeCheck = await userDao.verifyOwnerPasscode('1234');
      expect(oldCodeCheck, isFalse, reason: 'Old passcode 1234 should no longer authorize main owner');

      // Restore back to 1234
      await userDao.updateUserAccountPasscode('acc-admin-main', '1234');
      expect(await userDao.verifyOwnerPasscode('1234'), isTrue);
    });

    test('Old database compatibility: old bcrypt hash auto-migrates to plain text seamlessly', () async {
      final db = await dbHelper.database;
      // Simulate an old database user row containing an old bcrypt hash
      const oldBcryptHash = r'$2y$10$e8wV4s6N.g6Yp7q6F4c3eO7Z9L0M1N2O3P4Q5R6S7T8U9V0W1X2Y3';
      await db.update('users', {'password_hash': oldBcryptHash}, where: 'id = ?', whereArgs: ['usr-admin-001']);

      // Attempt login with default password '123456'
      final canLogin = await userDao.verifyOfflinePassword('usr-admin-001', '123456');
      expect(canLogin, isTrue, reason: 'Old database users with bcrypt hashes must still be able to log in with 123456');

      // Verify that the row in SQLite has now been auto-upgraded to plain text '123456'
      final res = await db.query('users', columns: ['password_hash'], where: 'id = ?', whereArgs: ['usr-admin-001']);
      expect(res.first['password_hash']?.toString(), equals('123456'),
          reason: 'Row should now be converted to pure plain text for future instant logins');
    });

    test('getAllUsersWithAccounts retrieves users and their accounts', () async {
      final list = await userDao.getAllUsersWithAccounts();
      expect(list.isNotEmpty, isTrue);

      final adminUser = list.firstWhere((u) => u.id == 'usr-admin-001');
      expect(adminUser.accounts.isNotEmpty, isTrue);
      expect(adminUser.accounts.any((a) => a.roleName == 'owner'), isTrue);
    });
  });
}
