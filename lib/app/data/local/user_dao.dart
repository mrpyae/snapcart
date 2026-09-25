import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/user_model.dart';
import 'db_helper.dart';

class UserDao {
  final dbHelper = DBHelper.instance;

  Future<void> cacheUsersAndAccounts(List<dynamic> users, List<dynamic> accounts) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    for (var u in users) {
      batch.insert(
        'users',
        {
          'id': u['id'],
          'name': u['name'],
          'username': u['username'],
          'phone': u['phone'],
          'password_hash': u['password_hash'] ?? u['password'] ?? '123456',
          'is_active': u['is_active'] ?? 1,
          'sync_status': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (var a in accounts) {
      batch.insert(
        'user_accounts',
        {
          'id': a['id'],
          'user_id': a['user_id'],
          'business_id': a['business_id'] ?? 'default_biz',
          'branch_name': a['branch_name'] ?? 'Main Branch',
          'role_name': a['role_name'] ?? 'cashier',
          'passcode': a['passcode'],
          'permissions': a['permissions'] is String ? a['permissions'] : jsonEncode(a['permissions'] ?? []),
          'is_default': a['is_default'] ?? 0,
          'is_active': a['is_active'] ?? 1,
          'sync_status': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<UserAccountModel>> getAccountsForUser(String userId) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'user_accounts',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'is_default DESC',
    );
    return res.map((e) => UserAccountModel.fromJson(e)).toList();
  }

  Future<UserAccountModel?> verifyOfflinePin(String userAccountId, String pin) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'user_accounts',
      where: 'id = ? AND passcode = ? AND is_active = 1',
      whereArgs: [userAccountId, pin],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return UserAccountModel.fromJson(res.first);
    }
    return null;
  }

  Future<bool> verifyOfflinePassword(String userId, String rawPassword) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'users',
      columns: ['password_hash'],
      where: 'id = ? AND is_active = 1',
      whereArgs: [userId],
      limit: 1,
    );
    if (res.isNotEmpty) {
      final storedHash = res.first['password_hash']?.toString() ?? '';
      // Direct plain text comparison (unencrypted):
      if (storedHash == rawPassword.trim()) {
        return true;
      }
      // Backwards-compatibility for initial seeded default passwords:
      if (storedHash == '123456' || storedHash == 'password') {
        if (rawPassword.trim() == '123456' || rawPassword.trim() == 'password') {
          return true;
        }
      }
    }
    return false;
  }

  /// Update user login password in plain text (unencrypted)
  Future<void> updateUserPassword(String userId, String plainPassword) async {
    final db = await dbHelper.database;
    await db.update(
      'users',
      {
        'password_hash': plainPassword.trim(),
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Update user account 4-digit passcode in plain text
  Future<void> updateUserAccountPasscode(String accountId, String plainPasscode) async {
    final db = await dbHelper.database;
    await db.update(
      'user_accounts',
      {
        'passcode': plainPasscode.trim(),
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  /// Get all active users with their associated branch accounts
  Future<List<UserModel>> getAllUsersWithAccounts() async {
    final db = await dbHelper.database;
    final res = await db.query(
      'users',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    final List<UserModel> users = [];
    for (var row in res) {
      final user = UserModel.fromJson(row);
      final accounts = await getAccountsForUser(user.id);
      users.add(UserModel(
        id: user.id,
        name: user.name,
        username: user.username,
        phone: user.phone,
        isActive: user.isActive,
        syncStatus: user.syncStatus,
        accounts: accounts,
      ));
    }
    return users;
  }

  Future<UserModel?> getOfflineUserByUsername(String username) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'users',
      where: '(username = ? OR phone = ?) AND is_active = 1',
      whereArgs: [username, username],
      limit: 1,
    );
    if (res.isNotEmpty) {
      final user = UserModel.fromJson(res.first);
      final accounts = await getAccountsForUser(user.id);
      return UserModel(
        id: user.id,
        name: user.name,
        username: user.username,
        phone: user.phone,
        isActive: user.isActive,
        syncStatus: user.syncStatus,
        accounts: accounts,
      );
    }
    return null;
  }

  Future<UserModel?> getOfflineUserById(String userId) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'users',
      where: 'id = ? AND is_active = 1',
      whereArgs: [userId],
      limit: 1,
    );
    if (res.isNotEmpty) {
      final user = UserModel.fromJson(res.first);
      final accounts = await getAccountsForUser(user.id);
      return UserModel(
        id: user.id,
        name: user.name,
        username: user.username,
        phone: user.phone,
        isActive: user.isActive,
        syncStatus: user.syncStatus,
        accounts: accounts,
      );
    }
    return null;
  }

  Future<UserAccountModel?> getDefaultActiveAccount() async {
    final db = await dbHelper.database;
    final res = await db.query(
      'user_accounts',
      where: 'is_active = 1',
      orderBy: 'is_default DESC, role_name ASC',
      limit: 1,
    );
    if (res.isNotEmpty) {
      return UserAccountModel.fromJson(res.first);
    }
    return null;
  }

  /// Verify if the given passcode matches any active Owner or Admin account
  Future<bool> verifyOwnerPasscode(String passcode) async {
    final trimmed = passcode.trim();
    if (trimmed.isEmpty) return false;
    final db = await dbHelper.database;
    final res = await db.rawQuery('''
      SELECT id FROM user_accounts 
      WHERE (LOWER(role_name) = 'owner' OR LOWER(role_name) = 'admin') 
        AND passcode = ? 
        AND is_active = 1
      LIMIT 1
    ''', [trimmed]);
    return res.isNotEmpty;
  }
}
