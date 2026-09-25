import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/local/customer_dao.dart';
import '../data/models/customer_model.dart';
import '../data/models/sale_order_model.dart';
import '../modules/pos/controllers/pos_controller.dart';
import 'app_colors.dart';
import 'formatters.dart';
import 'owner_auth_helper.dart';

class VoucherOwnerDialogs {
  /// Confirms and deletes/voids a voucher after owner verification
  static void confirmAndDelete(
    BuildContext context,
    SaleOrderModel order, {
    VoidCallback? onDeleted,
  }) {
    OwnerAuthHelper.requireOwnerAccess(
      context,
      actionName: 'Void Voucher ${order.voucherNo}',
      subtitle: 'Authorizing will delete voucher and return items to stock.',
      onAuthorized: () {
        Get.dialog(
          AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Void Voucher ${order.voucherNo}?',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to void and delete this voucher?',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cardBgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• Restores all item quantities back to stock inventory.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textPrimary)),
                      if (order.dueAmount > 0 && order.customerId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '• Reverses customer credit debt by ${Formatters.formatCurrency(order.dueAmount)}.',
                          style: const TextStyle(fontSize: 11.5, color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (order.isCod && order.deliveryServiceId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '• Reverses courier receivable balance by ${Formatters.formatCurrency(order.codAmount)}.',
                          style: const TextStyle(fontSize: 11.5, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () async {
                  Get.back();
                  final posCtrl = Get.isRegistered<POSController>()
                      ? Get.find<POSController>()
                      : Get.put(POSController());
                  final success = await posCtrl.deleteVoucher(order.id);
                  if (success) {
                    onDeleted?.call();
                  }
                },
                child: const Text('Void & Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens the Owner Edit dialog to either edit in-place or recall to POS cart
  static void openEditDialog(
    BuildContext context,
    SaleOrderModel order, {
    VoidCallback? onUpdated,
  }) {
    OwnerAuthHelper.requireOwnerAccess(
      context,
      actionName: 'Edit Voucher ${order.voucherNo}',
      subtitle: 'Authorizing allows modifying payment, customer, or re-opening into cart.',
      onAuthorized: () async {
        final customers = await CustomerDao().getCustomers();
        CustomerModel? selectedCustomer =
            customers.firstWhereOrNull((c) => c.id == order.customerId);
        String selectedPayment = order.paymentMethod;
        final paidAmountCtrl = TextEditingController(text: order.paidAmount.toStringAsFixed(0));
        final notesCtrl = TextEditingController(text: order.notes ?? '');

        Get.dialog(
          Dialog(
            backgroundColor: AppColors.cardBg,
            insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: StatefulBuilder(
              builder: (context, setState) {
                final double enteredPaid = double.tryParse(paidAmountCtrl.text.trim()) ?? 0.0;
                final double calculatedDue = (order.grandTotal - enteredPaid).clamp(0.0, double.infinity);
                final String status = calculatedDue <= 0
                    ? 'PAID'
                    : (enteredPaid > 0 ? 'PARTIAL' : 'CREDIT');

                return Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(18),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Voucher: ${order.voucherNo}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Total: ${Formatters.formatCurrency(order.grandTotal)} • ${order.items.length} item(s)',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                  ),
                                ],
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
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Recall to POS Cart Quick Option
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.tealAccent, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Need to edit items or quantities?',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                                    Text('Recall this entire voucher back into POS cart for full editing.',
                                        style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: () async {
                                  Get.back(); // close edit dialog
                                  final posCtrl = Get.isRegistered<POSController>()
                                      ? Get.find<POSController>()
                                      : Get.put(POSController());
                                  final recalled = await posCtrl.recallVoucherToCart(order);
                                  if (recalled) {
                                    onUpdated?.call();
                                  }
                                },
                                child: const Text('Re-open in Cart', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // In-Place Header Adjustments
                        Text(Get.locale?.languageCode == 'my' ? 'အချက်အလက်များ ပြင်ဆင်ရန်:' : 'Modify Header Details:',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),

                        // Customer Selector
                        DropdownButtonFormField<CustomerModel?>(
                          value: selectedCustomer,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: Get.locale?.languageCode == 'my' ? 'ဝယ်ယူသူ' : 'Customer',
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                            isDense: true,
                          ),
                          items: [
                            DropdownMenuItem<CustomerModel?>(
                              value: null,
                              child: Text(Get.locale?.languageCode == 'my' ? 'ဆိုင်လာဝယ်သူ' : 'Walk-in Customer'),
                            ),
                            ...customers.map((c) {
                              return DropdownMenuItem<CustomerModel?>(
                                value: c,
                                child: Text('${c.name} ${c.phone != null ? "(${c.phone})" : ""}'),
                              );
                            }),
                          ],
                          onChanged: (val) => setState(() => selectedCustomer = val),
                        ),
                        const SizedBox(height: 10),

                        // Payment Method Selector
                        DropdownButtonFormField<String>(
                          value: selectedPayment,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: Get.locale?.languageCode == 'my' ? 'ငွေပေးချေမှုစနစ်' : 'Payment Method',
                            prefixIcon: const Icon(Icons.payment_rounded, size: 18),
                            isDense: true,
                          ),
                          items: [
                            DropdownMenuItem(value: 'cash', child: Text(Get.locale?.languageCode == 'my' ? '💵 ငွေသား' : '💵 Cash')),
                            const DropdownMenuItem(value: 'kpay', child: Text('📱 KBZPay')),
                            const DropdownMenuItem(value: 'wave', child: Text('🟡 WavePay')),
                            const DropdownMenuItem(value: 'cbpay', child: Text('🔵 CBPay')),
                            const DropdownMenuItem(value: 'ayapay', child: Text('🔴 AYA Pay')),
                            const DropdownMenuItem(value: 'bank_transfer', child: Text('🏦 Bank Transfer')),
                          ],
                          onChanged: (val) => setState(() => selectedPayment = val ?? 'cash'),
                        ),
                        const SizedBox(height: 10),

                        // Paid Amount Input
                        TextField(
                          controller: paidAmountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: Get.locale?.languageCode == 'my' ? 'ပေးငွေ' : 'Paid Amount',
                            prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                            isDense: true,
                            suffixIcon: TextButton(
                              onPressed: () {
                                setState(() {
                                  paidAmountCtrl.text = order.grandTotal.toStringAsFixed(0);
                                });
                              },
                              child: const Text('Full', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Financial Summary Calculation Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.cardBgLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Due Amount: ${Formatters.formatCurrency(calculatedDue)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: calculatedDue > 0 ? AppColors.error : Colors.green,
                                  )),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (status == 'PAID' ? Colors.green : Colors.amber).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'PAID' ? Colors.greenAccent : Colors.amber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Notes Field
                        TextField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Notes / Remarks',
                            prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              onPressed: () async {
                                Get.back();
                                final posCtrl = Get.isRegistered<POSController>()
                                    ? Get.find<POSController>()
                                    : Get.put(POSController());
                                final success = await posCtrl.updateVoucherHeader(
                                  orderId: order.id,
                                  paymentMethod: selectedPayment,
                                  paidAmount: enteredPaid,
                                  dueAmount: calculatedDue,
                                  saleStatus: status,
                                  customerId: selectedCustomer?.id,
                                  notes: notesCtrl.text.trim(),
                                );
                                if (success) {
                                  onUpdated?.call();
                                }
                              },
                              icon: const Icon(Icons.save_rounded, size: 16),
                              label: const Text('Save Changes'),
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
      },
    );
  }
}
