import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();

  static final NavigationService instance = NavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(Widget screen) {
    return navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
