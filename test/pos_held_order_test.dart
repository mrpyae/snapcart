import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/data/local/product_dao.dart';
import 'package:snapcart/app/data/local/customer_dao.dart';
import 'package:snapcart/app/data/local/sale_dao.dart';
import 'package:snapcart/app/data/local/held_order_dao.dart';
import 'package:snapcart/app/data/models/product_model.dart';
import 'package:snapcart/app/data/models/customer_model.dart';
import 'package:snapcart/app/data/models/held_order_model.dart';
import 'package:snapcart/app/data/models/sale_order_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DBHelper.instance.close();
  });

  test('POS Partial Payment, Held Orders & Product Status Test Suite', () async {
    final productDao = ProductDao();
    final customerDao = CustomerDao();
    final saleDao = SaleDao();
    final heldOrderDao = HeldOrderDao();

    // 1. Product Status Test
    final prodAvailable = ProductModel(
      id: 'p-status-01',
      name: 'ချည်ပွင့် ရင်စေ့',
      retailPrice: 20000,
      productStatus: 'AVAILABLE',
    );
    final prodOutOfStock = ProductModel(
      id: 'p-status-02',
      name: 'ပိုးလွန်းကြင်',
      retailPrice: 45000,
      productStatus: 'OUT_OF_STOCK',
    );
    final prodDiscontinued = ProductModel(
      id: 'p-status-03',
      name: 'ရွှေဇာ အင်္ကျီဟောင်း',
      retailPrice: 15000,
      productStatus: 'DISCONTINUED',
    );

    expect(prodAvailable.isAvailable, true);
    expect(prodAvailable.statusLabel, 'ရောင်းရန်ရှိ');
    expect(prodOutOfStock.isOutOfStock, true);
    expect(prodOutOfStock.statusLabel, 'ပစ္စည်းပြတ်');
    expect(prodDiscontinued.isDiscontinued, true);
    expect(prodDiscontinued.statusLabel, 'ရပ်ဆိုင်း');

    await productDao.insertOrUpdateProduct(prodAvailable);
    await productDao.insertOrUpdateProduct(prodOutOfStock);
    await productDao.insertOrUpdateProduct(prodDiscontinued);

    final searched = await productDao.searchProducts(query: 'လွန်းကြင်');
    expect(searched.first.productStatus, 'OUT_OF_STOCK');

    // 2. Customer Setup & Partial Payment Test
    final customer = CustomerModel(
      id: 'cust-pos-partial-01',
      name: 'ဒေါ်သန်းသန်းစိုး',
      phone: '09444444444',
      currentDebt: 0.0,
    );
    await customerDao.insertOrUpdateCustomer(customer);

    // Sale order with Grand Total: 50,000 Ks, Paid: 20,000 Ks, Due (Debt): 30,000 Ks
    final partialSale = SaleOrderModel(
      id: 'sale-partial-01',
      voucherNo: 'VOU-TEST-PARTIAL',
      customerId: customer.id,
      userId: 'user-01',
      userAccountId: 'account-01',
      userName: 'Cashier 1',
      subtotal: 50000,
      grandTotal: 50000,
      paidAmount: 20000,
      dueAmount: 30000,
      saleStatus: 'PARTIAL',
      paymentMethod: 'cash',
      saleDate: DateTime.now().toIso8601String(),
      items: [
        SaleOrderItemModel(
          id: 'item-01',
          saleOrderId: 'sale-partial-01',
          productId: prodAvailable.id,
          productName: prodAvailable.name,
          quantity: 2.5,
          price: 20000,
          total: 50000,
        ),
      ],
    );

    await saleDao.saveSaleOrder(partialSale);

    final updatedCust = await customerDao.getCustomers(query: 'သန်းသန်းစိုး');
    expect(updatedCust.first.currentDebt, 30000.0);

    // 3. Held Order (Draft / Parked Order) Lifecycle Test
    final heldOrder = HeldOrderModel(
      id: 'held-test-01',
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      items: [
        HeldOrderItemModel(
          productId: prodAvailable.id,
          productName: prodAvailable.name,
          quantity: 2.0,
          price: 20000.0,
        ),
        HeldOrderItemModel(
          productId: prodOutOfStock.id,
          productName: prodOutOfStock.name,
          quantity: 1.0,
          price: 45000.0,
        ),
      ],
      subtotal: 85000,
      discount: 5000,
      grandTotal: 80000,
      notes: 'Customer getting money from ATM',
      createdAt: DateTime.now().toIso8601String(),
    );

    // Save Held Order
    await heldOrderDao.saveHeldOrder(heldOrder);

    // Retrieve list of Held Orders
    final heldList = await heldOrderDao.getHeldOrders();
    expect(heldList.any((h) => h.id == 'held-test-01'), true);
    final fetched = heldList.firstWhere((h) => h.id == 'held-test-01');
    expect(fetched.items.length, 2);
    expect(fetched.grandTotal, 80000.0);
    expect(fetched.notes, 'Customer getting money from ATM');
    expect(fetched.customerName, 'ဒေါ်သန်းသန်းစိုး');

    // Delete / Resume Held Order
    await heldOrderDao.deleteHeldOrder('held-test-01');
    final afterDelete = await heldOrderDao.getHeldOrders();
    expect(afterDelete.any((h) => h.id == 'held-test-01'), false);
  });
}
