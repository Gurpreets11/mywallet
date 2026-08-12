import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LoggerService {
  LoggerService._();

  static final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void d(dynamic message) {
    logger.d(message);
  }

  static void e(dynamic message) {
    logger.e(message);
  }

  static void i(dynamic message) {
    if (!kReleaseMode) logger.i(message);
  }

  static void w(dynamic message) {
    logger.w(message);
  }

  static void info(dynamic method, dynamic message) {
    i('''
Info
--------------------------------
METHOD  : $method
Message : $message
--------------------------------''');
  }

  static void error(
    dynamic url,
    dynamic statusCode,
    dynamic errorType,
    dynamic errorMessage,
    dynamic errorData,
  ) {
    e('''
ERROR
--------------------------------
URL     : $url
STATUS  : $statusCode
TYPE    : $errorType
MESSAGE : $errorMessage
DATA    : $errorData
--------------------------------''');
  }
}
