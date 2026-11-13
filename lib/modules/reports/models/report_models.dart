class MonthlyReport {
  final int month; final double income; final double expense;
  const MonthlyReport({required this.month, required this.income, required this.expense});
  double get net => income - expense;
}
class CategoryExpenseReport {
  final String categoryName; final double amount;
  const CategoryExpenseReport({required this.categoryName, required this.amount});
}
class FinancialReport {
  final int year; final double totalIncome; final double totalExpense;
  final List<MonthlyReport> monthly; final List<CategoryExpenseReport> categories;
  const FinancialReport({required this.year, required this.totalIncome, required this.totalExpense, required this.monthly, required this.categories});
  double get netSavings => totalIncome - totalExpense;
}
