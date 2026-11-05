import 'package:flutter/material.dart';

import '../models/recurring_transaction_model.dart';
import '../repositories/recurring_repository.dart';

class RecurringProvider extends ChangeNotifier {
  final RecurringRepository _repository = RecurringRepository();
  List<RecurringTransactionModel> _items = [];
  bool _isLoading = false;
  int _lastGeneratedCount = 0;

  List<RecurringTransactionModel> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  int get lastGeneratedCount => _lastGeneratedCount;

  Future<void> load({bool generateDue = true}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (generateDue) {
        _lastGeneratedCount = await _repository.generateDueTransactions();
      }
      _items = await _repository.getAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(RecurringTransactionModel item) async {
    await _repository.insert(item);
    await load(generateDue: false);
  }

  Future<void> update(RecurringTransactionModel item) async {
    await _repository.update(item);
    await load(generateDue: false);
  }

  Future<void> pause(RecurringTransactionModel item) async {
    if (item.id == null) return;
    await _repository.setStatus(item.id!, 'PAUSED');
    await load(generateDue: false);
  }

  Future<void> resume(RecurringTransactionModel item) async {
    if (item.id == null) return;
    await _repository.setStatus(item.id!, 'ACTIVE');
    await load();
  }

  Future<void> delete(RecurringTransactionModel item) async {
    if (item.id == null) return;
    await _repository.delete(item.id!);
    await load(generateDue: false);
  }

  Future<int> getOccurrenceCount(int id) => _repository.occurrenceCount(id);
}
