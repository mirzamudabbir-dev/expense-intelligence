import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  static String format(double amount) => _fmt.format(amount);

  static String compact(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return format(amount);
  }
}
