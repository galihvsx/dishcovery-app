import 'package:dishcovery_app/app.dart';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/services/firebase_ai_service.dart';
import 'package:dishcovery_app/core/database/database_helper.dart';
import 'package:dishcovery_app/providers/history_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class ScanProvider extends ChangeNotifier {
  final FirebaseAiService _aiService = FirebaseAiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _loading = false;
  ScanResult? _result;
  String? _error;

  bool get loading => _loading;
  ScanResult? get result => _result;
  String? get error => _error;

  Future<void> processImage(String imagePath) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulasi proses
      await Future.delayed(const Duration(seconds: 2));

      // Kirim gambar ke AI
      final bytes = await _aiService.readImageFile(imagePath);
      final res = await _aiService.imageToDishcovery(
        imageBytes: bytes,
        prompt: """
Kamu adalah AI asisten untuk aplikasi Dishcovery, seorang ahli kuliner Nusantara.
Identifikasi apakah gambar ini adalah makanan atau bukan.
Jika bukan makanan, tulis "bukan makanan" pada field name.
Jika makanan, berikan JSON lengkap berisi:
- name, origin, description, history, recipe (ingredients dan steps), tags, relatedFoods.
Gunakan format Markdown untuk description dan history.
""",
      );

      final parsed = ScanResult.fromJson(res).copyWith(imagePath: imagePath);
      _result = parsed;

      if (parsed.name.toLowerCase() != "bukan makanan") {
        final existing = await _dbHelper.getAllHistory();
        final alreadyExists = existing.any(
          (item) =>
              item.name == parsed.name && item.imagePath == parsed.imagePath,
        );

        if (!alreadyExists) {
          await _dbHelper.insertScanResult(parsed);
        }
      }

      final historyProvider = Provider.of<HistoryProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      await historyProvider.loadHistory();
    } catch (e) {
      _error = e.toString();
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
