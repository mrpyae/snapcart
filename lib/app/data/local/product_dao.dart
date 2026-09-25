import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/product_model.dart';
import 'db_helper.dart';

class ProductDao {
  final dbHelper = DBHelper.instance;

  Future<void> insertOrUpdateProduct(ProductModel product) async {
    final db = await dbHelper.database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> batchSaveProducts(List<dynamic> products) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var p in products) {
      final model = ProductModel.fromJson(Map<String, dynamic>.from(p));
      batch.insert(
        'products',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ProductModel>> searchProducts({String query = '', String? categoryId, String? businessId}) async {
    final db = await dbHelper.database;
    String whereClause = 'is_active = 1';
    List<dynamic> whereArgs = [];

    if (businessId != null && businessId.isNotEmpty && businessId != 'default_biz') {
      whereClause += ' AND (business_id = ? OR business_id = "default_biz")';
      whereArgs.add(businessId);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    if (query.isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR barcode LIKE ? OR fabric_type LIKE ? OR color LIKE ?)';
      final q = '%$query%';
      whereArgs.addAll([q, q, q, q]);
    }

    final res = await db.query(
      'products',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    return res.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<ProductModel?> getProductByBarcode(String barcode, {String businessId = 'default_biz'}) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return ProductModel.fromJson(res.first);
    }
    return null;
  }

  Future<ProductModel?> getProductById(String id) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return ProductModel.fromJson(res.first);
    }
    return null;
  }
}
