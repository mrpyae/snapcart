import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/local/customer_dao.dart';
import '../../../data/local/held_order_dao.dart';
import '../../../data/local/product_dao.dart';
import '../../../data/local/sale_dao.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/held_order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/sale_order_model.dart';
import '../../../data/models/item_price_history_model.dart';
import '../../../Controller/AppController.dart';
import '../../../utils/image_picker_helper.dart';
import '../../../utils/image_similarity_service.dart';

class CartItem {
  final ProductModel product;
  double quantity;
  double price;
  double discount;
  bool isPriceOverridden;

  CartItem({
    required this.product,
    this.quantity = 1.0,
    required this.price,
    this.discount = 0.0,
    this.isPriceOverridden = false,
  });

  double get total => (quantity * price) - discount;
}

class POSController extends GetxController {
  final ProductDao productDao = ProductDao();
  final CustomerDao customerDao = CustomerDao();
  final SaleDao saleDao = SaleDao();
  final HeldOrderDao heldOrderDao = HeldOrderDao();
  AppController? get appController => Get.isRegistered<AppController>() ? Get.find<AppController>() : null;

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<CartItem> cart = <CartItem>[].obs;
  final RxList<CustomerModel> customers = <CustomerModel>[].obs;
  final Rx<CustomerModel?> selectedCustomer = Rx<CustomerModel?>(null);
  final RxList<HeldOrderModel> heldOrders = <HeldOrderModel>[].obs;

  final RxDouble voucherDiscount = 0.0.obs;
  final RxDouble deliveryFee = 0.0.obs;
  final RxDouble taxRate = 0.0.obs;
  final RxString selectedPaymentMethod = 'cash'.obs;

