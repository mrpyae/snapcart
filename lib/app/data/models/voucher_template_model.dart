import 'dart:convert';

class VoucherTemplateModel {
  final String id;
  final String businessId;
  final String storeName;
  final String storeTagline;
  final String storePhone;
  final String storeAddress;
  final String socialInfo;
  final String? logoBase64;
  final String layoutStyle; // 'modern', 'classic_thermal', 'corporate_invoice', 'minimal'
  final String paperSize; // 'mm80', 'mm58', 'a4', 'a5'
  final int primaryColorValue; // e.g. 0xFF0D9488
  final String headerAlignment; // 'center', 'left', 'right'
  final String fontSizeScale; // 'compact', 'standard', 'large'
  final bool showLogo;
  final bool showShopDetails;
  final bool showCashier;
  final bool showCustomer;
  final bool showPaymentMethod;
  final bool showDeliveryDetails;
  final bool showBarcode;
  final bool showTaxAndDiscount;
  final String thankYouNote;
  final String policyNote;
  final bool showSignatureLine;

  const VoucherTemplateModel({
    required this.id,
    required this.businessId,
    required this.storeName,
    this.storeTagline = 'မြန်မာဝတ်စုံနှင့် အထည်အလိပ် လက်လီ/လက်ကား',
    this.storePhone = '09-123456789, 09-987654321',
    this.storeAddress = 'အမှတ် (၁၂)၊ ဗဟိုလမ်း၊ ကမာရွတ်မြို့နယ်၊ ရန်ကုန်။',
    this.socialInfo = 'Viber / FB: 09123456789',
    this.logoBase64,
    this.layoutStyle = 'modern',
    this.paperSize = 'mm80',
    this.primaryColorValue = 0xFF0D9488,
    this.headerAlignment = 'center',
    this.fontSizeScale = 'standard',
    this.showLogo = true,
    this.showShopDetails = true,
    this.showCashier = true,
    this.showCustomer = true,
    this.showPaymentMethod = true,
    this.showDeliveryDetails = true,
    this.showBarcode = true,
    this.showTaxAndDiscount = true,
    this.thankYouNote = 'ဝယ်ယူအားပေးမှုအတွက် အထူးကျေးဇူးတင်ရှိပါသည်။ (Thank You)',
    this.policyNote = 'ပစ္စည်းများ လဲလှယ်လိုပါက (၃) ရက်အတွင်း ဘောက်ချာနှင့်တကွ ယူဆောင်လာပါရန်။',
    this.showSignatureLine = false,
  });

  factory VoucherTemplateModel.defaultTemplate() {
    return const VoucherTemplateModel(
      id: 'tpl-default',
      businessId: 'default_biz',
      storeName: 'SnapCart Textile & Fashion',
      storeTagline: 'မြန်မာဝတ်စုံနှင့် အထည်အလိပ် လက်လီ/လက်ကား',
      storePhone: '09-123456789, 09-987654321',
      storeAddress: 'အမှတ် (၁၂)၊ ဗဟိုလမ်း၊ ကမာရွတ်မြို့နယ်၊ ရန်ကုန်။',
      socialInfo: 'Viber / FB: 09123456789',
      logoBase64: null,
      layoutStyle: 'modern',
      paperSize: 'mm80',
      primaryColorValue: 0xFF0D9488,
      headerAlignment: 'center',
      fontSizeScale: 'standard',
      showLogo: true,
      showShopDetails: true,
      showCashier: true,
      showCustomer: true,
      showPaymentMethod: true,
      showDeliveryDetails: true,
      showBarcode: true,
      showTaxAndDiscount: true,
      thankYouNote: 'ဝယ်ယူအားပေးမှုအတွက် အထူးကျေးဇူးတင်ရှိပါသည်။ (Thank You)',
      policyNote: 'ပစ္စည်းများ လဲလှယ်လိုပါက (၃) ရက်အတွင်း ဘောက်ချာနှင့်တကွ ယူဆောင်လာပါရန်။',
      showSignatureLine: false,
    );
  }

