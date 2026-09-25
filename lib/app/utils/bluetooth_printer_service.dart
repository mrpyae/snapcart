import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../data/local/db_helper.dart';

class BluetoothPrinterService {
  static final BluetoothPrinterService instance = BluetoothPrinterService._();
  BluetoothPrinterService._();

  static const String keyPrinterMac = 'bt_printer_mac';
  static const String keyPrinterName = 'bt_printer_name';
  static const String keyPaperSize = 'bt_printer_paper_size'; // 'mm80' or 'mm58'
  static const String keyAutoPrint = 'bt_printer_auto_print'; // 'true' or 'false'

  // Check if Bluetooth is powered on
  Future<bool> isBluetoothEnabled() async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (e) {
      debugPrint('BluetoothPrinterService: isBluetoothEnabled error: $e');
      return false;
    }
  }

  // Get list of paired / bonded Bluetooth devices
  Future<List<BluetoothInfo>> getPairedPrinters() async {
    try {
      final List<BluetoothInfo> list = await PrintBluetoothThermal.pairedBluetooths;
      return list;
    } catch (e) {
      debugPrint('BluetoothPrinterService: getPairedPrinters error: $e');
      return [];
    }
  }

  // Check if currently connected to a printer
  Future<bool> isConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      debugPrint('BluetoothPrinterService: isConnected error: $e');
      return false;
    }
  }

  // Connect to a printer by its MAC address
  Future<bool> connect(String macAddress) async {
    try {
      if (macAddress.trim().isEmpty) return false;
      
      // If already connected, return true
      final alreadyConnected = await isConnected();
      if (alreadyConnected) {
        final currentMac = await getSavedPrinterMac();
        if (currentMac == macAddress) return true;
        // Different printer, disconnect first
        await disconnect();
      }

      final result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress.trim());
      return result;
    } catch (e) {
      debugPrint('BluetoothPrinterService: connect error: $e');
      return false;
    }
  }

  // Disconnect from current printer
  Future<bool> disconnect() async {
    try {
      return await PrintBluetoothThermal.disconnect;
    } catch (e) {
      debugPrint('BluetoothPrinterService: disconnect error: $e');
      return false;
    }
  }

  // Send raw ESC/POS bytes to the connected thermal printer
  Future<bool> printBytes(List<int> bytes) async {
    try {
      final connected = await isConnected();
      if (!connected) {
        // Attempt auto-reconnect using saved MAC
        final savedMac = await getSavedPrinterMac();
        if (savedMac != null && savedMac.isNotEmpty) {
          final reconnected = await connect(savedMac);
          if (!reconnected) return false;
        } else {
          return false;
        }
      }

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('BluetoothPrinterService: printBytes error: $e');
      return false;
    }
  }

  // Print a hardware test receipt to verify alignment, font, and paper cut
  Future<bool> printTestReceipt({String? macAddress, String paperSize = 'mm80'}) async {
    try {
      final targetMac = macAddress ?? await getSavedPrinterMac();
      if (targetMac == null || targetMac.isEmpty) return false;

      final connected = await connect(targetMac);
      if (!connected) return false;

      final profile = await CapabilityProfile.load();
      final size = paperSize == 'mm58' ? PaperSize.mm58 : PaperSize.mm80;
      final generator = Generator(size, profile);

      List<int> bytes = [];
      bytes += generator.reset();
      bytes += generator.text(
        'SnapCart POS',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
      bytes += generator.text(
        'Bluetooth Thermal Printer Test',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Paper Width:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: paperSize == 'mm58' ? '58mm (384 dots)' : '80mm (576 dots)', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'MAC Address:', width: 5, styles: const PosStyles(bold: true)),
        PosColumn(text: targetMac, width: 7, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Status:', width: 5, styles: const PosStyles(bold: true)),
        PosColumn(text: 'OK / READY', width: 7, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.hr();
      bytes += generator.text(
        'Thermal printing is functioning properly!',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(3);
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('BluetoothPrinterService: printTestReceipt error: $e');
      return false;
    }
  }

  // Settings helpers
  Future<String?> getSavedPrinterMac() async {
    return await DBHelper.instance.getSetting(keyPrinterMac);
  }

  Future<String?> getSavedPrinterName() async {
    return await DBHelper.instance.getSetting(keyPrinterName);
  }

  Future<String> getSavedPaperSize() async {
    final size = await DBHelper.instance.getSetting(keyPaperSize);
    return (size == 'mm58') ? 'mm58' : 'mm80';
  }

  Future<bool> getSavedAutoPrint() async {
    final val = await DBHelper.instance.getSetting(keyAutoPrint);
    return val == 'true';
  }

  Future<void> savePrinterSettings({
    required String mac,
    required String name,
    String paperSize = 'mm80',
    bool autoPrint = false,
  }) async {
    await DBHelper.instance.setSetting(keyPrinterMac, mac);
    await DBHelper.instance.setSetting(keyPrinterName, name);
    await DBHelper.instance.setSetting(keyPaperSize, paperSize);
    await DBHelper.instance.setSetting(keyAutoPrint, autoPrint ? 'true' : 'false');
  }

  Future<void> clearSavedPrinter() async {
    await disconnect();
    await DBHelper.instance.setSetting(keyPrinterMac, '');
    await DBHelper.instance.setSetting(keyPrinterName, '');
  }
}
