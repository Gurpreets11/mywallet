import 'package:intl/intl.dart';

import '../services/settings/app_preferences.dart';

class AppDateUtils {
  /// Follows the date format chosen in Settings > Preferences.
  static String formatDate(DateTime date) {
    return DateFormat(AppPreferences.instance.dateFormat).format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat(
      '${AppPreferences.instance.dateFormat} hh:mm a',
    ).format(date);
  }

  static String getCurrentTimestamp() {
    return DateTime.now().toIso8601String();
  }
}
