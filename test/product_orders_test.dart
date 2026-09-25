import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/data/local/product_dao.dart';
import 'package:snapcart/app/data/local/customer_order_dao.dart';
import 'package:snapcart/app/data/models/product_model.dart';
import 'package:snapcart/app/data/models/customer_order_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    final db = await DBHelper.instance.database;
    await db.delete('customer_order_items', where: 'product_id = ?', whereArgs: ['prod-ord-test-01']);
    await db.delete('customer_orders', where: 'id IN (?, ?, ?)', whereArgs: ['ord-cust-01', 'ord-cust-02', 'ord-cust-03']);
    await DBHelper.instance.close();
  });

  test('Product Current Orders & Stock Commitment Test', () async {
    final db = await DBHelper.instance.database;
    await db.delete('customer_order_items', where: 'product_id = ?', whereArgs: ['prod-ord-test-01']);
    await db.delete('customer_orders', where: 'id IN (?, ?, ?)', whereArgs: ['ord-cust-01', 'ord-cust-02', 'ord-cust-03']);

    final productDao = ProductDao();
    final customerOrderDao = CustomerOrderDao();

    // 1. Create a product with 30 units in stock
    final product = ProductModel(
      id: 'prod-ord-test-01',
      name: 'ရွှေတောင်ပိုးထည် ပန်းချီဆင် ဝမ်းဆက်',
      barcode: 'SKU-ST-001',
      costPrice: 20000,
      retailPrice: 35000,
      stockQty: 30,
      unit: 'set',
    );
    await productDao.insertOrUpdateProduct(product);

    // 2. Create Order 1: Active (CONFIRMED), 5 sets @ 35,000 Ks
    final order1 = CustomerOrderModel(
      id: 'ord-cust-01',
      orderNo: 'ORD-1001',
      businessId: 'default_biz',
      customerName: 'Daw Aye Thida',
      customerPhone: '09777888999',
      orderSource: 'VIBER',
      status: 'CONFIRMED',
      totalAmount: 175000,
      advanceAmount: 50000,
      dueAmount: 125000,
      paymentMethod: 'KBZ_PAY',
      appointmentDate: '2026-09-15 14:00:00',
      createdAt: '2026-09-08 10:00:00',
      items: [
        CustomerOrderItemModel(
          id: 'item-01',
          customerOrderId: 'ord-cust-01',
          productId: product.id,
          itemName: product.name,
          quantity: 5,
          unit: 'set',
          unitPrice: 35000,
          subtotal: 175000,
        ),
      ],
    );
    await customerOrderDao.saveCustomerOrder(order1);

    // 3. Create Order 2: Active (IN_PROGRESS), 8 sets @ 35,000 Ks
    final order2 = CustomerOrderModel(
      id: 'ord-cust-02',
      orderNo: 'ORD-1002',
      businessId: 'default_biz',
      customerName: 'Ma Hnin Nu',
      customerPhone: '09111222333',
      orderSource: 'MESSENGER',
      status: 'IN_PROGRESS',
      totalAmount: 280000,
      advanceAmount: 100000,
      dueAmount: 180000,
      paymentMethod: 'WAVE_PAY',
      appointmentDate: '2026-09-18 10:30:00',
      createdAt: '2026-09-08 11:30:00',
      items: [
        CustomerOrderItemModel(
          id: 'item-02',
          customerOrderId: 'ord-cust-02',
          productId: product.id,
          itemName: product.name,
          quantity: 8,
          unit: 'set',
          unitPrice: 35000,
          subtotal: 280000,
        ),
      ],
    );
    await customerOrderDao.saveCustomerOrder(order2);

    // 4. Create Order 3: Completed (COMPLETED), 4 sets @ 35,000 Ks
    final order3 = CustomerOrderModel(
      id: 'ord-cust-03',
      orderNo: 'ORD-1003',
      businessId: 'default_biz',
      customerName: 'U Min Thu',
      customerPhone: '09555666777',
      orderSource: 'WALK_IN',
      status: 'COMPLETED',
      totalAmount: 140000,
      advanceAmount: 140000,
      dueAmount: 0,
      paymentMethod: 'CASH',
      createdAt: '2026-09-01 09:00:00',
      items: [
        CustomerOrderItemModel(
          id: 'item-03',
          customerOrderId: 'ord-cust-03',
          productId: product.id,
          itemName: product.name,
          quantity: 4,
          unit: 'set',
          unitPrice: 35000,
          subtotal: 140000,
        ),
      ],
    );
    await customerOrderDao.saveCustomerOrder(order3);

    // 5. Test Active Orders query
    final activeOrders = await customerOrderDao.getOrdersForProduct(product.id, activeOnly: true);
    expect(activeOrders.length, 2);
    expect(activeOrders.any((o) => o.orderNo == 'ORD-1001'), true);
    expect(activeOrders.any((o) => o.orderNo == 'ORD-1002'), true);
    expect(activeOrders.any((o) => o.orderNo == 'ORD-1003'), false); // Completed filtered out

    // 6. Test All Orders query (including history)
    final allOrders = await customerOrderDao.getOrdersForProduct(product.id, activeOnly: false);
    expect(allOrders.length, 3);

    // 7. Test Product Order Summary & Stock Commitment Calculations
    final summary = await customerOrderDao.getProductOrderSummary(product.id);
    expect(summary['activeOrderCount'], 2);
    expect(summary['totalReservedQty'], 13.0); // 5 + 8
    expect(summary['totalPendingAmount'], 455000.0); // 175,000 + 280,000

    // Free available stock calculation
    final double freeStock = product.stockQty - (summary['totalReservedQty'] as double);
    expect(freeStock, 17.0); // 30 - 13 = 17 available
  });
}
