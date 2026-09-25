import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_supplier_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../suppliers/controllers/supplier_controller.dart';
import '../controllers/product_controller.dart';
import 'product_orders_dialog.dart';

class ProductSuppliersDialog extends StatelessWidget {
  final ProductModel product;

  const ProductSuppliersDialog({
    Key? key,
    required this.product,
  }) : super(key: key);

  static void show(BuildContext context, {required ProductModel product}) {
    final ProductController controller = Get.isRegistered<ProductController>()
        ? Get.find<ProductController>()
        : Get.put(ProductController());

    controller.loadProductSuppliers(product.id);

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
          width: isMobile ? screenWidth * 0.95 : 580,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: ProductSuppliersDialog(product: product),
        ),
      ),
    );
  }

  void _showManageSuppliersDialog(BuildContext context, ProductController controller) async {
    final SupplierController supplierController = Get.isRegistered<SupplierController>()
        ? Get.find<SupplierController>()
        : Get.put(SupplierController());

    await supplierController.loadSuppliers();

    final currentSuppliers = controller.productSuppliers;
    final Set<String> selectedIds = currentSuppliers.map((s) => s.supplierId).toSet();
    String? preferredId = currentSuppliers.firstWhereOrNull((s) => s.isPreferred)?.supplierId;

    if (context.mounted) {
      Get.dialog(
        StatefulBuilder(
          builder: (ctx, setState) {
            final screenWidth = MediaQuery.of(ctx).size.width;
            final isMobile = screenWidth < 600;

            return Dialog(
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20,
                vertical: 24,
              ),
              child: Container(
                width: isMobile ? screenWidth * 0.94 : 520,
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            Get.locale?.languageCode == 'my' ? 'ကုန်သွင်းသူများ သတ်မှတ်မည်' : 'Manage Suppliers',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Product: ${product.name}',
                      style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Select suppliers providing this product (Select ⭐ for Preferred):',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: Obx(() {
                        final allSuppliers = supplierController.suppliers;
                        if (allSuppliers.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_outline, size: 40, color: AppColors.textSecondary),
                                const SizedBox(height: 8),
                                const Text('No suppliers found in system', style: TextStyle(color: AppColors.textSecondary)),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: 150,
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Get.back();
                                      _showAddSupplierQuickModal(context, supplierController);
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Supplier', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: allSuppliers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (c, idx) {
                            final sup = allSuppliers[idx];
                            final isSelected = selectedIds.contains(sup.id);
                            final isPref = preferredId == sup.id;

                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: AppColors.primary,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sup.name,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                        ),
                                        if (sup.companyName != null && sup.companyName!.isNotEmpty)
                                          Text(
                                            sup.companyName!,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    IconButton(
                                      tooltip: isPref ? 'Preferred Supplier' : 'Set as Preferred',
                                      icon: Icon(
                                        isPref ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: isPref ? Colors.amber : AppColors.textSecondary,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (isPref) {
                                            preferredId = null;
                                          } else {
                                            preferredId = sup.id;
                                          }
                                        });
                                      },
                                    ),
                                ],
                              ),
                              subtitle: sup.phone != null && sup.phone!.isNotEmpty
                                  ? Text(sup.phone!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
                                  : null,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedIds.add(sup.id);
                                    if (selectedIds.length == 1 && preferredId == null) {
                                      preferredId = sup.id;
                                    }
                                  } else {
                                    selectedIds.remove(sup.id);
                                    if (preferredId == sup.id) {
                                      preferredId = selectedIds.isNotEmpty ? selectedIds.first : null;
                                    }
                                  }
                                });
                              },
                            );
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            _showAddSupplierQuickModal(context, supplierController);
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Supplier', style: TextStyle(fontSize: 12)),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 120,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () async {
                                  Get.back();
                                  final success = await controller.saveProductSuppliers(
                                    product.id,
                                    selectedIds.toList(),
                                    preferredSupplierId: preferredId,
                                  );
                                  if (success) {
                                    Get.snackbar(
                                      'Updated',
                                      'Suppliers for "${product.name}" updated successfully',
                                      backgroundColor: AppColors.primary,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
                                },
                                child: const Text('Save Links'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }

  void _showAddSupplierQuickModal(BuildContext context, SupplierController supplierController) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final companyCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Quick Supplier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: Get.locale?.languageCode == 'my' ? 'ကုန်သွင်းသူ အမည် *' : 'Supplier Name *',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: companyCtrl,
                decoration: InputDecoration(
                  labelText: Get.locale?.languageCode == 'my' ? 'ဆိုင် / ကုမ္ပဏီ အမည်' : 'Company / Shop Name',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: Get.locale?.languageCode == 'my' ? 'ဖုန်းနံပါတ်' : 'Phone',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        Get.back();
                        await supplierController.saveSupplier(
                          name: name,
                          phone: phoneCtrl.text.trim(),
                          companyName: companyCtrl.text.trim(),
                        );
                      },
                      child: const Text('Save'),
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
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
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
                        if (product.barcode != null && product.barcode!.isNotEmpty) ...[
                          Text(
                            'SKU/Barcode: ${product.barcode}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.border.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Stock: ${product.stockQty.toStringAsFixed(0)} ${product.unit}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
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

          // Price Overview Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPriceChip(Get.locale?.languageCode == 'my' ? 'လက်ရှိ ဝယ်စျေး' : 'Current Cost', Formatters.formatCurrency(product.costPrice)),
                _buildPriceChip(Get.locale?.languageCode == 'my' ? 'လက်လီ ရောင်းစျေး' : 'Retail Price', Formatters.formatCurrency(product.retailPrice)),
                if (product.wholesalePrice > 0)
                  _buildPriceChip(Get.locale?.languageCode == 'my' ? 'လက်ကားစျေး' : 'Wholesale Price', Formatters.formatCurrency(product.wholesalePrice)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action Toolbar above list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Get.locale?.languageCode == 'my' ? 'ကုန်သွင်းသူ စာရင်း' : 'Suppliers List',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Get.back();
                      ProductOrdersDialog.show(context, product: product);
                    },
                    icon: const Icon(Icons.assignment_outlined, size: 16, color: AppColors.secondary),
                    label: Text(
                      isMobile ? 'Orders' : 'View Orders',
                      style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: isMobile ? 110 : 130,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () => _showManageSuppliersDialog(context, controller),
                      icon: const Icon(Icons.link_rounded, size: 16),
                      label: Text(
                        isMobile ? 'Manage' : 'Manage Links',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Supplier Cards List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingSuppliers.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final suppliers = controller.productSuppliers;
              if (suppliers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary.withOpacity(0.6)),
                        const SizedBox(height: 10),
                        const Text(
                          'ဤပစ္စည်းအတွက် ကုန်သွင်းသူ မချိတ်ဆက်ရသေးပါ',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'No suppliers linked yet. Link suppliers to track cost history and stock-ins.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 160,
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () => _showManageSuppliersDialog(context, controller),
                            icon: const Icon(Icons.add_link_rounded, size: 16),
                            label: const Text('Link Suppliers', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                itemCount: suppliers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final supplier = suppliers[index];
                  return _buildSupplierCard(context, controller, supplier, isMobile);
                },
              );
            }),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Bottom Close button
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

  Widget _buildPriceChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildSupplierCard(
    BuildContext context,
    ProductController controller,
    ProductSupplierModel supplier,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: supplier.isPreferred ? AppColors.primary.withOpacity(0.5) : AppColors.border,
          width: supplier.isPreferred ? 1.5 : 1.0,
        ),
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
          // Supplier Name + Badges + Unlink option
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            supplier.supplierName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (supplier.isPreferred) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.shade700, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade800),
                                const SizedBox(width: 3),
                                Text(
                                  Get.locale?.languageCode == 'my' ? 'အဓိက' : 'Preferred',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (supplier.companyName != null && supplier.companyName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          supplier.companyName!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                onSelected: (val) async {
                  if (val == 'unlink') {
                    await controller.unlinkProductSupplier(product.id, supplier.supplierId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'unlink',
                    child: Row(
                      children: [
                        Icon(Icons.link_off_rounded, size: 16, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Unlink Supplier', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Contact details
          if ((supplier.phone != null && supplier.phone!.isNotEmpty) ||
              (supplier.address != null && supplier.address!.isNotEmpty)) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                  const Icon(Icons.phone_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(supplier.phone!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                ],
                if (supplier.address != null && supplier.address!.isNotEmpty) ...[
                  const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      supplier.address!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Aggregated Metrics Row
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    '🏷️ Last Cost',
                    supplier.lastCostPrice > 0
                        ? Formatters.formatCurrency(supplier.lastCostPrice)
                        : '-',
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    '📅 Last Stock-In',
                    (supplier.lastPurchaseDate != null && supplier.lastPurchaseDate!.length >= 10)
                        ? supplier.lastPurchaseDate!.substring(0, 10)
                        : '-',
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    '📦 Total Qty',
                    supplier.totalSuppliedQty > 0
                        ? '${supplier.totalSuppliedQty.toStringAsFixed(0)} ${supplier.unit.isNotEmpty ? supplier.unit : product.unit}'
                        : '-',
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    '💰 Total Spend',
                    supplier.totalSpend > 0
                        ? Formatters.formatCurrency(supplier.totalSpend)
                        : '-',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
