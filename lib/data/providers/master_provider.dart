import 'package:flutter/material.dart';

import '../repositories/master_repository.dart';

class MasterProvider extends ChangeNotifier {
  final MasterRepository _repository = MasterRepository();

  List<Map<String, dynamic>> _expenseCategories = [];

  List<Map<String, dynamic>> _subcategories = [];

  List<Map<String, dynamic>> get expenseCategories => _expenseCategories;

  List<Map<String, dynamic>> get subcategories => _subcategories;

  Future<void> loadExpenseCategories({
    int? alsoIncludeId,
    bool includeInactive = false,
  }) async {
    _expenseCategories = await _repository.getCategoriesByType(
      0,
      alsoIncludeId: alsoIncludeId,
      includeInactive: includeInactive,
    );

    notifyListeners();
  }

  Future<void> loadSubcategories(int categoryId, {int? alsoIncludeId}) async {
    _subcategories = await _repository.getSubcategoriesByCategory(
      categoryId,
      alsoIncludeId: alsoIncludeId,
    );

    notifyListeners();
  }

  //

  List<Map<String, dynamic>> _incomeCategories = [];

  List<Map<String, dynamic>> _incomeSubcategories = [];

  List<Map<String, dynamic>> get incomeCategories => _incomeCategories;

  List<Map<String, dynamic>> get incomeSubCategories => _incomeSubcategories;

  Future<void> loadIncomeCategories({
    int? alsoIncludeId,
    bool includeInactive = false,
  }) async {
    _incomeCategories = await _repository.getCategoriesByType(
      1,
      alsoIncludeId: alsoIncludeId,
      includeInactive: includeInactive,
    );

    notifyListeners();
  }

  Future<void> loadIncomeSubcategories(
    int categoryId, {
    int? alsoIncludeId,
  }) async {
    debugPrint("categoryId   ::  $categoryId");
    _incomeSubcategories = await _repository.getSubcategoriesByCategory(
      categoryId,
      alsoIncludeId: alsoIncludeId,
    );

    debugPrint("_incomeSubcategories Size ::  ${_incomeSubcategories.length}");
    notifyListeners();
  }
}
