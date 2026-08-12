import 'package:flutter/material.dart';

import '../repositories/master_repository.dart';

class MasterProvider extends ChangeNotifier {
  final MasterRepository _repository = MasterRepository();

  List<Map<String, dynamic>> _expenseCategories = [];

  List<Map<String, dynamic>> _subcategories = [];

  List<Map<String, dynamic>> get expenseCategories => _expenseCategories;

  List<Map<String, dynamic>> get subcategories => _subcategories;

  Future<void> loadExpenseCategories() async {
    _expenseCategories = await _repository.getCategoriesByType(0);

    notifyListeners();
  }

  Future<void> loadSubcategories(int categoryId) async {
    _subcategories = await _repository.getSubcategoriesByCategory(categoryId);

    notifyListeners();
  }

  //

  List<Map<String, dynamic>> _incomeCategories = [];

  List<Map<String, dynamic>> _incomeSubcategories = [];

  List<Map<String, dynamic>> get incomeCategories => _incomeCategories;

  List<Map<String, dynamic>> get incomeSubCategories => _incomeSubcategories;

  Future<void> loadIncomeCategories() async {
    _incomeCategories = await _repository.getCategoriesByType(1);

    notifyListeners();
  }

  Future<void> loadIncomeSubcategories(int categoryId) async {
    debugPrint("categoryId   ::  $categoryId");
    _incomeSubcategories = await _repository.getSubcategoriesByCategory(
      categoryId,
    );

    debugPrint("_incomeSubcategories Size ::  ${_incomeSubcategories.length}");
    notifyListeners();
  }
}
