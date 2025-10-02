import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/services/firebase_ai_service.dart';
import 'package:flutter/foundation.dart';

class ScanProvider extends ChangeNotifier {
  final FirebaseAiService _aiService = FirebaseAiService();

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

    await Future.delayed(const Duration(seconds: 3));

    try {
      final bytes = await _aiService.readImageFile(imagePath);
      final res = await _aiService.imageToDishcovery(
        imageBytes: bytes,
        prompt: """
Kamu adalah AI asisten untuk aplikasi Dishcovery, seorang ahli kuliner Nusantara.
Identifikasi makanan tradisional Nusantara pada gambar ini secara akurat.
Berikan jawaban dalam format JSON yang sesuai dengan schema yang diberikan.
- Pastikan 'description' dan 'history' ditulis dalam format Markdown untuk Tampilan yang menarik.
- Isi 'name', 'origin', 'description', 'history', dan 'recipe' (ingredients dan steps) dengan lengkap dan informatif.
""",
      );

      _result = ScanResult.fromJson(res);
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
