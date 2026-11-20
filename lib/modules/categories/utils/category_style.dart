import 'package:flutter/material.dart';

/// Icons and colours a category can use. Only the short names are stored in
/// the database (`icon_name`, `color_code`), so the lists can grow later.
class CategoryStyle {
  CategoryStyle._();

  static const Map<String, IconData> icons = {
    'food': Icons.restaurant,
    'groceries': Icons.shopping_basket,
    'coffee': Icons.local_cafe,
    'transport': Icons.directions_bus,
    'car': Icons.directions_car,
    'fuel': Icons.local_gas_station,
    'home': Icons.home,
    'bills': Icons.receipt_long,
    'electricity': Icons.bolt,
    'phone': Icons.phone_android,
    'shopping': Icons.shopping_bag,
    'health': Icons.favorite,
    'medical': Icons.medical_services,
    'fitness': Icons.fitness_center,
    'education': Icons.school,
    'entertainment': Icons.movie,
    'travel': Icons.flight,
    'gift': Icons.card_giftcard,
    'pets': Icons.pets,
    'kids': Icons.child_care,
    'salary': Icons.payments,
    'business': Icons.business_center,
    'savings': Icons.savings,
    'investment': Icons.trending_up,
    'insurance': Icons.shield,
    'tax': Icons.account_balance,
    'other': Icons.category,
  };

  static const List<String> colors = [
    '#E53935',
    '#D81B60',
    '#8E24AA',
    '#5E35B1',
    '#3949AB',
    '#1E88E5',
    '#00ACC1',
    '#00897B',
    '#43A047',
    '#7CB342',
    '#F9A825',
    '#FB8C00',
    '#F4511E',
    '#6D4C41',
    '#546E7A',
  ];

  static IconData iconFor(String? name) => icons[name] ?? Icons.category;

  static Color? colorFor(String? code) {
    if (code == null || code.length != 7 || !code.startsWith('#')) return null;
    final v = int.tryParse(code.substring(1), radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }
}
