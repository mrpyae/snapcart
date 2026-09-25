import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  // Format currency with "Ks" suffix: e.g. 15,000 Ks
  static String formatCurrency(num amount, {String symbol = 'Ks'}) {
    return '${_currencyFormat.format(amount)} $symbol';
  }

  // Format Decimal Quantity (e.g. 2.5 yards)
  static String formatQty(num qty, {String unit = 'piece'}) {
    if (qty == qty.roundToDouble()) {
      return '${qty.toInt()} $unit';
    }
    return '${qty.toStringAsFixed(2)} $unit';
  }

  // Format date time (YYYY-MM-DD HH:mm)
  static String formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return isoDate;
    }
  }
}
