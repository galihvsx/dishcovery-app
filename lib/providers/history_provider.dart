import 'dart:async';

import 'package:dishcovery_app/core/database/objectbox_database.dart';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class HistoryProvider extends ChangeNotifier {
  final ObjectBoxDatabase _database;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ScanResult> _historyList = [];
  List<ScanResult> _favoritesList = [];
  StreamSubscription? _historySubscription;
  bool _isLoading = false;
  final Set<String> _processedFirestoreIds = {};
  final Set<String> _processedTransactionIds = {};
  final Map<String, DateTime> _lastProcessedTimes = {};
  static const Duration _deduplicationWindow = Duration(
    seconds: 30,
  );

  HistoryProvider(this._database) {
    _initializeHistory();
  }

  List<ScanResult> get historyList => _historyList;
  List<ScanResult> get favoritesList => _favoritesList;
  bool get isLoading => _isLoading;

  bool _wasRecentlyProcessed(String firestoreId) {
    final lastProcessed = _lastProcessedTimes[firestoreId];
    if (lastProcessed == null) return false;
    return DateTime.now().difference(lastProcessed) < _deduplicationWindow;
  }

  void _markAsProcessed(String firestoreId) {
    _lastProcessedTimes[firestoreId] = DateTime.now();
    _lastProcessedTimes.removeWhere(
      (id, time) => DateTime.now().difference(time) > _deduplicationWindow * 2,
    );
  }

  void _initializeHistory() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        loadHistory();
        loadFavorites();
      } else {
        _historyList = [];
        _favoritesList = [];
        notifyListeners();
      }
    });
  }

  Future<void> loadHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _historySubscription?.cancel();
    _historySubscription = null;

    _isLoading = true;
    notifyListeners();

    try {
      _processedFirestoreIds.clear();
      _processedTransactionIds.clear();
      _lastProcessedTimes.clear();

      _historySubscription = _firestoreService
          .getUserScans(user.uid)
          .listen(
            (scans) {
              final filteredScans = <ScanResult>[];
              final seenFirestoreIds = <String>{};
              final seenTransactionIds = <String>{};
              final seenContentHashes = <String>{};

              for (final scan in scans) {
                if (scan.firestoreId != null &&
                    _processedFirestoreIds.contains(scan.firestoreId!)) {
                  continue;
                }

                if (scan.firestoreId != null &&
                    _wasRecentlyProcessed(scan.firestoreId!)) {
                  continue;
                }

                if (scan.firestoreId != null &&
                    seenFirestoreIds.contains(scan.firestoreId!)) {
                  continue;
                }

                if (scan.transactionId != null &&
                    seenTransactionIds.contains(scan.transactionId!)) {
                  continue;
                }

                if (scan.contentHash != null &&
                    seenContentHashes.contains(scan.contentHash!)) {
                  continue;
                }

                filteredScans.add(scan);

                if (scan.firestoreId != null) {
                  seenFirestoreIds.add(scan.firestoreId!);
                  _processedFirestoreIds.add(scan.firestoreId!);
                  _markAsProcessed(scan.firestoreId!);
                }
                if (scan.transactionId != null) {
                  seenTransactionIds.add(scan.transactionId!);
                  _processedTransactionIds.add(scan.transactionId!);
                }
                if (scan.contentHash != null) {
                  seenContentHashes.add(scan.contentHash!);
                }
              }

              filteredScans.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              _historyList = filteredScans;
              _applyFavoritesToHistory();
              _isLoading = false;
              notifyListeners();

              _cacheScansToLocal(_historyList);
            },
            onError: (error) async {
              print('Error loading from Firestore, using local cache: $error');
              _historyList = await _database.getAllHistory();
              _applyFavoritesToHistory();
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      print('Error loading history: $e');
      _historyList = await _database.getAllHistory();
      _applyFavoritesToHistory();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cacheScansToLocal(List<ScanResult> scans) async {
    final existing = await _database.getAllHistory();
    final existingFirestoreIds =
        existing
            .where((s) => s.firestoreId != null)
            .map((s) => s.firestoreId!)
            .toSet();

    for (final scan in scans) {
      try {
        if (scan.firestoreId == null) continue;

        if (_processedFirestoreIds.contains(scan.firestoreId)) continue;

        if (_wasRecentlyProcessed(scan.firestoreId!)) continue;

        if (!existingFirestoreIds.contains(scan.firestoreId)) {
          await _database.insertScanResult(scan);
          print(
            'Cached new scan to ObjectBox: ${scan.name} (${scan.firestoreId})',
          );
        } else {
          final existingScan = existing.firstWhere(
            (s) => s.firestoreId == scan.firestoreId,
            orElse: () => scan,
          );
          if (existingScan.id != null) {
            await _database.updateScanResult(
              scan.copyWith(id: existingScan.id),
            );
            print(
              'Updated existing scan in ObjectBox: ${scan.name} (${scan.firestoreId})',
            );
          }
        }

        _processedFirestoreIds.add(scan.firestoreId!);
        _markAsProcessed(scan.firestoreId!);
      } catch (e) {
        print('Error caching scan: $e');
      }
    }
  }

  Future<void> addHistory(ScanResult data, {String? transactionId}) async {
    print('addHistory called - this should be handled by Firestore listener');

    if (data.firestoreId != null) {
      final exists = _historyList.any((s) => s.firestoreId == data.firestoreId);
      if (exists) {
        print('Scan already exists in history, skipping addHistory');
        return;
      }

      if (_wasRecentlyProcessed(data.firestoreId!)) {
        print('Scan was recently processed, skipping addHistory');
        return;
      }
    }

    if (transactionId != null) {
      if (_processedTransactionIds.contains(transactionId)) {
        print('Transaction ID already processed, skipping addHistory');
        return;
      }
      _processedTransactionIds.add(transactionId);
    }

    await _database.insertScanResult(data);

    if (data.firestoreId != null) {
      _processedFirestoreIds.add(data.firestoreId!);
      _markAsProcessed(data.firestoreId!);
    }

  }

  Future<void> deleteHistory(ScanResult scan) async {
    ScanResult? localScan;

    if (scan.id != null) {
      try {
        localScan = _database.getScanResultById(scan.id!);
      } catch (e) {
        print('Error finding scan by ID: $e');
      }
    }

    if (localScan == null && scan.firestoreId != null) {
      try {
        final cached = await _database.getAllHistory();
        for (final cachedScan in cached) {
          if (cachedScan.firestoreId == scan.firestoreId) {
            localScan = cachedScan;
            break;
          }
        }
      } catch (e) {
        print('Error finding scan by Firestore ID: $e');
      }
    }

    final firestoreId = scan.firestoreId ?? localScan?.firestoreId;
    if (firestoreId != null) {
      await _firestoreService.deleteScanResult(firestoreId);
    }

    final localId = localScan?.id ?? scan.id;
    if (localId != null) {
      await _database.deleteHistory(localId);
    }

    _historyList.removeWhere((item) {
      final matchesLocal = localId != null && item.id == localId;
      final matchesFirestore =
          firestoreId != null && item.firestoreId == firestoreId;
      return matchesLocal || matchesFirestore;
    });
    notifyListeners();
  }

  Future<void> clearAll() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final scans = await _firestoreService.getUserScans(user.uid).first;
    for (final scan in scans) {
      if (scan.firestoreId != null) {
        await _firestoreService.deleteScanResult(scan.firestoreId!);
      }
    }

    await _database.clearAll();

    _historyList = [];
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    _favoritesList = await _database.getFavorites();
    _applyFavoritesToHistory();
    notifyListeners();
  }

  bool isInCollection(ScanResult? scan) {
    if (scan == null) return false;
    return _favoritesList.any((fav) => _isSameScan(fav, scan));
  }

  Future<void> toggleFavorite(ScanResult scan) async {
    final localScan = await _ensureLocalScan(scan);
    if (localScan == null) return;
    await _setFavoriteStatus(localScan, !localScan.isFavorite);
  }

  Future<void> setFavoriteStatus(ScanResult scan, bool isFavorite) async {
    final localScan = await _ensureLocalScan(scan);
    if (localScan == null) return;
    await _setFavoriteStatus(localScan, isFavorite);
  }

  Future<void> _setFavoriteStatus(ScanResult scan, bool isFavorite) async {
    final updated = scan.copyWith(isFavorite: isFavorite);
    await _database.updateScanResult(updated);
    await loadFavorites();
  }

  Future<ScanResult?> _ensureLocalScan(ScanResult scan) async {
    if (scan.id != null) return scan;

    if (scan.firestoreId != null) {
      final existing = _database.getScanResultByFirestoreId(scan.firestoreId!);
      if (existing != null) {
        return existing;
      }
    }

    final newId = await _database.insertScanResult(scan);
    if (newId <= 0) return scan;
    return scan.copyWith(id: newId);
  }

  void _applyFavoritesToHistory() {
    if (_historyList.isEmpty) return;

    final updatedHistory = <ScanResult>[];
    for (final scan in _historyList) {
      final isFav = _favoritesList.any((fav) => _isSameScan(fav, scan));
      updatedHistory.add(scan.copyWith(isFavorite: isFav));
    }
    _historyList = updatedHistory;
  }

  bool _isSameScan(ScanResult a, ScanResult b) {
    if (a.id != null && b.id != null && a.id == b.id) return true;
    if (a.firestoreId != null &&
        b.firestoreId != null &&
        a.firestoreId == b.firestoreId) {
      return true;
    }
    if (a.transactionId != null &&
        b.transactionId != null &&
        a.transactionId == b.transactionId) {
      return true;
    }
    return false;
  }

  Future<List<ScanResult>> searchHistory(String searchTerm) async {
    if (searchTerm.isEmpty) return _historyList;

    return _historyList
        .where(
          (scan) =>
              scan.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
              scan.origin.toLowerCase().contains(searchTerm.toLowerCase()) ||
              scan.tags.any(
                (tag) => tag.toLowerCase().contains(searchTerm.toLowerCase()),
              ),
        )
        .toList();
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    _historySubscription = null;
    _processedFirestoreIds.clear();
    _processedTransactionIds.clear();
    _lastProcessedTimes.clear();
    _historyList.clear();
    _favoritesList.clear();
    _database.close();
    super.dispose();
  }
}
