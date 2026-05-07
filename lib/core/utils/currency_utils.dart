import 'package:intl/intl.dart';

class CurrencyUtils {
  static String formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return formatter.format(amount);
  }
}