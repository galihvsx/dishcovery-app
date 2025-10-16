import 'dart:async';

import 'package:dishcovery_app/core/database/objectbox_database.dart';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Provider for managing scan history from Firestore and local cache
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
  ); // Increased from 5 to 30 seconds

  HistoryProvider(this._database) {
    _initializeHistory();
  }

  List<ScanResult> get historyList => _historyList;
  List<ScanResult> get favoritesList => _favoritesList;
  bool get isLoading => _isLoading;

  /// Check if a scan was recently processed (within deduplication window)
  bool _wasRecentlyProcessed(String firestoreId) {
    final lastProcessed = _lastProcessedTimes[firestoreId];
    if (lastProcessed == null) return false;
    return DateTime.now().difference(lastProcessed) < _deduplicationWindow;
  }

  /// Mark a scan as recently processed
  void _markAsProcessed(String firestoreId) {
    _lastProcessedTimes[firestoreId] = DateTime.now();
    // Clean up old entries
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

  /// Load history from Firestore (online) or ObjectBox (offline)
  Future<void> loadHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cancel previous subscription first to prevent duplicates
    await _historySubscription?.cancel();
    _historySubscription = null;

    _isLoading = true;
    notifyListeners();

    try {
      // Clear processed IDs when reloading
      _processedFirestoreIds.clear();
      _processedTransactionIds.clear();
      _lastProcessedTimes.clear();

      // Subscribe to Firestore updates
      _historySubscription = _firestoreService
          .getUserScans(user.uid)
          .listen(
            (scans) {
              // Filter and deduplicate scans
              final filteredScans = <ScanResult>[];
              final seenFirestoreIds = <String>{};
              final seenTransactionIds = <String>{};
              final seenContentHashes = <String>{};

              for (final scan in scans) {
                // Skip if already processed in this session
                if (scan.firestoreId != null &&
                    _processedFirestoreIds.contains(scan.firestoreId!)) {
                  continue;
                }

                // Skip if recently processed (within deduplication window)
                if (scan.firestoreId != null &&
                    _wasRecentlyProcessed(scan.firestoreId!)) {
                  continue;
                }

                // Skip duplicate by firestoreId within this batch
                if (scan.firestoreId != null &&
                    seenFirestoreIds.contains(scan.firestoreId!)) {
                  continue;
                }

                // Skip duplicate by transactionId within this batch
                if (scan.transactionId != null &&
                    seenTransactionIds.contains(scan.transactionId!)) {
                  continue;
                }

                // Skip duplicate by contentHash
                if (scan.contentHash != null &&
                    seenContentHashes.contains(scan.contentHash!)) {
                  continue;
                }

                // Add to filtered list
                filteredScans.add(scan);

                // Mark as seen and processed
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

              // Sort by creation time (newest first)
              filteredScans.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              _historyList = filteredScans;
              _applyFavoritesToHistory();
              _isLoading = false;
              notifyListeners();

              // Cache to ObjectBox for offline access
              _cacheScansToLocal(_historyList);
            },
            onError: (error) async {
              print('Error loading from Firestore, using local cache: $error');
              // Fallback to ObjectBox cache
              _historyList = await _database.getAllHistory();
              _applyFavoritesToHistory();
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      print('Error loading history: $e');
      // Fallback to ObjectBox cache
      _historyList = await _database.getAllHistory();
      _applyFavoritesToHistory();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cache scans to ObjectBox
  Future<void> _cacheScansToLocal(List<ScanResult> scans) async {
    // Get all existing cached scans once
    final existing = await _database.getAllHistory();
    final existingFirestoreIds =
        existing
            .where((s) => s.firestoreId != null)
            .map((s) => s.firestoreId!)
            .toSet();

    for (final scan in scans) {
      try {
        if (scan.firestoreId == null) continue;

        // Skip if already processed in this session
        if (_processedFirestoreIds.contains(scan.firestoreId)) continue;

        // Skip if recently processed to prevent duplicate saves
        if (_wasRecentlyProcessed(scan.firestoreId!)) continue;

        if (!existingFirestoreIds.contains(scan.firestoreId)) {
          // New scan, insert it
          await _database.insertScanResult(scan);
          print(
            'Cached new scan to ObjectBox: ${scan.name} (${scan.firestoreId})',
          );
        } else {
          // Existing scan, update it
          // Find the existing scan with matching firestoreId
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

        // Mark as processed
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

      // Check if recently processed
      if (_wasRecentlyProcessed(data.firestoreId!)) {
        print('Scan was recently processed, skipping addHistory');
        return;
      }
    }

    // Check by transactionId if provided
    if (transactionId != null) {
      if (_processedTransactionIds.contains(transactionId)) {
        print('Transaction ID already processed, skipping addHistory');
        return;
      }
      _processedTransactionIds.add(transactionId);
    }

    // Cache locally immediately
    await _database.insertScanResult(data);

    // Add to processed IDs to prevent duplicate processing
    if (data.firestoreId != null) {
      _processedFirestoreIds.add(data.firestoreId!);
      _markAsProcessed(data.firestoreId!);
    }

    // The Firestore listener will update the list, so we don't need to do it here
    // This prevents the duplicate addition issue
  }

  /// Delete history item from Firestore and local cache
  Future<void> deleteHistory(ScanResult scan) async {
    ScanResult? localScan;

    // Try to resolve the local cached entity by ObjectBox ID
    if (scan.id != null) {
      try {
        localScan = _database.getScanResultById(scan.id!);
      } catch (e) {
        print('Error finding scan by ID: $e');
      }
    }

    // Fallback to lookup using Firestore ID if no local record found
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

  /// Clear all history
  Future<void> clearAll() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Delete all user's scans from Firestore
    final scans = await _firestoreService.getUserScans(user.uid).first;
    for (final scan in scans) {
      if (scan.firestoreId != null) {
        await _firestoreService.deleteScanResult(scan.firestoreId!);
      }
    }

    // Clear local cache
    await _database.clearAll();

    _historyList = [];
    notifyListeners();
  }

  /// Load favorites (local only)
  Future<void> loadFavorites() async {
    _favoritesList = await _database.getFavorites();
    _applyFavoritesToHistory();
    notifyListeners();
  }

  bool isInCollection(ScanResult? scan) {
    if (scan == null) return false;
    return _favoritesList.any((fav) => _isSameScan(fav, scan));
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(ScanResult scan) async {
    final localScan = await _ensureLocalScan(scan);
    if (localScan == null) return;
    await _setFavoriteStatus(localScan, !localScan.isFavorite);
  }

  /// Explicitly set favorite status (add/remove from collection)
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

  /// Ensure the scan exists locally before updating favorites
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

  /// Search history
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
    // Cancel subscription and clear state
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
