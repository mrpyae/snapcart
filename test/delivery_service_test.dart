import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/delivery_service_dao.dart';
import 'package:snapcart/app/data/local/sale_dao.dart';
import 'package:snapcart/app/data/models/delivery_service_model.dart';
import 'package:snapcart/app/data/models/sale_order_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('In-House Delivery Service and Rider Commission Test Suite', () async {
    final deliveryDao = DeliveryServiceDao();
    final saleDao = SaleDao();
    const testBiz = 'biz-delivery-test-01';

    // 1. Create In-House Salary Rider
    final salaryRider = DeliveryServiceModel(
      id: 'rider-salary-01',
      businessId: testBiz,
      name: 'Ko Kyaw (Salary Rider)',
      serviceType: 'IN_HOUSE',
      riderType: 'SALARY',
      defaultDeliveryFee: 1500.0,
      phone: '09111222333',
    );
    await deliveryDao.saveDeliveryService(salaryRider);
    expect(salaryRider.isInHouse, true);
    expect(salaryRider.isCommissionBased, false);
    expect(salaryRider.calculateCommission(1500.0), 0.0);

    // 2. Create In-House Commission Rider (% based)
    final percentRider = DeliveryServiceModel(
      id: 'rider-percent-02',
      businessId: testBiz,
      name: 'Ko Aung (20% Commission Rider)',
      serviceType: 'IN_HOUSE',
      riderType: 'COMMISSION',
      commissionType: 'PERCENT',
      commissionVal: 20.0,
      defaultDeliveryFee: 2500.0,
      phone: '09444555666',
    );
    await deliveryDao.saveDeliveryService(percentRider);
    expect(percentRider.isInHouse, true);
    expect(percentRider.isCommissionBased, true);
    // 20% of 2,500 Ks = 500 Ks
    expect(percentRider.calculateCommission(2500.0), 500.0);

    // 3. Create In-House Commission Rider (Fixed Ks based)
    final fixedRider = DeliveryServiceModel(
      id: 'rider-fixed-03',
      businessId: testBiz,
      name: 'Ko Myo (1,000 Ks Fixed Rider)',
      serviceType: 'IN_HOUSE',
      riderType: 'COMMISSION',
      commissionType: 'FIXED',
      commissionVal: 1000.0,
      defaultDeliveryFee: 3000.0,
      phone: '09777888999',
    );
    await deliveryDao.saveDeliveryService(fixedRider);
    expect(fixedRider.calculateCommission(3000.0), 1000.0);

    // 4. Create External Courier
    final externalCourier = DeliveryServiceModel(
      id: 'courier-ext-04',
      businessId: testBiz,
      name: 'Royal Express',
      serviceType: 'EXTERNAL',
      receivableBalance: 0.0,
    );
    await deliveryDao.saveDeliveryService(externalCourier);
    expect(externalCourier.isInHouse, false);

    // 5. Create Sales Orders with In-House Delivery
    final now = DateTime.now();
    final order1 = SaleOrderModel(
      id: 'sale-del-01',
      businessId: testBiz,
      voucherNo: 'VOU-DEL-01',
      userId: 'user-01',
      userAccountId: 'acc-01',
      userName: 'Cashier',
      subtotal: 50000.0,
      deliveryFee: 2500.0,
      grandTotal: 52500.0,
      paidAmount: 52500.0,
      paymentMethod: 'cash',
      saleStatus: 'PAID',
      saleDate: now.toIso8601String(),
      deliveryType: 'DELIVERY',
      deliveryServiceId: percentRider.id,
      deliveryServiceName: percentRider.name,
      riderCommissionAmount: percentRider.calculateCommission(2500.0), // 500 Ks
    );
    await saleDao.saveSaleOrder(order1);

    final order2 = SaleOrderModel(
      id: 'sale-del-02',
      businessId: testBiz,
      voucherNo: 'VOU-DEL-02',
      userId: 'user-01',
      userAccountId: 'acc-01',
      userName: 'Cashier',
      subtotal: 30000.0,
      deliveryFee: 1500.0,
      grandTotal: 31500.0,
      paidAmount: 31500.0,
      paymentMethod: 'kpay',
      saleStatus: 'PAID',
      saleDate: now.toIso8601String(),
      deliveryType: 'DELIVERY',
      deliveryServiceId: salaryRider.id,
      deliveryServiceName: salaryRider.name,
      riderCommissionAmount: 0.0,
    );
    await saleDao.saveSaleOrder(order2);

    // 6. Test In-House Delivery Income Summary
    final summary = await deliveryDao.getInHouseDeliveryIncomeSummary(
      businessId: testBiz,
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 1)),
    );

    expect(summary['total_trips'], 2);
    expect(summary['total_delivery_income'], 4000.0); // 2500 + 1500
    expect(summary['total_rider_commission'], 500.0); // 500 + 0
    expect(summary['net_delivery_income'], 3500.0); // 4000 - 500

    // Filter by specific rider
    final riderSummary = await deliveryDao.getInHouseDeliveryIncomeSummary(
      businessId: testBiz,
      riderId: percentRider.id,
    );
    expect(riderSummary['total_trips'], 1);
    expect(riderSummary['total_delivery_income'], 2500.0);
    expect(riderSummary['total_rider_commission'], 500.0);
  });
}
