class SupplierModel {
  final String id;
  final String businessId;
  final String? supplierCategoryId;
  final String? categoryName;
  final String name;
  final String? phone;
  final String? companyName;
  final String? address;
  final double payableBalance; // Amount we owe to supplier (AP)
  final double advanceBalance; // Advance payments / deposit to supplier (AR)
  final int isActive;
  final int syncStatus;
  final String? createdAt;
  final String? updatedAt;

  SupplierModel({
    required this.id,
    this.businessId = 'default_biz',
    this.supplierCategoryId,
    this.categoryName,
    required this.name,
    this.phone,
    this.companyName,
    this.address,
    this.payableBalance = 0.0,
    this.advanceBalance = 0.0,
    this.isActive = 1,
    this.syncStatus = 0,
    this.createdAt,
    this.updatedAt,
  });

  // Net Balance calculation
  double get netBalance => advanceBalance - payableBalance;
  bool get hasDebt => payableBalance > advanceBalance;
  bool get hasCredit => advanceBalance > payableBalance;

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      supplierCategoryId: json['supplier_category_id']?.toString(),
      categoryName: json['category_name']?.toString() ?? json['supplier_category_name']?.toString(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      companyName: json['company_name']?.toString(),
      address: json['address']?.toString(),
      payableBalance: json['payable_balance'] is num ? (json['payable_balance'] as num).toDouble() : double.tryParse(json['payable_balance']?.toString() ?? '0') ?? 0.0,
      advanceBalance: json['advance_balance'] is num ? (json['advance_balance'] as num).toDouble() : double.tryParse(json['advance_balance']?.toString() ?? '0') ?? 0.0,
      isActive: json['is_active'] is int ? json['is_active'] : int.tryParse(json['is_active']?.toString() ?? '1') ?? 1,
      syncStatus: json['sync_status'] is int ? json['sync_status'] : int.tryParse(json['sync_status']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'supplier_category_id': supplierCategoryId,
      'name': name,
      'phone': phone,
      'company_name': companyName,
      'address': address,
      'payable_balance': payableBalance,
      'advance_balance': advanceBalance,
      'is_active': isActive,
      'sync_status': syncStatus,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
