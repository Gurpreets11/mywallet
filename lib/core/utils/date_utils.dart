import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(
      DateTime date,
      ) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(
      DateTime date,
      ) {
    return DateFormat(
      'dd MMM yyyy hh:mm a',
    ).format(date);
  }

  static String getCurrentTimestamp() {
    return DateTime.now().toIso8601String();
  }
}