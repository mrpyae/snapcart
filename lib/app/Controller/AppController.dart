import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Util/AppConstants.dart';
import '../data/local/db_helper.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/sync_repository.dart';
import '../modules/pos/controllers/pos_controller.dart';
import '../modules/products/controllers/product_controller.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';

enum OperationMode {
  hybrid,
  onlineOnly,
  offlineOnly,
}

class AppController extends GetxController {
  final AuthRepository authRepository = AuthRepository();
  final SyncRepository syncRepository = SyncRepository();

  // Authentication State
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<UserAccountModel?> currentAccount = Rx<UserAccountModel?>(null);
  final RxList<UserModel> lstloginuser = <UserModel>[].obs;

  // Connectivity & Sync State
  final RxBool isOnline = true.obs;
  final Rx<OperationMode> operationMode = OperationMode.hybrid.obs;
  final RxBool isStandaloneMode = false.obs;
  final RxBool isSyncing = false.obs;
  final RxBool isLoading = false.obs;
  final RxString lastSyncTime = ''.obs;

  bool get isOnlineOnly => operationMode.value == OperationMode.onlineOnly;
  bool get isHybrid => operationMode.value == OperationMode.hybrid;
  bool get isOfflineOnly => operationMode.value == OperationMode.offlineOnly;
  bool get isOwner {
    final role = currentAccount.value?.roleName.toLowerCase();
    return role == 'owner' || role == 'admin';
  }

  // Language & Internationalization
  final Rx<Locale> currentLocale = const Locale('en', 'US').obs;
  String get currentLanguageCode => currentLocale.value.languageCode;

