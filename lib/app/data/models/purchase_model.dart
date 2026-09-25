import 'package:get/get.dart';

class PurchaseItemModel {
  final String id;
  final String purchaseId;
  final String productId;
  final String productName;
  final String unit;
  final double costPrice;
  final double quantity; // Represents effective current quantity or received qty
  final double orderedQuantity;
  final double receivedQuantity;
  final double rejectedQuantity;
  final double subtotal;
  final String status; // 'ORDERED', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED'
  final String? customerOrderId;
  final String? customerOrderNo;
  final int syncStatus;
  final String? createdAt;

  PurchaseItemModel({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    this.unit = 'piece',
    required this.costPrice,
    required this.quantity,
    double? orderedQuantity,
    double? receivedQuantity,
    this.rejectedQuantity = 0.0,
    required this.subtotal,
    this.status = 'RECEIVED',
    this.customerOrderId,
    this.customerOrderNo,
    this.syncStatus = 0,
    this.createdAt,
  })  : orderedQuantity = orderedQuantity ?? quantity,
        receivedQuantity = receivedQuantity ?? (status == 'ORDERED' ? 0.0 : quantity);

  double get remainingQuantity {
    final rem = orderedQuantity - receivedQuantity - rejectedQuantity;
    return rem > 0 ? rem : 0.0;
  }

