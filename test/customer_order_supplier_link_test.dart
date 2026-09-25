import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/data/local/customer_order_dao.dart';
import 'package:snapcart/app/data/local/supplier_dao.dart';
import 'package:snapcart/app/data/local/product_dao.dart';
import 'package:snapcart/app/data/models/customer_order_model.dart';
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

  test('Customer Order Supplier Link, Demand Status and Filter Test', () async {
    final db = await DBHelper.instance.database;
    await db.delete('customer_order_items');
    await db.delete('customer_orders');
    await db.delete('product_suppliers');
    await db.delete('products');
    await db.delete('suppliers');

    final orderDao = CustomerOrderDao();
    final supplierDao = SupplierDao();
    final productDao = ProductDao();

    // 1. Create Suppliers
    final supplier1 = SupplierModel(
      id: 'sup-weave-001',
      name: 'Daw Hla Silk Weaving (ရွှေပိုး ရက္ကန်း)',
      companyName: 'Daw Hla Silk Workshop',
      phone: '09-111222333',
    );
    final supplier2 = SupplierModel(
      id: 'sup-weave-002',
      name: 'Shwe Zin Cotton Workshop (ရွှေဇင် ချည်ထည်)',
      companyName: 'Shwe Zin Textiles',
      phone: '09-444555666',
    );
    await supplierDao.insertOrUpdateSupplier(supplier1);
    await supplierDao.insertOrUpdateSupplier(supplier2);

    // 2. Create Products
    final product1 = ProductModel(
      id: 'prod-silk-101',
      name: 'Amarapura Silk Lun Yar Kyaw (အမရပူရ လွန်းတစ်ရာ)',
      costPrice: 65000,
      retailPrice: 95000,
      wholesalePrice: 85000,
      stockQty: 3.0,
      minStockAlert: 5.0,
      unit: 'piece',
    );
    final product2 = ProductModel(
      id: 'prod-cotton-102',
      name: 'Traditional Cotton Paso (ရိုးရာ ချည်ပုဆိုး)',
      costPrice: 12000,
      retailPrice: 18000,
      wholesalePrice: 15000,
      stockQty: 20.0,
      minStockAlert: 5.0,
      unit: 'piece',
    );
    await productDao.insertOrUpdateProduct(product1);
    await productDao.insertOrUpdateProduct(product2);

    // Link product1 to supplier1 as preferred
    await supplierDao.linkProductSuppliers(product1.id, [supplier1.id], preferredSupplierId: supplier1.id);

    // 3. Create Customer Orders assigned to supplier1
    final order1 = CustomerOrderModel(
      id: 'co-test-001',
      orderNo: 'ORD-TEST-1001',
      customerName: 'Daw Nu Nu',
      customerPhone: '09-999888777',
      orderSource: 'MESSENGER',
      appointmentDate: '2026-09-15 14:00:00',
      appointmentType: 'LOOM_WEAVING',
      supplierId: supplier1.id,
      supplierName: supplier1.name,
      totalAmount: 95000,
      advanceAmount: 30000,
      dueAmount: 65000,
      createdAt: DateTime.now().toIso8601String(),
      items: [
        CustomerOrderItemModel(
          id: 'coi-test-001',
          customerOrderId: 'co-test-001',
          productId: product1.id,
          itemName: product1.name,
          supplierId: supplier1.id,
          supplierName: supplier1.name,
          quantity: 2.0,
          unit: 'piece',
          unitPrice: 95000,
          subtotal: 190000,
        ),
      ],
    );

    final order2 = CustomerOrderModel(
      id: 'co-test-002',
      orderNo: 'ORD-TEST-1002',
      customerName: 'U Ba Maung',
      customerPhone: '09-777666555',
      orderSource: 'VIBER',
      appointmentDate: '2026-09-16 10:00:00',
      appointmentType: 'FABRIC_DELIVERY_IN',
      supplierId: supplier2.id,
      supplierName: supplier2.name,
      totalAmount: 36000,
      advanceAmount: 10000,
      dueAmount: 26000,
      createdAt: DateTime.now().toIso8601String(),
      items: [
        CustomerOrderItemModel(
          id: 'coi-test-002',
          customerOrderId: 'co-test-002',
          productId: product2.id,
          itemName: product2.name,
          supplierId: supplier2.id,
          supplierName: supplier2.name,
          quantity: 2.0,
          unit: 'piece',
          unitPrice: 18000,
          subtotal: 36000,
        ),
      ],
    );

    await orderDao.saveCustomerOrder(order1);
    await orderDao.saveCustomerOrder(order2);

    // 4. Test Querying Orders Filtered by Supplier
    final supplier1Orders = await orderDao.getCustomerOrders(supplierId: supplier1.id);
    expect(supplier1Orders.any((o) => o.id == order1.id), isTrue);
    expect(supplier1Orders.any((o) => o.id == order2.id), isFalse);

    final supplier2Orders = await orderDao.getCustomerOrders(supplierId: supplier2.id);
    expect(supplier2Orders.any((o) => o.id == order2.id), isTrue);
    expect(supplier2Orders.any((o) => o.id == order1.id), isFalse);

    // 5. Test Pending Customer Demand Lookup for Products (for Purchase Orders & Stock In)
    final demandMap = await orderDao.getPendingCustomerOrdersForProducts([product1.id, product2.id]);
    expect(demandMap[product1.id]!.isNotEmpty, isTrue);
    expect(demandMap[product1.id]!.first['order_no'], equals('ORD-TEST-1001'));
    expect((demandMap[product1.id]!.first['quantity'] as num).toDouble(), equals(2.0));

    // 6. Test Product Order Summary
    final summary = await orderDao.getProductOrderSummary(product1.id);
    expect(summary['activeOrderCount'], equals(1));
    expect(summary['totalReservedQty'], equals(2.0));
  });
}
