import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:snapcart/app/data/models/product_model.dart';
import 'package:snapcart/app/utils/image_similarity_service.dart';

void main() {
  test('High-Precision ImageSimilarityService Multi-Feature Visual Match Test', () {
    // 1. Solid Red Silk
    final redImg = img.Image(width: 48, height: 48);
    img.fill(redImg, color: img.ColorRgb8(255, 10, 10));
    final redBase64 = 'data:image/png;base64,${base64Encode(img.encodePng(redImg))}';

    // 2. Slightly different lighting / warm tone Red Silk
    final warmRedImg = img.Image(width: 48, height: 48);
    img.fill(warmRedImg, color: img.ColorRgb8(245, 25, 20));
    final warmRedBase64 = 'data:image/png;base64,${base64Encode(img.encodePng(warmRedImg))}';

    // 3. Floral / Patterned Red Fabric
    final floralRedImg = img.Image(width: 48, height: 48);
    img.fill(floralRedImg, color: img.ColorRgb8(255, 10, 10));
    for (int i = 0; i < 48; i += 4) {
      img.drawLine(floralRedImg, x1: 0, y1: i, x2: 47, y2: i, color: img.ColorRgb8(255, 255, 255));
    }
    final floralRedBase64 = 'data:image/png;base64,${base64Encode(img.encodePng(floralRedImg))}';

    // 4. Royal Blue Silk (Different color)
    final blueImg = img.Image(width: 48, height: 48);
    img.fill(blueImg, color: img.ColorRgb8(10, 30, 255));
    final blueBase64 = 'data:image/png;base64,${base64Encode(img.encodePng(blueImg))}';

    final products = [
      ProductModel(id: 'p1-exact-red', name: 'Plain Red Silk', retailPrice: 15000, imageUrl: redBase64),
      ProductModel(id: 'p2-warm-red', name: 'Warm Red Silk', retailPrice: 16000, imageUrl: warmRedBase64),
      ProductModel(id: 'p3-floral-red', name: 'Floral Red Fabric', retailPrice: 22000, imageUrl: floralRedBase64),
      ProductModel(id: 'p4-blue', name: 'Royal Blue Fabric', retailPrice: 18000, imageUrl: blueBase64),
    ];

    final results = ImageSimilarityService.instance.rankProducts(redBase64, products, minThreshold: 0.1);

    expect(results.isNotEmpty, true);
    // 1. Exact match is 100%
    expect(results[0].product.id, 'p1-exact-red');
    expect(results[0].percentage, 100);

    // 2. Warm lighting variant of red is #2
    expect(results[1].product.id, 'p2-warm-red');
    expect(results[1].percentage >= 80, true);

    // 3. Blue fabric is filtered / lowest rank
    final blueResult = results.firstWhere((r) => r.product.id == 'p4-blue');
    expect(blueResult.percentage < 30, true);
  });
}
