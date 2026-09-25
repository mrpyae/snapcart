import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/db_helper.dart';
import 'package:snapcart/app/data/local/category_dao.dart';
import 'package:snapcart/app/data/local/supplier_dao.dart';
import 'package:snapcart/app/data/local/purchase_dao.dart';
import 'package:snapcart/app/data/local/product_dao.dart';
import 'package:snapcart/app/data/local/customer_dao.dart';
import 'package:snapcart/app/data/models/category_model.dart';
import 'package:snapcart/app/data/models/supplier_model.dart';
import 'package:snapcart/app/data/models/supplier_payment_model.dart';
import 'package:snapcart/app/data/models/purchase_model.dart';
import 'package:snapcart/app/data/models/product_model.dart';
import 'package:snapcart/app/data/models/customer_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DBHelper.instance.close();
  });

  test('Category, Supplier, Purchase & Customer AP/AR Test Suite', () async {
    final categoryDao = CategoryDao();
    final supplierDao = SupplierDao();
    final purchaseDao = PurchaseDao();
    final productDao = ProductDao();
    final customerDao = CustomerDao();

    // 1. Category Creation Test
    final cat = CategoryModel(
      id: 'cat-test-01',
      name: 'ဝမ်းဆက် ချည်ထည်',
      description: 'Matching sets',
    );
    await categoryDao.insertOrUpdateCategory(cat);
    final categories = await categoryDao.getCategories();
    expect(categories.any((c) => c.id == 'cat-test-01'), true);

    // 2. Product Setup
    final product = ProductModel(
      id: 'prod-test-stock-01',
      name: 'ပိုးချည် ဝမ်းဆက်',
      categoryId: 'cat-test-01',
      retailPrice: 25000,
      costPrice: 15000,
      stockQty: 5.0,
    );
    await productDao.insertOrUpdateProduct(product);

    // 3. Supplier Setup
    final supplier = SupplierModel(
      id: 'sup-test-01',
      name: 'မန္တလေး ရွှေချည်ထည် ကုန်တိုက်',
      phone: '09777777777',
      payableBalance: 0.0,
    );
    await supplierDao.insertOrUpdateSupplier(supplier);

    // 4. Record Purchase & Stock In: 10 units @ 16,000 Ks (Total: 160,000 Ks, Paid: 60,000 Ks, Due: 100,000 Ks)
    final purchase = PurchaseModel(
      id: 'pur-test-01',
      invoiceNo: 'PUR-TEST-001',
      supplierId: supplier.id,
      supplierName: supplier.name,
      totalAmount: 160000,
      paidAmount: 60000,
      dueAmount: 100000,
      purchaseDate: DateTime.now().toIso8601String(),
      items: [
        PurchaseItemModel(
          id: 'pi-01',
          purchaseId: 'pur-test-01',
          productId: product.id,
          productName: product.name,
          costPrice: 16000,
          quantity: 10.0,
          subtotal: 160000,
        ),
      ],
    );

    await purchaseDao.savePurchaseOrder(purchase);

    // Verify Product Stock In: 5.0 + 10.0 = 15.0 units, cost updated to 16,000
    final updatedProducts = await productDao.searchProducts();
    final targetProduct = updatedProducts.firstWhere((p) => p.id == product.id);
    expect(targetProduct.stockQty, 15.0);
    expect(targetProduct.costPrice, 16000.0);

    // Verify Supplier Payable Debt: 100,000 Ks
    final updatedSupplier = await supplierDao.getSupplierById(supplier.id);
    expect(updatedSupplier != null, true);
    expect(updatedSupplier!.payableBalance, 100000.0);

    // 5. Supplier Debt Repayment: Pay 40,000 Ks on custom date
    const customPayDate = '2026-08-22T10:00:00.000';
    final payment = SupplierPaymentModel(
      id: 'sp-pay-01',
      supplierId: supplier.id,
      amount: 40000,
      type: 'PAYMENT',
      paymentDate: customPayDate,
    );
    await supplierDao.recordSupplierPayment(payment);

    final settledSupplier = await supplierDao.getSupplierById(supplier.id);
    expect(settledSupplier!.payableBalance, 60000.0); // 100,000 - 40,000 = 60,000

    // 5b. Record Advance Deposit for Supplier: 25,000 Ks with custom date
    const customAdvanceDate = '2026-08-25T15:30:00.000';
    final advancePayment = SupplierPaymentModel(
      id: 'sp-adv-01',
      supplierId: supplier.id,
      amount: 25000,
      type: 'ADVANCE',
      paymentDate: customAdvanceDate,
    );
    await supplierDao.recordSupplierPayment(advancePayment);

    final advSupplier = await supplierDao.getSupplierById(supplier.id);
    expect(advSupplier!.advanceBalance, 25000.0);
    expect(advSupplier.payableBalance, 60000.0);
    expect(advSupplier.hasDebt, true);
    expect(advSupplier.netBalance, -35000.0); // 25,000 advance - 60,000 debt

    final supPayments = await supplierDao.getSupplierPayments(supplier.id);
    expect(supPayments.length, 2);
    expect(supPayments.firstWhere((p) => p.id == 'sp-adv-01').paymentDate, customAdvanceDate);

    // 5c. Edit Supplier Payment Record: Edit sp-pay-01 from 40,000 to 50,000 Ks
    final updatedPayment = SupplierPaymentModel(
      id: 'sp-pay-01',
      supplierId: supplier.id,
      amount: 50000,
      type: 'PAYMENT',
      paymentDate: customPayDate,
      notes: 'Updated repayment amount',
    );
    await supplierDao.updateSupplierPayment(updatedPayment);

    final reSettledSupplier = await supplierDao.getSupplierById(supplier.id);
    expect(reSettledSupplier!.payableBalance, 50000.0); // 100,000 - 50,000 = 50,000

    final updatedPayments = await supplierDao.getSupplierPayments(supplier.id);
    final reFetchedPayment = updatedPayments.firstWhere((p) => p.id == 'sp-pay-01');
    expect(reFetchedPayment.amount, 50000.0);
    expect(reFetchedPayment.notes, 'Updated repayment amount');

    // 6. Customer Advance & Debt Test
    final customer = CustomerModel(
      id: 'cust-test-01',
      name: 'ဒေါ်အေးအေး',
      currentDebt: 30000,
      advanceBalance: 0.0,
    );
    await customerDao.insertOrUpdateCustomer(customer);

    // Record Advance Deposit: 15,000 Ks
    await customerDao.adjustCustomerAdvance(customer.id, 15000);
    final customers = await customerDao.getCustomers();
    final targetCustomer = customers.firstWhere((c) => c.id == customer.id);
    expect(targetCustomer.advanceBalance, 15000.0);

    // 7. Customer Search by Name and Phone Filter Test
    final custByName = await customerDao.getCustomers(query: 'အေးအေး');
    expect(custByName.isNotEmpty, true);
    expect(custByName.first.name, 'ဒေါ်အေးအေး');

    final newCust = CustomerModel(
      id: 'cust-pos-01',
      name: 'ဦးလှမောင်',
      phone: '09888888888',
      address: 'ရန်ကုန်',
    );
    await customerDao.insertOrUpdateCustomer(newCust);

    final custByPhone = await customerDao.getCustomers(query: '09888888888');
    expect(custByPhone.isNotEmpty, true);
    expect(custByPhone.first.id, 'cust-pos-01');
    expect(custByPhone.first.name, 'ဦးလှမောင်');
  });
}
