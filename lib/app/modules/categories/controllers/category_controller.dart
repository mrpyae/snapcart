import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../Controller/AppController.dart';
import '../../../data/local/category_dao.dart';
import '../../../data/models/category_model.dart';
import '../../../utils/app_colors.dart';

class CategoryController extends GetxController {
  final CategoryDao categoryDao = CategoryDao();
  final AppController appController = Get.find<AppController>();

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final list = await categoryDao.getCategories(businessId: bizId);
      categories.assignAll(list);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<CategoryModel?> saveCategory({
    String? id,
    required String name,
    String? description,
  }) async {
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final cat = CategoryModel(
        id: id ?? const Uuid().v4(),
        businessId: bizId,
        name: name.trim(),
        description: description?.trim(),
        isActive: 1,
        syncStatus: 0,
      );

      await categoryDao.insertOrUpdateCategory(cat);
      await loadCategories();

      // Trigger sync with MySQL
      appController.triggerAutoSync();

      Get.snackbar(
        'Success',
        'Category "$name" saved successfully',
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
}
