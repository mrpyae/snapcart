import 'package:intl/intl.dart';

class ProductSupplierModel {
  final String supplierId;
  final String supplierName;
  final String? companyName;
  final String? phone;
  final String? address;
  final double lastCostPrice;
  final String? lastPurchaseDate;
  final double totalSuppliedQty;
  final String unit;
  final double totalSpend;
  final int invoiceCount;
  final bool isPreferred;

  ProductSupplierModel({
    required this.supplierId,
    required this.supplierName,
    this.companyName,
    this.phone,
    this.address,
    this.lastCostPrice = 0.0,
    this.lastPurchaseDate,
    this.totalSuppliedQty = 0.0,
    this.unit = 'piece',
    this.totalSpend = 0.0,
    this.invoiceCount = 0,
    this.isPreferred = false,
  });

  factory ProductSupplierModel.fromMap(Map<String, dynamic> map) {
    return ProductSupplierModel(
      supplierId: map['supplier_id']?.toString() ?? '',
      supplierName: map['supplier_name']?.toString() ?? 'Unknown Supplier',
      companyName: map['company_name']?.toString(),
      phone: map['phone']?.toString(),
      address: map['address']?.toString(),
      lastCostPrice: (map['last_cost_price'] as num?)?.toDouble() ?? 0.0,
      lastPurchaseDate: map['last_purchase_date']?.toString(),
      totalSuppliedQty: (map['total_supplied_qty'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? 'piece',
      totalSpend: (map['total_spend'] as num?)?.toDouble() ?? 0.0,
      invoiceCount: (map['invoice_count'] as num?)?.toInt() ?? 0,
      isPreferred: (map['is_preferred'] == 1 || map['is_preferred'] == true),
    );
  }

  String get formattedLastPurchaseDate {
    if (lastPurchaseDate == null || lastPurchaseDate!.isEmpty) return 'No purchase recorded';
    try {
      final dt = DateTime.parse(lastPurchaseDate!);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return lastPurchaseDate!;
    }
  }

  String get displayName {
    if (companyName != null && companyName!.trim().isNotEmpty) {
      return '$supplierName ($companyName)';
    }
    return supplierName;
  }
}
