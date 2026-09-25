import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/data/local/purchase_dao.dart';
import 'package:snapcart/app/data/local/supplier_dao.dart';
import 'package:snapcart/app/data/local/product_dao.dart';
import 'package:snapcart/app/data/models/purchase_model.dart';
import 'package:snapcart/app/data/models/supplier_model.dart';
import 'package:snapcart/app/data/models/product_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DBHelper.instance.close();
  });

  test('Supplier Purchase Order, Follow-up & Partial Goods Receiving Test Suite', () async {
    final db = await DBHelper.instance.database;
    await db.delete('purchase_items');
    await db.delete('purchases');
    await db.delete('products');
    await db.delete('suppliers');

    final purchaseDao = PurchaseDao();
    final supplierDao = SupplierDao();
    final productDao = ProductDao();

    // 1. Create Supplier & Product
    final supplier = SupplierModel(
      id: 'sup-weaver-99',
      name: 'Daw San Silk Loom (ဒေါ်စန်း ရက္ကန်း)',
      companyName: 'Daw San Silk',
      phone: '09-12345678',
    );
    await supplierDao.insertOrUpdateSupplier(supplier);

    final product = ProductModel(
      id: 'prod-silk-99',
      name: 'Amarapura Pure Silk (အမရပူရ ပိုးစစ်)',
      costPrice: 50000,
      retailPrice: 80000,
      stockQty: 5.0, // initial stock is 5
      minStockAlert: 10.0,
      unit: 'piece',
    );
    await productDao.insertOrUpdateProduct(product);

    // 2. Place a Supplier Purchase Order (PO) for 10 pieces with status: 'ORDERED'
    final expDate = DateTime.now().add(const Duration(days: 4)).toIso8601String().substring(0, 10);
    final po = PurchaseModel(
      id: 'po-test-99',
      invoiceNo: 'PO-2026-0099',
      supplierId: supplier.id,
      supplierName: supplier.name,
      totalAmount: 500000, // 10 pcs * 50,000
      paidAmount: 100000, // Advance paid
      dueAmount: 400000,
      status: 'ORDERED',
      expectedDeliveryDate: expDate,
      purchaseDate: DateTime.now().toIso8601String(),
      items: [
        PurchaseItemModel(
          id: 'poi-test-99',
          purchaseId: 'po-test-99',
          productId: product.id,
          productName: product.name,
          costPrice: 50000,
          quantity: 0.0, // not in stock yet
          orderedQuantity: 10.0,
          receivedQuantity: 0.0,
          subtotal: 500000,
          status: 'ORDERED',
        ),
      ],
    );

    await purchaseDao.savePurchaseOrder(po);

    // Verify product stock is STILL 5.0 (has NOT incremented!)
    final pAfterPO = await productDao.getProductById(product.id);
    expect(pAfterPO!.stockQty, equals(5.0));

    // Verify PO query
    final poList = await purchaseDao.getPurchases(status: 'ORDERED');
    expect(poList.any((p) => p.id == 'po-test-99'), isTrue);
    expect(poList.firstWhere((p) => p.id == 'po-test-99').isPendingDelivery, isTrue);

    // 3. Log a Follow-up Note with Supplier
    await purchaseDao.updateFollowUp(
      'po-test-99',
      'Phoned Daw San - Loom 70% complete, 7 pieces will arrive on Friday.',
      nextExpectedDeliveryDate: '2026-09-18',
    );

    final poWithFollowUp = await purchaseDao.getPurchaseById('po-test-99');
    expect(poWithFollowUp!.followUpNotes, contains('Loom 70% complete'));
    expect(poWithFollowUp.expectedDeliveryDate, equals('2026-09-18'));

    // 4. Partial Goods Receiving: 7 pieces arrive at the shop
    await purchaseDao.receivePurchaseItems(
      purchaseId: 'po-test-99',
      itemsReceived: [
        {'itemId': 'poi-test-99', 'receivedQty': 7.0},
      ],
      cancelRemaining: false, // Keep waiting for the remaining 3 pieces
      additionalPaid: 200000, // Pay 200,000 upon receiving
      receivingNotes: '7 pieces received in good condition',
    );

    // Verify product stock increased by EXACTLY 7 pieces (5 + 7 = 12)
    final pAfterPartial = await productDao.getProductById(product.id);
    expect(pAfterPartial!.stockQty, equals(12.0));

    final poAfterPartial = await purchaseDao.getPurchaseById('po-test-99');
    expect(poAfterPartial!.status, equals('PARTIALLY_RECEIVED'));
    expect(poAfterPartial.paidAmount, equals(300000.0)); // 100k + 200k
    expect(poAfterPartial.items.first.receivedQuantity, equals(7.0));
    expect(poAfterPartial.items.first.remainingQuantity, equals(3.0));

    // 5. Supplier informs that the remaining 3 pieces cannot be woven -> Close and cancel remaining 3
    await purchaseDao.receivePurchaseItems(
      purchaseId: 'po-test-99',
      itemsReceived: [
        {'itemId': 'poi-test-99', 'receivedQty': 0.0},
      ],
      cancelRemaining: true, // Close remaining
      additionalPaid: 50000, // Settle final balance: 7 * 50,000 = 350,000 total. Paid so far: 300,000 -> remaining 50,000
    );

    // Stock stays at 12
    final pFinal = await productDao.getProductById(product.id);
    expect(pFinal!.stockQty, equals(12.0));

    final poFinal = await purchaseDao.getPurchaseById('po-test-99');
    expect(poFinal!.status, equals('RECEIVED')); // All accounted for (7 received, 3 rejected)
    expect(poFinal.totalAmount, equals(350000.0)); // 7 * 50,000
    expect(poFinal.paidAmount, equals(350000.0));
    expect(poFinal.dueAmount, equals(0.0));
    expect(poFinal.items.first.rejectedQuantity, equals(3.0));
  });
}
