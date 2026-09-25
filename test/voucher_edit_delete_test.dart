import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/data/local/product_dao.dart';
import 'package:snapcart/app/data/local/customer_dao.dart';
import 'package:snapcart/app/data/local/sale_dao.dart';
import 'package:snapcart/app/data/local/user_dao.dart';
import 'package:snapcart/app/data/local/delivery_service_dao.dart';
import 'package:snapcart/app/data/models/product_model.dart';
import 'package:snapcart/app/data/models/customer_model.dart';
import 'package:snapcart/app/data/models/sale_order_model.dart';
import 'package:snapcart/app/data/models/delivery_service_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DBHelper.instance.close();
  });

  test('Owner Passcode Verification & Voucher Edit/Delete Test Suite', () async {
    final userDao = UserDao();
    final saleDao = SaleDao();
    final productDao = ProductDao();
    final customerDao = CustomerDao();
    final deliveryDao = DeliveryServiceDao();

    // 1. Verify Owner Passcode logic
    // Default seeded owner has passcode '1234'
    final isOwnerValid = await userDao.verifyOwnerPasscode('1234');
    expect(isOwnerValid, true, reason: 'Owner with passcode 1234 should verify successfully');

    final isWrongValid = await userDao.verifyOwnerPasscode('9999');
    expect(isWrongValid, false, reason: 'Incorrect passcode should fail');

    // Default seeded cashier has passcode '0000', but is NOT an owner
    final isCashierPasscodeOwner = await userDao.verifyOwnerPasscode('0000');
    expect(isCashierPasscodeOwner, false, reason: 'Cashier passcode must not pass owner verification');

    // 2. Setup test product, customer, delivery service
    final testProduct = ProductModel(
      id: 'prod-void-01',
      name: 'Test Fabric Roll',
      retailPrice: 25000,
      stockQty: 50.0,
      unit: 'yard',
    );
    await productDao.insertOrUpdateProduct(testProduct);

    final testCustomer = CustomerModel(
      id: 'cust-void-01',
      name: 'Daw Hla Khin',
      phone: '09777888999',
      currentDebt: 0.0,
    );
    await customerDao.insertOrUpdateCustomer(testCustomer);

    final testCourier = DeliveryServiceModel(
      id: 'ds-void-01',
      name: 'Royal Express COD',
      phone: '0912345678',
      serviceType: 'EXTERNAL',
      receivableBalance: 0.0,
    );
    await deliveryDao.saveDeliveryService(testCourier);

    // Initial stock check
    final initialProd = await productDao.getProductById('prod-void-01');
    expect(initialProd!.stockQty, 50.0);

    // 3. Create a Sale Voucher with 5 units sold on credit + COD delivery
    final order = SaleOrderModel(
      id: 'sale-void-001',
      voucherNo: 'V-VOID-1001',
      customerId: 'cust-void-01',
      customerName: 'Daw Hla Khin',
      userId: 'usr-admin-001',
      userAccountId: 'acc-admin-main',
      userName: 'Admin',
      subtotal: 125000,
      grandTotal: 125000,
      paidAmount: 25000,
      dueAmount: 100000, // 100,000 credit debt
      paymentMethod: 'cash',
      saleStatus: 'PARTIAL',
      saleDate: DateTime.now().toIso8601String(),
      isCod: true,
      codAmount: 100000,
      deliveryServiceId: 'ds-void-01',
      deliveryServiceName: 'Royal Express COD',
      items: [
        SaleOrderItemModel(
          id: 'item-void-01',
          saleOrderId: 'sale-void-001',
          productId: 'prod-void-01',
          productName: 'Test Fabric Roll',
          price: 25000,
          quantity: 5.0,
          total: 125000,
          unit: 'yard',
        ),
      ],
    );

    await saleDao.saveSaleOrder(order);

    // Verify after checkout:
    // Stock should be 50 - 5 = 45
    final afterSaleProd = await productDao.getProductById('prod-void-01');
    expect(afterSaleProd!.stockQty, 45.0);

    // Customer debt should be +100,000
    final afterSaleCust = await customerDao.getCustomerById('cust-void-01');
    expect(afterSaleCust!.currentDebt, 100000.0);

    // Courier receivable should be +100,000
    final afterSaleCourier = (await deliveryDao.getActiveDeliveryServices())
        .firstWhere((d) => d.id == 'ds-void-01');
    expect(afterSaleCourier.receivableBalance, 100000.0);

    // 4. Test In-Place Header Update (e.g. customer pays extra 50,000 Ks)
    await saleDao.updateSaleOrderHeader(
      orderId: 'sale-void-001',
      paymentMethod: 'kpay',
      paidAmount: 75000,
      dueAmount: 50000, // Due reduced from 100,000 to 50,000
      saleStatus: 'PARTIAL',
      customerId: 'cust-void-01',
      notes: 'Customer transferred 50k via KPay',
    );

    final updatedOrder = await saleDao.getSaleOrderById('sale-void-001');
    expect(updatedOrder!.paymentMethod, 'kpay');
    expect(updatedOrder.paidAmount, 75000);
    expect(updatedOrder.dueAmount, 50000);

    // Customer debt should have adjusted down to 50,000
    final afterEditCust = await customerDao.getCustomerById('cust-void-01');
    expect(afterEditCust!.currentDebt, 50000.0);

    // 5. Test Delete / Void Voucher
    await saleDao.deleteSaleOrder('sale-void-001');

    // Order should no longer exist
    final deletedOrder = await saleDao.getSaleOrderById('sale-void-001');
    expect(deletedOrder, isNull);

    // Stock MUST be fully restored back to 50.0!
    final restoredProd = await productDao.getProductById('prod-void-01');
    expect(restoredProd!.stockQty, 50.0, reason: 'Voiding voucher must restore sold quantity back to inventory');

    // Customer debt MUST be reduced back to 0.0!
    final restoredCust = await customerDao.getCustomerById('cust-void-01');
    expect(restoredCust!.currentDebt, 0.0, reason: 'Voiding credit voucher must clear remaining customer debt');

    // Courier COD receivable MUST be cleared!
    final restoredCourier = (await deliveryDao.getActiveDeliveryServices())
        .firstWhere((d) => d.id == 'ds-void-01');
    expect(restoredCourier.receivableBalance, 0.0, reason: 'Voiding COD voucher must reverse courier receivable balance');
  });
}
