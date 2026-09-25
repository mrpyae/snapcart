import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/sale_order_model.dart';
import '../../../data/models/voucher_template_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/voucher_pdf_service.dart';

class VoucherBuilderController extends GetxController {
  final VoucherPdfService pdfService = VoucherPdfService.instance;
  final ImagePicker _picker = ImagePicker();

  final Rx<VoucherTemplateModel> template = VoucherTemplateModel.defaultTemplate().obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  // Text Controllers
  final TextEditingController storeNameCtrl = TextEditingController();
  final TextEditingController storeTaglineCtrl = TextEditingController();
  final TextEditingController storePhoneCtrl = TextEditingController();
  final TextEditingController storeAddressCtrl = TextEditingController();
  final TextEditingController socialInfoCtrl = TextEditingController();
  final TextEditingController thankYouNoteCtrl = TextEditingController();
  final TextEditingController policyNoteCtrl = TextEditingController();

  // Reactive State
  final RxString layoutStyle = 'modern'.obs;
  final RxString paperSize = 'mm80'.obs;
  final RxInt primaryColorValue = 0xFF0D9488.obs;
  final Rx<String?> logoBase64 = Rx<String?>(null);

  final RxBool showLogo = true.obs;
  final RxBool showShopDetails = true.obs;
  final RxBool showCashier = true.obs;
  final RxBool showCustomer = true.obs;
  final RxBool showPaymentMethod = true.obs;
  final RxBool showDeliveryDetails = true.obs;
  final RxBool showBarcode = true.obs;
  final RxBool showTaxAndDiscount = true.obs;
  final RxBool showSignatureLine = false.obs;

  // Mock order for live visual preview
  late final SaleOrderModel sampleOrder;

  @override
  void onInit() {
    super.onInit();
    _initSampleOrder();
    loadTemplate();
  }

  @override
  void onClose() {
    storeNameCtrl.dispose();
    storeTaglineCtrl.dispose();
    storePhoneCtrl.dispose();
    storeAddressCtrl.dispose();
    socialInfoCtrl.dispose();
    thankYouNoteCtrl.dispose();
    policyNoteCtrl.dispose();
    super.onClose();
  }

  void _initSampleOrder() {
    sampleOrder = SaleOrderModel(
      id: 'mock-sample-01',
      businessId: 'default_biz',
      voucherNo: 'VOU-84920',
      customerId: 'cust-mock-01',
      customerName: 'ဒေါ်အေးအေးသင်း',
      customerPhone: '09-450012345',
      userId: 'usr-admin-001',
      userName: 'ကိုအောင်သူ',
      subtotal: 54000.0,
      taxAmount: 2700.0,
      discountAmount: 2000.0,
      deliveryFee: 2500.0,
      grandTotal: 57200.0,
      paidAmount: 60000.0,
      changeAmount: 2800.0,
      dueAmount: 0.0,
      paymentMethod: 'KBZPay',
      saleStatus: 'PAID',
      saleDate: DateTime.now().toIso8601String(),
      deliveryType: 'DELIVERY',
      deliveryServiceName: 'Royal Express Courier',
      trackingNo: 'REX-992384',
      items: [
        SaleOrderItemModel(
          id: 'item-1',
          saleOrderId: 'mock-sample-01',
          productId: 'prod-01',
          productName: 'မြန်မာဝတ်စုံ ရင်ဖုံးအင်္ကျီ (ချည်သား)',
          unit: 'စုံ',
          price: 18500.0,
          quantity: 2.0,
          total: 37000.0,
        ),
        SaleOrderItemModel(
          id: 'item-2',
          saleOrderId: 'mock-sample-01',
          productId: 'prod-02',
          productName: 'ပိုးယွန်း လုံချည် (အနက်/ရွှေပန်း)',
          unit: 'ထည်',
          price: 17000.0,
          quantity: 1.0,
          total: 17000.0,
        ),
      ],
    );
  }

