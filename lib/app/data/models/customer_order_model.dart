import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerOrderItemModel {
  final String id;
  final String customerOrderId;
  final String? productId;
  final String itemName;
  final String? fabricType;
  final String? color;
  final String? supplierId;
  final String? supplierName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double subtotal;
  final String? designNotes;
  final int syncStatus;

  CustomerOrderItemModel({
    required this.id,
    required this.customerOrderId,
    this.productId,
    required this.itemName,
    this.fabricType,
    this.color,
    this.supplierId,
    this.supplierName,
    required this.quantity,
    this.unit = 'piece',
    required this.unitPrice,
    required this.subtotal,
    this.designNotes,
    this.syncStatus = 1,
  });

  factory CustomerOrderItemModel.fromJson(Map<String, dynamic> json) {
    return CustomerOrderItemModel(
      id: json['id']?.toString() ?? '',
      customerOrderId: json['customer_order_id']?.toString() ?? '',
      productId: json['product_id']?.toString(),
      itemName: json['item_name']?.toString() ?? '',
      fabricType: json['fabric_type']?.toString(),
      color: json['color']?.toString(),
      supplierId: json['supplier_id']?.toString(),
      supplierName: json['supplier_name']?.toString(),
      quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      unit: json['unit']?.toString() ?? 'piece',
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      designNotes: json['design_notes']?.toString(),
      syncStatus: json['sync_status'] != null ? int.tryParse(json['sync_status'].toString()) ?? 1 : 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_order_id': customerOrderId,
      'product_id': productId,
      'item_name': itemName,
      'fabric_type': fabricType,
      'color': color,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'design_notes': designNotes,
      'sync_status': syncStatus,
    };
  }
}

class CustomerOrderModel {
  final String id;
  final String orderNo;
  final String businessId;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String orderSource; // PHONE, VIBER, MESSENGER, TELEGRAM, TIKTOK, WALK_IN, OTHER
  final String? leadAccount; // e.g. "Main Page", "Personal Viber", "Sales Team 1"
  final String? appointmentDate; // ISO string e.g. 2026-08-30 14:00
  final String appointmentType; // LOOM_WEAVING, FABRIC_DELIVERY_IN, PACKING, DELIVERY
  final String? supplierId;
  final String? supplierName;
  final String? linkedPurchaseId;
  final String status; // PENDING, CONFIRMED, IN_PROGRESS, READY_FOR_PICKUP, COMPLETED, CANCELLED
  final double totalAmount;
  final double advanceAmount;
  final double dueAmount;
  final String paymentMethod;
  final String? notes;
  final double deliveryFee;
  final String deliveryType; // 'SELF_COLLECT', 'DELIVERY'
  final String? deliveryServiceId;
  final String? deliveryServiceName;
  final bool isCod;
  final double codAmount;
  final double riderCommissionAmount;
  final String deliveryStatus; // 'PENDING', 'SHIPPED', 'DELIVERED', 'RETURNED'
  final String codSettlementStatus; // 'PENDING', 'COLLECTED', 'REMITTED'
  final int syncStatus;
  final String createdAt;
  final String? updatedAt;
  final List<CustomerOrderItemModel> items;

