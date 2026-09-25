import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/data/local/product_dao.dart';
import 'package:snapcart/app/data/local/customer_dao.dart';
import 'package:snapcart/app/data/local/sale_dao.dart';
import 'package:snapcart/app/data/models/product_model.dart';
import 'package:snapcart/app/data/models/customer_model.dart';
import 'package:snapcart/app/data/models/sale_order_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DBHelper.instance.close();
  });

  test('Item Price History Recording, Customer Filtering & Urgent Retrieval Test', () async {
    final productDao = ProductDao();
    final customerDao = CustomerDao();
    final saleDao = SaleDao();

    // 1. Setup sample products
    final productA = ProductModel(
      id: 'prod-price-01',
      name: 'မြန်မာ့ချည်ထည် အဆင်လှ',
      retailPrice: 25000,
      wholesalePrice: 22000,
      stockQty: 100,
      unit: 'yard',
    );
    await productDao.insertOrUpdateProduct(productA);

    // 2. Setup sample customers
    final customer1 = CustomerModel(
      id: 'cust-price-01',
      name: 'Daw Myaing Myaing (Mandalay Wholesale)',
      phone: '09111222333',
    );
    final customer2 = CustomerModel(
      id: 'cust-price-02',
      name: 'U Kyaw Swar (Retail Walkin)',
      phone: '09444555666',
    );
    await customerDao.insertOrUpdateCustomer(customer1);
    await customerDao.insertOrUpdateCustomer(customer2);

    // 3. Record 12 sales with different prices, dates, and customers
    for (int i = 1; i <= 12; i++) {
      final cust = (i % 2 == 1) ? customer1 : customer2;
      final double soldPrice = (cust.id == customer1.id)
          ? 20000.0 + (i * 200) // Wholesale client gets custom lower tiered prices
          : 25000.0 - (i * 100); // Retail customer gets slight variation

      final dateDay = i < 10 ? '0$i' : '$i';
      final saleOrder = SaleOrderModel(
        id: 'so-price-$i',
        voucherNo: 'VCH-PH-$i',
        customerId: cust.id,
        userId: 'u-01',
        userAccountId: 'ua-01',
        userName: 'Admin Cashier',
        subtotal: soldPrice * 2,
        grandTotal: soldPrice * 2,
        paidAmount: soldPrice * 2,
        paymentMethod: 'cash',
        saleDate: '2026-09-${dateDay}T10:00:00.000Z',
        items: [
          SaleOrderItemModel(
            id: 'soi-price-$i',
            saleOrderId: 'so-price-$i',
            productId: productA.id,
            productName: productA.name,
            unit: 'yard',
            price: soldPrice,
            costPrice: 15000,
            quantity: 2.0,
            total: soldPrice * 2,
          ),
        ],
      );
      await saleDao.saveSaleOrder(saleOrder);
    }

    // 4. Urgent 10 Records Retrieval (Default Limit 10)
    final urgent10 = await saleDao.getProductPriceHistory(
      productId: productA.id,
      limit: 10,
    );
    expect(urgent10.length, 10);
    // Should be ordered by sale_date DESC (newest first: i=12, i=11, ...)
    expect(urgent10.first.voucherNo, 'VCH-PH-12');

    // 5. Customer-specific Filtering
    final cust1History = await saleDao.getProductPriceHistory(
      productId: productA.id,
      customerId: customer1.id,
      limit: 10,
    );
    expect(cust1History.length, 6);
    for (final record in cust1History) {
      expect(record.customerId, customer1.id);
      expect(record.customerName, contains('Daw Myaing Myaing'));
    }

    // 6. Latest Sold Price for Specific Customer
    final lastPriceCust1 = await saleDao.getLastPriceForCustomer(
      productId: productA.id,
      customerId: customer1.id,
    );
    expect(lastPriceCust1, isNotNull);
    // i=11 was the last sale for cust1 -> 20000 + (11 * 200) = 22200
    expect(lastPriceCust1, 22200.0);

    // 7. Date Range Filtering
    final dateFiltered = await saleDao.getProductPriceHistory(
      productId: productA.id,
      startDate: DateTime(2026, 9, 3),
      endDate: DateTime(2026, 9, 6),
      limit: 0, // No limit
    );
    expect(dateFiltered.length, 4); // Days 03, 04, 05, 06
  });
}
