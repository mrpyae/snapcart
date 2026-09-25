import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/data/local/sync_dao.dart';
import 'package:snapcart/app/data/local/customer_order_dao.dart';
import 'package:snapcart/app/data/models/customer_order_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DBHelper.instance.close();
  });

  test('Customer Orders 2-Way Sync Engine Test (Push & Delta Ingestion)', () async {
    final syncDao = SyncDao();
    final customerOrderDao = CustomerOrderDao();
    final db = await DBHelper.instance.database;

    // 1. Create a customer order offline with sync_status = 0
    final testOrder = CustomerOrderModel(
      id: 'co-sync-test-01',
      orderNo: 'CO-SYNC-001',
      customerName: 'Daw Thuzar',
      customerPhone: '09555123456',
      totalAmount: 45000.0,
      advanceAmount: 15000.0,
      dueAmount: 30000.0,
      syncStatus: 0,
      createdAt: DateTime.now().toIso8601String(),
      items: [
        CustomerOrderItemModel(
          id: 'item-sync-test-01',
          customerOrderId: 'co-sync-test-01',
          itemName: 'Silk Cheongsam Custom Dress',
          fabricType: 'Silk',
          quantity: 1,
          unitPrice: 45000.0,
          subtotal: 45000.0,
          syncStatus: 0,
        ),
      ],
    );

    await customerOrderDao.saveCustomerOrder(testOrder);

    // Manually mark sync_status = 0 for the test
    await db.rawUpdate('UPDATE customer_orders SET sync_status = 0 WHERE id = ?', [testOrder.id]);
    await db.rawUpdate('UPDATE customer_order_items SET sync_status = 0 WHERE customer_order_id = ?', [testOrder.id]);

    // 2. Test getPendingPushPayload includes customer_orders
    final payload = await syncDao.getPendingPushPayload();
    expect(payload.containsKey('customer_orders'), isTrue);
    final List pendingCO = payload['customer_orders'];
    expect(pendingCO.any((e) => e['id'] == 'co-sync-test-01'), isTrue);

    final pushedOrder = pendingCO.firstWhere((e) => e['id'] == 'co-sync-test-01');
    expect(pushedOrder['items'], isNotNull);
    expect((pushedOrder['items'] as List).isNotEmpty, isTrue);

    // 3. Test markSynced updates sync_status to 1
    await syncDao.markSynced({
      'customer_orders': ['co-sync-test-01'],
    });

    final res = await db.query('customer_orders', where: 'id = ?', whereArgs: ['co-sync-test-01']);
    expect(res.first['sync_status'], 1);

    // 4. Test batchSaveCustomerOrders (Ingesting delta pulled from server)
    final deltaOrders = [
      {
        'id': 'co-server-delta-02',
        'order_no': 'CO-SERVER-002',
        'customer_name': 'U Kyaw Swar',
        'customer_phone': '09888777666',
        'total_amount': 60000.0,
        'advance_amount': 20000.0,
        'due_amount': 40000.0,
        'status': 'CONFIRMED',
        'created_at': DateTime.now().toIso8601String(),
        'items': [
          {
            'id': 'item-delta-02',
            'item_name': 'Traditional Silk Longyi',
            'quantity': 2.0,
            'unit_price': 30000.0,
            'subtotal': 60000.0,
          }
        ]
      }
    ];

    await customerOrderDao.batchSaveCustomerOrders(deltaOrders);

    final deltaCheck = await db.query('customer_orders', where: 'id = ?', whereArgs: ['co-server-delta-02']);
    expect(deltaCheck.isNotEmpty, isTrue);
    expect(deltaCheck.first['customer_name'], 'U Kyaw Swar');

    final deltaItemCheck = await db.query('customer_order_items', where: 'customer_order_id = ?', whereArgs: ['co-server-delta-02']);
    expect(deltaItemCheck.isNotEmpty, isTrue);
    expect(deltaItemCheck.first['item_name'], 'Traditional Silk Longyi');
  });
}
