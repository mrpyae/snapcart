import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Controller/AppController.dart';
import '../../../Util/AppConstants.dart';
import '../../../data/local/data_cleanup_dao.dart';
import '../../../data/providers/api_provider.dart';
import '../../../utils/app_colors.dart';

// Controllers to refresh if registered
import '../../categories/controllers/category_controller.dart';
import '../../customer_orders/controllers/customer_order_controller.dart';
import '../../customers/controllers/customer_controller.dart';
import '../../delivery_services/controllers/delivery_service_controller.dart';
import '../../expenses/controllers/expense_controller.dart';
import '../../pos/controllers/pos_controller.dart';
import '../../products/controllers/product_controller.dart';
import '../../purchase/controllers/purchase_controller.dart';
import '../../suppliers/controllers/supplier_controller.dart';

class DataCleanupDialog extends StatefulWidget {
  const DataCleanupDialog({Key? key}) : super(key: key);

  @override
  State<DataCleanupDialog> createState() => _DataCleanupDialogState();
}

class _DataCleanupDialogState extends State<DataCleanupDialog> {
  final TextEditingController _passcodeController = TextEditingController();
  final DataCleanupDao _cleanupDao = DataCleanupDao();
  final ApiProvider _apiProvider = ApiProvider();

  bool _obscurePasscode = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Scope selection
  bool _deleteOffline = true;
  bool _deleteOnline = true;

  // Module checklist
  final Map<String, bool> _selectedModules = {
    'sales': true,
    'customer_orders': true,
    'purchases': true,
    'products': true,
    'categories': true,
    'customers': true,
    'suppliers': true,
    'expenses': true,
    'delivery_services': true,
    'users': true,
  };

  final Map<String, Map<String, dynamic>> _moduleInfo = {
    'sales': {
      'title': 'Sales & POS Invoices',
      'desc': 'Sales orders, item vouchers, debt repayments & held carts',
      'icon': Icons.point_of_sale_rounded,
    },
    'customer_orders': {
      'title': 'Custom Customer Orders',
      'desc': 'Loom weaving & custom tailoring orders and items',
      'icon': Icons.design_services_rounded,
    },
    'purchases': {
      'title': 'Purchases & Stock Receiving',
      'desc': 'Supplier purchase orders, receiving items & payments',
      'icon': Icons.shopping_bag_rounded,
    },
    'products': {
      'title': 'Products & Inventory',
      'desc': 'Product catalog, stock balances & supplier mappings',
      'icon': Icons.inventory_2_rounded,
    },
    'categories': {
      'title': 'Product Categories',
      'desc': 'All category classifications',
      'icon': Icons.category_rounded,
    },
    'customers': {
      'title': 'Customers & Receivables',
      'desc': 'Customer records, contact information & debt profiles',
      'icon': Icons.people_alt_rounded,
    },
    'suppliers': {
      'title': 'Suppliers & Payables',
      'desc': 'Vendor profiles, company information & payable balances',
      'icon': Icons.storefront_rounded,
    },
    'expenses': {
      'title': 'Expenses & Operational Costs',
      'desc': 'Daily expense vouchers and categorization logs',
      'icon': Icons.receipt_long_rounded,
    },
    'delivery_services': {
      'title': 'Delivery Services & Couriers',
      'desc': 'Courier partners, in-house riders & delivery remittances',
      'icon': Icons.local_shipping_rounded,
    },
    'users': {
      'title': 'Staff / Cashier Accounts',
      'desc': 'Non-admin cashiers & accounts (Default Admin usr-admin-001 is kept)',
      'icon': Icons.badge_rounded,
    },
  };

  static const String _requiredPasscode = '092051590';

  bool get _allSelected => _selectedModules.values.every((v) => v);

  void _toggleSelectAll() {
    final targetState = !_allSelected;
    setState(() {
      _selectedModules.updateAll((key, value) => targetState);
    });
  }

