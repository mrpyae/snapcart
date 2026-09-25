import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/data/local/product_dao.dart';
import 'package:snapcart/app/data/local/supplier_dao.dart';
import 'package:snapcart/app/data/local/purchase_dao.dart';
import 'package:snapcart/app/data/models/product_model.dart';
import 'package:snapcart/app/data/models/supplier_model.dart';
import 'package:snapcart/app/data/models/purchase_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    final db = await DBHelper.instance.database;
    await db.delete('purchase_items', where: 'product_id = ?', whereArgs: ['prod-inline-01']);
    await db.delete('product_suppliers', where: 'product_id = ?', whereArgs: ['prod-inline-01']);
    await db.delete('purchases', where: 'id = ?', whereArgs: ['po-inline-01']);
    await db.delete('products', where: 'id = ?', whereArgs: ['prod-inline-01']);
    await db.delete('suppliers', where: 'id = ?', whereArgs: ['sup-inline-01']);
    await DBHelper.instance.close();
  });

  test('Inline Product Creation & Stock-In Workflow Test', () async {
    final db = await DBHelper.instance.database;
    await db.delete('purchase_items', where: 'product_id = ?', whereArgs: ['prod-inline-01']);
    await db.delete('product_suppliers', where: 'product_id = ?', whereArgs: ['prod-inline-01']);
    await db.delete('purchases', where: 'id = ?', whereArgs: ['po-inline-01']);
    await db.delete('products', where: 'id = ?', whereArgs: ['prod-inline-01']);
    await db.delete('suppliers', where: 'id = ?', whereArgs: ['sup-inline-01']);

    final productDao = ProductDao();
    final supplierDao = SupplierDao();
    final purchaseDao = PurchaseDao();

    // 1. Setup a Supplier
    final supplier = SupplierModel(
      id: 'sup-inline-01',
      name: 'U Hla Win Cotton Mill',
      companyName: 'Meiktila Weaving Co.',
      phone: '0977889900',
    );
    await supplierDao.insertOrUpdateSupplier(supplier);

    // 2. Simulate inline creation of a brand new product during purchase stock-in
    final newProduct = ProductModel(
      id: 'prod-inline-01',
      name: 'မိတ္ထီလာချည်ထည် အဆင်သစ်',
      barcode: 'SKU-MTL-001',
      costPrice: 14000,
      retailPrice: 21000,
      stockQty: 0, // Initially 0 units
      unit: 'yard',
    );
    await productDao.insertOrUpdateProduct(newProduct);

    // Auto-link new product to current supplier
    await supplierDao.linkProductSuppliers(
      newProduct.id,
      [supplier.id],
      businessId: 'default_biz',
      preferredSupplierId: supplier.id,
    );

    // Verify initial product state
    var fetchedProduct = await productDao.getProductById(newProduct.id);
    expect(fetchedProduct != null, true);
    expect(fetchedProduct!.stockQty, 0.0);
    expect(fetchedProduct.costPrice, 14000.0);

    // 3. Complete Purchase & Stock-In: 25 yards @ 14,000 Ks
    final purchase = PurchaseModel(
      id: 'po-inline-01',
      supplierId: supplier.id,
      supplierName: supplier.name,
      invoiceNo: 'INV-INLINE-001',
      purchaseDate: '2026-09-08 15:00:00',
      totalAmount: 350000,
      paidAmount: 350000,
      dueAmount: 0,
      status: 'RECEIVED',
      paymentMethod: 'CASH',
      items: [
        PurchaseItemModel(
          id: 'poi-inline-01',
          purchaseId: 'po-inline-01',
          productId: newProduct.id,
          productName: newProduct.name,
          quantity: 25,
          costPrice: 14000,
          subtotal: 350000,
        ),
      ],
    );
    await purchaseDao.savePurchaseOrder(purchase);

    // 4. Verify inventory stock incremented automatically
    fetchedProduct = await productDao.getProductById(newProduct.id);
    expect(fetchedProduct!.stockQty, 25.0); // 0 -> 25 yards
    expect(fetchedProduct.costPrice, 14000.0);

    // 5. Verify supplier metrics updated
    final suppliersForProduct = await supplierDao.getSuppliersForProduct(newProduct.id);
    expect(suppliersForProduct.length, 1);
    expect(suppliersForProduct.first.supplierId, supplier.id);
    expect(suppliersForProduct.first.isPreferred, true);
    expect(suppliersForProduct.first.totalSuppliedQty, 25.0);
    expect(suppliersForProduct.first.totalSpend, 350000.0);
    expect(suppliersForProduct.first.lastCostPrice, 14000.0);
  });
}