  final RxString searchQuery = ''.obs;
  final Rx<String?> selectedCategoryId = Rx<String?>(null);
  final Rx<String?> visualSearchImage = Rx<String?>(null);
  final RxMap<String, int> visualMatchScores = <String, int>{}.obs;
  final RxList<SaleOrderModel> todayVouchers = <SaleOrderModel>[].obs;
  final RxBool isLoadingVouchers = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadCustomers();
    loadHeldOrders();
    loadTodayVouchers();
  }

  Future<void> loadTodayVouchers() async {
    isLoadingVouchers.value = true;
    try {
      final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
      final now = DateTime.now();
      final list = await saleDao.getFilteredSales(
        startDate: DateTime(now.year, now.month, now.day),
        endDate: now,
        businessId: bizId,
      );
      todayVouchers.assignAll(list);
    } catch (_) {
    } finally {
      isLoadingVouchers.value = false;
    }
  }

  Future<void> loadHeldOrders() async {
    final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
    final list = await heldOrderDao.getHeldOrders(businessId: bizId);
    heldOrders.assignAll(list);
  }

  // Hold current order so cashier can serve new customer
  Future<bool> holdCurrentOrder({String? notes}) async {
    if (cart.isEmpty) {
      Get.snackbar('Cart Empty', 'Cannot hold an empty cart');
      return false;
    }

    final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
    final heldOrder = HeldOrderModel(
      id: const Uuid().v4(),
      businessId: bizId,
      customerId: selectedCustomer.value?.id,
      customerName: selectedCustomer.value?.name,
      customerPhone: selectedCustomer.value?.phone,
      items: cart
          .map((c) => HeldOrderItemModel(
                productId: c.product.id,
                productName: c.product.name,
                unit: c.product.unit,
                quantity: c.quantity,
                price: c.price,
                isPriceOverridden: c.isPriceOverridden,
              ))
          .toList(),
      subtotal: subtotal,
      discount: voucherDiscount.value,
      taxRate: taxRate.value,
      deliveryFee: deliveryFee.value,
      grandTotal: grandTotal,
      notes: notes,
      createdAt: DateTime.now().toIso8601String(),
    );

    await heldOrderDao.saveHeldOrder(heldOrder);
    clearCart();
    await loadHeldOrders();

    Get.snackbar(
      'Order Held',
      'Current order saved to Held Orders. Ready for next customer.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return true;
  }

  // Resume / Restore a held order into the current cart
  Future<void> resumeHeldOrder(HeldOrderModel heldOrder) async {
    cart.clear();

    for (var item in heldOrder.items) {
      // Find matching product in products list or create minimal product
      final existingIndex = products.indexWhere((p) => p.id == item.productId);
      final product = existingIndex >= 0
          ? products[existingIndex]
          : ProductModel(
              id: item.productId,
              name: item.productName,
              unit: item.unit,
              retailPrice: item.price,
            );

      cart.add(CartItem(
        product: product,
        quantity: item.quantity,
        price: item.price,
        isPriceOverridden: item.isPriceOverridden,
      ));
    }

    voucherDiscount.value = heldOrder.discount;
    taxRate.value = heldOrder.taxRate;
    deliveryFee.value = heldOrder.deliveryFee;

    // Restore selected customer if any
    if (heldOrder.customerId != null) {
      final custIndex = customers.indexWhere((c) => c.id == heldOrder.customerId);
      if (custIndex >= 0) {
        selectedCustomer.value = customers[custIndex];
      } else {
        selectedCustomer.value = CustomerModel(
          id: heldOrder.customerId!,
          name: heldOrder.customerName ?? 'Customer',
          phone: heldOrder.customerPhone,
        );
      }
    } else {
      selectedCustomer.value = null;
    }

    // Remove from held orders
    await heldOrderDao.deleteHeldOrder(heldOrder.id);
    await loadHeldOrders();
    cart.refresh();

    Get.snackbar('Order Resumed', 'Restored held order into cart');
  }

  // Delete a held order
  Future<void> deleteHeldOrder(String id) async {
    await heldOrderDao.deleteHeldOrder(id);
    await loadHeldOrders();
  }

  // Clear all items in cart
  void clearCart() {
    cart.clear();
    voucherDiscount.value = 0.0;
    deliveryFee.value = 0.0;
    selectedCustomer.value = null;
  }

  Future<void> searchByImage({bool isCamera = false}) async {
    final img = await pickImageCrossPlatform(isCamera: isCamera);
    if (img != null && img.isNotEmpty) {
      visualSearchImage.value = img;
      await loadProducts();
    }
  }

  void clearVisualSearch() {
    visualSearchImage.value = null;
    visualMatchScores.clear();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final list = await productDao.searchProducts(
      query: searchQuery.value,
      categoryId: selectedCategoryId.value,
    );

    if (visualSearchImage.value != null && visualSearchImage.value!.isNotEmpty) {
      final ranked = ImageSimilarityService.instance.rankProducts(
        visualSearchImage.value!,
        list,
        minThreshold: 0.35,
      );
      visualMatchScores.clear();
      final List<ProductModel> sorted = [];
      for (final r in ranked) {
        visualMatchScores[r.product.id] = r.percentage;
        sorted.add(r.product);
      }
      products.assignAll(sorted);
    } else {
      visualMatchScores.clear();
      products.assignAll(list);
    }
  }

  Future<void> loadCustomers() async {
    final list = await customerDao.getCustomers();
    customers.assignAll(list);
  }

  Future<CustomerModel> createAndSelectCustomer({
    required String name,
    String? phone,
    String? address,
    double creditLimit = 0.0,
    double advanceBalance = 0.0,
  }) async {
    final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
    final customer = CustomerModel(
      id: const Uuid().v4(),
      businessId: bizId,
      name: name,
      phone: phone,
      address: address,
      customerType: 'retail',
      creditLimit: creditLimit,
      currentDebt: 0.0,
      advanceBalance: advanceBalance,
      syncStatus: 0,
    );

    await customerDao.insertOrUpdateCustomer(customer);
    await loadCustomers();
    selectedCustomer.value = customer;
    appController?.triggerAutoSync();
    return customer;
  }

  // Add Product to Cart with automatic wholesale pricing calculation
  void addToCart(ProductModel product, {double qty = 1.0}) {
    if (product.isDiscontinued) {
      Get.snackbar(
        'Discontinued Product',
        '${product.name} is marked as Discontinued and cannot be added to cart.',
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return;
    }

    final index = cart.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      cart[index].quantity += qty;
      if (!cart[index].isPriceOverridden) {
        cart[index].price = cart[index].product.getEffectivePrice(cart[index].quantity);
      }
    } else {
      final initialPrice = product.getEffectivePrice(qty);
      cart.add(CartItem(product: product, quantity: qty, price: initialPrice));
    }
    cart.refresh();
  }

  // Update item quantity (supports decimal for fabrics: 2.5 yards)
  void updateQuantity(int index, double newQty) {
    if (newQty <= 0) {
      cart.removeAt(index);
    } else {
      cart[index].quantity = newQty;
      // Preserve custom price if overridden, otherwise recalculate tiered pricing
      if (!cart[index].isPriceOverridden) {
        cart[index].price = cart[index].product.getEffectivePrice(newQty);
      }
    }
    cart.refresh();
  }

  // Edit / Override individual product unit price in cart
  void updateUnitPrice(int index, double newPrice) {
    if (index >= 0 && index < cart.length && newPrice >= 0) {
      cart[index].price = newPrice;
      cart[index].isPriceOverridden = true;
      cart.refresh();
    }
  }

  // Subtotal before voucher discount and tax
  double get subtotal => cart.fold(0.0, (sum, item) => sum + item.total);

  // Grand total
  double get grandTotal {
    final discounted = (subtotal - voucherDiscount.value);
    final tax = (discounted * (taxRate.value / 100));
    return (discounted + tax + deliveryFee.value).clamp(0.0, double.infinity);
  }

  // Checkout and record local sale
  Future<SaleOrderModel?> checkout({
    required double paidAmount,
    String? notes,
    String deliveryType = 'SELF_COLLECT',
    String? deliveryServiceId,
    String? deliveryServiceName,
    String? deliveryAddress,
    String? trackingNo,
    bool isCod = false,
    double codAmount = 0.0,
    double riderCommissionAmount = 0.0,
  }) async {
    // Ensure active user session & account profile exists
    var user = appController?.currentUser.value;
    var account = appController?.currentAccount.value;
    if (user == null || account == null) {
      account = await appController?.ensureActiveAccount();
      user = appController?.currentUser.value;
    }

    if (user == null || account == null) {
      Get.snackbar(
        'Auth Required',
        'No active cashier session found. Please log in or select an account.',
        backgroundColor: Colors.amber.shade900.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    // Check Online Only mode constraint
    if (appController?.isOnlineOnly == true && appController?.isOnline.value == false) {
      Get.snackbar(
        'Server Connection Required',
        'Cannot complete checkout. "Online Use Only" mode is active and the central server is disconnected.',
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
      return null;
    }

    if (cart.isEmpty) {
      Get.snackbar('Warning', 'Cart is empty');
      return null;
    }

    final total = grandTotal;
    final change = paidAmount > total ? (paidAmount - total) : 0.0;
    final due = paidAmount < total ? (total - paidAmount) : 0.0;

    String saleStatus = 'PAID';
    if (isCod) {
      saleStatus = 'COD';
    } else if (due > 0) {
      saleStatus = paidAmount > 0 ? 'PARTIAL' : 'CREDIT';
      if (selectedCustomer.value == null) {
        Get.snackbar('Customer Required', 'Credit sale requires selecting a customer');
        return null;
      }
    }

    final orderId = const Uuid().v4();
    final voucherNo = 'VOU-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    List<SaleOrderItemModel> orderItems = [];
    for (var item in cart) {
      orderItems.add(SaleOrderItemModel(
        id: const Uuid().v4(),
        saleOrderId: orderId,
        productId: item.product.id,
        productName: item.product.name,
        unit: item.product.unit,
        price: item.price,
        costPrice: item.product.costPrice,
        quantity: item.quantity,
        discount: item.discount,
        total: item.total,
        syncStatus: 0,
      ));
    }

    final order = SaleOrderModel(
      id: orderId,
      businessId: account.businessId,
      voucherNo: voucherNo,
      customerId: selectedCustomer.value?.id,
      customerName: selectedCustomer.value?.name,
      customerPhone: selectedCustomer.value?.phone,
      userId: user.id,
      userAccountId: account.id,
      userName: user.name,
      subtotal: subtotal,
      taxAmount: subtotal * (taxRate.value / 100),
      discountAmount: voucherDiscount.value,
      deliveryFee: deliveryFee.value,
      grandTotal: total,
      paidAmount: paidAmount,
      changeAmount: change,
      dueAmount: isCod ? 0.0 : due,
      paymentMethod: isCod ? 'cod' : selectedPaymentMethod.value,
      saleStatus: saleStatus,
      notes: notes,
      saleDate: DateTime.now().toIso8601String(),
      deliveryType: deliveryType,
      deliveryServiceId: deliveryServiceId,
      deliveryServiceName: deliveryServiceName,
      deliveryAddress: deliveryAddress,
      trackingNo: trackingNo,
      isCod: isCod,
      codAmount: codAmount,
      riderCommissionAmount: riderCommissionAmount,
      deliveryStatus: deliveryType == 'DELIVERY' ? 'PENDING' : 'DELIVERED',
      codSettlementStatus: isCod ? 'PENDING' : 'N/A',
      syncStatus: 0,
      items: orderItems,
    );

    await saleDao.saveSaleOrder(order);

    // NOTE: Debt is updated atomically inside saveSaleOrder() transaction (sale_dao.dart).
    // Do NOT call adjustCustomerDebt() here — it would double-count the debt.

    // Trigger automatic sync with MySQL localhost database
    appController?.triggerAutoSync();

    // Clear cart and reset
    cart.clear();
    voucherDiscount.value = 0.0;
    deliveryFee.value = 0.0;
    selectedCustomer.value = null;

    // Reload products to update local stock quantities
    await loadProducts();
    await loadTodayVouchers();

    return order;
  }

  // --- Item Price History Management ---
  final priceHistory = <ItemPriceHistoryModel>[].obs;
  final isLoadingPriceHistory = false.obs;

  Future<List<ItemPriceHistoryModel>> fetchItemPriceHistory({
    required String productId,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      isLoadingPriceHistory.value = true;
      final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
      final list = await saleDao.getProductPriceHistory(
        productId: productId,
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        businessId: bizId,
      );
      priceHistory.assignAll(list);
      return list;
    } catch (_) {
      return [];
    } finally {
      isLoadingPriceHistory.value = false;
    }
  }

  Future<double?> getCustomerLastPrice(String productId, String customerId) async {
    final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
    return await saleDao.getLastPriceForCustomer(
      productId: productId,
      customerId: customerId,
      businessId: bizId,
    );
  }

  /// Void/delete an existing voucher (restores product stock, reverses customer credit debt, reverses courier COD)
  Future<bool> deleteVoucher(String orderId) async {
    try {
      await saleDao.deleteSaleOrder(orderId);
      await loadTodayVouchers();
      await loadProducts();
      await loadCustomers();
      Get.snackbar(
        'Voucher Voided',
        'Voucher was successfully deleted and stock was restored.',
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not delete voucher: $e',
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Recall an existing voucher into the POS Cart for editing and void the original
  Future<bool> recallVoucherToCart(SaleOrderModel order) async {
    try {
      // 1. Fetch full items if not already populated
      SaleOrderModel? fullOrder = order;
      if (order.items.isEmpty) {
        fullOrder = await saleDao.getSaleOrderById(order.id);
      }
      if (fullOrder == null) return false;

      // 2. Void the original voucher from database so stock is returned
      await saleDao.deleteSaleOrder(order.id);
      await loadTodayVouchers();
      await loadProducts();
      await loadCustomers();

      // 3. Clear existing cart and populate with voucher's items
      cart.clear();
      for (var item in fullOrder.items) {
        final matchedProduct = products.firstWhereOrNull((p) => p.id == item.productId) ??
            ProductModel(
              id: item.productId,
              name: item.productName,
              retailPrice: item.price,
              unit: item.unit,
              categoryName: 'General',
              stockQty: 999,
            );

        cart.add(CartItem(
          product: matchedProduct,
          quantity: item.quantity,
          price: item.price,
          discount: item.discount,
          isPriceOverridden: (item.price != matchedProduct.retailPrice),
        ));
      }

      // 4. Restore customer, discount, delivery fee, payment method
      if (fullOrder.customerId != null && fullOrder.customerId!.isNotEmpty) {
        selectedCustomer.value = customers.firstWhereOrNull((c) => c.id == fullOrder!.customerId);
      } else {
        selectedCustomer.value = null;
      }
      voucherDiscount.value = fullOrder.discountAmount;
      deliveryFee.value = fullOrder.deliveryFee;
      selectedPaymentMethod.value = fullOrder.paymentMethod;

      Get.snackbar(
        'Voucher Recalled to Cart',
        'Voucher ${fullOrder.voucherNo} items loaded into POS cart. Original record removed.',
        backgroundColor: Colors.teal.shade800,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to recall voucher: $e', backgroundColor: Colors.red.shade800, colorText: Colors.white);
      return false;
    }
  }

  /// Update voucher header (payment method, paid amount, due amount, notes, customer)
  Future<bool> updateVoucherHeader({
    required String orderId,
    required String paymentMethod,
    required double paidAmount,
    required double dueAmount,
    required String saleStatus,
    String? customerId,
    String? notes,
  }) async {
    try {
      await saleDao.updateSaleOrderHeader(
        orderId: orderId,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        dueAmount: dueAmount,
        saleStatus: saleStatus,
        customerId: customerId,
        notes: notes,
      );
      await loadTodayVouchers();
      await loadCustomers();
      Get.snackbar(
        'Voucher Updated',
        'Voucher changes saved successfully.',
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update voucher: $e', backgroundColor: Colors.red.shade800, colorText: Colors.white);
      return false;
    }
  }
}

