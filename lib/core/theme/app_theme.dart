import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor:
    AppColors.background,

    inputDecorationTheme:
    const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),

    elevatedButtonTheme:
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
    ),
  );
}