import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_colors.dart';
import '../controllers/voucher_builder_controller.dart';

class VoucherBuilderView extends StatelessWidget {
  const VoucherBuilderView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VoucherBuilderController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 950;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voucher Builder & Layout Designer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: controller.resetToDefault,
            icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
            label: const Text('Reset', style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => controller.testPrintPdf(context),
            icon: const Icon(Icons.print_rounded, size: 18, color: AppColors.primaryLight),
            label: const Text('Test Print PDF', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 10),
          Obx(() => ElevatedButton.icon(
            onPressed: controller.isSaving.value ? null : controller.saveTemplate,
            icon: controller.isSaving.value
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(controller.isSaving.value ? 'Saving...' : 'Save Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          )),
          const SizedBox(width: 16),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (isDesktop) {
          // Desktop 2-Column layout
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Customizer Controls
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildControlsColumn(context, controller),
                ),
              ),
              // Vertical Divider
              Container(width: 1, color: AppColors.border),
              // Right: Live Visual Preview
              Expanded(
                flex: 5,
                child: Container(
                  color: AppColors.cardBgLight.withOpacity(0.3),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          color: AppColors.cardBg,
                          border: Border(bottom: BorderSide(color: AppColors.border)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.visibility_rounded, size: 18, color: AppColors.primaryLight),
                                SizedBox(width: 8),
                                Text('Live Visual Preview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                            Obx(() => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                controller.paperSize.value.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                              ),
                            )),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: _buildLiveVoucherPaper(context, controller),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          // Mobile / Tablet Tabbed layout
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: AppColors.cardBg,
                  child: const TabBar(
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primaryLight,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: [
                      Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Customizer Controls'),
                      Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Live Preview'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(14),
                        child: _buildControlsColumn(context, controller),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: _buildLiveVoucherPaper(context, controller),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      }),
    );
  }

  // --- Left Column: Controls ---
  Widget _buildControlsColumn(BuildContext context, VoucherBuilderController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Branding & Identity
        _buildSectionCard(
          title: 'Store Branding & Contact Details',
          subtitle: 'Company name, logo, phone, and store location printed at the top',
          icon: Icons.storefront_rounded,
          children: [
            // Logo upload row
            Row(
              children: [
                Obx(() {
                  final logo = controller.logoBase64.value;
                  return Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.cardBgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: logo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(base64Decode(logo), fit: BoxFit.contain),
                          )
                        : const Icon(Icons.image_outlined, size: 32, color: AppColors.textMuted),
                  );
                }),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: controller.pickLogo,
                            icon: const Icon(Icons.upload_rounded, size: 16),
                            label: const Text('Upload Logo', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Obx(() => controller.logoBase64.value != null
                              ? OutlinedButton(
                                  onPressed: controller.removeLogo,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    side: const BorderSide(color: AppColors.error),
                                  ),
                                  child: const Text('Remove', style: TextStyle(fontSize: 12, color: AppColors.error)),
                                )
                              : const SizedBox.shrink()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Recommended: PNG or JPG with transparent/white background', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildTextField(controller.storeNameCtrl, 'Shop / Store Name', 'e.g. SnapCart Fashion'),
            const SizedBox(height: 10),
            _buildTextField(controller.storeTaglineCtrl, 'Tagline / Slogan (Optional)', 'e.g. မြန်မာဝတ်စုံနှင့် အထည်အလိပ် လက်လီ/လက်ကား'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTextField(controller.storePhoneCtrl, 'Phone Number(s)', 'e.g. 09-123456789')),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(controller.socialInfoCtrl, 'Social / Viber (Optional)', 'e.g. FB: SnapCart Myanmar')),
              ],
            ),
            const SizedBox(height: 10),
            _buildTextField(controller.storeAddressCtrl, 'Store Address', 'e.g. အမှတ် (၁၂)၊ ဗဟိုလမ်း၊ ကမာရွတ်မြို့နယ်၊ ရန်ကုန်။', maxLines: 2),
          ],
        ),

        const SizedBox(height: 16),

        // Card 2: Layout & Paper Formats
        _buildSectionCard(
          title: 'Layout & Paper Dimensions',
          subtitle: 'Select receipt roll format or A4/A5 invoice sheet format',
          icon: Icons.aspect_ratio_rounded,
          children: [
            const Text('Paper Dimension:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Obx(() => Row(
              children: [
                _buildPaperSizeOption(controller, 'mm80', '80mm Thermal', 'POS Counter Standard', Icons.receipt_rounded),
                const SizedBox(width: 8),
                _buildPaperSizeOption(controller, 'mm58', '58mm Mini', 'Portable Bluetooth', Icons.receipt_long_rounded),
                const SizedBox(width: 8),
                _buildPaperSizeOption(controller, 'a4', 'A4 Sheet', 'Full Invoice Page', Icons.description_rounded),
                const SizedBox(width: 8),
                _buildPaperSizeOption(controller, 'a5', 'A5 Sheet', 'Half Sheet Invoice', Icons.article_rounded),
              ],
            )),
            const SizedBox(height: 14),

            const Text('Accent Theme Color:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Obx(() => Row(
              children: [
                _buildColorSwatch(controller, 0xFF0D9488, 'Emerald Teal'),
                const SizedBox(width: 10),
                _buildColorSwatch(controller, 0xFF2563EB, 'Royal Blue'),
                const SizedBox(width: 10),
                _buildColorSwatch(controller, 0xFF4F46E5, 'Indigo'),
                const SizedBox(width: 10),
                _buildColorSwatch(controller, 0xFFD97706, 'Amber Gold'),
                const SizedBox(width: 10),
                _buildColorSwatch(controller, 0xFFE11D48, 'Rose Red'),
                const SizedBox(width: 10),
                _buildColorSwatch(controller, 0xFF18181B, 'Monochrome'),
              ],
            )),
          ],
        ),

        const SizedBox(height: 16),

        // Card 3: Content Visibility Toggles
        _buildSectionCard(
          title: 'Content Section Toggles',
          subtitle: 'Choose which details should appear on the printed voucher',
          icon: Icons.checklist_rounded,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildSwitch('Show Logo', controller.showLogo),
                _buildSwitch('Store Tagline & Address', controller.showShopDetails),
                _buildSwitch('Cashier Name', controller.showCashier),
                _buildSwitch('Customer Name & Phone', controller.showCustomer),
                _buildSwitch('Payment Method', controller.showPaymentMethod),
                _buildSwitch('Delivery & COD Details', controller.showDeliveryDetails),
                _buildSwitch('Tax & Discount Breakdown', controller.showTaxAndDiscount),
                _buildSwitch('Barcode / QR Code', controller.showBarcode),
                _buildSwitch('Signature Lines (A4/A5)', controller.showSignatureLine),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Card 4: Footer Notes & Policy
        _buildSectionCard(
          title: 'Footer Messages & Return Policy',
          subtitle: 'Custom thank you messages and shop exchange conditions',
          icon: Icons.notes_rounded,
          children: [
            _buildTextField(controller.thankYouNoteCtrl, 'Thank You Message', 'e.g. ဝယ်ယူအားပေးမှုအတွက် ကျေးဇူးတင်ရှိပါသည်။'),
            const SizedBox(height: 10),
            _buildTextField(controller.policyNoteCtrl, 'Exchange / Return Policy', 'e.g. ပစ္စည်းများ လဲလှယ်လိုပါက (၃) ရက်အတွင်း ဘောက်ချာနှင့်တကွ ယူဆောင်လာပါရန်။', maxLines: 2),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // Helper for Section Cards
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: AppColors.cardBgLight.withOpacity(0.4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaperSizeOption(VoucherBuilderController controller, String sizeKey, String label, String desc, IconData icon) {
    final isSelected = controller.paperSize.value == sizeKey;
    return Expanded(
      child: InkWell(
        onTap: () => controller.paperSize.value = sizeKey,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.cardBgLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primaryLight : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? AppColors.textPrimary : AppColors.textSecondary)),
              Text(desc, style: const TextStyle(fontSize: 9, color: AppColors.textMuted), textAlign: TextAlign.center, maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSwatch(VoucherBuilderController controller, int colorVal, String tooltip) {
    final isSelected = controller.primaryColorValue.value == colorVal;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => controller.primaryColorValue.value = colorVal,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Color(colorVal),
            shape: BoxShape.circle,
            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
            boxShadow: isSelected
                ? [BoxShadow(color: Color(colorVal).withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                : null,
          ),
          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, RxBool obs) {
    return Obx(() => FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: obs.value ? AppColors.primaryLight : AppColors.textSecondary)),
      selected: obs.value,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primaryLight,
      backgroundColor: AppColors.cardBgLight.withOpacity(0.4),
      side: BorderSide(color: obs.value ? AppColors.primary : AppColors.border),
      onSelected: (val) => obs.value = val,
    ));
  }

  // --- Right Column: Live Visual Paper Preview ---
  Widget _buildLiveVoucherPaper(BuildContext context, VoucherBuilderController controller) {
    return Obx(() {
      final isRoll = controller.paperSize.value == 'mm80' || controller.paperSize.value == 'mm58';
      final is58mm = controller.paperSize.value == 'mm58';
      final primaryColor = Color(controller.primaryColorValue.value);
      final logo = controller.logoBase64.value;

      final double paperWidth = is58mm ? 270 : (isRoll ? 340 : 480);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: paperWidth,
        padding: EdgeInsets.all(isRoll ? 14 : 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.black, fontFamily: 'Roboto'),
          child: Column(
            crossAxisAlignment: isRoll ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              if (controller.showLogo.value && logo != null) ...[
                Center(
                  child: Container(
                    height: 42,
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Image.memory(base64Decode(logo), fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Store Name
              Text(
                controller.storeNameCtrl.text.isNotEmpty ? controller.storeNameCtrl.text : 'SnapCart Fashion',
                textAlign: isRoll ? TextAlign.center : TextAlign.left,
                style: TextStyle(fontSize: isRoll ? 15 : 18, fontWeight: FontWeight.bold, color: isRoll ? Colors.black : primaryColor),
              ),

              // Store Tagline & Address
              if (controller.showShopDetails.value) ...[
                if (controller.storeTaglineCtrl.text.isNotEmpty)
                  Text(controller.storeTaglineCtrl.text, textAlign: isRoll ? TextAlign.center : TextAlign.left, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                if (controller.storePhoneCtrl.text.isNotEmpty)
                  Text('Ph: ${controller.storePhoneCtrl.text}', textAlign: isRoll ? TextAlign.center : TextAlign.left, style: const TextStyle(fontSize: 9.5, color: Colors.black87)),
                if (controller.storeAddressCtrl.text.isNotEmpty)
                  Text(controller.storeAddressCtrl.text, textAlign: isRoll ? TextAlign.center : TextAlign.left, style: const TextStyle(fontSize: 9, color: Colors.black54)),
              ],

              const SizedBox(height: 6),
              const Divider(color: Colors.black, thickness: 1),
              const SizedBox(height: 4),

              // Voucher Meta
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Voucher: ${controller.sampleOrder.voucherNo}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(controller.sampleOrder.saleDate.substring(0, 10), style: const TextStyle(fontSize: 9.5, color: Colors.black54)),
                ],
              ),
              if (controller.showCashier.value)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cashier: ${controller.sampleOrder.userName}', style: const TextStyle(fontSize: 9.5, color: Colors.black54)),
                    if (controller.showPaymentMethod.value)
                      Text('Pay: ${controller.sampleOrder.paymentMethod}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              if (controller.showCustomer.value) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Customer: ${controller.sampleOrder.customerName}', style: const TextStyle(fontSize: 9.5, color: Colors.black87)),
                    Text(controller.sampleOrder.customerPhone ?? '', style: const TextStyle(fontSize: 9.5, color: Colors.black54)),
                  ],
                ),
              ],

              const SizedBox(height: 4),
              const Divider(color: Colors.black, thickness: 0.8),
              const SizedBox(height: 4),

              // Items Table Header
              const Row(
                children: [
                  Expanded(flex: 5, child: Text('Item', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
              const Divider(color: Colors.black26, thickness: 0.5),

              // Items Rows
              ...controller.sampleOrder.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500)),
                          Text('${item.price.toStringAsFixed(0)} Ks x ${item.quantity} ${item.unit}', style: const TextStyle(fontSize: 8, color: Colors.black54)),
                        ],
                      ),
                    ),
                    Expanded(flex: 2, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5))),
                    Expanded(flex: 3, child: Text('${item.total.toStringAsFixed(0)} Ks', textAlign: TextAlign.right, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                  ],
                ),
              )),

              const SizedBox(height: 4),
              const Divider(color: Colors.black, thickness: 0.8),

              // Financial Totals
              _buildLiveTotalRow('Subtotal:', '${controller.sampleOrder.subtotal.toStringAsFixed(0)} Ks'),
              if (controller.showTaxAndDiscount.value) ...[
                _buildLiveTotalRow('Discount:', '-${controller.sampleOrder.discountAmount.toStringAsFixed(0)} Ks'),
                _buildLiveTotalRow('Tax:', '+${controller.sampleOrder.taxAmount.toStringAsFixed(0)} Ks'),
              ],
              if (controller.showDeliveryDetails.value && controller.sampleOrder.deliveryFee > 0)
                _buildLiveTotalRow('Delivery Fee:', '+${controller.sampleOrder.deliveryFee.toStringAsFixed(0)} Ks'),

              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Grand Total:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isRoll ? Colors.black : primaryColor)),
                  Text('${controller.sampleOrder.grandTotal.toStringAsFixed(0)} Ks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isRoll ? Colors.black : primaryColor)),
                ],
              ),
              const SizedBox(height: 2),
              _buildLiveTotalRow('Paid Amount:', '${controller.sampleOrder.paidAmount.toStringAsFixed(0)} Ks'),
              if (controller.sampleOrder.changeAmount > 0)
                _buildLiveTotalRow('change_due_preview'.tr, '${controller.sampleOrder.changeAmount.toStringAsFixed(0)} Ks'),

              // Barcode / QR placeholder
              if (controller.showBarcode.value) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 24, color: Colors.black87),
                        SizedBox(width: 8),
                        Text('|||||||||||||||||||||', style: TextStyle(letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],

              // Thank You & Policy Notes
              if (controller.thankYouNoteCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  controller.thankYouNoteCtrl.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
              if (controller.policyNoteCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  controller.policyNoteCtrl.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8, color: Colors.black54),
                ),
              ],

              // Signature Line
              if (controller.showSignatureLine.value) ...[
                const SizedBox(height: 18),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        SizedBox(width: 80, child: Divider(color: Colors.black54, thickness: 1)),
                        Text('Customer Signature', style: TextStyle(fontSize: 8, color: Colors.black54)),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(width: 80, child: Divider(color: Colors.black54, thickness: 1)),
                        Text('Cashier Signature', style: TextStyle(fontSize: 8, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  static Widget _buildLiveTotalRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 9.5, color: Colors.black87)),
          Text(val, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Colors.black)),
        ],
      ),
    );
  }
}
