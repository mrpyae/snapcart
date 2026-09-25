import 'package:intl/intl.dart';

class ItemPriceHistoryModel {
  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  final double quantity;
  final String unit;
  final double total;
  final String? saleOrderId;
  final String voucherNo;
  final String saleDate;
  final String paymentMethod;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String sourceType; // 'POS_SALE' or 'CUSTOM_ORDER'

  ItemPriceHistoryModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.unit = 'piece',
    required this.total,
    this.saleOrderId,
    required this.voucherNo,
    required this.saleDate,
    this.paymentMethod = 'cash',
    this.customerId,
    this.customerName = 'Walk-in Customer',
    this.customerPhone = '',
    this.sourceType = 'POS_SALE',
  });

  factory ItemPriceHistoryModel.fromMap(Map<String, dynamic> map) {
    return ItemPriceHistoryModel(
      id: map['id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '',
      productName: map['product_name']?.toString() ?? '',
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit']?.toString() ?? 'piece',
      total: (map['total'] as num?)?.toDouble() ?? (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      saleOrderId: map['sale_order_id']?.toString() ?? map['customer_order_id']?.toString(),
      voucherNo: map['voucher_no']?.toString() ?? map['order_no']?.toString() ?? 'N/A',
      saleDate: map['sale_date']?.toString() ?? map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      paymentMethod: map['payment_method']?.toString() ?? 'cash',
      customerId: map['customer_id']?.toString(),
      customerName: map['customer_name']?.toString() ?? 'Walk-in Customer',
      customerPhone: map['customer_phone']?.toString() ?? '',
      sourceType: map['source_type']?.toString() ?? 'POS_SALE',
    );
  }

  DateTime get parsedDate {
    try {
      return DateTime.parse(saleDate);
    } catch (_) {
      return DateTime.now();
    }
  }

  String get formattedDate {
    try {
      return DateFormat('yyyy-MM-dd hh:mm a').format(parsedDate);
    } catch (_) {
      return saleDate;
    }
  }

  String get shortDate {
    try {
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (_) {
      return saleDate;
    }
  }
}
