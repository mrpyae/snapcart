import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../models/supplier_model.dart';
import '../models/supplier_payment_model.dart';
import '../models/product_supplier_model.dart';
import 'db_helper.dart';

class SupplierDao {
  final dbHelper = DBHelper.instance;

  Future<void> insertOrUpdateSupplier(SupplierModel supplier) async {
    final db = await dbHelper.database;
    await db.insert(
      'suppliers',
      supplier.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> batchSaveSuppliers(List<dynamic> list) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var s in list) {
      final model = SupplierModel.fromJson(Map<String, dynamic>.from(s));
      batch.insert(
        'suppliers',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<SupplierModel>> getSuppliers({
    String query = '',
    String? businessId,
    String? categoryId,
  }) async {
    final db = await dbHelper.database;
    String whereClause = 's.is_active = 1';
    List<dynamic> whereArgs = [];

    if (businessId != null && businessId.isNotEmpty && businessId != 'default_biz') {
      whereClause += ' AND (s.business_id = ? OR s.business_id = "default_biz")';
      whereArgs.add(businessId);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      whereClause += ' AND s.supplier_category_id = ?';
      whereArgs.add(categoryId);
    }

    if (query.isNotEmpty) {
      whereClause += ' AND (s.name LIKE ? OR s.phone LIKE ? OR s.company_name LIKE ?)';
      final q = '%$query%';
      whereArgs.addAll([q, q, q]);
    }

    final res = await db.rawQuery('''
      SELECT s.*, sc.name AS category_name
      FROM suppliers s
      LEFT JOIN supplier_categories sc ON s.supplier_category_id = sc.id
      WHERE $whereClause
      ORDER BY s.name ASC
    ''', whereArgs);

    return res.map((e) => SupplierModel.fromJson(e)).toList();
  }

  Future<SupplierModel?> getSupplierById(String id) async {
    final db = await dbHelper.database;
    final res = await db.rawQuery('''
      SELECT s.*, sc.name AS category_name
      FROM suppliers s
      LEFT JOIN supplier_categories sc ON s.supplier_category_id = sc.id
      WHERE s.id = ?
      LIMIT 1
    ''', [id]);
    if (res.isNotEmpty) {
      return SupplierModel.fromJson(res.first);
    }
    return null;
  }

  // Adjust Supplier Payable/Advance balances
  Future<void> adjustSupplierBalance(String supplierId, {double payableDelta = 0.0, double advanceDelta = 0.0}) async {
    final db = await dbHelper.database;
    await db.rawUpdate(
      'UPDATE suppliers SET payable_balance = MAX(0.0, payable_balance + ?), advance_balance = MAX(0.0, advance_balance + ?), sync_status = 0, updated_at = ? WHERE id = ?',
      [payableDelta, advanceDelta, DateTime.now().toIso8601String(), supplierId],
    );
  }

  // Record a payment to supplier (Debt settlement or advance deposit)
  Future<void> recordSupplierPayment(SupplierPaymentModel payment) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        'supplier_payments',
        payment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (payment.type == 'PAYMENT') {
        // Settle payable debt
        await txn.rawUpdate(
          'UPDATE suppliers SET payable_balance = MAX(0.0, payable_balance - ?), sync_status = 0, updated_at = ? WHERE id = ?',
          [payment.amount, DateTime.now().toIso8601String(), payment.supplierId],
        );
      } else if (payment.type == 'ADVANCE') {
        // Increase advance balance
        await txn.rawUpdate(
          'UPDATE suppliers SET advance_balance = advance_balance + ?, sync_status = 0, updated_at = ? WHERE id = ?',
          [payment.amount, DateTime.now().toIso8601String(), payment.supplierId],
        );
      }
    });
  }

