class CategoryModel {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final int isActive;
  final int syncStatus;
  final String? createdAt;
  final String? updatedAt;

  CategoryModel({
    required this.id,
    this.businessId = 'default_biz',
    required this.name,
    this.description,
    this.isActive = 1,
    this.syncStatus = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
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
      'name': name,
      'description': description,
      'is_active': isActive,
      'sync_status': syncStatus,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }
}
