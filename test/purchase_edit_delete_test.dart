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

  test('Purchase & Supplier Order - Delete Stock-In Rollback Test', () async {
    final db = await DBHelper.instance.database;
    await db.delete('purchase_items');
    await db.delete('purchases');
    await db.delete('products');
    await db.delete('suppliers');
    await db.delete('supplier_payments');

    final purchaseDao = PurchaseDao();
    final supplierDao = SupplierDao();
    final productDao = ProductDao();

    // 1. Setup Supplier & Product
    final supplier = SupplierModel(
      id: 'sup-del-1',
      name: 'Mandalay Cotton Factory',
      companyName: 'Mandalay Textiles',
    );
    await supplierDao.insertOrUpdateSupplier(supplier);

    final product = ProductModel(
      id: 'prod-del-1',
      name: 'Mandalay Cotton Longyi',
      costPrice: 12000,
      retailPrice: 18000,
      stockQty: 10.0,
      unit: 'piece',
    );
    await productDao.insertOrUpdateProduct(product);

    // 2. Direct Stock-In: 20 pieces @ 12,000 = 240,000. Paid: 100,000, Due: 140,000.
    final directPurchase = PurchaseModel(
      id: 'pur-direct-1',
      invoiceNo: 'PUR-0001',
      supplierId: supplier.id,
      supplierName: supplier.name,
      totalAmount: 240000,
      paidAmount: 100000,
      dueAmount: 140000,
      status: 'RECEIVED',
      purchaseDate: DateTime.now().toIso8601String(),
      items: [
        PurchaseItemModel(
          id: 'item-del-1',
          purchaseId: 'pur-direct-1',
          productId: product.id,
          productName: product.name,
          costPrice: 12000,
          quantity: 20.0,
          orderedQuantity: 20.0,
          receivedQuantity: 20.0,
          subtotal: 240000,
          status: 'RECEIVED',
        ),
      ],
    );
    await purchaseDao.savePurchaseOrder(directPurchase);

    // Verify stock became 10 + 20 = 30
    var pAfterStockIn = await productDao.getProductById(product.id);
    expect(pAfterStockIn?.stockQty, equals(30.0));

    // Verify supplier payable debt became 140,000
    var sAfterStockIn = await supplierDao.getSupplierById(supplier.id);
    expect(sAfterStockIn?.payableBalance, equals(140000.0));

    // 3. Delete Direct Purchase
    await purchaseDao.deletePurchaseOrder('pur-direct-1');

    // Verify stock is rolled back: 30 - 20 = 10
    var pAfterDelete = await productDao.getProductById(product.id);
    expect(pAfterDelete?.stockQty, equals(10.0));

    // Verify supplier payable debt is reversed: 140,000 - 140,000 = 0
    var sAfterDelete = await supplierDao.getSupplierById(supplier.id);
    expect(sAfterDelete?.payableBalance, equals(0.0));

    // Verify purchase record is gone
    var deletedPurchase = await purchaseDao.getPurchaseById('pur-direct-1');
    expect(deletedPurchase, isNull);
  });

  test('Purchase & Supplier Order - Delete Ordered PO (No Stock Rollback)', () async {
    final db = await DBHelper.instance.database;
    await db.delete('purchase_items');
    await db.delete('purchases');
    await db.delete('products');
    await db.delete('suppliers');

    final purchaseDao = PurchaseDao();
    final supplierDao = SupplierDao();
    final productDao = ProductDao();

    final supplier = SupplierModel(id: 'sup-del-2', name: 'Shan Paper Mill');
    await supplierDao.insertOrUpdateSupplier(supplier);

    final product = ProductModel(
      id: 'prod-del-2',
      name: 'Shan Handmade Paper',
      costPrice: 5000,
      retailPrice: 8000,
      stockQty: 15.0,
      unit: 'pack',
    );
    await productDao.insertOrUpdateProduct(product);

    // Place an ORDERED PO (not yet received into physical stock)
    final po = PurchaseModel(
      id: 'po-del-2',
      invoiceNo: 'PO-0002',
      supplierId: supplier.id,
      supplierName: supplier.name,
      totalAmount: 50000,
      paidAmount: 0,
      dueAmount: 50000,
      status: 'ORDERED',
      purchaseDate: DateTime.now().toIso8601String(),
      items: [
        PurchaseItemModel(
          id: 'item-del-2',
          purchaseId: 'po-del-2',
          productId: product.id,
          productName: product.name,
          costPrice: 5000,
          quantity: 0.0,
          orderedQuantity: 10.0,
          receivedQuantity: 0.0,
          subtotal: 50000,
          status: 'ORDERED',
        ),
      ],
    );
    await purchaseDao.savePurchaseOrder(po);

    // Physical stock should remain 15.0
    var pBefore = await productDao.getProductById(product.id);
    expect(pBefore?.stockQty, equals(15.0));

    // Delete PO
    await purchaseDao.deletePurchaseOrder('po-del-2');

    // Physical stock must still be 15.0
    var pAfter = await productDao.getProductById(product.id);
    expect(pAfter?.stockQty, equals(15.0));

    // Purchase record should be null
    var deletedPo = await purchaseDao.getPurchaseById('po-del-2');
    expect(deletedPo, isNull);
  });

  test('Purchase & Supplier Order - Update Purchase Order Details & Stock', () async {
    final db = await DBHelper.instance.database;
    await db.delete('purchase_items');
    await db.delete('purchases');
    await db.delete('products');
    await db.delete('suppliers');

    final purchaseDao = PurchaseDao();
    final supplierDao = SupplierDao();
    final productDao = ProductDao();

    final supplier = SupplierModel(id: 'sup-edit-1', name: 'Bago Woodworks');
    await supplierDao.insertOrUpdateSupplier(supplier);

    final product = ProductModel(
      id: 'prod-edit-1',
      name: 'Teak Coaster',
      costPrice: 3000,
      retailPrice: 5000,
      stockQty: 5.0,
      unit: 'piece',
    );
    await productDao.insertOrUpdateProduct(product);

    // Initial stock-in of 10 items @ 3000 = 30,000. Paid: 10,000, Due: 20,000.
    final purchase = PurchaseModel(
      id: 'pur-edit-1',
      invoiceNo: 'PUR-EDIT-1',
      supplierId: supplier.id,
      supplierName: supplier.name,
      totalAmount: 30000,
      paidAmount: 10000,
      dueAmount: 20000,
      status: 'RECEIVED',
      purchaseDate: DateTime.now().toIso8601String(),
      items: [
        PurchaseItemModel(
          id: 'item-edit-1',
          purchaseId: 'pur-edit-1',
          productId: product.id,
          productName: product.name,
          costPrice: 3000,
          quantity: 10.0,
          orderedQuantity: 10.0,
          receivedQuantity: 10.0,
          subtotal: 30000,
          status: 'RECEIVED',
        ),
      ],
    );
    await purchaseDao.savePurchaseOrder(purchase);

    // Stock should be 5 + 10 = 15
    var p1 = await productDao.getProductById(product.id);
    expect(p1?.stockQty, equals(15.0));

    // Supplier balance should be 20,000
    var s1 = await supplierDao.getSupplierById(supplier.id);
    expect(s1?.payableBalance, equals(20000.0));

    // Update purchase: change quantity from 10 to 15, cost price to 3200, paidAmount to 25,000
    // Total = 15 * 3200 = 48,000. Paid: 25,000, Due: 23,000.
    final updatedItem = PurchaseItemModel(
      id: 'item-edit-1',
      purchaseId: 'pur-edit-1',
      productId: product.id,
      productName: product.name,
      costPrice: 3200,
      quantity: 15.0,
      orderedQuantity: 15.0,
      receivedQuantity: 15.0,
      subtotal: 48000,
      status: 'RECEIVED',
    );

    final updatedPurchase = purchase.copyWith(
      invoiceNo: 'PUR-EDIT-1-MODIFIED',
      notes: 'Updated quantities after supplier invoice reconciliation',
      totalAmount: 48000,
      paidAmount: 25000,
      dueAmount: 23000,
      items: [updatedItem],
    );

    await purchaseDao.updatePurchaseOrder(
      updatedPurchase: updatedPurchase,
      updatedItems: [updatedItem],
    );

    // Stock should now be 5 + 15 = 20
    var p2 = await productDao.getProductById(product.id);
    expect(p2?.stockQty, equals(20.0));
    expect(p2?.costPrice, equals(3200.0));

    // Supplier payable balance should now be 23,000
    var s2 = await supplierDao.getSupplierById(supplier.id);
    expect(s2?.payableBalance, equals(23000.0));

    // Verify purchase fetched from db has updated fields
    var pFetched = await purchaseDao.getPurchaseById('pur-edit-1');
    expect(pFetched?.invoiceNo, equals('PUR-EDIT-1-MODIFIED'));
    expect(pFetched?.notes, equals('Updated quantities after supplier invoice reconciliation'));
    expect(pFetched?.totalAmount, equals(48000.0));
    expect(pFetched?.dueAmount, equals(23000.0));
    expect(pFetched?.items.first.quantity, equals(15.0));
  });
}