  Future<void> changeLanguage(String langCode) async {
    final newLocale = (langCode == 'my') ? const Locale('my', 'MM') : const Locale('en', 'US');
    currentLocale.value = newLocale;
    await DBHelper.instance.setSetting('app_language', langCode);
    try {
      await Get.updateLocale(newLocale);
    } catch (_) {}
  }

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _loadSavedOperationMode();
    _initConnectivity();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> _loadSavedOperationMode() async {
    try {
      final saved = await DBHelper.instance.getSetting('operation_mode');
      if (saved != null) {
        final mode = OperationMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => OperationMode.hybrid,
        );
        operationMode.value = mode;
        isStandaloneMode.value = (mode == OperationMode.offlineOnly);
      }

      // Restore active user session from SQLite
      final savedUserId = await DBHelper.instance.getSetting('active_session_user_id');
      if (savedUserId != null && savedUserId.isNotEmpty) {
        final offlineUser = await authRepository.userDao.getOfflineUserById(savedUserId);
        if (offlineUser != null) {
          currentUser.value = offlineUser;
          lstloginuser.assignAll([offlineUser]);

          final savedAccId = await DBHelper.instance.getSetting('active_session_account_id');
          if (savedAccId != null && savedAccId.isNotEmpty) {
            final acc = offlineUser.accounts.firstWhereOrNull((a) => a.id == savedAccId);
            if (acc != null) {
              currentAccount.value = acc;
            }
          }
          if (currentAccount.value == null && offlineUser.accounts.isNotEmpty) {
            currentAccount.value = offlineUser.accounts.firstWhereOrNull((a) => a.isDefault == 1) ?? offlineUser.accounts.first;
          }
        }
      }

      // Restore saved language
      final savedLang = await DBHelper.instance.getSetting('app_language');
      if (savedLang != null && savedLang == 'my') {
        currentLocale.value = const Locale('my', 'MM');
        await Get.updateLocale(const Locale('my', 'MM'));
      }

      update();
    } catch (_) {}
  }

  Future<void> setOperationMode(OperationMode mode) async {
    if (mode == OperationMode.onlineOnly && !isOnline.value) {
      Get.snackbar(
        'Warning',
        'Device is currently offline. "Online Use Only" requires an active network connection.',
        backgroundColor: Colors.orangeAccent.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }

    operationMode.value = mode;
    isStandaloneMode.value = (mode == OperationMode.offlineOnly);
    await DBHelper.instance.setSetting('operation_mode', mode.name);
    update();

    // Trigger auto sync if switching to a synced mode while online
    if (isOnline.value && mode != OperationMode.offlineOnly && currentUser.value != null) {
      triggerAutoSync();
    }
  }

  void toggleStandaloneMode(bool val) {
    setOperationMode(val ? OperationMode.offlineOnly : OperationMode.hybrid);
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final online = (result != ConnectivityResult.none);
      isOnline.value = online;

      // Trigger automatic background delta sync when coming back online in hybrid/onlineOnly
      if (online && operationMode.value != OperationMode.offlineOnly && currentUser.value != null) {
        triggerAutoSync();
      }
    });
  }

  // Multi-mode Authentication
  Future<bool> authentication(String username, String password, {bool forceOffline = false}) async {
    isLoading.value = true;
    try {
      bool offlineTarget = false;
      bool disallowOfflineFallback = false;

      if (operationMode.value == OperationMode.onlineOnly) {
        if (!isOnline.value) {
          Get.snackbar(
            'Server Connection Required',
            'Cannot log in. "Online Use Only" mode is active and the server is disconnected.',
            backgroundColor: Colors.redAccent.withOpacity(0.85),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
          return false;
        }
        offlineTarget = false;
        disallowOfflineFallback = true;
      } else if (operationMode.value == OperationMode.offlineOnly) {
        offlineTarget = true;
      } else {
        // Hybrid mode
        offlineTarget = forceOffline || !isOnline.value;
      }

      final res = await authRepository.login(
        username,
        password,
        forceOffline: offlineTarget,
        disallowOfflineFallback: disallowOfflineFallback,
      ).timeout(
        Duration(seconds: offlineTarget ? 2 : 5),
        onTimeout: () => {'success': false, 'message': 'Authentication timed out. Please try again.'},
      );

      if (res['success'] == true && res['user'] != null) {
        final user = res['user'] as UserModel;
        currentUser.value = user;
        lstloginuser.assignAll([user]);

        // Auto select default account immediately so currentAccount is never null
        if (user.accounts.isNotEmpty) {
          final defaultAcc = user.accounts.firstWhereOrNull((a) => a.isDefault == 1) ?? user.accounts.first;
          selectAccount(defaultAcc);
        }

        // Persist active session in SQLite
        DBHelper.instance.setSetting('active_session_user_id', user.id);
        if (currentAccount.value != null) {
          DBHelper.instance.setSetting('active_session_account_id', currentAccount.value!.id);
        }

        update();
        return true;
      } else {
        Get.snackbar(
          'Login Failed',
          res['message'] ?? 'Invalid username/phone or password',
          backgroundColor: Colors.redAccent.withOpacity(0.85),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Authentication error: $e',
        backgroundColor: Colors.redAccent.withOpacity(0.85),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Change user password and/or passcode (Owner action)
  Future<bool> changeUserPasswordAndPasscode({
    required String userId,
    required String accountId,
    required String newPassword,
    required String newPasscode,
  }) async {
    try {
      if (newPassword.isNotEmpty) {
        await authRepository.userDao.updateUserPassword(userId, newPassword);
      }
      if (newPasscode.isNotEmpty) {
        await authRepository.userDao.updateUserAccountPasscode(accountId, newPasscode);
      }

      // If updating currently logged in user/account, refresh current session in memory
      if (currentUser.value?.id == userId) {
        final updatedUser = await authRepository.userDao.getOfflineUserById(userId);
        if (updatedUser != null) {
          currentUser.value = updatedUser;
          if (currentAccount.value?.id == accountId) {
            currentAccount.value = updatedUser.accounts.firstWhereOrNull((a) => a.id == accountId) ?? currentAccount.value;
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error changing user password/passcode: $e');
      return false;
    }
  }

  // Switch Active Account / Branch Profile
  void selectAccount(UserAccountModel account) {
    currentAccount.value = account;
    DBHelper.instance.setSetting('active_session_account_id', account.id);
    update();
  }

  // Ensure an active account is present (or restore/fallback)
  Future<UserAccountModel?> ensureActiveAccount() async {
    if (currentAccount.value != null) return currentAccount.value;

    if (currentUser.value != null && currentUser.value!.accounts.isNotEmpty) {
      final acc = currentUser.value!.accounts.firstWhereOrNull((a) => a.isDefault == 1) ?? currentUser.value!.accounts.first;
      selectAccount(acc);
      return acc;
    }

    // Try finding default active account from SQLite
    try {
      final defaultAcc = await authRepository.userDao.getDefaultActiveAccount();
      if (defaultAcc != null) {
        currentAccount.value = defaultAcc;
        final user = await authRepository.userDao.getOfflineUserById(defaultAcc.userId);
        if (user != null) {
          currentUser.value = user;
          lstloginuser.assignAll([user]);
        }
        update();
        return defaultAcc;
      }
    } catch (_) {}

    return null;
  }

  // Verify PIN for Fast Cashier Switch or Manager Approval Override
  Future<UserAccountModel?> verifyPin(String pin, {String? targetAccountId}) async {
    final accountId = targetAccountId ?? currentAccount.value?.id;
    if (accountId == null) return null;

    return await authRepository.verifyPin(accountId, pin);
  }

  // Permission Gatekeeper (RBAC)
  bool hasPermission(String permission) {
    if (currentAccount.value == null) return false;
    return currentAccount.value!.hasPermission(permission);
  }

  // Background / Manual Sync
  Future<bool> triggerAutoSync({bool forceFull = false}) async {
    if (operationMode.value == OperationMode.offlineOnly || !isOnline.value || isSyncing.value) return false;

    isSyncing.value = true;
    try {
      final bizId = currentAccount.value?.businessId ?? AppConstants.defaultBusinessId;
      final res = await syncRepository.performSync(
        lastSyncTimestamp: forceFull ? null : (lastSyncTime.value.isNotEmpty ? lastSyncTime.value : null),
        businessId: bizId,
      );

      isSyncing.value = false;
      if (res['success'] == true) {
        if (res['server_timestamp'] != null) {
          lastSyncTime.value = res['server_timestamp'];
        }
        update();

        // Automatically reload POS and Product controllers if registered
        try {
          if (Get.isRegistered<POSController>()) {
            Get.find<POSController>().loadProducts();
          }
        } catch (_) {}
        try {
          if (Get.isRegistered<ProductController>()) {
            Get.find<ProductController>().loadProducts();
          }
        } catch (_) {}

        Get.snackbar(
          'Sync Complete',
          forceFull
              ? 'All products & catalog data refreshed from server'
              : 'Data synchronized successfully with server',
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return true;
      } else {
        Get.snackbar(
          'Sync Failed',
          res['message']?.toString() ?? 'Failed to synchronize with server',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      isSyncing.value = false;
      Get.snackbar(
        'Sync Error',
        'Error during sync: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    return false;
  }

  // Logout
  void logout() {
    currentUser.value = null;
    currentAccount.value = null;
    lstloginuser.clear();
    DBHelper.instance.setSetting('active_session_user_id', '');
    DBHelper.instance.setSetting('active_session_account_id', '');
    update();
    Get.offAllNamed(Routes.LOGIN);
  }
}