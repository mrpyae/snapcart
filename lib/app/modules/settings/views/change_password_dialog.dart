import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Controller/AppController.dart';
import '../../../data/models/user_model.dart';
import '../../../data/local/user_dao.dart';
import '../../../utils/app_colors.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({Key? key}) : super(key: key);

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final UserDao _userDao = UserDao();
  final AppController _appController = Get.find<AppController>();

  bool _isLoading = true;
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  UserAccountModel? _selectedAccount;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();

  bool _obscurePassword = false; // Default visible so owner can see plain text!
  bool _obscureConfirmPassword = false;
  bool _obscurePasscode = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final list = await _userDao.getAllUsersWithAccounts();
      setState(() {
        _users = list;
        final currentUserId = _appController.currentUser.value?.id;
        final currentAccId = _appController.currentAccount.value?.id;

        if (list.isNotEmpty) {
          _selectedUser = list.firstWhereOrNull((u) => u.id == currentUserId) ?? list.first;
          if (_selectedUser!.accounts.isNotEmpty) {
            _selectedAccount = _selectedUser!.accounts.firstWhereOrNull((a) => a.id == currentAccId) ?? _selectedUser!.accounts.first;
            _passcodeController.text = _selectedAccount!.passcode ?? '';
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load user accounts: $e';
      });
    }
  }

  void _onUserChanged(UserModel? user) {
    if (user == null) return;
    setState(() {
      _selectedUser = user;
      _selectedAccount = user.accounts.isNotEmpty ? user.accounts.first : null;
      _passcodeController.text = _selectedAccount?.passcode ?? '';
      _passwordController.clear();
      _confirmPasswordController.clear();
      _errorMessage = null;
    });
  }

  void _onAccountChanged(UserAccountModel? acc) {
    if (acc == null) return;
    setState(() {
      _selectedAccount = acc;
      _passcodeController.text = acc.passcode ?? '';
      _errorMessage = null;
    });
  }

  Future<void> _submitChanges() async {
    setState(() => _errorMessage = null);

    if (_selectedUser == null || _selectedAccount == null) {
      setState(() => _errorMessage = 'Please select a valid user account.');
      return;
    }

    final newPass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();
    final newPasscode = _passcodeController.text.trim();

    if (newPass.isNotEmpty && newPass != confirmPass) {
      setState(() => _errorMessage = 'Passwords do not match. Please re-check.');
      return;
    }

    if (newPasscode.isNotEmpty) {
      if (newPasscode.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPasscode)) {
        setState(() => _errorMessage = 'Passcode must be exactly 4 numeric digits (e.g. 1234).');
        return;
      }
    }

    if (newPass.isEmpty && newPasscode.isEmpty) {
      setState(() => _errorMessage = 'Please enter a new password or passcode to update.');
      return;
    }

    setState(() => _isLoading = true);

    final success = await _appController.changeUserPasswordAndPasscode(
      userId: _selectedUser!.id,
      accountId: _selectedAccount!.id,
      newPassword: newPass,
      newPasscode: newPasscode,
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop();
      Get.snackbar(
        'Success',
        'Credentials updated successfully! Stored as plain text without encryption.',
        backgroundColor: Colors.teal.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      );
    } else {
      setState(() => _errorMessage = 'Failed to update credentials. Please try again.');
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(22),
        child: _isLoading
            ? const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.password_rounded, color: Colors.amber, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Manage User Password & Passcode',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Owner Access • Plain text (No encryption)',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // User selection dropdown
                    const Text('Select User Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UserModel>(
                          isExpanded: true,
                          dropdownColor: AppColors.cardBg,
                          value: _selectedUser,
                          items: _users.map((u) {
                            return DropdownMenuItem<UserModel>(
                              value: u,
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.primaryLight),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${u.name} (@${u.username})',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _onUserChanged,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Account / Branch selection (if user has accounts)
                    if (_selectedUser != null && _selectedUser!.accounts.isNotEmpty) ...[
                      const Text('Select Branch Profile / Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<UserAccountModel>(
                            isExpanded: true,
                            dropdownColor: AppColors.cardBg,
                            value: _selectedAccount,
                            items: _selectedUser!.accounts.map((a) {
                              final isOwner = a.roleName.toLowerCase() == 'owner' || a.roleName.toLowerCase() == 'admin';
                              return DropdownMenuItem<UserAccountModel>(
                                value: a,
                                child: Row(
                                  children: [
                                    Icon(
                                      isOwner ? Icons.shield_rounded : Icons.badge_outlined,
                                      size: 16,
                                      color: isOwner ? Colors.amber : AppColors.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${a.branchName} (${a.roleName.toUpperCase()})',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isOwner ? FontWeight.bold : FontWeight.normal,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: _onAccountChanged,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // New Login Password Input
                    const Text('New Login Password (Plain Text)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter new login password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Confirm Login Password Input
                    const Text('Confirm New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Re-enter new password to confirm',
                        prefixIcon: const Icon(Icons.lock_reset_rounded, size: 18, color: AppColors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4-Digit Passcode Input (PIN for Owner Authorization)
                    Row(
                      children: const [
                        Text('4-Digit Authorization Passcode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        SizedBox(width: 6),
                        Text('(Voucher Edit/Void PIN)', style: TextStyle(fontSize: 10, color: Colors.amber)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passcodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: _obscurePasscode,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 3, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. 1234',
                        counterText: '',
                        prefixIcon: const Icon(Icons.pin_rounded, size: 18, color: Colors.amber),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePasscode ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePasscode = !_obscurePasscode),
                        ),
                      ),
                    ),

                    // Error Message display
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _submitChanges,
                            icon: const Icon(Icons.save_rounded, size: 16),
                            label: const Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
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
