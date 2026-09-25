import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/purchase_model.dart';
import 'db_helper.dart';

class PurchaseDao {
  final dbHelper = DBHelper.instance;

  // Save Purchase Order (either Direct Stock In 'RECEIVED' or Supplier Order 'ORDERED')
  Future<void> savePurchaseOrder(PurchaseModel purchase) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 1. Insert Purchase Record
      await txn.insert(
        'purchases',
        purchase.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final isDirectStockIn = purchase.status == 'RECEIVED';

      // 2. Insert Items & conditionally Increment Product Stock
      for (var item in purchase.items) {
        final itemMap = item.toMap();
        if (!isDirectStockIn) {
          // If it's a pending supplier order, received qty is 0.0 initially
          itemMap['received_quantity'] = item.receivedQuantity;
          itemMap['ordered_quantity'] = item.orderedQuantity;
          itemMap['status'] = item.status;
        }

        await txn.insert(
          'purchase_items',
          itemMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // ONLY Increment Product Stock Quantity & cost price if Direct Stock-In / Received!
        if (isDirectStockIn && item.quantity > 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock_qty = stock_qty + ?, cost_price = ?, sync_status = 0, updated_at = ? WHERE id = ?',
            [item.quantity, item.costPrice, DateTime.now().toIso8601String(), item.productId],
          );
        }
      }

      // 3. Update Supplier Payable Debt if direct stock-in and due > 0
      if (isDirectStockIn && purchase.dueAmount > 0 && purchase.supplierId != null && purchase.supplierId!.isNotEmpty) {
        await txn.rawUpdate(
          'UPDATE suppliers SET payable_balance = payable_balance + ?, sync_status = 0, updated_at = ? WHERE id = ?',
          [purchase.dueAmount, DateTime.now().toIso8601String(), purchase.supplierId],
        );
      }
    });
  }

  // Receive Goods / Stock-In (Full or Partial) against an existing Supplier Purchase Order
  Future<void> receivePurchaseItems({
    required String purchaseId,
    required List<Map<String, dynamic>> itemsReceived,
    bool cancelRemaining = false,
    double additionalPaid = 0.0,
    String? paymentMethod,
    String? receivingNotes,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 1. Fetch existing purchase and items
      final pRes = await txn.query('purchases', where: 'id = ?', whereArgs: [purchaseId]);
      if (pRes.isEmpty) return;
      final currentPurchase = PurchaseModel.fromJson(pRes.first);

      final itemsRes = await txn.query('purchase_items', where: 'purchase_id = ?', whereArgs: [purchaseId]);
      final existingItems = itemsRes.map((i) => PurchaseItemModel.fromJson(i)).toList();

      final nowStr = DateTime.now().toIso8601String();
      double totalReceivedAmount = 0.0;
      bool hasAnyPendingItem = false;

      // 2. Process each item receiving
      for (var item in existingItems) {
        final match = itemsReceived.firstWhere(
          (m) => m['itemId']?.toString() == item.id || m['productId']?.toString() == item.productId,
          orElse: () => {'receivedQty': 0.0},
        );

        final newlyReceivedQty = (match['receivedQty'] as num?)?.toDouble() ?? 0.0;
        final updatedReceivedQty = item.receivedQuantity + newlyReceivedQty;
        double updatedRejectedQty = item.rejectedQuantity;

        if (cancelRemaining) {
          final remaining = item.orderedQuantity - updatedReceivedQty - item.rejectedQuantity;
          if (remaining > 0) {
            updatedRejectedQty += remaining;
          }
        }

        // Determine item status
        String itemStatus;
        if (updatedReceivedQty >= item.orderedQuantity) {
          itemStatus = 'RECEIVED';
        } else if (updatedReceivedQty + updatedRejectedQty >= item.orderedQuantity) {
          itemStatus = updatedReceivedQty > 0 ? 'RECEIVED' : 'CANCELLED';
        } else if (updatedReceivedQty > 0) {
          itemStatus = 'PARTIALLY_RECEIVED';
          hasAnyPendingItem = true;
        } else {
          itemStatus = item.status;
          hasAnyPendingItem = true;
        }

        // Increment Product Stock for newly received quantity
        if (newlyReceivedQty > 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock_qty = stock_qty + ?, cost_price = ?, sync_status = 0, updated_at = ? WHERE id = ?',
            [newlyReceivedQty, item.costPrice, nowStr, item.productId],
          );
        }

        // Update purchase_item row
        final effectiveItemSubtotal = item.costPrice * (cancelRemaining ? updatedReceivedQty : item.orderedQuantity);
        totalReceivedAmount += item.costPrice * updatedReceivedQty;

        await txn.rawUpdate(
          'UPDATE purchase_items SET received_quantity = ?, rejected_quantity = ?, status = ?, subtotal = ?, quantity = ?, sync_status = 0 WHERE id = ?',
          [
            updatedReceivedQty,
            updatedRejectedQty,
            itemStatus,
            effectiveItemSubtotal,
            updatedReceivedQty > 0 ? updatedReceivedQty : item.quantity,
            item.id,
          ],
        );
      }

      // 3. Determine Overall Purchase Status
      String newPurchaseStatus;
      if (!hasAnyPendingItem || cancelRemaining) {
        newPurchaseStatus = totalReceivedAmount > 0 ? 'RECEIVED' : 'CANCELLED';
      } else {
        newPurchaseStatus = 'PARTIALLY_RECEIVED';
      }

      // 4. Calculate Financials
      final newTotal = cancelRemaining ? totalReceivedAmount : currentPurchase.totalAmount;
      final newPaid = currentPurchase.paidAmount + additionalPaid;
      final newDue = (newTotal - newPaid) > 0 ? (newTotal - newPaid) : 0.0;

      // 5. Update Purchase Record
      String combinedNotes = currentPurchase.notes ?? '';
      if (receivingNotes != null && receivingNotes.trim().isNotEmpty) {
        final recLine = '[Received on $nowStr]: $receivingNotes';
        combinedNotes = combinedNotes.isEmpty ? recLine : '$combinedNotes\n$recLine';
      }

      await txn.rawUpdate(
        'UPDATE purchases SET status = ?, total_amount = ?, paid_amount = ?, due_amount = ?, notes = ?, updated_at = ?, sync_status = 0 WHERE id = ?',
        [
          newPurchaseStatus,
          newTotal,
          newPaid,
          newDue,
          combinedNotes,
          nowStr,
          purchaseId,
        ],
      );

      // 6. Record Supplier Payment if additionalPaid > 0
      if (additionalPaid > 0 && currentPurchase.supplierId != null && currentPurchase.supplierId!.isNotEmpty) {
        await txn.insert('supplier_payments', {
          'id': 'sp-rec-${DateTime.now().millisecondsSinceEpoch}',
          'business_id': currentPurchase.businessId,
          'supplier_id': currentPurchase.supplierId,
          'purchase_id': purchaseId,
          'amount': additionalPaid,
          'type': 'PAYMENT',
          'payment_method': paymentMethod ?? currentPurchase.paymentMethod,
          'notes': 'Payment on Goods Receiving for Invoice ${currentPurchase.invoiceNo}',
          'payment_date': nowStr,
          'sync_status': 0,
          'created_at': nowStr,
        });
      }

      // 7. Adjust Supplier Payable Debt
      if (currentPurchase.supplierId != null && currentPurchase.supplierId!.isNotEmpty) {
        final dueDifference = newDue - currentPurchase.dueAmount;
        if (dueDifference != 0) {
          await txn.rawUpdate(
            'UPDATE suppliers SET payable_balance = payable_balance + ?, sync_status = 0, updated_at = ? WHERE id = ?',
            [dueDifference, nowStr, currentPurchase.supplierId],
          );
        }
      }
    });
  }

  // Update Follow-up Log and Reschedule Expected Delivery Date
  Future<void> updateFollowUp(
    String purchaseId,
    String followUpNote, {
    String? nextExpectedDeliveryDate,
  }) async {
    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String().substring(0, 16);

    final res = await db.query('purchases', where: 'id = ?', whereArgs: [purchaseId]);
    if (res.isEmpty) return;

    final existingNotes = res.first['follow_up_notes']?.toString() ?? '';
    final newEntry = '[$nowStr] $followUpNote';
    final newLog = existingNotes.isEmpty ? newEntry : '$existingNotes\n$newEntry';

    final updateData = <String, dynamic>{
      'last_follow_up_date': DateTime.now().toIso8601String(),
      'follow_up_notes': newLog,
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 0,
    };

    if (nextExpectedDeliveryDate != null && nextExpectedDeliveryDate.isNotEmpty) {
      updateData['expected_delivery_date'] = nextExpectedDeliveryDate;
    }

    await db.update('purchases', updateData, where: 'id = ?', whereArgs: [purchaseId]);
  }

  // Cancel Supplier Purchase Order
  Future<void> cancelPurchaseOrder(String purchaseId, {String? cancelReason}) async {
    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final res = await txn.query('purchases', where: 'id = ?', whereArgs: [purchaseId]);
      if (res.isEmpty) return;
      final p = PurchaseModel.fromJson(res.first);

      // Cancel all items
      await txn.rawUpdate(
        'UPDATE purchase_items SET status = "CANCELLED", sync_status = 0 WHERE purchase_id = ?',
        [purchaseId],
      );

      // If supplier had payable due recorded, remove it
      if (p.dueAmount > 0 && p.supplierId != null && p.supplierId!.isNotEmpty) {
        await txn.rawUpdate(
          'UPDATE suppliers SET payable_balance = payable_balance - ?, sync_status = 0, updated_at = ? WHERE id = ?',
          [p.dueAmount, nowStr, p.supplierId],
        );
      }

      String note = p.notes ?? '';
      if (cancelReason != null && cancelReason.trim().isNotEmpty) {
        final cancelEntry = '[Cancelled: $cancelReason]';
        note = note.isEmpty ? cancelEntry : '$note\n$cancelEntry';
      }

      await txn.update(
        'purchases',
        {
          'status': 'CANCELLED',
          'due_amount': 0.0,
          'notes': note,
          'updated_at': nowStr,
          'sync_status': 0,
        },
        where: 'id = ?',
        whereArgs: [purchaseId],
      );
    });
  }

  Future<List<PurchaseModel>> getPurchases({
    String query = '',
    String? supplierId,
    String? status,
    bool? isOverdueOnly,
    String? businessId,
  }) async {
    final db = await dbHelper.database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (businessId != null && businessId.isNotEmpty && businessId != 'default_biz') {
      whereClause += ' AND (business_id = ? OR business_id = "default_biz")';
      whereArgs.add(businessId);
    }

    if (supplierId != null && supplierId.isNotEmpty) {
      whereClause += ' AND supplier_id = ?';
      whereArgs.add(supplierId);
    }

    if (status != null && status.isNotEmpty && status != 'ALL') {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    if (query.isNotEmpty) {
      whereClause += ' AND (invoice_no LIKE ? OR supplier_name LIKE ? OR notes LIKE ? OR follow_up_notes LIKE ?)';
      final q = '%$query%';
      whereArgs.addAll([q, q, q, q]);
    }

    final res = await db.query(
      'purchases',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'purchase_date DESC',
    );

    List<PurchaseModel> purchases = [];
    for (var row in res) {
      final itemsRes = await db.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [row['id']],
      );
      final items = itemsRes.map((i) => PurchaseItemModel.fromJson(i)).toList();
      final map = Map<String, dynamic>.from(row);
      map['items'] = items.map((i) => i.toMap()).toList();
      final purchase = PurchaseModel.fromJson(map);

      if (isOverdueOnly == true) {
        if (!purchase.isOverdue) continue;
      }

      purchases.add(purchase);
    }

    return purchases;
  }

  Future<PurchaseModel?> getPurchaseById(String purchaseId) async {
    final list = await getPurchases();
    try {
      return list.firstWhere((p) => p.id == purchaseId);
    } catch (_) {
      return null;
    }
  }

  Future<List<PurchaseItemModel>> getPurchaseItems(String purchaseId) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    return res.map((e) => PurchaseItemModel.fromJson(e)).toList();
  }

  Future<void> batchSavePurchases(List<dynamic> list) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (var p in list) {
      final model = PurchaseModel.fromJson(Map<String, dynamic>.from(p));
      batch.insert('purchases', model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (var item in model.items) {
        batch.insert('purchase_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }
}
