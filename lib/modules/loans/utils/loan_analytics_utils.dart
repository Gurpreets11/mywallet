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
    final emiDate = DateTime.tryParse(nextEmiDate);

    if (emiDate == null) {
      return false;
    }

    // Compare calendar days: an EMI due today is not overdue yet.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(emiDate.year, emiDate.month, emiDate.day);

    return dueDay.isBefore(today);
  }
}
