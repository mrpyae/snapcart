import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/delivery_service_model.dart';
import '../models/delivery_payment_model.dart';
import 'db_helper.dart';

class DeliveryServiceDao {
  final dbHelper = DBHelper.instance;

  // Retrieve delivery services with optional search and active filter
  Future<List<DeliveryServiceModel>> getDeliveryServices({
    String? query,
    bool activeOnly = false,
    String businessId = 'default_biz',
  }) async {
    final db = await dbHelper.database;
    String whereClause = 'business_id = ?';
    List<dynamic> whereArgs = [businessId];

    if (activeOnly) {
      whereClause += ' AND is_active = 1';
    }

    if (query != null && query.trim().isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR phone LIKE ? OR coverage_area LIKE ? OR contact_person LIKE ?)';
      final q = '%${query.trim()}%';
      whereArgs.addAll([q, q, q, q]);
    }

    final res = await db.query(
      'delivery_services',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return res.map((e) => DeliveryServiceModel.fromJson(e)).toList();
  }

  // Get active delivery services for dropdowns
  Future<List<DeliveryServiceModel>> getActiveDeliveryServices({String businessId = 'default_biz'}) async {
    return getDeliveryServices(activeOnly: true, businessId: businessId);
  }

  // Get a single delivery service by ID
  Future<DeliveryServiceModel?> getDeliveryServiceById(String id) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'delivery_services',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return DeliveryServiceModel.fromJson(res.first);
    }
    return null;
  }

  // Save or update delivery service
  Future<void> saveDeliveryService(DeliveryServiceModel service) async {
    final db = await dbHelper.database;
    await db.insert(
      'delivery_services',
      service.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete delivery service
  Future<void> deleteDeliveryService(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'delivery_services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Adjust outstanding COD receivable balance
  Future<void> adjustReceivable(String serviceId, double deltaAmount) async {
    final db = await dbHelper.database;
    await db.rawUpdate(
      'UPDATE delivery_services SET receivable_balance = MAX(0.0, receivable_balance + ?), sync_status = 0, updated_at = ? WHERE id = ?',
      [deltaAmount, DateTime.now().toIso8601String(), serviceId],
    );
  }

  // Record a payment / remittance from delivery service back to the shop
  Future<void> recordDeliveryPayment(DeliveryPaymentModel payment) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        'delivery_payments',
        payment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Deduct payment amount from delivery service receivable balance
      await txn.rawUpdate(
        'UPDATE delivery_services SET receivable_balance = MAX(0.0, receivable_balance - ?), sync_status = 0, updated_at = ? WHERE id = ?',
        [payment.amount, DateTime.now().toIso8601String(), payment.deliveryServiceId],
      );
    });
  }

  // Get payment history for a specific delivery service
  Future<List<DeliveryPaymentModel>> getDeliveryPayments(String deliveryServiceId) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'delivery_payments',
      where: 'delivery_service_id = ?',
      whereArgs: [deliveryServiceId],
      orderBy: 'payment_date DESC',
    );
    return res.map((e) => DeliveryPaymentModel.fromJson(e)).toList();
  }

  // Calculate total outstanding COD receivables across all couriers
  Future<double> getTotalReceivableBalance({String businessId = 'default_biz'}) async {
    final db = await dbHelper.database;
    final res = await db.rawQuery(
      'SELECT SUM(receivable_balance) as total FROM delivery_services WHERE business_id = ? AND is_active = 1',
      [businessId],
    );
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // Batch save for Delta Sync
  Future<void> batchSaveDeliveryServices(List<dynamic> list) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var item in list) {
      var map = Map<String, dynamic>.from(item);
      map['sync_status'] = 1;
      batch.insert(
        'delivery_services',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> batchSaveDeliveryPayments(List<dynamic> list) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var item in list) {
      var map = Map<String, dynamic>.from(item);
      map['sync_status'] = 1;
      batch.insert(
        'delivery_payments',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Get In-House delivery income and rider commission summary
  Future<Map<String, dynamic>> getInHouseDeliveryIncomeSummary({
    String businessId = 'default_biz',
    String? riderId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await dbHelper.database;
    String whereClause = "s.delivery_service_id IN (SELECT id FROM delivery_services WHERE service_type = 'IN_HOUSE') AND (s.business_id = ? OR s.business_id = 'default_biz')";
    List<dynamic> whereArgs = [businessId];

    if (riderId != null && riderId.isNotEmpty) {
      whereClause += ' AND s.delivery_service_id = ?';
      whereArgs.add(riderId);
    }
    if (startDate != null) {
      whereClause += ' AND s.sale_date >= ?';
      whereArgs.add(startDate.toIso8601String().substring(0, 10));
    }
    if (endDate != null) {
      whereClause += ' AND s.sale_date <= ?';
      whereArgs.add('${endDate.toIso8601String().substring(0, 10)}T23:59:59.999');
    }

    final res = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_trips,
        SUM(s.delivery_fee) as total_delivery_income,
        SUM(s.rider_commission_amount) as total_rider_commission
      FROM sales_orders s
      WHERE $whereClause
    ''', whereArgs);

    final orders = await db.rawQuery('''
      SELECT s.id, s.voucher_no, s.sale_date, c.name as customer_name, s.delivery_service_id, s.delivery_service_name,
             s.delivery_fee, s.rider_commission_amount, s.is_cod, s.cod_amount
      FROM sales_orders s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE $whereClause
      ORDER BY s.sale_date DESC
    ''', whereArgs);

    double totalIncome = 0.0;
    double totalCommission = 0.0;
    int trips = 0;

    if (res.isNotEmpty) {
      trips = int.tryParse(res.first['total_trips']?.toString() ?? '0') ?? 0;
      totalIncome = double.tryParse(res.first['total_delivery_income']?.toString() ?? '0') ?? 0.0;
      totalCommission = double.tryParse(res.first['total_rider_commission']?.toString() ?? '0') ?? 0.0;
    }

    return {
      'total_trips': trips,
      'total_delivery_income': totalIncome,
      'total_rider_commission': totalCommission,
      'net_delivery_income': totalIncome - totalCommission,
      'orders': orders,
    };
  }
}
