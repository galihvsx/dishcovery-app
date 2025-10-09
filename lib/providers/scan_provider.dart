import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/services/firebase_ai_service.dart';
import 'package:dishcovery_app/core/services/firestore_service.dart';
import 'package:dishcovery_app/providers/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'dart:typed_data';

class ScanProvider extends ChangeNotifier {
  final FirebaseAiService _aiService = FirebaseAiService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _loading = false;
  ScanResult? _result;
  String? _error;
  String _loadingMessage = '';
  BuildContext? _lastContext;

  bool get loading => _loading;
  ScanResult? get result => _result;
  String? get error => _error;
  String get loadingMessage => _loadingMessage;

  // Build prompt based on language code
  String _buildPrompt(String languageCode) {
    if (languageCode == 'id') {
      return '''
Identifikasi makanan Indonesia dalam gambar ini.
Jika bukan makanan, set name="bukan makanan" dan isFood=false.
Jika makanan, berikan informasi singkat dan padat:
- Fokus pada informasi penting saja
- Deskripsi maksimal 2 paragraf
- History maksimal 1 paragraf
- Recipe dengan bahan dan langkah utama saja
- Tags maksimal 5
- Related foods maksimal 3
Jawab dalam Bahasa Indonesia.
''';
    } else {
      return '''
Identify the Indonesian food in this image.
If it's not food, set name="not food" and isFood=false.
If it's food, provide concise information:
- Focus only on important details
- Description max 2 paragraphs
- History max 1 paragraph
- Recipe with main ingredients and steps only
- Tags max 5
- Related foods max 3
Respond in English.
''';
    }
  }

  /// Optimize image before sending to API
  Future<Uint8List> _optimizeImage(String imagePath) async {
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

    // Get current language code from context
    String languageCode = context?.locale.languageCode ?? 'id';
    print("Language code nya: $languageCode");

    _loadingMessage = 'scan_loading.processing'.tr();
    _lastContext = context;
    notifyListeners();

    try {
      _loadingMessage = 'scan_loading.optimizing'.tr();
      notifyListeners();
      // Optimize image first
      final optimizedBytes = await _optimizeImage(imagePath);

      _loadingMessage = 'scan_loading.identifying'.tr();
      notifyListeners();

      // Generate prompt based on language code from context
      final prompt = _buildPrompt(languageCode);

      // Use non-streaming version for stability
      final res = await _aiService.imageToDishcovery(
        imageBytes: optimizedBytes,
        prompt: prompt,
        languageCode: languageCode,
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

      // Save to Firestore and cache locally
      if (parsed.name.toLowerCase() != "bukan makanan" &&
          parsed.name.toLowerCase() != "not food" &&
          parsed.isFood) {
        _loadingMessage = 'scan_loading.saving'.tr();
        notifyListeners();

        try {
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
              await historyProvider.addHistory(updatedResult);
            }
          }
        } catch (e) {
          debugPrint("Error saving scan result: $e");
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error processing image: ${e.toString()}");
      debugPrint("Stack trace: $stackTrace");
      _error = 'scan_loading.error'.tr(args: [e.toString()]);
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

    // Get current language code from context
    String languageCode = context?.locale.languageCode ?? 'id';

    _loadingMessage = 'scan_loading.processing'.tr();
    _lastContext = context;
    notifyListeners();

    try {
      _loadingMessage = 'scan_loading.optimizing'.tr();
      notifyListeners();
      // Optimize image first
      final optimizedBytes = await _optimizeImage(imagePath);

      _loadingMessage = 'scan_loading.identifying'.tr();
      notifyListeners();

      // Generate prompt based on language
      final prompt = _buildPrompt(languageCode);

      // Use streaming for progressive response
      final stream = _aiService.imageToDishcoveryStream(
        imageBytes: optimizedBytes,
        prompt: prompt,
        languageCode: languageCode,
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
            _loadingMessage = 'scan_loading.loading_details'.tr();
          } else if (parsed.description.isNotEmpty &&
              parsed.recipe.ingredients.isEmpty) {
            _loadingMessage = 'scan_loading.loading_recipe'.tr();
          }

          notifyListeners(); // Update UI with partial data
        } catch (e) {
          // Continue if partial JSON can't be parsed yet
          continue;
        }
      }

      // Save to Firestore and cache locally after stream completes
      final result = _result;
      if (result != null &&
          result.name.toLowerCase() != "bukan makanan" &&
          result.name.toLowerCase() != "not food" &&
          result.isFood) {
        _loadingMessage = 'scan_loading.saving'.tr();
        notifyListeners();

        try {
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
              await historyProvider.addHistory(updatedResult);
            }
          }
        } catch (e) {
          debugPrint("Error saving scan result: $e");
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error processing image with stream: ${e.toString()}");
      debugPrint("Stack trace: $stackTrace");
      _error = 'scan_loading.error'.tr(args: [e.toString()]);
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
