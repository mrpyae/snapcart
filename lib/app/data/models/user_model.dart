import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String username;
  final String? phone;
  final int isActive;
  final int syncStatus;
  final List<UserAccountModel> accounts;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    this.phone,
    this.isActive = 1,
    this.syncStatus = 1,
    this.accounts = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var accList = <UserAccountModel>[];
    if (json['accounts'] != null && json['accounts'] is List) {
      accList = (json['accounts'] as List)
          .map((i) => UserAccountModel.fromJson(i))
          .toList();
    }
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      phone: json['phone']?.toString(),
      isActive: json['is_active'] != null ? int.tryParse(json['is_active'].toString()) ?? 1 : 1,
      syncStatus: json['sync_status'] != null ? int.tryParse(json['sync_status'].toString()) ?? 1 : 1,
      accounts: accList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'phone': phone,
      'is_active': isActive,
      'sync_status': syncStatus,
    };
  }
}

class UserAccountModel {
  final String id;
  final String userId;
  final String businessId;
  final String branchName;
  final String roleName;
  final String? passcode;
  final List<String> permissions;
  final int isDefault;
  final int isActive;

  UserAccountModel({
    required this.id,
    required this.userId,
    this.businessId = 'default_biz',
    this.branchName = 'Main Branch',
    this.roleName = 'cashier',
    this.passcode,
    this.permissions = const [],
    this.isDefault = 0,
    this.isActive = 1,
  });

  bool hasPermission(String permission) {
    if (roleName.toLowerCase() == 'owner' || roleName.toLowerCase() == 'admin') {
      return true;
    }
    return permissions.contains(permission);
  }

  factory UserAccountModel.fromJson(Map<String, dynamic> json) {
    List<String> perms = [];
    if (json['permissions'] != null) {
      if (json['permissions'] is List) {
        perms = (json['permissions'] as List).map((e) => e.toString()).toList();
      } else if (json['permissions'] is String) {
        try {
          var decoded = jsonDecode(json['permissions']);
          if (decoded is List) {
            perms = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
    }
    return UserAccountModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      branchName: json['branch_name']?.toString() ?? 'Main Branch',
      roleName: json['role_name']?.toString() ?? 'cashier',
      passcode: json['passcode']?.toString(),
      permissions: perms,
      isDefault: json['is_default'] != null ? int.tryParse(json['is_default'].toString()) ?? 0 : 0,
      isActive: json['is_active'] != null ? int.tryParse(json['is_active'].toString()) ?? 1 : 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'branch_name': branchName,
      'role_name': roleName,
      'passcode': passcode,
      'permissions': jsonEncode(permissions),
      'is_default': isDefault,
      'is_active': isActive,
    };
  }
}
