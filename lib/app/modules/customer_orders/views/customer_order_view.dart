import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/customer_order_model.dart';
import '../../../data/models/delivery_service_model.dart';
import '../../../data/local/delivery_service_dao.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/supplier_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';
import '../controllers/customer_order_controller.dart';

class CustomerOrderView extends StatelessWidget {
  const CustomerOrderView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CustomerOrderController>()
        ? Get.find<CustomerOrderController>()
        : Get.put(CustomerOrderController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Header Cards
            _buildMetricsHeader(context, controller),
            const SizedBox(height: 14),

            // Search, Filter & Action Bar
            _buildFilterAndActionBar(context, controller),
            const SizedBox(height: 12),

            // Orders & Appointments List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 10),
                        Text(
                          'No customer orders or appointments found.',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: controller.orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = controller.orders[index];
                    return _buildOrderCard(context, order, controller);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // KPI Metrics Header
  Widget _buildMetricsHeader(BuildContext context, CustomerOrderController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        final isVerySmall = constraints.maxWidth < 380;
        return Obx(() {
          return GridView.count(
            crossAxisCount: isNarrow ? 2 : 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            childAspectRatio: isVerySmall ? 1.75 : (isNarrow ? 1.95 : 2.5),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMetricCard(
                title: "Today's Appointments",
                subTitle: isNarrow ? 'ယနေ့ရက်ချိန်း' : 'ယနေ့ရက်ချိန်းများ',
                value: '${controller.todayAppointmentsCount}',
                icon: Icons.event_available_rounded,
                color: Colors.blueAccent,
                isMobile: isNarrow,
              ),
              _buildMetricCard(
                title: 'In Progress (ရက်လုပ်ဆဲ)',
                subTitle: isNarrow ? 'ရက်လုပ်ဆဲ' : 'Loom Weaving',
                value: '${controller.inProgressCount}',
                icon: Icons.precision_manufacturing_rounded,
                color: Colors.amber.shade700,
                isMobile: isNarrow,
              ),
              _buildMetricCard(
                title: 'Ready for Pickup',
                subTitle: 'လာယူရန်အသင့်',
                value: '${controller.readyForPickupCount}',
                icon: Icons.inventory_rounded,
                color: Colors.teal,
                isMobile: isNarrow,
              ),
              _buildMetricCard(
                title: 'Advance Collected',
                subTitle: 'စရံငွေစုစုပေါင်း',
                value: Formatters.formatCurrency(controller.totalAdvanceDeposits),
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.green,
                isMobile: isNarrow,
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String subTitle,
    required String value,
    required IconData icon,
    required Color color,
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 17 : 20),
          ),
          SizedBox(width: isMobile ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subTitle,
                  style: TextStyle(
                    fontSize: isMobile ? 10.5 : 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filter and Action Bar
  Widget _buildFilterAndActionBar(BuildContext context, CustomerOrderController controller) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (isMobile)
            Column(
              children: [
                TextField(
                  onChanged: (v) {
                    controller.searchQuery.value = v.trim();
                    controller.loadOrders();
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search customer, phone, order no...',
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () => _showOrderFormDialog(context, controller),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('+ New Order (အမှာစာသစ်)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                // Search Input
                Expanded(
                  child: TextField(
                    onChanged: (v) {
                      controller.searchQuery.value = v.trim();
                      controller.loadOrders();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search by customer, phone, order no, lead account...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Create Order Button
                SizedBox(
                  width: 220,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => _showOrderFormDialog(context, controller),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('+ New Order (အမှာစာသစ်)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),

          // Date & Source Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date Filters
                Obx(() => Row(
                  children: [
                    _buildFilterChip('All Dates', controller.selectedDateFilter.value == 'ALL', () {
                      controller.selectedDateFilter.value = 'ALL';
                      controller.loadOrders();
                    }),
                    _buildFilterChip("Today (ယနေ့)", controller.selectedDateFilter.value == 'TODAY', () {
                      controller.selectedDateFilter.value = 'TODAY';
                      controller.loadOrders();
                    }, badgeColor: Colors.blue),
                    _buildFilterChip("Tomorrow (မနက်ဖြန်)", controller.selectedDateFilter.value == 'TOMORROW', () {
                      controller.selectedDateFilter.value = 'TOMORROW';
                      controller.loadOrders();
                    }),
                  ],
                )),
                const SizedBox(width: 10),
                Container(height: 18, width: 1, color: AppColors.border),
                const SizedBox(width: 10),

                // Status Filters
                Obx(() => Row(
                  children: [
                    _buildFilterChip('All Status', controller.selectedStatusFilter.value == 'ALL', () {
                      controller.selectedStatusFilter.value = 'ALL';
                      controller.loadOrders();
                    }),
                    _buildFilterChip('PENDING (စောင့်ဆိုင်းဆဲ)', controller.selectedStatusFilter.value == 'PENDING', () {
                      controller.selectedStatusFilter.value = 'PENDING';
                      controller.loadOrders();
                    }),
                    _buildFilterChip('CONFIRMED (အတည်ပြု)', controller.selectedStatusFilter.value == 'CONFIRMED', () {
                      controller.selectedStatusFilter.value = 'CONFIRMED';
                      controller.loadOrders();
                    }),
                    _buildFilterChip('IN_PROGRESS (ရက်လုပ်ဆဲ)', controller.selectedStatusFilter.value == 'IN_PROGRESS', () {
                      controller.selectedStatusFilter.value = 'IN_PROGRESS';
                      controller.loadOrders();
                    }),
                    _buildFilterChip('READY (လာယူရန်အသင့်)', controller.selectedStatusFilter.value == 'READY_FOR_PICKUP', () {
                      controller.selectedStatusFilter.value = 'READY_FOR_PICKUP';
                      controller.loadOrders();
                    }),
                    _buildFilterChip('COMPLETED (အပြီးသတ်)', controller.selectedStatusFilter.value == 'COMPLETED', () {
                      controller.selectedStatusFilter.value = 'COMPLETED';
                      controller.loadOrders();
                    }),
                  ],
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Supplier / Weaver Filter Tabs
          Obx(() {
            if (controller.suppliers.isEmpty) return const SizedBox.shrink();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Supplier / Weaver (ရက္ကန်း/ဆိုင်):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  _buildFilterChip('All Suppliers', controller.selectedSupplierFilter.value == 'ALL', () {
                    controller.selectedSupplierFilter.value = 'ALL';
                    controller.loadOrders();
                  }),
                  ...controller.suppliers.map((s) => _buildFilterChip(
                    s.name,
                    controller.selectedSupplierFilter.value == s.id,
                    () {
                      controller.selectedSupplierFilter.value = s.id;
                      controller.loadOrders();
                    },
                    badgeColor: Colors.teal,
                  )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? (badgeColor ?? AppColors.primary) : AppColors.cardBgLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? (badgeColor ?? AppColors.primary) : AppColors.border,
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // Order Card Component
  Widget _buildOrderCard(BuildContext context, CustomerOrderModel order, CustomerOrderController controller) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Order No, Source Badge, Status Badge & Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cardBgLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  order.orderNo,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),

              // Lead Source Badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getSourceColor(order.orderSource).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getSourceColor(order.orderSource), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getSourceIcon(order.orderSource), size: 12, color: _getSourceColor(order.orderSource)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${order.sourceLabel}${order.leadAccount != null && order.leadAccount!.isNotEmpty ? " • ${order.leadAccount}" : ""}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getSourceColor(order.orderSource)),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: order.statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: order.statusColor, width: 0.8),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: order.statusColor),
                ),
              ),

              // Popup Menu Actions
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted),
                onSelected: (val) {
                  if (val == 'payment') {
                    _showPaymentSettlementDialog(context, order, controller);
                  } else if (val == 'reschedule') {
                    _showRescheduleDialog(context, order, controller);
                  } else if (val == 'delete') {
                    _showDeleteConfirmDialog(context, order, controller);
                  }
                },
                itemBuilder: (ctx) => [
                  if (order.dueAmount > 0)
                    const PopupMenuItem(value: 'payment', child: Text('💳 ငွေလက်ခံမည် (Collect Payment)')),
                  const PopupMenuItem(value: 'reschedule', child: Text('ရက်ချိန်းပြောင်းမည် (Reschedule)')),
                  const PopupMenuItem(value: 'delete', child: Text('ဖျက်မည် (Delete)', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Customer Info & Appointment Section
          if (isMobile) ...[
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${order.customerName}${order.customerPhone != null && order.customerPhone!.isNotEmpty ? " (${order.customerPhone})" : ""}',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (order.customerAddress != null && order.customerAddress!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 22),
                child: Text(order.customerAddress!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3), width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_note_rounded, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.appointmentTypeLabel,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        Text(
                          order.appointmentDate != null
                              ? DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.parse(order.appointmentDate!))
                              : 'No date scheduled',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Details
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 16, color: AppColors.primaryLight),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${order.customerName}${order.customerPhone != null && order.customerPhone!.isNotEmpty ? " (${order.customerPhone})" : ""}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (order.customerAddress != null && order.customerAddress!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 22),
                          child: Text(order.customerAddress!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ),
                    ],
                  ),
                ),

                // Appointment Box
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_note_rounded, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.appointmentTypeLabel,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                              Text(
                                order.appointmentDate != null
                                    ? DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.parse(order.appointmentDate!))
                                    : 'No date scheduled',
                                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (order.supplierName != null && order.supplierName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.teal.withOpacity(0.3), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.precision_manufacturing_rounded, size: 13, color: Colors.teal),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Supplier: ${order.supplierName}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Items Summary Table
          if (order.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.itemName} (${Formatters.formatQty(item.quantity, unit: item.unit)})',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.formatCurrency(item.subtotal),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 10),

          // Financial Summary & Quick Progression Buttons
          if (isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBgLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildFinancePill('Total', Formatters.formatCurrency(order.totalAmount), AppColors.textPrimary),
                  _buildFinancePill('Advance Paid', Formatters.formatCurrency(order.advanceAmount), Colors.green),
                  _buildFinancePill(
                    'Due',
                    Formatters.formatCurrency(order.dueAmount),
                    order.dueAmount > 0 ? AppColors.error : AppColors.textMuted,
                    onPayTap: order.dueAmount > 0 ? () => _showPaymentSettlementDialog(context, order, controller) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _buildProgressionAction(context, order, controller, isFullWidth: true),
            ),
          ] else ...[
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                // Financials
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildFinancePill('Total', Formatters.formatCurrency(order.totalAmount), AppColors.textPrimary),
                    _buildFinancePill('Advance Paid', Formatters.formatCurrency(order.advanceAmount), Colors.green),
                    _buildFinancePill(
                      'Due',
                      Formatters.formatCurrency(order.dueAmount),
                      order.dueAmount > 0 ? AppColors.error : AppColors.textMuted,
                      onPayTap: order.dueAmount > 0 ? () => _showPaymentSettlementDialog(context, order, controller) : null,
                    ),
                  ],
                ),

                // Workflow Action Progression Button
                _buildProgressionAction(context, order, controller),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancePill(String label, String value, Color color, {VoidCallback? onPayTap}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        if (onPayTap != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: onPayTap,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green, width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 10, color: Colors.green),
                  Text('Pay', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressionAction(
    BuildContext context,
    CustomerOrderModel order,
    CustomerOrderController controller, {
    bool isFullWidth = false,
  }) {
    switch (order.status) {
      case 'PENDING':
        return SizedBox(
          height: isFullWidth ? 38 : 34,
          child: ElevatedButton.icon(
            onPressed: () => controller.updateStatus(order.id, 'CONFIRMED'),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
            label: const Text('Confirm (အတည်ပြုမည်)', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
          ),
        );
      case 'CONFIRMED':
        return SizedBox(
          height: isFullWidth ? 38 : 34,
          child: ElevatedButton.icon(
            onPressed: () => controller.updateStatus(order.id, 'IN_PROGRESS'),
            icon: const Icon(Icons.play_arrow_rounded, size: 15),
            label: const Text('Start Weaving (ရက်လုပ်မည်)', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
          ),
        );
      case 'IN_PROGRESS':
        return SizedBox(
          height: isFullWidth ? 38 : 34,
          child: ElevatedButton.icon(
            onPressed: () => controller.updateStatus(order.id, 'READY_FOR_PICKUP'),
            icon: const Icon(Icons.inventory_rounded, size: 15),
            label: const Text('Ready for Pickup (အသင့်ဖြစ်)', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
          ),
        );
      case 'READY_FOR_PICKUP':
        return SizedBox(
          height: isFullWidth ? 38 : 34,
          child: ElevatedButton.icon(
            onPressed: () {
              if (order.dueAmount > 0) {
                _showPaymentSettlementDialog(context, order, controller);
              } else {
                controller.updateStatus(order.id, 'COMPLETED');
              }
            },
            icon: const Icon(Icons.done_all_rounded, size: 15),
            label: Text(
              order.dueAmount > 0 ? 'Complete & Settle (လွှဲပြောင်းငွေရှင်း)' : 'Complete & Handover (လွှဲပြောင်းမည်)',
              style: const TextStyle(fontSize: 11),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: order.dueAmount > 0 ? Colors.teal.shade700 : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          ),
        );
      case 'COMPLETED':
        if (order.dueAmount > 0) {
          if (isFullWidth) {
            return Row(
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text('Completed (Due)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentSettlementDialog(context, order, controller),
                      icon: const Icon(Icons.payments_outlined, size: 13),
                      label: const Text('Pay Due (ငွေရှင်းမည်)', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text('Completed (Due)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
              SizedBox(
                width: 150,
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentSettlementDialog(context, order, controller),
                  icon: const Icon(Icons.payments_outlined, size: 13),
                  label: const Text('Pay Due (ငွေရှင်းမည်)', style: TextStyle(fontSize: 10.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
            ],
          );
        }
        return const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
            SizedBox(width: 4),
            Text('Completed (Paid)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getSourceColor(String source) {
    switch (source.toUpperCase()) {
      case 'MESSENGER':
        return Colors.blue;
      case 'VIBER':
        return const Color(0xFF7360F2);
      case 'PHONE':
        return Colors.green;
      case 'TELEGRAM':
        return Colors.lightBlue;
      case 'TIKTOK':
        return Colors.pinkAccent;
      case 'WALK_IN':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getSourceIcon(String source) {
    switch (source.toUpperCase()) {
      case 'MESSENGER':
        return Icons.message_rounded;
      case 'VIBER':
        return Icons.phone_in_talk_rounded;
      case 'PHONE':
        return Icons.call_rounded;
      case 'TELEGRAM':
        return Icons.send_rounded;
      case 'TIKTOK':
        return Icons.music_note_rounded;
      case 'WALK_IN':
        return Icons.store_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  // Create / Edit Customer Order Form Modal
  void _showOrderFormDialog(BuildContext context, CustomerOrderController controller) {
    CustomerModel? selectedCustomer;
    SupplierModel? selectedSupplier;
    String selectedSource = 'MESSENGER';
    final leadAccountCtrl = TextEditingController(text: 'Main Facebook Page');
    final customerNameCtrl = TextEditingController();
    final customerPhoneCtrl = TextEditingController();
    final customerAddressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final advanceCtrl = TextEditingController(text: '0');

    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));
    TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);
    String selectedAppointmentType = 'LOOM_WEAVING';

    final List<Map<String, dynamic>> orderItems = [
      {
        'productId': null,
        'supplierId': null,
        'supplierName': null,
        'itemName': TextEditingController(),
        'fabricType': TextEditingController(),
        'color': TextEditingController(),
        'quantity': TextEditingController(text: '1'),
        'unit': 'piece',
        'unitPrice': TextEditingController(text: '0'),
      }
    ];

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            double calculateTotal() {
              double sum = 0.0;
              for (var i in orderItems) {
                final qty = double.tryParse((i['quantity'] as TextEditingController).text.trim()) ?? 0.0;
                final price = double.tryParse((i['unitPrice'] as TextEditingController).text.trim()) ?? 0.0;
                sum += (qty * price);
              }
              return sum;
            }

            final total = calculateTotal();
            final advance = double.tryParse(advanceCtrl.text.trim()) ?? 0.0;
            final due = (total - advance).clamp(0.0, double.infinity);
            final screenWidth = MediaQuery.of(context).size.width;
            final isMobile = screenWidth < 600;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 580,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modal Title
                      Row(
                        children: [
                          const Icon(Icons.event_note_rounded, color: AppColors.primaryLight, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'New Customer Order & Appointment',
                              style: TextStyle(
                                fontSize: isMobile ? 14.5 : 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                            onPressed: () => Get.back(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Customer Selection / Input
                      DropdownButtonFormField<CustomerModel?>(
                        value: selectedCustomer,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Registered Customer (or fill below)',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: AppColors.primaryLight),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Walk-in / Direct Input')),
                          ...controller.customers.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.name} ${c.phone != null ? "(${c.phone})" : ""}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedCustomer = val;
                            if (val != null) {
                              customerNameCtrl.text = val.name;
                              customerPhoneCtrl.text = val.phone ?? '';
                              customerAddressCtrl.text = val.address ?? '';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      if (isMobile) ...[
                        TextField(
                          controller: customerNameCtrl,
                          decoration: const InputDecoration(labelText: 'Customer Name *', isDense: true),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: customerPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone Number', isDense: true),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: customerNameCtrl,
                                decoration: const InputDecoration(labelText: 'Customer Name *'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: customerPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(labelText: 'Phone Number'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Order Source & Lead Account
                      if (isMobile) ...[
                        DropdownButtonFormField<String>(
                          value: selectedSource,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Order Source (လမ်းကြောင်း)', isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'MESSENGER', child: Text('🔵 Messenger')),
                            DropdownMenuItem(value: 'VIBER', child: Text('🟣 Viber')),
                            DropdownMenuItem(value: 'PHONE', child: Text('📞 Phone')),
                            DropdownMenuItem(value: 'TELEGRAM', child: Text('✈️ Telegram')),
                            DropdownMenuItem(value: 'TIKTOK', child: Text('🎵 TikTok')),
                            DropdownMenuItem(value: 'WALK_IN', child: Text('🏪 Walk-in')),
                            DropdownMenuItem(value: 'OTHER', child: Text('🌐 Other')),
                          ],
                          onChanged: (val) => setState(() => selectedSource = val ?? 'MESSENGER'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: leadAccountCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Lead / Page Account Name',
                            hintText: 'e.g. Main Facebook Page / Viber 09...',
                            isDense: true,
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: DropdownButtonFormField<String>(
                                value: selectedSource,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Order Source (လမ်းကြောင်း)'),
                                items: const [
                                  DropdownMenuItem(value: 'MESSENGER', child: Text('🔵 Messenger')),
                                  DropdownMenuItem(value: 'VIBER', child: Text('🟣 Viber')),
                                  DropdownMenuItem(value: 'PHONE', child: Text('📞 Phone')),
                                  DropdownMenuItem(value: 'TELEGRAM', child: Text('✈️ Telegram')),
                                  DropdownMenuItem(value: 'TIKTOK', child: Text('🎵 TikTok')),
                                  DropdownMenuItem(value: 'WALK_IN', child: Text('🏪 Walk-in')),
                                  DropdownMenuItem(value: 'OTHER', child: Text('🌐 Other')),
                                ],
                                onChanged: (val) => setState(() => selectedSource = val ?? 'MESSENGER'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 6,
                              child: TextField(
                                controller: leadAccountCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Lead / Page Account Name',
                                  hintText: 'e.g. Main Facebook Page / Viber 09...',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Primary Supplier / Weaver Selector
                      Obx(() {
                        final currentId = selectedSupplier?.id;
                        final isValid = controller.suppliers.any((s) => s.id == currentId);
                        return DropdownButtonFormField<String?>(
                          value: isValid ? currentId : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Assign Primary Supplier / Weaver (ရက္ကန်း/ကုန်သွင်းသူ)',
                            prefixIcon: Icon(Icons.precision_manufacturing_rounded, size: 18, color: Colors.teal),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('No Supplier Assigned (General)')),
                            ...controller.suppliers.map((s) => DropdownMenuItem<String?>(
                              value: s.id,
                              child: Text(
                                '${s.name} ${s.companyName != null ? "(${s.companyName})" : ""}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                          ],
                          onChanged: (val) {
                            setState(() {
                              selectedSupplier = controller.suppliers.firstWhereOrNull((s) => s.id == val);
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 14),

                      // Appointment Schedule Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Appointment Scheduling (ရက်ချိန်းသတ်မှတ်ခြင်း)',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.blue)),
                            const SizedBox(height: 10),
                            if (isMobile) ...[
                              DropdownButtonFormField<String>(
                                value: selectedAppointmentType,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Appointment Type', isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 'LOOM_WEAVING', child: Text('🧵 ရက္ကန်းနှင့်ချိတ်ဆက်ခြင်း', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'FABRIC_DELIVERY_IN', child: Text('📦 အထည်လာပို့ခြင်း', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'PACKING', child: Text('🏷️ ပစ္စည်းထုတ်ပိုးခြင်း', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'DELIVERY', child: Text('🚚 ပို့ဆောင်ခြင်း', overflow: TextOverflow.ellipsis)),
                                ],
                                onChanged: (val) => setState(() => selectedAppointmentType = val ?? 'LOOM_WEAVING'),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (pickedDate != null) {
                                    final pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: selectedTime,
                                    );
                                    if (pickedTime != null) {
                                      setState(() {
                                        selectedDate = pickedDate;
                                        selectedTime = pickedTime;
                                      });
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBgLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${DateFormat('yyyy-MM-dd').format(selectedDate)} ${selectedTime.format(context)}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.blue),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: DropdownButtonFormField<String>(
                                      value: selectedAppointmentType,
                                      isExpanded: true,
                                      decoration: const InputDecoration(labelText: 'Appointment Type'),
                                      items: const [
                                        DropdownMenuItem(value: 'LOOM_WEAVING', child: Text('🧵 ရက္ကန်းနှင့်ချိတ်ဆက်ခြင်း', overflow: TextOverflow.ellipsis)),
                                        DropdownMenuItem(value: 'FABRIC_DELIVERY_IN', child: Text('📦 အထည်လာပို့ခြင်း', overflow: TextOverflow.ellipsis)),
                                        DropdownMenuItem(value: 'PACKING', child: Text('🏷️ ပစ္စည်းထုတ်ပိုးခြင်း', overflow: TextOverflow.ellipsis)),
                                        DropdownMenuItem(value: 'DELIVERY', child: Text('🚚 ပို့ဆောင်ခြင်း', overflow: TextOverflow.ellipsis)),
                                      ],
                                      onChanged: (val) => setState(() => selectedAppointmentType = val ?? 'LOOM_WEAVING'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 5,
                                    child: InkWell(
                                      onTap: () async {
                                        final pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: selectedDate,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (pickedDate != null) {
                                          final pickedTime = await showTimePicker(
                                            context: context,
                                            initialTime: selectedTime,
                                          );
                                          if (pickedTime != null) {
                                            setState(() {
                                              selectedDate = pickedDate;
                                              selectedTime = pickedTime;
                                            });
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardBgLight,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${DateFormat('yyyy-MM-dd').format(selectedDate)} ${selectedTime.format(context)}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                            ),
                                            const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.blue),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Order Items Builder
                      if (isMobile) ...[
                        Row(
                          children: [
                            const Text('မှာယူသည့် အထည်များ',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${orderItems.length} items',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                _showMultiProductSelectModal(context, controller, (selectedProducts) {
                                  setState(() {
                                    if (orderItems.length == 1 &&
                                        (orderItems[0]['itemName'] as TextEditingController).text.trim().isEmpty) {
                                      orderItems.clear();
                                    }
                                    for (var product in selectedProducts) {
                                      orderItems.add({
                                        'productId': product.id,
                                        'supplierId': selectedSupplier?.id,
                                        'supplierName': selectedSupplier?.name,
                                        'itemName': TextEditingController(text: product.name),
                                        'fabricType': TextEditingController(text: product.fabricType ?? ''),
                                        'color': TextEditingController(text: product.color ?? ''),
                                        'quantity': TextEditingController(text: '1'),
                                        'unit': product.unit,
                                        'unitPrice': TextEditingController(text: product.retailPrice.toStringAsFixed(0)),
                                      });
                                    }
                                  });
                                });
                              },
                              icon: const Icon(Icons.playlist_add_rounded, size: 16, color: AppColors.secondary),
                              label: const Text('+ပစ္စည်းမှရွေးမည်', style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  orderItems.add({
                                    'productId': null,
                                    'supplierId': selectedSupplier?.id,
                                    'supplierName': selectedSupplier?.name,
                                    'itemName': TextEditingController(text: ''),
                                    'fabricType': TextEditingController(text: ''),
                                    'color': TextEditingController(text: ''),
                                    'quantity': TextEditingController(text: '1'),
                                    'unit': 'piece',
                                    'unitPrice': TextEditingController(text: '0'),
                                  });
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                              label: const Text('+ Custom Item', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('မှာယူသည့် အထည်များ',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${orderItems.length} items',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    _showMultiProductSelectModal(context, controller, (selectedProducts) {
                                      setState(() {
                                        if (orderItems.length == 1 &&
                                            (orderItems[0]['itemName'] as TextEditingController).text.trim().isEmpty) {
                                          orderItems.clear();
                                        }
                                        for (var product in selectedProducts) {
                                          orderItems.add({
                                            'productId': product.id,
                                            'supplierId': selectedSupplier?.id,
                                            'supplierName': selectedSupplier?.name,
                                            'itemName': TextEditingController(text: product.name),
                                            'fabricType': TextEditingController(text: product.fabricType ?? ''),
                                            'color': TextEditingController(text: product.color ?? ''),
                                            'quantity': TextEditingController(text: '1'),
                                            'unit': product.unit,
                                            'unitPrice': TextEditingController(text: product.retailPrice.toStringAsFixed(0)),
                                          });
                                        }
                                      });
                                    });
                                  },
                                  icon: const Icon(Icons.playlist_add_rounded, size: 16, color: AppColors.secondary),
                                  label: const Text('+ပစ္စည်းများမှရွေးမည်', style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      orderItems.add({
                                        'productId': null,
                                        'supplierId': selectedSupplier?.id,
                                        'supplierName': selectedSupplier?.name,
                                        'itemName': TextEditingController(text: ''),
                                        'fabricType': TextEditingController(text: ''),
                                        'color': TextEditingController(text: ''),
                                        'quantity': TextEditingController(text: '1'),
                                        'unit': 'piece',
                                        'unitPrice': TextEditingController(text: '0'),
                                      });
                                    });
                                  },
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                                  label: const Text('+ Custom Item (အသစ်)', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),

                      ...orderItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final isExistingProduct = item['productId'] != null;
                        final ProductModel? matchedProduct = isExistingProduct
                            ? controller.products.firstWhereOrNull((p) => p.id == item['productId'])
                            : null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.cardBgLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isExistingProduct ? AppColors.secondary.withOpacity(0.4) : AppColors.border,
                              width: isExistingProduct ? 1.2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isExistingProduct ? AppColors.secondary.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isExistingProduct ? '#${idx + 1} Catalog' : '#${idx + 1} Custom',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: isExistingProduct ? AppColors.secondary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: item['itemName'],
                                      decoration: InputDecoration(
                                        labelText: isExistingProduct ? 'Product Name *' : 'Custom Item Name *',
                                        hintText: 'e.g. ပိုးလွန်းကြင် ဝမ်းဆက်',
                                        isDense: true,
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.search_rounded, size: 16, color: AppColors.secondary),
                                          tooltip: 'Select / Change Product',
                                          onPressed: () {
                                            _showProductSelectModal(context, controller, (product) {
                                              setState(() {
                                                item['productId'] = product.id;
                                                (item['itemName'] as TextEditingController).text = product.name;
                                                (item['fabricType'] as TextEditingController).text = product.fabricType ?? '';
                                                (item['color'] as TextEditingController).text = product.color ?? '';
                                                (item['unitPrice'] as TextEditingController).text = product.retailPrice.toStringAsFixed(0);
                                                item['unit'] = product.unit;
                                              });
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (orderItems.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red, size: 18),
                                      tooltip: 'Remove Item',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => setState(() => orderItems.removeAt(idx)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: item['fabricType'],
                                decoration: const InputDecoration(labelText: 'Fabric / Color (အရောင်/အထည်အမျိုးအစား)', isDense: true),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: item['quantity'],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: DropdownButtonFormField<String>(
                                      value: item['unit'] as String,
                                      isExpanded: true,
                                      decoration: const InputDecoration(labelText: 'Unit', isDense: true),
                                      items: const [
                                        DropdownMenuItem(value: 'piece', child: Text('Piece (ထည်)')),
                                        DropdownMenuItem(value: 'yard', child: Text('Yard (ကိုက်)')),
                                        DropdownMenuItem(value: 'meter', child: Text('Meter (မီတာ)')),
                                        DropdownMenuItem(value: 'set', child: Text('Set (စုံ)')),
                                      ],
                                      onChanged: (val) => setState(() => item['unit'] = val ?? 'piece'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 4,
                                    child: TextField(
                                      controller: item['unitPrice'],
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(labelText: 'Unit Price', isDense: true),
                                    ),
                                  ),
                                ],
                              ),
                              // Product Inventory & Supplier Linkage Bar
                              if (matchedProduct != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (matchedProduct.stockQty <= matchedProduct.minStockAlert ? Colors.orange : Colors.teal).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: (matchedProduct.stockQty <= matchedProduct.minStockAlert ? Colors.orange : Colors.teal).withOpacity(0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 2,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            matchedProduct.stockQty <= matchedProduct.minStockAlert
                                                ? Icons.warning_amber_rounded
                                                : Icons.check_circle_outline_rounded,
                                            size: 13,
                                            color: matchedProduct.stockQty <= matchedProduct.minStockAlert ? Colors.orange : Colors.teal,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Stock: ${matchedProduct.stockQty.toStringAsFixed(0)} ${matchedProduct.unit}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: matchedProduct.stockQty <= matchedProduct.minStockAlert ? Colors.orange : Colors.teal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (matchedProduct.stockQty <= matchedProduct.minStockAlert)
                                        const Text('• Reorder to Supplier',
                                            style: TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.w600)),
                                      if (selectedSupplier != null)
                                        Text(
                                          '• Linked: ${selectedSupplier!.name}',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.teal),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 12),

                      // Financial Summary & Advance Deposit
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Order Price:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                Text(Formatters.formatCurrency(total),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: advanceCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Advance Deposit Paid (စရံငွေ)',
                                prefixIcon: Icon(Icons.payments_outlined, size: 18, color: Colors.green),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Remaining Due (ကျန်ငွေ):',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error)),
                                Text(
                                  Formatters.formatCurrency(due),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Dialog Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: isMobile ? 1 : 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final name = customerNameCtrl.text.trim();
                                if (name.isEmpty) {
                                  Get.snackbar('Input Error', 'Please enter customer name',
                                      backgroundColor: Colors.amber.shade800, colorText: Colors.white);
                                  return;
                                }

                                final appointmentIso = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                ).toIso8601String();

                                List<CustomerOrderItemModel> builtItems = [];
                                for (var i in orderItems) {
                                  final itemName = (i['itemName'] as TextEditingController).text.trim();
                                  if (itemName.isEmpty) continue;
                                  final qty = double.tryParse((i['quantity'] as TextEditingController).text.trim()) ?? 1.0;
                                  final price = double.tryParse((i['unitPrice'] as TextEditingController).text.trim()) ?? 0.0;

                                  builtItems.add(CustomerOrderItemModel(
                                    id: '',
                                    customerOrderId: '',
                                    productId: i['productId'] as String?,
                                    supplierId: i['supplierId'] as String? ?? selectedSupplier?.id,
                                    supplierName: i['supplierName'] as String? ?? selectedSupplier?.name,
                                    itemName: itemName,
                                    fabricType: (i['fabricType'] as TextEditingController).text.trim(),
                                    color: (i['color'] as TextEditingController).text.trim(),
                                    quantity: qty,
                                    unit: i['unit'] as String,
                                    unitPrice: price,
                                    subtotal: qty * price,
                                  ));
                                }

                                if (builtItems.isEmpty) {
                                  Get.snackbar('Input Error', 'Please add at least one order item',
                                      backgroundColor: Colors.amber.shade800, colorText: Colors.white);
                                  return;
                                }

                                Get.back();
                                await controller.saveOrder(
                                  customerName: name,
                                  customerId: selectedCustomer?.id,
                                  customerPhone: customerPhoneCtrl.text.trim().isNotEmpty ? customerPhoneCtrl.text.trim() : null,
                                  customerAddress: customerAddressCtrl.text.trim().isNotEmpty ? customerAddressCtrl.text.trim() : null,
                                  orderSource: selectedSource,
                                  leadAccount: leadAccountCtrl.text.trim(),
                                  appointmentDate: appointmentIso,
                                  appointmentType: selectedAppointmentType,
                                  status: 'CONFIRMED',
                                  totalAmount: total,
                                  advanceAmount: advance,
                                  notes: notesCtrl.text.trim(),
                                  items: builtItems,
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: Text(isMobile ? 'Save Order' : 'Save Customer Order'),
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
          },
        ),
      ),
    );
  }

  // Single Product Selection Modal from Existing Catalog
  void _showProductSelectModal(BuildContext context, CustomerOrderController controller, Function(ProductModel) onSelect) {
    String searchQuery = '';
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final filtered = controller.products.where((p) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return p.name.toLowerCase().contains(q) ||
                  (p.barcode != null && p.barcode!.toLowerCase().contains(q)) ||
                  (p.fabricType != null && p.fabricType!.toLowerCase().contains(q)) ||
                  (p.color != null && p.color!.toLowerCase().contains(q));
            }).toList();

            final screenWidth = MediaQuery.of(context).size.width;
            return Container(
              constraints: const BoxConstraints(maxWidth: 500),
              width: screenWidth < 540 ? screenWidth * 0.94 : 500,
              height: 520,
              padding: EdgeInsets.all(screenWidth < 500 ? 12 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded, color: AppColors.secondary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          screenWidth < 400 ? 'Select Product' : 'Select Product (ကုန်ပစ္စည်းရွေးချယ်ရန်)',
                          style: TextStyle(
                            fontSize: screenWidth < 400 ? 13.5 : 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

                  // Search Bar
                  TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => searchQuery = v.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Search product by name, barcode, fabric...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Products List
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.search_off_rounded, size: 36, color: AppColors.textMuted),
                                SizedBox(height: 6),
                                Text('No matching products found', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = filtered[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBgLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.checkroom_rounded, color: AppColors.secondary, size: 20),
                                ),
                                title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                subtitle: Text(
                                  '${p.fabricType ?? ""} ${p.color ?? ""} • ${Formatters.formatQty(p.stockQty, unit: p.unit)} in stock'.trim(),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                trailing: Text(
                                  Formatters.formatCurrency(p.retailPrice),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                                onTap: () {
                                  Get.back();
                                  onSelect(p);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Multi-Product Selection Modal with Checkboxes
  void _showMultiProductSelectModal(
    BuildContext context,
    CustomerOrderController controller,
    Function(List<ProductModel>) onSelectedList,
  ) {
    String searchQuery = '';
    final Set<String> selectedProductIds = {};

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final filtered = controller.products.where((p) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return p.name.toLowerCase().contains(q) ||
                  (p.barcode != null && p.barcode!.toLowerCase().contains(q)) ||
                  (p.fabricType != null && p.fabricType!.toLowerCase().contains(q)) ||
                  (p.color != null && p.color!.toLowerCase().contains(q));
            }).toList();

            final screenWidth = MediaQuery.of(context).size.width;
            final isMobile = screenWidth < 500;

            return Container(
              constraints: const BoxConstraints(maxWidth: 520),
              width: screenWidth < 560 ? screenWidth * 0.94 : 520,
              height: 560,
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.playlist_add_check_rounded, color: AppColors.secondary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isMobile
                              ? 'Select Products (${selectedProductIds.length})'
                              : 'Select Multiple Products (${selectedProductIds.length} selected)',
                          style: TextStyle(
                            fontSize: isMobile ? 13.5 : 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

                  // Search Bar
                  TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => searchQuery = v.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Search products to add to order...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Products List with Checkboxes
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.search_off_rounded, size: 36, color: AppColors.textMuted),
                                SizedBox(height: 6),
                                Text('No matching products found', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = filtered[index];
                              final isChecked = selectedProductIds.contains(p.id);

                              return CheckboxListTile(
                                dense: true,
                                value: isChecked,
                                activeColor: AppColors.secondary,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                secondary: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBgLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.checkroom_rounded, color: AppColors.secondary, size: 20),
                                ),
                                title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                subtitle: Text(
                                  '${p.fabricType ?? ""} ${p.color ?? ""} • ${Formatters.formatCurrency(p.retailPrice)}'.trim(),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedProductIds.add(p.id);
                                    } else {
                                      selectedProductIds.remove(p.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Bottom Action Buttons
                  if (screenWidth < 480) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (selectedProductIds.length == filtered.length) {
                                selectedProductIds.clear();
                              } else {
                                selectedProductIds.addAll(filtered.map((p) => p.id));
                              }
                            });
                          },
                          child: Text(
                            selectedProductIds.length == filtered.length ? 'Deselect All' : 'Select All',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: selectedProductIds.isEmpty
                            ? null
                            : () {
                                final selectedList = controller.products
                                    .where((p) => selectedProductIds.contains(p.id))
                                    .toList();
                                Get.back();
                                onSelectedList(selectedList);
                              },
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                        label: Text('Add Selected (${selectedProductIds.length})'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (selectedProductIds.length == filtered.length) {
                                selectedProductIds.clear();
                              } else {
                                selectedProductIds.addAll(filtered.map((p) => p.id));
                              }
                            });
                          },
                          child: Text(
                            selectedProductIds.length == filtered.length ? 'Deselect All' : 'Select All',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 170,
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: selectedProductIds.isEmpty
                                    ? null
                                    : () {
                                        final selectedList = controller.products
                                            .where((p) => selectedProductIds.contains(p.id))
                                            .toList();
                                        Get.back();
                                        onSelectedList(selectedList);
                                      },
                                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                                label: Text('Add Selected (${selectedProductIds.length})'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Reschedule Appointment Dialog
  void _showRescheduleDialog(BuildContext context, CustomerOrderModel order, CustomerOrderController controller) {
    DateTime selectedDate = order.appointmentDate != null ? DateTime.parse(order.appointmentDate!) : DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    const validTypes = ['LOOM_WEAVING', 'FABRIC_DELIVERY_IN', 'PACKING', 'DELIVERY'];
    String selectedType = validTypes.contains(order.appointmentType) ? order.appointmentType : 'LOOM_WEAVING';

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final screenWidth = MediaQuery.of(context).size.width;
            return Container(
              constraints: const BoxConstraints(maxWidth: 420),
              width: screenWidth < 460 ? screenWidth * 0.94 : 420,
              padding: EdgeInsets.all(screenWidth < 460 ? 14 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_calendar_rounded, color: Colors.blue, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          screenWidth < 400 ? 'ရက်ချိန်းပြောင်းမည်' : 'ရက်ချိန်းပြောင်းမည် (Reschedule)',
                          style: TextStyle(
                            fontSize: screenWidth < 400 ? 13.5 : 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  Text('Order: ${order.orderNo} (${order.customerName})', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Appointment Type'),
                    items: const [
                      DropdownMenuItem(value: 'LOOM_WEAVING', child: Text('🧵 ရက္ကန်းနှင့်ချိတ်ဆက်ခြင်း')),
                      DropdownMenuItem(value: 'FABRIC_DELIVERY_IN', child: Text('📦 အထည်လာပို့ခြင်း')),
                      DropdownMenuItem(value: 'PACKING', child: Text('🏷️ ပစ္စည်းထုတ်ပိုးခြင်း')),
                      DropdownMenuItem(value: 'DELIVERY', child: Text('🚚 ပို့ဆောင်ခြင်း')),
                    ],
                    onChanged: (val) => setState(() => selectedType = val ?? 'LOOM_WEAVING'),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(context: context, initialTime: selectedTime);
                        if (pickedTime != null) {
                          setState(() {
                            selectedDate = pickedDate;
                            selectedTime = pickedTime;
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${DateFormat('yyyy-MM-dd').format(selectedDate)} ${selectedTime.format(context)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            final newIso = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            ).toIso8601String();

                            Get.back();
                            await controller.rescheduleAppointment(order.id, newIso, appointmentType: selectedType);
                          },
                          child: const Text('Save Reschedule'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, CustomerOrderModel order, CustomerOrderController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Delete Customer Order?'),
        content: Text('Are you sure you want to delete order "${order.orderNo}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          SizedBox(
            width: 90,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                controller.deleteOrder(order.id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }

  // Payment Settlement Dialog for Customer Order
  void _showPaymentSettlementDialog(
    BuildContext context,
    CustomerOrderModel order,
    CustomerOrderController controller,
  ) async {
    final deliveryServices = await DeliveryServiceDao().getActiveDeliveryServices();
    final payAmountCtrl = TextEditingController(text: order.dueAmount.toStringAsFixed(0));
    final codAmountCtrl = TextEditingController(text: order.dueAmount.toStringAsFixed(0));
    String selectedPaymentMethod = 'cash';
    bool chargeDebtToAccount = false;
    final isRegisteredCustomer = order.customerId != null && order.customerId!.isNotEmpty;

    // Fulfillment State
    String fulfillmentType = order.appointmentType == 'DELIVERY' ? 'DELIVERY' : 'SELF_COLLECT';
    DeliveryServiceModel? selectedDeliveryService = deliveryServices.isNotEmpty ? deliveryServices.first : null;
    final inHouseDeliveryFeeCtrl = TextEditingController(
      text: selectedDeliveryService?.isInHouse == true && selectedDeliveryService!.defaultDeliveryFee > 0
          ? selectedDeliveryService.defaultDeliveryFee.toStringAsFixed(0)
          : '0',
    );
    bool isCod = false;

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final double enteredAmount = double.tryParse(payAmountCtrl.text.trim()) ?? 0.0;
            final double remainingAfterPay = (order.dueAmount - enteredAmount).clamp(0.0, double.infinity);
            final bool isFullSettlement = enteredAmount >= order.dueAmount;
            final double codAmount = double.tryParse(codAmountCtrl.text.trim()) ?? order.dueAmount;

            final screenWidth = MediaQuery.of(context).size.width;
            return Container(
              constraints: const BoxConstraints(maxWidth: 500),
              width: screenWidth < 540 ? screenWidth * 0.94 : 500,
              padding: EdgeInsets.all(screenWidth < 500 ? 12 : 22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog Header
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Order Payment & Settlement',
                            style: TextStyle(
                              fontSize: screenWidth < 400 ? 14.5 : 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

                    // Order Summary Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order: ${order.orderNo}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                              Text(order.customerName, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Price:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text(Formatters.formatCurrency(order.totalAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Advance Paid (ပေးပြီးစရံ):', style: TextStyle(fontSize: 12, color: Colors.green)),
                              Text(Formatters.formatCurrency(order.advanceAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Current Due (လက်ကျန်ကျန်ငွေ):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error)),
                              Text(Formatters.formatCurrency(order.dueAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Fulfillment Selector
                    const Text('Fulfillment Method (ပို့ဆောင်ရေး):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            avatar: Icon(Icons.storefront_rounded,
                                size: 16,
                                color: fulfillmentType == 'SELF_COLLECT' ? Colors.white : AppColors.textSecondary),
                            label: const Text('Self-Collected (ဆိုင်လာယူ)', style: TextStyle(fontSize: 11)),
                            selected: fulfillmentType == 'SELF_COLLECT',
                            selectedColor: AppColors.primary,
                            onSelected: (_) {
                              setState(() {
                                fulfillmentType = 'SELF_COLLECT';
                                isCod = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            avatar: Icon(Icons.local_shipping_rounded,
                                size: 16,
                                color: fulfillmentType == 'DELIVERY' ? Colors.white : AppColors.textSecondary),
                            label: const Text('Delivery Service (ပို့ဆောင်ရေး)', style: TextStyle(fontSize: 11)),
                            selected: fulfillmentType == 'DELIVERY',
                            selectedColor: AppColors.primary,
                            onSelected: (_) {
                              setState(() {
                                fulfillmentType = 'DELIVERY';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Delivery Service Details if Delivery
                    if (fulfillmentType == 'DELIVERY') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              value: selectedDeliveryService?.id,
                              decoration: const InputDecoration(
                                labelText: 'Select Delivery Courier *',
                                prefixIcon: Icon(Icons.delivery_dining_rounded, size: 18, color: AppColors.primaryLight),
                              ),
                              items: deliveryServices.map((ds) {
                                return DropdownMenuItem(
                                  value: ds.id,
                                  child: Row(
                                    children: [
                                      Text(ds.name, style: const TextStyle(fontSize: 12)),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: (ds.isInHouse ? Colors.teal : Colors.blue).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          ds.isInHouse ? 'In-House' : 'External',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: ds.isInHouse ? Colors.tealAccent : Colors.blue.shade300,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (id) {
                                if (id == null) return;
                                final matched = deliveryServices.firstWhereOrNull((s) => s.id == id);
                                if (matched != null) {
                                  setState(() {
                                    selectedDeliveryService = matched;
                                    if (matched.isInHouse) {
                                      inHouseDeliveryFeeCtrl.text = matched.defaultDeliveryFee.toStringAsFixed(0);
                                    } else {
                                      inHouseDeliveryFeeCtrl.text = '0';
                                    }
                                  });
                                }
                              },
                            ),

                            // In-House Delivery Price input
                            if (selectedDeliveryService?.isInHouse == true) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade900.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.teal.shade700.withOpacity(0.4)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.storefront_rounded, size: 15, color: Colors.tealAccent),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            screenWidth < 400 ? 'In-House Delivery Income' : 'In-House Delivery Income (ဆိုင်တွင်းပို့ခဝင်ငွေ)',
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (selectedDeliveryService!.isCommissionBased) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade800.withOpacity(0.4),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${selectedDeliveryService!.commissionVal.toStringAsFixed(0)}${selectedDeliveryService!.commissionType == 'PERCENT' ? '%' : ' Ks'} comm.',
                                              style: const TextStyle(fontSize: 9.5, color: Colors.tealAccent),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: inHouseDeliveryFeeCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Delivery Price to Charge Customer (Ks) *',
                                        prefixIcon: Icon(Icons.attach_money_rounded, size: 16),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),

                            // COD Switch for Customer Order
                            Row(
                              children: [
                                const Icon(Icons.handshake_outlined, size: 18, color: Colors.amber),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    screenWidth < 420 ? 'Cash on Delivery (COD)' : 'Cash on Delivery (COD / ပစ္စည်းရောက်ငွေချေ)',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Switch(
                                  value: isCod,
                                  activeColor: Colors.amber,
                                  onChanged: (v) => setState(() => isCod = v),
                                ),
                              ],
                            ),
                            if (isCod) ...[
                              const SizedBox(height: 6),
                              TextField(
                                controller: codAmountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'COD Amount to Collect by Courier (ကောက်ခံမည့်ငွေ) *',
                                  prefixIcon: Icon(Icons.attach_money_rounded, size: 18, color: Colors.amber),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Payment Amount Input (hidden if COD)
                    if (!isCod) ...[
                      TextField(
                        controller: payAmountCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Payment Amount to Collect (ကောက်ခံမည့်ငွေ) *',
                          prefixIcon: const Icon(Icons.payments_outlined, size: 20, color: Colors.green),
                          suffixIcon: TextButton(
                            onPressed: () {
                              setState(() {
                                payAmountCtrl.text = order.dueAmount.toStringAsFixed(0);
                              });
                            },
                            child: const Text('Full Due', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Payment Method Selector
                      DropdownButtonFormField<String>(
                        value: selectedPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method (ငွေပေးချေမှုစနစ်)',
                          prefixIcon: Icon(Icons.payment_rounded, size: 18, color: AppColors.primaryLight),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('💵 Cash (ငွေသား)')),
                          DropdownMenuItem(value: 'kpay', child: Text('📱 KBZPay')),
                          DropdownMenuItem(value: 'wave', child: Text('🟡 WavePay')),
                          DropdownMenuItem(value: 'cbpay', child: Text('🔵 CBPay')),
                          DropdownMenuItem(value: 'ayapay', child: Text('🔴 AYA Pay')),
                          DropdownMenuItem(value: 'bank_transfer', child: Text('🏦 Bank Transfer')),
                        ],
                        onChanged: (v) => setState(() => selectedPaymentMethod = v ?? 'cash'),
                      ),
                      const SizedBox(height: 10),

                      // Credit option for remaining due
                      if (!isFullSettlement && isRegisteredCustomer)
                        CheckboxListTile(
                          dense: true,
                          value: chargeDebtToAccount,
                          activeColor: AppColors.secondary,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Charge remaining ${Formatters.formatCurrency(remainingAfterPay)} to customer credit account (အကြွေးစာရင်းသွင်းမည်)',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                          ),
                          onChanged: (v) => setState(() => chargeDebtToAccount = v ?? false),
                        ),
                    ],

                    const SizedBox(height: 16),

                    // Settlement Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              backgroundColor: isCod
                                  ? Colors.amber.shade800
                                  : (isFullSettlement ? Colors.green : AppColors.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: !isCod && enteredAmount <= 0
                                ? null
                                : () async {
                                    final double deliveryFee = (fulfillmentType == 'DELIVERY' && selectedDeliveryService?.isInHouse == true)
                                        ? (double.tryParse(inHouseDeliveryFeeCtrl.text.trim()) ?? 0.0)
                                        : 0.0;
                                    final double riderCommissionAmount = (fulfillmentType == 'DELIVERY' && selectedDeliveryService?.isInHouse == true)
                                        ? selectedDeliveryService!.calculateCommission(deliveryFee)
                                        : 0.0;
                                    Get.back();
                                    await controller.collectOrderPayment(
                                      order: order,
                                      paymentAmount: isCod ? 0.0 : enteredAmount,
                                      paymentMethod: isCod ? 'cod' : selectedPaymentMethod,
                                      markCompleted: isFullSettlement || chargeDebtToAccount || isCod,
                                      chargeRemainingToDebt: chargeDebtToAccount && !isCod,
                                      deliveryType: fulfillmentType,
                                      deliveryServiceId: fulfillmentType == 'DELIVERY' ? selectedDeliveryService?.id : null,
                                      deliveryServiceName: fulfillmentType == 'DELIVERY' ? selectedDeliveryService?.name : null,
                                      isCod: isCod,
                                      codAmount: isCod ? codAmount : 0.0,
                                      deliveryFee: deliveryFee,
                                      riderCommissionAmount: riderCommissionAmount,
                                    );
                                  },
                            icon: Icon(
                              isCod ? Icons.local_shipping_rounded : Icons.check_circle_rounded,
                              size: 18,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isCod
                                    ? 'Dispatch with COD (${Formatters.formatCurrency(codAmount)})'
                                    : (isFullSettlement
                                        ? 'Settle Full & Complete Order'
                                        : 'Record Partial Payment'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
