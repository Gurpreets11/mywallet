import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Color(0xFF202433),
  );

  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF202433),
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: Color(0xFF42485A),
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Color(0xFF73798B),
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}
