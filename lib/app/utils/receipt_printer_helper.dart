import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../data/models/sale_order_model.dart';

class ReceiptPrinterHelper {
  final ScreenshotController screenshotController = ScreenshotController();

  // Generate ESC/POS byte commands from receipt widget image (Monochrome Raster)
  Future<List<int>> generateReceiptBytes(Uint8List imageBytes, {PaperSize paperSize = PaperSize.mm80}) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // Decode image and convert to monochrome bitmap
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage != null) {
      // Resize to fit printer width (576px for 80mm, 384px for 58mm)
      final targetWidth = paperSize == PaperSize.mm80 ? 576 : 384;
      final resized = img.copyResize(decodedImage, width: targetWidth, interpolation: img.Interpolation.average);

      // High-contrast binarization: converts antialiased grays into solid pitch-black (0) or white (255)
      for (var y = 0; y < resized.height; y++) {
        for (var x = 0; x < resized.width; x++) {
          final p = resized.getPixel(x, y);
          final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
          final v = lum < 185 ? 0 : 255;
          resized.setPixelRgba(x, y, v, v, v, 255);
        }
      }

      bytes += generator.imageRaster(resized, align: PosAlign.center);
      bytes += generator.feed(2);
      bytes += generator.cut();
    }

    return bytes;
  }

  // Thermal Receipt Widget for Myanmar Font rendering
  static Widget buildReceiptWidget(SaleOrderModel order, {String storeName = 'SnapCart Textile Shop', String storePhone = '09-123456789'}) {
    return Container(
      width: 380,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(storeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
          Text('ဖုန်း - $storePhone', style: const TextStyle(fontSize: 13, color: Colors.black)),
          const SizedBox(height: 8),
          const Divider(thickness: 1, color: Colors.black),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ဘောက်ချာ : ${order.voucherNo}', style: const TextStyle(fontSize: 12, color: Colors.black)),
              Text('ရက်စွဲ : ${order.saleDate.substring(0, 10)}', style: const TextStyle(fontSize: 12, color: Colors.black)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('အရောင်းဝန်ထမ်း : ${order.userName}', style: const TextStyle(fontSize: 12, color: Colors.black)),
              Text('ငွေချေမှု : ${order.paymentMethod.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.black)),
            ],
          ),
          const Divider(thickness: 1, color: Colors.black),
          // Items table
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(item.productName, style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('${item.quantity} ${item.unit}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('${item.total.toStringAsFixed(0)} Ks', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: Colors.black)),
                ),
              ],
            ),
          )),
          const Divider(thickness: 1, color: Colors.black),
          // Summary
          if (order.deliveryFee > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ပစ္စည်းတန်ဖိုး စုစုပေါင်း :', style: TextStyle(fontSize: 12, color: Colors.black)),
                Text('${(order.grandTotal - order.deliveryFee).toStringAsFixed(0)} Ks', style: const TextStyle(fontSize: 12, color: Colors.black)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ပို့ဆောင်ခ (Delivery Fee) :', style: TextStyle(fontSize: 12, color: Colors.black)),
                Text('${order.deliveryFee.toStringAsFixed(0)} Ks', style: const TextStyle(fontSize: 12, color: Colors.black)),
              ],
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('စုစုပေါင်း ကျသင့်ငွေ :', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
              Text('${order.grandTotal.toStringAsFixed(0)} Ks', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ပေးငွေ :', style: TextStyle(fontSize: 13, color: Colors.black)),
              Text('${order.paidAmount.toStringAsFixed(0)} Ks', style: const TextStyle(fontSize: 13, color: Colors.black)),
            ],
          ),
          if (order.dueAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ကျန်ငွေ (အကြွေး) :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                Text('${order.dueAmount.toStringAsFixed(0)} Ks', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          if (order.changeAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ပြန်အမ်းငွေ :', style: TextStyle(fontSize: 13, color: Colors.black)),
                Text('${order.changeAmount.toStringAsFixed(0)} Ks', style: const TextStyle(fontSize: 13, color: Colors.black)),
              ],
            ),
          // Delivery & COD Section
          if (order.deliveryType == 'DELIVERY' || order.isCod) ...[
            const Divider(thickness: 1, color: Colors.black),
            if (order.deliveryServiceName != null && order.deliveryServiceName!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ပို့ဆောင်ရေး (Delivery) :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                  Text(order.deliveryServiceName!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
            if (order.trackingNo != null && order.trackingNo!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tracking # :', style: TextStyle(fontSize: 12, color: Colors.black)),
                  Text(order.trackingNo!, style: const TextStyle(fontSize: 12, color: Colors.black)),
                ],
              ),
            if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('လိပ်စာ : ', style: TextStyle(fontSize: 11, color: Colors.black)),
                    Expanded(
                      child: Text(order.deliveryAddress!, style: const TextStyle(fontSize: 11, color: Colors.black)),
                    ),
                  ],
                ),
              ),
            if (order.isCod) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    const Text('★ ပစ္စည်းရောက်ငွေချေ (C.O.D) ★',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 2),
                    Text('ကောက်ခံရန်ငွေ : ${order.codAmount.toStringAsFixed(0)} Ks',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          const Text('ဝယ်ယူအားပေးမှုအတွက် ကျေးဇူးတင်ပါသည်', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black)),
        ],
      ),
    );
  }
}
