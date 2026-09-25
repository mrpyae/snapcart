import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_colors.dart';
import '../../../Controller/AppController.dart';
import 'account_selection_dialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AppController appController = Get.find<AppController>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar('Input Required', 'Please enter username and password',
          backgroundColor: Colors.amber.withOpacity(0.8), colorText: Colors.black);
      return;
    }

    final success = await appController.authentication(username, password);
    if (success) {
      final user = appController.currentUser.value;
      if (user != null && user.accounts.length > 1) {
        Get.dialog(AccountSelectionDialog(accounts: user.accounts), barrierDismissible: false);
      } else {
        Get.offAllNamed(Routes.HOME);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Container(
            width: isMobile ? screenWidth * 0.92 : 440,
            constraints: const BoxConstraints(maxWidth: 440),
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Network Status Indicator & Mode Switch
                Align(
                  alignment: Alignment.topRight,
                  child: Obx(() {
                    final mode = appController.operationMode.value;
                    final isOnline = appController.isOnline.value;

                    Color badgeColor;
                    String badgeLabel;
                    IconData badgeIcon;

                    switch (mode) {
                      case OperationMode.offlineOnly:
                        badgeColor = AppColors.offline;
                        badgeLabel = 'Offline Only';
                        badgeIcon = Icons.cloud_off_rounded;
                        break;
                      case OperationMode.onlineOnly:
                        if (isOnline) {
                          badgeColor = AppColors.online;
                          badgeLabel = 'Online Only';
                          badgeIcon = Icons.cloud_done_rounded;
                        } else {
                          badgeColor = AppColors.error;
                          badgeLabel = 'Online (Offline!)';
                          badgeIcon = Icons.wifi_off_rounded;
                        }
                        break;
                      case OperationMode.hybrid:
                      default:
                        if (isOnline) {
                          badgeColor = AppColors.online;
                          badgeLabel = 'Hybrid (Online)';
                          badgeIcon = Icons.cloud_sync_rounded;
                        } else {
                          badgeColor = AppColors.offline;
                          badgeLabel = 'Hybrid (Offline)';
                          badgeIcon = Icons.wifi_off_rounded;
                        }
                        break;
                    }

                    return Tooltip(
                      message: 'Tap to switch Operation Mode (Hybrid / Online / Offline)',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showOperationModeSelectorDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: badgeColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                badgeIcon,
                                size: 14,
                                color: badgeColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                badgeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 15,
                                color: badgeColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                // Brand Header
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/snapcartlogo.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SnapCart POS',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Textile & Retail POS System',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),

                // Username Input
                const Text('Username / Phone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: AppColors.textMuted),
                    hintText: 'Enter username or phone number',
                  ),
                ),
                const SizedBox(height: 18),

                // Password Input
                const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted),
                    hintText: 'Enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 28),

                // Login Button
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Obx(() => ElevatedButton(
                      onPressed: appController.isLoading.value ? null : _handleLogin,
                      child: appController.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Sign In to POS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    )),
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Login Helper Chips
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _usernameController.text = 'admin';
                          _passwordController.text = '123456';
                          _handleLogin();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: const Text('Fill Admin (admin)', style: TextStyle(fontSize: 11, color: AppColors.primaryLight)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _usernameController.text = 'cashier';
                          _passwordController.text = '123456';
                          _handleLogin();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: const Text('Fill Cashier (cashier)', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Default Password: "password" or "123456"',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOperationModeSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text('Select Operation Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Obx(() {
              final currentMode = appController.operationMode.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLoginModeTile(
                    title: 'Both Offline + Online (Hybrid)',
                    subtitle: 'Local SQLite with auto-sync when online. (Recommended)',
                    icon: Icons.cloud_sync_rounded,
                    color: AppColors.primary,
                    isSelected: currentMode == OperationMode.hybrid,
                    onTap: () {
                      appController.setOperationMode(OperationMode.hybrid);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildLoginModeTile(
                    title: 'Online Use Only',
                    subtitle: 'Requires active server connection. Offline fallback disabled.',
                    icon: Icons.cloud_done_rounded,
                    color: const Color(0xFF0284C7),
                    isSelected: currentMode == OperationMode.onlineOnly,
                    onTap: () {
                      appController.setOperationMode(OperationMode.onlineOnly);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildLoginModeTile(
                    title: 'Offline Only (Standalone)',
                    subtitle: 'Pure local SQLite storage. All server calls disabled.',
                    icon: Icons.cloud_off_rounded,
                    color: AppColors.offline,
                    isSelected: currentMode == OperationMode.offlineOnly,
                    onTap: () {
                      appController.setOperationMode(OperationMode.offlineOnly);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginModeTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppColors.cardBgLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isSelected ? color : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
