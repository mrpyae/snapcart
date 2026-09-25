import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:snapcart/app/data/local/product_dao.dart';
import 'package:snapcart/app/data/models/product_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Save and retrieve product test', () async {
    final dao = ProductDao();
    final p = ProductModel(
      id: 'test-prod-123',
      name: 'Test Fabric',
      retailPrice: 25000.0,
      wholesalePrice: 20000.0,
      stockQty: 50.0,
      fabricType: 'Silk',
    );

    await dao.insertOrUpdateProduct(p);
    final results = await dao.searchProducts(query: 'Test');
    expect(results.any((x) => x.id == 'test-prod-123'), true);
  });
}
