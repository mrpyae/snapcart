import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_colors.dart';
import '../../../Controller/AppController.dart';
import '../../../routes/app_routes.dart';
import '../../customers/views/customer_view.dart';
import '../../customer_orders/views/customer_order_view.dart';
import '../../expenses/views/expense_view.dart';
import '../../pos/views/pos_view.dart';
import '../../products/views/product_list_view.dart';
import '../../purchase/views/purchase_view.dart';
import '../../reports/views/report_view.dart';
import '../../settings/views/settings_view.dart';
import '../../suppliers/views/supplier_view.dart';
import '../../delivery_services/views/delivery_service_view.dart';
import '../../auth/views/account_selection_dialog.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final AppController appController = Get.find<AppController>();
  int _selectedIndex = 0;

  // Maps bottom-nav slot (0–3) → menuItems index
  static const List<int> _bottomNavIndexMap = [0, 2, 5, 8]; // POS, Products, Customers(AR), Reports

  int get _bottomNavCurrentIndex {
    final idx = _bottomNavIndexMap.indexOf(_selectedIndex);
    return idx == -1 ? 0 : idx;
  }
  final List<Map<String, dynamic>> menuItems = [
    {'title': 'POS Counter', 'title_key': 'menu_pos', 'icon': Icons.point_of_sale_rounded, 'perm': 'pos_sale', 'view': const POSView()},
    {'title': 'Orders & Appointments', 'title_key': 'menu_orders', 'icon': Icons.event_note_rounded, 'perm': 'pos_sale', 'view': const CustomerOrderView()},
    {'title': 'Products', 'title_key': 'menu_products', 'icon': Icons.inventory_2_rounded, 'perm': 'manage_products', 'view': const ProductListView()},
    {'title': 'Purchases & Stock In', 'title_key': 'menu_purchases', 'icon': Icons.add_shopping_cart_rounded, 'perm': 'manage_stock', 'view': const PurchaseView()},
    {'title': 'Suppliers (AP)', 'title_key': 'menu_suppliers', 'icon': Icons.local_shipping_rounded, 'perm': 'manage_stock', 'view': const SupplierView()},
    {'title': 'Customers (AR)', 'title_key': 'menu_customers', 'icon': Icons.people_alt_rounded, 'perm': 'pos_sale', 'view': const CustomerView()},
    {'title': 'Delivery Services', 'title_key': 'menu_delivery', 'icon': Icons.delivery_dining_rounded, 'perm': 'pos_sale', 'view': const DeliveryServiceView()},
    {'title': 'Expenses', 'title_key': 'menu_expenses', 'icon': Icons.receipt_long_rounded, 'perm': 'manage_expenses', 'view': const ExpenseView()},
    {'title': 'Reports', 'title_key': 'menu_reports', 'icon': Icons.bar_chart_rounded, 'perm': 'view_reports', 'view': const ReportView()},
    {'title': 'Settings', 'title_key': 'menu_settings', 'icon': Icons.settings_rounded, 'perm': null, 'view': const SettingsView()},
  ];

  void _confirmLogout(BuildContext context, AppController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // MOBILE & TABLET LAYOUT (< 768px)
    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.cardBg,
          elevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/snapcartlogo.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SnapCart POS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Obx(() => Text(
                      appController.currentAccount.value?.branchName ?? 'Counter',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Instant Sync with MySQL Button
            Obx(() => IconButton(
              icon: appController.isSyncing.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                    )
                  : const Icon(Icons.sync_rounded, size: 20, color: AppColors.primaryLight),
              tooltip: 'Sync with Localhost MySQL Database',
              onPressed: appController.isSyncing.value
                  ? null
                  : () async {
                      final ok = await appController.triggerAutoSync();
                      Get.snackbar(
                        ok ? 'Sync Complete' : 'Sync Notice',
                        ok ? 'All data successfully synchronized with Localhost MySQL!' : 'Sync completed or MySQL server unreachable',
                        backgroundColor: ok ? AppColors.primary : Colors.amber.shade800,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 3),
                      );
                    },
            )),
            // Status Indicator (Online/Offline/Modes)
            Obx(() {
              final mode = appController.operationMode.value;
              final isOnline = appController.isOnline.value;

              Color statusColor;
              String statusText;
              IconData statusIcon;

              switch (mode) {
                case OperationMode.offlineOnly:
                  statusColor = AppColors.offline;
                  statusText = 'Offline Only';
                  statusIcon = Icons.cloud_off_rounded;
                  break;
                case OperationMode.onlineOnly:
                  if (isOnline) {
                    statusColor = AppColors.online;
                    statusText = 'Online Only';
                    statusIcon = Icons.cloud_done_rounded;
                  } else {
                    statusColor = AppColors.error;
                    statusText = 'Online (Offline!)';
                    statusIcon = Icons.cloud_off_rounded;
                  }
                  break;
                case OperationMode.hybrid:
                default:
                  if (isOnline) {
                    statusColor = AppColors.online;
                    statusText = 'Hybrid (Online)';
                    statusIcon = Icons.cloud_sync_rounded;
                  } else {
                    statusColor = AppColors.offline;
                    statusText = 'Hybrid (Offline)';
                    statusIcon = Icons.cloud_queue_rounded;
                  }
                  break;
              }

              return Tooltip(
                message: 'Operating Mode: $statusText\nClick to configure in Settings & Sync Hub',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final idx = menuItems.indexWhere((m) => m['title'] == 'Settings');
                    if (idx != -1) {
                      setState(() {
                        _selectedIndex = idx;
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            // Account Switcher / Login / Logout Actions
            Obx(() {
              final user = appController.currentUser.value;
              if (user == null) {
                // User is NOT logged in -> Show Log In Button
                return TextButton.icon(
                  onPressed: () => Get.toNamed(Routes.LOGIN),
                  icon: const Icon(Icons.login_rounded, size: 16, color: AppColors.primaryLight),
                  label: const Text('Log In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                );
              }

              // User IS logged in -> Show Account Switcher & Logout
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user.accounts.length > 1)
                    IconButton(
                      icon: const Icon(Icons.switch_account_rounded, size: 19, color: AppColors.textSecondary),
                      tooltip: 'Switch Account Profile',
                      onPressed: () => Get.dialog(AccountSelectionDialog(accounts: user.accounts)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 19, color: AppColors.error),
                    tooltip: 'Log Out (${user.name})',
                    onPressed: () => _confirmLogout(context, appController),
                  ),
                ],
              );
            }),
            const SizedBox(width: 4),
          ],
        ),
        drawer: Drawer(
          backgroundColor: AppColors.cardBg,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/snapcartlogo.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('SnapCart Textile POS', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    Obx(() => Text(
                      'User: ${appController.currentUser.value?.name ?? "Staff"} (${appController.currentAccount.value?.roleName ?? "Cashier"})',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    )),
                  ],
                ),
              ),
              ...List.generate(menuItems.length, (index) {
                final item = menuItems[index];
                final isSelected = _selectedIndex == index;
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: AppColors.primary.withOpacity(0.18),
                  leading: Icon(
                    item['icon'] as IconData,
                    color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                  ),
                  title: Obx(() => Text(
                    (item['title_key'] as String?)?.tr ?? (item['title'] as String),
                    style: TextStyle(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  )),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.of(context).pop();
                  },
                );
              }),
              const Divider(),
              Obx(() {
                final user = appController.currentUser.value;
                if (user == null) {
                  return ListTile(
                    leading: const Icon(Icons.login_rounded, color: AppColors.primaryLight),
                    title: const Text('Log In to Account', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.toNamed(Routes.LOGIN);
                    },
                  );
                }
                return ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: Text('Log Out (${user.name})', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _confirmLogout(context, appController);
                  },
                );
              }),
            ],
          ),
        ),
        body: menuItems[_selectedIndex]['view'] as Widget,
        bottomNavigationBar: Obx(() => BottomNavigationBar(
          currentIndex: _bottomNavCurrentIndex,
          onTap: (idx) => setState(() => _selectedIndex = _bottomNavIndexMap[idx]),
          backgroundColor: AppColors.cardBg,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.point_of_sale_rounded), label: 'menu_pos'.tr),
            BottomNavigationBarItem(icon: const Icon(Icons.inventory_2_rounded), label: 'menu_products'.tr),
            BottomNavigationBarItem(icon: const Icon(Icons.people_alt_rounded), label: 'menu_customers'.tr),
            BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_rounded), label: 'menu_reports'.tr),
          ],
        )),
      );
    }

    // DESKTOP & TABLET LAYOUT (>= 768px)
    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR NAVIGATION
          Container(
            width: 230,
            color: AppColors.cardBg,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/snapcartlogo.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SnapCart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Obx(() => Text(
                            appController.currentAccount.value?.branchName ?? 'POS Terminal',
                            style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                // Navigation Items
                Expanded(
                  child: ListView.separated(
                    itemCount: menuItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final isSelected = _selectedIndex == index;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppColors.primary.withOpacity(0.18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        leading: Icon(
                          item['icon'] as IconData,
                          color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                          size: 20,
                        ),
                        title: Obx(() => Text(
                          (item['title_key'] as String?)?.tr ?? (item['title'] as String),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        )),
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),

                // Bottom Connectivity, Staff Badge & Auth Actions
                Obx(() {
                  final user = appController.currentUser.value;
                  if (user == null) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.toNamed(Routes.LOGIN),
                        icon: const Icon(Icons.login_rounded, size: 16),
                        label: const Text('Log In / Sign In'),
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: appController.isOfflineOnly
                                ? AppColors.offline
                                : (appController.isOnline.value ? AppColors.online : AppColors.offline),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                appController.currentAccount.value?.roleName.toUpperCase() ?? 'STAFF',
                                style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                          tooltip: 'Log Out',
                          onPressed: () => _confirmLogout(context, appController),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // VERTICAL SEPARATOR
          Container(width: 1, color: AppColors.border),

          // ACTIVE PAGE VIEW
          Expanded(
            child: menuItems[_selectedIndex]['view'] as Widget,
          ),
        ],
      ),
    );
  }
}
