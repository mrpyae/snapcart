class DeliveryServiceModel {
  final String id;
  final String businessId;
  final String name;
  final String serviceType; // 'EXTERNAL' or 'IN_HOUSE'
  final String riderType; // 'SALARY' or 'COMMISSION'
  final String commissionType; // 'PERCENT' or 'FIXED'
  final double commissionVal;
  final double defaultDeliveryFee;
  final String? phone;
  final String? contactPerson;
  final double baseFee;
  final String? coverageArea;
  final double receivableBalance;
  final String? notes;
  final bool isActive;
  final int syncStatus;
  final String? createdAt;
  final String? updatedAt;

  DeliveryServiceModel({
    required this.id,
    this.businessId = 'default_biz',
    required this.name,
    this.serviceType = 'EXTERNAL',
    this.riderType = 'SALARY',
    this.commissionType = 'PERCENT',
    this.commissionVal = 0.0,
    this.defaultDeliveryFee = 0.0,
    this.phone,
    this.contactPerson,
    this.baseFee = 0.0,
    this.coverageArea,
    this.receivableBalance = 0.0,
    this.notes,
    this.isActive = true,
    this.syncStatus = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isInHouse => serviceType == 'IN_HOUSE';
  bool get isCommissionBased => isInHouse && riderType == 'COMMISSION';

  double calculateCommission(double deliveryFee) {
    if (!isCommissionBased || deliveryFee <= 0) return 0.0;
    if (commissionType == 'PERCENT') {
      return (deliveryFee * commissionVal / 100.0).clamp(0.0, double.infinity);
    } else {
      return commissionVal.clamp(0.0, deliveryFee);
    }
  }

  factory DeliveryServiceModel.fromJson(Map<String, dynamic> json) {
    return DeliveryServiceModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      name: json['name']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? 'EXTERNAL',
      riderType: json['rider_type']?.toString() ?? 'SALARY',
      commissionType: json['commission_type']?.toString() ?? 'PERCENT',
      commissionVal: json['commission_val'] is num
          ? (json['commission_val'] as num).toDouble()
          : double.tryParse(json['commission_val']?.toString() ?? '0') ?? 0.0,
      defaultDeliveryFee: json['default_delivery_fee'] is num
          ? (json['default_delivery_fee'] as num).toDouble()
          : double.tryParse(json['default_delivery_fee']?.toString() ?? '0') ?? 0.0,
      phone: json['phone']?.toString(),
      contactPerson: json['contact_person']?.toString(),
      baseFee: json['base_fee'] is num
          ? (json['base_fee'] as num).toDouble()
          : double.tryParse(json['base_fee']?.toString() ?? '0') ?? 0.0,
      coverageArea: json['coverage_area']?.toString(),
      receivableBalance: json['receivable_balance'] is num
          ? (json['receivable_balance'] as num).toDouble()
          : double.tryParse(json['receivable_balance']?.toString() ?? '0') ?? 0.0,
      notes: json['notes']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1',
      syncStatus: json['sync_status'] is int
          ? json['sync_status']
          : int.tryParse(json['sync_status']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'service_type': serviceType,
      'rider_type': riderType,
      'commission_type': commissionType,
      'commission_val': commissionVal,
      'default_delivery_fee': defaultDeliveryFee,
      'phone': phone,
      'contact_person': contactPerson,
      'base_fee': baseFee,
      'coverage_area': coverageArea,
      'receivable_balance': receivableBalance,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'sync_status': syncStatus,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  DeliveryServiceModel copyWith({
    String? id,
    String? businessId,
    String? name,
    String? serviceType,
    String? riderType,
    String? commissionType,
    double? commissionVal,
    double? defaultDeliveryFee,
    String? phone,
    String? contactPerson,
    double? baseFee,
    String? coverageArea,
    double? receivableBalance,
    String? notes,
    bool? isActive,
    int? syncStatus,
    String? createdAt,
    String? updatedAt,
  }) {
    return DeliveryServiceModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      serviceType: serviceType ?? this.serviceType,
      riderType: riderType ?? this.riderType,
      commissionType: commissionType ?? this.commissionType,
      commissionVal: commissionVal ?? this.commissionVal,
      defaultDeliveryFee: defaultDeliveryFee ?? this.defaultDeliveryFee,
      phone: phone ?? this.phone,
      contactPerson: contactPerson ?? this.contactPerson,
      baseFee: baseFee ?? this.baseFee,
      coverageArea: coverageArea ?? this.coverageArea,
      receivableBalance: receivableBalance ?? this.receivableBalance,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
