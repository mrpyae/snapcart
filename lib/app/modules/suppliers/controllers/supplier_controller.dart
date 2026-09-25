import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../Controller/AppController.dart';
import '../../../data/local/supplier_category_dao.dart';
import '../../../data/local/supplier_dao.dart';
import '../../../data/models/supplier_category_model.dart';
import '../../../data/models/supplier_model.dart';
import '../../../data/models/supplier_payment_model.dart';
import '../../../utils/app_colors.dart';

class SupplierController extends GetxController {
  final SupplierDao supplierDao = SupplierDao();
  final SupplierCategoryDao supplierCategoryDao = SupplierCategoryDao();
  final AppController appController = Get.find<AppController>();

  final RxList<SupplierModel> suppliers = <SupplierModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Supplier Categories state
  final RxList<SupplierCategoryModel> categories = <SupplierCategoryModel>[].obs;
  final RxString selectedCategoryId = ''.obs; // '' means All categories
  final RxBool isCategoryLoading = false.obs;

  // Ledger state for selected supplier
  final RxList<SupplierPaymentModel> currentPayments = <SupplierPaymentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    loadSuppliers();
  }

  Future<void> loadCategories() async {
    isCategoryLoading.value = true;
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final list = await supplierCategoryDao.getCategories(businessId: bizId);
      categories.assignAll(list);
    } catch (_) {
    } finally {
      isCategoryLoading.value = false;
    }
  }

  Future<SupplierCategoryModel?> saveCategory({
    String? id,
    required String name,
    String? description,
  }) async {
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final cat = SupplierCategoryModel(
        id: id ?? const Uuid().v4(),
        businessId: bizId,
        name: name.trim(),
        description: description?.trim(),
        isActive: 1,
        syncStatus: 0,
      );

      await supplierCategoryDao.insertOrUpdateCategory(cat);
      await loadCategories();
      await loadSuppliers();

      // Trigger sync
      appController.triggerAutoSync();

      Get.snackbar(
        'Success',
        'Supplier Category "$name" saved successfully',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return cat;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save category: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await supplierCategoryDao.deleteCategory(id);
      if (selectedCategoryId.value == id) {
        selectedCategoryId.value = '';
      }
      await loadCategories();
      await loadSuppliers();

      appController.triggerAutoSync();

      Get.snackbar(
        'Deleted',
        'Supplier category deleted successfully',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete category: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> loadSuppliers() async {
    isLoading.value = true;
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final list = await supplierDao.getSuppliers(
        query: searchQuery.value,
        businessId: bizId,
        categoryId: selectedCategoryId.value.isNotEmpty ? selectedCategoryId.value : null,
      );
      suppliers.assignAll(list);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<SupplierModel?> saveSupplier({
    String? id,
    required String name,
    String? supplierCategoryId,
    String? phone,
    String? companyName,
    String? address,
    double payableBalance = 0.0,
    double advanceBalance = 0.0,
  }) async {
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final supplier = SupplierModel(
        id: id ?? const Uuid().v4(),
        businessId: bizId,
        supplierCategoryId: supplierCategoryId,
        name: name.trim(),
        phone: phone?.trim(),
        companyName: companyName?.trim(),
        address: address?.trim(),
        payableBalance: payableBalance,
        advanceBalance: advanceBalance,
        isActive: 1,
        syncStatus: 0,
      );

      await supplierDao.insertOrUpdateSupplier(supplier);
      await loadSuppliers();

      // Trigger sync
      appController.triggerAutoSync();

      Get.snackbar(
        'Success',
        'Supplier "$name" saved successfully',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return supplier;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save supplier: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // Settle supplier debt or record advance payment
  Future<bool> recordPayment({
    required String supplierId,
    String? purchaseId,
    required double amount,
    String type = 'PAYMENT', // 'PAYMENT' or 'ADVANCE'
    String paymentMethod = 'cash',
    DateTime? paymentDate,
    String? notes,
  }) async {
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final payment = SupplierPaymentModel(
        id: const Uuid().v4(),
        businessId: bizId,
        supplierId: supplierId,
        purchaseId: purchaseId,
        amount: amount,
        type: type,
        paymentMethod: paymentMethod,
        paymentDate: (paymentDate ?? DateTime.now()).toIso8601String(),
        notes: notes,
        syncStatus: 0,
      );

      await supplierDao.recordSupplierPayment(payment);
      await loadSuppliers();

      // Trigger sync
      appController.triggerAutoSync();

      Get.snackbar(
        'Payment Recorded',
        type == 'PAYMENT'
            ? 'Successfully settled ${amount.toStringAsFixed(0)} Ks debt'
            : 'Successfully recorded ${amount.toStringAsFixed(0)} Ks advance deposit',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to record payment: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> loadSupplierPayments(String supplierId) async {
    try {
      final list = await supplierDao.getSupplierPayments(supplierId);
      currentPayments.assignAll(list);
    } catch (_) {
      currentPayments.clear();
    }
  }

  // Edit existing payment record
  Future<bool> editPayment(SupplierPaymentModel updatedPayment) async {
    try {
      await supplierDao.updateSupplierPayment(updatedPayment);
      await loadSuppliers();
      await loadSupplierPayments(updatedPayment.supplierId);
      appController.triggerAutoSync();

      Get.snackbar(
        'Payment Updated',
        'Payment record updated successfully',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update payment: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }
}
