import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../Controller/AppController.dart';
import '../../../data/local/purchase_dao.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/purchase_model.dart';
import '../../../data/models/supplier_model.dart';
import '../../../utils/app_colors.dart';
import '../../pos/controllers/pos_controller.dart';
import '../../products/controllers/product_controller.dart';
import '../../suppliers/controllers/supplier_controller.dart';
import '../../../data/local/customer_order_dao.dart';

class PurchaseCartItem {
  final ProductModel product;
  double costPrice;
  double quantity;

  PurchaseCartItem({
    required this.product,
    required this.costPrice,
    this.quantity = 1.0,
  });

  double get subtotal => costPrice * quantity;
}

class PurchaseController extends GetxController {
  final PurchaseDao purchaseDao = PurchaseDao();
  final CustomerOrderDao customerOrderDao = CustomerOrderDao();
  final AppController appController = Get.find<AppController>();

  final RxList<PurchaseModel> purchases = <PurchaseModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rx<String?> filterSupplierId = Rx<String?>(null);
  final RxString selectedStatusFilter = 'ALL'.obs; // 'ALL', 'ORDERED', 'OVERDUE', 'PARTIALLY_RECEIVED', 'RECEIVED'

  // New Purchase / PO Creation Cart
  final RxList<PurchaseCartItem> cart = <PurchaseCartItem>[].obs;
  final Rx<SupplierModel?> selectedSupplier = Rx<SupplierModel?>(null);
  final RxDouble paidAmount = 0.0.obs;
  final RxString paymentMethod = 'cash'.obs;
  final RxString notes = ''.obs;
  final RxBool isDirectStockIn = true.obs;
  final Rx<String?> expectedDeliveryDate = Rx<String?>(null);
  final RxMap<String, List<Map<String, dynamic>>> pendingCustomerOrdersMap = <String, List<Map<String, dynamic>>>{}.obs;

  double get subtotal => cart.fold(0.0, (sum, item) => sum + item.subtotal);
  double get dueAmount => paidAmount.value < subtotal ? (subtotal - paidAmount.value) : 0.0;