  CustomerOrderModel({
    required this.id,
    required this.orderNo,
    this.businessId = 'default_biz',
    this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.orderSource = 'PHONE',
    this.leadAccount,
    this.appointmentDate,
    this.appointmentType = 'LOOM_WEAVING',
    this.supplierId,
    this.supplierName,
    this.linkedPurchaseId,
    this.status = 'PENDING',
    required this.totalAmount,
    this.advanceAmount = 0.0,
    this.dueAmount = 0.0,
    this.paymentMethod = 'cash',
    this.notes,
    this.deliveryFee = 0.0,
    this.deliveryType = 'SELF_COLLECT',
    this.deliveryServiceId,
    this.deliveryServiceName,
    this.isCod = false,
    this.codAmount = 0.0,
    this.riderCommissionAmount = 0.0,
    this.deliveryStatus = 'PENDING',
    this.codSettlementStatus = 'PENDING',
    this.syncStatus = 1,
    required this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  // Source Label Helper
  String get sourceLabel {
    switch (orderSource.toUpperCase()) {
      case 'MESSENGER':
        return 'Messenger';
      case 'VIBER':
        return 'Viber';
      case 'PHONE':
        return 'Phone';
      case 'TELEGRAM':
        return 'Telegram';
      case 'TIKTOK':
        return 'TikTok';
      case 'WALK_IN':
        return 'walk_in_customer'.tr;
      case 'OTHER':
      default:
        return 'Other';
    }
  }

  // Appointment Type Label Helper
  String get appointmentTypeLabel {
    final isEn = Get.locale?.languageCode == 'en';
    switch (appointmentType.toUpperCase()) {
      case 'LOOM_WEAVING':
        return isEn ? 'Loom Weaving' : 'ရက္ကန်းနှင့်ချိတ်ဆက်ခြင်း';
      case 'FABRIC_DELIVERY_IN':
        return isEn ? 'Fabric In Delivery' : 'အထည်လာပို့ခြင်း';
      case 'PACKING':
        return isEn ? 'Packing' : 'ပစ္စည်းထုတ်ပိုးခြင်း';
      case 'DELIVERY':
        return isEn ? 'Delivery' : 'ပို့ဆောင်ခြင်း';
      default:
        return appointmentType;
    }
  }

  // Status Label Helper
  String get statusLabel {
    final isEn = Get.locale?.languageCode == 'en';
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return isEn ? 'Confirmed' : 'အတည်ပြုပြီး';
      case 'IN_PROGRESS':
        return isEn ? 'In Progress' : 'ရက်လုပ်ဆဲ';
      case 'READY_FOR_PICKUP':
        return isEn ? 'Ready for Pickup' : 'လာယူရန်အသင့်';
      case 'COMPLETED':
        return isEn ? 'Completed' : 'အပြီးသတ်လွှဲပြောင်းပြီး';
      case 'CANCELLED':
        return isEn ? 'Cancelled' : 'ပယ်ဖျက်';
      case 'PENDING':
      default:
        return isEn ? 'Pending' : 'စောင့်ဆိုင်းဆဲ';
    }
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.amber.shade700;
      case 'READY_FOR_PICKUP':
        return Colors.teal;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.grey;
    }
  }

  factory CustomerOrderModel.fromJson(Map<String, dynamic> json, {List<CustomerOrderItemModel> items = const []}) {
    return CustomerOrderModel(
      id: json['id']?.toString() ?? '',
      orderNo: json['order_no']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? 'default_biz',
      customerId: json['customer_id']?.toString(),
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString(),
      customerAddress: json['customer_address']?.toString(),
      orderSource: json['order_source']?.toString() ?? 'PHONE',
      leadAccount: json['lead_account']?.toString(),
      appointmentDate: json['appointment_date']?.toString(),
      appointmentType: json['appointment_type']?.toString() ?? 'LOOM_WEAVING',
      supplierId: json['supplier_id']?.toString(),
      supplierName: json['supplier_name']?.toString(),
      linkedPurchaseId: json['linked_purchase_id']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      advanceAmount: double.tryParse(json['advance_amount']?.toString() ?? '0') ?? 0.0,
      dueAmount: double.tryParse(json['due_amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      notes: json['notes']?.toString(),
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0.0,
      deliveryType: json['delivery_type']?.toString() ?? 'SELF_COLLECT',
      deliveryServiceId: json['delivery_service_id']?.toString(),
      deliveryServiceName: json['delivery_service_name']?.toString(),
      isCod: json['is_cod'] == 1 || json['is_cod'] == true || json['is_cod'] == '1',
      codAmount: double.tryParse(json['cod_amount']?.toString() ?? '0') ?? 0.0,
      riderCommissionAmount: double.tryParse(json['rider_commission_amount']?.toString() ?? '0') ?? 0.0,
      deliveryStatus: json['delivery_status']?.toString() ?? 'PENDING',
      codSettlementStatus: json['cod_settlement_status']?.toString() ?? 'PENDING',
      syncStatus: json['sync_status'] != null ? int.tryParse(json['sync_status'].toString()) ?? 1 : 1,
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at']?.toString(),
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_no': orderNo,
      'business_id': businessId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'order_source': orderSource,
      'lead_account': leadAccount,
      'appointment_date': appointmentDate,
      'appointment_type': appointmentType,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'linked_purchase_id': linkedPurchaseId,
      'status': status,
      'total_amount': totalAmount,
      'advance_amount': advanceAmount,
      'due_amount': dueAmount,
      'payment_method': paymentMethod,
      'notes': notes,
      'delivery_fee': deliveryFee,
      'delivery_type': deliveryType,
      'delivery_service_id': deliveryServiceId,
      'delivery_service_name': deliveryServiceName,
      'is_cod': isCod ? 1 : 0,
      'cod_amount': codAmount,
      'rider_commission_amount': riderCommissionAmount,
      'delivery_status': deliveryStatus,
      'cod_settlement_status': codSettlementStatus,
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }
}