  PurchaseItemModel copyWith({
    String? id,
    String? purchaseId,
    String? productId,
    String? productName,
    String? unit,
    double? costPrice,
    double? quantity,
    double? orderedQuantity,
    double? receivedQuantity,
    double? rejectedQuantity,
    double? subtotal,
    String? status,
    String? customerOrderId,
    String? customerOrderNo,
    int? syncStatus,
    String? createdAt,
  }) {
    return PurchaseItemModel(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      orderedQuantity: orderedQuantity ?? this.orderedQuantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      rejectedQuantity: rejectedQuantity ?? this.rejectedQuantity,
      subtotal: subtotal ?? this.subtotal,
      status: status ?? this.status,
      customerOrderId: customerOrderId ?? this.customerOrderId,
      customerOrderNo: customerOrderNo ?? this.customerOrderNo,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    final qty = json['quantity'] is num
        ? (json['quantity'] as num).toDouble()
        : double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0;
    final ordQty = json['ordered_quantity'] is num
        ? (json['ordered_quantity'] as num).toDouble()
        : double.tryParse(json['ordered_quantity']?.toString() ?? '') ?? qty;
    final recQty = json['received_quantity'] is num
        ? (json['received_quantity'] as num).toDouble()
        : double.tryParse(json['received_quantity']?.toString() ?? '') ??
            (json['status'] == 'ORDERED' ? 0.0 : qty);
    final rejQty = json['rejected_quantity'] is num
        ? (json['rejected_quantity'] as num).toDouble()
        : double.tryParse(json['rejected_quantity']?.toString() ?? '0') ?? 0.0;

    return PurchaseItemModel(
      id: json['id']?.toString() ?? '',
      purchaseId: json['purchase_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'piece',
      costPrice: json['cost_price'] is num
          ? (json['cost_price'] as num).toDouble()
          : double.tryParse(json['cost_price']?.toString() ?? '0') ?? 0.0,
      quantity: qty,
      orderedQuantity: ordQty,
      receivedQuantity: recQty,
      rejectedQuantity: rejQty,
      subtotal: json['subtotal'] is num
          ? (json['subtotal'] as num).toDouble()
          : double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'RECEIVED',
      customerOrderId: json['customer_order_id']?.toString(),
      customerOrderNo: json['customer_order_no']?.toString(),
      syncStatus: json['sync_status'] is int
          ? json['sync_status']
          : int.tryParse(json['sync_status']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'product_name': productName,
      'unit': unit,
      'cost_price': costPrice,
      'quantity': quantity,
      'ordered_quantity': orderedQuantity,
      'received_quantity': receivedQuantity,
      'rejected_quantity': rejectedQuantity,
      'subtotal': subtotal,
      'status': status,
      'customer_order_id': customerOrderId,
      'customer_order_no': customerOrderNo,
      'sync_status': syncStatus,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}

class PurchaseModel {
  final String id;
  final String businessId;
  final String invoiceNo;
  final String? supplierId;
  final String? supplierName;
  final String? userId;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String paymentMethod;
  final String status; // 'ORDERED', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED'
  final String? expectedDeliveryDate;
  final String? lastFollowUpDate;
  final String? followUpNotes;
  final String? notes;
  final String purchaseDate;
  final int syncStatus;
  final String? createdAt;
  final String? updatedAt;
  final List<PurchaseItemModel> items;

  PurchaseModel({
    required this.id,
    this.businessId = 'default_biz',
    required this.invoiceNo,
    this.supplierId,
    this.supplierName,
    this.userId,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.dueAmount = 0.0,
    this.paymentMethod = 'cash',
    this.status = 'RECEIVED',
    this.expectedDeliveryDate,
    this.lastFollowUpDate,
    this.followUpNotes,
    this.notes,
    required this.purchaseDate,
    this.syncStatus = 0,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  bool get isOverdue {
    if (status != 'ORDERED' && status != 'PARTIALLY_RECEIVED') return false;
    if (expectedDeliveryDate == null || expectedDeliveryDate!.isEmpty) return false;
    final exp = DateTime.tryParse(expectedDeliveryDate!);
    if (exp == null) return false;
    return exp.isBefore(DateTime.now());
  }

  bool get isPendingDelivery => status == 'ORDERED' || status == 'PARTIALLY_RECEIVED';

  String get statusLabel {
    final isEn = Get.locale?.languageCode == 'en';
    switch (status) {
      case 'ORDERED':
        return isEn ? 'Ordered' : 'မှာယူထားဆဲ';
      case 'PARTIALLY_RECEIVED':
        return isEn ? 'Partially Received' : 'တစ်စိတ်တစ်ပိုင်းရရှိ';
      case 'RECEIVED':
        return isEn ? 'Received' : 'လက်ခံရရှိပြီး';
      case 'CANCELLED':
        return isEn ? 'Cancelled' : 'ပယ်ဖျက်';
      default:
        return status;
    }
  }

  PurchaseModel copyWith({
    String? id,
    String? businessId,
    String? invoiceNo,
    String? supplierId,
    String? supplierName,
    String? userId,
    double? totalAmount,
    double? paidAmount,
    double? dueAmount,
    String? paymentMethod,
    String? status,
    String? expectedDeliveryDate,
    String? lastFollowUpDate,
    String? followUpNotes,
    String? notes,
    String? purchaseDate,
    int? syncStatus,
    String? createdAt,
    String? updatedAt,
    List<PurchaseItemModel>? items,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      userId: userId ?? this.userId,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      lastFollowUpDate: lastFollowUpDate ?? this.lastFollowUpDate,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      notes: notes ?? this.notes,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    var itemsList = <PurchaseItemModel>[];
    if (json['items'] != null && json['items'] is List) {
      itemsList = (json['items'] as List)
          .map((i) => PurchaseItemModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }

    return PurchaseModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      invoiceNo: json['invoice_no']?.toString() ?? '',
      supplierId: json['supplier_id']?.toString(),
      supplierName: json['supplier_name']?.toString(),
      userId: json['user_id']?.toString(),
      totalAmount: json['total_amount'] is num
          ? (json['total_amount'] as num).toDouble()
          : double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paidAmount: json['paid_amount'] is num
          ? (json['paid_amount'] as num).toDouble()
          : double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      dueAmount: json['due_amount'] is num
          ? (json['due_amount'] as num).toDouble()
          : double.tryParse(json['due_amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      status: json['status']?.toString() ?? 'RECEIVED',
      expectedDeliveryDate: json['expected_delivery_date']?.toString(),
      lastFollowUpDate: json['last_follow_up_date']?.toString(),
      followUpNotes: json['follow_up_notes']?.toString(),
      notes: json['notes']?.toString(),
      purchaseDate: json['purchase_date']?.toString() ?? DateTime.now().toIso8601String(),
      syncStatus: json['sync_status'] is int
          ? json['sync_status']
          : int.tryParse(json['sync_status']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      items: itemsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'invoice_no': invoiceNo,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'user_id': userId,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'payment_method': paymentMethod,
      'status': status,
      'expected_delivery_date': expectedDeliveryDate,
      'last_follow_up_date': lastFollowUpDate,
      'follow_up_notes': followUpNotes,
      'notes': notes,
      'purchase_date': purchaseDate,
      'sync_status': syncStatus,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }
}
