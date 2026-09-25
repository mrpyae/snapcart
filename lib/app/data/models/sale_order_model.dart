class SaleOrderModel {
  final String id;
  final String businessId;
  final String voucherNo;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String userId;
  final String? userAccountId;
  final String userName;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double deliveryFee;
  final double grandTotal;
  final double paidAmount;
  final double changeAmount;
  final double dueAmount;
  final String paymentMethod;
  final String saleStatus;
  final String? notes;
  final String saleDate;
  final String deliveryType; // 'SELF_COLLECT', 'DELIVERY'
  final String? deliveryServiceId;
  final String? deliveryServiceName;
  final String? deliveryAddress;
  final String? trackingNo;
  final bool isCod;
  final double codAmount;
  final double riderCommissionAmount;
  final String deliveryStatus; // 'PENDING', 'SHIPPED', 'DELIVERED', 'RETURNED'
  final String codSettlementStatus; // 'PENDING', 'COLLECTED', 'REMITTED'
  final int syncStatus;
  final List<SaleOrderItemModel> items;

  SaleOrderModel({
    required this.id,
    this.businessId = 'default_biz',
    required this.voucherNo,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.userId,
    this.userAccountId,
    required this.userName,
    required this.subtotal,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.deliveryFee = 0.0,
    required this.grandTotal,
    required this.paidAmount,
    this.changeAmount = 0.0,
    this.dueAmount = 0.0,
    required this.paymentMethod,
    this.saleStatus = 'PAID',
    this.notes,
    required this.saleDate,
    this.deliveryType = 'SELF_COLLECT',
    this.deliveryServiceId,
    this.deliveryServiceName,
    this.deliveryAddress,
    this.trackingNo,
    this.isCod = false,
    this.codAmount = 0.0,
    this.riderCommissionAmount = 0.0,
    this.deliveryStatus = 'PENDING',
    this.codSettlementStatus = 'PENDING',
    this.syncStatus = 0,
    this.items = const [],
  });

  factory SaleOrderModel.fromJson(Map<String, dynamic> json, {List<SaleOrderItemModel> items = const []}) {
    var itemList = <SaleOrderItemModel>[];
    if (items.isNotEmpty) {
      itemList = items;
    } else if (json['items'] != null && json['items'] is List) {
      itemList = (json['items'] as List)
          .map((i) => SaleOrderItemModel.fromJson(i))
          .toList();
    }
    return SaleOrderModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      voucherNo: json['voucher_no']?.toString() ?? '',
      customerId: json['customer_id']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      userAccountId: json['user_account_id']?.toString(),
      userName: json['user_name']?.toString() ?? '',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0.0,
      grandTotal: double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0.0,
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      changeAmount: double.tryParse(json['change_amount']?.toString() ?? '0') ?? 0.0,
      dueAmount: double.tryParse(json['due_amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      saleStatus: json['sale_status']?.toString() ?? 'PAID',
      notes: json['notes']?.toString(),
      saleDate: json['sale_date']?.toString() ?? DateTime.now().toIso8601String(),
      deliveryType: json['delivery_type']?.toString() ?? 'SELF_COLLECT',
      deliveryServiceId: json['delivery_service_id']?.toString(),
      deliveryServiceName: json['delivery_service_name']?.toString(),
      deliveryAddress: json['delivery_address']?.toString(),
      trackingNo: json['tracking_no']?.toString(),
      isCod: json['is_cod'] == 1 || json['is_cod'] == true || json['is_cod'] == '1',
      codAmount: double.tryParse(json['cod_amount']?.toString() ?? '0') ?? 0.0,
      riderCommissionAmount: double.tryParse(json['rider_commission_amount']?.toString() ?? '0') ?? 0.0,
      deliveryStatus: json['delivery_status']?.toString() ?? 'PENDING',
      codSettlementStatus: json['cod_settlement_status']?.toString() ?? 'PENDING',
      syncStatus: json['sync_status'] != null ? int.tryParse(json['sync_status'].toString()) ?? 0 : 0,
      items: itemList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'voucher_no': voucherNo,
      'customer_id': customerId,
      'user_id': userId,
      'user_account_id': userAccountId,
      'user_name': userName,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'delivery_fee': deliveryFee,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'due_amount': dueAmount,
      'payment_method': paymentMethod,
      'sale_status': saleStatus,
      'notes': notes,
      'sale_date': saleDate,
      'delivery_type': deliveryType,
      'delivery_service_id': deliveryServiceId,
      'delivery_service_name': deliveryServiceName,
      'delivery_address': deliveryAddress,
      'tracking_no': trackingNo,
      'is_cod': isCod ? 1 : 0,
      'cod_amount': codAmount,
      'rider_commission_amount': riderCommissionAmount,
      'delivery_status': deliveryStatus,
      'cod_settlement_status': codSettlementStatus,
      'sync_status': syncStatus,
    };
  }
}

class SaleOrderItemModel {
  final String id;
  final String saleOrderId;
  final String productId;
  final String productName;
  final String unit;
  final double price;
  final double costPrice;
  final double quantity;
  final double discount;
  final double total;
  final int syncStatus;

  SaleOrderItemModel({
    required this.id,
    required this.saleOrderId,
    required this.productId,
    required this.productName,
    this.unit = 'piece',
    required this.price,
    this.costPrice = 0.0,
    required this.quantity,
    this.discount = 0.0,
    required this.total,
    this.syncStatus = 0,
  });

  double get unitPrice => price;
  double get subtotal => total;

  factory SaleOrderItemModel.fromJson(Map<String, dynamic> json) {
    return SaleOrderItemModel(
      id: json['id']?.toString() ?? '',
      saleOrderId: json['sale_order_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'piece',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      costPrice: double.tryParse(json['cost_price']?.toString() ?? '0') ?? 0.0,
      quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      syncStatus: json['sync_status'] != null ? int.tryParse(json['sync_status'].toString()) ?? 0 : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_order_id': saleOrderId,
      'product_id': productId,
      'product_name': productName,
      'unit': unit,
      'price': price,
      'cost_price': costPrice,
      'quantity': quantity,
      'discount': discount,
      'total': total,
      'sync_status': syncStatus,
    };
  }
}
