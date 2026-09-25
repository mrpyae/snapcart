import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/supplier_category_model.dart';
import '../../../data/models/supplier_model.dart';
import '../../../data/models/supplier_payment_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../utils/responsive.dart';
import '../controllers/supplier_controller.dart';

class SupplierView extends StatelessWidget {
  const SupplierView({Key? key}) : super(key: key);

  void _showCategoryEditDialog(
    BuildContext context,
    SupplierController controller, {
    SupplierCategoryModel? category,
    Function(SupplierCategoryModel)? onSaved,
  }) {
    final isEditing = category != null;
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Category' : 'Add Supplier Category',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category Name (အမျိုးအစားအမည်) *',
                  hintText: 'e.g. ပိုးထည်, ချည်ထည်, ရက်ကန်း, Packaging',
                  prefixIcon: Icon(Icons.category_outlined, size: 18, color: AppColors.primaryLight),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description / Notes (optional)',
                  prefixIcon: Icon(Icons.notes_rounded, size: 18, color: AppColors.primaryLight),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        Get.snackbar('Validation', 'Category name is required', backgroundColor: Colors.amber.shade800, colorText: Colors.white);
                        return;
                      }
                      Get.back();
                      final saved = await controller.saveCategory(
                        id: category?.id,
                        name: name,
                        description: descCtrl.text.trim(),
                      );
                      if (saved != null && onSaved != null) {
                        onSaved(saved);
                      }
                    },
                    child: Text(isEditing ? 'Save Changes' : 'Create Category'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryManagerDialog(BuildContext context, SupplierController controller) {

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          constraints: const BoxConstraints(maxHeight: 560),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.category_outlined, color: AppColors.primaryLight, size: 22),
                      SizedBox(width: 4),
                      Text(
                        'ရက်ကန်းအမျိုးအစားများ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 17, color: AppColors.textMuted),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Organize your suppliers and loom artisans into categories.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCategoryEditDialog(context, controller),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add New Category'),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  if (controller.isCategoryLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.categories.isEmpty) {
                    return const Center(
                      child: Text(
                        'No supplier categories yet.\nClick "Add New Category" above to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: controller.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cat = controller.categories[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.label_outline_rounded, size: 18, color: AppColors.primaryLight),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13.5),
                                  ),
                                  if (cat.description != null && cat.description!.isNotEmpty)
                                    Text(
                                      cat.description!,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryLight),
                              tooltip: 'Edit',
                              onPressed: () => _showCategoryEditDialog(context, controller, category: cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              tooltip: 'Delete',
                              onPressed: () {
                                Get.defaultDialog(
                                  title: 'Delete Category',
                                  titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  middleText: 'Are you sure you want to delete category "${cat.name}"?',
                                  middleTextStyle: const TextStyle(color: AppColors.textSecondary),
                                  textCancel: 'Cancel',
                                  textConfirm: 'Delete',
                                  confirmTextColor: Colors.white,
                                  buttonColor: AppColors.error,
                                  onConfirm: () async {
                                    Get.back();
                                    await controller.deleteCategory(cat.id);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupplierFormDialog(BuildContext context, SupplierController controller, {SupplierModel? supplier}) {
    final isEditing = supplier != null;
    final nameCtrl = TextEditingController(text: supplier?.name ?? '');
    final phoneCtrl = TextEditingController(text: supplier?.phone ?? '');
    final companyCtrl = TextEditingController(text: supplier?.companyName ?? '');
    final addressCtrl = TextEditingController(text: supplier?.address ?? '');
    final payableCtrl = TextEditingController(text: supplier != null ? supplier.payableBalance.toStringAsFixed(0) : '0');
    final advanceCtrl = TextEditingController(text: supplier != null ? supplier.advanceBalance.toStringAsFixed(0) : '0');
    String? selectedCategoryId = supplier?.supplierCategoryId;

    final screenWidth = MediaQuery.of(context).size.width;
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: screenWidth < 520 ? screenWidth * 0.94 : 480,
              constraints: const BoxConstraints(maxWidth: 480),
              padding: EdgeInsets.all(screenWidth < 520 ? 14 : 22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'ရက်ကန်းပြင်မယ်' : 'ရက်ကန်း',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Supplier Name *', prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: AppColors.primaryLight)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined, size: 18, color: AppColors.primaryLight)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: companyCtrl,
                      decoration: const InputDecoration(labelText: 'Company / Workshop Name', prefixIcon: Icon(Icons.business_outlined, size: 18, color: AppColors.primaryLight)),
                    ),
                    const SizedBox(height: 12),

                    // Supplier Category Dropdown + Quick Add Shortcut
                    Obx(() {
                      final catList = controller.categories;
                      final hasMatching = selectedCategoryId != null && catList.any((c) => c.id == selectedCategoryId);
                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              isExpanded: true,
                              value: hasMatching ? selectedCategoryId : null,
                              decoration: const InputDecoration(
                                labelText: 'Category (အမျိုးအစား)',
                                prefixIcon: Icon(Icons.category_outlined, size: 18, color: AppColors.primaryLight),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('General / No Category', style: TextStyle(color: AppColors.textMuted)),
                                ),
                                ...catList.map((c) => DropdownMenuItem<String?>(
                                  value: c.id,
                                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                                )),
                              ],
                              onChanged: (val) {
                                setState(() => selectedCategoryId = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Tooltip(
                            message: 'Add New Category',
                            child: InkWell(
                              onTap: () {
                                _showCategoryEditDialog(
                                  context,
                                  controller,
                                  onSaved: (newCat) {
                                    setState(() => selectedCategoryId = newCat.id);
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 48,
                                width: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.add_rounded, color: AppColors.primaryLight, size: 22),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 12),

                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address / Location', prefixIcon: Icon(Icons.location_on_outlined, size: 18, color: AppColors.primaryLight)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: payableCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Initial Debt (Payable)',
                              prefixIcon: Icon(Icons.money_off_rounded, size: 18, color: AppColors.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: advanceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Initial Advance Deposit',
                              prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.success),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                            onPressed: () async {
                              if (nameCtrl.text.trim().isEmpty) {
                                Get.snackbar('Validation', 'Supplier name is required', backgroundColor: Colors.amber.shade800, colorText: Colors.white);
                                return;
                              }
                              Get.back();
                              await controller.saveSupplier(
                                id: supplier?.id,
                                name: nameCtrl.text.trim(),
                                supplierCategoryId: selectedCategoryId,
                                phone: phoneCtrl.text.trim(),
                                companyName: companyCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                                payableBalance: double.tryParse(payableCtrl.text.trim()) ?? 0.0,
                                advanceBalance: double.tryParse(advanceCtrl.text.trim()) ?? 0.0,
                              );
                            },
                            child: Text(isEditing ? 'Save Changes' : 'Create Supplier'),
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

  void _showPaymentDialog(BuildContext context, SupplierController controller, SupplierModel supplier, {bool isAdvance = false}) {
    final amountCtrl = TextEditingController(text: isAdvance ? '0' : supplier.payableBalance.toStringAsFixed(0));
    final notesCtrl = TextEditingController();
    String paymentMethod = 'cash';
    DateTime paymentDate = DateTime.now();

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final screenWidth = MediaQuery.of(context).size.width;
            return Container(
              width: screenWidth < 480 ? screenWidth * 0.94 : 440,
              constraints: const BoxConstraints(maxWidth: 440),
              padding: EdgeInsets.all(screenWidth < 480 ? 14 : 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAdvance ? 'Advance Payment to Supplier' : 'Settle Supplier Debt (Repayment)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Supplier: ${supplier.name} ${supplier.companyName != null ? "(${supplier.companyName})" : ""}',
                      style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                  if (!isAdvance) ...[
                    const SizedBox(height: 4),
                    Text('Current Outstanding Debt: ${Formatters.formatCurrency(supplier.payableBalance)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 14),

                  // Payment Date Picker Field
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: paymentDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => paymentDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryLight),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Payment Date (ငွေပေးချေသည့်ရက်စွဲ) *', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('yyyy-MM-dd (EEEE)').format(paymentDate),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.secondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: isAdvance ? 'Advance Deposit Amount (Ks) *' : 'Amount to Settle (Ks) *',
                      prefixIcon: const Icon(Icons.payments_rounded, size: 18, color: AppColors.primaryLight),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment Method'),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('💵 Cash (ငွေသား)')),
                      DropdownMenuItem(value: 'kpay', child: Text('📱 KBZPay / Mobile Banking')),
                      DropdownMenuItem(value: 'wave', child: Text('🟡 WavePay')),
                      DropdownMenuItem(value: 'bank', child: Text('🏦 Bank Transfer')),
                    ],
                    onChanged: (val) => setState(() => paymentMethod = val ?? 'cash'),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes / Voucher Reference (Optional)'),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                            backgroundColor: isAdvance ? AppColors.primary : AppColors.success,
                          ),
                          onPressed: () async {
                            final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                            if (amount <= 0) {
                              Get.snackbar('Input Error', 'Please enter a valid payment amount', backgroundColor: Colors.amber.shade800, colorText: Colors.white);
                              return;
                            }
                            Get.back();
                            await controller.recordPayment(
                              supplierId: supplier.id,
                              amount: amount,
                              type: isAdvance ? 'ADVANCE' : 'PAYMENT',
                              paymentMethod: paymentMethod,
                              paymentDate: paymentDate,
                              notes: notesCtrl.text.trim(),
                            );
                          },
                          child: Text(isAdvance ? 'Record Advance' : 'Confirm Settlement'),
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

  // Edit Existing Supplier Payment Record Dialog
  void _showEditPaymentDialog(
    BuildContext context,
    SupplierController controller,
    SupplierPaymentModel payment,
    SupplierModel supplier,
  ) {
    final amountCtrl = TextEditingController(text: payment.amount.toStringAsFixed(0));
    final notesCtrl = TextEditingController(text: payment.notes ?? '');
    String paymentMethod = payment.paymentMethod.isNotEmpty ? payment.paymentMethod : 'cash';
    String paymentType = payment.type;
    DateTime paymentDate = DateTime.tryParse(payment.paymentDate) ?? DateTime.now();

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: 440,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Payment Record (ငွေပေးမှတ်တမ်းပြင်ဆင်ရန်)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Supplier: ${supplier.name}', style: const TextStyle(fontSize: 12.5, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),

                  // Transaction Type (Payment vs Advance)
                  DropdownButtonFormField<String>(
                    value: paymentType,
                    decoration: const InputDecoration(labelText: 'Transaction Type (အမျိုးအစား)'),
                    items: const [
                      DropdownMenuItem(value: 'PAYMENT', child: Text('Debt Repayment (အကြွေးဆပ်ခြင်း)')),
                      DropdownMenuItem(value: 'ADVANCE', child: Text('Advance Deposit (စရံငွေကြိုတင်ပေးသွင်းခြင်း)')),
                    ],
                    onChanged: (val) => setState(() => paymentType = val ?? 'PAYMENT'),
                  ),
                  const SizedBox(height: 12),

                  // Payment Date Picker Field
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: paymentDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => paymentDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryLight),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Payment Date (ငွေပေးချေသည့်ရက်စွဲ) *', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('yyyy-MM-dd (EEEE)').format(paymentDate),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.secondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Amount
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (Ks) *',
                      prefixIcon: Icon(Icons.payments_rounded, size: 18, color: AppColors.primaryLight),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Payment Method
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment Method'),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('💵 Cash (ငွေသား)')),
                      DropdownMenuItem(value: 'kpay', child: Text('📱 KBZPay / Mobile Banking')),
                      DropdownMenuItem(value: 'wave', child: Text('🟡 WavePay')),
                      DropdownMenuItem(value: 'bank', child: Text('🏦 Bank Transfer')),
                    ],
                    onChanged: (val) => setState(() => paymentMethod = val ?? 'cash'),
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes / Voucher Reference (Optional)'),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: () async {
                            final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                            if (amount <= 0) {
                              Get.snackbar('Input Error', 'Please enter a valid amount', backgroundColor: Colors.amber.shade800, colorText: Colors.white);
                              return;
                            }
                            Get.back();
                            final updated = SupplierPaymentModel(
                              id: payment.id,
                              businessId: payment.businessId,
                              supplierId: payment.supplierId,
                              purchaseId: payment.purchaseId,
                              amount: amount,
                              type: paymentType,
                              paymentMethod: paymentMethod,
                              paymentDate: paymentDate.toIso8601String(),
                              notes: notesCtrl.text.trim(),
                              syncStatus: 0,
                            );
                            await controller.editPayment(updated);
                          },
                          child: const Text('Save Changes'),
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

  void _showLedgerHistoryDialog(BuildContext context, SupplierController controller, SupplierModel supplier) async {
    await controller.loadSupplierPayments(supplier.id);
    final screenWidth = MediaQuery.of(context).size.width;

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: screenWidth < 600 ? screenWidth * 0.94 : 560,
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
          padding: EdgeInsets.all(screenWidth < 600 ? 14 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Debt, Advance and Net Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment History: ${supplier.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(supplier.companyName ?? 'Supplier Account Ledger', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Get.back()),
                ],
              ),
              const SizedBox(height: 12),

              // Ledger Balance Summary Pill
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total Debt (AP)', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(Formatters.formatCurrency(supplier.payableBalance), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error)),
                      ],
                    ),
                    Container(width: 1, height: 28, color: AppColors.border),
                    Column(
                      children: [
                        const Text('Advance Deposit', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(Formatters.formatCurrency(supplier.advanceBalance), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    Container(width: 1, height: 28, color: AppColors.border),
                    Column(
                      children: [
                        const Text('Net Balance (လက်ကျန်)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          supplier.hasDebt
                              ? '-${Formatters.formatCurrency(supplier.payableBalance - supplier.advanceBalance)} (Due)'
                              : supplier.hasCredit
                                  ? '+${Formatters.formatCurrency(supplier.advanceBalance - supplier.payableBalance)} (Adv)'
                                  : '0 Ks (Settled)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: supplier.hasDebt ? AppColors.error : supplier.hasCredit ? Colors.green : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Payment Transactions List with Edit Button
              Expanded(
                child: Obx(() {
                  if (controller.currentPayments.isEmpty) {
                    return const Center(child: Text('No payment records found for this supplier.', style: TextStyle(color: AppColors.textMuted)));
                  }

                  return ListView.separated(
                    itemCount: controller.currentPayments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final p = controller.currentPayments[idx];
                      final isSettlement = p.type == 'PAYMENT';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isSettlement ? AppColors.success : AppColors.primary).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSettlement ? Icons.check_circle_rounded : Icons.account_balance_wallet_rounded,
                            color: isSettlement ? AppColors.success : AppColors.primaryLight,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isSettlement ? 'Debt Repayment (အကြွေးဆပ်)' : 'Advance Deposit (စရံငွေ)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text(
                              Formatters.formatCurrency(p.amount),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSettlement ? AppColors.success : AppColors.primaryLight),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${p.paymentMethod.toUpperCase()} • ${Formatters.formatDate(p.paymentDate)} ${p.notes != null && p.notes!.isNotEmpty ? "• " + p.notes! : ""}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.secondary),
                          tooltip: 'Edit Record (ပြင်ဆင်ရန်)',
                          onPressed: () {
                            _showEditPaymentDialog(context, controller, p, supplier);
                          },
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SupplierController controller = Get.put(SupplierController());
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Suppliers & AP Ledger',
                          style: TextStyle(fontSize: Responsive.titleFontSize(context), fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      const Text('Manage suppliers, purchases, debt payables & advance deposits',
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: Responsive.buttonHeight(context),
                      child: OutlinedButton.icon(
                        onPressed: () => _showCategoryManagerDialog(context, controller),
                        icon: const Icon(Icons.category_outlined, size: 18),
                        label: Text(isMobile ? 'Categories' : 'Categories (အမျိုးအစားများ)',style: TextStyle(
                          fontSize: isMobile?10:18,color: Colors.white
                        ),),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: Responsive.buttonHeight(context),
                      child: ElevatedButton.icon(
                        onPressed: () => _showSupplierFormDialog(context, controller),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(isMobile ? 'Add' : 'Add Supplier'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Summary Metrics Cards with Net Balance
            Obx(() {
              final totalPayable = controller.suppliers.fold(0.0, (sum, s) => sum + s.payableBalance);
              final totalAdvance = controller.suppliers.fold(0.0, (sum, s) => sum + s.advanceBalance);
              final netPosition = totalAdvance - totalPayable;

              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Suppliers', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text('${controller.suppliers.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Debt (Payable)', style: TextStyle(fontSize: 11, color: AppColors.error)),
                          const SizedBox(height: 4),
                          Text(Formatters.formatCurrency(totalPayable), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Advance Deposits', style: TextStyle(fontSize: 11, color: AppColors.primaryLight)),
                          const SizedBox(height: 4),
                          Text(Formatters.formatCurrency(totalAdvance), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                        ],
                      ),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: netPosition < 0 ? AppColors.error.withOpacity(0.4) : Colors.green.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Net AP Position (လက်ကျန်ရှင်းတမ်း)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              netPosition < 0
                                  ? '-${Formatters.formatCurrency(netPosition.abs())} (Due)'
                                  : netPosition > 0
                                      ? '+${Formatters.formatCurrency(netPosition)} (Credit)'
                                      : '0 Ks (Settled)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: netPosition < 0 ? AppColors.error : netPosition > 0 ? Colors.green : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: 14),

            // Category Filter Chips
            Obx(() {
              if (controller.categories.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('All Suppliers (${controller.suppliers.length})'),
                          selected: controller.selectedCategoryId.value.isEmpty,
                          onSelected: (_) {
                            controller.selectedCategoryId.value = '';
                            controller.loadSuppliers();
                          },
                          backgroundColor: AppColors.cardBg,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: controller.selectedCategoryId.value.isEmpty ? FontWeight.bold : FontWeight.normal,
                            color: controller.selectedCategoryId.value.isEmpty ? AppColors.primaryLight : AppColors.textSecondary,
                          ),
                          side: BorderSide(
                            color: controller.selectedCategoryId.value.isEmpty ? AppColors.primary : AppColors.border,
                          ),
                        ),
                      ),
                      ...controller.categories.map((cat) {
                        final isSelected = controller.selectedCategoryId.value == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat.name),
                            selected: isSelected,
                            onSelected: (_) {
                              controller.selectedCategoryId.value = isSelected ? '' : cat.id;
                              controller.loadSuppliers();
                            },
                            backgroundColor: AppColors.cardBg,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primaryLight,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),

            // Search Bar
            TextField(
              onChanged: (val) {
                controller.searchQuery.value = val;
                controller.loadSuppliers();
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                hintText: 'Search supplier by name, phone, or company...',
              ),
            ),
            const SizedBox(height: 14),

            // Supplier List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.suppliers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 10),
                        const Text('No suppliers found', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 180,
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: () => _showSupplierFormDialog(context, controller),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add First Supplier'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: controller.suppliers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = controller.suppliers[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.18),
                          child: const Icon(Icons.business_rounded, color: AppColors.primaryLight, size: 20),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                s.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (s.companyName != null && s.companyName!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(s.companyName!, style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                              ),
                            ],
                            if (s.categoryName != null && s.categoryName!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: Text(s.categoryName!, style: const TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Phone: ${s.phone ?? "N/A"} • Address: ${s.address ?? "N/A"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Financial Breakdown & Net Balance Badge
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (s.payableBalance > 0)
                                      Text(
                                        'Debt: ${Formatters.formatCurrency(s.payableBalance)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 12),
                                      ),
                                    if (s.payableBalance > 0 && s.advanceBalance > 0)
                                      const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                                    if (s.advanceBalance > 0)
                                      Text(
                                        'Adv: ${Formatters.formatCurrency(s.advanceBalance)}',
                                        style: const TextStyle(fontSize: 11.5, color: Colors.green, fontWeight: FontWeight.w600),
                                      ),
                                    if (s.payableBalance == 0 && s.advanceBalance == 0)
                                      const Text('No Debt', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (s.hasDebt ? AppColors.error : s.hasCredit ? Colors.green : Colors.grey).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: (s.hasDebt ? AppColors.error : s.hasCredit ? Colors.green : Colors.grey).withOpacity(0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    s.hasDebt
                                        ? 'Net Balance: -${Formatters.formatCurrency(s.payableBalance - s.advanceBalance)}'
                                        : s.hasCredit
                                            ? 'Net Balance: +${Formatters.formatCurrency(s.advanceBalance - s.payableBalance)}'
                                            : 'Net Balance: 0 Ks',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: s.hasDebt ? AppColors.error : s.hasCredit ? Colors.green : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                              onSelected: (action) {
                                if (action == 'settle') {
                                  _showPaymentDialog(context, controller, s, isAdvance: false);
                                } else if (action == 'advance') {
                                  _showPaymentDialog(context, controller, s, isAdvance: true);
                                } else if (action == 'history') {
                                  _showLedgerHistoryDialog(context, controller, s);
                                } else if (action == 'edit') {
                                  _showSupplierFormDialog(context, controller, supplier: s);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'settle', child: Text('Settle Debt (Repayment)')),
                                const PopupMenuItem(value: 'advance', child: Text('Record Advance Deposit')),
                                const PopupMenuItem(value: 'history', child: Text('View Payment History')),
                                const PopupMenuItem(value: 'edit', child: Text('Edit Supplier')),
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
