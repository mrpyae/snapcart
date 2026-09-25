class CustomerModel {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? address;
  final String customerType; // retail, wholesale, vip
  final double creditLimit;
  final double currentDebt;
  final double advanceBalance; // Advance payments / Customer AP
  final int syncStatus;

  CustomerModel({
    required this.id,
    this.businessId = 'default_biz',
    required this.name,
    this.phone,
    this.address,
    this.customerType = 'retail',
    this.creditLimit = 0.0,
    this.currentDebt = 0.0,
    this.advanceBalance = 0.0,
    this.syncStatus = 1,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      customerType: json['customer_type']?.toString() ?? 'retail',
      creditLimit: double.tryParse(json['credit_limit']?.toString() ?? '0') ?? 0.0,
      currentDebt: double.tryParse(json['current_debt']?.toString() ?? '0') ?? 0.0,
      advanceBalance: double.tryParse(json['advance_balance']?.toString() ?? '0') ?? 0.0,
      syncStatus: json['sync_status'] != null ? int.tryParse(json['sync_status'].toString()) ?? 1 : 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'phone': phone,
      'address': address,
      'customer_type': customerType,
      'credit_limit': creditLimit,
      'current_debt': currentDebt,
      'advance_balance': advanceBalance,
      'sync_status': syncStatus,
    };
  }
}
