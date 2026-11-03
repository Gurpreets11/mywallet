import 'package:flutter/foundation.dart';
import '../models/budget_model.dart';
import '../repositories/budget_repository.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _repository = BudgetRepository();
  List<BudgetModel> _budgets = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  List<BudgetModel> get budgets => List.unmodifiable(_budgets);
  List<Map<String, dynamic>> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  int get month => _month;
  int get year => _year;
  double get totalBudget => _budgets.fold(0, (sum, item) => sum + item.amount);
  double get totalSpent =>
      _budgets.fold(0, (sum, item) => sum + item.spentAmount);
  double get totalRemaining => totalBudget - totalSpent;

  Future<void> load({int? month, int? year}) async {
    _month = month ?? _month;
    _year = year ?? _year;
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getBudgets(month: _month, year: _year),
        _repository.getExpenseCategories(),
      ]);
      _budgets = results[0] as List<BudgetModel>;
      _categories = results[1] as List<Map<String, dynamic>>;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeMonth(int delta) async {
    final next = DateTime(_year, _month + delta, 1);
    await load(month: next.month, year: next.year);
  }

  Future<void> save(BudgetModel budget) async {
    await _repository.saveBudget(budget);
    await load();
  }

  Future<void> delete(int id) async {
    await _repository.deleteBudget(id);
    await load();
  }
}
