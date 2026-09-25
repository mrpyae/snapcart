import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/supplier_category_model.dart';
import 'db_helper.dart';

class SupplierCategoryDao {
  final dbHelper = DBHelper.instance;

  Future<void> insertOrUpdateCategory(SupplierCategoryModel category) async {
    final db = await dbHelper.database;
    await db.insert(
      'supplier_categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> batchSaveCategories(List<dynamic> list) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var c in list) {
      final model = SupplierCategoryModel.fromJson(Map<String, dynamic>.from(c));
      batch.insert(
        'supplier_categories',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<SupplierCategoryModel>> getCategories({String? businessId}) async {
    final db = await dbHelper.database;
    String whereClause = 'is_active = 1';
    List<dynamic> whereArgs = [];

    if (businessId != null && businessId.isNotEmpty && businessId != 'default_biz') {
      whereClause += ' AND (business_id = ? OR business_id = "default_biz")';
      whereArgs.add(businessId);
    }

    final res = await db.query(
      'supplier_categories',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    return res.map((e) => SupplierCategoryModel.fromJson(e)).toList();
  }

  Future<SupplierCategoryModel?> getCategoryById(String id) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'supplier_categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return SupplierCategoryModel.fromJson(res.first);
    }
    return null;
  }

  Future<void> deleteCategory(String id) async {
    final db = await dbHelper.database;
    await db.update(
      'supplier_categories',
      {
        'is_active': 0,
        'sync_status': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
