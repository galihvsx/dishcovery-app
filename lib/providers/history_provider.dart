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

  HistoryProvider(this._database) {
    _initializeHistory();
  }

  List<ScanResult> get historyList => _historyList;
  List<ScanResult> get favoritesList => _favoritesList;
  bool get isLoading => _isLoading;

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

      // Subscribe to Firestore updates
      _historySubscription = _firestoreService
          .getUserScans(user.uid)
          .listen(
            (scans) {
              // Use a Set to ensure unique items by firestoreId
              final uniqueScans = <String, ScanResult>{};
              for (final scan in scans) {
                if (scan.firestoreId != null) {
                  uniqueScans[scan.firestoreId!] = scan;
                }
              }

              _historyList = uniqueScans.values.toList();
              _isLoading = false;
              notifyListeners();

              // Cache to ObjectBox for offline access
              _cacheScansToLocal(_historyList);
            },
            onError: (error) async {
              print('Error loading from Firestore, using local cache: $error');
              // Fallback to ObjectBox cache
              _historyList = await _database.getAllHistory();
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      print('Error loading history: $e');
      // Fallback to ObjectBox cache
      _historyList = await _database.getAllHistory();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cache scans to ObjectBox
  Future<void> _cacheScansToLocal(List<ScanResult> scans) async {
    // Get all existing cached scans once
    final existing = await _database.getAllHistory();
    final existingFirestoreIds = existing
        .where((s) => s.firestoreId != null)
        .map((s) => s.firestoreId!)
        .toSet();

    for (final scan in scans) {
      try {
        if (scan.firestoreId == null) continue;

        // Skip if already processed in this session
        if (_processedFirestoreIds.contains(scan.firestoreId)) continue;

        if (!existingFirestoreIds.contains(scan.firestoreId)) {
          // New scan, insert it
          await _database.insertScanResult(scan);
        } else {
          // Existing scan, update it
          // Find the existing scan with matching firestoreId
          final existingScan = existing.firstWhere(
            (s) => s.firestoreId == scan.firestoreId,
            orElse: () => scan,
          );
          if (existingScan.id != null) {
            await _database.updateScanResult(scan.copyWith(id: existingScan.id));
          }
        }

        // Mark as processed
        _processedFirestoreIds.add(scan.firestoreId!);
      } catch (e) {
        print('Error caching scan: $e');
      }
    }
  }

  /// Add new scan (saved to both Firestore and ObjectBox)
  /// Note: This is called after Firestore save, so the listener will also pick it up
  /// We need to ensure we don't duplicate it
  Future<void> addHistory(ScanResult data) async {
    // Check if already exists in history list by firestoreId
    if (data.firestoreId != null) {
      final exists = _historyList.any((s) => s.firestoreId == data.firestoreId);
      if (exists) {
        print('Scan already exists in history, skipping addHistory');
        return;
      }
    }

    // Cache locally immediately
    await _database.insertScanResult(data);

    // Add to processed IDs to prevent duplicate processing
    if (data.firestoreId != null) {
      _processedFirestoreIds.add(data.firestoreId!);
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
    notifyListeners();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(ScanResult scan) async {
    final updated = scan.copyWith(isFavorite: !scan.isFavorite);
    await _database.updateScanResult(updated);
    await loadFavorites();
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
    _historyList.clear();
    _favoritesList.clear();
    _database.close();
    super.dispose();
  }
}
