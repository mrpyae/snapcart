class ExpenseModel {
  final String id;
  final String businessId;
  final String category;
  final double amount;
  final String userId;
  final String paymentMethod;
  final String expenseDate;
  final String? description;
  final int syncStatus;

  ExpenseModel({
    required this.id,
    this.businessId = 'default_biz',
    required this.category,
    required this.amount,
    required this.userId,
    this.paymentMethod = 'cash',
    required this.expenseDate,
    this.description,
    this.syncStatus = 0,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      category: json['category']?.toString() ?? 'General',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      userId: json['user_id']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      expenseDate: json['expense_date']?.toString() ?? DateTime.now().toIso8601String(),
      description: json['description']?.toString(),
      syncStatus: json['sync_status'] != null ? int.tryParse(json['sync_status'].toString()) ?? 0 : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'category': category,
      'amount': amount,
      'user_id': userId,
      'payment_method': paymentMethod,
      'expense_date': expenseDate,
      'description': description,
      'sync_status': syncStatus,
    };
  }
}
