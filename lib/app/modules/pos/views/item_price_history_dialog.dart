import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/product_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';
import '../controllers/pos_controller.dart';

class ItemPriceHistoryDialog extends StatefulWidget {
  final ProductModel product;
  final String? initialCustomerId;
  final Function(double selectedPrice)? onPriceSelected;

  const ItemPriceHistoryDialog({
    Key? key,
    required this.product,
    this.initialCustomerId,
    this.onPriceSelected,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required ProductModel product,
    String? initialCustomerId,
    Function(double selectedPrice)? onPriceSelected,
  }) {
    Get.dialog(
      ItemPriceHistoryDialog(
        product: product,
        initialCustomerId: initialCustomerId,
        onPriceSelected: onPriceSelected,
      ),
    );
  }

  @override
  State<ItemPriceHistoryDialog> createState() => _ItemPriceHistoryDialogState();
}

class _ItemPriceHistoryDialogState extends State<ItemPriceHistoryDialog> {
  late POSController posController;
  String? selectedCustomerId;
  DateTime? startDate;
  DateTime? endDate;
  int recordLimit = 10; // Default urgent 10 records
  bool isUrgent10Mode = true;

  @override
  void initState() {
    super.initState();
    posController = Get.find<POSController>();
    selectedCustomerId = widget.initialCustomerId ?? posController.selectedCustomer.value?.id;
    _loadHistory();
  }

  void _loadHistory() {
    posController.fetchItemPriceHistory(
      productId: widget.product.id,
      customerId: selectedCustomerId,
      startDate: startDate,
      endDate: endDate,
      limit: isUrgent10Mode ? 10 : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: screenWidth < 620 ? screenWidth * 0.94 : 580,
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.history_rounded, color: AppColors.secondary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price History: ${widget.product.name}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Retail: ${Formatters.formatCurrency(widget.product.retailPrice)} • Wholesale: ${Formatters.formatCurrency(widget.product.wholesalePrice)}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Filter Bar (Customer Selector & Urgent 10 Toggle / Date Range)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Customer Dropdown
                  Row(
                    children: [
                      const Icon(Icons.person_search_rounded, size: 18, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Obx(() {
                          final customerList = posController.customers;
                          return DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: selectedCustomerId,
                              isExpanded: true,
                              hint: const Text('All Customers (အားလုံး)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              dropdownColor: AppColors.cardBg,
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All Customers (အားလုံး)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                                ...customerList.map((c) => DropdownMenuItem<String?>(
                                      value: c.id,
                                      child: Text(
                                        '${c.name} ${c.phone != null && c.phone!.isNotEmpty ? "(${c.phone})" : ""}',
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedCustomerId = val;
                                });
                                _loadHistory();
                              },
                            ),
                          );
                        }),
                      ),
                      if (selectedCustomerId != null)
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedCustomerId = null;
                            });
                            _loadHistory();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Mode Toggle: Urgent Last 10 vs Date Range
                  Row(
                    children: [
                      // Urgent 10 Badge Toggle
                      InkWell(
                        onTap: () {
                          setState(() {
                            isUrgent10Mode = !isUrgent10Mode;
                            if (isUrgent10Mode) {
                              startDate = null;
                              endDate = null;
                            }
                          });
                          _loadHistory();
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isUrgent10Mode ? Colors.amber.shade900.withOpacity(0.3) : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isUrgent10Mode ? Colors.amber.shade400 : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 14, color: isUrgent10Mode ? Colors.amber : AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'Last 10 (Urgent)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isUrgent10Mode ? Colors.amber : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Date Range Picker
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: now.add(const Duration(days: 1)),
                              initialDateRange: startDate != null && endDate != null
                                  ? DateTimeRange(start: startDate!, end: endDate!)
                                  : DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
                            );
                            if (picked != null) {
                              setState(() {
                                startDate = picked.start;
                                endDate = picked.end;
                                isUrgent10Mode = false;
                              });
                              _loadHistory();
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (!isUrgent10Mode && startDate != null) ? AppColors.primary.withOpacity(0.2) : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (!isUrgent10Mode && startDate != null) ? AppColors.primaryLight : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.date_range_rounded, size: 14, color: AppColors.primaryLight),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    startDate != null && endDate != null
                                        ? '${DateFormat("dd/MM").format(startDate!)} - ${DateFormat("dd/MM").format(endDate!)}'
                                        : 'Filter by Date',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Summary Statistics Pill
            Obx(() {
              final list = posController.priceHistory;
              if (list.isEmpty) return const SizedBox.shrink();

              final prices = list.map((e) => e.unitPrice).toList();
              final minPrice = prices.reduce((a, b) => a < b ? a : b);
              final maxPrice = prices.reduce((a, b) => a > b ? a : b);
              final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
              final latestPrice = list.first.unitPrice;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Latest Sold', Formatters.formatCurrency(latestPrice), AppColors.secondary),
                    _buildStatItem('Lowest', Formatters.formatCurrency(minPrice), AppColors.success),
                    _buildStatItem('Highest', Formatters.formatCurrency(maxPrice), Colors.amber),
                    _buildStatItem('Average', Formatters.formatCurrency(avgPrice), AppColors.primaryLight),
                  ],
                ),
              );
            }),

            // History Records List
            Expanded(
              child: Obx(() {
                if (posController.isLoadingPriceHistory.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = posController.priceHistory;
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_outlined, size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          selectedCustomerId != null
                              ? 'No price history found for this customer'
                              : 'No sales history recorded for this item yet',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      Formatters.formatCurrency(item.unitPrice),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '× ${Formatters.formatQty(item.quantity, unit: item.unit)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                    const Spacer(),
                                    Text(
                                      item.shortDate,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.customerName,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      'Voucher: ${item.voucherNo}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (widget.onPriceSelected != null) ...[
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.onPriceSelected!(item.unitPrice);
                                  Get.back();
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  backgroundColor: AppColors.primary,
                                ),
                                child: const Text('Apply', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 12),

            // Dialog Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text(
                      'Showing ${posController.priceHistory.length} record(s)',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    )),
                SizedBox(
                  width: 100,
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
