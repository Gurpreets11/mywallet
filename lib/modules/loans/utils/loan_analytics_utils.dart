class LoanAnalyticsUtils {
  /// LOAN COMPLETION %

  static double calculateCompletionPercentage({
    required double loanAmount,

    required double outstandingAmount,
  }) {
    if (loanAmount == 0) {
      return 0;
    }

    final paidAmount = loanAmount - outstandingAmount;

    return (paidAmount / loanAmount) * 100;
  }

  /// REMAINING EMI COUNT

  static int calculateRemainingEmiCount({
    required double outstandingAmount,

    required double emiAmount,
  }) {
    if (emiAmount == 0) {
      return 0;
    }

    return (outstandingAmount / emiAmount).ceil();
  }

  /// OVERDUE CHECK

  static bool isLoanOverdue(String nextEmiDate) {
    final emiDate = DateTime.parse(nextEmiDate);

    return emiDate.isBefore(DateTime.now());
  }
}
