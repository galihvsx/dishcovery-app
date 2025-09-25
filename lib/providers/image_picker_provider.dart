import 'dart:io';
import 'package:flutter/foundation.dart';
import '../features/capture/services/image_picker_service.dart';

class ImagePickerProvider extends ChangeNotifier {
  final ImagePickerService _imagePickerService = ImagePickerService();

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  Future<void> pickImageFromGallery() async {
    final image = await _imagePickerService.pickFromGallery();
    if (image != null) {
      _selectedImage = image;
      notifyListeners();
    }
  }

  void clearImage() {
    _selectedImage = null;
    notifyListeners();
  }
}
