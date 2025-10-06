import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/services/firebase_ai_service.dart';
import 'package:dishcovery_app/core/database/database_helper.dart';
import 'package:dishcovery_app/providers/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';

class ScanProvider extends ChangeNotifier {
  final FirebaseAiService _aiService = FirebaseAiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _loading = false;
  ScanResult? _result;
  String? _error;
  String _loadingMessage = "Memproses gambar...";
  BuildContext? _lastContext;

  bool get loading => _loading;
  ScanResult? get result => _result;
  String? get error => _error;
  String get loadingMessage => _loadingMessage;

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
        parsed = ScanResult.fromJson(res).copyWith(imagePath: imagePath);
        debugPrint("Parsed result: ${parsed.name}");
        debugPrint("History: ${parsed.history}");
      } catch (parseError) {
        debugPrint("Error parsing result: $parseError");
        throw Exception("Failed to parse API response: $parseError");
      }

      _result = parsed;

      // Save to database
      if (parsed.name.toLowerCase() != "bukan makanan") {
        _loadingMessage = "Menyimpan hasil...";
        notifyListeners();

        final existing = await _dbHelper.getAllHistory();
        final alreadyExists = existing.any(
          (item) =>
              item.name == parsed.name && item.imagePath == parsed.imagePath,
        );

        if (!alreadyExists) {
          await _dbHelper.insertScanResult(parsed);
        }
      }

      // Update history if context is available
      if (_lastContext != null && _lastContext!.mounted) {
        try {
          final historyProvider = Provider.of<HistoryProvider>(
            _lastContext!,
            listen: false,
          );
          await historyProvider.loadHistory();
        } catch (e) {
          debugPrint("Could not update history provider: $e");
        }
      }
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
      await for (final res in stream) {
        try {
          final parsed = ScanResult.fromJson(
            res,
          ).copyWith(imagePath: imagePath);
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

      // Save to database after stream completes
      final result = _result;
      if (result != null && result.name.toLowerCase() != "bukan makanan") {
        _loadingMessage = "Menyimpan hasil...";
        notifyListeners();

        final existing = await _dbHelper.getAllHistory();
        final alreadyExists = existing.any(
          (item) =>
              item.name == result.name && item.imagePath == result.imagePath,
        );

        if (!alreadyExists) {
          await _dbHelper.insertScanResult(result);
        }
      }

      // Update history if context is available
      if (_lastContext != null && _lastContext!.mounted) {
        try {
          final historyProvider = Provider.of<HistoryProvider>(
            _lastContext!,
            listen: false,
          );
          await historyProvider.loadHistory();
        } catch (e) {
          debugPrint("Could not update history provider: $e");
        }
      }
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
    notifyListeners();
  }
}
