import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/local/customer_dao.dart';
import '../../../data/local/customer_order_dao.dart';
import '../../../data/local/product_dao.dart';
import '../../../data/local/delivery_service_dao.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/customer_order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../Controller/AppController.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';

import '../../../data/local/supplier_dao.dart';
import '../../../data/models/supplier_model.dart';
import '../../../data/models/product_supplier_model.dart';

class CustomerOrderController extends GetxController {
  final CustomerOrderDao orderDao = CustomerOrderDao();
  final CustomerDao customerDao = CustomerDao();
  final ProductDao productDao = ProductDao();
  final SupplierDao supplierDao = SupplierDao();
  final DeliveryServiceDao deliveryDao = DeliveryServiceDao();
  AppController? get appController => Get.isRegistered<AppController>() ? Get.find<AppController>() : null;

  final RxList<CustomerOrderModel> orders = <CustomerOrderModel>[].obs;
  final RxList<CustomerModel> customers = <CustomerModel>[].obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<SupplierModel> suppliers = <SupplierModel>[].obs;
  final RxBool isLoading = false.obs;

  // Filter States
  final RxString selectedStatusFilter = 'ALL'.obs;
  final RxString selectedSourceFilter = 'ALL'.obs;
  final RxString selectedDateFilter = 'ALL'.obs; // 'ALL', 'TODAY', 'TOMORROW', 'THIS_WEEK'
  final RxString selectedSupplierFilter = 'ALL'.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
    loadCustomers();
    loadProducts();
    loadSuppliers();
  }

  Future<void> loadCustomers() async {
    final list = await customerDao.getCustomers();
    customers.assignAll(list);
  }

  Future<void> loadProducts() async {
    final list = await productDao.searchProducts();
    products.assignAll(list);
  }

  Future<void> loadSuppliers() async {
    final list = await supplierDao.getSuppliers();
    suppliers.assignAll(list);
  }

  Future<List<ProductSupplierModel>> getSuppliersForProduct(String productId) async {
    return await supplierDao.getSuppliersForProduct(productId);
  }

  Future<void> loadOrders() async {
    isLoading.value = true;
    try {
      final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';

      DateTime? targetDate;
      final now = DateTime.now();
      if (selectedDateFilter.value == 'TODAY') {
        targetDate = now;
      } else if (selectedDateFilter.value == 'TOMORROW') {
        targetDate = now.add(const Duration(days: 1));
      }

      final list = await orderDao.getCustomerOrders(
        status: selectedStatusFilter.value,
        orderSource: selectedSourceFilter.value,
        query: searchQuery.value,
        supplierId: selectedSupplierFilter.value,
        appointmentDate: targetDate,
        businessId: bizId,
      );

      orders.assignAll(list);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  // Metrics
  int get todayAppointmentsCount {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    return orders.where((o) => o.appointmentDate != null && o.appointmentDate!.startsWith(todayStr)).length;
  }

  int get inProgressCount => orders.where((o) => o.status == 'IN_PROGRESS').length;
  int get readyForPickupCount => orders.where((o) => o.status == 'READY_FOR_PICKUP').length;
  double get totalAdvanceDeposits => orders.fold(0.0, (sum, o) => sum + o.advanceAmount);

  // Save / Create Customer Order
  Future<bool> saveOrder({
    String? id,
    String? customerId,
    required String customerName,
    String? customerPhone,
    String? customerAddress,
    String orderSource = 'PHONE',
    String? leadAccount,
    String? appointmentDate,
    String appointmentType = 'LOOM_WEAVING',
    String? supplierId,
    String? supplierName,
    String? linkedPurchaseId,
    String status = 'PENDING',
    required double totalAmount,
    double advanceAmount = 0.0,
    String paymentMethod = 'cash',
    String? notes,
    required List<CustomerOrderItemModel> items,
  }) async {
    try {
      final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
      final orderId = id ?? const Uuid().v4();
      final orderNo = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final due = (totalAmount - advanceAmount).clamp(0.0, double.infinity);

      final order = CustomerOrderModel(
        id: orderId,
        orderNo: orderNo,
        businessId: bizId,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        orderSource: orderSource,
        leadAccount: leadAccount,
        appointmentDate: appointmentDate,
        appointmentType: appointmentType,
        supplierId: supplierId,
        supplierName: supplierName,
        linkedPurchaseId: linkedPurchaseId,
        status: status,
        totalAmount: totalAmount,
        advanceAmount: advanceAmount,
        dueAmount: due,
        paymentMethod: paymentMethod,
        notes: notes,
        createdAt: DateTime.now().toIso8601String(),
        items: items.map((i) => CustomerOrderItemModel(
          id: i.id.isNotEmpty ? i.id : const Uuid().v4(),
          customerOrderId: orderId,
          productId: i.productId,
          itemName: i.itemName,
          fabricType: i.fabricType,
          color: i.color,
          supplierId: i.supplierId ?? supplierId,
          supplierName: i.supplierName ?? supplierName,
          quantity: i.quantity,
          unit: i.unit,
          unitPrice: i.unitPrice,
          subtotal: i.subtotal,
          designNotes: i.designNotes,
        )).toList(),
      );

      await orderDao.saveCustomerOrder(order);
      await loadOrders();

      appController?.triggerAutoSync();

      Get.snackbar(
        'Order Saved',
        'Customer order "$orderNo" saved successfully',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to save order: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  // Update Status Progression
  Future<void> updateStatus(String orderId, String newStatus) async {
    await orderDao.updateOrderStatus(orderId, newStatus);
    await loadOrders();
    appController?.triggerAutoSync();

    Get.snackbar(
      'Status Updated',
      'Order marked as "$newStatus"',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Reschedule Appointment
  Future<void> rescheduleAppointment(String orderId, String newDate, {String? appointmentType}) async {
    await orderDao.rescheduleAppointment(orderId, newDate, appointmentType: appointmentType);
    await loadOrders();
    appController?.triggerAutoSync();

    Get.snackbar(
      'Rescheduled',
      'Appointment updated successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Collect Customer Order Payment & Settle Remaining Due
  Future<void> collectOrderPayment({
    required CustomerOrderModel order,
    required double paymentAmount,
    String paymentMethod = 'cash',
    bool markCompleted = false,
    bool chargeRemainingToDebt = false,
    String deliveryType = 'SELF_COLLECT',
    String? deliveryServiceId,
    String? deliveryServiceName,
    double deliveryFee = 0.0,
    double riderCommissionAmount = 0.0,
    bool isCod = false,
    double codAmount = 0.0,
  }) async {
    try {
      await orderDao.recordOrderPayment(
        order.id,
        paymentAmount,
        paymentMethod: isCod ? 'cod' : paymentMethod,
        markCompleted: markCompleted || isCod,
        deliveryType: deliveryType,
        deliveryServiceId: deliveryServiceId,
        deliveryServiceName: deliveryServiceName,
        deliveryFee: deliveryFee,
        riderCommissionAmount: riderCommissionAmount,
        isCod: isCod,
        codAmount: codAmount,
      );

      // If COD and delivery service selected, increment courier receivable
      if (isCod && deliveryServiceId != null && codAmount > 0) {
        await deliveryDao.adjustReceivable(deliveryServiceId, codAmount);
      }

      final remainingDue = (order.dueAmount - paymentAmount).clamp(0.0, double.infinity);

      // If customer is registered and remaining due is converted to credit/debt (and not COD)
      if (!isCod && chargeRemainingToDebt && remainingDue > 0 && order.customerId != null && order.customerId!.isNotEmpty) {
        await customerDao.adjustCustomerDebt(order.customerId!, remainingDue);
      }

      await loadOrders();
      appController?.triggerAutoSync();

      Get.snackbar(
        'Payment Recorded',
        isCod
            ? 'Order ${order.orderNo} marked for COD Delivery (${Formatters.formatCurrency(codAmount)})'
            : 'Payment of ${Formatters.formatCurrency(paymentAmount)} recorded for order ${order.orderNo}',
        backgroundColor: isCod ? Colors.amber.shade800 : AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to record payment: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // Delete Order
  Future<void> deleteOrder(String orderId) async {
    await orderDao.deleteCustomerOrder(orderId);
    await loadOrders();
    appController?.triggerAutoSync();

    Get.snackbar('Order Deleted', 'Customer order removed');
  }
}
