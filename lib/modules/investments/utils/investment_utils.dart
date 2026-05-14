class InvestmentUtils {
  static double calculateProfit({
    required double investedAmount,
    required double currentValue,
  }) {
    return currentValue - investedAmount;
  }

  static double calculateRoi({
    required double investedAmount,
    required double currentValue,
  }) {
    if (investedAmount == 0) {
      return 0;
    }

    return ((currentValue - investedAmount) / investedAmount) * 100;
  }
}
