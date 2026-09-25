import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/delivery_service_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../utils/responsive.dart';
import '../controllers/delivery_service_controller.dart';

class DeliveryServiceView extends StatelessWidget {
  const DeliveryServiceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DeliveryServiceController());
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: Responsive.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Top Actions
              _buildHeader(context, controller, isMobile),
              const SizedBox(height: 14),

              // Tab Switcher (Couriers vs In-House Delivery Income)
              _buildTabSwitcher(controller, isMobile),
              const SizedBox(height: 14),

              // Tab Content
              Expanded(
                child: Obx(() {
                  if (controller.currentTabIndex.value == 0) {
                    return _buildCouriersTab(context, controller, isMobile);
                  } else {
                    return _buildInHouseIncomeTab(context, controller, isMobile);
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tab Switcher
  Widget _buildTabSwitcher(DeliveryServiceController controller, bool isMobile) {
    return Obx(() {
      final tab = controller.currentTabIndex.value;

      Widget buildCourierTabBtn() {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => controller.currentTabIndex.value = 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 18, vertical: 8),
            decoration: BoxDecoration(
              color: tab == 0 ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping_rounded,
                  size: 16,
                  color: tab == 0 ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isMobile ? 'Couriers & COD' : 'Couriers & COD Remittances',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: tab == 0 ? FontWeight.bold : FontWeight.normal,
                      color: tab == 0 ? Colors.white : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      Widget buildInHouseTabBtn() {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            controller.currentTabIndex.value = 1;
            controller.loadIncomeSummary();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 18, vertical: 8),
            decoration: BoxDecoration(
              color: tab == 1 ? Colors.teal : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.storefront_rounded,
                  size: 16,
                  color: tab == 1 ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    Get.locale?.languageCode == 'my'
                        ? (isMobile ? 'ဆိုင်တွင်း' : 'ဆိုင်တွင်းပို့ဆောင်ခ')
                        : (isMobile ? 'In-House' : 'In-House Delivery'),
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12.5,
                      fontWeight: tab == 1 ? FontWeight.bold : FontWeight.normal,
                      color: tab == 1 ? Colors.white : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        width: isMobile ? double.infinity : null,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: isMobile
            ? Row(
                children: [
                  Expanded(child: buildCourierTabBtn()),
                  const SizedBox(width: 4),
                  Expanded(child: buildInHouseTabBtn()),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildCourierTabBtn(),
                  const SizedBox(width: 4),
                  buildInHouseTabBtn(),
                ],
              ),
      );
    });
  }

  // Couriers Tab View
  Widget _buildCouriersTab(BuildContext context, DeliveryServiceController controller, bool isMobile) {
    return Column(
      children: [
        // Metrics Banner
        _buildMetricsBanner(controller, isMobile),
        const SizedBox(height: 14),

        // Search & Filter Bar
        _buildSearchBar(controller, isMobile),
        const SizedBox(height: 14),

        // Delivery Services List / Grid
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
            }

            if (controller.services.isEmpty) {
              return _buildEmptyState(context, controller);
            }

            return isMobile
                ? ListView.separated(
                    itemCount: controller.services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final service = controller.services[index];
                      return _buildServiceCard(context, controller, service, isMobile);
                    },
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 440,
                      mainAxisExtent: 285,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: controller.services.length,
                    itemBuilder: (context, index) {
                      final service = controller.services[index];
                      return _buildServiceCard(context, controller, service, isMobile);
                    },
                  );
          }),
        ),
      ],
    );
  }

  // In-House Delivery Income Tab View
  Widget _buildInHouseIncomeTab(BuildContext context, DeliveryServiceController controller, bool isMobile) {
    final inHouseRiders = controller.services.where((s) => s.isInHouse).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter bar: Rider selection & Preset Dates
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: isMobile ? 10 : 8),
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
                        const Icon(Icons.two_wheeler_rounded, size: 18, color: Colors.tealAccent),
                        const SizedBox(width: 8),
                        const Text('Rider: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Obx(() => DropdownButton<String>(
                                isExpanded: true,
                                value: controller.selectedRiderId.value.isEmpty ? '' : controller.selectedRiderId.value,
                                dropdownColor: AppColors.cardBgLight,
                                underline: const SizedBox(),
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                                items: [
                                  DropdownMenuItem(value: '', child: Text(Get.locale?.languageCode == 'my' ? 'ဆိုင်တွင်းပို့ဆောင်သူများ အားလုံး' : 'All In-House Riders', overflow: TextOverflow.ellipsis)),
                                  ...inHouseRiders.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name, overflow: TextOverflow.ellipsis))),
                                ],
                                onChanged: (val) {
                                  controller.selectedRiderId.value = val ?? '';
                                  controller.loadIncomeSummary();
                                },
                              )),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primaryLight),
                          tooltip: 'Refresh',
                          onPressed: () => controller.loadIncomeSummary(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDateFilterChip(controller, 'Today', DateTime.now(), DateTime.now()),
                          const SizedBox(width: 6),
                          _buildDateFilterChip(controller, 'Last 7 Days', DateTime.now().subtract(const Duration(days: 7)), DateTime.now()),
                          const SizedBox(width: 6),
                          _buildDateFilterChip(controller, 'Last 30 Days', DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
                          const SizedBox(width: 6),
                          _buildDateFilterChip(controller, 'All Time', null, null),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.two_wheeler_rounded, size: 18, color: Colors.tealAccent),
                    const SizedBox(width: 8),
                    const Text('Rider: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    Obx(() => DropdownButton<String>(
                          value: controller.selectedRiderId.value.isEmpty ? '' : controller.selectedRiderId.value,
                          dropdownColor: AppColors.cardBgLight,
                          underline: const SizedBox(),
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                          items: [
                            DropdownMenuItem(value: '', child: Text(Get.locale?.languageCode == 'my' ? 'ဆိုင်တွင်းပို့ဆောင်သူများ အားလုံး' : 'All In-House Riders')),
                            ...inHouseRiders.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))),
                          ],
                          onChanged: (val) {
                            controller.selectedRiderId.value = val ?? '';
                            controller.loadIncomeSummary();
                          },
                        )),
                    const Spacer(),
                    // Preset range buttons
                    Wrap(
                      spacing: 6,
                      children: [
                        _buildDateFilterChip(controller, 'Today', DateTime.now(), DateTime.now()),
                        _buildDateFilterChip(controller, 'Last 7 Days', DateTime.now().subtract(const Duration(days: 7)), DateTime.now()),
                        _buildDateFilterChip(controller, 'Last 30 Days', DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
                        _buildDateFilterChip(controller, 'All Time', null, null),
                      ],
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primaryLight),
                      tooltip: 'Refresh',
                      onPressed: () => controller.loadIncomeSummary(),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),

        // Income Metrics Cards
        Obx(() => _buildInHouseMetricsBanner(controller, isMobile)),
        const SizedBox(height: 14),

        // Order Records Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primaryLight),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isMobile ? 'Orders Log' : 'In-House Delivery Orders Log',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final orders = (controller.incomeSummary['orders'] as List<dynamic>?) ?? [];
              return Text(
                '${orders.length} order(s)',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              );
            }),
          ],
        ),
        const SizedBox(height: 10),

        // Delivery Orders Table / List
        Expanded(
          child: Obx(() {
            if (controller.isLoadingIncome.value) {
              return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
            }

            final orders = (controller.incomeSummary['orders'] as List<dynamic>?) ?? [];
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                    const SizedBox(height: 10),
                    const Text(
                      'No In-House Delivery Orders Found',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'When orders are delivered with in-house riders, income & commissions will appear here.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, i) {
                    final item = orders[i] as Map<String, dynamic>;
                    final fee = double.tryParse(item['delivery_fee']?.toString() ?? '0') ?? 0.0;
                    final comm = double.tryParse(item['rider_commission_amount']?.toString() ?? '0') ?? 0.0;
                    final net = fee - comm;
                    final isCod = item['is_cod'] == 1 || item['is_cod'] == true;
                    final codAmt = double.tryParse(item['cod_amount']?.toString() ?? '0') ?? 0.0;

                    if (isMobile) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.two_wheeler_rounded, color: Colors.tealAccent, size: 15),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          item['voucher_no']?.toString() ?? 'Voucher',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isCod) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'COD: ${Formatters.formatCurrency(codAmt)}',
                                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.amber),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Net: ', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
                                      Text(
                                        Formatters.formatCurrency(net),
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rider: ${item['delivery_service_name'] ?? '-'} • Customer: ${item['customer_name'] ?? 'Walk-in'} • Date: ${(item['sale_date']?.toString() ?? '').substring(0, 10)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Delivery Fee: +${Formatters.formatCurrency(fee)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.tealAccent),
                                ),
                                Text(
                                  'Comm: -${Formatters.formatCurrency(comm)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.purpleAccent),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: Colors.tealAccent, size: 20),
                      ),
                      title: Row(
                        children: [
                          Text(
                            item['voucher_no']?.toString() ?? 'Voucher',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          if (isCod)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'COD: ${Formatters.formatCurrency(codAmt)}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        'Rider: ${item['delivery_service_name'] ?? '-'} • Customer: ${item['customer_name'] ?? 'Walk-in'} • Date: ${(item['sale_date']?.toString() ?? '').substring(0, 10)}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+${Formatters.formatCurrency(fee)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                              ),
                              Text(
                                'Comm: -${Formatters.formatCurrency(comm)}',
                                style: const TextStyle(fontSize: 10.5, color: Colors.purpleAccent),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Store Net', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                                Text(
                                  Formatters.formatCurrency(net),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // In-House Metrics Banner
  Widget _buildInHouseMetricsBanner(DeliveryServiceController controller, bool isMobile) {
    final summary = controller.incomeSummary;
    final trips = summary['total_trips'] ?? 0;
    final totalFee = double.tryParse(summary['total_delivery_income']?.toString() ?? '0') ?? 0.0;
    final totalComm = double.tryParse(summary['total_rider_commission']?.toString() ?? '0') ?? 0.0;
    final netIncome = double.tryParse(summary['net_delivery_income']?.toString() ?? '0') ?? 0.0;

    final bool isMm = Get.locale?.languageCode == 'my';
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _buildMetricItem(
                label: isMm ? 'ခေါက်ရေ' : 'Total Trips',
                value: isMm ? '$trips ခေါက်' : '$trips Trips',
                icon: Icons.local_shipping_rounded,
                color: Colors.cyan,
                isMobile: isMobile,
              ),
              const SizedBox(width: 8),
              _buildMetricItem(
                label: isMm ? 'ပို့ဆောင်ခ' : 'Delivery Income',
                value: Formatters.formatCurrency(totalFee),
                icon: Icons.payments_rounded,
                color: Colors.tealAccent,
                isMobile: isMobile,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetricItem(
                label: isMm ? 'ကော်မရှင်' : 'Rider Comm.',
                value: Formatters.formatCurrency(totalComm),
                icon: Icons.account_circle_rounded,
                color: Colors.purpleAccent,
                isMobile: isMobile,
              ),
              const SizedBox(width: 8),
              _buildMetricItem(
                label: isMm ? 'အသားတင်' : 'Store Net',
                value: Formatters.formatCurrency(netIncome),
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.greenAccent,
                isMobile: isMobile,
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildMetricItem(
          label: isMm ? 'စုစုပေါင်း ခေါက်ရေ' : 'Total Trips',
          value: isMm ? '$trips ခေါက်' : '$trips Trips',
          icon: Icons.local_shipping_rounded,
          color: Colors.cyan,
        ),
        const SizedBox(width: 10),
        _buildMetricItem(
          label: isMm ? 'စုစုပေါင်း ပို့ဆောင်ခ' : 'Total Delivery Income',
          value: Formatters.formatCurrency(totalFee),
          icon: Icons.payments_rounded,
          color: Colors.tealAccent,
        ),
        const SizedBox(width: 10),
        _buildMetricItem(
          label: isMm ? 'ပို့ဆောင်သူ ကော်မရှင်' : 'Rider Commission',
          value: Formatters.formatCurrency(totalComm),
          icon: Icons.account_circle_rounded,
          color: Colors.purpleAccent,
        ),
        const SizedBox(width: 10),
        _buildMetricItem(
          label: isMm ? 'ဆိုင် အသားတင် ပို့ဆောင်ခ' : 'Net Store Delivery Income',
          value: Formatters.formatCurrency(netIncome),
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.greenAccent,
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isMobile = false,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: isMobile ? 18 : 20),
            ),
            SizedBox(width: isMobile ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: isMobile ? 10 : 10.5, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.bold, color: color),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterChip(
    DeliveryServiceController controller,
    String label,
    DateTime? start,
    DateTime? end,
  ) {
    final bool isSelected = (start == null && controller.incomeStartDate.value == null) ||
        (start != null &&
            controller.incomeStartDate.value != null &&
            start.year == controller.incomeStartDate.value!.year &&
            start.month == controller.incomeStartDate.value!.month &&
            start.day == controller.incomeStartDate.value!.day);

    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textSecondary)),
      backgroundColor: isSelected ? Colors.teal : AppColors.cardBgLight,
      side: BorderSide(color: isSelected ? Colors.tealAccent : AppColors.border),
      onPressed: () {
        controller.incomeStartDate.value = start;
        controller.incomeEndDate.value = end;
        controller.loadIncomeSummary();
      },
    );
  }

  // Header
  Widget _buildHeader(BuildContext context, DeliveryServiceController controller, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Expanded(
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
                    child: const Icon(Icons.local_shipping_rounded, color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isMobile ? 'Delivery Services' : 'Delivery Services & COD Management',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (!isMobile) ...[
                const SizedBox(height: 4),
                const Text(
                  'Manage couriers, base shipping fees, and COD receivable settlements',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => _showAddEditDialog(context, controller),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(isMobile ? 'Add' : 'Add Courier', style: TextStyle(fontSize: isMobile ? 12 : 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // Metrics Banner
  Widget _buildMetricsBanner(DeliveryServiceController controller, bool isMobile) {
    return Obx(() {
      final totalReceivable = controller.totalReceivable.value;
      final activeCount = controller.services.where((s) => s.isActive).length;
      final totalCount = controller.services.length;

      final codCard = Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade900.withOpacity(0.2),
              AppColors.cardBg,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Get.locale?.languageCode == 'my' ? 'စုစုပေါင်း COD ရရန်ကျန်ငွေ' : 'Total COD Receivable',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.formatCurrency(totalReceivable),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final statsCard = Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_outline_rounded, color: AppColors.primaryLight, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Couriers', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    '$activeCount Active / $totalCount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      if (isMobile) {
        return Column(
          children: [
            codCard,
            const SizedBox(height: 10),
            statsCard,
          ],
        );
      }

      return Row(
        children: [
          Expanded(flex: 2, child: codCard),
          const SizedBox(width: 12),
          Expanded(child: statsCard),
        ],
      );
    });
  }

  // Search Bar
  Widget _buildSearchBar(DeliveryServiceController controller, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              onChanged: (val) {
                controller.searchQuery.value = val;
                controller.loadServices();
              },
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: isMobile ? 'Search couriers...' : 'Search courier name, phone, or coverage area...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Obx(() => FilterChip(
              label: Text(isMobile ? 'Active' : 'Active Only', style: const TextStyle(fontSize: 11.5)),
              selected: controller.filterActiveOnly.value,
              onSelected: (selected) {
                controller.filterActiveOnly.value = selected;
                controller.loadServices();
              },
              selectedColor: AppColors.primary.withOpacity(0.3),
              backgroundColor: AppColors.cardBg,
              checkmarkColor: AppColors.primaryLight,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: controller.filterActiveOnly.value ? AppColors.primary : AppColors.border,
                ),
              ),
            )),
      ],
    );
  }

  // Delivery Service Card
  Widget _buildServiceCard(
    BuildContext context,
    DeliveryServiceController controller,
    DeliveryServiceModel service,
    bool isMobile,
  ) {
    final hasReceivable = service.receivableBalance > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasReceivable ? Colors.amber.withOpacity(0.4) : AppColors.border,
          width: hasReceivable ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name, Active Badge & Options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (service.isInHouse ? Colors.teal : (service.isActive ? AppColors.primary : AppColors.textMuted)).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        service.isInHouse ? Icons.two_wheeler_rounded : Icons.delivery_dining_rounded,
                        color: service.isInHouse ? Colors.tealAccent : (service.isActive ? AppColors.primaryLight : AppColors.textMuted),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active switch
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: service.isActive,
                      activeColor: AppColors.online,
                      onChanged: (_) => controller.toggleActive(service),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                    color: AppColors.cardBgLight,
                    onSelected: (action) {
                      if (action == 'edit') {
                        _showAddEditDialog(context, controller, service: service);
                      } else if (action == 'history') {
                        _showRemittanceHistoryDialog(context, controller, service);
                      } else if (action == 'delete') {
                        _confirmDelete(context, controller, service);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryLight),
                            SizedBox(width: 8),
                            Text('Edit Details', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'history',
                        child: Row(
                          children: [
                            Icon(Icons.history_rounded, size: 16, color: AppColors.secondary),
                            SizedBox(width: 8),
                            Text('Remittance History', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(fontSize: 12.5, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Badges: In-House vs External, Commission vs Salary, Default Fee
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: service.isInHouse ? Colors.teal.withOpacity(0.2) : Colors.blueGrey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: service.isInHouse ? Colors.teal.shade400 : Colors.blueGrey.shade400,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  service.isInHouse
                      ? (Get.locale?.languageCode == 'my' ? 'ဆိုင်ပိုင်' : 'In-House')
                      : (Get.locale?.languageCode == 'my' ? 'ပြင်ပ ပို့ဆောင်ရေး' : 'External Courier'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: service.isInHouse ? Colors.tealAccent : Colors.blueGrey.shade200,
                  ),
                ),
              ),
              if (service.isInHouse) ...[
                if (service.isCommissionBased)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.deepPurple.shade300, width: 0.8),
                    ),
                    child: Text(
                      'Commission: ${service.commissionVal.toStringAsFixed(0)}${service.commissionType == 'PERCENT' ? '%' : ' Ks'}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.purpleAccent),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade300, width: 0.8),
                    ),
                    child: Text(
                      Get.locale?.languageCode == 'my' ? 'လစာပေး' : 'Salary',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.lightBlueAccent),
                    ),
                  ),
                if (service.defaultDeliveryFee > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.shade400, width: 0.8),
                    ),
                    child: Text(
                      'Default: ${Formatters.formatCurrency(service.defaultDeliveryFee)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.amber),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Contact & Area Info
          if ((service.phone != null && service.phone!.isNotEmpty) ||
              (service.contactPerson != null && service.contactPerson!.isNotEmpty))
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (service.phone != null && service.phone!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(service.phone!, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                if (service.contactPerson != null && service.contactPerson!.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isMobile ? 220 : 300),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            service.contactPerson!,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

          if (service.coverageArea != null && service.coverageArea!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    service.coverageArea!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          isMobile ? const SizedBox(height: 12) : const Spacer(),

          // Receivable Balance Highlight Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasReceivable ? Colors.amber.shade900.withOpacity(0.15) : AppColors.cardBgLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasReceivable ? Colors.amber.shade700.withOpacity(0.4) : AppColors.border,
              ),
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              service.isInHouse ? 'Pending COD:' : 'COD Receivable:',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              Formatters.formatCurrency(service.receivableBalance),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: hasReceivable ? Colors.amber : AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      if (hasReceivable) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 34,
                          child: ElevatedButton.icon(
                            onPressed: () => _showRecordRemittanceDialog(context, controller, service),
                            icon: const Icon(Icons.receipt_long_rounded, size: 14),
                            label: const Text(
                              'Receive Payment',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.isInHouse
                                ? (Get.locale?.languageCode == 'my' ? 'ပို့ဆောင်သူထံမှ ရရန်ကျန် COD:' : 'Pending Rider COD:')
                                : (Get.locale?.languageCode == 'my' ? 'ရရန်ကျန်ငွေ:' : 'COD Receivable:'),
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                          Text(
                            Formatters.formatCurrency(service.receivableBalance),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: hasReceivable ? Colors.amber : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      // Receive Payment Button
                      SizedBox(
                        width: 145,
                        height: 34,
                        child: ElevatedButton.icon(
                          onPressed: hasReceivable ? () => _showRecordRemittanceDialog(context, controller, service) : null,
                          icon: const Icon(Icons.receipt_long_rounded, size: 14),
                          label: Text(
                            hasReceivable ? 'Receive Payment' : 'No Pending COD',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasReceivable ? Colors.green : AppColors.cardBg,
                            foregroundColor: hasReceivable ? Colors.white : AppColors.textMuted,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Add / Edit Modal Dialog
  void _showAddEditDialog(
    BuildContext context,
    DeliveryServiceController controller, {
    DeliveryServiceModel? service,
  }) {
    final isEdit = service != null;
    final nameCtrl = TextEditingController(text: service?.name ?? '');
    final phoneCtrl = TextEditingController(text: service?.phone ?? '');
    final contactCtrl = TextEditingController(text: service?.contactPerson ?? '');
    final areaCtrl = TextEditingController(text: service?.coverageArea ?? '');
    final notesCtrl = TextEditingController(text: service?.notes ?? '');

    // In-House & Commission State
    String serviceType = service?.serviceType ?? 'EXTERNAL';
    String riderType = service?.riderType ?? 'SALARY';
    String commissionType = service?.commissionType ?? 'PERCENT';
    final commissionValCtrl = TextEditingController(
      text: service != null && service.commissionVal > 0 ? service.commissionVal.toStringAsFixed(0) : '',
    );
    final defaultDeliveryFeeCtrl = TextEditingController(
      text: service != null && service.defaultDeliveryFee > 0 ? service.defaultDeliveryFee.toStringAsFixed(0) : '',
    );

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final screenWidth = MediaQuery.of(context).size.width;
            return Container(
              width: screenWidth < 540 ? screenWidth * 0.94 : 500,
              constraints: const BoxConstraints(maxWidth: 500),
              padding: EdgeInsets.all(screenWidth < 540 ? 14 : 22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                serviceType == 'IN_HOUSE' ? Icons.two_wheeler_rounded : Icons.local_shipping_rounded,
                                color: serviceType == 'IN_HOUSE' ? Colors.tealAccent : AppColors.primaryLight,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isEdit ? 'Edit Delivery Service' : 'Add Delivery Service',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Service Type Selection (External vs In-House)
                    Text(Get.locale?.languageCode == 'my' ? 'ဝန်ဆောင်မှု အမျိုးအစား:' : 'Service Type:',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_shipping_outlined, size: 15),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text('External Courier', style: TextStyle(fontSize: 11.5), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            selected: serviceType == 'EXTERNAL',
                            selectedColor: AppColors.primary,
                            onSelected: (_) => setState(() => serviceType = 'EXTERNAL'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.two_wheeler_rounded, size: 15),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(Get.locale?.languageCode == 'my' ? 'ဆိုင်ပိုင် ပို့ဆောင်သူ' : 'In-House Rider', style: const TextStyle(fontSize: 11.5), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            selected: serviceType == 'IN_HOUSE',
                            selectedColor: Colors.teal,
                            onSelected: (_) => setState(() => serviceType = 'IN_HOUSE'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: serviceType == 'IN_HOUSE' ? 'Rider / Delivery Person Name *' : 'Courier / Company Name *',
                        hintText: serviceType == 'IN_HOUSE' ? 'e.g. Ko Zaw (Shop Rider), Rider 1' : 'e.g. Royal Express, Ninja Van',
                        prefixIcon: Icon(serviceType == 'IN_HOUSE' ? Icons.person_rounded : Icons.business_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // In-House Configuration Container
                    if (serviceType == 'IN_HOUSE') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade900.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal.shade700.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.settings_outlined, size: 16, color: Colors.tealAccent),
                                SizedBox(width: 6),
                                Text('In-House Delivery & Compensation Setup',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                              ],
                            ),
                            const SizedBox(height: 10),

                            TextField(
                              controller: defaultDeliveryFeeCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Default Delivery Price to Customer (Ks)',
                                hintText: 'e.g. 2000, 2500',
                                prefixIcon: Icon(Icons.monetization_on_outlined, size: 18, color: Colors.tealAccent),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 10),

                            Text(Get.locale?.languageCode == 'my' ? 'ပို့ဆောင်သူ အကျိုးခံစားခွင့်:' : 'Rider Compensation:',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text(Get.locale?.languageCode == 'my' ? 'လစာပေး' : 'Salary-based', style: const TextStyle(fontSize: 11)),
                                  selected: riderType == 'SALARY',
                                  selectedColor: Colors.blue.shade700,
                                  onSelected: (_) => setState(() => riderType = 'SALARY'),
                                ),
                                ChoiceChip(
                                  label: Text(Get.locale?.languageCode == 'my' ? 'ကော်မရှင်စား' : 'Commission-based', style: const TextStyle(fontSize: 11)),
                                  selected: riderType == 'COMMISSION',
                                  selectedColor: Colors.deepPurple,
                                  onSelected: (_) => setState(() => riderType = 'COMMISSION'),
                                ),
                              ],
                            ),

                            if (riderType == 'COMMISSION') ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ChoiceChip(
                                    label: const Text('% Percent', style: TextStyle(fontSize: 11)),
                                    selected: commissionType == 'PERCENT',
                                    selectedColor: Colors.deepPurple,
                                    onSelected: (_) => setState(() => commissionType = 'PERCENT'),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Fixed Ks', style: TextStyle(fontSize: 11)),
                                    selected: commissionType == 'FIXED',
                                    selectedColor: Colors.deepPurple,
                                    onSelected: (_) => setState(() => commissionType = 'FIXED'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: commissionValCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: commissionType == 'PERCENT' ? 'Commission (%)' : 'Commission (Ks / Trip)',
                                  hintText: commissionType == 'PERCENT' ? 'e.g. 20 (for 20%)' : 'e.g. 1000',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    screenWidth < 480
                        ? Column(
                            children: [
                              TextField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Phone',
                                  prefixIcon: Icon(Icons.phone_rounded, size: 18),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: contactCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Person / Emergency',
                                  prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact Phone',
                                    prefixIcon: Icon(Icons.phone_rounded, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: contactCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact Person / Emergency',
                                    prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: areaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Coverage Area / Township',
                        hintText: 'e.g. Hlaing, Kamayut, Yangon',
                        prefixIcon: Icon(Icons.map_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Remarks (optional)',
                        prefixIcon: Icon(Icons.notes_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                              backgroundColor: serviceType == 'IN_HOUSE' ? Colors.teal : AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () async {
                              if (nameCtrl.text.trim().isEmpty) {
                                Get.snackbar('Validation', 'Name is required');
                                return;
                              }

                              final double commVal = double.tryParse(commissionValCtrl.text.trim()) ?? 0.0;
                              final double defaultFee = double.tryParse(defaultDeliveryFeeCtrl.text.trim()) ?? 0.0;

                              final ok = await controller.saveService(
                                id: service?.id,
                                name: nameCtrl.text.trim(),
                                serviceType: serviceType,
                                riderType: riderType,
                                commissionType: commissionType,
                                commissionVal: commVal,
                                defaultDeliveryFee: defaultFee,
                                phone: phoneCtrl.text.trim(),
                                contactPerson: contactCtrl.text.trim(),
                                baseFee: 0.0,
                                coverageArea: areaCtrl.text.trim(),
                                notes: notesCtrl.text.trim(),
                                isActive: service?.isActive ?? true,
                              );

                              if (ok) Get.back();
                            },
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: Text(isEdit ? 'Update Service' : 'Save Service'),
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

  // Receive Remittance Payment Dialog (Courier paying back collected COD)
  void _showRecordRemittanceDialog(
    BuildContext context,
    DeliveryServiceController controller,
    DeliveryServiceModel service,
  ) {
    final amountCtrl = TextEditingController(
      text: service.receivableBalance > 0 ? service.receivableBalance.toStringAsFixed(0) : '',
    );
    final notesCtrl = TextEditingController();
    String selectedMethod = 'kpay';

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final screenWidth = MediaQuery.of(context).size.width;
            return Container(
              width: screenWidth < 500 ? screenWidth * 0.94 : 460,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: EdgeInsets.all(screenWidth < 500 ? 14 : 22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.payments_rounded, color: Colors.green, size: 22),
                            SizedBox(width: 8),
                            Text('Record Courier Remittance',
                                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Courier Status Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (service.phone != null)
                                  Text(
                                    'Phone: ${service.phone}',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Outstanding COD:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                Formatters.formatCurrency(service.receivableBalance),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Remittance Amount Input
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: Get.locale?.languageCode == 'my' ? 'လက်ခံရရှိငွေ *' : 'Remitted Amount *',
                        prefixIcon: const Icon(Icons.attach_money_rounded, size: 18, color: Colors.green),
                        suffixIcon: TextButton(
                          onPressed: () {
                            setState(() {
                              amountCtrl.text = service.receivableBalance.toStringAsFixed(0);
                            });
                          },
                          child: const Text('Full Balance', style: TextStyle(fontSize: 11.5, color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Channel Selection
                    Text(Get.locale?.languageCode == 'my' ? 'လက်ခံရရှိသည့် နည်းလမ်း:' : 'Received via:',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('KPay', style: TextStyle(fontSize: 11.5)),
                          selected: selectedMethod == 'kpay',
                          onSelected: (_) => setState(() => selectedMethod = 'kpay'),
                          selectedColor: AppColors.primary,
                        ),
                        ChoiceChip(
                          label: const Text('WavePay', style: TextStyle(fontSize: 11.5)),
                          selected: selectedMethod == 'wave',
                          onSelected: (_) => setState(() => selectedMethod = 'wave'),
                          selectedColor: AppColors.primary,
                        ),
                        ChoiceChip(
                          label: const Text('Bank', style: TextStyle(fontSize: 11.5)),
                          selected: selectedMethod == 'bank',
                          onSelected: (_) => setState(() => selectedMethod = 'bank'),
                          selectedColor: AppColors.primary,
                        ),
                        ChoiceChip(
                          label: const Text('Cash', style: TextStyle(fontSize: 11.5)),
                          selected: selectedMethod == 'cash',
                          onSelected: (_) => setState(() => selectedMethod = 'cash'),
                          selectedColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Transaction Ref / Batch Remark (optional)',
                        prefixIcon: Icon(Icons.comment_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                        const SizedBox(width: 8),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final entered = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                              if (entered <= 0) {
                                Get.snackbar('Invalid Amount', 'Please enter a valid amount');
                                return;
                              }

                              Get.back();
                              await controller.recordRemittancePayment(
                                deliveryServiceId: service.id,
                                amount: entered,
                                paymentMethod: selectedMethod,
                                notes: notesCtrl.text.trim(),
                              );
                            },
                            icon: const Icon(Icons.check_circle_rounded, size: 16),
                            label: Text(
                              screenWidth < 400 ? 'Confirm Settle' : 'Confirm Remittance & Settle',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  // Remittance History Dialog
  void _showRemittanceHistoryDialog(
    BuildContext context,
    DeliveryServiceController controller,
    DeliveryServiceModel service,
  ) {
    controller.loadPayments(service.id);

    final screenWidth = MediaQuery.of(context).size.width;

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: screenWidth < 520 ? screenWidth * 0.94 : 480,
          constraints: const BoxConstraints(maxWidth: 480),
          padding: EdgeInsets.all(screenWidth < 520 ? 14 : 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.history_rounded, color: AppColors.secondary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Remittances: ${service.name}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(height: 16),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: Obx(() {
                  if (controller.isLoadingPayments.value) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
                  }

                  if (controller.payments.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          'No remittance payment records yet for this courier.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.payments.length,
                    separatorBuilder: (_, __) => const Divider(height: 10),
                    itemBuilder: (context, i) {
                      final p = controller.payments[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_downward_rounded, color: Colors.green, size: 18),
                        ),
                        title: Text(
                          Formatters.formatCurrency(p.amount),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        subtitle: Text(
                          '${p.paymentMethod.toUpperCase()} • ${p.paymentDate.substring(0, 16).replaceAll("T", " ")}'
                          '${p.notes != null && p.notes!.isNotEmpty ? "\nNote: ${p.notes}" : ""}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Get.back(), child: const Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DeliveryServiceController controller, DeliveryServiceModel service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Delivery Service'),
        content: Text('Are you sure you want to delete "${service.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteService(service.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DeliveryServiceController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 60, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('No Delivery Services Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          const Text('Register your couriers and riders to track COD shipments', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(context, controller),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Delivery Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