  Future<List<SupplierPaymentModel>> getSupplierPayments(String supplierId) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'supplier_payments',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'payment_date DESC',
    );
    return res.map((e) => SupplierPaymentModel.fromJson(e)).toList();
  }

  // Update an existing payment record and adjust supplier balances
  Future<void> updateSupplierPayment(SupplierPaymentModel updatedPayment) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final oldRows = await txn.query(
        'supplier_payments',
        where: 'id = ?',
        whereArgs: [updatedPayment.id],
        limit: 1,
      );
      if (oldRows.isEmpty) return;

      final oldPayment = SupplierPaymentModel.fromJson(oldRows.first);

      // 1. Revert old payment effect
      if (oldPayment.type == 'PAYMENT') {
        await txn.rawUpdate(
          'UPDATE suppliers SET payable_balance = payable_balance + ?, sync_status = 0, updated_at = ? WHERE id = ?',
          [oldPayment.amount, DateTime.now().toIso8601String(), oldPayment.supplierId],
        );
      } else if (oldPayment.type == 'ADVANCE') {
        await txn.rawUpdate(
          'UPDATE suppliers SET advance_balance = MAX(0.0, advance_balance - ?), sync_status = 0, updated_at = ? WHERE id = ?',
          [oldPayment.amount, DateTime.now().toIso8601String(), oldPayment.supplierId],
        );
      }

      // 2. Apply new payment effect
      if (updatedPayment.type == 'PAYMENT') {
        await txn.rawUpdate(
          'UPDATE suppliers SET payable_balance = MAX(0.0, payable_balance - ?), sync_status = 0, updated_at = ? WHERE id = ?',
          [updatedPayment.amount, DateTime.now().toIso8601String(), updatedPayment.supplierId],
        );
      } else if (updatedPayment.type == 'ADVANCE') {
        await txn.rawUpdate(
          'UPDATE suppliers SET advance_balance = advance_balance + ?, sync_status = 0, updated_at = ? WHERE id = ?',
          [updatedPayment.amount, DateTime.now().toIso8601String(), updatedPayment.supplierId],
        );
      }

      // 3. Update payment record
      await txn.update(
        'supplier_payments',
        updatedPayment.toMap(),
        where: 'id = ?',
        whereArgs: [updatedPayment.id],
      );
    });
  }

  /// Retrieve all suppliers providing a specific product with aggregated supply metrics
  Future<List<ProductSupplierModel>> getSuppliersForProduct(
    String productId, {
    String businessId = 'default_biz',
  }) async {
    final db = await dbHelper.database;

    // 1. Get explicit links from product_suppliers
    final links = await db.query(
      'product_suppliers',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    final Set<String> supplierIds = links.map((e) => e['supplier_id'].toString()).toSet();
    final Map<String, bool> preferredMap = {
      for (var e in links) e['supplier_id'].toString(): (e['is_preferred'] == 1)
    };

    // 2. Get purchase history suppliers for this product
    final purchaseRecords = await db.rawQuery('''
      SELECT 
        p.supplier_id,
        pi.cost_price,
        pi.quantity,
        pi.unit,
        pi.subtotal,
        p.purchase_date,
        p.id as purchase_id
      FROM purchase_items pi
      JOIN purchases p ON pi.purchase_id = p.id
      WHERE pi.product_id = ? AND p.supplier_id IS NOT NULL AND p.supplier_id != ''
      ORDER BY p.purchase_date DESC, pi.created_at DESC
    ''', [productId]);

    for (var r in purchaseRecords) {
      final sId = r['supplier_id']?.toString();
      if (sId != null && sId.isNotEmpty) {
        supplierIds.add(sId);
      }
    }

    if (supplierIds.isEmpty) return [];

    // 3. Load all matching suppliers
    final placeholders = List.filled(supplierIds.length, '?').join(',');
    final suppliersData = await db.rawQuery(
      'SELECT * FROM suppliers WHERE id IN ($placeholders)',
      supplierIds.toList(),
    );

    // 4. Compute aggregated supply stats per supplier
    final Map<String, double> lastCostMap = {};
    final Map<String, String> lastDateMap = {};
    final Map<String, double> totalQtyMap = {};
    final Map<String, String> unitMap = {};
    final Map<String, double> totalSpendMap = {};
    final Map<String, Set<String>> invoiceSetMap = {};

    for (var r in purchaseRecords) {
      final sId = r['supplier_id'].toString();
      final cost = (r['cost_price'] as num?)?.toDouble() ?? 0.0;
      final qty = (r['quantity'] as num?)?.toDouble() ?? 0.0;
      final subtotal = (r['subtotal'] as num?)?.toDouble() ?? (cost * qty);
      final date = r['purchase_date']?.toString();
      final unit = r['unit']?.toString() ?? 'piece';
      final purId = r['purchase_id']?.toString() ?? '';

      if (!lastCostMap.containsKey(sId)) {
        lastCostMap[sId] = cost;
        if (date != null) lastDateMap[sId] = date;
      }
      totalQtyMap[sId] = (totalQtyMap[sId] ?? 0.0) + qty;
      totalSpendMap[sId] = (totalSpendMap[sId] ?? 0.0) + subtotal;
      unitMap[sId] = unit;
      invoiceSetMap.putIfAbsent(sId, () => <String>{}).add(purId);
    }

    List<ProductSupplierModel> result = [];
    for (var s in suppliersData) {
      final sId = s['id'].toString();
      result.add(ProductSupplierModel(
        supplierId: sId,
        supplierName: s['name']?.toString() ?? '',
        companyName: s['company_name']?.toString(),
        phone: s['phone']?.toString(),
        address: s['address']?.toString(),
        lastCostPrice: lastCostMap[sId] ?? 0.0,
        lastPurchaseDate: lastDateMap[sId],
        totalSuppliedQty: totalQtyMap[sId] ?? 0.0,
        unit: unitMap[sId] ?? 'piece',
        totalSpend: totalSpendMap[sId] ?? 0.0,
        invoiceCount: invoiceSetMap[sId]?.length ?? 0,
        isPreferred: preferredMap[sId] ?? false,
      ));
    }

    result.sort((a, b) {
      if (a.isPreferred != b.isPreferred) {
        return a.isPreferred ? -1 : 1;
      }
      if (a.lastPurchaseDate != null && b.lastPurchaseDate != null) {
        return b.lastPurchaseDate!.compareTo(a.lastPurchaseDate!);
      }
      if (a.lastPurchaseDate != null) return -1;
      if (b.lastPurchaseDate != null) return 1;
      return a.supplierName.compareTo(b.supplierName);
    });

    return result;
  }

  /// Batch link suppliers to a product
  Future<void> linkProductSuppliers(
    String productId,
    List<String> supplierIds, {
    String? preferredSupplierId,
    String businessId = 'default_biz',
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('product_suppliers', where: 'product_id = ?', whereArgs: [productId]);
      final now = DateTime.now().toIso8601String();
      for (final sId in supplierIds) {
        await txn.insert('product_suppliers', {
          'id': const Uuid().v4(),
          'business_id': businessId,
          'product_id': productId,
          'supplier_id': sId,
          'is_preferred': (sId == preferredSupplierId) ? 1 : 0,
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Unlink a single supplier from a product
  Future<void> unlinkProductSupplier(String productId, String supplierId) async {
    final db = await dbHelper.database;
    await db.delete(
      'product_suppliers',
      where: 'product_id = ? AND supplier_id = ?',
      whereArgs: [productId, supplierId],
    );
  }
}

