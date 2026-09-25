import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/delivery_service_model.dart';
import '../../../data/local/delivery_service_dao.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../utils/product_image_widget.dart';
import '../controllers/pos_controller.dart';
import 'receipt_dialog.dart';
import 'item_price_history_dialog.dart';

class POSView extends StatelessWidget {
  const POSView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final POSController posController = Get.put(POSController());
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      // MOBILE VIEW: Full-Width Product Grid + Bottom Floating Cart Bar
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Search and Refresh Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            posController.searchQuery.value = val;
                            posController.loadProducts();
                          },
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                            hintText: 'Search products by name, barcode, fabric...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Visual Image Search Button
                      IconButton(
                        onPressed: () => _showVisualSearchOptions(context, posController),
                        icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryLight),
                        tooltip: 'Visual Image Search (Find similar fabric/photo)',
                      ),
                      IconButton(
                        onPressed: () => _showRecentVouchersDialog(context, posController),
                        icon: Obx(() => Badge(
                          label: Text('${posController.todayVouchers.length}'),
                          isLabelVisible: posController.todayVouchers.isNotEmpty,
                          backgroundColor: Colors.teal,
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.tealAccent),
                        )),
                        tooltip: "Today's Vouchers",
                      ),
                      IconButton(
                        onPressed: () {
                          posController.clearVisualSearch();
                          posController.loadProducts();
                          posController.loadTodayVouchers();
                        },
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                        tooltip: 'Refresh Products & Sales',
                      ),
                    ],
                  ),
                  // Active Visual Search Filter Banner
                  Obx(() {
                    if (posController.visualSearchImage.value == null) return const SizedBox.shrink();
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
                            imageUrl: posController.visualSearchImage.value,
                            width: 26,
                            height: 26,
                            borderRadius: 4,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Visual Match: ${posController.products.length} similar item(s) found',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textPrimary),
                            tooltip: 'Clear Visual Search',
                            onPressed: () => posController.clearVisualSearch(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Product Grid (2 columns on mobile)
            Expanded(
              child: Obx(() {
                if (posController.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text('No products found', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: posController.products.length,
                  itemBuilder: (context, index) {
                    final product = posController.products[index];
                    return _buildProductCard(context, product, posController);
                  },
                );
              }),
            ),

            // Floating Bottom Cart Bar for Mobile
            Obx(() {
              if (posController.cart.isEmpty) return const SizedBox.shrink();

              final totalItems = posController.cart.fold<double>(0.0, (sum, i) => sum + i.quantity);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${Formatters.formatQty(totalItems)} Items in Cart',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            Text(
                              Formatters.formatCurrency(posController.grandTotal),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _showMobileCartBottomSheet(context, posController),
                          icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                          label: const Text('View Cart'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    // DESKTOP & TABLET VIEW (>= 768px): Split Grid & Cart Panel
    return Scaffold(
      body: Row(
        children: [
          // LEFT PANEL: Product Search, Category Filter, Product Grid
          Expanded(
            flex: 6,
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            posController.searchQuery.value = val;
                            posController.loadProducts();
                          },
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                            hintText: 'Search products by name, barcode, fabric, color...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Visual Image Search Button
                      SizedBox(
                        width: 145,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _showVisualSearchOptions(context, posController),
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: const Text('Image Search', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardBgLight,
                            foregroundColor: AppColors.primaryLight,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Today's Vouchers Button in Top Bar
                      SizedBox(
                        width: 180,
                        height: 44,
                        child: Obx(() => ElevatedButton.icon(
                          onPressed: () => _showRecentVouchersDialog(context, posController),
                          icon: const Icon(Icons.receipt_long_rounded, size: 16),
                          label: Text("Today's Vouchers (${posController.todayVouchers.length})", style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardBgLight,
                            foregroundColor: Colors.tealAccent,
                            side: BorderSide(color: Colors.teal.shade700),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        )),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          posController.clearVisualSearch();
                          posController.loadProducts();
                          posController.loadTodayVouchers();
                        },
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                        tooltip: 'Refresh Products & Vouchers',
                      ),
                    ],
                  ),
                  // Active Visual Search Filter Banner
                  Obx(() {
                    if (posController.visualSearchImage.value == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Row(
                        children: [
                          ProductImageWidget(
                            imageUrl: posController.visualSearchImage.value,
                            width: 32,
                            height: 32,
                            borderRadius: 6,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Visual Image Search Filter Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                Text('Found ${posController.products.length} visually matching product(s)', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.close_rounded, size: 14),
                            label: const Text('Clear Filter', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            onPressed: () => posController.clearVisualSearch(),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 14),

                  // Product Grid
                  Expanded(
                    child: Obx(() {
                      if (posController.products.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text('No products found', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.15,
                        ),
                        itemCount: posController.products.length,
                        itemBuilder: (context, index) {
                          final product = posController.products[index];
                          return _buildProductCard(context, product, posController);
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // VERTICAL SEPARATOR
          Container(width: 1, color: AppColors.border),

          // RIGHT PANEL: Cart & Checkout
          Expanded(
            flex: 4,
            child: _buildCartPanel(context, posController),
          ),
        ],
      ),
    );
  }

  // Mobile Cart Bottom Sheet
  void _showMobileCartBottomSheet(BuildContext context, POSController posController) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Bottom Sheet Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Cart Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // Expanded Cart Body
            Expanded(
              child: _buildCartPanel(context, posController, isModal: true),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // Single Product Card Component
  Widget _buildProductCard(BuildContext context, ProductModel product, POSController posController) {
    return InkWell(
      onTap: () => posController.addToCart(product, qty: 1.0),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.unit.toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                          ),
                        ),
                        if (product.isOneSet == 1) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.secondary, width: 0.8),
                            ),
                            child: const Text(
                              'ဝမ်းဆက်',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                          ),
                        ],
                        if (product.productStatus != 'AVAILABLE') ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.isOutOfStock
                                  ? AppColors.error.withOpacity(0.25)
                                  : (product.isPreOrder ? Colors.amber.shade900.withOpacity(0.35) : Colors.grey.shade800),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: product.isOutOfStock ? AppColors.error : (product.isPreOrder ? Colors.amber : Colors.grey),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              product.statusLabel,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: product.isOutOfStock
                                    ? AppColors.error
                                    : (product.isPreOrder ? Colors.amber : Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ],
                        // Visual Match Score Badge
                        Obx(() {
                          final match = posController.visualMatchScores[product.id];
                          if (match == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade900.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber.shade400, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, size: 9, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$match%',
                                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  Formatters.formatQty(product.stockQty, unit: product.unit),
                  style: TextStyle(
                    fontSize: 10,
                    color: product.stockQty <= product.minStockAlert ? AppColors.error : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                InkWell(
                  onTap: () => _showLargePhotoDialog(context, product, posController),
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      ProductImageWidget(
                        imageUrl: product.imageUrl,
                        width: 42,
                        height: 42,
                        borderRadius: 8,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.zoom_in_rounded, size: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      if (product.fabricType != null || product.color != null)
                        Text(
                          '${product.fabricType ?? ""} ${product.color ?? ""}'.trim(),
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Formatters.formatCurrency(product.retailPrice),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                      if (product.wholesalePrice > 0)
                        Text(
                          'Wholesale: ${Formatters.formatCurrency(product.wholesalePrice)} (≥${product.minWholesaleQty.toInt()})',
                          style: const TextStyle(fontSize: 9.5, color: AppColors.success, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Cart & Checkout Panel Component
  Widget _buildCartPanel(BuildContext context, POSController posController, {bool isModal = false}) {
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Action Buttons (Held Orders, Hold Order, Clear Cart)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Current Order', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(width: 6),
                  Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${posController.cart.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                    ),
                  )),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Held Orders List Button
                  Obx(() {
                    final count = posController.heldOrders.length;
                    return InkWell(
                      onTap: () => _showHeldOrdersDialog(context, posController),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: count > 0 ? Colors.amber.shade900.withOpacity(0.2) : AppColors.cardBgLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: count > 0 ? Colors.amber.shade600 : AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pause_circle_outline_rounded, size: 14, color: count > 0 ? Colors.amber : AppColors.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              'Held ($count)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: count > 0 ? Colors.amber : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),

                  // Today's Sales Vouchers Button
                  Obx(() {
                    final count = posController.todayVouchers.length;
                    return InkWell(
                      onTap: () => _showRecentVouchersDialog(context, posController),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: count > 0 ? Colors.teal.shade900.withOpacity(0.22) : AppColors.cardBgLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: count > 0 ? Colors.tealAccent.shade400 : AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 14, color: count > 0 ? Colors.tealAccent : AppColors.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              'Sales ($count)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: count > 0 ? Colors.tealAccent : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),

                  // Hold Order Button (when cart has items)
                  Obx(() {
                    if (posController.cart.isEmpty) return const SizedBox.shrink();
                    return Tooltip(
                      message: 'Hold / Save Incomplete Order',
                      child: InkWell(
                        onTap: () => _showHoldOrderDialog(context, posController),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.pause_rounded, size: 16, color: Colors.amber),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),

                  // Clear Cart Button (when cart has items)
                  Obx(() {
                    if (posController.cart.isEmpty) return const SizedBox.shrink();
                    return Tooltip(
                      message: 'Clear Cart Items (ရှင်းမည်)',
                      child: InkWell(
                        onTap: () => _showClearCartConfirmDialog(context, posController),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.delete_sweep_rounded, size: 16, color: AppColors.error),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Customer Selector Row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showCustomerSearchDialog(context, posController),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Obx(() {
                            final c = posController.selectedCustomer.value;
                            if (c == null) {
                              return const Text(
                                'Select Customer (Walk-in)',
                                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (c.phone != null && c.phone!.isNotEmpty)
                                  Text(
                                    c.phone!,
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                              ],
                            );
                          }),
                        ),
                        Obx(() {
                          if (posController.selectedCustomer.value != null) {
                            return InkWell(
                              onTap: () => posController.selectedCustomer.value = null,
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                              ),
                            );
                          }
                          return const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted);
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBgLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: AppColors.primaryLight),
                  tooltip: 'Create New Customer',
                  onPressed: () => _showQuickCustomerCreateDialog(context, posController),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cart Items List
          Expanded(
            child: Obx(() {
              if (posController.cart.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.shopping_cart_outlined, size: 36, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text('Cart is empty', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: posController.cart.length,
                separatorBuilder: (_, __) => const Divider(height: 8),
                itemBuilder: (context, index) {
                  final item = posController.cart[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            InkWell(
                              onTap: () => _showEditItemPriceDialog(context, index, item, posController),
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${Formatters.formatCurrency(item.price)} × ${Formatters.formatQty(item.quantity, unit: item.product.unit)}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_outlined, size: 11, color: AppColors.secondary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Decimal Yard/Meter Quantity Stepper
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.error),
                            onPressed: () => posController.updateQuantity(index, item.quantity - (item.product.unit == 'piece' ? 1.0 : 0.5)),
                          ),
                          InkWell(
                            onTap: () => _showDecimalQtyDialog(context, index, item, posController),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                Formatters.formatQty(item.quantity),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.success),
                            onPressed: () => posController.updateQuantity(index, item.quantity + (item.product.unit == 'piece' ? 1.0 : 0.5)),
                          ),
                        ],
                      ),
                      Text(
                        Formatters.formatCurrency(item.total),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 12),
          const Divider(),

          // Payment Summary
          Obx(() => Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text(Formatters.formatCurrency(posController.subtotal), style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text(
                    Formatters.formatCurrency(posController.grandTotal),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                ],
              ),
            ],
          )),
          const SizedBox(height: 14),

          // Payment Method Selector
          Obx(() => Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Cash', style: TextStyle(fontSize: 12))),
                  selected: posController.selectedPaymentMethod.value == 'cash',
                  onSelected: (_) => posController.selectedPaymentMethod.value = 'cash',
                  selectedColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('KPay', style: TextStyle(fontSize: 12))),
                  selected: posController.selectedPaymentMethod.value == 'kpay',
                  onSelected: (_) => posController.selectedPaymentMethod.value = 'kpay',
                  selectedColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Credit', style: TextStyle(fontSize: 12))),
                  selected: posController.selectedPaymentMethod.value == 'credit',
                  onSelected: (_) => posController.selectedPaymentMethod.value = 'credit',
                  selectedColor: AppColors.error,
                ),
              ),
            ],
          )),
          const SizedBox(height: 14),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _handleCheckout(context, posController),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: const Text('Complete Sale & Print Receipt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Decimal Quantity Direct Input Dialog for Textile Yards/Meters
  void _showDecimalQtyDialog(BuildContext context, int index, CartItem item, POSController posController) {
    final controller = TextEditingController(text: item.quantity.toString());
    Get.defaultDialog(
      title: 'Enter Quantity (${item.product.unit})',
      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      backgroundColor: AppColors.cardBg,
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Quantity in ${item.product.unit}',
            hintText: 'e.g. 2.5',
          ),
        ),
      ),
      textConfirm: 'Update',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () {
        final val = double.tryParse(controller.text.trim()) ?? 1.0;
        posController.updateQuantity(index, val);
        Get.back();
      },
    );
  }

  // Quick Customer Registration Dialog
  void _showQuickCustomerCreateDialog(BuildContext context, POSController posController, {String initialText = ''}) {
    final isPhoneLike = RegExp(r'^[0-9+ ]+$').hasMatch(initialText.trim()) && initialText.trim().length >= 4;
    final nameCtrl = TextEditingController(text: isPhoneLike ? '' : initialText.trim());
    final phoneCtrl = TextEditingController(text: isPhoneLike ? initialText.trim() : '');
    final addressCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '0');

    final screenWidth = MediaQuery.of(context).size.width;
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          width: screenWidth < 460 ? screenWidth * 0.94 : 420,
          padding: EdgeInsets.all(screenWidth < 460 ? 14 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.person_add_rounded, color: AppColors.primaryLight, size: 22),
                      SizedBox(width: 8),
                      Text('Quick Add Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  hintText: 'e.g. ဒေါ်လှလှ',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '09xxxxxxxxx',
                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address / Location',
                  hintText: 'e.g. မန္တလေးမြို့',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: limitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Credit Limit (Ks)',
                  prefixIcon: Icon(Icons.credit_card_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 20),

              Row(
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
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          Get.snackbar('Input Error', 'Please enter customer name',
                              backgroundColor: Colors.amber.shade800, colorText: Colors.white);
                          return;
                        }

                        Get.back(); // close quick registration
                        final newCust = await posController.createAndSelectCustomer(
                          name: name,
                          phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                          address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                          creditLimit: double.tryParse(limitCtrl.text.trim()) ?? 0.0,
                        );

                        Get.snackbar(
                          'Customer Registered',
                          '${newCust.name} has been created and selected for this sale',
                          backgroundColor: AppColors.success.withOpacity(0.85),
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );
                      },
                      child: const Text('Save & Select'),
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

  // Customer Selection Search Dialog with Name / Phone filtering & quick creation
  void _showCustomerSearchDialog(BuildContext context, POSController posController) {
    final searchCtrl = TextEditingController();
    String query = '';

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final filtered = posController.customers.where((c) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              final matchesName = c.name.toLowerCase().contains(q);
              final matchesPhone = c.phone != null && c.phone!.contains(q);
              return matchesName || matchesPhone;
            }).toList();

            final screenWidth = MediaQuery.of(context).size.width;
            return Container(
              constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
              width: screenWidth < 460 ? screenWidth * 0.94 : 440,
              padding: EdgeInsets.all(screenWidth < 460 ? 14 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Customer',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Bar with real-time name & phone filtering
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by Name or Phone (အမည်/ဖုန်း)...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                searchCtrl.clear();
                                setState(() => query = '');
                              },
                            )
                          : null,
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => query = val.trim()),
                  ),
                  const SizedBox(height: 10),

                  // Walk-in option
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    leading: const CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.cardBgLight,
                      child: Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                    ),
                    title: const Text('Walk-in Customer (General)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onTap: () {
                      posController.selectedCustomer.value = null;
                      Get.back();
                    },
                  ),
                  const Divider(height: 8),

                  // Customers List or No Result State
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_search_rounded, size: 44, color: AppColors.textMuted),
                                  const SizedBox(height: 8),
                                  Text(
                                    query.isNotEmpty
                                        ? 'No customer found matching "$query"'
                                        : 'No registered customers yet',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: 190,
                                    height: 40,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Get.back(); // close search
                                        _showQuickCustomerCreateDialog(context, posController, initialText: query);
                                      },
                                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                                      label: Text(
                                        query.isNotEmpty ? 'Register "$query"' : 'Create New Customer',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final c = filtered[idx];
                              final isSelected = posController.selectedCustomer.value?.id == c.id;

                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: AppColors.primary.withOpacity(0.12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                leading: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: (c.currentDebt > 0 ? AppColors.error : AppColors.primary).withOpacity(0.15),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                    color: c.currentDebt > 0 ? AppColors.error : AppColors.primaryLight,
                                  ),
                                ),
                                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                subtitle: Text(
                                  c.phone ?? 'No phone',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                trailing: c.currentDebt > 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Debt: ${Formatters.formatCurrency(c.currentDebt)}',
                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.error),
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  posController.selectedCustomer.value = c;
                                  Get.back();
                                },
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Bottom Action: Direct Create Customer Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${posController.customers.length} customer(s)',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Get.back();
                          _showQuickCustomerCreateDialog(context, posController, initialText: query);
                        },
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                        label: const Text('+ New Customer', style: TextStyle(fontSize: 12)),
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

  // Hold Current Order Dialog
  void _showHoldOrderDialog(BuildContext context, POSController posController) {
    final noteCtrl = TextEditingController();
    final screenWidth = MediaQuery.of(context).size.width;
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          width: screenWidth < 440 ? screenWidth * 0.94 : 400,
          padding: EdgeInsets.all(screenWidth < 440 ? 14 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.pause_circle_outline_rounded, color: Colors.amber, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Hold Current Order (ခေတ္တဆိုင်းငံ့မည်)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
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
              Text(
                'Hold ${posController.cart.length} items (Total: ${Formatters.formatCurrency(posController.grandTotal)}) and clear cart to serve the next customer.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hold Note / Table Reference (optional)',
                  hintText: 'e.g. Customer getting cash / Table 3',
                  prefixIcon: Icon(Icons.note_alt_outlined, size: 18, color: AppColors.primaryLight),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Get.back();
                          await posController.holdCurrentOrder(notes: noteCtrl.text.trim());
                        },
                        icon: const Icon(Icons.pause_rounded, size: 18),
                        label: const Text('Confirm Hold', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
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

  // Held Orders List Modal
  void _showHeldOrdersDialog(BuildContext context, POSController posController) {
    final screenWidth = MediaQuery.of(context).size.width;
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          width: screenWidth < 540 ? screenWidth * 0.94 : 500,
          height: 480,
          padding: EdgeInsets.all(screenWidth < 500 ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pending_actions_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Obx(() => Text(
                        'Held Orders (${posController.heldOrders.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      )),
                    ],
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
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  if (posController.heldOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.inbox_outlined, size: 42, color: AppColors.textMuted),
                          SizedBox(height: 8),
                          Text('No held orders currently parked.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: posController.heldOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = posController.heldOrders[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgLight,
                          borderRadius: BorderRadius.circular(10),
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
                                        order.customerName ?? 'Walk-in Customer',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      if (order.customerPhone != null && order.customerPhone!.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${order.customerPhone})',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.items.length} items  •  ${Formatters.formatCurrency(order.grandTotal)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
                                  ),
                                  if (order.notes != null && order.notes!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Note: ${order.notes}',
                                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.error),
                              tooltip: 'Delete Held Order',
                              onPressed: () => posController.deleteHeldOrder(order.id),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 155,
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (posController.cart.isNotEmpty) {
                                    final overwrite = await Get.dialog<bool>(
                                      AlertDialog(
                                        backgroundColor: AppColors.cardBg,
                                        title: const Text('Active Cart Notice', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                        content: const Text('Current cart has items. Replace current cart with this held order?'),
                                        actions: [
                                          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                                          SizedBox(
                                            width: 90,
                                            height: 36,
                                            child: ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Replace')),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (overwrite != true) return;
                                  }
                                  Get.back();
                                  await posController.resumeHeldOrder(order);
                                },
                                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                label: const Text('Resume (ခေါ်ယူမည်)', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  backgroundColor: AppColors.primary,
                                ),
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
      ),
    );
  }

  // Today's Sales Vouchers Dialog in POS View
  void _showRecentVouchersDialog(BuildContext context, POSController posController) {
    posController.loadTodayVouchers();
    final screenWidth = MediaQuery.of(context).size.width;

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          width: screenWidth < 660 ? screenWidth * 0.94 : 620,
          padding: EdgeInsets.all(screenWidth < 500 ? 14 : 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Colors.tealAccent, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => Text(
                            "Today's Vouchers (${posController.todayVouchers.length})",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          )),
                          Obx(() {
                            final total = posController.todayVouchers.fold(0.0, (sum, v) => sum + v.grandTotal);
                            return Text(
                              'Total Revenue: ${Formatters.formatCurrency(total)}',
                              style: const TextStyle(fontSize: 12, color: Colors.tealAccent, fontWeight: FontWeight.w600),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),

              // Vouchers List
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 450),
                child: Obx(() {
                  if (posController.isLoadingVouchers.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (posController.todayVouchers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text('No sales vouchers recorded today', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Complete a sale in POS to see vouchers here.', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: posController.todayVouchers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = posController.todayVouchers[index];
                      final timeStr = order.saleDate.length >= 16 ? order.saleDate.substring(11, 16) : '';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.receipt_rounded, size: 18, color: AppColors.primaryLight),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        order.voucherNo,
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      if (timeStr.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                      const SizedBox(width: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: (order.saleStatus == 'PAID' ? Colors.green : Colors.amber).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          order.saleStatus,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: order.saleStatus == 'PAID' ? Colors.greenAccent : Colors.amber,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.customerName != null && order.customerName!.isNotEmpty
                                        ? '${order.customerName} • ${order.paymentMethod.toUpperCase()}'
                                        : 'Walk-in Customer • ${order.paymentMethod.toUpperCase()}',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.formatCurrency(order.grandTotal),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                                if (order.dueAmount > 0)
                                  Text(
                                    'Due: ${Formatters.formatCurrency(order.dueAmount)}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.error),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.print_rounded, size: 18, color: AppColors.primaryLight),
                              tooltip: 'Reprint / Preview Receipt',
                              onPressed: () => Get.dialog(ReceiptDialog(order: order)),
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

  // Clear Cart Confirmation Dialog
  void _showClearCartConfirmDialog(BuildContext context, POSController posController) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Row(
          children: const [
            Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 8),
            Text('Clear Cart Items (အကုန်ရှင်းမည်)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove all items and reset the current order?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          SizedBox(
            width: 100,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                posController.clearCart();
                Get.back();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Clear All'),
            ),
          ),
        ],
      ),
    );
  }

  // Interactive Payment & Flexible Settlement Modal
  void _showPaymentDialog(BuildContext context, POSController posController) async {
    final deliveryDao = DeliveryServiceDao();
    final deliveryServices = await deliveryDao.getActiveDeliveryServices();
    final isCustomerSelected = posController.selectedCustomer.value != null;
    final selectedCustomer = posController.selectedCustomer.value;

    // Fulfillment State
    posController.deliveryFee.value = 0.0;
    String fulfillmentType = 'SELF_COLLECT'; // 'SELF_COLLECT' or 'DELIVERY'
    DeliveryServiceModel? selectedDeliveryService = deliveryServices.isNotEmpty ? deliveryServices.first : null;
    final addressCtrl = TextEditingController(text: selectedCustomer?.address ?? '');
    final inHouseDeliveryFeeCtrl = TextEditingController(text: '0');
    final trackingCtrl = TextEditingController();
    bool isCod = false;
    final codAmountCtrl = TextEditingController();

    // Payment Mode: 'full', 'partial', 'credit'
    String paymentMode = posController.selectedPaymentMethod.value == 'credit'
        ? (isCustomerSelected ? 'credit' : 'full')
        : 'full';
    String selectedMethod = posController.selectedPaymentMethod.value == 'credit' ? 'cash' : posController.selectedPaymentMethod.value;
    final paidCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final grandTotal = posController.grandTotal;
            if (paidCtrl.text.isEmpty && !isCod && paymentMode != 'credit') {
              paidCtrl.text = grandTotal.toStringAsFixed(0);
            }
            if (codAmountCtrl.text.isEmpty && isCod) {
              codAmountCtrl.text = grandTotal.toStringAsFixed(0);
            }

            final tendered = double.tryParse(paidCtrl.text.trim()) ?? 0.0;
            final isCredit = paymentMode == 'credit';
            final isPartial = paymentMode == 'partial';
            final isFull = paymentMode == 'full';

            double actualPaid = isCredit || isCod ? 0.0 : (isFull ? grandTotal : tendered);
            double dueAmount = actualPaid < grandTotal ? (grandTotal - actualPaid) : 0.0;
            double changeAmount = actualPaid > grandTotal ? (actualPaid - grandTotal) : 0.0;
            final codToCollect = double.tryParse(codAmountCtrl.text.trim()) ?? grandTotal;

            // Walk-in customer validation: if not COD and not credit, must pay >= grandTotal
            final bool isWalkInInvalid = !isCustomerSelected && !isCod && (actualPaid < grandTotal);

            final screenWidth = MediaQuery.of(context).size.width;
            return Container(
              constraints: const BoxConstraints(maxWidth: 520),
              width: screenWidth < 560 ? screenWidth * 0.94 : 520,
              padding: EdgeInsets.all(screenWidth < 500 ? 14 : 22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.payments_rounded, color: AppColors.primaryLight, size: 22),
                            SizedBox(width: 8),
                            Text('Payment & Settlement', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                          onPressed: () => Get.back(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Grand Total Display Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total Payable:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            Formatters.formatCurrency(grandTotal),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Customer Status Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCustomerSelected ? AppColors.primary.withOpacity(0.08) : Colors.amber.shade900.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCustomerSelected ? AppColors.primary.withOpacity(0.3) : Colors.amber.shade600,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCustomerSelected ? Icons.person_rounded : Icons.person_off_outlined,
                            size: 18,
                            color: isCustomerSelected ? AppColors.primaryLight : Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: isCustomerSelected
                                ? Text(
                                    'Customer: ${selectedCustomer!.name} ${selectedCustomer.phone != null ? "(${selectedCustomer.phone})" : ""}',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  )
                                : const Text(
                                    'Walk-in Customer',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 1. Fulfillment Type Selection (Self-Collected vs Delivery Service)
                    const Text('Fulfillment & Delivery Method (ပို့ဆောင်ရေး):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            avatar: Icon(Icons.storefront_rounded,
                                size: 16,
                                color: fulfillmentType == 'SELF_COLLECT' ? Colors.white : AppColors.textSecondary),
                            label: const Text('Self-Collected (ဆိုင်လာယူ)', style: TextStyle(fontSize: 11.5)),
                            selected: fulfillmentType == 'SELF_COLLECT',
                            selectedColor: AppColors.primary,
                            onSelected: (_) {
                              setState(() {
                                fulfillmentType = 'SELF_COLLECT';
                                isCod = false;
                                posController.deliveryFee.value = 0.0;
                                inHouseDeliveryFeeCtrl.text = '0';
                                paidCtrl.text = posController.grandTotal.toStringAsFixed(0);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            avatar: Icon(Icons.local_shipping_rounded,
                                size: 16,
                                color: fulfillmentType == 'DELIVERY' ? Colors.white : AppColors.textSecondary),
                            label: const Text('Delivery Service (ပို့ဆောင်ရေး)', style: TextStyle(fontSize: 11.5)),
                            selected: fulfillmentType == 'DELIVERY',
                            selectedColor: AppColors.primary,
                            onSelected: (_) {
                              setState(() {
                                fulfillmentType = 'DELIVERY';
                                if (selectedDeliveryService?.isInHouse == true) {
                                  posController.deliveryFee.value = selectedDeliveryService!.defaultDeliveryFee;
                                  inHouseDeliveryFeeCtrl.text = selectedDeliveryService!.defaultDeliveryFee.toStringAsFixed(0);
                                } else {
                                  posController.deliveryFee.value = 0.0;
                                  inHouseDeliveryFeeCtrl.text = '0';
                                }
                                paidCtrl.text = posController.grandTotal.toStringAsFixed(0);
                                codAmountCtrl.text = posController.grandTotal.toStringAsFixed(0);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // If Delivery Service chosen, show Delivery Configuration Section
                    if (fulfillmentType == 'DELIVERY') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Courier Dropdown
                            DropdownButtonFormField<String>(
                              value: selectedDeliveryService?.id,
                              decoration: const InputDecoration(
                                labelText: 'Select Delivery Courier / Rider *',
                                prefixIcon: Icon(Icons.delivery_dining_rounded, size: 18, color: AppColors.primaryLight),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: deliveryServices.map((ds) {
                                return DropdownMenuItem(
                                  value: ds.id,
                                  child: Row(
                                    children: [
                                      Text(
                                        ds.name,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: (ds.isInHouse ? Colors.teal : Colors.blue).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          ds.isInHouse ? 'In-House' : 'External',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: ds.isInHouse ? Colors.tealAccent : Colors.blue.shade300,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (id) {
                                if (id == null) return;
                                final matched = deliveryServices.firstWhereOrNull((s) => s.id == id);
                                if (matched != null) {
                                  setState(() {
                                    selectedDeliveryService = matched;
                                    if (matched.isInHouse) {
                                      posController.deliveryFee.value = matched.defaultDeliveryFee;
                                      inHouseDeliveryFeeCtrl.text = matched.defaultDeliveryFee.toStringAsFixed(0);
                                    } else {
                                      posController.deliveryFee.value = 0.0;
                                      inHouseDeliveryFeeCtrl.text = '0';
                                    }
                                    paidCtrl.text = posController.grandTotal.toStringAsFixed(0);
                                    codAmountCtrl.text = posController.grandTotal.toStringAsFixed(0);
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 10),

                            // In-House Delivery Price / Fee Input (Only for In-House Delivery Services)
                            if (selectedDeliveryService?.isInHouse == true) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade900.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.teal.shade700.withOpacity(0.4)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.storefront_rounded, size: 15, color: Colors.tealAccent),
                                            SizedBox(width: 5),
                                            Text('In-House Delivery Income (ဆိုင်တွင်းပို့ခဝင်ငွေ)',
                                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                                          ],
                                        ),
                                        if (selectedDeliveryService!.isCommissionBased)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade800.withOpacity(0.4),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Commission: ${selectedDeliveryService!.commissionVal.toStringAsFixed(0)}${selectedDeliveryService!.commissionType == 'PERCENT' ? '%' : ' Ks'}',
                                              style: const TextStyle(fontSize: 10, color: Colors.tealAccent),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: inHouseDeliveryFeeCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Delivery Price to Charge Customer (Ks) *',
                                        prefixIcon: Icon(Icons.attach_money_rounded, size: 16),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (val) {
                                        final fee = double.tryParse(val.trim()) ?? 0.0;
                                        posController.deliveryFee.value = fee;
                                        setState(() {
                                          paidCtrl.text = posController.grandTotal.toStringAsFixed(0);
                                          if (isCod) codAmountCtrl.text = posController.grandTotal.toStringAsFixed(0);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),

                            // Address & Phone
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: addressCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Delivery Address',
                                      hintText: 'Street / Township',
                                      prefixIcon: Icon(Icons.location_on_outlined, size: 16),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: trackingCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Tracking / Waybill #',
                                      hintText: 'e.g. RY-99881',
                                      prefixIcon: Icon(Icons.qr_code_rounded, size: 16),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Cash On Delivery (COD) Switch & Amount
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isCod ? Colors.amber.shade900.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCod ? Colors.amber.shade600 : AppColors.border,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.handshake_outlined,
                                            size: 18,
                                            color: isCod ? Colors.amber : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Cash on Delivery (COD / ပစ္စည်းရောက်ငွေချေ)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isCod ? Colors.amber : AppColors.textPrimary,
                                                ),
                                              ),
                                              const Text(
                                                'Courier collects cash upon drop-off and remits later',
                                                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Switch(
                                        value: isCod,
                                        activeColor: Colors.amber,
                                        onChanged: (val) {
                                          setState(() {
                                            isCod = val;
                                            if (isCod) {
                                              paidCtrl.text = '0';
                                              codAmountCtrl.text = grandTotal.toStringAsFixed(0);
                                            } else {
                                              paidCtrl.text = grandTotal.toStringAsFixed(0);
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (isCod) ...[
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: codAmountCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        labelText: 'COD Amount to Collect by Courier (ကောက်ခံမည့်ငွေ) *',
                                        prefixIcon: const Icon(Icons.attach_money_rounded, size: 18, color: Colors.amber),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        suffixIcon: TextButton(
                                          onPressed: () {
                                            setState(() {
                                              codAmountCtrl.text = grandTotal.toStringAsFixed(0);
                                            });
                                          },
                                          child: const Text('Full Total', style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 2. Settlement Mode Selection (Hidden if COD)
                    if (!isCod) ...[
                      if (isCustomerSelected) ...[
                        const Text('Payment Settlement Type:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Full Payment', style: TextStyle(fontSize: 11.5))),
                                selected: paymentMode == 'full',
                                onSelected: (_) {
                                  setState(() {
                                    paymentMode = 'full';
                                    paidCtrl.text = grandTotal.toStringAsFixed(0);
                                  });
                                },
                                selectedColor: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Partial Pay', style: TextStyle(fontSize: 11.5))),
                                selected: paymentMode == 'partial',
                                onSelected: (_) {
                                  setState(() {
                                    paymentMode = 'partial';
                                    paidCtrl.text = (grandTotal * 0.5).toStringAsFixed(0);
                                  });
                                },
                                selectedColor: Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Full Credit', style: TextStyle(fontSize: 11.5))),
                                selected: paymentMode == 'credit',
                                onSelected: (_) {
                                  setState(() {
                                    paymentMode = 'credit';
                                    paidCtrl.text = '0';
                                  });
                                },
                                selectedColor: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Paid Amount Field (for Full, Partial or Walk-in cash input)
                      if (!isCredit) ...[
                        TextField(
                          controller: paidCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: isPartial ? 'Paid Amount (ပေးငွေ) *' : 'Tendered Cash / Paid Amount',
                            prefixIcon: const Icon(Icons.attach_money_rounded, size: 18, color: AppColors.primaryLight),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Calculation Summary (Due Debt or Change)
                      if (dueAmount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Unpaid Due (Customer Debt):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
                              Text(
                                Formatters.formatCurrency(dueAmount),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error),
                              ),
                            ],
                          ),
                        ),

                      if (changeAmount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Change Return (ပြန်အမ်းငွေ):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                              Text(
                                Formatters.formatCurrency(changeAmount),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ),

                      if (isWalkInInvalid)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '⚠️ Walk-in customers cannot make partial or credit payment. Please enter at least ${Formatters.formatCurrency(grandTotal)} or select a customer.',
                            style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Payment Method Chips (for non-credit)
                      if (!isCredit) ...[
                        const Text('Payment Channel:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Cash', style: TextStyle(fontSize: 11))),
                                selected: selectedMethod == 'cash',
                                onSelected: (_) => setState(() => selectedMethod = 'cash'),
                                selectedColor: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('KPay', style: TextStyle(fontSize: 11))),
                                selected: selectedMethod == 'kpay',
                                onSelected: (_) => setState(() => selectedMethod = 'kpay'),
                                selectedColor: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('WavePay', style: TextStyle(fontSize: 11))),
                                selected: selectedMethod == 'wave',
                                onSelected: (_) => setState(() => selectedMethod = 'wave'),
                                selectedColor: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Bank', style: TextStyle(fontSize: 11))),
                                selected: selectedMethod == 'bank',
                                onSelected: (_) => setState(() => selectedMethod = 'bank'),
                                selectedColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],

                    // Notes
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Voucher Note / Remark (optional)',
                        prefixIcon: Icon(Icons.comment_outlined, size: 18, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Action Button
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: isWalkInInvalid
                              ? null
                              : () async {
                                  posController.selectedPaymentMethod.value = isCod
                                      ? 'cod'
                                      : (isCredit ? 'credit' : selectedMethod);
                                  Get.back(); // close payment dialog
                                  final riderCommission = (fulfillmentType == 'DELIVERY' && selectedDeliveryService != null)
                                      ? selectedDeliveryService!.calculateCommission(posController.deliveryFee.value)
                                      : 0.0;
                                  final order = await posController.checkout(
                                    paidAmount: isCod ? 0.0 : actualPaid,
                                    notes: notesCtrl.text.trim(),
                                    deliveryType: fulfillmentType,
                                    deliveryServiceId: fulfillmentType == 'DELIVERY' ? selectedDeliveryService?.id : null,
                                    deliveryServiceName: fulfillmentType == 'DELIVERY' ? selectedDeliveryService?.name : null,
                                    deliveryAddress: fulfillmentType == 'DELIVERY' ? addressCtrl.text.trim() : null,
                                    trackingNo: fulfillmentType == 'DELIVERY' ? trackingCtrl.text.trim() : null,
                                    isCod: isCod,
                                    codAmount: isCod ? codToCollect : 0.0,
                                    riderCommissionAmount: riderCommission,
                                  );
                                  if (order != null) {
                                    Get.dialog(ReceiptDialog(order: order));
                                  }
                                },
                          icon: Icon(
                            isCod ? Icons.local_shipping_rounded : Icons.check_circle_rounded,
                            size: 20,
                          ),
                          label: Text(
                            isCod
                                ? 'Record COD Delivery (${Formatters.formatCurrency(codToCollect)})'
                                : (isCredit
                                    ? 'Record Credit Sale (${Formatters.formatCurrency(grandTotal)})'
                                    : 'Complete Sale & Print Receipt'),
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            backgroundColor: isCod
                                ? Colors.amber.shade800
                                : (isCredit ? AppColors.error : AppColors.primary),
                          ),
                        ),
                      ),
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

  // Checkout Action Handler
  void _handleCheckout(BuildContext context, POSController posController) {
    if (posController.cart.isEmpty) {
      Get.snackbar('Warning', 'Cart is empty');
      return;
    }
    _showPaymentDialog(context, posController);
  }

  // Large Photo & Fabric Preview Dialog
  void _showLargePhotoDialog(BuildContext context, ProductModel product, POSController posController) {
    final screenWidth = MediaQuery.of(context).size.width;
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          width: screenWidth < 460 ? screenWidth * 0.94 : 440,
          padding: EdgeInsets.all(screenWidth < 460 ? 14 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Title and Close button
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
              const SizedBox(height: 12),

              // Multi-Image Gallery with Retail and Wholesale Prices
              MultiImageGalleryView(
                images: product.imageList,
                retailPrice: product.retailPrice,
                wholesalePrice: product.wholesalePrice,
                minWholesaleQty: product.minWholesaleQty,
                unit: product.unit,
              ),
              const SizedBox(height: 16),

              // Product Details Grid (Fabric, Size, Color, ဝမ်းဆက်)
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
                        Text('Fabric: ${product.fabricType ?? "N/A"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Size: ${product.size ?? "Free"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Color: ${product.color ?? "N/A"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock: ${Formatters.formatQty(product.stockQty, unit: product.unit)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: product.stockQty <= product.minStockAlert ? AppColors.error : AppColors.success,
                          ),
                        ),
                        if (product.isOneSet == 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.secondary, width: 0.8),
                            ),
                            child: const Text('ဝမ်းဆက် (One Set)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Price & Add to Cart Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Retail Price', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text(
                        Formatters.formatCurrency(product.retailPrice),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                          ItemPriceHistoryDialog.show(
                            context,
                            product: product,
                            initialCustomerId: posController.selectedCustomer.value?.id,
                          );
                        },
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: const Text('History', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            posController.addToCart(product, qty: 1.0);
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                          label: const Text('Add to Cart'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Visual Image Search Source Selector Modal
  void _showVisualSearchOptions(BuildContext context, POSController posController) {
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
                        posController.searchByImage(isCamera: false);
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
                          posController.searchByImage(isCamera: true);
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

  // Edit / Override Unit Price for Cart Item Dialog
  void _showEditItemPriceDialog(BuildContext context, int index, CartItem item, POSController posController) {
    final controller = TextEditingController(text: item.price.toStringAsFixed(0));
    Get.defaultDialog(
      title: 'Change Price (${item.product.name})',
      titleStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      backgroundColor: AppColors.cardBg,
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Retail: ${Formatters.formatCurrency(item.product.retailPrice)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                if (item.product.wholesalePrice > 0)
                  Text('Wholesale: ${Formatters.formatCurrency(item.product.wholesalePrice)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Unit Price (Ks)',
                prefixText: 'Ks ',
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                ItemPriceHistoryDialog.show(
                  context,
                  product: item.product,
                  initialCustomerId: posController.selectedCustomer.value?.id,
                  onPriceSelected: (selectedPrice) {
                    controller.text = selectedPrice.toStringAsFixed(0);
                  },
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.history_rounded, size: 14, color: AppColors.primaryLight),
                    SizedBox(width: 4),
                    Text(
                      'Check Past Price History (ဈေးနှုန်းမှတ်တမ်း)',
                      style: TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            if (item.isPriceOverridden) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  item.isPriceOverridden = false;
                  item.price = item.product.getEffectivePrice(item.quantity);
                  posController.cart.refresh();
                  Get.back();
                },
                icon: const Icon(Icons.restore_rounded, size: 14, color: AppColors.textMuted),
                label: const Text('Reset to Standard Price', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ),
            ],
          ],
        ),
      ),
      textConfirm: 'Update Price',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () {
        final val = double.tryParse(controller.text.trim()) ?? item.price;
        posController.updateUnitPrice(index, val);
        Get.back();
      },
    );
  }
}
