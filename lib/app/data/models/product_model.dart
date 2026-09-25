import 'dart:convert';

class ProductModel {
  final String id;
  final String businessId;
  final String? categoryId;
  final String? categoryName;
  final String? barcode;
  final String name;
  final String? fabricType;
  final String? size;
  final String? color;
  final String unit;
  final double costPrice;
  final double retailPrice;
  final double wholesalePrice;
  final double minWholesaleQty;
  final double stockQty;
  final double minStockAlert;
  final String? imageUrl;
  final int isOneSet;
  final String productStatus; // 'AVAILABLE', 'OUT_OF_STOCK', 'PRE_ORDER', 'DISCONTINUED'
  final int isActive;
  final int syncStatus;

  ProductModel({
    required this.id,
    this.businessId = 'default_biz',
    this.categoryId,
    this.categoryName,
    this.barcode,
    required this.name,
    this.fabricType,
    this.size,
    this.color,
    this.unit = 'piece',
    this.costPrice = 0.0,
    required this.retailPrice,
    this.wholesalePrice = 0.0,
    this.minWholesaleQty = 5.0,
    this.stockQty = 0.0,
    this.minStockAlert = 5.0,
    this.imageUrl,
    this.isOneSet = 0,
    this.productStatus = 'AVAILABLE',
    this.isActive = 1,
    this.syncStatus = 1,
  });

  // Return list of images (supports multiple images stored as JSON array or pipe-separated)
  List<String> get imageList {
    if (imageUrl == null || imageUrl!.trim().isEmpty) return [];
    final trimmed = imageUrl!.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final List<dynamic> list = jsonDecode(trimmed);
        return list.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
      } catch (_) {}
    }
    if (trimmed.contains('|')) {
      return trimmed.split('|').where((s) => s.trim().isNotEmpty).toList();
    }
    return [trimmed];
  }

  // Get primary display image
  String? get primaryImage => imageList.isNotEmpty ? imageList.first : null;

  // Status helpers
  bool get isAvailable => productStatus == 'AVAILABLE';
  bool get isOutOfStock => productStatus == 'OUT_OF_STOCK';
  bool get isPreOrder => productStatus == 'PRE_ORDER';
  bool get isDiscontinued => productStatus == 'DISCONTINUED';

  String get statusLabel {
    switch (productStatus) {
      case 'OUT_OF_STOCK':
        return 'ပစ္စည်းပြတ်';
      case 'PRE_ORDER':
        return 'Pre-Order';
      case 'DISCONTINUED':
        return 'ရပ်ဆိုင်း';
      case 'AVAILABLE':
      default:
        return 'ရောင်းရန်ရှိ';
    }
  }

  // Calculate dynamic price based on order quantity
  double getEffectivePrice(double qty) {
    if (wholesalePrice > 0 && qty >= minWholesaleQty) {
      return wholesalePrice;
    }
    return retailPrice;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name']?.toString(),
      barcode: json['barcode']?.toString(),
      name: json['name']?.toString() ?? '',
      fabricType: json['fabric_type']?.toString(),
      size: json['size']?.toString(),
      color: json['color']?.toString(),
      unit: json['unit']?.toString() ?? 'piece',
      costPrice: double.tryParse(json['cost_price']?.toString() ?? '0') ?? 0.0,
      retailPrice: double.tryParse(json['retail_price']?.toString() ?? '0') ?? 0.0,
      wholesalePrice: double.tryParse(json['wholesale_price']?.toString() ?? '0') ?? 0.0,
      minWholesaleQty: double.tryParse(json['min_wholesale_qty']?.toString() ?? '5') ?? 5.0,
      stockQty: double.tryParse(json['stock_qty']?.toString() ?? '0') ?? 0.0,
      minStockAlert: double.tryParse(json['min_stock_alert']?.toString() ?? '5') ?? 5.0,
      imageUrl: json['image_url']?.toString(),
      isOneSet: json['is_one_set'] != null ? int.tryParse(json['is_one_set'].toString()) ?? 0 : 0,
      productStatus: json['product_status']?.toString() ?? 'AVAILABLE',
      isActive: json['is_active'] != null ? int.tryParse(json['is_active'].toString()) ?? 1 : 1,
      syncStatus: json['sync_status'] != null ? int.tryParse(json['sync_status'].toString()) ?? 1 : 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'category_id': categoryId,
      'barcode': barcode,
      'name': name,
      'fabric_type': fabricType,
      'size': size,
      'color': color,
      'unit': unit,
      'cost_price': costPrice,
      'retail_price': retailPrice,
      'wholesale_price': wholesalePrice,
      'min_wholesale_qty': minWholesaleQty,
      'stock_qty': stockQty,
      'min_stock_alert': minStockAlert,
      'image_url': imageUrl,
      'is_one_set': isOneSet,
      'product_status': productStatus,
      'is_active': isActive,
      'sync_status': syncStatus,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
