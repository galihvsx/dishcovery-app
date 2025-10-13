import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/services/firebase_ai_service.dart';
import 'package:dishcovery_app/core/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ScanProvider extends ChangeNotifier {
  final FirebaseAiService _aiService = FirebaseAiService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _loading = false;
  ScanResult? _result;
  String? _error;
  String _loadingMessage = "Memproses gambar...";
  BuildContext? _lastContext;
  String? _currentTransactionId;
  final Set<String> _completedTransactions = {};
  final Set<String> _inProgressTransactions = {};
  bool _isSaving = false; // Prevent concurrent saves

  bool get loading => _loading;
  ScanResult? get result => _result;
  String? get error => _error;
  String get loadingMessage => _loadingMessage;

  /// Generate unique transaction ID for tracking scan operations
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    return 'scan_${timestamp}_$random';
  }

  /// Check if a transaction has been completed
  bool _isTransactionCompleted(String transactionId) {
    return _completedTransactions.contains(transactionId);
  }

  /// Check if a transaction is currently in progress
  bool _isTransactionInProgress(String transactionId) {
    return _inProgressTransactions.contains(transactionId);
  }

  /// Mark a transaction as in progress
  void _markTransactionInProgress(String transactionId) {
    _inProgressTransactions.add(transactionId);
  }

  /// Mark a transaction as completed
  void _markTransactionCompleted(String transactionId) {
    _inProgressTransactions.remove(transactionId);
    _completedTransactions.add(transactionId);
    // Keep only last 50 transactions to prevent memory leak
    if (_completedTransactions.length > 50) {
      _completedTransactions.remove(_completedTransactions.first);
    }
  }

  /// Generate content hash from image bytes and food name
  String _generateContentHash(
    Uint8List imageBytes,
    String foodName,
    String userId,
  ) {
    // Create a simple hash of the first 1000 bytes (for performance)
    // Combined with food name and user ID for uniqueness
    final sampleSize = imageBytes.length > 1000 ? 1000 : imageBytes.length;
    final imageSample = imageBytes.sublist(0, sampleSize);

    // Combine image sample, food name, and userId for the hash
    final contentToHash = utf8.encode(
      '${base64.encode(imageSample)}_${foodName.toLowerCase()}_$userId',
    );

    // Generate SHA256 hash
    final digest = sha256.convert(contentToHash);
    return digest.toString();
  }

  /// Optimize image before sending to API
  Future<Uint8List> _optimizeImage(String imagePath) async {
    _loadingMessage = "Mengoptimalkan gambar...";
    notifyListeners();

    final file = File(imagePath);
    final bytes = await file.readAsBytes();

    // Decode the image
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // Resize if image is too large (max 1024px on longest side)
    const maxSize = 1024;
    img.Image resized;

    if (image.width > maxSize || image.height > maxSize) {
      if (image.width > image.height) {
        resized = img.copyResize(image, width: maxSize);
      } else {
        resized = img.copyResize(image, height: maxSize);
      }
    } else {
      resized = image;
    }

    // Compress to JPEG with 85% quality
    final optimized = img.encodeJpg(resized, quality: 85);
    return Uint8List.fromList(optimized);
  }

  Future<void> processImage(String imagePath, {BuildContext? context}) async {
    // Generate new transaction ID for this scan operation
    _currentTransactionId = _generateTransactionId();
    final transactionId = _currentTransactionId!;

    // PRE-AI GUARD: Check if this transaction is already in progress or completed
    // This prevents duplicate AI calls when the same image is processed multiple times
    if (_isTransactionInProgress(transactionId) ||
        _isTransactionCompleted(transactionId)) {
      debugPrint(
        "Transaction $transactionId already in progress or completed, skipping",
      );
      return;
    }

    // Mark transaction as in progress immediately
    _markTransactionInProgress(transactionId);

    _loading = true;
    _error = null;
    _loadingMessage = "Memproses gambar...";
    _lastContext = context;
    notifyListeners();

    try {
      // Optimize image first
      final optimizedBytes = await _optimizeImage(imagePath);

      _loadingMessage = "Mengidentifikasi makanan...";
      notifyListeners();

      // Use non-streaming version for stability
      final res = await _aiService.imageToDishcovery(
        imageBytes: optimizedBytes,
        prompt: """
Identifikasi makanan Indonesia dalam gambar ini.
Jika bukan makanan, set name="bukan makanan" dan isFood=false.
Jika makanan, berikan informasi singkat dan padat:
- Fokus pada informasi penting saja
- Deskripsi maksimal 2 paragraf
- History maksimal 1 paragraf
- Recipe dengan bahan dan langkah utama saja
- Tags maksimal 5
- Related foods maksimal 3
""",
      );

      // Safe parsing with error handling
      final ScanResult parsed;
      try {
        // Generate content hash before creating the result
        final user = _firestoreService.currentUser;
        final userId = user?.uid ?? 'anonymous';
        final contentHash = _generateContentHash(
          optimizedBytes,
          res['name'] ?? '',
          userId,
        );

        parsed = ScanResult.fromJson(res).copyWith(
          imagePath: imagePath,
          transactionId: transactionId, // Add transaction ID for tracking
          contentHash: contentHash, // Add content hash for duplicate detection
        );
        debugPrint("Parsed result: ${parsed.name}");
        debugPrint("History: ${parsed.history}");
        debugPrint("Transaction ID: $transactionId");
        debugPrint("Content Hash: $contentHash");
      } catch (parseError) {
        debugPrint("Error parsing result: $parseError");
        throw Exception("Failed to parse API response: $parseError");
      }

      _result = parsed;

      // Save to Firestore only - HistoryProvider listener will handle local caching
      if (parsed.name.toLowerCase() != "bukan makanan" && parsed.isFood) {
        // Prevent concurrent saves
        if (_isSaving) {
          debugPrint("Save already in progress, skipping duplicate save");
          return;
        }
        _isSaving = true;

        _loadingMessage = "Memeriksa duplikat...";
        notifyListeners();

        try {
          final user = _firestoreService.currentUser;
          if (user != null && parsed.contentHash != null) {
            // Check for duplicate by content hash
            final isDuplicate = await _firestoreService.checkDuplicateScan(
              parsed.contentHash!,
              user.uid,
            );

            if (isDuplicate) {
              debugPrint(
                "Duplicate scan detected by content hash, skipping save",
              );
              _isSaving = false;
              return;
            }

            // Check for recent similar scan (same food within 1 minute)
            final hasRecentSimilar = await _firestoreService
                .checkRecentSimilarScan(parsed.name, user.uid);

            if (hasRecentSimilar) {
              debugPrint("Recent similar scan detected, skipping save");
              _isSaving = false;
              return;
            }
          }

          _loadingMessage = "Menyimpan hasil...";
          notifyListeners();

          // Save to Firestore (cloud-first)
          final firestoreId = await _firestoreService.saveScanResult(parsed);

          if (firestoreId != null) {
            // Update result with Firestore ID
            final updatedResult = parsed.copyWith(firestoreId: firestoreId);
            _result = updatedResult;

            // Cache locally using HistoryProvider (ObjectBox)
            if (_lastContext != null && _lastContext!.mounted) {
              final historyProvider = Provider.of<HistoryProvider>(
                _lastContext!,
                listen: false,
              );
              // Pass transaction ID to prevent duplicate processing
              await historyProvider.addHistory(
                updatedResult,
                transactionId: transactionId,
              );
            }
          }
        } catch (e) {
          debugPrint("Error saving scan result: $e");
        } finally {
          _isSaving = false;
        }
      }

      // Mark transaction as completed
      _markTransactionCompleted(transactionId);
    } catch (e, stackTrace) {
      debugPrint("Error processing image: ${e.toString()}");
      debugPrint("Stack trace: $stackTrace");
      _error = "Gagal memproses gambar: ${e.toString()}";
    }

    _loading = false;
    notifyListeners();
  }

  /// Alternative: Process image with streaming (experimental)
  Future<void> processImageWithStream(
    String imagePath, {
    BuildContext? context,
  }) async {
    // Generate new transaction ID for this scan operation
    _currentTransactionId = _generateTransactionId();
    final transactionId = _currentTransactionId!;

    // PRE-AI GUARD: Check if this transaction is already in progress or completed
    // This prevents duplicate AI calls when the same image is processed multiple times
    if (_isTransactionInProgress(transactionId) ||
        _isTransactionCompleted(transactionId)) {
      debugPrint(
        "Transaction $transactionId already in progress or completed, skipping",
      );
      return;
    }

    // Mark transaction as in progress immediately
    _markTransactionInProgress(transactionId);

    _loading = true;
    _error = null;
    _loadingMessage = "Memproses gambar...";
    _lastContext = context;
    notifyListeners();

    try {
      // Optimize image first
      final optimizedBytes = await _optimizeImage(imagePath);

      _loadingMessage = "Mengidentifikasi makanan...";
      notifyListeners();

      // Use streaming for progressive response
      final stream = _aiService.imageToDishcoveryStream(
        imageBytes: optimizedBytes,
        prompt: """
Identifikasi makanan Indonesia dalam gambar ini.
Jika bukan makanan, set name="bukan makanan" dan isFood=false.
Jika makanan, berikan informasi singkat dan padat:
- Fokus pada informasi penting saja
- Deskripsi maksimal 2 paragraf
- History maksimal 1 paragraf
- Recipe dengan bahan dan langkah utama saja
- Tags maksimal 5
""",
      );

      bool firstUpdate = true;
      String? contentHash;
      await for (final res in stream) {
        try {
          // Generate content hash on first successful parse with name
          if (contentHash == null && res['name'] != null) {
            final user = _firestoreService.currentUser;
            final userId = user?.uid ?? 'anonymous';
            contentHash = _generateContentHash(
              optimizedBytes,
              res['name'] ?? '',
              userId,
            );
            debugPrint("Generated content hash: $contentHash");
          }

          final parsed = ScanResult.fromJson(res).copyWith(
            imagePath: imagePath,
            transactionId: transactionId, // Add transaction ID for tracking
            contentHash:
                contentHash, // Add content hash for duplicate detection
          );
          _result = parsed;

          if (firstUpdate) {
            _loading = false; // Stop loading as soon as we get first data
            firstUpdate = false;
          }

          // Update loading message based on what we have
          if (parsed.name.isNotEmpty && parsed.description.isEmpty) {
            _loadingMessage = "Memuat detail makanan...";
          } else if (parsed.description.isNotEmpty &&
              parsed.recipe.ingredients.isEmpty) {
            _loadingMessage = "Memuat resep...";
          }

          notifyListeners(); // Update UI with partial data
        } catch (e) {
          // Continue if partial JSON can't be parsed yet
          continue;
        }
      }

      // Save to Firestore only - HistoryProvider listener will handle local caching
      final result = _result;
      if (result != null &&
          result.name.toLowerCase() != "bukan makanan" &&
          result.isFood) {
        // Prevent concurrent saves
        if (_isSaving) {
          debugPrint("Save already in progress, skipping duplicate save");
          return;
        }
        _isSaving = true;

        _loadingMessage = "Memeriksa duplikat...";
        notifyListeners();

        try {
          final user = _firestoreService.currentUser;
          if (user != null && result.contentHash != null) {
            // Check for duplicate by content hash
            final isDuplicate = await _firestoreService.checkDuplicateScan(
              result.contentHash!,
              user.uid,
            );

            if (isDuplicate) {
              debugPrint(
                "Duplicate scan detected by content hash, skipping save",
              );
              _isSaving = false;
              return;
            }

            // Check for recent similar scan (same food within 1 minute)
            final hasRecentSimilar = await _firestoreService
                .checkRecentSimilarScan(result.name, user.uid);

            if (hasRecentSimilar) {
              debugPrint("Recent similar scan detected, skipping save");
              _isSaving = false;
              return;
            }
          }

          _loadingMessage = "Menyimpan hasil...";
          notifyListeners();

          // Save to Firestore (cloud-first)
          final firestoreId = await _firestoreService.saveScanResult(result);

          if (firestoreId != null) {
            // Update result with Firestore ID
            final updatedResult = result.copyWith(firestoreId: firestoreId);
            _result = updatedResult;

            // Cache locally using HistoryProvider (ObjectBox)
            if (_lastContext != null && _lastContext!.mounted) {
              final historyProvider = Provider.of<HistoryProvider>(
                _lastContext!,
                listen: false,
              );
              // Pass transaction ID to prevent duplicate processing
              await historyProvider.addHistory(
                updatedResult,
                transactionId: transactionId,
              );
            }
          }
        } catch (e) {
          debugPrint("Error saving scan result: $e");
        } finally {
          _isSaving = false;
        }
      }

      // Mark transaction as completed
      _markTransactionCompleted(transactionId);
    } catch (e, stackTrace) {
      debugPrint("Error processing image with stream: ${e.toString()}");
      debugPrint("Stack trace: $stackTrace");
      _error = "Gagal memproses gambar: ${e.toString()}";
    }

    _loading = false;
    notifyListeners();
  }

  void clear() {
    _result = null;
    _error = null;
    _loading = false;

    // Defer notification to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setResult(ScanResult result) {
    _result = result;
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
