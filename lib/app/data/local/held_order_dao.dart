import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/held_order_model.dart';
import 'db_helper.dart';

class HeldOrderDao {
  final dbHelper = DBHelper.instance;

  Future<void> saveHeldOrder(HeldOrderModel order) async {
    final db = await dbHelper.database;
    await db.insert(
      'held_orders',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HeldOrderModel>> getHeldOrders({String? businessId}) async {
    final db = await dbHelper.database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (businessId != null && businessId.isNotEmpty && businessId != 'default_biz') {
      whereClause += ' AND (business_id = ? OR business_id = "default_biz")';
      whereArgs.add(businessId);
    }

    final res = await db.query(
      'held_orders',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return res.map((e) => HeldOrderModel.fromJson(e)).toList();
  }

  Future<HeldOrderModel?> getHeldOrderById(String id) async {
    final db = await dbHelper.database;
    final res = await db.query('held_orders', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isNotEmpty) {
      return HeldOrderModel.fromJson(res.first);
    }
    return null;
  }

  Future<void> deleteHeldOrder(String id) async {
    final db = await dbHelper.database;
    await db.delete('held_orders', where: 'id = ?', whereArgs: [id]);
  }
}
