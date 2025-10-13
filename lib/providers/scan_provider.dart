import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/services/firebase_ai_service.dart';
import 'package:dishcovery_app/core/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

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

  /// Mark a transaction as completed
  void _markTransactionCompleted(String transactionId) {
    _completedTransactions.add(transactionId);
    // Keep only last 50 transactions to prevent memory leak
    if (_completedTransactions.length > 50) {
      _completedTransactions.remove(_completedTransactions.first);
    }
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

    _loading = true;
    _error = null;
    _loadingMessage = "Memproses gambar...";
    _lastContext = context;
    notifyListeners();

    try {
      // Check if this transaction was already completed
      if (_isTransactionCompleted(transactionId)) {
        debugPrint("Transaction $transactionId already completed, skipping");
        _loading = false;
        notifyListeners();
        return;
      }

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
        parsed = ScanResult.fromJson(res).copyWith(
          imagePath: imagePath,
          transactionId: transactionId, // Add transaction ID for tracking
        );
        debugPrint("Parsed result: ${parsed.name}");
        debugPrint("History: ${parsed.history}");
        debugPrint("Transaction ID: $transactionId");
      } catch (parseError) {
        debugPrint("Error parsing result: $parseError");
        throw Exception("Failed to parse API response: $parseError");
      }

      _result = parsed;

      // Save to Firestore only - HistoryProvider listener will handle local caching
      if (parsed.name.toLowerCase() != "bukan makanan" && parsed.isFood) {
        _loadingMessage = "Menyimpan hasil...";
        notifyListeners();

        try {
          // Save to Firestore (cloud-first)
          final firestoreId = await _firestoreService.saveScanResult(parsed);

          if (firestoreId != null) {
            // Update result with Firestore ID
            final updatedResult = parsed.copyWith(firestoreId: firestoreId);
            _result = updatedResult;
            
            // Note: HistoryProvider's Firestore listener will automatically
            // cache this to local ObjectBox, preventing duplicate saves
          }
        } catch (e) {
          debugPrint("Error saving scan result: $e");
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

    _loading = true;
    _error = null;
    _loadingMessage = "Memproses gambar...";
    _lastContext = context;
    notifyListeners();

    try {
      // Check if this transaction was already completed
      if (_isTransactionCompleted(transactionId)) {
        debugPrint("Transaction $transactionId already completed, skipping");
        _loading = false;
        notifyListeners();
        return;
      }

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
      await for (final res in stream) {
        try {
          final parsed = ScanResult.fromJson(
            res,
          ).copyWith(
            imagePath: imagePath,
            transactionId: transactionId, // Add transaction ID for tracking
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
        _loadingMessage = "Menyimpan hasil...";
        notifyListeners();

        try {
          // Save to Firestore (cloud-first)
          final firestoreId = await _firestoreService.saveScanResult(result);

          if (firestoreId != null) {
            // Update result with Firestore ID
            final updatedResult = result.copyWith(firestoreId: firestoreId);
            _result = updatedResult;
            
            // Note: HistoryProvider's Firestore listener will automatically
            // cache this to local ObjectBox, preventing duplicate saves
          }
        } catch (e) {
          debugPrint("Error saving scan result: $e");
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
