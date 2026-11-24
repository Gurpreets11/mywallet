import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/modules/investments/utils/investment_utils.dart';
import 'package:mywallet/modules/loans/utils/loan_analytics_utils.dart';

void main() {
  group('InvestmentUtils', () {
    test('profit', () {
      expect(
        InvestmentUtils.calculateProfit(
          investedAmount: 1000,
          currentValue: 1300,
        ),
        300,
      );
      expect(
        InvestmentUtils.calculateProfit(
          investedAmount: 1000,
          currentValue: 700,
        ),
        -300,
      );
    });

    test('ROI percentage and zero guard', () {
      expect(
        InvestmentUtils.calculateRoi(investedAmount: 1000, currentValue: 1250),
        25,
      );
      expect(
        InvestmentUtils.calculateRoi(investedAmount: 1000, currentValue: 500),
        -50,
      );
      expect(
        InvestmentUtils.calculateRoi(investedAmount: 0, currentValue: 500),
        0,
      );
    });
  });

  group('LoanAnalyticsUtils', () {
    test('completion percentage', () {
      expect(
        LoanAnalyticsUtils.calculateCompletionPercentage(
          loanAmount: 1000,
          outstandingAmount: 750,
        ),
        25,
      );
      expect(
        LoanAnalyticsUtils.calculateCompletionPercentage(
          loanAmount: 0,
          outstandingAmount: 0,
        ),
        0,
      );
    });

    test('remaining EMI count rounds up', () {
      expect(
        LoanAnalyticsUtils.calculateRemainingEmiCount(
          outstandingAmount: 1050,
          emiAmount: 500,
        ),
        3,
      );
      expect(
        LoanAnalyticsUtils.calculateRemainingEmiCount(
          outstandingAmount: 1000,
          emiAmount: 0,
        ),
        0,
      );
    });

    test('overdue detection compares whole days', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(
        LoanAnalyticsUtils.isLoanOverdue(
          today.subtract(const Duration(days: 1)).toIso8601String(),
        ),
        isTrue,
      );
      expect(
        LoanAnalyticsUtils.isLoanOverdue(today.toIso8601String()),
        isFalse,
      );
      expect(
        LoanAnalyticsUtils.isLoanOverdue(
          today.add(const Duration(days: 3)).toIso8601String(),
        ),
        isFalse,
      );
      expect(LoanAnalyticsUtils.isLoanOverdue('not a date'), isFalse);
    });
  });
}
