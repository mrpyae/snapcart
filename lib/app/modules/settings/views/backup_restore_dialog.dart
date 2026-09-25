import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/backup_restore_service.dart';

// Controllers to refresh on restore
import '../../categories/controllers/category_controller.dart';
import '../../customer_orders/controllers/customer_order_controller.dart';
import '../../customers/controllers/customer_controller.dart';
import '../../delivery_services/controllers/delivery_service_controller.dart';
import '../../expenses/controllers/expense_controller.dart';
import '../../pos/controllers/pos_controller.dart';
import '../../products/controllers/product_controller.dart';
import '../../purchase/controllers/purchase_controller.dart';
import '../../suppliers/controllers/supplier_controller.dart';

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({Key? key}) : super(key: key);

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BackupRestoreService _backupService = BackupRestoreService.instance;

  List<BackupFileInfo> _backups = [];
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = true;

  // Restore inspection state for external file tab
  String? _selectedExternalFilePath;
  BackupInspectionResult? _externalInspection;
  bool _isInspecting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBackups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    final list = await _backupService.getLocalBackups();
    if (mounted) {
      setState(() {
        _backups = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackupNow({bool exportToFolder = false}) async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    String? customDir;
    if (exportToFolder) {
      final selectedDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select destination folder for backup',
      );
      if (selectedDir == null) {
        setState(() => _isLoading = false);
        return;
      }
      customDir = selectedDir;
    }

    final res = await _backupService.createBackup(customDestinationDir: customDir);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = res.success;
        _statusMessage = res.message;
      });
      await _loadBackups();

      if (res.success) {
        Get.snackbar(
          'Backup Created',
          res.message,
          backgroundColor: AppColors.success.withOpacity(0.9),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }

  Future<void> _pickAndInspectExternalFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select SnapCart SQLite Backup (.db)',
      );

      if (result == null || result.files.single.path == null) return;

      final path = result.files.single.path!;

      setState(() {
        _selectedExternalFilePath = path;
        _isInspecting = true;
        _externalInspection = null;
        _statusMessage = null;
      });

      final inspection = await _backupService.inspectBackupFile(path);

      if (mounted) {
        setState(() {
          _isInspecting = false;
          _externalInspection = inspection;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInspecting = false;
          _statusMessage = 'Failed to inspect file: $e';
          _isSuccess = false;
        });
      }
    }
  }

  void _promptConfirmRestore(String filePath, {BackupInspectionResult? previewInspection}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.warning, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            SizedBox(width: 10),
            Text('Confirm Restore Database',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restoring this backup will REPLACE your current offline database with the records from the backup file.',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Automatic Safety Rollback:',
                      style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text(
                    'SnapCart will create a safety snapshot before replacing. If any error occurs, your data will revert automatically.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  if (previewInspection != null) ...[
                    const Divider(color: AppColors.border, height: 16),
                    Text('• Products: ${previewInspection.productsCount}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                    Text('• Sales Invoices: ${previewInspection.salesCount}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                    Text('• Customers: ${previewInspection.customersCount}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeRestore(filePath);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Proceed & Restore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeRestore(String filePath) async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final res = await _backupService.restoreDatabase(filePath);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = res.success;
        _statusMessage = res.message;
      });

      if (res.success) {
        _refreshActiveControllers();
        Navigator.pop(context); // Close main dialog

        Get.snackbar(
          'Database Restored Successfully',
          'Your offline database has been restored from backup. All views updated.',
          backgroundColor: AppColors.success.withOpacity(0.95),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }

  void _refreshActiveControllers() {
    try {
      if (Get.isRegistered<ProductController>()) Get.find<ProductController>().loadProducts();
      if (Get.isRegistered<CategoryController>()) Get.find<CategoryController>().loadCategories();
      if (Get.isRegistered<CustomerController>()) Get.find<CustomerController>().loadCustomers();
      if (Get.isRegistered<SupplierController>()) Get.find<SupplierController>().loadSuppliers();
      if (Get.isRegistered<PurchaseController>()) Get.find<PurchaseController>().loadPurchases();
      if (Get.isRegistered<ExpenseController>()) Get.find<ExpenseController>().loadExpenses();
      if (Get.isRegistered<DeliveryServiceController>()) Get.find<DeliveryServiceController>().loadServices();
      if (Get.isRegistered<CustomerOrderController>()) Get.find<CustomerOrderController>().loadOrders();
      if (Get.isRegistered<POSController>()) Get.find<POSController>().loadProducts();
    } catch (_) {}
  }

  Future<void> _deleteBackupFile(String filePath) async {
    final deleted = await _backupService.deleteBackup(filePath);
    if (deleted) {
      await _loadBackups();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_backup_restore_rounded,
                        color: AppColors.primaryLight, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SQLite Database Backup & Restore',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('Create atomic snapshots or restore previous database files',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primaryLight,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(icon: Icon(Icons.backup_rounded, size: 18), text: 'Create & History'),
                  Tab(icon: Icon(Icons.restore_page_rounded, size: 18), text: 'Restore External .db'),
                ],
              ),
              const SizedBox(height: 12),

              // Status message banner
              if (_statusMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (_isSuccess ? AppColors.success : AppColors.error).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_isSuccess ? AppColors.success : AppColors.error).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          color: _isSuccess ? AppColors.success : AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _isSuccess ? AppColors.success : AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCreateAndHistoryTab(isMobile),
                    _buildRestoreExternalTab(isMobile),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAndHistoryTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _createBackupNow(exportToFolder: false),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_isLoading ? 'Saving...' : 'Backup Now (Default Dir)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _createBackupNow(exportToFolder: true),
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Export to Folder...'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Local Backup History (${_backups.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            IconButton(
              tooltip: 'Refresh list',
              onPressed: _isLoading ? null : _loadBackups,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),

        Expanded(
          child: _backups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      const Text('No backups found in local storage.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('Click "Backup Now" to create your first backup.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _backups.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (context, index) {
                    final item = _backups[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storage_rounded, size: 22, color: AppColors.primaryLight),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.fileName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${item.formattedDate} • ${item.formattedSize}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quick inspect and restore button
                          TextButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    final insp = await _backupService.inspectBackupFile(item.filePath);
                                    if (mounted) {
                                      _promptConfirmRestore(item.filePath, previewInspection: insp);
                                    }
                                  },
                            icon: const Icon(Icons.settings_backup_restore_rounded, size: 16),
                            label: const Text('Restore', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryLight,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                          // Delete button
                          IconButton(
                            tooltip: 'Delete Backup',
                            onPressed: _isLoading ? null : () => _deleteBackupFile(item.filePath),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRestoreExternalTab(bool isMobile) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select an external SQLite .db backup file from your computer or storage drive to restore:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // File picker trigger
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_isLoading || _isInspecting) ? null : _pickAndInspectExternalFile,
              icon: _isInspecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                    )
                  : const Icon(Icons.file_open_rounded, size: 18),
              label: Text(_isInspecting ? 'Inspecting Database...' : 'Browse & Pick .db File'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Inspection Result Card
          if (_externalInspection != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _externalInspection!.isValid
                    ? AppColors.cardBgLight.withOpacity(0.5)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _externalInspection!.isValid
                      ? AppColors.border
                      : AppColors.error.withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _externalInspection!.isValid
                            ? Icons.verified_rounded
                            : Icons.gpp_bad_rounded,
                        color: _externalInspection!.isValid ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _externalInspection!.isValid
                            ? 'Valid SQLite Database Verified'
                            : 'Inspection Failed',
                        style: TextStyle(
                          color: _externalInspection!.isValid ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Path: ${_selectedExternalFilePath ?? ""}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text('Size: ${_externalInspection!.formattedSize}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const Divider(color: AppColors.border, height: 16),

                  if (_externalInspection!.isValid) ...[
                    const Text('Contents Preview:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildStatChip(Icons.shopping_bag_outlined, 'Products', _externalInspection!.productsCount),
                        _buildStatChip(Icons.receipt_long_outlined, 'Sales Orders', _externalInspection!.salesCount),
                        _buildStatChip(Icons.delivery_dining_outlined, 'Customer Orders', _externalInspection!.ordersCount),
                        _buildStatChip(Icons.people_outline, 'Customers', _externalInspection!.customersCount),
                        _buildStatChip(Icons.admin_panel_settings_outlined, 'Users', _externalInspection!.usersCount),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _promptConfirmRestore(
                                  _selectedExternalFilePath!,
                                  previewInspection: _externalInspection,
                                ),
                        icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                        label: const Text('Confirm & Restore This Backup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      _externalInspection!.errorMessage ?? 'Unknown error inspecting database.',
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryLight),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
