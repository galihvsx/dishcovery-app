import 'package:dishcovery_app/core/database/objectbox_database.dart';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:flutter/foundation.dart';

class HistoryProvider extends ChangeNotifier {
  final ObjectBoxDatabase _database;
  List<ScanResult> _historyList = [];

  HistoryProvider(this._database);

  List<ScanResult> get historyList => _historyList;

  Future<void> loadHistory() async {
    final data = await _database.getAllHistory();
    _historyList = data;
    notifyListeners();
  }

  Future<void> addHistory(ScanResult data) async {
    await _database.insertScanResult(data);
    await loadHistory();
  }

  Future<void> deleteHistory(int id) async {
    await _database.deleteHistory(id);
    await loadHistory();
  }

  Future<void> clearAll() async {
    await _database.clearAll();
    await loadHistory();
  }

  // Additional methods for enhanced functionality
  Future<void> updateHistory(ScanResult data) async {
    await _database.updateScanResult(data);
    await loadHistory();
  }

  Future<List<ScanResult>> searchHistory(String searchTerm) async {
    return await _database.searchByName(searchTerm);
  }

  Future<List<ScanResult>> getSharedHistory() async {
    return await _database.getScanResultsBySharedStatus(true);
  }

  Future<List<ScanResult>> getUnsharedHistory() async {
    return await _database.getScanResultsBySharedStatus(false);
  }

  ScanResult? getHistoryById(int id) {
    return _database.getScanResultById(id);
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }
}
