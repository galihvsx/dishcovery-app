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

    try {
      final bytes = await _aiService.readImageFile(imagePath);
      final res = await _aiService.imageToDishcovery(
        imageBytes: bytes,
        prompt: """
Kamu adalah AI asisten untuk aplikasi Dishcovery.
Identifikasi makanan tradisional Nusantara pada gambar ini.
Kembalikan JSON sesuai schema: name, origin, description, tags[], relatedFoods[].
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
