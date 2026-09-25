class SupplierPaymentModel {
  final String id;
  final String businessId;
  final String supplierId;
  final String? purchaseId;
  final double amount;
  final String type; // 'PAYMENT', 'ADVANCE', 'REFUND'
  final String paymentMethod;
  final String paymentDate;
  final String? notes;
  final int syncStatus;
  final String? createdAt;

  SupplierPaymentModel({
    required this.id,
    this.businessId = 'default_biz',
    required this.supplierId,
    this.purchaseId,
    required this.amount,
    this.type = 'PAYMENT',
    this.paymentMethod = 'cash',
    required this.paymentDate,
    this.notes,
    this.syncStatus = 0,
    this.createdAt,
  });

  factory SupplierPaymentModel.fromJson(Map<String, dynamic> json) {
    return SupplierPaymentModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      supplierId: json['supplier_id']?.toString() ?? '',
      purchaseId: json['purchase_id']?.toString(),
      amount: json['amount'] is num ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      type: json['type']?.toString() ?? 'PAYMENT',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      paymentDate: json['payment_date']?.toString() ?? DateTime.now().toIso8601String(),
      notes: json['notes']?.toString(),
      syncStatus: json['sync_status'] is int ? json['sync_status'] : int.tryParse(json['sync_status']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'supplier_id': supplierId,
      'purchase_id': purchaseId,
      'amount': amount,
      'type': type,
      'payment_method': paymentMethod,
      'payment_date': paymentDate,
      'notes': notes,
      'sync_status': syncStatus,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}
