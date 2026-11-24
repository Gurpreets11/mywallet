import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/core/services/security/sha256_lite.dart';
import 'package:mywallet/core/services/settings/app_preferences.dart';
import 'package:mywallet/core/utils/app_breakpoints.dart';
import 'package:mywallet/core/utils/currency_utils.dart';
import 'package:mywallet/core/utils/date_utils.dart';
import 'package:mywallet/core/utils/greeting_utils.dart';
import 'package:mywallet/core/utils/validator_utils.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();

  setUp(() async {
    // Fresh DB -> every preference back to its default (INR, dd MMM yyyy).
    await AppPreferences.instance.load();
  });

  group('ValidatorUtils', () {
    test('validateRequired', () {
      expect(ValidatorUtils.validateRequired(null, 'Name'), 'Name is required');
      expect(ValidatorUtils.validateRequired('', 'Name'), 'Name is required');
      expect(
        ValidatorUtils.validateRequired('   ', 'Name'),
        'Name is required',
      );
      expect(ValidatorUtils.validateRequired('Asha', 'Name'), isNull);
    });

    test('validateAmount', () {
      expect(ValidatorUtils.validateAmount(null), 'Amount is required');
      expect(ValidatorUtils.validateAmount(' '), 'Amount is required');
      expect(ValidatorUtils.validateAmount('abc'), 'Enter valid amount');
      expect(ValidatorUtils.validateAmount('0'), 'Enter valid amount');
      expect(ValidatorUtils.validateAmount('-5'), 'Enter valid amount');
      expect(ValidatorUtils.validateAmount('12.5'), isNull);
    });
  });

  group('AppBreakpoints', () {
    test('mobile / tablet / rail thresholds', () {
      expect(AppBreakpoints.isMobile(599), isTrue);
      expect(AppBreakpoints.isMobile(600), isFalse);
      expect(AppBreakpoints.isTablet(600), isTrue);
      expect(AppBreakpoints.isTablet(839), isTrue);
      expect(AppBreakpoints.isTablet(840), isFalse);
      expect(AppBreakpoints.useNavigationRail(599), isFalse);
      expect(AppBreakpoints.useNavigationRail(600), isTrue);
      expect(AppBreakpoints.useExtendedNavigationRail(1199), isFalse);
      expect(AppBreakpoints.useExtendedNavigationRail(1200), isTrue);
    });
  });

  group('GreetingUtils', () {
    test('returns one of the known greetings', () {
      expect([
        'Good Morning',
        'Good Afternoon',
        'Good Evening',
        'Good Night',
      ], contains(GreetingUtils.getGreeting()));
    });
  });

  group('CurrencyUtils', () {
    test('defaults to INR with Indian digit grouping', () {
      expect(CurrencyUtils.symbol, '₹');
      expect(CurrencyUtils.formatAmount(1234567.5), '₹12,34,567.50');
      expect(CurrencyUtils.simple(1500), '₹1500');
      expect(CurrencyUtils.simple(1500.456, decimals: 2), '₹1500.46');
    });

    test('follows the selected currency', () async {
      await AppPreferences.instance.setCurrency(AppCurrency.usd);
      expect(CurrencyUtils.symbol, r'$');
      expect(CurrencyUtils.formatAmount(1234.5), r'$1,234.50');
      expect(CurrencyUtils.simple(10), r'$10');
    });

    test('yen has no decimals', () async {
      await AppPreferences.instance.setCurrency(AppCurrency.jpy);
      expect(CurrencyUtils.formatAmount(1234), '¥1,234');
    });

    test('negative amounts keep their sign', () {
      expect(CurrencyUtils.formatAmount(-50), contains('-'));
      expect(CurrencyUtils.formatAmount(-50), contains('50.00'));
    });
  });

  group('AppDateUtils', () {
    final d = DateTime(2026, 3, 5, 9, 7);

    test('default format', () {
      expect(AppDateUtils.formatDate(d), '05 Mar 2026');
      expect(AppDateUtils.formatDateTime(d), '05 Mar 2026 09:07 AM');
    });

    test('follows the chosen date format', () async {
      await AppPreferences.instance.setDateFormat('yyyy-MM-dd');
      expect(AppDateUtils.formatDate(d), '2026-03-05');
      await AppPreferences.instance.setDateFormat('MM/dd/yyyy');
      expect(AppDateUtils.formatDate(d), '03/05/2026');
      await AppPreferences.instance.setDateFormat('dd/MM/yyyy');
      expect(AppDateUtils.formatDate(d), '05/03/2026');
    });

    test('timestamp is parseable ISO text', () {
      expect(DateTime.tryParse(AppDateUtils.getCurrentTimestamp()), isNotNull);
    });
  });

  group('sha256_lite', () {
    test('matches the standard SHA-256 test vectors', () {
      expect(
        toHex(sha256Bytes(utf8.encode('abc'))),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(
        toHex(sha256Bytes(const [])),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });
  });
}
