import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../utils/responsive.dart';
import '../controllers/expense_controller.dart';

class ExpenseView extends StatelessWidget {
  const ExpenseView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.put(ExpenseController());
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
                      Text(
                        isMobile ? 'Expenses' : 'Store Expenses',
                        style: TextStyle(
                          fontSize: Responsive.titleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMobile
                            ? 'Record daily shop expenses'
                            : 'Record daily operational expenses (utilities, salaries, logistics)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: Responsive.buttonHeight(context),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddExpenseDialog(context, controller),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: Text(isMobile ? 'Add' : 'Add Expense'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Expense List ────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.expenses.isEmpty) {
                  return const Center(child: Text('No expenses recorded yet.'));
                }

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    itemCount: controller.expenses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final exp = controller.expenses[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.trending_down_rounded, color: AppColors.error, size: 20),
                        ),
                        title: Text(exp.category,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        subtitle: Text(
                          '${exp.description ?? "No details"} • ${Formatters.formatDate(exp.expenseDate)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        trailing: Text(
                          Formatters.formatCurrency(exp.amount),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, ExpenseController controller) {
    final amountCtrl = TextEditingController();
    final descCtrl   = TextEditingController();
    String selectedCategory = 'General';

    Responsive.showAdaptiveSheet(
      context: context,
      mobileSizeInitial: 0.70,
      builder: (ctx, scroll) => StatefulBuilder(
        builder: (ctx, setState) => Container(
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
                    const Text('Add Daily Expense',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                      onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Expense Category'),
                  dropdownColor: AppColors.cardBg,
                  items: [
                    'General',
                    'Utilities',
                    'Shop Rent',
                    'Electricity / Water',
                    'Staff Salary',
                    'Logistics / Delivery',
                    'Packaging & Supplies',
                  ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => selectedCategory = v ?? 'General'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (Ks) *',
                    prefixIcon: Icon(Icons.attach_money_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description / Note',
                    prefixIcon: Icon(Icons.notes_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                            if (amount <= 0) return;
                            await controller.addExpense(
                              category: selectedCategory,
                              amount: amount,
                              description: descCtrl.text.trim(),
                            );
                            Navigator.of(ctx, rootNavigator: true).pop();
                          },
                          child: const Text('Save Expense'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
