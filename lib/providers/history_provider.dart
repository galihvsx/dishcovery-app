import 'package:dishcovery_app/core/database/database_helper.dart';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:flutter/foundation.dart';

class HistoryProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<ScanResult> _historyList = [];

  List<ScanResult> get historyList => _historyList;

  Future<void> loadHistory() async {
    final data = await _dbHelper.getAllHistory();
    _historyList = data;
    notifyListeners();
  }

  Future<void> addHistory(ScanResult data) async {
    await _dbHelper.insertScanResult(data);
    await loadHistory();
  }

  Future<void> deleteHistory(int id) async {
    await _dbHelper.deleteHistory(id);
    await loadHistory();
  }

  Future<void> clearAll() async {
    await _dbHelper.clearAll();
    await loadHistory();
  }
}