  VoucherTemplateModel copyWith({
    String? id,
    String? businessId,
    String? storeName,
    String? storeTagline,
    String? storePhone,
    String? storeAddress,
    String? socialInfo,
    String? logoBase64,
    bool clearLogo = false,
    String? layoutStyle,
    String? paperSize,
    int? primaryColorValue,
    String? headerAlignment,
    String? fontSizeScale,
    bool? showLogo,
    bool? showShopDetails,
    bool? showCashier,
    bool? showCustomer,
    bool? showPaymentMethod,
    bool? showDeliveryDetails,
    bool? showBarcode,
    bool? showTaxAndDiscount,
    String? thankYouNote,
    String? policyNote,
    bool? showSignatureLine,
  }) {
    return VoucherTemplateModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      storeName: storeName ?? this.storeName,
      storeTagline: storeTagline ?? this.storeTagline,
      storePhone: storePhone ?? this.storePhone,
      storeAddress: storeAddress ?? this.storeAddress,
      socialInfo: socialInfo ?? this.socialInfo,
      logoBase64: clearLogo ? null : (logoBase64 ?? this.logoBase64),
      layoutStyle: layoutStyle ?? this.layoutStyle,
      paperSize: paperSize ?? this.paperSize,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      headerAlignment: headerAlignment ?? this.headerAlignment,
      fontSizeScale: fontSizeScale ?? this.fontSizeScale,
      showLogo: showLogo ?? this.showLogo,
      showShopDetails: showShopDetails ?? this.showShopDetails,
      showCashier: showCashier ?? this.showCashier,
      showCustomer: showCustomer ?? this.showCustomer,
      showPaymentMethod: showPaymentMethod ?? this.showPaymentMethod,
      showDeliveryDetails: showDeliveryDetails ?? this.showDeliveryDetails,
      showBarcode: showBarcode ?? this.showBarcode,
      showTaxAndDiscount: showTaxAndDiscount ?? this.showTaxAndDiscount,
      thankYouNote: thankYouNote ?? this.thankYouNote,
      policyNote: policyNote ?? this.policyNote,
      showSignatureLine: showSignatureLine ?? this.showSignatureLine,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'storeName': storeName,
      'storeTagline': storeTagline,
      'storePhone': storePhone,
      'storeAddress': storeAddress,
      'socialInfo': socialInfo,
      'logoBase64': logoBase64,
      'layoutStyle': layoutStyle,
      'paperSize': paperSize,
      'primaryColorValue': primaryColorValue,
      'headerAlignment': headerAlignment,
      'fontSizeScale': fontSizeScale,
      'showLogo': showLogo ? 1 : 0,
      'showShopDetails': showShopDetails ? 1 : 0,
      'showCashier': showCashier ? 1 : 0,
      'showCustomer': showCustomer ? 1 : 0,
      'showPaymentMethod': showPaymentMethod ? 1 : 0,
      'showDeliveryDetails': showDeliveryDetails ? 1 : 0,
      'showBarcode': showBarcode ? 1 : 0,
      'showTaxAndDiscount': showTaxAndDiscount ? 1 : 0,
      'thankYouNote': thankYouNote,
      'policyNote': policyNote,
      'showSignatureLine': showSignatureLine ? 1 : 0,
    };
  }

  factory VoucherTemplateModel.fromMap(Map<String, dynamic> map) {
    return VoucherTemplateModel(
      id: map['id']?.toString() ?? 'tpl-default',
      businessId: map['businessId']?.toString() ?? 'default_biz',
      storeName: map['storeName']?.toString() ?? 'SnapCart Textile & Fashion',
      storeTagline: map['storeTagline']?.toString() ?? '',
      storePhone: map['storePhone']?.toString() ?? '',
      storeAddress: map['storeAddress']?.toString() ?? '',
      socialInfo: map['socialInfo']?.toString() ?? '',
      logoBase64: map['logoBase64']?.toString(),
      layoutStyle: map['layoutStyle']?.toString() ?? 'modern',
      paperSize: map['paperSize']?.toString() ?? 'mm80',
      primaryColorValue: map['primaryColorValue'] is int
          ? map['primaryColorValue']
          : int.tryParse(map['primaryColorValue']?.toString() ?? '') ?? 0xFF0D9488,
      headerAlignment: map['headerAlignment']?.toString() ?? 'center',
      fontSizeScale: map['fontSizeScale']?.toString() ?? 'standard',
      showLogo: map['showLogo'] == 1 || map['showLogo'] == true,
      showShopDetails: map['showShopDetails'] == 1 || map['showShopDetails'] == true,
      showCashier: map['showCashier'] == 1 || map['showCashier'] == true,
      showCustomer: map['showCustomer'] == 1 || map['showCustomer'] == true,
      showPaymentMethod: map['showPaymentMethod'] == 1 || map['showPaymentMethod'] == true,
      showDeliveryDetails: map['showDeliveryDetails'] == 1 || map['showDeliveryDetails'] == true,
      showBarcode: map['showBarcode'] == 1 || map['showBarcode'] == true,
      showTaxAndDiscount: map['showTaxAndDiscount'] == 1 || map['showTaxAndDiscount'] == true,
      thankYouNote: map['thankYouNote']?.toString() ?? '',
      policyNote: map['policyNote']?.toString() ?? '',
      showSignatureLine: map['showSignatureLine'] == 1 || map['showSignatureLine'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory VoucherTemplateModel.fromJson(String source) =>
      VoucherTemplateModel.fromMap(json.decode(source));
}
