import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../utils/product_image_widget.dart';
import '../../../utils/responsive.dart';
import '../../categories/controllers/category_controller.dart';
import '../../pos/views/item_price_history_dialog.dart';
import '../controllers/product_controller.dart';
import 'product_suppliers_dialog.dart';
import 'product_orders_dialog.dart';

class ProductListView extends StatelessWidget {
  const ProductListView({Key? key}) : super(key: key);

  void _showQuickCategoryModal(BuildContext context, CategoryController categoryController, Function(String) onCreated) {
    final catNameCtrl = TextEditingController();
    Responsive.showAdaptiveSheet(
      context: context,
      mobileSizeInitial: 0.45,
      dialogMaxWidth: 400,
      builder: (ctx, scroll) => Container(
        color: AppColors.cardBg,
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          controller: scroll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 6),
              const Text('Add New Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              TextField(
                controller: catNameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  hintText: 'e.g. ဝမ်းဆက်, ချည်ထည်, ပိုးထည်, ဇာ',
                ),
              ),
              const SizedBox(height: 18),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = catNameCtrl.text.trim();
                          if (name.isEmpty) return;
                          Navigator.of(ctx, rootNavigator: true).pop();
                          final cat = await categoryController.saveCategory(name: name);
                          if (cat != null) onCreated(cat.id);
                        },
                        child: const Text('Save Category'),
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
    final ProductController controller = Get.put(ProductController());
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Header
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () => _showProductFormDialog(context, controller),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text('Manage textile inventory & prices', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Products & Inventory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Manage textile items, sizes, fabrics, and wholesale pricing', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  SizedBox(
                    width: 150,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () => _showProductFormDialog(context, controller),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Product'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 14),

            // Search Bar & Visual Search
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      controller.searchQuery.value = val;
                      controller.loadProducts();
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                      hintText: 'Search product by name, barcode, fabric type, color...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showVisualSearchSheet(context, controller),
                  icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryLight),
                  tooltip: 'Visual Image Search',
                ),
                IconButton(
                  onPressed: () {
                    controller.clearVisualSearch();
                    controller.loadProducts();
                  },
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            // Active Visual Search Banner
            Obx(() {
              if (controller.visualSearchImage.value == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryLight, width: 0.8),
                ),
                child: Row(
                  children: [
                    ProductImageWidget(
                      imageUrl: controller.visualSearchImage.value,
                      width: 26,
                      height: 26,
                      borderRadius: 4,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Visual Match: ${controller.products.length} similar item(s) found',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textPrimary),
                      tooltip: 'Clear Visual Search',
                      onPressed: () => controller.clearVisualSearch(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),

            // Products List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text('No products found. Click "+ Add Product" to add one.', style: TextStyle(color: AppColors.textSecondary)),
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
                  child: ListView.separated(
                    itemCount: controller.products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = controller.products[index];
                      return isMobile
                          ? _buildProductItemMobile(context, controller, p)
                          : _buildProductItemDesktop(context, controller, p);
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

  // Mobile Product Item Layout
  Widget _buildProductItemMobile(BuildContext context, ProductController controller, ProductModel p) {
    return InkWell(
      onTap: () => _showProductFormDialog(context, controller, product: p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _showLargeImageModal(context, p),
                  borderRadius: BorderRadius.circular(8),
                  child: ProductImageWidget(
                    imageUrl: p.imageUrl,
                    width: 54,
                    height: 54,
                    borderRadius: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (p.isOneSet == 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.secondary, width: 0.8),
                              ),
                              child: const Text(
                                'ဝမ်းဆက်',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                              ),
                            ),
                          if (p.productStatus != 'AVAILABLE')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.isOutOfStock
                                    ? AppColors.error.withOpacity(0.2)
                                    : (p.isPreOrder ? Colors.amber.shade900.withOpacity(0.3) : Colors.grey.shade800),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: p.isOutOfStock ? AppColors.error : (p.isPreOrder ? Colors.amber : Colors.grey),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                p.statusLabel,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: p.isOutOfStock
                                      ? AppColors.error
                                      : (p.isPreOrder ? Colors.amber : Colors.grey.shade300),
                                ),
                              ),
                            ),
                          Obx(() {
                            final match = controller.visualMatchScores[p.id];
                            if (match == null) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade900.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber.shade400, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, size: 10, color: Colors.amber),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$match% Match',
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fabric: ${p.fabricType ?? "N/A"} • Size: ${p.size ?? "Free"} • Color: ${p.color ?? "N/A"} • Barcode: ${p.barcode ?? "N/A"}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Price, Stock & Action Buttons Bar
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        Formatters.formatCurrency(p.retailPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 13),
                      ),
                      if (p.wholesalePrice > 0)
                        Text(
                          'WS: ${Formatters.formatCurrency(p.wholesalePrice)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: p.isOutOfStock ? AppColors.error.withOpacity(0.15) : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: p.isOutOfStock ? AppColors.error.withOpacity(0.5) : AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Stock: ${Formatters.formatQty(p.stockQty, unit: p.unit)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: p.isOutOfStock ? FontWeight.bold : FontWeight.normal,
                            color: p.isOutOfStock ? AppColors.error : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.assignment_outlined, color: AppColors.secondary, size: 20),
                      tooltip: 'current_orders'.tr,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: () => ProductOrdersDialog.show(context, product: p),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary, size: 20),
                      tooltip: 'price_history'.tr,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: () => ItemPriceHistoryDialog.show(context, product: p),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.local_shipping_outlined, color: AppColors.primaryLight, size: 20),
                      tooltip: 'suppliers'.tr,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: () => ProductSuppliersDialog.show(context, product: p),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryLight, size: 22),
                      tooltip: 'Edit Product',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: () => _showProductFormDialog(context, controller, product: p),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Desktop Product Item Layout
  Widget _buildProductItemDesktop(BuildContext context, ProductController controller, ProductModel p) {
    return InkWell(
      onTap: () => _showProductFormDialog(context, controller, product: p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => _showLargeImageModal(context, p),
              borderRadius: BorderRadius.circular(8),
              child: ProductImageWidget(
                imageUrl: p.imageUrl,
                width: 52,
                height: 52,
                borderRadius: 8,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (p.isOneSet == 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.secondary, width: 0.8),
                          ),
                          child: const Text(
                            'ဝမ်းဆက်',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                        ),
                      ],
                      if (p.productStatus != 'AVAILABLE') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: p.isOutOfStock
                                ? AppColors.error.withOpacity(0.2)
                                : (p.isPreOrder ? Colors.amber.shade900.withOpacity(0.3) : Colors.grey.shade800),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: p.isOutOfStock ? AppColors.error : (p.isPreOrder ? Colors.amber : Colors.grey),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            p.statusLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: p.isOutOfStock
                                  ? AppColors.error
                                  : (p.isPreOrder ? Colors.amber : Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ],
                      Obx(() {
                        final match = controller.visualMatchScores[p.id];
                        if (match == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade900.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.shade400, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 10, color: Colors.amber),
                                const SizedBox(width: 3),
                                Text(
                                  '$match% Match',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.amber),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fabric: ${p.fabricType ?? "N/A"} • Size: ${p.size ?? "Free"} • Color: ${p.color ?? "N/A"} • Barcode: ${p.barcode ?? "N/A"}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(p.retailPrice),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 12),
                ),
                if (p.wholesalePrice > 0)
                  Text(
                    'Wholesale: ${Formatters.formatCurrency(p.wholesalePrice)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                Text(
                  'Stock: ${Formatters.formatQty(p.stockQty, unit: p.unit)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: p.isOutOfStock ? AppColors.error : AppColors.textSecondary,
                    fontWeight: p.isOutOfStock ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.assignment_outlined, color: AppColors.secondary, size: 20),
                  tooltip: 'current_orders'.tr,
                  onPressed: () => ProductOrdersDialog.show(context, product: p),
                ),
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary, size: 20),
                  tooltip: 'price_history'.tr,
                  onPressed: () => ItemPriceHistoryDialog.show(context, product: p),
                ),
                IconButton(
                  icon: const Icon(Icons.local_shipping_outlined, color: AppColors.primaryLight, size: 20),
                  tooltip: 'suppliers'.tr,
                  onPressed: () => ProductSuppliersDialog.show(context, product: p),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryLight, size: 22),
                  tooltip: 'Edit Product',
                  onPressed: () => _showProductFormDialog(context, controller, product: p),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Unified Add / Edit Product Dialog
  void _showProductFormDialog(BuildContext context, ProductController controller, {ProductModel? product}) {
    final isEditing = product != null;
    final CategoryController categoryController = Get.put(CategoryController());
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final fabricCtrl = TextEditingController(text: product?.fabricType ?? '');
    final sizeCtrl = TextEditingController(text: product?.size ?? '');
    final colorCtrl = TextEditingController(text: product?.color ?? '');
    final retailCtrl = TextEditingController(text: product != null ? product.retailPrice.toStringAsFixed(0) : '');
    final wholesaleCtrl = TextEditingController(text: product != null ? product.wholesalePrice.toStringAsFixed(0) : '');
    final stockCtrl = TextEditingController(text: product != null ? product.stockQty.toStringAsFixed(0) : '10');
    String selectedUnit = product?.unit ?? 'piece';
    String? selectedCategoryId = product?.categoryId;
    String selectedStatus = product?.productStatus ?? 'AVAILABLE';
    final List<String> selectedImages = product != null ? List<String>.from(product.imageList) : [];
    bool isOneSet = product?.isOneSet == 1;
    bool isSaving = false;

    Responsive.showAdaptiveSheet(
      context: context,
      mobileSizeInitial: 0.94,
      mobileSizeMax: 0.97,
      dialogMaxWidth: 540,
      builder: (ctx, scroll) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final isMobile = Responsive.isMobile(ctx);
            return Container(
              color: AppColors.cardBg,
              child: Column(
                children: [
                  const SheetDragHandle(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scroll,
                      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 0, isMobile ? 16 : 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
                      child:Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isEditing ? 'Edit Textile Product' : 'Add New Textile Product',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Multi-Photo Picker Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Product Photos (Multiple Photos Supported)',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  if (selectedImages.isNotEmpty)
                                    Text('${selectedImages.length} photo(s)', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Thumbnails row
                              if (selectedImages.isNotEmpty)
                                SizedBox(
                                  height: 72,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: selectedImages.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (context, idx) {
                                      return Stack(
                                        children: [
                                          ProductImageWidget(
                                            imageUrl: selectedImages[idx],
                                            width: 70,
                                            height: 70,
                                            borderRadius: 8,
                                          ),
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: InkWell(
                                              onTap: () => setState(() => selectedImages.removeAt(idx)),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.75),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 8),

                              // Add Photo Buttons
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final img = await controller.pickProductImage(isCamera: false);
                                      if (img != null) {
                                        setState(() => selectedImages.add(img));
                                      }
                                    },
                                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 15),
                                    label: const Text('+ Gallery / File', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final img = await controller.pickProductImage(isCamera: true);
                                      if (img != null) {
                                        setState(() => selectedImages.add(img));
                                      }
                                    },
                                    icon: const Icon(Icons.add_a_photo_rounded, size: 15),
                                    label: const Text('+ Camera', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                  if (selectedImages.isNotEmpty)
                                    TextButton(
                                      onPressed: () => setState(() => selectedImages.clear()),
                                      child: const Text('Clear All', style: TextStyle(fontSize: 11, color: AppColors.error)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(),
                          const SizedBox(height: 10),

                          // Category Selector with + New Category Button
                          Row(
                            children: [
                              Expanded(
                                child: Obx(() => DropdownButtonFormField<String?>(
                                  value: (selectedCategoryId != null && categoryController.categories.any((c) => c.id == selectedCategoryId))
                                      ? selectedCategoryId
                                      : null,
                                  decoration: InputDecoration(
                                    labelText: 'category'.tr,
                                    prefixIcon: const Icon(Icons.category_rounded, size: 18, color: AppColors.primaryLight),
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
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryLight, size: 24),
                                tooltip: 'Add New Category',
                                onPressed: () => _showQuickCategoryModal(context, categoryController, (newCatId) {
                                  setState(() => selectedCategoryId = newCatId);
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Product Name
                          TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Product Name *',
                              hintText: 'e.g. ပိုးချည် ရင်ဖုံး အင်္ကျီ',
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Barcode
                          TextField(
                            controller: barcodeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Barcode (Auto-generated if blank)',
                              hintText: 'e.g. 10001 or scan code',
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ဝမ်းဆက် (One Set) Checkbox
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardBgLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isOneSet ? AppColors.secondary : AppColors.border,
                                width: isOneSet ? 1.5 : 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isOneSet,
                              onChanged: (val) => setState(() => isOneSet = val ?? false),
                              activeColor: AppColors.secondary,
                              checkColor: Colors.black,
                              title: Text(
                                'one_set'.tr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              subtitle: Text(
                                Get.locale?.languageCode == 'my'
                                    ? 'အင်္ကျီနှင့် လုံချည် တွဲဖက်ရောင်းချသော ဝမ်းဆက်ဖြစ်ပါက အမှန်ခြစ်ပါ'
                                    : 'Check if this product is sold as a matching top & bottom set',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Fabric & Unit Selection
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: fabricCtrl,
                                  decoration: InputDecoration(labelText: 'fabric'.tr),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedUnit,
                                  decoration: InputDecoration(labelText: 'unit'.tr),
                                  items: [
                                    DropdownMenuItem(value: 'piece', child: Text('unit_piece'.tr)),
                                    DropdownMenuItem(value: 'set', child: Text('unit_set'.tr)),
                                    DropdownMenuItem(value: 'yard', child: Text('unit_yard'.tr)),
                                    DropdownMenuItem(value: 'meter', child: Text('unit_meter'.tr)),
                                  ],
                                  onChanged: (val) => setState(() => selectedUnit = val ?? 'piece'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Size & Color
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: sizeCtrl,
                                  decoration: const InputDecoration(labelText: 'Size (S, M, L, XL, Free)'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: colorCtrl,
                                  decoration: InputDecoration(labelText: Get.locale?.languageCode == 'my' ? 'အရောင်' : 'Color'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Retail & Wholesale Price
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: retailCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Retail Price (Ks) *'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: wholesaleCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Wholesale Price (Ks)'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Stock Quantity & Status Row
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: stockCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Stock Qty'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedStatus,
                                  decoration: InputDecoration(labelText: Get.locale?.languageCode == 'my' ? 'အခြေအနေ' : 'Status'),
                                  items: [
                                    DropdownMenuItem(value: 'AVAILABLE', child: Text('status_available'.tr)),
                                    DropdownMenuItem(value: 'OUT_OF_STOCK', child: Text('status_out_of_stock'.tr)),
                                    DropdownMenuItem(value: 'PRE_ORDER', child: Text('status_pre_order'.tr)),
                                    DropdownMenuItem(value: 'DISCONTINUED', child: Text('status_discontinued'.tr)),
                                  ],
                                  onChanged: (val) => setState(() => selectedStatus = val ?? 'AVAILABLE'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Dialog Actions
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isSaving ? null : () => Navigator.of(context, rootNavigator: true).pop(),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                    final name = nameCtrl.text.trim();
                                    final retail = retailCtrl.text.trim();

                                    if (name.isEmpty) {
                                      Get.snackbar('Input Error', 'Please enter Product Name',
                                          backgroundColor: Colors.amber.shade800, colorText: Colors.white);
                                      return;
                                    }

                                    if (retail.isEmpty || double.tryParse(retail) == null) {
                                      Get.snackbar('Input Error', 'Please enter a valid Retail Price',
                                          backgroundColor: Colors.amber.shade800, colorText: Colors.white);
                                      return;
                                    }

                                    setState(() => isSaving = true);

                                    try {
                                      final saved = await controller.saveProduct(
                                        id: product?.id,
                                        name: name,
                                        barcode: barcodeCtrl.text.trim().isNotEmpty ? barcodeCtrl.text.trim() : null,
                                        categoryId: selectedCategoryId,
                                        fabricType: fabricCtrl.text.trim(),
                                        size: sizeCtrl.text.trim(),
                                        color: colorCtrl.text.trim(),
                                        unit: selectedUnit,
                                        retailPrice: double.tryParse(retail) ?? 0.0,
                                        wholesalePrice: double.tryParse(wholesaleCtrl.text.trim()) ?? 0.0,
                                        stockQty: double.tryParse(stockCtrl.text.trim()) ?? 0.0,
                                        imageUrl: selectedImages.isEmpty
                                            ? null
                                            : (selectedImages.length == 1 ? selectedImages.first : jsonEncode(selectedImages)),
                                        isOneSet: isOneSet ? 1 : 0,
                                        productStatus: selectedStatus,
                                      );

                                      if (saved) {
                                        Navigator.of(ctx, rootNavigator: true).pop();
                                      } else {
                                        setState(() => isSaving = false);
                                      }
                                    } catch (e) {
                                      setState(() => isSaving = false);
                                    }
                                  },
                                  child: isSaving
                                      ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                      : Text(isEditing ? 'Update Product' : 'Save Product'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  void _showLargeImageModal(BuildContext context, ProductModel product) {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 440,
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  ),
                ],
              ),
              // Multi-Image Gallery with Retail and Wholesale Prices
              MultiImageGalleryView(
                images: product.imageList,
                retailPrice: product.retailPrice,
                wholesalePrice: product.wholesalePrice,
                minWholesaleQty: product.minWholesaleQty,
                unit: product.unit,
              ),
              const SizedBox(height: 16),
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
                    Text('Fabric: ${product.fabricType ?? "N/A"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('Size: ${product.size ?? "Free"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('Color: ${product.color ?? "N/A"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVisualSearchSheet(BuildContext context, ProductController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Visual Image Search', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Take or upload a sample photo of a fabric or dress to find similar products in inventory.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        controller.searchByVisualImage(isCamera: false);
                      },
                      icon: const Icon(Icons.photo_library_rounded, color: AppColors.primaryLight),
                      label: const Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          controller.searchByVisualImage(isCamera: true);
                        },
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
