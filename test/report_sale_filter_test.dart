import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/data/local/sale_dao.dart';
import 'package:snapcart/app/data/local/customer_dao.dart';
import 'package:snapcart/app/data/models/sale_order_model.dart';
import 'package:snapcart/app/data/models/customer_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DBHelper.instance.close();
  });

  test('Sales Vouchers Report Filtering by Date Range, Customer & Voucher No Test Suite', () async {
    final saleDao = SaleDao();
    final customerDao = CustomerDao();
    const bizId = 'biz-report-filter';

    // 1. Create Test Customers
    final customer1 = CustomerModel(
      id: 'cust-filter-01',
      name: 'ဒေါ်သန်းသန်းဆွေ',
      phone: '0911223344',
      businessId: bizId,
    );
    final customer2 = CustomerModel(
      id: 'cust-filter-02',
      name: 'ဦးကျော်မင်း',
      phone: '0999887766',
      businessId: bizId,
    );
    await customerDao.insertOrUpdateCustomer(customer1);
    await customerDao.insertOrUpdateCustomer(customer2);

    // 2. Create Sale Orders with different dates
    final sale1 = SaleOrderModel(
      id: 'sale-test-01',
      businessId: bizId,
      voucherNo: 'VOC-20260820-001',
      customerId: 'cust-filter-01',
      userId: 'user-01',
      userAccountId: 'acc-01',
      userName: 'Cashier 1',
      subtotal: 50000,
      grandTotal: 50000,
      paidAmount: 50000,
      paymentMethod: 'kpay',
      saleDate: '2026-08-20 10:30:00',
      items: [
        SaleOrderItemModel(
          id: 'item-01',
          saleOrderId: 'sale-test-01',
          productId: 'prod-01',
          productName: 'ရိုးရာ ပိုးလွန်းကြင်',
          price: 50000,
          quantity: 1,
          total: 50000,
        ),
      ],
    );

    final sale2 = SaleOrderModel(
      id: 'sale-test-02',
      businessId: bizId,
      voucherNo: 'VOC-20260825-002',
      customerId: 'cust-filter-02',
      userId: 'user-01',
      userAccountId: 'acc-01',
      userName: 'Cashier 1',
      subtotal: 80000,
      grandTotal: 80000,
      paidAmount: 50000,
      dueAmount: 30000,
      paymentMethod: 'cash',
      saleDate: '2026-08-25 14:15:00',
      items: [
        SaleOrderItemModel(
          id: 'item-02',
          saleOrderId: 'sale-test-02',
          productId: 'prod-02',
          productName: 'ချည်ပွင့် ဝမ်းဆက်',
          price: 40000,
          quantity: 2,
          total: 80000,
        ),
      ],
    );

    await saleDao.saveSaleOrder(sale1);
    await saleDao.saveSaleOrder(sale2);

    // 3. Test Filter by Date Range: (2026-08-24 to 2026-08-26) -> Only sale2 should match
    final dateFiltered = await saleDao.getFilteredSales(
      businessId: bizId,
      startDate: DateTime(2026, 8, 24),
      endDate: DateTime(2026, 8, 26),
    );
    expect(dateFiltered.length, 1);
    expect(dateFiltered.first.voucherNo, 'VOC-20260825-002');
    expect(dateFiltered.first.customerName, 'ဦးကျော်မင်း');
    expect(dateFiltered.first.dueAmount, 30000.0);

    // 4. Test Filter by Customer Name: 'သန်းသန်း' -> Only sale1 should match
    final nameFiltered = await saleDao.getFilteredSales(
      businessId: bizId,
      query: 'သန်းသန်း',
    );
    expect(nameFiltered.length, 1);
    expect(nameFiltered.first.voucherNo, 'VOC-20260820-001');
    expect(nameFiltered.first.customerName, 'ဒေါ်သန်းသန်းဆွေ');

    // 5. Test Filter by Voucher Number: 'VOC-20260825'
    final voucherFiltered = await saleDao.getFilteredSales(
      businessId: bizId,
      query: 'VOC-20260825',
    );
    expect(voucherFiltered.length, 1);
    expect(voucherFiltered.first.voucherNo, 'VOC-20260825-002');

    // 6. Test All Vouchers for this business
    final allVouchers = await saleDao.getFilteredSales(businessId: bizId);
    expect(allVouchers.length, 2);
  });
}
