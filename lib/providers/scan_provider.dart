import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/services/firebase_ai_service.dart';
import 'package:dishcovery_app/core/services/firestore_service.dart';
import 'package:dishcovery_app/providers/history_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

class ScanProvider extends ChangeNotifier {
  final FirebaseAiService _aiService = FirebaseAiService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _loading = false;
  ScanResult? _result;
  String? _error;
  String _loadingMessage = '';
  BuildContext? _lastContext;
  String? _currentTransactionId;
  final Set<String> _completedTransactions = {};
  final Set<String> _inProgressTransactions = {};
  bool _isSaving = false;

  bool get loading => _loading;
  ScanResult? get result => _result;
  String? get error => _error;
  String get loadingMessage => _loadingMessage;

  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    return 'scan_${timestamp}_$random';
  }

  bool _isTransactionCompleted(String transactionId) {
    return _completedTransactions.contains(transactionId);
  }

  bool _isTransactionInProgress(String transactionId) {
    return _inProgressTransactions.contains(transactionId);
  }

  void _markTransactionInProgress(String transactionId) {
    _inProgressTransactions.add(transactionId);
  }

  void _markTransactionCompleted(String transactionId) {
    _inProgressTransactions.remove(transactionId);
    _completedTransactions.add(transactionId);
    if (_completedTransactions.length > 50) {
      _completedTransactions.remove(_completedTransactions.first);
    }
  }

  String _generateContentHash(
    Uint8List imageBytes,
    String foodName,
    String userId,
  ) {
    final sampleSize = imageBytes.length > 1000 ? 1000 : imageBytes.length;
    final imageSample = imageBytes.sublist(0, sampleSize);

    final contentToHash = utf8.encode(
      '${base64.encode(imageSample)}_${foodName.toLowerCase()}_$userId',
    );

    final digest = sha256.convert(contentToHash);
    return digest.toString();
  }

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

  Future<Uint8List> _optimizeImage(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();

    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

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

    final optimized = img.encodeJpg(resized, quality: 85);
    return Uint8List.fromList(optimized);
  }

  Future<void> processImage(String imagePath, {BuildContext? context}) async {
    _currentTransactionId = _generateTransactionId();
    final transactionId = _currentTransactionId!;

    if (_isTransactionInProgress(transactionId) ||
        _isTransactionCompleted(transactionId)) {
      debugPrint(
        "Transaction $transactionId already in progress or completed, skipping",
      );
      return;
    }

    _markTransactionInProgress(transactionId);

    _loading = true;
    _error = null;

    String languageCode = context?.locale.languageCode ?? 'id';
    print("Language code nya: $languageCode");

    _loadingMessage = 'scan_loading.processing'.tr();
    _lastContext = context;
    notifyListeners();

    try {
      _loadingMessage = 'scan_loading.optimizing'.tr();
      notifyListeners();
      final optimizedBytes = await _optimizeImage(imagePath);

      _loadingMessage = 'scan_loading.identifying'.tr();
      notifyListeners();

      final prompt = _buildPrompt(languageCode);

      final res = await _aiService.imageToDishcovery(
        imageBytes: optimizedBytes,
        prompt: prompt,
        languageCode: languageCode,
      );

      final ScanResult parsed;
      try {
        final user = _firestoreService.currentUser;
        final userId = user?.uid ?? 'anonymous';
        final contentHash = _generateContentHash(
          optimizedBytes,
          res['name'] ?? '',
          userId,
        );

        parsed = ScanResult.fromJson(res).copyWith(
          imagePath: imagePath,
          transactionId: transactionId,
          contentHash: contentHash,
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

      if (parsed.name.toLowerCase() != "bukan makanan" &&
          parsed.name.toLowerCase() != "not food" &&
          parsed.isFood) {
        if (_isSaving) {
          debugPrint("Save already in progress, skipping duplicate save");
          return;
        }
        _isSaving = true;

        _loadingMessage = 'scan_loading.saving'.tr();
        notifyListeners();

        try {
          final user = _firestoreService.currentUser;
          if (user != null && parsed.contentHash != null) {
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

          final firestoreId = await _firestoreService.saveScanResult(parsed);

          if (firestoreId != null) {
            final updatedResult = parsed.copyWith(firestoreId: firestoreId);
            _result = updatedResult;

            if (_lastContext != null && _lastContext!.mounted) {
              final historyProvider = Provider.of<HistoryProvider>(
                _lastContext!,
                listen: false,
              );
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

      _markTransactionCompleted(transactionId);
    } catch (e, stackTrace) {
      debugPrint("Error processing image: ${e.toString()}");
      debugPrint("Stack trace: $stackTrace");
      _error = 'scan_loading.error'.tr(args: [e.toString()]);
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> processImageWithStream(
    String imagePath, {
    BuildContext? context,
  }) async {
    _currentTransactionId = _generateTransactionId();
    final transactionId = _currentTransactionId!;

    if (_isTransactionInProgress(transactionId) ||
        _isTransactionCompleted(transactionId)) {
      debugPrint(
        "Transaction $transactionId already in progress or completed, skipping",
      );
      return;
    }

    _markTransactionInProgress(transactionId);

    _loading = true;
    _error = null;

    String languageCode = context?.locale.languageCode ?? 'id';

    _loadingMessage = 'scan_loading.processing'.tr();
    _lastContext = context;
    notifyListeners();

    try {
      _loadingMessage = 'scan_loading.optimizing'.tr();
      notifyListeners();
      final optimizedBytes = await _optimizeImage(imagePath);

      _loadingMessage = 'scan_loading.identifying'.tr();
      notifyListeners();

      final prompt = _buildPrompt(languageCode);

      final stream = _aiService.imageToDishcoveryStream(
        imageBytes: optimizedBytes,
        prompt: prompt,
        languageCode: languageCode,
      );

      bool firstUpdate = true;
      String? contentHash;
      await for (final res in stream) {
        try {
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
            transactionId: transactionId,
            contentHash:
                contentHash,
          );
          _result = parsed;

          if (firstUpdate) {
            _loading = false;
            firstUpdate = false;
          }

          if (parsed.name.isNotEmpty && parsed.description.isEmpty) {
            _loadingMessage = 'scan_loading.loading_details'.tr();
          } else if (parsed.description.isNotEmpty &&
              parsed.recipe.ingredients.isEmpty) {
            _loadingMessage = 'scan_loading.loading_recipe'.tr();
          }

          notifyListeners();
        } catch (e) {
          continue;
        }
      }

      final result = _result;
      if (result != null &&
          result.name.toLowerCase() != "bukan makanan" &&
          result.name.toLowerCase() != "not food" &&
          result.isFood) {
        if (_isSaving) {
          debugPrint("Save already in progress, skipping duplicate save");
          return;
        }
        _isSaving = true;

        _loadingMessage = 'scan_loading.saving'.tr();
        notifyListeners();

        try {
          final user = _firestoreService.currentUser;
          if (user != null && result.contentHash != null) {
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

          final firestoreId = await _firestoreService.saveScanResult(result);

          if (firestoreId != null) {
            final updatedResult = result.copyWith(firestoreId: firestoreId);
            _result = updatedResult;

            if (_lastContext != null && _lastContext!.mounted) {
              final historyProvider = Provider.of<HistoryProvider>(
                _lastContext!,
                listen: false,
              );
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

      _markTransactionCompleted(transactionId);
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