  Future<void> loadTemplate() async {
    isLoading.value = true;
    try {
      final loaded = await pdfService.getActiveTemplate();
      template.value = loaded;

      storeNameCtrl.text = loaded.storeName;
      storeTaglineCtrl.text = loaded.storeTagline;
      storePhoneCtrl.text = loaded.storePhone;
      storeAddressCtrl.text = loaded.storeAddress;
      socialInfoCtrl.text = loaded.socialInfo;
      thankYouNoteCtrl.text = loaded.thankYouNote;
      policyNoteCtrl.text = loaded.policyNote;

      layoutStyle.value = loaded.layoutStyle;
      paperSize.value = loaded.paperSize;
      primaryColorValue.value = loaded.primaryColorValue;
      logoBase64.value = loaded.logoBase64;

      showLogo.value = loaded.showLogo;
      showShopDetails.value = loaded.showShopDetails;
      showCashier.value = loaded.showCashier;
      showCustomer.value = loaded.showCustomer;
      showPaymentMethod.value = loaded.showPaymentMethod;
      showDeliveryDetails.value = loaded.showDeliveryDetails;
      showBarcode.value = loaded.showBarcode;
      showTaxAndDiscount.value = loaded.showTaxAndDiscount;
      showSignatureLine.value = loaded.showSignatureLine;
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  VoucherTemplateModel get currentLiveTemplate {
    return VoucherTemplateModel(
      id: template.value.id,
      businessId: template.value.businessId,
      storeName: storeNameCtrl.text.trim().isNotEmpty ? storeNameCtrl.text.trim() : 'SnapCart Shop',
      storeTagline: storeTaglineCtrl.text.trim(),
      storePhone: storePhoneCtrl.text.trim(),
      storeAddress: storeAddressCtrl.text.trim(),
      socialInfo: socialInfoCtrl.text.trim(),
      logoBase64: logoBase64.value,
      layoutStyle: layoutStyle.value,
      paperSize: paperSize.value,
      primaryColorValue: primaryColorValue.value,
      showLogo: showLogo.value,
      showShopDetails: showShopDetails.value,
      showCashier: showCashier.value,
      showCustomer: showCustomer.value,
      showPaymentMethod: showPaymentMethod.value,
      showDeliveryDetails: showDeliveryDetails.value,
      showBarcode: showBarcode.value,
      showTaxAndDiscount: showTaxAndDiscount.value,
      thankYouNote: thankYouNoteCtrl.text.trim(),
      policyNote: policyNoteCtrl.text.trim(),
      showSignatureLine: showSignatureLine.value,
    );
  }

  Future<void> pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        logoBase64.value = base64Encode(bytes);
        update();
      }
    } catch (e) {
      Get.snackbar('Logo Error', 'Could not select image: $e');
    }
  }

  void removeLogo() {
    logoBase64.value = null;
    update();
  }

  Future<void> saveTemplate() async {
    isSaving.value = true;
    try {
      final updated = currentLiveTemplate;
      await pdfService.saveTemplate(updated);
      template.value = updated;
      Get.snackbar(
        'Design Saved',
        'Voucher template successfully saved! All future POS receipts will use this design.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Save Error', 'Failed to save voucher template: $e',
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }

  void resetToDefault() {
    final def = VoucherTemplateModel.defaultTemplate();
    storeNameCtrl.text = def.storeName;
    storeTaglineCtrl.text = def.storeTagline;
    storePhoneCtrl.text = def.storePhone;
    storeAddressCtrl.text = def.storeAddress;
    socialInfoCtrl.text = def.socialInfo;
    thankYouNoteCtrl.text = def.thankYouNote;
    policyNoteCtrl.text = def.policyNote;

    layoutStyle.value = def.layoutStyle;
    paperSize.value = def.paperSize;
    primaryColorValue.value = def.primaryColorValue;
    logoBase64.value = null;

    showLogo.value = def.showLogo;
    showShopDetails.value = def.showShopDetails;
    showCashier.value = def.showCashier;
    showCustomer.value = def.showCustomer;
    showPaymentMethod.value = def.showPaymentMethod;
    showDeliveryDetails.value = def.showDeliveryDetails;
    showBarcode.value = def.showBarcode;
    showTaxAndDiscount.value = def.showTaxAndDiscount;
    showSignatureLine.value = def.showSignatureLine;

    update();
  }

  Future<void> testPrintPdf(BuildContext context) async {
    await pdfService.previewOrPrint(context, sampleOrder, template: currentLiveTemplate);
  }
}
