import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controller/AppController.dart';
import '../data/local/user_dao.dart';
import 'app_colors.dart';

class OwnerAuthHelper {
  /// Check if active session is owner/admin. If yes, directly executes callback.
  /// If not, prompts for Owner Passcode dialog to authorize.
  static Future<void> requireOwnerAccess(
    BuildContext context, {
    required VoidCallback onAuthorized,
    String actionName = 'Owner Action',
    String? subtitle,
  }) async {
    final appController = Get.isRegistered<AppController>() ? Get.find<AppController>() : null;
    if (appController?.isOwner == true) {
      // Direct access for Owner / Admin session
      onAuthorized();
      return;
    }

    // Prompt Owner Passcode modal for staff / cashier session
    _showPasscodeDialog(
      context,
      actionName: actionName,
      subtitle: subtitle ?? 'Enter Owner Passcode to authorize this operation.',
      onSuccess: onAuthorized,
    );
  }

  static void _showPasscodeDialog(
    BuildContext context, {
    required String actionName,
    required String subtitle,
    required VoidCallback onSuccess,
  }) {
    final pinController = TextEditingController();
    final isError = false.obs;
    final errorMessage = ''.obs;

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Owner Authorization',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          actionName,
                          style: const TextStyle(fontSize: 11.5, color: Colors.amber, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // PIN Input Field
              TextField(
                controller: pinController,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Owner Passcode / PIN',
                  prefixIcon: Icon(Icons.lock_rounded, size: 18),
                  hintText: 'Enter 4-digit PIN',
                  isDense: true,
                ),
                onSubmitted: (val) async {
                  final pin = val.trim();
                  if (pin.isEmpty) {
                    isError.value = true;
                    errorMessage.value = 'Please enter passcode.';
                    return;
                  }
                  final isValid = await UserDao().verifyOwnerPasscode(pin);
                  if (isValid) {
                    Get.back();
                    onSuccess();
                  } else {
                    isError.value = true;
                    errorMessage.value = 'Incorrect owner passcode. Access denied.';
                  }
                },
              ),
              Obx(() => isError.value
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage.value,
                        style: const TextStyle(color: AppColors.error, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    )
                  : const SizedBox.shrink()),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () async {
                      final pin = pinController.text.trim();
                      if (pin.isEmpty) {
                        isError.value = true;
                        errorMessage.value = 'Please enter passcode.';
                        return;
                      }
                      final isValid = await UserDao().verifyOwnerPasscode(pin);
                      if (isValid) {
                        Get.back();
                        onSuccess();
                      } else {
                        isError.value = true;
                        errorMessage.value = 'Incorrect owner passcode. Access denied.';
                      }
                    },
                    child: const Text('Authorize'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
