import 'package:intl/intl.dart';

import '../services/settings/app_preferences.dart';

/// Formats money using the currency chosen in Settings.
class CurrencyUtils {
  /// Symbol of the selected currency (e.g. ₹, \$, €).
  static String get symbol => AppPreferences.instance.currency.symbol;

  static String formatAmount(double amount) {
    final currency = AppPreferences.instance.currency;
    final formatter = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: currency == AppCurrency.jpy ? 0 : 2,
    );

    return formatter.format(amount);
  }

  /// Symbol followed by a plain fixed-decimal number, e.g. `₹1500`.
  static String simple(double amount, {int decimals = 0}) =>
      '$symbol${amount.toStringAsFixed(decimals)}';
}
