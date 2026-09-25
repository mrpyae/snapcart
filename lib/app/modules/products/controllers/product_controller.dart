import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/local/customer_order_dao.dart';
import '../../../data/local/product_dao.dart';
import '../../../data/local/supplier_dao.dart';
import '../../../data/models/customer_order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_supplier_model.dart';
import '../../../Controller/AppController.dart';
import '../../pos/controllers/pos_controller.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/image_picker_helper.dart';
import '../../../utils/image_similarity_service.dart';

class ProductController extends GetxController {
  final ProductDao productDao = ProductDao();
  final SupplierDao supplierDao = SupplierDao();
  final CustomerOrderDao customerOrderDao = CustomerOrderDao();
  final AppController appController = Get.find<AppController>();

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rx<String?> visualSearchImage = Rx<String?>(null);
  final RxMap<String, int> visualMatchScores = <String, int>{}.obs;

  final RxList<ProductSupplierModel> productSuppliers = <ProductSupplierModel>[].obs;
  final RxBool isLoadingSuppliers = false.obs;

  final RxList<CustomerOrderModel> currentProductOrders = <CustomerOrderModel>[].obs;
  final RxBool isLoadingProductOrders = false.obs;
  final RxDouble activeOrderedQty = 0.0.obs;
  final RxDouble activeOrderedAmount = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> searchByVisualImage({bool isCamera = false}) async {
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
    isLoading.value = true;
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final list = await productDao.searchProducts(
        query: searchQuery.value,
        businessId: bizId,
      ).timeout(const Duration(seconds: 3), onTimeout: () => []);

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
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  // Pick Image from Gallery or Camera (Android/iOS/Web cross-platform)
  Future<String?> pickProductImage({bool isCamera = false}) async {
    try {
      final img = await pickImageCrossPlatform(isCamera: isCamera);
      return img;
    } catch (e) {
      Get.snackbar(
        'Image Error',
        'Could not load image: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<void> loadProductSuppliers(String productId) async {
    isLoadingSuppliers.value = true;
    try {
      final list = await supplierDao.getSuppliersForProduct(productId);
      productSuppliers.assignAll(list);
    } catch (e) {
      debugPrint('Error loading product suppliers: $e');
    } finally {
      isLoadingSuppliers.value = false;
    }
  }

  Future<bool> saveProductSuppliers(String productId, List<String> supplierIds, {String? preferredSupplierId}) async {
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      await supplierDao.linkProductSuppliers(
        productId,
        supplierIds,
        businessId: bizId,
        preferredSupplierId: preferredSupplierId,
      );
      await loadProductSuppliers(productId);
      return true;
    } catch (e) {
      debugPrint('Error saving product suppliers: $e');
      return false;
    }
  }

  Future<bool> unlinkProductSupplier(String productId, String supplierId) async {
    try {
      await supplierDao.unlinkProductSupplier(productId, supplierId);
      await loadProductSuppliers(productId);
      return true;
    } catch (e) {
      debugPrint('Error unlinking product supplier: $e');
      return false;
    }
  }

  Future<void> loadOrdersForProduct(String productId, {bool activeOnly = true}) async {
    isLoadingProductOrders.value = true;
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final orders = await customerOrderDao.getOrdersForProduct(
        productId,
        activeOnly: activeOnly,
        businessId: bizId,
      );
      currentProductOrders.assignAll(orders);

      // Compute active reserved qty and total pending value
      double qty = 0.0;
      double amount = 0.0;
      for (final order in orders) {
        if (order.status != 'COMPLETED' && order.status != 'CANCELLED') {
          for (final item in order.items) {
            if (item.productId == productId) {
              qty += item.quantity;
              amount += item.subtotal;
            }
          }
        }
      }
      activeOrderedQty.value = qty;
      activeOrderedAmount.value = amount;
    } catch (e) {
      debugPrint('Error loading product orders: $e');
    } finally {
      isLoadingProductOrders.value = false;
    }
  }

  Future<bool> saveProduct({
    String? id,
    required String name,
    String? barcode,
    String? categoryId,
    String? fabricType,
    String? size,
    String? color,
    String unit = 'piece',
    double costPrice = 0.0,
    required double retailPrice,
    double wholesalePrice = 0.0,
    double minWholesaleQty = 5.0,
    double stockQty = 0.0,
    double minStockAlert = 5.0,
    String? imageUrl,
    int isOneSet = 0,
    String productStatus = 'AVAILABLE',
    List<String>? supplierIds,
    String? preferredSupplierId,
  }) async {
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final generatedId = id ?? const Uuid().v4();
      final product = ProductModel(
        id: generatedId,
        businessId: bizId,
        name: name,
        barcode: barcode?.isNotEmpty == true ? barcode : (DateTime.now().millisecondsSinceEpoch % 1000000).toString(),
        categoryId: categoryId,
        fabricType: fabricType,
        size: size,
        color: color,
        unit: unit,
        costPrice: costPrice,
        retailPrice: retailPrice,
        wholesalePrice: wholesalePrice,
        minWholesaleQty: minWholesaleQty,
        stockQty: stockQty,
        minStockAlert: minStockAlert,
        imageUrl: imageUrl,
        isOneSet: isOneSet,
        productStatus: productStatus,
        isActive: 1,
        syncStatus: 0,
      );

      await productDao.insertOrUpdateProduct(product).timeout(const Duration(seconds: 4));
      
      if (supplierIds != null) {
        await supplierDao.linkProductSuppliers(
          generatedId,
          supplierIds,
          businessId: bizId,
          preferredSupplierId: preferredSupplierId,
        );
      }

      await loadProducts().timeout(const Duration(seconds: 3));

      // Trigger automatic sync with MySQL localhost database
      appController.triggerAutoSync();

      // Also reload POS counter products if active
      if (Get.isRegistered<POSController>()) {
        Get.find<POSController>().loadProducts();
      }

      Get.snackbar(
        'Success',
        'Product "${product.name}" saved and synced successfully',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save product: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<ProductModel?> saveProductAndReturn({
    String? id,
    required String name,
    String? barcode,
    String? categoryId,
    String? fabricType,
    String? size,
    String? color,
    String unit = 'piece',
    double costPrice = 0.0,
    required double retailPrice,
    double wholesalePrice = 0.0,
    double minWholesaleQty = 5.0,
    double stockQty = 0.0,
    double minStockAlert = 5.0,
    String? imageUrl,
    int isOneSet = 0,
    String productStatus = 'AVAILABLE',
    List<String>? supplierIds,
    String? preferredSupplierId,
  }) async {
    try {
      final bizId = appController.currentAccount.value?.businessId ?? 'default_biz';
      final generatedId = id ?? const Uuid().v4();
      final product = ProductModel(
        id: generatedId,
        businessId: bizId,
        name: name,
        barcode: barcode?.isNotEmpty == true ? barcode : (DateTime.now().millisecondsSinceEpoch % 1000000).toString(),
        categoryId: categoryId,
        fabricType: fabricType,
        size: size,
        color: color,
        unit: unit,
        costPrice: costPrice,
        retailPrice: retailPrice,
        wholesalePrice: wholesalePrice,
        minWholesaleQty: minWholesaleQty,
        stockQty: stockQty,
        minStockAlert: minStockAlert,
        imageUrl: imageUrl,
        isOneSet: isOneSet,
        productStatus: productStatus,
        isActive: 1,
        syncStatus: 0,
      );

      await productDao.insertOrUpdateProduct(product).timeout(const Duration(seconds: 4));

      if (supplierIds != null) {
        await supplierDao.linkProductSuppliers(
          generatedId,
          supplierIds,
          businessId: bizId,
          preferredSupplierId: preferredSupplierId,
        );
      }

      await loadProducts().timeout(const Duration(seconds: 3));

      // Trigger automatic sync with MySQL localhost database
      appController.triggerAutoSync();

      // Also reload POS counter products if active
      if (Get.isRegistered<POSController>()) {
        Get.find<POSController>().loadProducts();
      }

      Get.snackbar(
        'Success',
        'Product "${product.name}" created and added successfully',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return product;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save product: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }
}
