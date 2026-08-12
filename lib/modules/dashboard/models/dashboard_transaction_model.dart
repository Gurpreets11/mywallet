class DashboardTransactionModel {
  final String title;

  final String subtitle;

  final double amount;

  final String date;

  final bool isExpense;

  DashboardTransactionModel({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.isExpense,
  });
}
