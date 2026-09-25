import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
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

  test('Customer Orders, Lead Source & Weaving Appointments Test Suite', () async {
    final db = await DBHelper.instance.database;
    await db.delete('customer_order_items');
    await db.delete('customer_orders');

    final orderDao = CustomerOrderDao();

    // 1. Create Customer Order with Messenger Lead Source & Loom Weaving Appointment
    final appointmentDate = DateTime.now().add(const Duration(days: 3)).toIso8601String();
    final order = CustomerOrderModel(
      id: 'cust-ord-test-01',
      orderNo: 'ORD-TEST-001',
      customerName: 'ဒေါ်နီနီဝင်း',
      customerPhone: '09778899112',
      customerAddress: 'အမရပူရ၊ မန္တလေး',
      orderSource: 'MESSENGER',
      leadAccount: 'SnapCart Silk Page',
      appointmentDate: appointmentDate,
      appointmentType: 'LOOM_WEAVING',
      status: 'PENDING',
      totalAmount: 120000,
      advanceAmount: 40000,
      dueAmount: 80000,
      notes: 'ရွှေချည်ထိုး အထူးဒီဇိုင်း',
      createdAt: DateTime.now().toIso8601String(),
      items: [
        CustomerOrderItemModel(
          id: 'item-01',
          customerOrderId: 'cust-ord-test-01',
          itemName: 'အမရပူရ ပိုးလွန်းကြင်',
          fabricType: 'ပိုးချည်စစ်စစ်',
          color: 'ရွှေဝါရောင်',
          quantity: 2.0,
          unit: 'set',
          unitPrice: 60000,
          subtotal: 120000,
          designNotes: 'ရင်ဖုံး လက်ရှည် ချုပ်လုပ်ရန်',
        ),
      ],
    );

    // Verify Model Getters
    expect(order.sourceLabel, 'Messenger');
    expect(order.appointmentTypeLabel, 'ရက္ကန်းနှင့်ချိတ်ဆက်ခြင်း');
    expect(order.statusLabel, 'စောင့်ဆိုင်းဆဲ');

    // Save Order
    await orderDao.saveCustomerOrder(order);

    // Retrieve Order
    final fetched = await orderDao.getCustomerOrderById('cust-ord-test-01');
    expect(fetched != null, true);
    expect(fetched!.customerName, 'ဒေါ်နီနီဝင်း');
    expect(fetched.orderSource, 'MESSENGER');
    expect(fetched.leadAccount, 'SnapCart Silk Page');
    expect(fetched.appointmentType, 'LOOM_WEAVING');
    expect(fetched.items.length, 1);
    expect(fetched.items.first.itemName, 'အမရပူရ ပိုးလွန်းကြင်');
    expect(fetched.dueAmount, 80000.0);

    // 2. Status Progression: PENDING -> CONFIRMED -> IN_PROGRESS -> READY_FOR_PICKUP -> COMPLETED
    await orderDao.updateOrderStatus(order.id, 'CONFIRMED');
    var updated = await orderDao.getCustomerOrderById(order.id);
    expect(updated!.status, 'CONFIRMED');
    expect(updated.statusLabel, 'အတည်ပြုပြီး');

    await orderDao.updateOrderStatus(order.id, 'IN_PROGRESS');
    updated = await orderDao.getCustomerOrderById(order.id);
    expect(updated!.status, 'IN_PROGRESS');
    expect(updated.statusLabel, 'ရက်လုပ်ဆဲ');

    await orderDao.updateOrderStatus(order.id, 'READY_FOR_PICKUP');
    updated = await orderDao.getCustomerOrderById(order.id);
    expect(updated!.status, 'READY_FOR_PICKUP');
    expect(updated.statusLabel, 'လာယူရန်အသင့်');

    await orderDao.updateOrderStatus(order.id, 'COMPLETED');
    updated = await orderDao.getCustomerOrderById(order.id);
    expect(updated!.status, 'COMPLETED');
    expect(updated.statusLabel, 'အပြီးသတ်လွှဲပြောင်းပြီး');

    // 3. Reschedule Appointment Test: Change to DELIVERY on new date
    final newDate = DateTime.now().add(const Duration(days: 5)).toIso8601String();
    await orderDao.rescheduleAppointment(order.id, newDate, appointmentType: 'DELIVERY');

    final rescheduled = await orderDao.getCustomerOrderById(order.id);
    expect(rescheduled!.appointmentDate, newDate);
    expect(rescheduled.appointmentType, 'DELIVERY');
    expect(rescheduled.appointmentTypeLabel, 'ပို့ဆောင်ခြင်း');

    // 4. Source & Status Query Filter Test
    final messengerOrders = await orderDao.getCustomerOrders(orderSource: 'MESSENGER');
    expect(messengerOrders.isNotEmpty, true);

    final viberOrders = await orderDao.getCustomerOrders(orderSource: 'VIBER');
    expect(viberOrders.isEmpty, true);

    // 5. Order Payment Recording (Partial & Full Settlement)
    final order2 = CustomerOrderModel(
      id: 'cust-ord-test-02',
      orderNo: 'ORD-TEST-002',
      customerName: 'ကိုအောင်ကို',
      customerPhone: '09445566778',
      orderSource: 'VIBER',
      leadAccount: 'Viber Sales',
      totalAmount: 100000,
      advanceAmount: 20000,
      dueAmount: 80000,
      status: 'READY_FOR_PICKUP',
      createdAt: DateTime.now().toIso8601String(),
    );
    await orderDao.saveCustomerOrder(order2);

    // Partial payment: Pay 30,000 Ks -> Remaining Due = 50,000 Ks
    await orderDao.recordOrderPayment('cust-ord-test-02', 30000, paymentMethod: 'kpay');
    var payFetched = await orderDao.getCustomerOrderById('cust-ord-test-02');
    expect(payFetched!.advanceAmount, 50000.0);
    expect(payFetched.dueAmount, 50000.0);
    expect(payFetched.status, 'READY_FOR_PICKUP');

    // Final settlement: Pay remaining 50,000 Ks -> Due = 0, Status = COMPLETED
    await orderDao.recordOrderPayment('cust-ord-test-02', 50000, paymentMethod: 'cash', markCompleted: true);
    payFetched = await orderDao.getCustomerOrderById('cust-ord-test-02');
    expect(payFetched!.advanceAmount, 100000.0);
    expect(payFetched.dueAmount, 0.0);
    expect(payFetched.status, 'COMPLETED');
    expect(payFetched.statusLabel, 'အပြီးသတ်လွှဲပြောင်းပြီး');

    // 6. Delete Customer Orders
    await orderDao.deleteCustomerOrder(order.id);
    await orderDao.deleteCustomerOrder(order2.id);
    final deleted = await orderDao.getCustomerOrderById(order.id);
    expect(deleted, null);
  });
}
