import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/purchase_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../utils/product_image_widget.dart';
import '../../../utils/responsive.dart';
import '../../categories/controllers/category_controller.dart';
import '../../products/controllers/product_controller.dart';
import '../../suppliers/controllers/supplier_controller.dart';
import '../controllers/purchase_controller.dart';
import 'package:uuid/uuid.dart';
import '../../../utils/owner_auth_helper.dart';

class PurchaseView extends StatelessWidget {
  const PurchaseView({Key? key}) : super(key: key);

  void _showQuickProductCreateDialog(
    BuildContext context,
    PurchaseController controller,
    ProductController productController, {
    String? initialName,
    VoidCallback? onProductAdded,
  }) {
    final CategoryController categoryController = Get.isRegistered<CategoryController>()
        ? Get.find<CategoryController>()
        : Get.put(CategoryController());

    final nameCtrl = TextEditingController(text: initialName ?? '');
    final costCtrl = TextEditingController();
    final retailCtrl = TextEditingController();
    final wholesaleCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '10');
    final barcodeCtrl = TextEditingController();
    final fabricCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    String selectedUnit = 'piece';
    String? selectedCategoryId;

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            final screenWidth = MediaQuery.of(ctx).size.width;
            final isMobile = screenWidth < 560;

            return Container(
              width: isMobile ? screenWidth * 0.94 : 520,
              constraints: const BoxConstraints(maxWidth: 520),
              padding: EdgeInsets.all(isMobile ? 16 : 22),
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
                            Icon(Icons.add_box_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Add New Product to Inventory',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Create a new product directly and add to this purchase order/invoice.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: '${'product_name'.tr} *',
                        hintText: 'e.g. မန္တလေးချည်ထည် ဝမ်းဆက်, ပိုးလုံချည်',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category selector
                    Obx(() => DropdownButtonFormField<String?>(
                      value: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'category'.tr,
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No Category (None)')),
                        ...categoryController.categories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )),
                      ],
                      onChanged: (val) => setState(() => selectedCategoryId = val),
                    )),
                    const SizedBox(height: 12),

                    // Cost Price, Retail Price, Wholesale Price
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '${'cost_price'.tr} *',
                              hintText: 'e.g. 15000',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: retailCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '${'retail_price'.tr} *',
                              hintText: 'e.g. 22000',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: wholesaleCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'wholesale_price'.tr,
                              hintText: 'e.g. 18000',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Stock In Qty & Unit
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '${'initial_qty'.tr} *',
                              hintText: 'e.g. 10',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: InputDecoration(labelText: 'unit'.tr, isDense: true),
                            items: [
                              DropdownMenuItem(value: 'piece', child: Text('unit_piece'.tr)),
                              DropdownMenuItem(value: 'set', child: Text('unit_set'.tr)),
                              DropdownMenuItem(value: 'yard', child: Text('unit_yard'.tr)),
                              DropdownMenuItem(value: 'roll', child: Text('unit_roll'.tr)),
                              DropdownMenuItem(value: 'pack', child: Text('unit_pack'.tr)),
                            ],
                            onChanged: (val) => setState(() => selectedUnit = val ?? 'piece'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Optional Fabric & Color
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fabricCtrl,
                            decoration: InputDecoration(
                              labelText: 'fabric'.tr,
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: colorCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Color / Size',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              final costStr = costCtrl.text.trim();
                              final retailStr = retailCtrl.text.trim();
                              final wholesaleStr = wholesaleCtrl.text.trim();
                              final qtyStr = qtyCtrl.text.trim();

                              if (name.isEmpty) {
                                Get.snackbar('Required', 'Please enter Product Name',
                                    backgroundColor: Colors.amber.shade800, colorText: Colors.white);
                                return;
                              }
                              final cost = double.tryParse(costStr) ?? 0.0;
                              final retail = double.tryParse(retailStr) ?? (cost > 0 ? cost * 1.3 : 0.0);
                              final wholesale = double.tryParse(wholesaleStr) ?? 0.0;
                              final qty = double.tryParse(qtyStr) ?? 1.0;

                              Get.back(); // close quick product dialog

                              final selectedSup = controller.selectedSupplier.value;
                              final created = await productController.saveProductAndReturn(
                                name: name,
                                categoryId: selectedCategoryId,
                                costPrice: cost,
                                retailPrice: retail,
                                wholesalePrice: wholesale,
                                unit: selectedUnit,
                                fabricType: fabricCtrl.text.trim().isNotEmpty ? fabricCtrl.text.trim() : null,
                                color: colorCtrl.text.trim().isNotEmpty ? colorCtrl.text.trim() : null,
                                barcode: barcodeCtrl.text.trim().isNotEmpty ? barcodeCtrl.text.trim() : null,
                                supplierIds: selectedSup != null ? [selectedSup.id] : null,
                                preferredSupplierId: selectedSup?.id,
                              );

                              if (created != null) {
                                controller.addToCart(created, qty: qty, customCostPrice: cost);
                                onProductAdded?.call();
                              }
                            },
                            child: const Text('Save & Add to Cart'),
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

  void _showNewPurchaseDialog(BuildContext context, PurchaseController controller) {
    final SupplierController supplierController = Get.put(SupplierController());
    final ProductController productController = Get.put(ProductController());
    productController.loadProducts();
    controller.clearCart();

    final paidCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    final productSearchCtrl = TextEditingController();
    final expectedDateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 3))),
    );

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final dialogWidth = MediaQuery.of(context).size.width;
            final isNarrow = dialogWidth < 680;

            return Container(
              width: isNarrow ? dialogWidth * 0.94 : 680,
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
              padding: EdgeInsets.all(isNarrow ? 14 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_shopping_cart_rounded, size: 20, color: AppColors.primaryLight),
                          ),
                          const SizedBox(width: 8),
                          const Text('New Purchase & Supplier Order',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 6),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Order Mode Selector (Direct Stock-In vs Supplier Order)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.cardBgLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('order_type_action'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          controller.isDirectStockIn.value = true;
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: controller.isDirectStockIn.value ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: controller.isDirectStockIn.value ? AppColors.primaryLight : AppColors.border,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.inventory_2_rounded, size: 16, color: controller.isDirectStockIn.value ? AppColors.primaryLight : AppColors.textSecondary),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  'direct_stock_in'.tr,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: controller.isDirectStockIn.value ? FontWeight.bold : FontWeight.normal,
                                                    color: controller.isDirectStockIn.value ? AppColors.primaryLight : AppColors.textSecondary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          controller.isDirectStockIn.value = false;
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: !controller.isDirectStockIn.value ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: !controller.isDirectStockIn.value ? Colors.blue : AppColors.border,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.assignment_outlined, size: 16, color: !controller.isDirectStockIn.value ? Colors.blue : AppColors.textSecondary),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  'place_supplier_order'.tr,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: !controller.isDirectStockIn.value ? FontWeight.bold : FontWeight.normal,
                                                    color: !controller.isDirectStockIn.value ? Colors.blue : AppColors.textSecondary,
                                                  ),
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
                                if (!controller.isDirectStockIn.value) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline_rounded, size: 14, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            Get.locale?.languageCode == 'my'
                                                ? 'မှာယူမှုအဆင့်တွင် စတော့ထဲ ချက်ချင်း မတိုးသေးပါ။ ပစ္စည်းရောက်ရှိချိန်မှသာ စစ်ဆေးလက်ခံပါမည်။'
                                                : 'Stock will not be added immediately. Items will be added upon receiving.',
                                            style: const TextStyle(fontSize: 10.5, color: Colors.blue, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 2. Supplier & Expected Date Row
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Obx(() {
                                  final currentSupplierId = controller.selectedSupplier.value?.id;
                                  final isValidId = supplierController.suppliers.any((s) => s.id == currentSupplierId);
                                  final dropdownValue = isValidId ? currentSupplierId : null;

                                  return DropdownButtonFormField<String?>(
                                    value: dropdownValue,
                                    decoration: InputDecoration(
                                      labelText: '${'select_supplier'.tr} *',
                                      prefixIcon: const Icon(Icons.business_rounded, size: 18, color: AppColors.primaryLight),
                                      isDense: true,
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(value: null, child: Text('General Cash Supplier (None)')),
                                      ...supplierController.suppliers.map((s) => DropdownMenuItem<String?>(
                                        value: s.id,
                                        child: Text('${s.name} ${s.companyName != null ? "(${s.companyName})" : ""}'),
                                      )),
                                    ],
                                    onChanged: (val) {
                                      if (val == null) {
                                        controller.selectedSupplier.value = null;
                                      } else {
                                        controller.selectedSupplier.value = supplierController.suppliers.firstWhereOrNull((s) => s.id == val);
                                      }
                                    },
                                  );
                                }),
                              ),
                              if (!controller.isDirectStockIn.value) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: expectedDateCtrl,
                                    readOnly: true,
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now().add(const Duration(days: 3)),
                                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        expectedDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                                        controller.expectedDeliveryDate.value = expectedDateCtrl.text;
                                      }
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'expected_delivery'.tr,
                                      prefixIcon: const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.blue),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 3. Search & Add Product Header + Add New Product Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'select_products'.tr,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              SizedBox(
                                height: 34,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showQuickProductCreateDialog(
                                      context,
                                      controller,
                                      productController,
                                      initialName: productSearchCtrl.text.trim(),
                                      onProductAdded: () => setState(() {}),
                                    );
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('New Product', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Product Dropdown Selector
                          Obx(() {
                            final allProducts = productController.products;
                            return DropdownButtonFormField<String?>(
                              value: null,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'choose_product_catalog'.tr,
                                prefixIcon: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.secondary),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('-- Select Product from List --', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ),
                                ...allProducts.map((p) => DropdownMenuItem<String?>(
                                  value: p.id,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          p.name,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        'Stock: ${p.stockQty.toStringAsFixed(0)} • Cost: ${Formatters.formatCurrency(p.costPrice)} • Retail: ${Formatters.formatCurrency(p.retailPrice)}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  final selectedProd = allProducts.firstWhereOrNull((p) => p.id == val);
                                  if (selectedProd != null) {
                                    controller.addToCart(selectedProd, qty: 1.0);
                                    setState(() {});
                                  }
                                }
                              },
                            );
                          }),
                          const SizedBox(height: 8),

                          // Product Instant Filter
                          TextField(
                            controller: productSearchCtrl,
                            onChanged: (val) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Type to filter catalog by name...',
                              prefixIcon: const Icon(Icons.filter_list_rounded, size: 16, color: AppColors.textMuted),
                              isDense: true,
                              suffixIcon: productSearchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        productSearchCtrl.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Filter Results List
                          if (productSearchCtrl.text.trim().isNotEmpty)
                            Obx(() {
                              final query = productSearchCtrl.text.trim().toLowerCase();
                              final filtered = productController.products
                                  .where((p) => p.name.toLowerCase().contains(query) || (p.barcode?.toLowerCase().contains(query) ?? false))
                                  .take(4)
                                  .toList();

                              if (filtered.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      const Text('No existing product found. ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      InkWell(
                                        onTap: () {
                                          _showQuickProductCreateDialog(
                                            context,
                                            controller,
                                            productController,
                                            initialName: productSearchCtrl.text.trim(),
                                            onProductAdded: () => setState(() {}),
                                          );
                                        },
                                        child: const Text('Create New Product', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Container(
                                constraints: const BoxConstraints(maxHeight: 180),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBgLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, idx) {
                                    final p = filtered[idx];
                                    final isProfitable = p.retailPrice > p.costPrice;
                                    final estProfit = p.retailPrice - p.costPrice;

                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                      leading: ProductImageWidget(
                                        imageUrl: p.imageUrl,
                                        width: 38,
                                        height: 38,
                                        borderRadius: 6,
                                      ),
                                      title: Text(
                                        p.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Stock: ${p.stockQty.toStringAsFixed(0)} ${p.unit} • Last Cost: ${Formatters.formatCurrency(p.costPrice)}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                'Retail: ${Formatters.formatCurrency(p.retailPrice)}',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                                              ),
                                              if (p.wholesalePrice > 0) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Wholesale: ${Formatters.formatCurrency(p.wholesalePrice)}',
                                                  style: const TextStyle(fontSize: 10.5, color: AppColors.success, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: (isProfitable ? AppColors.success : AppColors.error).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  isProfitable ? 'Profit +${Formatters.formatCurrency(estProfit)}' : 'No Profit',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isProfitable ? AppColors.success : AppColors.error,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: SizedBox(
                                        width: 75,
                                        height: 32,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          onPressed: () {
                                            controller.addToCart(p, qty: 1.0);
                                            productSearchCtrl.clear();
                                            setState(() {});
                                          },
                                          child: const Text('Add +', style: TextStyle(fontSize: 11)),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),
                          const SizedBox(height: 14),

                          // Purchase Cart Table
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('purchase_items_margins'.tr,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Obx(() => Text('${controller.cart.length} item(s)',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
                            ],
                          ),
                          const SizedBox(height: 6),

                          Obx(() {
                            if (controller.cart.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBgLight.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.add_shopping_cart_outlined, size: 30, color: AppColors.textMuted),
                                    SizedBox(height: 6),
                                    Text('No products added yet. Pick from catalog above.',
                                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: controller.cart.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final item = controller.cart[idx];
                                final isProfitable = item.product.retailPrice > item.costPrice;
                                final retailProfit = item.product.retailPrice - item.costPrice;
                                final wholesaleProfit = item.product.wholesalePrice > 0 ? (item.product.wholesalePrice - item.costPrice) : 0.0;
                                final profitPercent = item.costPrice > 0 ? ((retailProfit / item.costPrice) * 100).toStringAsFixed(0) : '0';

                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBgLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.product.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => controller.removeFromCart(idx),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 80,
                                            child: TextFormField(
                                              initialValue: item.quantity.toStringAsFixed(0),
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: 'Qty (${item.product.unit})',
                                                isDense: true,
                                              ),
                                              onChanged: (val) {
                                                final q = double.tryParse(val) ?? 1.0;
                                                controller.updateItemQty(idx, q);
                                                setState(() {});
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 100,
                                            child: TextFormField(
                                              initialValue: item.costPrice.toStringAsFixed(0),
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(labelText: 'cost'.tr, isDense: true),
                                              onChanged: (val) {
                                                final c = double.tryParse(val) ?? 0.0;
                                                controller.updateItemCost(idx, c);
                                                setState(() {});
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                const Text('Subtotal:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                                Text(
                                                  Formatters.formatCurrency(item.subtotal),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // Margin comparison
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (isProfitable ? AppColors.success : AppColors.error).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: (isProfitable ? AppColors.success : AppColors.error).withOpacity(0.3),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Retail: ${Formatters.formatCurrency(item.product.retailPrice)}',
                                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                                ),
                                                if (item.product.wholesalePrice > 0) ...[
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'WS: ${Formatters.formatCurrency(item.product.wholesalePrice)}',
                                                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  isProfitable ? Icons.trending_up_rounded : Icons.warning_amber_rounded,
                                                  size: 13,
                                                  color: isProfitable ? AppColors.success : AppColors.error,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  isProfitable
                                                      ? 'Profit: +${Formatters.formatCurrency(retailProfit)} ($profitPercent%)${item.product.wholesalePrice > 0 ? " • WS: +${Formatters.formatCurrency(wholesaleProfit)}" : ""}'
                                                      : '⚠️ Loss: ${Formatters.formatCurrency(retailProfit)}',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isProfitable ? AppColors.success : AppColors.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Customer Demand & Waiting Appointments section
                                      Obx(() {
                                        final waitingOrders = controller.pendingCustomerOrdersMap[item.product.id] ?? [];
                                        final isLowStock = item.product.stockQty <= item.product.minStockAlert;

                                        if (waitingOrders.isEmpty && !isLowStock) return const SizedBox.shrink();

                                        return Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: waitingOrders.isNotEmpty ? Colors.amber.withOpacity(0.12) : Colors.orange.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: waitingOrders.isNotEmpty ? Colors.amber.shade700.withOpacity(0.4) : Colors.orange.withOpacity(0.3),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (isLowStock) ...[
                                                Row(
                                                  children: [
                                                    const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.orange),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Low Stock: Current ${item.product.stockQty.toStringAsFixed(0)} / Min ${item.product.minStockAlert.toStringAsFixed(0)} ${item.product.unit}',
                                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.orange),
                                                    ),
                                                  ],
                                                ),
                                                if (waitingOrders.isNotEmpty) const SizedBox(height: 3),
                                              ],
                                              if (waitingOrders.isNotEmpty) ...[
                                                Row(
                                                  children: [
                                                    Icon(Icons.assignment_turned_in_rounded, size: 13, color: Colors.amber.shade800),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${waitingOrders.length} Waiting Customer Order(s) (${waitingOrders.fold<double>(0.0, (sum, o) => sum + (o['quantity'] as num).toDouble()).toStringAsFixed(0)} ${item.product.unit} demanded):',
                                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Wrap(
                                                  spacing: 4,
                                                  runSpacing: 3,
                                                  children: waitingOrders.take(3).map((o) {
                                                    final custName = o['customer_name'] ?? 'Customer';
                                                    final orderNo = o['order_no'] ?? '';
                                                    final qty = (o['quantity'] as num?)?.toDouble() ?? 1.0;
                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber.shade100.withOpacity(0.8),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        '$orderNo • $custName (${qty.toStringAsFixed(0)} ${item.product.unit})',
                                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                );
                              },
                            );
                          }),
                          const SizedBox(height: 14),

                          // Payment Summary
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBgLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Obx(() => Text(Formatters.formatCurrency(controller.subtotal),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary))),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: paidCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(labelText: 'paid_advance_paid'.tr),
                                        onChanged: (val) {
                                          controller.paidAmount.value = double.tryParse(val) ?? 0.0;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Obx(() => DropdownButtonFormField<String>(
                                        value: controller.paymentMethod.value,
                                        decoration: const InputDecoration(labelText: 'Payment Method'),
                                        items: const [
                                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                                          DropdownMenuItem(value: 'kpay', child: Text('KPay / Mobile')),
                                          DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                                        ],
                                        onChanged: (val) => controller.paymentMethod.value = val ?? 'cash',
                                      )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Obx(() {
                                  if (controller.dueAmount > 0) {
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Remaining Balance Due:', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
                                        Text(Formatters.formatCurrency(controller.dueAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error)),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          TextField(
                            controller: notesCtrl,
                            decoration: const InputDecoration(labelText: 'Purchase / Order Notes'),
                            onChanged: (val) => controller.notes.value = val,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: controller.isDirectStockIn.value ? AppColors.primary : Colors.blue.shade700,
                          ),
                          onPressed: () async {
                            final isDirect = controller.isDirectStockIn.value;
                            final purchase = await controller.savePurchaseOrder(
                              directStockIn: isDirect,
                              expectedDate: expectedDateCtrl.text.trim(),
                            );
                            if (purchase != null) {
                              if (Get.isDialogOpen ?? false) {
                                Get.back();
                              }
                            }
                          },
                          icon: Icon(controller.isDirectStockIn.value ? Icons.save_rounded : Icons.send_rounded, size: 18),
                          label: Text(controller.isDirectStockIn.value ? 'save_stock_in_now'.tr : 'place_order_btn'.tr),
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

  // Goods Receiving Dialog (Receive Stock against PO)
  void _showReceiveGoodsDialog(BuildContext context, PurchaseController controller, PurchaseModel purchase) {
    final Map<String, TextEditingController> qtyCtrls = {};
    for (var item in purchase.items) {
      qtyCtrls[item.id] = TextEditingController(text: item.remainingQuantity.toStringAsFixed(0));
    }

    final additionalPaidCtrl = TextEditingController(text: '0');
    final receivingNotesCtrl = TextEditingController();
    bool cancelRemaining = false;
    String paymentMethod = 'cash';

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final dialogWidth = MediaQuery.of(context).size.width;
            final isNarrow = dialogWidth < 650;

            return Container(
              width: isNarrow ? dialogWidth * 0.94 : 640,
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
              padding: EdgeInsets.all(isNarrow ? 14 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.archive_rounded, size: 20, color: AppColors.success),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('receive_goods'.tr,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text('PO: ${purchase.invoiceNo} • ${purchase.supplierName ?? "General Supplier"}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Get.back()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 6),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('item_receiving_checklist'.tr,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: purchase.items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final item = purchase.items[idx];
                              final ctrl = qtyCtrls[item.id]!;

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
                                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Ordered: ${item.orderedQuantity.toStringAsFixed(0)} • Received so far: ${item.receivedQuantity.toStringAsFixed(0)} • Remaining: ${item.remainingQuantity.toStringAsFixed(0)} ${item.unit}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 110,
                                      child: TextField(
                                        controller: ctrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Now Receiving',
                                          isDense: true,
                                          suffixText: item.unit,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),

                          // Cancel remaining checkbox
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cancelRemaining ? Colors.red.withOpacity(0.08) : AppColors.cardBgLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: cancelRemaining ? Colors.red.shade300 : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: cancelRemaining,
                                  activeColor: Colors.red,
                                  onChanged: (val) => setState(() => cancelRemaining = val ?? false),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'close_cancel_remaining'.tr,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        Get.locale?.languageCode == 'my'
                                            ? 'ကုန်သွင်းသူထံမှ ကျန်ရှိသည့် ပစ္စည်းများ ထပ်မံမရနိုင်တော့ပါက အော်ဒါကို ဤနေရာတွင် ပိတ်သိမ်းပါမည်။'
                                            : 'If remaining items cannot be delivered, close and complete this order here.',
                                        style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Additional Payment Row
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: additionalPaidCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'additional_payment_made'.tr,
                                    prefixIcon: const Icon(Icons.payments_outlined, size: 18, color: Colors.green),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: paymentMethod,
                                  decoration: const InputDecoration(labelText: 'Payment Method', isDense: true),
                                  items: const [
                                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                                    DropdownMenuItem(value: 'kpay', child: Text('KPay / Mobile')),
                                    DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                                  ],
                                  onChanged: (val) => setState(() => paymentMethod = val ?? 'cash'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          TextField(
                            controller: receivingNotesCtrl,
                            decoration: InputDecoration(
                              labelText: 'receiving_remark'.tr,
                              hintText: 'e.g. ၇ ထည် အရည်အသွေး ကောင်းမွန်စွာ လက်ခံရရှိပါသည်',
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: AppColors.success,
                          ),
                          onPressed: () async {
                            final List<Map<String, dynamic>> itemsReceived = [];
                            for (var item in purchase.items) {
                              final ctrl = qtyCtrls[item.id];
                              final recQty = double.tryParse(ctrl?.text ?? '0') ?? 0.0;
                              itemsReceived.add({
                                'itemId': item.id,
                                'productId': item.productId,
                                'receivedQty': recQty,
                              });
                            }

                            final addPaid = double.tryParse(additionalPaidCtrl.text) ?? 0.0;

                            Get.back(); // close modal
                            await controller.receiveStock(
                              purchaseId: purchase.id,
                              itemsReceived: itemsReceived,
                              cancelRemaining: cancelRemaining,
                              additionalPaid: addPaid,
                              paymentMethod: paymentMethod,
                              receivingNotes: receivingNotesCtrl.text.trim(),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text('Complete Receiving'),
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

  // Follow-up Log Dialog
  void _showFollowUpDialog(BuildContext context, PurchaseController controller, PurchaseModel purchase) {
    final noteCtrl = TextEditingController();
    final newDateCtrl = TextEditingController(text: purchase.expectedDeliveryDate ?? '');

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final dialogWidth = MediaQuery.of(context).size.width;
            final isNarrow = dialogWidth < 520;

            return Container(
              width: isNarrow ? dialogWidth * 0.94 : 500,
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              padding: EdgeInsets.all(isNarrow ? 14 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.phone_callback_rounded, size: 20, color: Colors.amber),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Supplier Follow-up Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text('${purchase.invoiceNo} • ${purchase.supplierName ?? "Supplier"}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Get.back()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 8),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Previous History
                          if (purchase.followUpNotes != null && purchase.followUpNotes!.isNotEmpty) ...[
                            Text('previous_followup_history'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                purchase.followUpNotes!,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary, height: 1.4),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          Text('log_new_followup'.tr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),

                          TextField(
                            controller: noteCtrl,
                            autofocus: true,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'e.g. ဒေါ်လှထံ ဖုန်းဆက်မေးမြန်းခဲ့ပါသည် - ရက်ကန်းစင်ပေါ်တင်ဆဲ၊ ၃ ရက်အတွင်း ပို့မည်ဟုပြောပါသည်',
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: newDateCtrl,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 3)),
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                newDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'reschedule_delivery_date'.tr,
                              prefixIcon: const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                          onPressed: () async {
                            final note = noteCtrl.text.trim();
                            if (note.isEmpty) {
                              Get.snackbar('Required', 'Please enter follow-up note', backgroundColor: Colors.amber.shade800, colorText: Colors.white);
                              return;
                            }

                            Get.back();
                            await controller.logFollowUp(
                              purchaseId: purchase.id,
                              notes: note,
                              nextExpectedDeliveryDate: newDateCtrl.text.isNotEmpty ? newDateCtrl.text : null,
                            );
                          },
                          child: const Text('Save Log'),
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

  void _confirmAndDeletePurchase(
    BuildContext context,
    PurchaseController controller,
    PurchaseModel purchase,
  ) {
    final isReceived = purchase.status == 'RECEIVED' || purchase.status == 'PARTIALLY_RECEIVED';
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
                '${'delete_purchase_order'.tr} (${purchase.invoiceNo})',
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
            Text(
              'delete_purchase_confirm'.tr,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
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
                  Text(
                    isReceived
                        ? '• ${'delete_purchase_stock_warning'.tr}'
                        : '• ${'delete_purchase_order_warning'.tr}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${'supplier'.tr}: ${purchase.supplierName ?? "General Supplier"}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${'total'.tr}: ${Formatters.formatCurrency(purchase.totalAmount)} (${purchase.items.length} ${'items'.tr})',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.secondary),
                  ),
                  if (purchase.dueAmount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${'due'.tr}: ${Formatters.formatCurrency(purchase.dueAmount)}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.error),
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
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Get.back();
              await controller.deletePurchaseOrder(purchase);
            },
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  void _showEditPurchaseDialog(
    BuildContext context,
    PurchaseController controller,
    PurchaseModel purchase,
  ) {
    final SupplierController supplierController = Get.isRegistered<SupplierController>()
        ? Get.find<SupplierController>()
        : Get.put(SupplierController());
    final ProductController productController = Get.isRegistered<ProductController>()
        ? Get.find<ProductController>()
        : Get.put(ProductController());

    final invoiceNoCtrl = TextEditingController(text: purchase.invoiceNo);
    final notesCtrl = TextEditingController(text: purchase.notes ?? '');
    final paidCtrl = TextEditingController(
      text: purchase.paidAmount > 0
          ? (purchase.paidAmount % 1 == 0 ? purchase.paidAmount.toInt().toString() : purchase.paidAmount.toString())
          : '0',
    );
    final expectedDateCtrl = TextEditingController(text: purchase.expectedDeliveryDate ?? '');

    String? selectedSupplierId = purchase.supplierId;
    String? selectedSupplierName = purchase.supplierName;
    String paymentMethod = purchase.paymentMethod;
    final String status = purchase.status;

    final List<_EditPurchaseItem> editItems = purchase.items.map((i) => _EditPurchaseItem(
      id: i.id,
      productId: i.productId,
      productName: i.productName,
      unit: i.unit,
      costPrice: i.costPrice,
      quantity: purchase.status == 'ORDERED' ? i.orderedQuantity : (i.receivedQuantity > 0 ? i.receivedQuantity : i.quantity),
      orderedQuantity: i.orderedQuantity,
      receivedQuantity: i.receivedQuantity,
      rejectedQuantity: i.rejectedQuantity,
      status: i.status,
    )).toList();

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            final screenWidth = MediaQuery.of(ctx).size.width;
            final isMobile = screenWidth < 560;

            final totalAmount = editItems.fold(0.0, (sum, i) => sum + i.subtotal);
            final paidAmount = double.tryParse(paidCtrl.text.replaceAll(',', '')) ?? 0.0;
            final dueAmount = totalAmount > paidAmount ? (totalAmount - paidAmount) : 0.0;

            return Container(
              width: isMobile ? screenWidth * 0.95 : 620,
              constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_note_rounded, size: 22, color: AppColors.primaryLight),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'edit_purchase_order'.tr,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                '${purchase.invoiceNo} • ${purchase.statusLabel}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Supplier & Invoice No Row
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Obx(() => DropdownButtonFormField<String?>(
                                  value: selectedSupplierId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'supplier'.tr,
                                    prefixIcon: const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.primaryLight),
                                    isDense: true,
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('General Supplier', style: TextStyle(fontSize: 12)),
                                    ),
                                    ...supplierController.suppliers.map((s) => DropdownMenuItem<String?>(
                                      value: s.id,
                                      child: Text(s.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                    )),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      selectedSupplierId = val;
                                      if (val == null) {
                                        selectedSupplierName = 'General Supplier';
                                      } else {
                                        final found = supplierController.suppliers.firstWhereOrNull((s) => s.id == val);
                                        selectedSupplierName = found?.name ?? 'General Supplier';
                                      }
                                    });
                                  },
                                )),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: invoiceNoCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Invoice No',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // If status == 'ORDERED' or 'PARTIALLY_RECEIVED', show Expected Delivery Date
                          if (status == 'ORDERED' || status == 'PARTIALLY_RECEIVED') ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: expectedDateCtrl,
                                    readOnly: true,
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now().add(const Duration(days: 3)),
                                        firstDate: DateTime.now().subtract(const Duration(days: 60)),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          expectedDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'expected_delivery'.tr,
                                      prefixIcon: const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.blue),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Items Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${'ordered_fabrics'.tr} (${editItems.length})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              // Dropdown to add more products to this order
                              Obx(() {
                                final products = productController.products;
                                return SizedBox(
                                  width: 170,
                                  child: DropdownButtonFormField<String?>(
                                    value: null,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      hintText: '+ Add Product',
                                      hintStyle: TextStyle(fontSize: 11, color: AppColors.primary),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('+ Add Product', style: TextStyle(fontSize: 11)),
                                      ),
                                      ...products.map((p) => DropdownMenuItem<String?>(
                                        value: p.id,
                                        child: Text(p.name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                                      )),
                                    ],
                                    onChanged: (prodId) {
                                      if (prodId != null) {
                                        final prod = products.firstWhereOrNull((p) => p.id == prodId);
                                        if (prod != null) {
                                          setState(() {
                                            editItems.add(_EditPurchaseItem(
                                              id: const Uuid().v4(),
                                              productId: prod.id,
                                              productName: prod.name,
                                              unit: prod.unit,
                                              costPrice: prod.costPrice > 0 ? prod.costPrice : prod.retailPrice * 0.7,
                                              quantity: 1.0,
                                              orderedQuantity: 1.0,
                                              receivedQuantity: status == 'RECEIVED' ? 1.0 : 0.0,
                                              rejectedQuantity: 0.0,
                                              status: status == 'RECEIVED' ? 'RECEIVED' : 'ORDERED',
                                            ));
                                          });
                                        }
                                      }
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // List of editable items
                          ...editItems.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${idx + 1}. ${item.productName}',
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (editItems.length > 1)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              editItems.removeAt(idx);
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      // Quantity Field
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: item.qtyCtrl,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => setState(() {}),
                                          decoration: InputDecoration(
                                            labelText: '${'qty'.tr} (${item.unit})',
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Cost Price Field
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: item.costCtrl,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => setState(() {}),
                                          decoration: InputDecoration(
                                            labelText: 'cost_price'.tr,
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Subtotal
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Subtotal', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                            Text(
                                              Formatters.formatCurrency(item.subtotal),
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 10),

                          // Payment Method & Paid Amount
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: paymentMethod,
                                  decoration: InputDecoration(labelText: 'payment_method'.tr, isDense: true),
                                  items: [
                                    DropdownMenuItem(value: 'cash', child: Text('payment_cash'.tr)),
                                    DropdownMenuItem(value: 'kpay', child: Text('payment_kpay'.tr)),
                                    DropdownMenuItem(value: 'wave', child: Text('payment_wave'.tr)),
                                    DropdownMenuItem(value: 'bank', child: Text('payment_bank'.tr)),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => paymentMethod = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: paidCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: 'paid_advance_paid'.tr,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Notes Field
                          TextField(
                            controller: notesCtrl,
                            decoration: InputDecoration(
                              labelText: 'notes'.tr,
                              hintText: 'e.g. Order remarks, delivery terms',
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Live Financial Calculation Summary
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
                                    const Text('Total Amount:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    Text(Formatters.formatCurrency(totalAmount),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Paid Amount:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    Text(Formatters.formatCurrency(paidAmount),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                                  ],
                                ),
                                const Divider(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Due Balance (Payable):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
                                    Text(Formatters.formatCurrency(dueAmount),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('cancel'.tr),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () async {
                          if (editItems.isEmpty) {
                            Get.snackbar('Error', 'Order must have at least one product item');
                            return;
                          }

                          final updatedItems = editItems.map((e) {
                            final isDirect = status == 'RECEIVED';
                            return PurchaseItemModel(
                              id: e.id,
                              purchaseId: purchase.id,
                              productId: e.productId,
                              productName: e.productName,
                              unit: e.unit,
                              costPrice: e.costPrice,
                              quantity: isDirect ? e.quantity : e.receivedQuantity,
                              orderedQuantity: e.quantity,
                              receivedQuantity: isDirect ? e.quantity : e.receivedQuantity,
                              rejectedQuantity: e.rejectedQuantity,
                              subtotal: e.subtotal,
                              status: isDirect ? 'RECEIVED' : e.status,
                              syncStatus: 0,
                            );
                          }).toList();

                          final updatedPurchase = purchase.copyWith(
                            invoiceNo: invoiceNoCtrl.text.trim().isNotEmpty ? invoiceNoCtrl.text.trim() : purchase.invoiceNo,
                            supplierId: selectedSupplierId,
                            supplierName: selectedSupplierName,
                            totalAmount: totalAmount,
                            paidAmount: paidAmount,
                            dueAmount: dueAmount,
                            paymentMethod: paymentMethod,
                            status: status,
                            expectedDeliveryDate: expectedDateCtrl.text.trim().isNotEmpty ? expectedDateCtrl.text.trim() : null,
                            notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                            items: updatedItems,
                          );

                          Get.back();
                          await controller.updatePurchaseOrder(
                            updatedPurchase: updatedPurchase,
                            updatedItems: updatedItems,
                          );
                        },
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: Text('save'.tr),
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

  void _showPurchaseDetailsModal(BuildContext context, PurchaseModel purchase, [PurchaseController? ctrl]) {
    final PurchaseController controller = ctrl ?? (Get.isRegistered<PurchaseController>()
        ? Get.find<PurchaseController>()
        : Get.put(PurchaseController()));
    final screenWidth = MediaQuery.of(context).size.width;
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: screenWidth < 550 ? screenWidth * 0.94 : 520,
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
          padding: EdgeInsets.all(screenWidth < 550 ? 14 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Purchase Voucher: ${purchase.invoiceNo}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('Supplier: ${purchase.supplierName ?? "General Supplier"} • ${Formatters.formatDate(purchase.purchaseDate)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Get.back()),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              Expanded(
                child: ListView.separated(
                  itemCount: purchase.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = purchase.items[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(
                        'Ordered: ${item.orderedQuantity.toStringAsFixed(0)} • Received: ${item.receivedQuantity.toStringAsFixed(0)} • ${item.unit} @ ${Formatters.formatCurrency(item.costPrice)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      trailing: Text(Formatters.formatCurrency(item.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary)),
                    );
                  },
                ),
              ),

              const Divider(),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(Formatters.formatCurrency(purchase.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Paid Amount:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(Formatters.formatCurrency(purchase.paidAmount), style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
                ],
              ),
              if (purchase.dueAmount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Due Balance (Payable):', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
                    Text(Formatters.formatCurrency(purchase.dueAmount), style: const TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      OwnerAuthHelper.requireOwnerAccess(
                        context,
                        actionName: 'Delete ${purchase.invoiceNo}',
                        subtitle: 'Authorizing will delete this purchase record and rollback inventory stock.',
                        onAuthorized: () => _confirmAndDeletePurchase(context, controller, purchase),
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                    label: Text('delete'.tr, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error, width: 0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      OwnerAuthHelper.requireOwnerAccess(
                        context,
                        actionName: 'Edit ${purchase.invoiceNo}',
                        subtitle: 'Authorizing will allow editing purchase quantities, prices and supplier.',
                        onAuthorized: () => _showEditPurchaseDialog(context, controller, purchase),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text('edit'.tr, style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
    final PurchaseController controller = Get.put(PurchaseController());
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Purchases & Supplier Orders',
                          style: TextStyle(fontSize: Responsive.titleFontSize(context), fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      const Text('Track supplier orders, follow-up timelines & receive stock',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                SizedBox(
                  height: Responsive.buttonHeight(context),
                  child: ElevatedButton.icon(
                    onPressed: () => _showNewPurchaseDialog(context, controller),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: Text(isMobile ? 'New Order' : 'New Purchase / Order'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Summary Metrics
            Obx(() {
              final totalVolume = controller.purchases.fold(0.0, (sum, p) => sum + p.totalAmount);
              final totalDue = controller.purchases.fold(0.0, (sum, p) => sum + p.dueAmount);
              final pendingCount = controller.purchases.where((p) => p.isPendingDelivery).length;
              final overdueCount = controller.purchases.where((p) => p.isOverdue).length;

              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Invoices', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text('${controller.purchases.length}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: pendingCount > 0 ? Colors.blue.withOpacity(0.5) : AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pending Orders', style: TextStyle(fontSize: 11, color: Colors.blue)),
                          const SizedBox(height: 4),
                          Text('$pendingCount', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                  if (overdueCount > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚠️ Overdue', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('$overdueCount', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Volume', style: TextStyle(fontSize: 11, color: AppColors.primaryLight)),
                            const SizedBox(height: 4),
                            Text(Formatters.formatCurrency(totalVolume), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Unpaid Dues (AP)', style: TextStyle(fontSize: 11, color: AppColors.error)),
                            const SizedBox(height: 4),
                            Text(Formatters.formatCurrency(totalDue), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: 12),

            // Status Filter Tabs
            Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(controller, 'ALL', 'status_all'.tr),
                  const SizedBox(width: 6),
                  _buildFilterChip(controller, 'ORDERED', 'status_ordered'.tr),
                  const SizedBox(width: 6),
                  _buildFilterChip(controller, 'OVERDUE', 'status_overdue'.tr),
                  const SizedBox(width: 6),
                  _buildFilterChip(controller, 'PARTIALLY_RECEIVED', 'status_partially_received'.tr),
                  const SizedBox(width: 6),
                  _buildFilterChip(controller, 'RECEIVED', 'status_received'.tr),
                ],
              ),
            )),
            const SizedBox(height: 10),

            // Search Bar
            TextField(
              onChanged: (val) {
                controller.searchQuery.value = val;
                controller.loadPurchases();
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                hintText: 'Search purchase by invoice no, supplier name, follow-up notes...',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Purchases List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.purchases.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 10),
                        const Text('No purchase or supplier orders found', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 270,
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: () => _showNewPurchaseDialog(context, controller),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Record First Order / Stock In'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: controller.purchases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = controller.purchases[index];
                    final isPending = p.isPendingDelivery;
                    final isOverdue = p.isOverdue;

                    Color statusColor;
                    String statusText = p.statusLabel;

                    if (isOverdue) {
                      statusColor = Colors.red;
                      statusText = '⚠️ ${'status_overdue'.tr}';
                    } else if (p.status == 'ORDERED') {
                      statusColor = Colors.blue;
                    } else if (p.status == 'PARTIALLY_RECEIVED') {
                      statusColor = Colors.amber.shade800;
                    } else if (p.status == 'CANCELLED') {
                      statusColor = Colors.grey;
                    } else {
                      statusColor = AppColors.success;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOverdue ? Colors.red.withOpacity(0.5) : AppColors.border,
                          width: isOverdue ? 1.2 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Header: Invoice No + Status Badge + Amount
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(p.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: statusColor.withOpacity(0.4), width: 0.8),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                Formatters.formatCurrency(p.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Details Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${p.supplierName ?? "General Supplier"} • ${p.items.length} item(s)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              Text(
                                Formatters.formatDate(p.purchaseDate),
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),

                          // Expected Date & Follow-up Row
                          if (p.expectedDeliveryDate != null && p.expectedDeliveryDate!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.schedule_rounded, size: 13, color: isOverdue ? Colors.red : Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  'Expected Delivery: ${p.expectedDeliveryDate}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                                    color: isOverdue ? Colors.red : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          if (p.followUpNotes != null && p.followUpNotes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.note_alt_outlined, size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Last note: ${p.followUpNotes!.split('\n').last}',
                                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 8),

                          // Action Buttons
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (p.dueAmount > 0)
                                      Text('Due: ${Formatters.formatCurrency(p.dueAmount)}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold))
                                    else
                                      const Text('PAID', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(width: 5,),
                                Row(
                                  children: [
                                    if (isPending) ...[
                                      SizedBox(
                                        height: 32,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showFollowUpDialog(context, controller, p),
                                          icon: const Icon(Icons.phone_callback_rounded, size: 14, color: Colors.amber),
                                          label: const Text('Follow-up', style: TextStyle(fontSize: 11, color: Colors.amber)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.amber, width: 0.8),
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      SizedBox(
                                        height: 32,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _showReceiveGoodsDialog(context, controller, p),
                                          icon: const Icon(Icons.archive_rounded, size: 14),
                                          label: const Text('Receive Goods', style: TextStyle(fontSize: 11)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                      onPressed: () {
                                        OwnerAuthHelper.requireOwnerAccess(
                                          context,
                                          actionName: 'Edit ${p.invoiceNo}',
                                          subtitle: 'Authorizing will allow editing purchase quantities, prices and supplier.',
                                          onAuthorized: () => _showEditPurchaseDialog(context, controller, p),
                                        );
                                      },
                                      tooltip: 'edit_purchase_order'.tr,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                      onPressed: () {
                                        OwnerAuthHelper.requireOwnerAccess(
                                          context,
                                          actionName: 'Delete ${p.invoiceNo}',
                                          subtitle: 'Authorizing will delete this purchase record and rollback inventory stock.',
                                          onAuthorized: () => _confirmAndDeletePurchase(context, controller, p),
                                        );
                                      },
                                      tooltip: 'delete_purchase_order'.tr,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textSecondary),
                                      onPressed: () => _showPurchaseDetailsModal(context, p, controller),
                                      tooltip: 'View Details',
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
    );
  }

  Widget _buildFilterChip(PurchaseController controller, String value, String label) {
    final isSelected = controller.selectedStatusFilter.value == value;
    return InkWell(
      onTap: () {
        controller.selectedStatusFilter.value = value;
        controller.loadPurchases();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
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
    );
  }
}

class _EditPurchaseItem {
  final String id;
  final String productId;
  final String productName;
  final String unit;
  final TextEditingController costCtrl;
  final TextEditingController qtyCtrl;
  final double orderedQuantity;
  final double receivedQuantity;
  final double rejectedQuantity;
  final String status;

  _EditPurchaseItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required double costPrice,
    required double quantity,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.rejectedQuantity,
    required this.status,
  })  : costCtrl = TextEditingController(text: costPrice > 0 ? (costPrice % 1 == 0 ? costPrice.toInt().toString() : costPrice.toString()) : '0'),
        qtyCtrl = TextEditingController(text: quantity > 0 ? (quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString()) : '1');

  double get costPrice => double.tryParse(costCtrl.text.replaceAll(',', '')) ?? 0.0;
  double get quantity => double.tryParse(qtyCtrl.text.replaceAll(',', '')) ?? 0.0;
  double get subtotal => costPrice * quantity;
}

