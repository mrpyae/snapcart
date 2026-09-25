import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/responsive.dart';
import '../../../Controller/AppController.dart';
import '../../auth/views/account_selection_dialog.dart';
import 'data_cleanup_dialog.dart';
import 'bluetooth_printer_dialog.dart';
import 'backup_restore_dialog.dart';
import '../../../utils/bluetooth_printer_service.dart';
import '../../../utils/owner_auth_helper.dart';
import 'change_password_dialog.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find<AppController>();
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isMobile ? 'menu_settings'.tr : 'settings_title'.tr,
                style: TextStyle(fontSize: Responsive.titleFontSize(context), fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text('settings_subtitle'.tr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 18),

            // Profile & Active Branch Card
            Obx(() {
              final user = appController.currentUser.value;
              final account = appController.currentAccount.value;
              return Container(
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_outline_rounded, color: AppColors.primaryLight, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.name ?? 'Guest User (Not Logged In)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(user != null ? 'Branch: ${account?.branchName ?? "N/A"} (${account?.roleName.toUpperCase() ?? "N/A"})' : 'Sign in to access synchronized cloud data',
                                  style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (user != null) ...[
                      if (user.accounts.length > 1) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Get.dialog(AccountSelectionDialog(accounts: user.accounts)),
                            icon: const Icon(Icons.switch_account_rounded, size: 16),
                            label: Text('switch_branch_role'.tr),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            OwnerAuthHelper.requireOwnerAccess(
                              context,
                              actionName: 'Change Password & Passcode',
                              subtitle: 'Enter Owner Passcode to manage user passwords.',
                              onAuthorized: () {
                                Get.dialog(const ChangePasswordDialog());
                              },
                            );
                          },
                          icon: const Icon(Icons.password_rounded, size: 16, color: Colors.amber),
                          label: const Text('Change Password & Passcode (Owner)', style: TextStyle(color: Colors.amber)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amber),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('confirm_logout'.tr),
                                content: Text('confirm_logout_msg'.tr),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('btn_cancel'.tr)),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      appController.logout();
                                    },
                                    child: Text('btn_logout'.tr, style: const TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
                          label: Text('log_out_account'.tr, style: const TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Get.toNamed(Routes.LOGIN),
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: Text('sign_in_account'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Language Settings Card
            Obx(() {
              final currentCode = appController.currentLanguageCode;
              return Container(
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.language_rounded, color: AppColors.primaryLight, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'language_settings'.tr,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'language_settings_subtitle'.tr,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isMobile) ...[
                      _buildLanguageOptionCard(
                        title: 'English',
                        subtitle: 'English (United States)',
                        flagEmoji: '🇺🇸',
                        isSelected: currentCode != 'my',
                        onTap: () async {
                          if (currentCode != 'en') {
                            await appController.changeLanguage('en');
                            Get.snackbar('language'.tr, 'language_switched'.tr,
                                snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildLanguageOptionCard(
                        title: 'မြန်မာဘာသာ',
                        subtitle: 'Myanmar (Unicode)',
                        flagEmoji: '🇲🇲',
                        isSelected: currentCode == 'my',
                        onTap: () async {
                          if (currentCode != 'my') {
                            await appController.changeLanguage('my');
                            Get.snackbar('language'.tr, 'language_switched'.tr,
                                snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
                          }
                        },
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildLanguageOptionCard(
                              title: 'English',
                              subtitle: 'English (United States)',
                              flagEmoji: '🇺🇸',
                              isSelected: currentCode != 'my',
                              onTap: () async {
                                if (currentCode != 'en') {
                                  await appController.changeLanguage('en');
                                  Get.snackbar('language'.tr, 'language_switched'.tr,
                                      snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildLanguageOptionCard(
                              title: 'မြန်မာဘာသာ',
                              subtitle: 'Myanmar (Unicode)',
                              flagEmoji: '🇲🇲',
                              isSelected: currentCode == 'my',
                              onTap: () async {
                                if (currentCode != 'my') {
                                  await appController.changeLanguage('my');
                                  Get.snackbar('language'.tr, 'language_switched'.tr,
                                      snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // 2-Way Delta Sync Hub Card
            Container(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('2-Way Delta Sync Hub', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Obx(() {
                        final mode = appController.operationMode.value;
                        final isOnline = appController.isOnline.value;

                        String chipText;
                        Color chipColor;

                        switch (mode) {
                          case OperationMode.offlineOnly:
                            chipText = 'Offline Only';
                            chipColor = AppColors.offline;
                            break;
                          case OperationMode.onlineOnly:
                            if (isOnline) {
                              chipText = 'Online Only (Connected)';
                              chipColor = AppColors.online;
                            } else {
                              chipText = 'Online Only (Disconnected)';
                              chipColor = AppColors.error;
                            }
                            break;
                          case OperationMode.hybrid:
                          default:
                            if (isOnline) {
                              chipText = 'Hybrid (Online)';
                              chipColor = AppColors.online;
                            } else {
                              chipText = 'Hybrid (Offline)';
                              chipColor = AppColors.offline;
                            }
                            break;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: chipColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: chipColor.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: chipColor,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                chipText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: chipColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Select operation mode and sync local SQLite transactions with MySQL server', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),

                  // 3-Way Operation Mode Selector
                  Obx(() {
                    final currentMode = appController.operationMode.value;
                    return Column(
                      children: [
                        // Option 1: Hybrid (Recommended)
                        _buildOperationModeCard(
                          context: context,
                          mode: OperationMode.hybrid,
                          currentMode: currentMode,
                          title: 'Both Offline + Online (Hybrid)',
                          subtitle: 'Operates with local SQLite; automatically syncs deltas with server when connected.',
                          badgeText: 'Recommended',
                          badgeColor: AppColors.primary,
                          icon: Icons.cloud_sync_rounded,
                          onTap: () => appController.setOperationMode(OperationMode.hybrid),
                        ),
                        const SizedBox(height: 10),

                        // Option 2: Online Use Only
                        _buildOperationModeCard(
                          context: context,
                          mode: OperationMode.onlineOnly,
                          currentMode: currentMode,
                          title: 'Online Use Only',
                          subtitle: 'Requires active server connection. POS sales sync immediately; offline checkout blocked.',
                          badgeText: 'Live Server Required',
                          badgeColor: const Color(0xFF0284C7),
                          icon: Icons.cloud_done_rounded,
                          onTap: () => appController.setOperationMode(OperationMode.onlineOnly),
                        ),
                        const SizedBox(height: 10),

                        // Option 3: Offline Only
                        _buildOperationModeCard(
                          context: context,
                          mode: OperationMode.offlineOnly,
                          currentMode: currentMode,
                          title: 'Offline Only (Standalone)',
                          subtitle: 'Operates purely on local SQLite. Server requests, polling, and background sync are disabled.',
                          badgeText: 'Standalone',
                          badgeColor: AppColors.offline,
                          icon: Icons.cloud_off_rounded,
                          onTap: () => appController.setOperationMode(OperationMode.offlineOnly),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),

                  // Sync Now Button
                  Obx(() {
                    final mode = appController.operationMode.value;
                    final isOnline = appController.isOnline.value;
                    final isSyncing = appController.isSyncing.value;

                    final bool canSync = mode != OperationMode.offlineOnly && isOnline && !isSyncing;

                    String btnText;
                    IconData btnIcon = Icons.sync_rounded;

                    if (mode == OperationMode.offlineOnly) {
                      btnText = 'Sync Disabled (Offline Only Mode)';
                      btnIcon = Icons.cloud_off_rounded;
                    } else if (!isOnline) {
                      btnText = mode == OperationMode.onlineOnly
                          ? 'Server Disconnected (Online Only)'
                          : 'Offline (Connect Network to Sync)';
                      btnIcon = Icons.wifi_off_rounded;
                    } else if (isSyncing) {
                      btnText = 'Syncing...';
                    } else {
                      btnText = 'Sync Now (Push & Pull)';
                    }

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: canSync ? () => appController.triggerAutoSync() : null,
                        icon: isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(btnIcon, size: 18),
                        label: Text(btnText),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),

                  // Force Full Re-Sync Button
                  Obx(() {
                    final mode = appController.operationMode.value;
                    final isOnline = appController.isOnline.value;
                    final isSyncing = appController.isSyncing.value;
                    final bool canReSync = mode != OperationMode.offlineOnly && isOnline && !isSyncing;

                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: canReSync ? () => appController.triggerAutoSync(forceFull: true) : null,
                        icon: const Icon(Icons.cloud_download_outlined, size: 18),
                        label: Text('force_full_resync'.tr),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sale Voucher & Receipt Design Card
            Container(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryLight, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sale Voucher & Receipt Design',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Voucher Builder, shop logo, address, thermal 80mm & A4 formats',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Customize voucher layout, store branding, logo, contact info, notes, and PDF print formatting.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.toNamed(Routes.VOUCHER_BUILDER),
                      icon: const Icon(Icons.palette_rounded, size: 18),
                      label: const Text('Open Voucher Builder & Designer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Thermal Bluetooth Printer Card
            _BluetoothPrinterCard(isMobile: isMobile),
            const SizedBox(height: 16),

            // SQLite Database Backup & Restore Card
            Container(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.settings_backup_restore_rounded, color: AppColors.primaryLight, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SQLite Database Backup & Restore',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Atomic database snapshots, export to storage & safety restore',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create local or external backup files (.db) of your entire POS data, or restore an earlier backup with pre-flight integrity inspection and automatic rollback protection.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.dialog(const BackupRestoreDialog()),
                      icon: const Icon(Icons.cloud_sync_rounded, size: 18),
                      label: const Text('Open Backup & Restore Hub'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Danger Zone / Data Management Card
            Container(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Management & Reset',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Selectively delete offline/online data (Requires password)',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Permanently delete sales, inventory, customers, or transactions. The default Admin account (usr-admin-001) will always be preserved.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.dialog(
                        const DataCleanupDialog(),
                        barrierDismissible: false,
                      ),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Colors.white),
                      label: const Text('All Data Delete / Database Reset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.offAllNamed(Routes.LOGIN),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationModeCard({
    required BuildContext context,
    required OperationMode mode,
    required OperationMode currentMode,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = currentMode == mode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? badgeColor.withOpacity(0.08) : AppColors.cardBgLight.withOpacity(0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? badgeColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? badgeColor.withOpacity(0.2) : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? badgeColor : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeColor.withOpacity(0.4), width: 0.8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Radio<OperationMode>(
              value: mode,
              groupValue: currentMode,
              activeColor: badgeColor,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOptionCard({
    required String title,
    required String subtitle,
    required String flagEmoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : AppColors.cardBgLight.withOpacity(0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(flagEmoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _BluetoothPrinterCard extends StatefulWidget {
  final bool isMobile;
  const _BluetoothPrinterCard({Key? key, required this.isMobile}) : super(key: key);

  @override
  State<_BluetoothPrinterCard> createState() => _BluetoothPrinterCardState();
}

class _BluetoothPrinterCardState extends State<_BluetoothPrinterCard> {
  String? _printerName;
  String? _printerMac;
  String _paperSize = 'mm80';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadPrinterSettings();
  }

  Future<void> _loadPrinterSettings() async {
    final name = await BluetoothPrinterService.instance.getSavedPrinterName();
    final mac = await BluetoothPrinterService.instance.getSavedPrinterMac();
    final paper = await BluetoothPrinterService.instance.getSavedPaperSize();
    final connected = await BluetoothPrinterService.instance.isConnected();

    if (mounted) {
      setState(() {
        _printerName = (name != null && name.isNotEmpty) ? name : null;
        _printerMac = (mac != null && mac.isNotEmpty) ? mac : null;
        _paperSize = paper;
        _isConnected = connected;
      });
    }
  }

  void _openPrinterDialog() async {
    final updated = await Get.dialog<bool>(const BluetoothPrinterDialog());
    if (updated == true || mounted) {
      _loadPrinterSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPrinter = _printerMac != null && _printerMac!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.print_rounded, color: AppColors.primaryLight, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thermal Bluetooth Printer',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ESC/POS 58mm / 80mm wireless receipt printing',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (hasPrinter)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_isConnected ? AppColors.success : AppColors.secondary).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_isConnected ? AppColors.success : AppColors.secondary).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    _isConnected ? 'Connected' : 'Paired',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isConnected ? AppColors.success : AppColors.secondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBgLight.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                Icon(
                  hasPrinter ? Icons.bluetooth_connected_rounded : Icons.bluetooth_searching_rounded,
                  size: 22,
                  color: hasPrinter ? AppColors.primaryLight : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasPrinter ? (_printerName ?? 'Bluetooth Printer') : 'No Bluetooth Printer Configured',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: hasPrinter ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasPrinter
                            ? 'MAC: $_printerMac • Width: ${_paperSize == 'mm58' ? "58mm Mini" : "80mm Standard"}'
                            : 'Pair and select your thermal slip printer for direct POS voucher printing.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openPrinterDialog,
              icon: const Icon(Icons.settings_bluetooth_rounded, size: 18),
              label: Text(hasPrinter ? 'Manage Printer / Test Slip' : 'Setup Bluetooth Printer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
