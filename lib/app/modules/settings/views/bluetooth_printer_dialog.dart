import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/bluetooth_printer_service.dart';

class BluetoothPrinterDialog extends StatefulWidget {
  const BluetoothPrinterDialog({Key? key}) : super(key: key);

  @override
  State<BluetoothPrinterDialog> createState() => _BluetoothPrinterDialogState();
}

class _BluetoothPrinterDialogState extends State<BluetoothPrinterDialog> {
  final BluetoothPrinterService _service = BluetoothPrinterService.instance;

  bool _isLoading = true;
  bool _isBluetoothEnabled = false;
  bool _isConnected = false;
  bool _isTesting = false;

  List<BluetoothInfo> _devices = [];
  String? _selectedMac;
  String? _selectedName;
  String _selectedPaperSize = 'mm80';

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    setState(() => _isLoading = true);

    final enabled = await _service.isBluetoothEnabled();
    final connected = await _service.isConnected();
    final savedMac = await _service.getSavedPrinterMac();
    final savedName = await _service.getSavedPrinterName();
    final savedPaper = await _service.getSavedPaperSize();

    List<BluetoothInfo> devices = [];
    if (enabled) {
      devices = await _service.getPairedPrinters();
    }

    if (mounted) {
      setState(() {
        _isBluetoothEnabled = enabled;
        _isConnected = connected;
        _selectedMac = (savedMac != null && savedMac.isNotEmpty) ? savedMac : null;
        _selectedName = (savedName != null && savedName.isNotEmpty) ? savedName : null;
        _selectedPaperSize = savedPaper;
        _devices = devices;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDevices() async {
    setState(() => _isLoading = true);
    final enabled = await _service.isBluetoothEnabled();
    final connected = await _service.isConnected();
    List<BluetoothInfo> devices = [];
    if (enabled) {
      devices = await _service.getPairedPrinters();
    }

    if (mounted) {
      setState(() {
        _isBluetoothEnabled = enabled;
        _isConnected = connected;
        _devices = devices;
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothInfo info) async {
    setState(() => _isLoading = true);

    final success = await _service.connect(info.macAdress);
    if (mounted) {
      setState(() {
        _selectedMac = info.macAdress;
        _selectedName = info.name;
        _isConnected = success;
        _isLoading = false;
      });

      if (success) {
        await _service.savePrinterSettings(
          mac: info.macAdress,
          name: info.name,
          paperSize: _selectedPaperSize,
        );
        Get.snackbar(
          'Printer Connected',
          'Successfully connected to ${info.name}',
          backgroundColor: AppColors.success.withOpacity(0.85),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Connection Failed',
          'Could not connect to ${info.name}. Please ensure printer is turned on.',
          backgroundColor: AppColors.error.withOpacity(0.85),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _testPrint() async {
    if (_selectedMac == null || _selectedMac!.isEmpty) {
      Get.snackbar('No Printer Selected', 'Please select a printer first',
          backgroundColor: AppColors.warning, colorText: Colors.black);
      return;
    }

    setState(() => _isTesting = true);
    final ok = await _service.printTestReceipt(
      macAddress: _selectedMac,
      paperSize: _selectedPaperSize,
    );

    if (mounted) {
      setState(() => _isTesting = false);
      if (ok) {
        Get.snackbar(
          'Test Successful',
          'Test receipt printed successfully!',
          backgroundColor: AppColors.success.withOpacity(0.85),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Print Failed',
          'Failed to print test slip. Verify printer status and paper roll.',
          backgroundColor: AppColors.error.withOpacity(0.85),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _saveAndClose() async {
    if (_selectedMac != null && _selectedName != null) {
      await _service.savePrinterSettings(
        mac: _selectedMac!,
        name: _selectedName!,
        paperSize: _selectedPaperSize,
      );
    }
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 500;

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        width: isCompact ? screenWidth * 0.95 : 500,
        padding: EdgeInsets.all(isCompact ? 16 : 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.print_rounded, color: AppColors.primaryLight, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thermal Bluetooth Printer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ESC/POS 58mm / 80mm portable slips',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                  splashRadius: 18,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bluetooth Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isBluetoothEnabled
                    ? AppColors.success.withOpacity(0.12)
                    : AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isBluetoothEnabled
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isBluetoothEnabled ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                    color: _isBluetoothEnabled ? AppColors.success : AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isBluetoothEnabled
                          ? (_isConnected
                              ? 'Bluetooth active • Connected to ${_selectedName ?? "Printer"}'
                              : 'Bluetooth active • Ready to pair')
                          : 'Bluetooth is turned OFF. Please enable Bluetooth on your device.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isBluetoothEnabled ? AppColors.textPrimary : AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primaryLight),
                    tooltip: 'Refresh Devices',
                    onPressed: _isLoading ? null : _refreshDevices,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Paper Size Preference
            const Text(
              'Paper Roll Width',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildPaperOption(
                    label: '80mm Standard',
                    subtitle: '576 dots (Counter POS)',
                    isSelected: _selectedPaperSize == 'mm80',
                    onTap: () {
                      setState(() => _selectedPaperSize = 'mm80');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPaperOption(
                    label: '58mm Mini Roll',
                    subtitle: '384 dots (Portable BT)',
                    isSelected: _selectedPaperSize == 'mm58',
                    onTap: () {
                      setState(() => _selectedPaperSize = 'mm58');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Device List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Paired Bluetooth Devices',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  '${_devices.length} found',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Devices Scroll List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                  : _devices.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.devices_other_rounded, size: 36, color: AppColors.textMuted),
                                SizedBox(height: 8),
                                Text(
                                  'No paired Bluetooth printers found',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '1. Turn on your thermal printer\n2. Pair with it in Android/OS Bluetooth Settings\n3. Tap Refresh above',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _devices.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final dev = _devices[index];
                            final isSelected = dev.macAdress == _selectedMac;

                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.15)
                                    : AppColors.cardBgLight.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryLight : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.2)
                                        : AppColors.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.bluetooth_rounded,
                                    size: 18,
                                    color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                                  ),
                                ),
                                title: Text(
                                  dev.name.isNotEmpty ? dev.name : 'Unknown Device',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  dev.macAdress,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                trailing: isSelected && _isConnected
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.success.withOpacity(0.5)),
                                        ),
                                        child: const Text(
                                          'Connected',
                                          style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: () => _connectToDevice(dev),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Text('Connect', style: TextStyle(fontSize: 11, color: Colors.white)),
                                      ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 14),

            // Bottom Buttons: Test Print & Save
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_selectedMac != null && !_isTesting) ? _testPrint : null,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                          )
                        : const Icon(Icons.receipt_rounded, size: 16),
                    label: Text(_isTesting ? 'Printing...' : 'Print Test Slip'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveAndClose,
                    icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    label: const Text('Save & Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaperOption({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.cardBgLight.withOpacity(0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: 14,
                  color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
