import 'package:flutter/material.dart';

import '../enums/investment_sort_type.dart';
import '../models/investment_analytics_model.dart';
import '../models/investment_model.dart';

import '../repositories/investment_repository.dart';
import '../utils/investment_utils.dart';

class InvestmentProvider extends ChangeNotifier {
  final InvestmentRepository _repository = InvestmentRepository();

  List<InvestmentModel> _investments = [];

  bool _isLoading = false;

  List<InvestmentModel> get investments => _investments;

  bool get isLoading => _isLoading;

  String _searchQuery = '';

  String _selectedFilter = 'All';

  InvestmentSortType _sortType = InvestmentSortType.latest;

  List<InvestmentModel> _filteredInvestments = [];

  String get searchQuery => _searchQuery;

  String get selectedFilter => _selectedFilter;

  InvestmentSortType get sortType => _sortType;

  List<InvestmentModel> get filteredInvestments => _filteredInvestments;

  InvestmentAnalyticsModel _analytics = const InvestmentAnalyticsModel();

  InvestmentAnalyticsModel get analytics => _analytics;

  Future<void> loadInvestments() async {
    _isLoading = true;

    notifyListeners();

    _investments = await _repository.getAllInvestments();
    _applyFilters();
    _analytics =
    await _repository
        .getInvestmentAnalytics();
    _isLoading = false;

    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;

    _applyFilters();
  }

  void updateFilter(String filter) {
    _selectedFilter = filter;

    _applyFilters();
  }

  void updateSortType(InvestmentSortType type) {
    _sortType = type;

    _applyFilters();
  }

  void _applyFilters() {
    List<InvestmentModel> temp = List.from(_investments);

    /// SEARCH

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();

      temp = temp.where((investment) {
        return investment.investmentName.toLowerCase().contains(query) ||
            investment.investmentType.toLowerCase().contains(query) ||
            (investment.investmentPlatform?.toLowerCase().contains(query) ??
                false);
      }).toList();
    }

    /// FILTER

    if (_selectedFilter != 'All') {
      if (_selectedFilter == 'SIP') {
        temp = temp.where((e) => e.isSip).toList();
      } else {
        temp = temp.where((e) => e.investmentType == _selectedFilter).toList();
      }
    }

    /// SORT

    switch (_sortType) {
      case InvestmentSortType.latest:
        temp.sort((a, b) => b.id!.compareTo(a.id!));

        break;

      case InvestmentSortType.highestInvestment:
        temp.sort((a, b) => b.investedAmount.compareTo(a.investedAmount));

        break;

      case InvestmentSortType.highestProfit:
        temp.sort((a, b) {
          final profitA = InvestmentUtils.calculateProfit(
            investedAmount: a.investedAmount,

            currentValue: a.currentValue,
          );

          final profitB = InvestmentUtils.calculateProfit(
            investedAmount: b.investedAmount,

            currentValue: b.currentValue,
          );

          return profitB.compareTo(profitA);
        });

        break;

      case InvestmentSortType.highestRoi:
        temp.sort((a, b) {
          final roiA = InvestmentUtils.calculateRoi(
            investedAmount: a.investedAmount,

            currentValue: a.currentValue,
          );

          final roiB = InvestmentUtils.calculateRoi(
            investedAmount: b.investedAmount,

            currentValue: b.currentValue,
          );

          return roiB.compareTo(roiA);
        });

        break;
    }

    _filteredInvestments = temp;

    notifyListeners();
  }

  Future<void> addInvestment(InvestmentModel investment) async {
    await _repository.insertInvestment(investment);

    await loadInvestments();
  }

  Future<void> updateInvestment(InvestmentModel investment) async {
    await _repository.updateInvestment(investment);

    await loadInvestments();
  }

  Future<void> deleteInvestment(int id) async {
    await _repository.deleteInvestment(id);

    await loadInvestments();
  }
}
