import 'dart:convert';

class HeldOrderItemModel {
  final String productId;
  final String productName;
  final String unit;
  final double quantity;
  final double price;
  final bool isPriceOverridden;

  HeldOrderItemModel({
    required this.productId,
    required this.productName,
    this.unit = 'piece',
    required this.quantity,
    required this.price,
    this.isPriceOverridden = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unit': unit,
      'quantity': quantity,
      'price': price,
      'isPriceOverridden': isPriceOverridden,
    };
  }

  factory HeldOrderItemModel.fromMap(Map<String, dynamic> map) {
    return HeldOrderItemModel(
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      unit: map['unit']?.toString() ?? 'piece',
      quantity: double.tryParse(map['quantity']?.toString() ?? '1') ?? 1.0,
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      isPriceOverridden: map['isPriceOverridden'] == true || map['isPriceOverridden'] == 1,
    );
  }
}

class HeldOrderModel {
  final String id;
  final String businessId;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final List<HeldOrderItemModel> items;
  final double subtotal;
  final double discount;
  final double taxRate;
  final double deliveryFee;
  final double grandTotal;
  final String? notes;
  final String createdAt;

  HeldOrderModel({
    required this.id,
    this.businessId = 'default_biz',
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.taxRate = 0.0,
    this.deliveryFee = 0.0,
    required this.grandTotal,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'cart_json': jsonEncode(items.map((i) => i.toMap()).toList()),
      'subtotal': subtotal,
      'discount': discount,
      'tax_rate': taxRate,
      'delivery_fee': deliveryFee,
      'grand_total': grandTotal,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory HeldOrderModel.fromJson(Map<String, dynamic> json) {
    List<HeldOrderItemModel> parsedItems = [];
    if (json['cart_json'] != null && json['cart_json'].toString().isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(json['cart_json'].toString());
        parsedItems = list.map((e) => HeldOrderItemModel.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    return HeldOrderModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      customerId: json['customer_id']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      items: parsedItems,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      taxRate: double.tryParse(json['tax_rate']?.toString() ?? '0') ?? 0.0,
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0.0,
      grandTotal: double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0.0,
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}
