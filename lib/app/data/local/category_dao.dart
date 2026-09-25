import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/category_model.dart';
import 'db_helper.dart';

class CategoryDao {
  final dbHelper = DBHelper.instance;

  Future<void> insertOrUpdateCategory(CategoryModel category) async {
    final db = await dbHelper.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> batchSaveCategories(List<dynamic> list) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var c in list) {
      final model = CategoryModel.fromJson(Map<String, dynamic>.from(c));
      batch.insert(
        'categories',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<CategoryModel>> getCategories({String? businessId}) async {
    final db = await dbHelper.database;
    String whereClause = 'is_active = 1';
    List<dynamic> whereArgs = [];

    if (businessId != null && businessId.isNotEmpty && businessId != 'default_biz') {
      whereClause += ' AND (business_id = ? OR business_id = "default_biz")';
      whereArgs.add(businessId);
    }

    final res = await db.query(
      'categories',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    return res.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final db = await dbHelper.database;
    final res = await db.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isNotEmpty) {
      return CategoryModel.fromJson(res.first);
    }
    return null;
  }
}
