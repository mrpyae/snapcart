class DeliveryPaymentModel {
  final String id;
  final String businessId;
  final String deliveryServiceId;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String? notes;
  final int syncStatus;
  final String? createdAt;

  DeliveryPaymentModel({
    required this.id,
    this.businessId = 'default_biz',
    required this.deliveryServiceId,
    required this.amount,
    this.paymentMethod = 'cash',
    required this.paymentDate,
    this.notes,
    this.syncStatus = 0,
    this.createdAt,
  });

  factory DeliveryPaymentModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPaymentModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      deliveryServiceId: json['delivery_service_id']?.toString() ?? '',
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      paymentDate: json['payment_date']?.toString() ?? DateTime.now().toIso8601String(),
      notes: json['notes']?.toString(),
      syncStatus: json['sync_status'] is int
          ? json['sync_status']
          : int.tryParse(json['sync_status']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'delivery_service_id': deliveryServiceId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate,
      'notes': notes,
      'sync_status': syncStatus,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}
