import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/modules/categories/utils/category_style.dart';

void main() {
  group('CategoryStyle', () {
    test('parses a hex colour', () {
      expect(CategoryStyle.colorFor('#E53935'), const Color(0xFFE53935));
    });

    test('returns null for missing or invalid colours', () {
      expect(CategoryStyle.colorFor(null), isNull);
      expect(CategoryStyle.colorFor('red'), isNull);
      expect(CategoryStyle.colorFor('#12'), isNull);
      expect(CategoryStyle.colorFor('#GGGGGG'), isNull);
    });

    test('falls back to the default icon', () {
      expect(CategoryStyle.iconFor('food'), Icons.restaurant);
      expect(CategoryStyle.iconFor('nope'), Icons.category);
      expect(CategoryStyle.iconFor(null), Icons.category);
    });

    test('every palette colour is valid', () {
      for (final c in CategoryStyle.colors) {
        expect(CategoryStyle.colorFor(c), isNotNull, reason: c);
      }
    });
  });
}