  @override
  void onInit() {
    super.onInit();
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    isLoading.value = true;
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final isOverdue = selectedStatusFilter.value == 'OVERDUE';
      final statusParam = (selectedStatusFilter.value == 'ALL' || isOverdue)
          ? null
          : selectedStatusFilter.value;

      final list = await purchaseDao.getPurchases(
        query: searchQuery.value,
        supplierId: filterSupplierId.value,
        status: statusParam,
        isOverdueOnly: isOverdue,
        businessId: bizId,
      );
      purchases.assignAll(list);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshCustomerDemandForCart() async {
    final ids = cart.map((i) => i.product.id).toSet().toList();
    if (ids.isEmpty) {
      pendingCustomerOrdersMap.clear();
      return;
    }
    final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
    final map = await customerOrderDao.getPendingCustomerOrdersForProducts(ids, businessId: bizId);
    pendingCustomerOrdersMap.assignAll(map);
  }

  void addToCart(ProductModel product, {double qty = 1.0, double? customCostPrice}) {
    final idx = cart.indexWhere((item) => item.product.id == product.id);
    final cost = customCostPrice ?? product.costPrice;

    if (idx != -1) {
      cart[idx].quantity += qty;
      cart.refresh();
    } else {
      cart.add(PurchaseCartItem(
        product: product,
        costPrice: cost > 0 ? cost : product.retailPrice * 0.7,
        quantity: qty,
      ));
    }
    refreshCustomerDemandForCart();
  }

  void updateItemQty(int index, double qty) {
    if (index >= 0 && index < cart.length) {
      if (qty <= 0) {
        cart.removeAt(index);
      } else {
        cart[index].quantity = qty;
        cart.refresh();
      }
      refreshCustomerDemandForCart();
    }
  }

  void updateItemCost(int index, double cost) {
    if (index >= 0 && index < cart.length) {
      cart[index].costPrice = cost;
      cart.refresh();
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < cart.length) {
      cart.removeAt(index);
      refreshCustomerDemandForCart();
    }
  }

  void clearCart() {
    cart.clear();
    selectedSupplier.value = null;
    paidAmount.value = 0.0;
    notes.value = '';
    isDirectStockIn.value = true;
    expectedDeliveryDate.value = null;
    pendingCustomerOrdersMap.clear();
  }

  // Save Purchase (either as Direct Stock In 'RECEIVED' or Supplier Order 'ORDERED')
  Future<PurchaseModel?> savePurchaseOrder({
    bool? directStockIn,
    String? expectedDate,
  }) async {
    if (cart.isEmpty) {
      Get.snackbar('Empty Cart', 'Please add at least one product to purchase', backgroundColor: Colors.amber.shade800, colorText: Colors.white);
      return null;
    }

    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final user = appController.currentUser.value;
      final purchaseId = const Uuid().v4();
      final isDirect = directStockIn ?? isDirectStockIn.value;
      final invoicePrefix = isDirect ? 'PUR' : 'PO';
      final invoiceNo = '$invoicePrefix-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      final total = subtotal;
      final paid = paidAmount.value;
      final due = total > paid ? (total - paid) : 0.0;
      final status = isDirect ? 'RECEIVED' : 'ORDERED';

      final List<PurchaseItemModel> items = [];
      for (var c in cart) {
        items.add(PurchaseItemModel(
          id: const Uuid().v4(),
          purchaseId: purchaseId,
          productId: c.product.id,
          productName: c.product.name,
          unit: c.product.unit,
          costPrice: c.costPrice,
          quantity: isDirect ? c.quantity : 0.0,
          orderedQuantity: c.quantity,
          receivedQuantity: isDirect ? c.quantity : 0.0,
          rejectedQuantity: 0.0,
          subtotal: c.subtotal,
          status: status,
          syncStatus: 0,
        ));
      }

      final purchase = PurchaseModel(
        id: purchaseId,
        businessId: bizId,
        invoiceNo: invoiceNo,
        supplierId: selectedSupplier.value?.id,
        supplierName: selectedSupplier.value?.name ?? 'General Supplier',
        userId: user?.id,
        totalAmount: total,
        paidAmount: paid,
        dueAmount: due,
        paymentMethod: paymentMethod.value,
        status: status,
        expectedDeliveryDate: isDirect ? null : (expectedDate ?? expectedDeliveryDate.value),
        notes: notes.value.isNotEmpty ? notes.value : null,
        purchaseDate: DateTime.now().toIso8601String(),
        syncStatus: 0,
        items: items,
      );

      await purchaseDao.savePurchaseOrder(purchase);

      if (isDirect) {
        // Refresh product lists & POS stock counts
        if (Get.isRegistered<ProductController>()) {
          Get.find<ProductController>().loadProducts();
        }
        if (Get.isRegistered<POSController>()) {
          Get.find<POSController>().loadProducts();
        }
      }
      if (Get.isRegistered<SupplierController>()) {
        Get.find<SupplierController>().loadSuppliers();
      }

      await loadPurchases();
      clearCart();

      // Trigger automatic sync with MySQL
      appController.triggerAutoSync();

      Get.snackbar(
        isDirect ? 'Stock In Complete' : 'Supplier Order Placed',
        isDirect
            ? 'Purchase ${purchase.invoiceNo} saved & stock quantities updated!'
            : 'Order ${purchase.invoiceNo} saved. Stock will be updated when goods arrive.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return purchase;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save purchase: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // Receive Goods against an existing Supplier Order
  Future<bool> receiveStock({
    required String purchaseId,
    required List<Map<String, dynamic>> itemsReceived,
    bool cancelRemaining = false,
    double additionalPaid = 0.0,
    String? paymentMethod,
    String? receivingNotes,
  }) async {
    try {
      await purchaseDao.receivePurchaseItems(
        purchaseId: purchaseId,
        itemsReceived: itemsReceived,
        cancelRemaining: cancelRemaining,
        additionalPaid: additionalPaid,
        paymentMethod: paymentMethod,
        receivingNotes: receivingNotes,
      );

      // Refresh products & POS stock counts
      if (Get.isRegistered<ProductController>()) {
        Get.find<ProductController>().loadProducts();
      }
      if (Get.isRegistered<POSController>()) {
        Get.find<POSController>().loadProducts();
      }
      if (Get.isRegistered<SupplierController>()) {
        Get.find<SupplierController>().loadSuppliers();
      }

      await loadPurchases();
      appController.triggerAutoSync();

      Get.snackbar(
        'Goods Received',
        'Inventory stock has been updated for received items.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to receive goods: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  // Log Follow-up Call or Message
  Future<bool> logFollowUp({
    required String purchaseId,
    required String notes,
    String? nextExpectedDeliveryDate,
  }) async {
    try {
      await purchaseDao.updateFollowUp(
        purchaseId,
        notes,
        nextExpectedDeliveryDate: nextExpectedDeliveryDate,
      );
      await loadPurchases();
      Get.snackbar(
        'Follow-up Logged',
        'Supplier check-in note successfully recorded.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to log follow-up: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  // Cancel Supplier Order
  Future<bool> cancelOrder(String purchaseId, {String? reason}) async {
    try {
      await purchaseDao.cancelPurchaseOrder(purchaseId, cancelReason: reason);
      await loadPurchases();
      Get.snackbar('Order Cancelled', 'Supplier order marked as cancelled.', backgroundColor: Colors.grey.shade800, colorText: Colors.white);
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel order: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  // Delete Purchase Order or Stock-In
  Future<bool> deletePurchaseOrder(PurchaseModel purchase) async {
    try {
      await purchaseDao.deletePurchaseOrder(purchase.id);

      // Refresh product lists & POS stock counts
      if (Get.isRegistered<ProductController>()) {
        Get.find<ProductController>().loadProducts();
      }
      if (Get.isRegistered<POSController>()) {
        Get.find<POSController>().loadProducts();
      }
      if (Get.isRegistered<SupplierController>()) {
        Get.find<SupplierController>().loadSuppliers();
      }

      await loadPurchases();
      appController.triggerAutoSync();

      Get.snackbar(
        'delete_purchase_order'.tr,
        'order_deleted_successfully'.tr,
        backgroundColor: Colors.grey.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete order: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Update Purchase Order or Stock-In
  Future<bool> updatePurchaseOrder({
    required PurchaseModel updatedPurchase,
    required List<PurchaseItemModel> updatedItems,
  }) async {
    try {
      await purchaseDao.updatePurchaseOrder(
        updatedPurchase: updatedPurchase,
        updatedItems: updatedItems,
      );

      // Refresh product lists & POS stock counts
      if (Get.isRegistered<ProductController>()) {
        Get.find<ProductController>().loadProducts();
      }
      if (Get.isRegistered<POSController>()) {
        Get.find<POSController>().loadProducts();
      }
      if (Get.isRegistered<SupplierController>()) {
        Get.find<SupplierController>().loadSuppliers();
      }

      await loadPurchases();
      appController.triggerAutoSync();

      Get.snackbar(
        'edit_purchase_order'.tr,
        'order_updated_successfully'.tr,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update order: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }
}

