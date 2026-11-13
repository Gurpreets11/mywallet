import 'package:flutter/foundation.dart';
import '../models/report_models.dart';
import '../repositories/report_repository.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository;
  ReportProvider({ReportRepository? repository}) : _repository=repository ?? ReportRepository();
  int _year=DateTime.now().year; FinancialReport? _report; bool _loading=false; String? _error;
  int get selectedYear=>_year; FinancialReport? get report=>_report; bool get isLoading=>_loading; String? get error=>_error;
  Future<void> load({int? year}) async {
    if(year!=null) _year=year;
    _loading=true; _error=null; notifyListeners();
    try { _report=await _repository.getYearlyReport(_year); }
    catch(e) { _error='Unable to load reports: $e'; }
    finally { _loading=false; notifyListeners(); }
  }
  Future<void> changeYear(int year)=>load(year:year);
}
