import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../../../data/models/sale_order_model.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/bluetooth_printer_service.dart';
import '../../../utils/receipt_printer_helper.dart';
import '../../../utils/voucher_pdf_service.dart';
import '../../settings/views/bluetooth_printer_dialog.dart';

class ReceiptDialog extends StatelessWidget {
  final SaleOrderModel order;
  final ScreenshotController screenshotController = ScreenshotController();

  ReceiptDialog({Key? key, required this.order}) : super(key: key);

  void _printReceipt() async {
    try {
      final savedMac = await BluetoothPrinterService.instance.getSavedPrinterMac();
      final savedName = await BluetoothPrinterService.instance.getSavedPrinterName();

      if (savedMac == null || savedMac.isEmpty) {
        Get.snackbar(
          'Printer Not Configured',
          'Please select a thermal Bluetooth printer to connect',
          backgroundColor: AppColors.warning,
          colorText: Colors.black,
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.dialog(const BluetoothPrinterDialog());
        return;
      }

      final isConnected = await BluetoothPrinterService.instance.isConnected();
      if (!isConnected) {
        Get.snackbar(
          'Connecting...',
          'Connecting to ${savedName ?? "Printer"}...',
          backgroundColor: AppColors.primaryLight.withOpacity(0.85),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        );
        final connected = await BluetoothPrinterService.instance.connect(savedMac);
        if (!connected) {
          Get.snackbar(
            'Connection Failed',
            'Could not connect to ${savedName ?? "Printer"}. Please verify it is powered on.',
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      final paperSizeStr = await BluetoothPrinterService.instance.getSavedPaperSize();
      final paperSize = (paperSizeStr == 'mm58') ? PaperSize.mm58 : PaperSize.mm80;

      final imageBytes = await screenshotController.captureFromWidget(
        ReceiptPrinterHelper.buildReceiptWidget(order),
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 100),
      );

      final printerHelper = ReceiptPrinterHelper();
      final bytes = await printerHelper.generateReceiptBytes(imageBytes, paperSize: paperSize);

      final success = await BluetoothPrinterService.instance.printBytes(bytes);
      if (success) {
        Get.snackbar(
          'Printing Complete',
          'Voucher ${order.voucherNo} printed to ${savedName ?? "Printer"}',
          backgroundColor: AppColors.success.withOpacity(0.85),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Print Failed',
          'Failed to send print commands to ${savedName ?? "Printer"}. Check paper roll.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar('Print Error', 'Could not print voucher: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void _printPdf(BuildContext context) async {
    try {
      await VoucherPdfService.instance.previewOrPrint(context, order);
    } catch (e) {
      Get.snackbar('PDF Error', 'Failed to generate PDF: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        width: screenWidth < 500 ? screenWidth * 0.95 : 480,
        padding: EdgeInsets.all(screenWidth < 460 ? 14 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: AppColors.primaryLight, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Voucher Receipt Preview',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 6),

            // Top action pill: Customize Voucher layout & Bluetooth Printer Setup
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Layout & Printing', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Get.dialog(const BluetoothPrinterDialog()),
                      icon: const Icon(Icons.settings_bluetooth_rounded, size: 14, color: AppColors.secondary),
                      label: const Text('Printer Setup', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () {
                        Get.back();
                        Get.toNamed(Routes.VOUCHER_BUILDER);
                      },
                      icon: const Icon(Icons.palette_outlined, size: 14, color: AppColors.primaryLight),
                      label: const Text('Customize Voucher', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            Container(
              constraints: const BoxConstraints(maxHeight: 380),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: ReceiptPrinterHelper.buildReceiptWidget(order),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons Row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _printPdf(context),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFF0284C7)),
                      label: const Text('Print PDF', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _printReceipt,
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Print Slip', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