  void _confirmAndDelete() {
    final entered = _passcodeController.text.trim();

    if (entered != _requiredPasscode) {
      setState(() {
        _errorMessage = 'Incorrect permission password. Access denied.';
      });
      return;
    }

    if (!_deleteOffline && !_deleteOnline) {
      setState(() {
        _errorMessage = 'Please select at least one database target (Offline or Online).';
      });
      return;
    }

    final chosen = _selectedModules.entries.where((e) => e.value).map((e) => e.key).toList();
    if (chosen.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one data category to delete.';
      });
      return;
    }

    // Show secondary confirmation modal
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 10),
            Text('Confirm Data Deletion', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you absolutely sure you want to permanently delete the selected data?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Targets: ${_deleteOffline ? "Offline SQLite" : ""}${(_deleteOffline && _deleteOnline) ? " & " : ""}${_deleteOnline ? "Online MySQL Server" : ""}',
                    style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '• Categories: ${chosen.length} module(s) selected',
                    style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    '• Default Admin account (usr-admin-001) will remain SAFE.',
                    style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // close confirm dialog
              _executeDeletion(chosen);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Yes, Permanently Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDeletion(List<String> chosenModules) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final AppController appController = Get.find<AppController>();
    final bizId = appController.currentAccount.value?.businessId ?? AppConstants.defaultBusinessId;

    bool offlineSuccess = true;
    bool onlineSuccess = true;
    String onlineMessage = '';

    try {
      // 1. Delete Offline SQLite data
      if (_deleteOffline) {
        await _cleanupDao.deleteSelectedData(chosenModules);
      }

      // 2. Delete Online MySQL data
      if (_deleteOnline) {
        final res = await _apiProvider.deleteServerData(
          permissionPassword: _requiredPasscode,
          modules: chosenModules,
          businessId: bizId,
        );

        if (res['status'] == 'success') {
          onlineSuccess = true;
          onlineMessage = res['message'] ?? 'Online data cleared successfully';
        } else {
          onlineSuccess = false;
          onlineMessage = res['message'] ?? 'Online server deletion failed';
        }
      }

      // 3. Refresh any active controllers
      _refreshActiveControllers();

      // Close main dialog
      Get.back();

      // Show outcome notification
      if (offlineSuccess && (_deleteOnline ? onlineSuccess : true)) {
        Get.snackbar(
          'Data Deletion Successful',
          'Selected modules have been deleted. Default Admin account was preserved.',
          backgroundColor: AppColors.success.withOpacity(0.9),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      } else {
        Get.snackbar(
          'Partial Deletion Result',
          'Offline deleted: $offlineSuccess. Online server: $onlineMessage',
          backgroundColor: AppColors.warning.withOpacity(0.9),
          colorText: Colors.white,
          icon: const Icon(Icons.warning_rounded, color: Colors.white),
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Deletion error: $e';
      });
    }
  }

  void _refreshActiveControllers() {
    try {
      if (Get.isRegistered<ProductController>()) {
        Get.find<ProductController>().loadProducts();
      }
      if (Get.isRegistered<CategoryController>()) {
        Get.find<CategoryController>().loadCategories();
      }
      if (Get.isRegistered<CustomerController>()) {
        Get.find<CustomerController>().loadCustomers();
      }
      if (Get.isRegistered<SupplierController>()) {
        Get.find<SupplierController>().loadSuppliers();
      }
      if (Get.isRegistered<PurchaseController>()) {
        Get.find<PurchaseController>().loadPurchases();
      }
      if (Get.isRegistered<ExpenseController>()) {
        Get.find<ExpenseController>().loadExpenses();
      }
      if (Get.isRegistered<DeliveryServiceController>()) {
        Get.find<DeliveryServiceController>().loadServices();
      }
      if (Get.isRegistered<CustomerOrderController>()) {
        Get.find<CustomerOrderController>().loadOrders();
      }
      if (Get.isRegistered<POSController>()) {
        Get.find<POSController>().loadProducts();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: isMobile ? 16 : 30,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Container(
        width: 680,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Data Delete / Database Reset',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Requires permission password. Admin account (usr-admin-001) will be preserved.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : () => Get.back(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 24),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Permission Password Input
                    const Text(
                      'Enter Permission Password *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passcodeController,
                      obscureText: _obscurePasscode,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.cardBg,
                        hintText: 'Enter permission password to authorize',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.error, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePasscode ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePasscode = !_obscurePasscode;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Target Databases (Scope)
                    const Text(
                      'Target Databases',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: AppColors.error,
                            title: const Text('Offline Local Database (SQLite)', style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Deletes local cached records on this device', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            value: _deleteOffline,
                            onChanged: (val) {
                              setState(() {
                                _deleteOffline = val ?? false;
                              });
                            },
                          ),
                          const Divider(color: AppColors.border, height: 1),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: AppColors.error,
                            title: const Text('Online Central Server (MySQL via API)', style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Deletes data from the main central MySQL database', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            value: _deleteOnline,
                            onChanged: (val) {
                              setState(() {
                                _deleteOnline = val ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Multi-Select Data Modules Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Data Categories to Delete',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        TextButton.icon(
                          onPressed: _toggleSelectAll,
                          icon: Icon(
                            _allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                            size: 16,
                            color: AppColors.primaryLight,
                          ),
                          label: Text(
                            _allSelected ? 'Deselect All' : 'Select All',
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Checklist cards
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedModules.length,
                        separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (context, index) {
                          final key = _selectedModules.keys.elementAt(index);
                          final isChecked = _selectedModules[key] ?? false;
                          final info = _moduleInfo[key] ?? {
                            'title': key,
                            'desc': '',
                            'icon': Icons.circle_outlined,
                          };

                          return CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            dense: true,
                            activeColor: AppColors.error,
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isChecked ? AppColors.error : AppColors.cardBgLight).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                info['icon'] as IconData,
                                size: 18,
                                color: isChecked ? AppColors.error : AppColors.textSecondary,
                              ),
                            ),
                            title: Text(
                              info['title'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isChecked ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                            ),
                            subtitle: Text(
                              info['desc'] as String,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            value: isChecked,
                            onChanged: (val) {
                              setState(() {
                                _selectedModules[key] = val ?? false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Safe admin notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_rounded, color: AppColors.success, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Admin Security Guarantee: The default Administrator account (usr-admin-001) will not be removed.',
                              style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(color: AppColors.border, height: 24),

            // Footer Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _confirmAndDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 18),
                    label: Text(
                      _isLoading ? 'Deleting Data...' : 'Delete Selected Data',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
