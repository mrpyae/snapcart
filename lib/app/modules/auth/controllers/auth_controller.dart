import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository authRepository = AuthRepository();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<UserAccountModel?> currentAccount = Rx<UserAccountModel?>(null);
  final RxBool isOnline = true.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      isOnline.value = (result != ConnectivityResult.none);
    });
  }

  // Check if active user account has specific granular permission
  bool hasPermission(String permission) {
    if (currentAccount.value == null) return false;
    return currentAccount.value!.hasPermission(permission);
  }

  // Login handler
  Future<bool> login(String username, String password) async {
    isLoading.value = true;
    try {
      final res = await authRepository.login(username, password);
      isLoading.value = false;

      if (res['success'] == true && res['user'] != null) {
        currentUser.value = res['user'] as UserModel;

        // If user has only 1 account profile, select it automatically
        if (currentUser.value!.accounts.length == 1) {
          selectAccount(currentUser.value!.accounts.first);
        }
        return true;
      } else {
        Get.snackbar('Login Failed', res['message'] ?? 'Invalid credentials',
            backgroundColor: Colors.redAccent.withOpacity(0.8),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Login error: $e',
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  // Select active account / branch profile
  void selectAccount(UserAccountModel account) {
    currentAccount.value = account;
  }

  // Logout
  void logout() {
    currentUser.value = null;
    currentAccount.value = null;
  }
}
