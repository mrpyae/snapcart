import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/customer_order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';
import '../controllers/product_controller.dart';
import 'product_suppliers_dialog.dart';

class ProductOrdersDialog extends StatefulWidget {
  final ProductModel product;

  const ProductOrdersDialog({
    Key? key,
    required this.product,
  }) : super(key: key);

  static void show(BuildContext context, {required ProductModel product}) {
    final ProductController controller = Get.isRegistered<ProductController>()
        ? Get.find<ProductController>()
        : Get.put(ProductController());

    controller.loadOrdersForProduct(product.id, activeOnly: true);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: 24,
        ),
        child: Container(
          width: isMobile ? screenWidth * 0.95 : 620,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          child: ProductOrdersDialog(product: product),
        ),
      ),
    );
  }

  @override
  State<ProductOrdersDialog> createState() => _ProductOrdersDialogState();
}

class _ProductOrdersDialogState extends State<ProductOrdersDialog> {
  bool _activeOnly = true;

  @override
  Widget build(BuildContext context) {
    final ProductController controller = Get.isRegistered<ProductController>()
        ? Get.find<ProductController>()
        : Get.put(ProductController());

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment_outlined, color: AppColors.secondary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (widget.product.barcode != null && widget.product.barcode!.isNotEmpty) ...[
                          Text(
                            'SKU: ${widget.product.barcode}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          'Retail: ${Formatters.formatCurrency(widget.product.retailPrice)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Get.back(),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Stock Commitment Overview
          Obx(() {
            final double inStock = widget.product.stockQty;
            final double reserved = controller.activeOrderedQty.value;
            final double available = inStock - reserved;
            final bool hasShortage = available < 0;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasShortage ? AppColors.error.withOpacity(0.6) : AppColors.border.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStockMetric(
                      Get.locale?.languageCode == 'my' ? '📦 စုစုပေါင်း လက်ကျန်' : '📦 Physical Stock',
                      '${inStock.toStringAsFixed(0)} ${widget.product.unit}',
                      AppColors.textPrimary,
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppColors.border),
                  Expanded(
                    child: _buildStockMetric(
                      Get.locale?.languageCode == 'my' ? '📝 မှာယူထားသော အော်ဒါ' : '📝 Committed Orders',
                      '${reserved.toStringAsFixed(0)} ${widget.product.unit}',
                      AppColors.secondary,
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppColors.border),
                  Expanded(
                    child: _buildStockMetric(
                      hasShortage
                          ? (Get.locale?.languageCode == 'my' ? '⚠️ လိုအပ်သော အရေအတွက်' : '⚠️ Shortage')
                          : (Get.locale?.languageCode == 'my' ? '✨ ရောင်းချနိုင်သော လက်ကျန်' : '✨ Free to Sell'),
                      '${available.toStringAsFixed(0)} ${widget.product.unit}',
                      hasShortage ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 14),

          // Filter Tab Bar & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ChoiceChip(
                    label: Text(Get.locale?.languageCode == 'my' ? 'လက်ရှိ အော်ဒါများ' : 'Active Orders', style: const TextStyle(fontSize: 12)),
                    selected: _activeOnly,
                    selectedColor: AppColors.primary.withOpacity(0.25),
                    onSelected: (val) {
                      setState(() => _activeOnly = true);
                      controller.loadOrdersForProduct(widget.product.id, activeOnly: true);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(Get.locale?.languageCode == 'my' ? 'မှတ်တမ်း အားလုံး' : 'All History', style: const TextStyle(fontSize: 12)),
                    selected: !_activeOnly,
                    selectedColor: AppColors.primary.withOpacity(0.25),
                    onSelected: (val) {
                      setState(() => _activeOnly = false);
                      controller.loadOrdersForProduct(widget.product.id, activeOnly: false);
                    },
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  Get.back();
                  ProductSuppliersDialog.show(context, product: widget.product);
                },
                icon: const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.primaryLight),
                label: Text(
                  isMobile ? 'Suppliers' : 'View Suppliers',
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryLight),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Orders List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingProductOrders.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = controller.currentProductOrders;
              if (orders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 10),
                        Text(
                          _activeOnly
                              ? 'ဤပစ္စည်းအတွက် လက်ရှိ အော်ဒါ မရှိသေးပါ'
                              : 'ဤပစ္စည်းအတွက် အော်ဒါမှတ်တမ်း မရှိသေးပါ',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _activeOnly
                              ? 'No pending or active customer orders for this product.'
                              : 'No past or active customer orders found for this product.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderCard(order, isMobile);
                },
              );
            }),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Bottom Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
    );
  }

  Widget _buildStockMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildOrderCard(CustomerOrderModel order, bool isMobile) {
    // Find item(s) for this specific product inside this order
    final targetItems = order.items.where((i) => i.productId == widget.product.id).toList();
    final double targetQty = targetItems.fold(0.0, (sum, i) => sum + i.quantity);
    final double targetSubtotal = targetItems.fold(0.0, (sum, i) => sum + i.subtotal);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order No, Channel & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    order.orderNo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      order.orderSource,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(order.status),
            ],
          ),

          const SizedBox(height: 8),

          // Customer Info
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${order.customerName}${order.customerPhone != null && order.customerPhone!.isNotEmpty ? " • ${order.customerPhone}" : ""}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (order.customerAddress != null && order.customerAddress!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 21),
              child: Text(
                order.customerAddress!,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 8),

          // Product-Specific Order Details Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text(
                      'Ordered: ${targetQty.toStringAsFixed(0)} ${widget.product.unit}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ],
                ),
                Text(
                  'Subtotal: ${Formatters.formatCurrency(targetSubtotal)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Order Financials and Appointment Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (order.appointmentDate != null && order.appointmentDate!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.event_note_rounded, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      order.appointmentDate!.length >= 10 ? order.appointmentDate!.substring(0, 10) : order.appointmentDate!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      order.createdAt.length >= 10 ? order.createdAt.substring(0, 10) : order.createdAt,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              Text(
                'Advance: ${Formatters.formatCurrency(order.advanceAmount)} • Due: ${Formatters.formatCurrency(order.dueAmount)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    final bool isMm = Get.locale?.languageCode == 'my';
    switch (status) {
      case 'PENDING':
        bg = Colors.amber.withOpacity(0.15);
        fg = Colors.amber.shade900;
        label = isMm ? 'စောင့်ဆိုင်း' : 'Pending';
        break;
      case 'CONFIRMED':
        bg = Colors.blue.withOpacity(0.15);
        fg = Colors.blue.shade800;
        label = isMm ? 'အတည်ပြု' : 'Confirmed';
        break;
      case 'IN_PROGRESS':
        bg = Colors.purple.withOpacity(0.15);
        fg = Colors.purple.shade800;
        label = isMm ? 'ချုပ်လုပ်နေ' : 'In Progress';
        break;
      case 'READY_FOR_PICKUP':
        bg = Colors.teal.withOpacity(0.15);
        fg = Colors.teal.shade800;
        label = isMm ? 'အသင့်ဖြစ်' : 'Ready';
        break;
      case 'COMPLETED':
        bg = Colors.green.withOpacity(0.15);
        fg = Colors.green.shade800;
        label = isMm ? 'ပြီးစီး' : 'Completed';
        break;
      case 'CANCELLED':
        bg = Colors.red.withOpacity(0.15);
        fg = Colors.red.shade800;
        label = isMm ? 'ပယ်ဖျက်' : 'Cancelled';
        break;
      default:
        bg = Colors.grey.withOpacity(0.15);
        fg = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
