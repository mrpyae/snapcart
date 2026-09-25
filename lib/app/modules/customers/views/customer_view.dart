import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/customer_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../utils/responsive.dart';
import '../controllers/customer_controller.dart';

class CustomerView extends StatelessWidget {
  const CustomerView({Key? key}) : super(key: key);

  // ── Add / Edit Customer ────────────────────────────────────────
  void _showAddCustomerDialog(BuildContext context, CustomerController controller, {CustomerModel? customer}) {
    final isEditing = customer != null;
    final nameCtrl    = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl   = TextEditingController(text: customer?.phone ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');
    final limitCtrl   = TextEditingController(text: customer != null ? customer.creditLimit.toStringAsFixed(0) : '0');
    final advanceCtrl = TextEditingController(text: customer != null ? customer.advanceBalance.toStringAsFixed(0) : '0');

    Responsive.showAdaptiveSheet(
      context: context,
      builder: (ctx, scroll) => Container(
        color: AppColors.cardBg,
        child: SingleChildScrollView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Customer Profile' : 'Add Customer Profile',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name *', prefixIcon: Icon(Icons.person_rounded, size: 18))),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_rounded, size: 18))),
              const SizedBox(height: 12),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_rounded, size: 18))),
              const SizedBox(height: 12),
              // Credit Limit & Advance — stacked on mobile, side-by-side on desktop
              Responsive.isMobile(context)
                  ? Column(
                      children: [
                        TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credit Limit (Ks)')),
                        const SizedBox(height: 12),
                        TextField(controller: advanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Advance Balance (Ks)')),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credit Limit (Ks)'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: advanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Advance Balance (Ks)'))),
                      ],
                    ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: SizedBox(height: 48, child: OutlinedButton(onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(), child: const Text('Cancel')))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          Navigator.of(ctx, rootNavigator: true).pop();
                          await controller.saveCustomer(
                            id: customer?.id,
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            creditLimit: double.tryParse(limitCtrl.text.trim()) ?? 0.0,
                            advanceBalance: double.tryParse(advanceCtrl.text.trim()) ?? 0.0,
                          );
                        },
                        child: Text(isEditing ? 'Update Customer' : 'Save Customer'),
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

  // ── Advance Deposit ─────────────────────────────────────────────
  void _showAdvanceDepositDialog(BuildContext context, CustomerModel customer, CustomerController controller) {
    final amountCtrl = TextEditingController();

    Responsive.showAdaptiveSheet(
      context: context,
      mobileSizeInitial: 0.55,
      builder: (ctx, scroll) => Container(
        color: AppColors.cardBg,
        child: SingleChildScrollView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 6),
              Text('Advance Deposit — ${customer.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Current Advance: ${Formatters.formatCurrency(customer.advanceBalance)}', style: const TextStyle(color: AppColors.primaryLight, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Deposit Amount (Ks) *', prefixIcon: Icon(Icons.account_balance_wallet_rounded, size: 18)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: SizedBox(height: 48, child: OutlinedButton(onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(), child: const Text('Cancel')))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                          if (amount > 0) {
                            Navigator.of(ctx, rootNavigator: true).pop();
                            await controller.recordAdvancePayment(customer.id, amount);
                            Get.snackbar('Success', 'Recorded advance deposit of ${Formatters.formatCurrency(amount)}',
                                backgroundColor: AppColors.primary, colorText: Colors.white);
                          }
                        },
                        child: const Text('Save Deposit'),
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

  // ── Debt Repayment ─────────────────────────────────────────────
  void _showRepayDialog(BuildContext context, CustomerModel customer, CustomerController controller) {
    final amountCtrl = TextEditingController(text: customer.currentDebt.toStringAsFixed(0));

    Responsive.showAdaptiveSheet(
      context: context,
      mobileSizeInitial: 0.55,
      builder: (ctx, scroll) => Container(
        color: AppColors.cardBg,
        child: SingleChildScrollView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 6),
              Text('Debt Repayment — ${customer.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Total Current Debt: ${Formatters.formatCurrency(customer.currentDebt)}', style: const TextStyle(color: AppColors.error, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Repayment Amount (Ks)', prefixIcon: Icon(Icons.payments_rounded, size: 18)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: SizedBox(height: 48, child: OutlinedButton(onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(), child: const Text('Cancel')))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                          if (amount > 0) {
                            await controller.repayDebt(customer.id, amount);
                            Navigator.of(ctx, rootNavigator: true).pop();
                            Get.snackbar('Repayment Success', 'Recorded repayment of ${Formatters.formatCurrency(amount)}',
                                backgroundColor: AppColors.success.withOpacity(0.85), colorText: Colors.white);
                          }
                        },
                        child: const Text('Confirm Repayment'),
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

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = Get.put(CustomerController());
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer & AR/AP Ledger',
                          style: TextStyle(fontSize: Responsive.titleFontSize(context), fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      const Text('Credit sales (AR) and advance payments (AP)',
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                SizedBox(
                  height: Responsive.buttonHeight(context),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddCustomerDialog(context, controller),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(isMobile ? 'Add' : 'Add Customer'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Summary Metrics ────────────────────────────────
            Obx(() {
              final totalDebt    = controller.customers.fold(0.0, (sum, c) => sum + c.currentDebt);
              final totalAdvance = controller.customers.fold(0.0, (sum, c) => sum + c.advanceBalance);

              Widget statCard({required String label, required String value, required Color accent, required Color border}) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 11, color: accent)),
                      const SizedBox(height: 4),
                      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accent)),
                    ],
                  ),
                );
              }

              // Always show all 3 cards — wrap on narrow screens
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 150,
                    child: statCard(
                      label: 'Total Customers',
                      value: '${controller.customers.length}',
                      accent: AppColors.textPrimary,
                      border: AppColors.border,
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? double.infinity : 200,
                    child: statCard(
                      label: 'Customer Debt (AR)',
                      value: Formatters.formatCurrency(totalDebt),
                      accent: AppColors.error,
                      border: AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? double.infinity : 200,
                    child: statCard(
                      label: 'Advance Deposits (AP)',
                      value: Formatters.formatCurrency(totalAdvance),
                      accent: AppColors.primaryLight,
                      border: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 14),

            // ── Search Bar ─────────────────────────────────────
            TextField(
              onChanged: (val) {
                controller.searchQuery.value = val;
                controller.loadCustomers();
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                hintText: 'Search customer by name or phone...',
              ),
            ),
            const SizedBox(height: 14),

            // ── Customer List ──────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.customers.isEmpty) {
                  return const Center(child: Text('No customers found.'));
                }

                return ListView.separated(
                  itemCount: controller.customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = controller.customers[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: c.currentDebt > 0 ? AppColors.error.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                          child: Icon(
                            Icons.person_rounded,
                            color: c.currentDebt > 0 ? AppColors.error : AppColors.primaryLight,
                            size: 20,
                          ),
                        ),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Phone: ${c.phone ?? "N/A"} • ${c.address ?? "No address"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (c.currentDebt > 0)
                                  Text(
                                    'Debt: ${Formatters.formatCurrency(c.currentDebt)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 13),
                                  )
                                else
                                  const Text('Debt Free', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                                if (c.advanceBalance > 0)
                                  Text('Advance: ${Formatters.formatCurrency(c.advanceBalance)}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.primaryLight)),
                              ],
                            ),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 22, color: AppColors.textSecondary),
                              onSelected: (action) {
                                if (action == 'repay') {
                                  _showRepayDialog(context, c, controller);
                                } else if (action == 'advance') {
                                  _showAdvanceDepositDialog(context, c, controller);
                                } else if (action == 'edit') {
                                  _showAddCustomerDialog(context, controller, customer: c);
                                }
                              },
                              itemBuilder: (context) => [
                                if (c.currentDebt > 0)
                                  const PopupMenuItem(value: 'repay', child: Text('Settle Debt (Repay)')),
                                const PopupMenuItem(value: 'advance', child: Text('Record Advance Deposit')),
                                const PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
