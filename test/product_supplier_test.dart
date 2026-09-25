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
    await DBHelper.instance.close();
  });

  test('Multi-Supplier per Product Tracking & Purchase Aggregations Test', () async {
    final db = await DBHelper.instance.database;
    await db.delete('purchase_items', where: 'product_id = ?', whereArgs: ['prod-sup-test-01']);
    await db.delete('product_suppliers', where: 'product_id = ?', whereArgs: ['prod-sup-test-01']);
    await db.delete('purchases', where: 'id IN (?, ?, ?)', whereArgs: ['po-test-01', 'po-test-02', 'po-test-03']);

    final productDao = ProductDao();
    final supplierDao = SupplierDao();
    final purchaseDao = PurchaseDao();

    // 1. Create a textile product
    final product = ProductModel(
      id: 'prod-sup-test-01',
      name: 'မန္တလေးချည်ထည် ပန်းရိုက် ဝမ်းဆက်',
      barcode: 'SKU-MDY-001',
      costPrice: 12000,
      retailPrice: 18000,
      wholesalePrice: 15000,
      stockQty: 50,
      unit: 'set',
    );
    await productDao.insertOrUpdateProduct(product);

    // 2. Create 3 distinct suppliers
    final supplierA = SupplierModel(
      id: 'sup-01',
      name: 'U Ba Maung',
      companyName: 'Mandalay Silk & Cotton Center',
      phone: '0912345678',
      address: 'Mandalay 78th St',
    );
    final supplierB = SupplierModel(
      id: 'sup-02',
      name: 'Daw Hla Hla',
      companyName: 'Amarapura Weaving House',
      phone: '0987654321',
      address: 'Amarapura',
    );
    final supplierC = SupplierModel(
      id: 'sup-03',
      name: 'Ko Thein Win',
      companyName: 'Pakokku Cotton Mills',
      phone: '0955566677',
      address: 'Pakokku',
    );

    await supplierDao.insertOrUpdateSupplier(supplierA);
    await supplierDao.insertOrUpdateSupplier(supplierB);
    await supplierDao.insertOrUpdateSupplier(supplierC);

    // 3. Link Supplier A and Supplier B to Product, with Supplier A as Preferred
    await supplierDao.linkProductSuppliers(
      product.id,
      [supplierA.id, supplierB.id],
      businessId: 'default_biz',
      preferredSupplierId: supplierA.id,
    );

    // Check initial linked suppliers (no purchases yet)
    var suppliers = await supplierDao.getSuppliersForProduct(product.id);
    expect(suppliers.length, 2);
    final supA = suppliers.firstWhere((s) => s.supplierId == supplierA.id);
    final supB = suppliers.firstWhere((s) => s.supplierId == supplierB.id);

    expect(supA.supplierName, 'U Ba Maung');
    expect(supA.companyName, 'Mandalay Silk & Cotton Center');
    expect(supA.isPreferred, true);
    expect(supA.totalSuppliedQty, 0.0);

    expect(supB.supplierName, 'Daw Hla Hla');
    expect(supB.isPreferred, false);

    // 4. Record Purchases:
    // Purchase 1: From Supplier A, 20 sets @ 11,500 Ks on 2026-08-10
    final purchase1 = PurchaseModel(
      id: 'po-test-01',
      supplierId: supplierA.id,
      invoiceNo: 'INV-A-101',
      purchaseDate: '2026-08-10 10:00:00',
      totalAmount: 230000,
      paidAmount: 230000,
      dueAmount: 0,
      status: 'RECEIVED',
      paymentMethod: 'CASH',
      items: [
        PurchaseItemModel(
          id: 'poi-01',
          purchaseId: 'po-test-01',
          productId: product.id,
          productName: product.name,
          quantity: 20,
          costPrice: 11500,
          subtotal: 230000,
        ),
      ],
    );
    await purchaseDao.savePurchaseOrder(purchase1);

    // Purchase 2: From Supplier A, 30 sets @ 11,000 Ks on 2026-09-01 (more recent)
    final purchase2 = PurchaseModel(
      id: 'po-test-02',
      supplierId: supplierA.id,
      invoiceNo: 'INV-A-102',
      purchaseDate: '2026-09-01 14:00:00',
      totalAmount: 330000,
      paidAmount: 330000,
      dueAmount: 0,
      status: 'RECEIVED',
      paymentMethod: 'CASH',
      items: [
        PurchaseItemModel(
          id: 'poi-02',
          purchaseId: 'po-test-02',
          productId: product.id,
          productName: product.name,
          quantity: 30,
          costPrice: 11000,
          subtotal: 330000,
        ),
      ],
    );
    await purchaseDao.savePurchaseOrder(purchase2);

    // Purchase 3: From Supplier B, 15 sets @ 12,200 Ks on 2026-08-25
    final purchase3 = PurchaseModel(
      id: 'po-test-03',
      supplierId: supplierB.id,
      invoiceNo: 'INV-B-201',
      purchaseDate: '2026-08-25 11:30:00',
      totalAmount: 183000,
      paidAmount: 183000,
      dueAmount: 0,
      status: 'RECEIVED',
      paymentMethod: 'CASH',
      items: [
        PurchaseItemModel(
          id: 'poi-03',
          purchaseId: 'po-test-03',
          productId: product.id,
          productName: product.name,
          quantity: 15,
          costPrice: 12200,
          subtotal: 183000,
        ),
      ],
    );
    await purchaseDao.savePurchaseOrder(purchase3);

    // 5. Query Suppliers for Product and verify aggregated metrics
    suppliers = await supplierDao.getSuppliersForProduct(product.id);
    expect(suppliers.length, 2);

    final aggA = suppliers.firstWhere((s) => s.supplierId == supplierA.id);
    expect(aggA.isPreferred, true);
    expect(aggA.totalSuppliedQty, 50.0); // 20 + 30
    expect(aggA.totalSpend, 560000.0); // 230,000 + 330,000
    expect(aggA.lastCostPrice, 11000.0); // Most recent unitCost
    expect(aggA.lastPurchaseDate, contains('2026-09-01'));
    expect(aggA.invoiceCount, 2);

    final aggB = suppliers.firstWhere((s) => s.supplierId == supplierB.id);
    expect(aggB.isPreferred, false);
    expect(aggB.totalSuppliedQty, 15.0);
    expect(aggB.totalSpend, 183000.0);
    expect(aggB.lastCostPrice, 12200.0);
    expect(aggB.lastPurchaseDate, contains('2026-08-25'));
    expect(aggB.invoiceCount, 1);

    // 6. Test Unlinking Supplier B
    await supplierDao.unlinkProductSupplier(product.id, supplierB.id);
    // Since Supplier B has historical purchase records for this product, getSuppliersForProduct still reflects the history
    final remaining = await supplierDao.getSuppliersForProduct(product.id);
    expect(remaining.any((s) => s.supplierId == supplierA.id), true);
    expect(remaining.any((s) => s.supplierId == supplierB.id), true);
  });
}
