import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/local/delivery_service_dao.dart';
import '../../../data/models/delivery_service_model.dart';
import '../../../data/models/delivery_payment_model.dart';
import '../../../Controller/AppController.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/formatters.dart';

class DeliveryServiceController extends GetxController {
  final DeliveryServiceDao deliveryDao = DeliveryServiceDao();
  AppController? get appController => Get.isRegistered<AppController>() ? Get.find<AppController>() : null;

  final RxList<DeliveryServiceModel> services = <DeliveryServiceModel>[].obs;
  final RxList<DeliveryPaymentModel> payments = <DeliveryPaymentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingPayments = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool filterActiveOnly = false.obs;
  final RxDouble totalReceivable = 0.0.obs;
  final RxInt currentTabIndex = 0.obs;

  // In-House Delivery Income Tracking
  final RxMap<String, dynamic> incomeSummary = <String, dynamic>{}.obs;
  final RxBool isLoadingIncome = false.obs;
  final Rx<DateTime?> incomeStartDate = Rx<DateTime?>(DateTime.now().subtract(const Duration(days: 30)));
  final Rx<DateTime?> incomeEndDate = Rx<DateTime?>(DateTime.now());
  final RxString selectedRiderId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadServices();
    loadIncomeSummary();
  }

  Future<void> loadServices() async {
    isLoading.value = true;
    try {
      final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
      final list = await deliveryDao.getDeliveryServices(
        query: searchQuery.value,
        activeOnly: filterActiveOnly.value,
        businessId: bizId,
      );
      services.assignAll(list);
      totalReceivable.value = await deliveryDao.getTotalReceivableBalance(businessId: bizId);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadIncomeSummary() async {
    isLoadingIncome.value = true;
    try {
      final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
      final res = await deliveryDao.getInHouseDeliveryIncomeSummary(
        businessId: bizId,
        riderId: selectedRiderId.value.isNotEmpty ? selectedRiderId.value : null,
        startDate: incomeStartDate.value,
        endDate: incomeEndDate.value,
      );
      incomeSummary.assignAll(res);
    } catch (_) {
    } finally {
      isLoadingIncome.value = false;
    }
  }

  Future<bool> saveService({
    String? id,
    required String name,
    String serviceType = 'EXTERNAL',
    String riderType = 'SALARY',
    String commissionType = 'PERCENT',
    double commissionVal = 0.0,
    double defaultDeliveryFee = 0.0,
    String? phone,
    String? contactPerson,
    double baseFee = 0.0,
    String? coverageArea,
    String? notes,
    bool isActive = true,
  }) async {
    try {
      final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
      final isNew = id == null || id.isEmpty;
      final serviceId = isNew ? const Uuid().v4() : id;

      // Retain existing receivable balance if editing
      double existingBalance = 0.0;
      if (!isNew) {
        final existing = await deliveryDao.getDeliveryServiceById(serviceId);
        existingBalance = existing?.receivableBalance ?? 0.0;
      }

      final service = DeliveryServiceModel(
        id: serviceId,
        businessId: bizId,
        name: name.trim(),
        serviceType: serviceType,
        riderType: riderType,
        commissionType: commissionType,
        commissionVal: commissionVal,
        defaultDeliveryFee: defaultDeliveryFee,
        phone: phone?.trim(),
        contactPerson: contactPerson?.trim(),
        baseFee: baseFee,
        coverageArea: coverageArea?.trim(),
        receivableBalance: existingBalance,
        notes: notes?.trim(),
        isActive: isActive,
        syncStatus: 0,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await deliveryDao.saveDeliveryService(service);
      await loadServices();
      await loadIncomeSummary();
      appController?.triggerAutoSync();

      Get.snackbar(
        'Delivery Service Saved',
        'Service "${service.name}" saved successfully',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to save delivery service: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  Future<void> toggleActive(DeliveryServiceModel service) async {
    final updated = service.copyWith(isActive: !service.isActive);
    await deliveryDao.saveDeliveryService(updated);
    await loadServices();
    appController?.triggerAutoSync();
  }

  Future<void> deleteService(String id) async {
    try {
      await deliveryDao.deleteDeliveryService(id);
      await loadServices();
      await loadIncomeSummary();
      appController?.triggerAutoSync();
      Get.snackbar('Service Deleted', 'Delivery service removed');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete service: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // Record a payment / remittance from courier back to shop and reduce receivable balance
  Future<bool> recordRemittancePayment({
    required String deliveryServiceId,
    required double amount,
    String paymentMethod = 'cash',
    String? notes,
  }) async {
    try {
      if (amount <= 0) {
        Get.snackbar('Invalid Amount', 'Payment amount must be greater than 0');
        return false;
      }

      final bizId = appController?.currentAccount.value?.businessId ?? 'default_biz';
      final payment = DeliveryPaymentModel(
        id: const Uuid().v4(),
        businessId: bizId,
        deliveryServiceId: deliveryServiceId,
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes?.trim(),
        paymentDate: DateTime.now().toIso8601String(),
        syncStatus: 0,
        createdAt: DateTime.now().toIso8601String(),
      );

      await deliveryDao.recordDeliveryPayment(payment);
      await loadServices();
      await loadPayments(deliveryServiceId);
      appController?.triggerAutoSync();

      Get.snackbar(
        'Remittance Recorded',
        'Received ${Formatters.formatCurrency(amount)} from courier. Receivable reduced.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to record remittance: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  // Load remittance history for a delivery service
  Future<void> loadPayments(String deliveryServiceId) async {
    isLoadingPayments.value = true;
    try {
      final list = await deliveryDao.getDeliveryPayments(deliveryServiceId);
      payments.assignAll(list);
    } catch (_) {
    } finally {
      isLoadingPayments.value = false;
    }
  }
}
