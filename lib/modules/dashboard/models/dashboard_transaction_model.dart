/// Where a transaction in the combined feed comes from.
enum TransactionKind { expense, income, loanEmi, investment }

class DashboardTransactionModel {
  final String title;

  final String subtitle;

  final double amount;

  final String date;

  /// True when money goes OUT (expense, EMI paid, ...). False when money
  /// comes IN (income, EMI received on a loan you gave).
  final bool isExpense;

  final TransactionKind kind;

  DashboardTransactionModel({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.isExpense,
    TransactionKind? kind,
  }) : kind =
           kind ??
           (isExpense ? TransactionKind.expense : TransactionKind.income);

  /// Parsed [date]; null if the stored text is not a valid date.
  DateTime? get dateTime => DateTime.tryParse(date);
}
