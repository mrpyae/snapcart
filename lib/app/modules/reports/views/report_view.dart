import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/sale_order_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../utils/responsive.dart';
import '../../../utils/voucher_owner_dialogs.dart';
import '../controllers/report_controller.dart';

class ReportView extends StatefulWidget {
  const ReportView({Key? key}) : super(key: key);

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  late final ReportController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ReportController>()
        ? Get.find<ReportController>()
        : Get.put(ReportController());
    controller.loadDashboardMetrics();
    controller.loadSalesVouchers();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMobile ? 'Reports & Sales' : 'Reports & Sales Vouchers (အရောင်းမှတ်တမ်းနှင့် အစီရင်ခံစာ)',
                        style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Daily revenue, expense, profit & voucher records',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    controller.loadDashboardMetrics();
                    controller.loadSalesVouchers();
                  },
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  tooltip: 'Refresh Reports',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Financial Metrics Header
            _buildMetricsHeader(context, controller, isMobile),
            const SizedBox(height: 18),

            // Sales Vouchers Filter Bar & Search
            _buildVoucherFiltersBar(context, controller, isMobile),
            const SizedBox(height: 14),

            // Filtered Aggregate Summary Bar
            _buildFilteredSummaryBanner(context, controller),
            const SizedBox(height: 14),

            // Sales Vouchers List / Table
            _buildVouchersList(context, controller, isMobile),
          ],
        ),
      ),
    );
  }

  // Top Financial Metric Cards
  Widget _buildMetricsHeader(BuildContext context, ReportController controller, bool isMobile) {
    return Obx(() {
      String presetLabel = 'Period';
      String presetSubLabel = 'ကာလပိုင်း';

      switch (controller.selectedDatePreset.value) {
        case 'TODAY':
          presetLabel = "Today's";
          presetSubLabel = 'ယနေ့';
          break;
        case 'YESTERDAY':
          presetLabel = "Yesterday's";
          presetSubLabel = 'မနေ့က';
          break;
        case 'THIS_WEEK':
          presetLabel = "This Week's";
          presetSubLabel = 'ဒီတစ်ပတ်';
          break;
        case 'THIS_MONTH':
          presetLabel = "This Month's";
          presetSubLabel = 'ဒီလ';
          break;
        case 'ALL':
          presetLabel = "All-Time";
          presetSubLabel = 'စုစုပေါင်း';
          break;
        default:
          presetLabel = "Filtered";
          presetSubLabel = 'ရွေးချယ်ထားသော';
          break;
      }

      final cards = [
        _buildMetricCard(
          title: "$presetLabel Sales Revenue",
          subTitle: '$presetSubLabel အရောင်းရငွေ',
          value: Formatters.formatCurrency(controller.filteredTotalRevenue),
          icon: Icons.monetization_on_outlined,
          color: AppColors.success,
          footer: '${controller.filteredVoucherCount} Orders Completed',
        ),
        _buildMetricCard(
          title: "$presetLabel Expenses",
          subTitle: '$presetSubLabel ကုန်ကျစရိတ်',
          value: Formatters.formatCurrency(controller.filteredExpenses.value),
          icon: Icons.receipt_long_outlined,
          color: AppColors.error,
          footer: 'Store Outflows',
        ),
        _buildMetricCard(
          title: "Estimated Net Profit",
          subTitle: 'ခန့်မှန်း အသားတင်အမြတ်',
          value: Formatters.formatCurrency(controller.filteredProfit),
          icon: Icons.query_stats_rounded,
          color: controller.filteredProfit >= 0 ? AppColors.secondary : AppColors.error,
          footer: 'Revenue minus expenses',
        ),
      ];

      if (isMobile) {
        return Column(
          children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList(),
        );
      }

      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 14),
          Expanded(child: cards[1]),
          const SizedBox(width: 14),
          Expanded(child: cards[2]),
        ],
      );
    });
  }

  Widget _buildMetricCard({
    required String title,
    required String subTitle,
    required String value,
    required IconData icon,
    required Color color,
    required String footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                    Text(subTitle, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(footer, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // Voucher Filter & Search Bar
  Widget _buildVoucherFiltersBar(BuildContext context, ReportController controller, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  children: [
                    TextField(
                      onChanged: (v) {
                        controller.searchQuery.value = v.trim();
                        controller.loadSalesVouchers();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search customer, phone, voucher...',
                        prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: controller.selectedPaymentMethod.value,
                          icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textSecondary),
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All Payments', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'cash', child: Text('💵 Cash', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'kpay', child: Text('📱 KBZPay', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'wave', child: Text('🟡 WavePay', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'cbpay', child: Text('🔵 CBPay', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'ayapay', child: Text('🔴 AYA Pay', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'credit', child: Text('🧾 Credit', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (v) {
                            controller.selectedPaymentMethod.value = v ?? 'ALL';
                            controller.loadSalesVouchers();
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Search Input by Customer or Voucher No
                    Expanded(
                      child: TextField(
                        onChanged: (v) {
                          controller.searchQuery.value = v.trim();
                          controller.loadSalesVouchers();
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search by customer name, phone, voucher no, cashier...',
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Payment Method Filter Dropdown
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.cardBgLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: controller.selectedPaymentMethod.value,
                              icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textSecondary),
                              items: const [
                                DropdownMenuItem(value: 'ALL', child: Text('All Payments', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'cash', child: Text('💵 Cash', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'kpay', child: Text('📱 KBZPay', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'wave', child: Text('🟡 WavePay', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'cbpay', child: Text('🔵 CBPay', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'ayapay', child: Text('🔴 AYA Pay', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'credit', child: Text('🧾 Credit', style: TextStyle(fontSize: 12))),
                              ],
                              onChanged: (v) {
                                controller.selectedPaymentMethod.value = v ?? 'ALL';
                                controller.loadSalesVouchers();
                              },
                            ),
                          ),
                        )),
                  ],
                ),
          const SizedBox(height: 10),

          // Date Range Presets & Custom Date Picker
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() {
              return Row(
                children: [
                  _buildDatePresetChip('Today (ယနေ့)', 'TODAY', controller, context),
                  _buildDatePresetChip('Yesterday (မနေ့က)', 'YESTERDAY', controller, context),
                  _buildDatePresetChip('This Week (ဒီအပတ်)', 'THIS_WEEK', controller, context),
                  _buildDatePresetChip('This Month (ဒီလ)', 'THIS_MONTH', controller, context),
                  _buildDatePresetChip('All Time (အားလုံး)', 'ALL', controller, context),
                  _buildDatePresetChip('📅 Custom Range', 'CUSTOM', controller, context),

                  if (controller.startDate.value != null && controller.endDate.value != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 0.8),
                      ),
                      child: Text(
                        '${DateFormat('yyyy-MM-dd').format(controller.startDate.value!)} ~ ${DateFormat('yyyy-MM-dd').format(controller.endDate.value!)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePresetChip(String label, String preset, ReportController controller, BuildContext context) {
    final isSelected = controller.selectedDatePreset.value == preset;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => controller.setDatePreset(preset, context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.cardBgLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
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

  Widget _buildFilteredSummaryBanner(BuildContext context, ReportController controller) {
    final isMobile = Responsive.isMobile(context);
    return Obx(() {
      final pills = [
        _buildSummaryPill('Total Sales', Formatters.formatCurrency(controller.filteredTotalRevenue), AppColors.textPrimary),
        _buildSummaryPill('Total Paid', Formatters.formatCurrency(controller.filteredTotalPaid), Colors.green),
        if (controller.filteredTotalDue > 0)
          _buildSummaryPill('Total Due', Formatters.formatCurrency(controller.filteredTotalDue), AppColors.error),
      ];

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.secondary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${controller.filteredVoucherCount} Sales Vouchers Found',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 16, runSpacing: 6, children: pills),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.secondary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${controller.filteredVoucherCount} Sales Vouchers Found',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      pills[0],
                      const SizedBox(width: 14),
                      pills[1],
                      if (controller.filteredTotalDue > 0) ...[
                        const SizedBox(width: 14),
                        pills[2],
                      ],
                    ],
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildSummaryPill(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // Sales Vouchers List / Cards
  Widget _buildVouchersList(BuildContext context, ReportController controller, bool isMobile) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.salesVouchers.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
              SizedBox(height: 10),
              Text(
                'No sales vouchers found for selected filters and date range.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.salesVouchers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final voucher = controller.salesVouchers[index];
          return _buildVoucherCard(context, voucher, isMobile);
        },
      );
    });
  }

  Widget _buildVoucherCard(BuildContext context, SaleOrderModel voucher, bool isMobile) {
    final bool isUnpaidDue = voucher.dueAmount > 0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Voucher No, Payment Method Badge, Due Badge & Receipt Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        voucher.voucherNo,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: _getPaymentMethodColor(voucher.paymentMethod).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _getPaymentMethodColor(voucher.paymentMethod), width: 0.8),
                      ),
                      child: Text(
                        voucher.paymentMethod.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getPaymentMethodColor(voucher.paymentMethod)),
                      ),
                    ),
                    if (isUnpaidDue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.error, width: 0.8),
                        ),
                        child: const Text('CREDIT DUE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.error)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showVoucherDetailModal(context, voucher),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.visibility_rounded, size: 13, color: AppColors.secondary),
                          SizedBox(width: 4),
                          Text('Receipt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Owner Actions',
                    onSelected: (val) {
                      if (val == 'edit') {
                        VoucherOwnerDialogs.openEditDialog(context, voucher, onUpdated: () => controller.loadSalesVouchers());
                      } else if (val == 'delete') {
                        VoucherOwnerDialogs.confirmAndDelete(context, voucher, onDeleted: () => controller.loadSalesVouchers());
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_note_rounded, size: 16, color: Colors.blueAccent),
                            SizedBox(width: 8),
                            Text('Edit Voucher (Owner)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever_rounded, size: 16, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Void / Delete (Owner)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.parse(voucher.saleDate)),
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),

          // Customer & Staff Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 15, color: AppColors.primaryLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        voucher.customerName != null && voucher.customerName!.isNotEmpty
                            ? '${voucher.customerName} ${voucher.customerPhone != null ? "(${voucher.customerPhone})" : ""}'
                            : 'ဆိုင်လာဝယ်သူ',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Cashier: ${voucher.userName}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Items summary table
          if (voucher.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: voucher.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '• ${item.productName} x ${Formatters.formatQty(item.quantity, unit: item.unit)}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
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
          const SizedBox(height: 8),

          // Financial row: Subtotal, Discount, Grand Total, Paid, Due
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        Text(
                          Formatters.formatCurrency(voucher.grandTotal),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (voucher.discountAmount > 0)
                          Text('Discount: -${Formatters.formatCurrency(voucher.discountAmount)}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                        Text('Paid: ${Formatters.formatCurrency(voucher.paidAmount)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.green)),
                        if (isUnpaidDue)
                          Text('Due: ${Formatters.formatCurrency(voucher.dueAmount)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.error)),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (voucher.discountAmount > 0) ...[
                          Text('Discount: -${Formatters.formatCurrency(voucher.discountAmount)}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                        ],
                        Text('Paid: ${Formatters.formatCurrency(voucher.paidAmount)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.green)),
                        if (isUnpaidDue) ...[
                          Text('Due: ${Formatters.formatCurrency(voucher.dueAmount)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.error)),
                        ],
                      ],
                    ),
                    Text(
                      'Grand Total: ${Formatters.formatCurrency(voucher.grandTotal)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'kpay':
        return Colors.blue;
      case 'wave':
        return Colors.amber.shade800;
      case 'cbpay':
        return Colors.indigoAccent;
      case 'ayapay':
        return Colors.redAccent;
      case 'credit':
        return Colors.purple;
      case 'cash':
      default:
        return Colors.green;
    }
  }

  void _showVoucherDetailModal(BuildContext context, SaleOrderModel voucher) {
    Responsive.showAdaptiveSheet(
      context: context,
      mobileSizeInitial: 0.90,
      dialogMaxWidth: 460,
      builder: (ctx, scroll) => Container(
        color: AppColors.cardBg,
        child: SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Sale Voucher (အရောင်းဘောက်ချာ)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text('Voucher: ${voucher.voucherNo}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                  Text(DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.parse(voucher.saleDate)), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text('Customer: ${voucher.customerName ?? "Walk-in Customer"}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                  Text('Cashier: ${voucher.userName}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.cardBgLight, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Item', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        Text('Subtotal', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      ],
                    ),
                    const Divider(height: 10),
                    ...voucher.items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text('${i.productName} (${Formatters.formatQty(i.quantity, unit: i.unit)} x ${Formatters.formatCurrency(i.unitPrice)})', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                          const SizedBox(width: 8),
                          Text(Formatters.formatCurrency(i.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Subtotal:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(Formatters.formatCurrency(voucher.subtotal), style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
              ]),
              if (voucher.discountAmount > 0) ...[
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Discount:', style: TextStyle(fontSize: 12, color: Colors.orange)),
                  Text('-${Formatters.formatCurrency(voucher.discountAmount)}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                ]),
              ],
              if (voucher.taxAmount > 0) ...[
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Tax:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('+${Formatters.formatCurrency(voucher.taxAmount)}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                ]),
              ],
              if (voucher.deliveryFee > 0) ...[
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Delivery Fee:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('+${Formatters.formatCurrency(voucher.deliveryFee)}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                ]),
              ],
              const Divider(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Grand Total:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(Formatters.formatCurrency(voucher.grandTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Paid (${voucher.paymentMethod.toUpperCase()}):', style: const TextStyle(fontSize: 12, color: Colors.green)),
                Text(Formatters.formatCurrency(voucher.paidAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
              ]),
              if (voucher.changeAmount > 0) ...[
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Change Returned:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(Formatters.formatCurrency(voucher.changeAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ]),
              ],
              if (voucher.dueAmount > 0) ...[
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Due (အကြွေးကျန်):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error)),
                  Text(Formatters.formatCurrency(voucher.dueAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error)),
                ]),
              ],
              const SizedBox(height: 14),

              // Owner Access Actions Panel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3), width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.admin_panel_settings_rounded, size: 16, color: Colors.amber),
                        SizedBox(width: 6),
                        Text('Owner Access', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(ctx, rootNavigator: true).pop();
                            VoucherOwnerDialogs.openEditDialog(context, voucher, onUpdated: () => controller.loadSalesVouchers());
                          },
                          icon: const Icon(Icons.edit_note_rounded, size: 15, color: Colors.blueAccent),
                          label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(ctx, rootNavigator: true).pop();
                            VoucherOwnerDialogs.confirmAndDelete(context, voucher, onDeleted: () => controller.loadSalesVouchers());
                          },
                          icon: const Icon(Icons.delete_forever_rounded, size: 15, color: AppColors.error),
                          label: const Text('Void / Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error)),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
