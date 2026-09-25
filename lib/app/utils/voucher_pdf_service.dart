import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:rabbit_converter/rabbit_converter.dart';
import 'package:get/get.dart';
import '../data/local/db_helper.dart';
import '../data/models/sale_order_model.dart';
import '../data/models/voucher_template_model.dart';
import 'pdf_web_helper.dart';
import 'zawgyi_font_fallback.dart';

class VoucherPdfService {
  static final VoucherPdfService instance = VoucherPdfService._();
  VoucherPdfService._();

  static pw.Font? _cachedMainFont;


  // Convert any text from Unicode to Zawgyi for pure vector PDF rendering
  static String zg(String? text) {
    if (text == null || text.isEmpty) return '';
    return Rabbit.uni2zg(text);
  }

  // Load active template from SQLite or return default
  Future<VoucherTemplateModel> getActiveTemplate() async {
    try {
      final jsonStr = await DBHelper.instance.getSetting('voucher_template_settings');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return VoucherTemplateModel.fromJson(jsonStr);
      }
    } catch (_) {}
    return VoucherTemplateModel.defaultTemplate();
  }

  // Save customized template to SQLite
  Future<void> saveTemplate(VoucherTemplateModel template) async {
    await DBHelper.instance.setSetting('voucher_template_settings', template.toJson());
  }

  // Generate Native Vector PDF Document
  Future<Uint8List> generateVoucherPdf(
    SaleOrderModel order, {
    VoucherTemplateModel? template,
    PdfPageFormat? customFormat,
  }) async {
    final tpl = template ?? await getActiveTemplate();

    // Determine Page Format
    PdfPageFormat pageFormat;
    if (customFormat != null) {
      pageFormat = customFormat;
    } else {
      switch (tpl.paperSize) {
        case 'mm58':
          pageFormat = PdfPageFormat.roll57;
          break;
        case 'a4':
          pageFormat = PdfPageFormat.a4;
          break;
        case 'a5':
          pageFormat = PdfPageFormat.a5;
          break;
        case 'mm80':
        default:
          pageFormat = PdfPageFormat.roll80;
          break;
      }
    }

    final doc = pw.Document();

    // Load TrueType Zawgyi font from local assets with fail-safe embedded fallback
    pw.Font mainFont;
    if (_cachedMainFont != null) {
      mainFont = _cachedMainFont!;
    } else {
      try {
        final regularData = await rootBundle.load('assets/fonts/Zawgyi-One.ttf');
        mainFont = pw.Font.ttf(regularData);
      } catch (e) {
        debugPrint('Notice: rootBundle could not load assets/fonts/Zawgyi-One.ttf ($e). Using fail-safe embedded Zawgyi font.');
        mainFont = pw.Font.ttf(ByteData.view(embeddedZawgyiFontBytes.buffer));
      }
      _cachedMainFont = mainFont;
    }


    final isThermalRoll = tpl.paperSize == 'mm80' || tpl.paperSize == 'mm58';
    final primaryColor = PdfColor.fromInt(tpl.primaryColorValue);

    // Prepare logo image if present
    pw.MemoryImage? logoImage;
    if (tpl.showLogo && tpl.logoBase64 != null && tpl.logoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(tpl.logoBase64!);
        logoImage = pw.MemoryImage(bytes);
      } catch (_) {}
    }

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: isThermalRoll
            ? const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 10)
            : const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: mainFont, bold: mainFont, fontFallback: [mainFont]),
        build: (pw.Context context) {
          if (isThermalRoll) {
            return _buildThermalSlipLayout(order, tpl, primaryColor, logoImage, mainFont);
          } else {
            return _buildInvoiceSheetLayout(order, tpl, primaryColor, logoImage, mainFont);
          }
        },
      ),
    );

    return await doc.save();
  }

  // 80mm & 58mm Thermal Roll Vector Layout
  pw.Widget _buildThermalSlipLayout(
    SaleOrderModel order,
    VoucherTemplateModel tpl,
    PdfColor primaryColor,
    pw.MemoryImage? logoImage,
    pw.Font mainFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Logo
        if (logoImage != null) ...[
          pw.Center(
            child: pw.Container(
              height: 48,
              width: 100,
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
          ),
          pw.SizedBox(height: 4),
        ],

        // Shop Name & Header
        pw.Text(
          zg(tpl.storeName),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: mainFont),
        ),
        if (tpl.showShopDetails && tpl.storeTagline.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            zg(tpl.storeTagline),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700, font: mainFont),
          ),
        ],
        if (tpl.showShopDetails && tpl.storePhone.isNotEmpty) ...[
          pw.SizedBox(height: 1),
          pw.Text(
            zg('Ph: ${tpl.storePhone}'),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8.5, font: mainFont),
          ),
        ],
        if (tpl.showShopDetails && tpl.storeAddress.isNotEmpty) ...[
          pw.SizedBox(height: 1),
          pw.Text(
            zg(tpl.storeAddress),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, font: mainFont),
          ),
        ],

        pw.SizedBox(height: 6),
        pw.Divider(thickness: 0.8, color: PdfColors.black),
        pw.SizedBox(height: 4),

        // Order Metadata
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(zg('Voucher: ${order.voucherNo}'), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, font: mainFont)),
            pw.Text(zg('Date: ${order.saleDate.substring(0, 10)}'), style: pw.TextStyle(fontSize: 8.5, font: mainFont)),
          ],
        ),
        if (tpl.showCashier)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(zg('Cashier: ${order.userName}'), style: pw.TextStyle(fontSize: 8, font: mainFont)),
              if (tpl.showPaymentMethod)
                pw.Text(zg('Pay: ${order.paymentMethod.toUpperCase()}'), style: pw.TextStyle(fontSize: 8, font: mainFont)),
            ],
          ),
        if (tpl.showCustomer && (order.customerName != null || order.customerPhone != null)) ...[
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(zg('Customer: ${order.customerName ?? "-"}'), style: pw.TextStyle(fontSize: 8, font: mainFont)),
              if (order.customerPhone != null)
                pw.Text(zg('Ph: ${order.customerPhone}'), style: pw.TextStyle(fontSize: 8, font: mainFont)),
            ],
          ),
        ],

        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.8, color: PdfColors.black),
        pw.SizedBox(height: 4),

        // Table Header
        pw.Row(
          children: [
            pw.Expanded(flex: 5, child: pw.Text(zg('Item'), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, font: mainFont))),
            pw.Expanded(flex: 2, child: pw.Text(zg('Qty'), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, font: mainFont))),
            pw.Expanded(flex: 3, child: pw.Text(zg('Total'), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, font: mainFont))),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),

        // Items List
        ...order.items.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(zg(item.productName), style: pw.TextStyle(fontSize: 8.5, font: mainFont)),
                    pw.Text(zg('${item.price.toStringAsFixed(0)} Ks x ${item.quantity} ${item.unit}'), style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700, font: mainFont)),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(zg('${item.quantity}'), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8.5, font: mainFont)),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(zg('${item.total.toStringAsFixed(0)} Ks'), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, font: mainFont)),
              ),
            ],
          ),
        )),

        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.8, color: PdfColors.black),
        pw.SizedBox(height: 4),

        // Financial Summary
        _buildSlipSummaryRow(zg('Subtotal:'), zg('${order.subtotal.toStringAsFixed(0)} Ks'), font: mainFont),
        if (tpl.showTaxAndDiscount && order.discountAmount > 0)
          _buildSlipSummaryRow(zg('Discount:'), zg('-${order.discountAmount.toStringAsFixed(0)} Ks'), font: mainFont),
        if (tpl.showTaxAndDiscount && order.taxAmount > 0)
          _buildSlipSummaryRow(zg('Tax:'), zg('+${order.taxAmount.toStringAsFixed(0)} Ks'), font: mainFont),
        if (tpl.showDeliveryDetails && order.deliveryFee > 0)
          _buildSlipSummaryRow(zg('Delivery Fee:'), zg('+${order.deliveryFee.toStringAsFixed(0)} Ks'), font: mainFont),

        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(zg('Grand Total:'), style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, font: mainFont)),
            pw.Text(zg('${order.grandTotal.toStringAsFixed(0)} Ks'), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: mainFont)),
          ],
        ),
        pw.SizedBox(height: 2),
        _buildSlipSummaryRow(zg(Get.locale?.languageCode == 'my' ? 'ပေးငွေ:' : 'Paid Amount:'), zg('${order.paidAmount.toStringAsFixed(0)} Ks'), font: mainFont),
        if (order.dueAmount > 0)
          _buildSlipSummaryRow(zg(Get.locale?.languageCode == 'my' ? 'အကြွေး:' : 'Due Amount:'), zg('${order.dueAmount.toStringAsFixed(0)} Ks'), isBold: true, color: PdfColors.red700, font: mainFont),
        if (order.changeAmount > 0)
          _buildSlipSummaryRow(zg(Get.locale?.languageCode == 'my' ? 'ပြန်အမ်း:' : 'Change:'), zg('${order.changeAmount.toStringAsFixed(0)} Ks'), font: mainFont),

        // Delivery info
        if (tpl.showDeliveryDetails && (order.deliveryType == 'DELIVERY' || order.isCod)) ...[
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 0.5, color: PdfColors.grey500),
          if (order.deliveryServiceName != null && order.deliveryServiceName!.isNotEmpty)
            _buildSlipSummaryRow(zg('Delivery:'), zg(order.deliveryServiceName!), font: mainFont),
          if (order.trackingNo != null && order.trackingNo!.isNotEmpty)
            _buildSlipSummaryRow(zg('Tracking:'), zg(order.trackingNo!), font: mainFont),
          if (order.isCod)
            _buildSlipSummaryRow(zg('COD Amount:'), zg('${order.codAmount.toStringAsFixed(0)} Ks'), isBold: true, font: mainFont),
        ],

        // Barcode / QR Code
        if (tpl.showBarcode) ...[
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: order.voucherNo,
              width: 140,
              height: 28,
              drawText: true,
              textStyle: pw.TextStyle(font: mainFont, fontSize: 7),
            ),
          ),
        ],

        // Notes & Policy
        if (tpl.thankYouNote.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            zg(tpl.thankYouNote),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, font: mainFont),
          ),
        ],
        if (tpl.policyNote.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            zg(tpl.policyNote),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700, font: mainFont),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildSlipSummaryRow(String title, String val, {bool isBold = false, PdfColor? color, required pw.Font font}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 8.5, color: color ?? PdfColors.grey900)),
          pw.Text(val, style: pw.TextStyle(font: font, fontSize: 8.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? PdfColors.black)),
        ],
      ),
    );
  }

  // A4 & A5 Standard Invoice Sheet Vector Layout
  pw.Widget _buildInvoiceSheetLayout(
    SaleOrderModel order,
    VoucherTemplateModel tpl,
    PdfColor primaryColor,
    pw.MemoryImage? logoImage,
    pw.Font mainFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Top Header Banner
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null) ...[
                    pw.Container(
                      height: 50,
                      width: 120,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(height: 6),
                  ],
                  pw.Text(zg(tpl.storeName), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: mainFont, color: primaryColor)),
                  if (tpl.showShopDetails && tpl.storeTagline.isNotEmpty)
                    pw.Text(zg(tpl.storeTagline), style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, font: mainFont)),
                  if (tpl.showShopDetails && tpl.storeAddress.isNotEmpty)
                    pw.Text(zg(tpl.storeAddress), style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700, font: mainFont)),
                  if (tpl.showShopDetails && tpl.storePhone.isNotEmpty)
                    pw.Text(zg('Tel: ${tpl.storePhone}'), style: pw.TextStyle(fontSize: 9.5, font: mainFont)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(zg('TAX INVOICE / VOUCHER'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: mainFont)),
                ),
                pw.SizedBox(height: 6),
                pw.Text(zg('Invoice No: ${order.voucherNo}'), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: mainFont)),
                pw.Text(zg('Date: ${order.saleDate.substring(0, 10)}'), style: pw.TextStyle(fontSize: 10, font: mainFont)),
                if (tpl.showCashier)
                  pw.Text(zg('Cashier: ${order.userName}'), style: pw.TextStyle(fontSize: 9.5, font: mainFont)),
                if (tpl.showPaymentMethod)
                  pw.Text(zg('Payment: ${order.paymentMethod.toUpperCase()}'), style: pw.TextStyle(fontSize: 9.5, font: mainFont)),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 16),

        // Customer Info Card
        if (tpl.showCustomer && (order.customerName != null || order.customerPhone != null || order.deliveryAddress != null)) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(zg('INVOICE TO:'), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600, font: mainFont)),
                    pw.SizedBox(height: 2),
                    pw.Text(zg(order.customerName ?? 'Valued Customer'), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: mainFont)),
                    if (order.customerPhone != null)
                      pw.Text(zg('Phone: ${order.customerPhone!}'), style: pw.TextStyle(fontSize: 9.5, font: mainFont)),
                  ],
                ),
                if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(zg('DELIVERY ADDRESS:'), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600, font: mainFont)),
                      pw.SizedBox(height: 2),
                      pw.Text(zg(order.deliveryAddress!), style: pw.TextStyle(fontSize: 9.5, font: mainFont)),
                    ],
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
        ],

        // Vector Items Table
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(5),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2.5),
            4: pw.FlexColumnWidth(3),
          },
          children: [
            // Header Row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: primaryColor),
              children: [
                _buildTableCell('#', isHeader: true, align: pw.TextAlign.center, font: mainFont),
                _buildTableCell(zg('Item Description'), isHeader: true, font: mainFont),
                _buildTableCell(zg('Quantity'), isHeader: true, align: pw.TextAlign.center, font: mainFont),
                _buildTableCell(zg('Unit Price'), isHeader: true, align: pw.TextAlign.right, font: mainFont),
                _buildTableCell(zg('Total Amount'), isHeader: true, align: pw.TextAlign.right, font: mainFont),
              ],
            ),
            // Items
            ...order.items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;
              final isEven = idx % 2 == 0;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: isEven ? PdfColors.grey50 : PdfColors.white),
                children: [
                  _buildTableCell('$idx', align: pw.TextAlign.center, font: mainFont),
                  _buildTableCell(zg(item.productName), font: mainFont),
                  _buildTableCell(zg('${item.quantity} ${item.unit}'), align: pw.TextAlign.center, font: mainFont),
                  _buildTableCell(zg('${item.price.toStringAsFixed(0)} Ks'), align: pw.TextAlign.right, font: mainFont),
                  _buildTableCell(zg('${item.total.toStringAsFixed(0)} Ks'), align: pw.TextAlign.right, isBold: true, font: mainFont),
                ],
              );
            }),
          ],
        ),

        pw.SizedBox(height: 12),

        // Financial Summary Bottom
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left: Notes, QR & Policy
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (tpl.showBarcode) ...[
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: order.voucherNo,
                      width: 140,
                      height: 30,
                      drawText: true,
                      textStyle: pw.TextStyle(font: mainFont, fontSize: 7),
                    ),
                    pw.SizedBox(height: 8),
                  ],
                  if (tpl.thankYouNote.isNotEmpty)
                    pw.Text(zg(tpl.thankYouNote), style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, font: mainFont)),
                  if (tpl.policyNote.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(zg(tpl.policyNote), style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700, font: mainFont)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            // Right: Calculation Box
            pw.Expanded(
              flex: 4,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    _buildInvoiceTotalRow(zg('Subtotal:'), zg('${order.subtotal.toStringAsFixed(0)} Ks'), font: mainFont),
                    if (tpl.showTaxAndDiscount && order.discountAmount > 0)
                      _buildInvoiceTotalRow(zg('Discount:'), zg('-${order.discountAmount.toStringAsFixed(0)} Ks'), font: mainFont),
                    if (tpl.showTaxAndDiscount && order.taxAmount > 0)
                      _buildInvoiceTotalRow(zg('Tax:'), zg('+${order.taxAmount.toStringAsFixed(0)} Ks'), font: mainFont),
                    if (tpl.showDeliveryDetails && order.deliveryFee > 0)
                      _buildInvoiceTotalRow(zg('Delivery Fee:'), zg('+${order.deliveryFee.toStringAsFixed(0)} Ks'), font: mainFont),
                    pw.Divider(thickness: 0.8, color: PdfColors.grey400),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(zg('Grand Total:'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: mainFont, color: primaryColor)),
                        pw.Text(zg('${order.grandTotal.toStringAsFixed(0)} Ks'), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, font: mainFont, color: primaryColor)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    _buildInvoiceTotalRow(zg(Get.locale?.languageCode == 'my' ? 'ပေးငွေ:' : 'Paid Amount:'), zg('${order.paidAmount.toStringAsFixed(0)} Ks'), font: mainFont),
                    if (order.dueAmount > 0)
                      _buildInvoiceTotalRow(zg(Get.locale?.languageCode == 'my' ? 'အကြွေး:' : 'Due:'), zg('${order.dueAmount.toStringAsFixed(0)} Ks'), isBold: true, color: PdfColors.red700, font: mainFont),
                    if (order.changeAmount > 0)
                      _buildInvoiceTotalRow(zg(Get.locale?.languageCode == 'my' ? 'ပြန်အမ်း:' : 'Change:'), zg('${order.changeAmount.toStringAsFixed(0)} Ks'), font: mainFont),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Signature Line
        if (tpl.showSignatureLine) ...[
          pw.Spacer(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 130, child: pw.Divider(thickness: 1, color: PdfColors.grey500)),
                  pw.Text(zg('Customer Signature'), style: pw.TextStyle(fontSize: 8.5, font: mainFont)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 130, child: pw.Divider(thickness: 1, color: PdfColors.grey500)),
                  pw.Text(zg('Authorized Signature'), style: pw.TextStyle(fontSize: 8.5, font: mainFont)),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left, bool isBold = false, required pw.Font font}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 9 : 8.5,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildInvoiceTotalRow(String title, String val, {bool isBold = false, PdfColor? color, required pw.Font font}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 9.5, color: color ?? PdfColors.grey800)),
          pw.Text(val, style: pw.TextStyle(font: font, fontSize: 9.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? PdfColors.black)),
        ],
      ),
    );
  }

  // Open Interactive Native Print Spooler / PDF Preview
  Future<void> previewOrPrint(
    BuildContext context,
    SaleOrderModel order, {
    VoucherTemplateModel? template,
  }) async {
    final tpl = template ?? await getActiveTemplate();
    final bytes = await generateVoucherPdf(order, template: tpl);

    // On Web, open native browser PDF viewer & 1-click print directly
    if (kIsWeb) {
      await openOrDownloadPdf(bytes, 'Voucher_${order.voucherNo}.pdf');
      return;
    }

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          return await generateVoucherPdf(order, template: tpl, customFormat: format);
        },
        name: 'Voucher_${order.voucherNo}',
      );
    } catch (_) {
      await Printing.sharePdf(bytes: bytes, filename: 'Voucher_${order.voucherNo}.pdf');
    }
  }

  // Direct Share/Export PDF File
  Future<void> exportPdfFile(
    SaleOrderModel order, {
    VoucherTemplateModel? template,
  }) async {
    final tpl = template ?? await getActiveTemplate();
    final bytes = await generateVoucherPdf(order, template: tpl);

    if (kIsWeb) {
      await openOrDownloadPdf(bytes, 'Voucher_${order.voucherNo}.pdf');
      return;
    }

    await Printing.sharePdf(bytes: bytes, filename: 'Voucher_${order.voucherNo}.pdf');
  }
}
