import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraProvider extends ChangeNotifier {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  CameraDescription? _activeCamera;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _isPermanentlyDenied = false;
  bool _isFlashOn = false;
  String? _errorMessage;

  CameraController? get cameraController => _cameraController;
  List<CameraDescription>? get cameras => _cameras;
  CameraDescription? get activeCamera => _activeCamera;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  bool get isPermanentlyDenied => _isPermanentlyDenied;
  bool get isFlashOn => _isFlashOn;
  String? get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void setPermissionState({
    required bool hasPermission,
    required bool isPermanentlyDenied,
  }) {
    _hasPermission = hasPermission;
    _isPermanentlyDenied = isPermanentlyDenied;
    notifyListeners();
  }

  Future<void> initializeCamera({int retryCount = 0}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final permissionStatus = await Permission.camera.status;

      if (permissionStatus.isPermanentlyDenied) {
        _hasPermission = false;
        _isPermanentlyDenied = true;
        _isLoading = false;
        _errorMessage = 'Izin kamera diperlukan untuk menggunakan fitur ini.';
        notifyListeners();
        return;
      }

      if (!permissionStatus.isGranted) {
        final result = await Permission.camera.request();

        if (result.isPermanentlyDenied) {
          _hasPermission = false;
          _isPermanentlyDenied = true;
          _isLoading = false;
          notifyListeners();
          return;
        }

        if (!result.isGranted) {
          _hasPermission = false;
          _isLoading = false;
          _errorMessage = 'Izin kamera diperlukan untuk menggunakan fitur ini.';
          notifyListeners();
          return;
        }
      }

      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _isLoading = false;
        _errorMessage = 'Tidak ada kamera yang tersedia di perangkat ini.';
        notifyListeners();
        return;
      }

      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      await _setupCameraController(backCamera);

      _hasPermission = true;
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing camera: $e');

      String friendlyMessage = 'Gagal menginisialisasi kamera.';

      if (e.toString().contains('CameraException')) {
        if (e.toString().contains('permission')) {
          friendlyMessage = 'Izin kamera tidak diberikan.';
        } else if (e.toString().contains('not available')) {
          friendlyMessage = 'Kamera sedang digunakan aplikasi lain.';
        }
      }

      if (e.toString().contains('already in use') && retryCount < 3) {
        await Future.delayed(const Duration(seconds: 1));
        await initializeCamera(retryCount: retryCount + 1);
        return;
      }

      _isLoading = false;
      _errorMessage = friendlyMessage;
      notifyListeners();
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();
    _activeCamera = camera;

    await _cameraController!.setFlashMode(FlashMode.off);
    _isFlashOn = false;
  }

  Future<void> toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newFlashMode);

      _isFlashOn = !_isFlashOn;
      notifyListeners();
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<XFile?> takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _errorMessage = 'Kamera belum siap';
      notifyListeners();
      return null;
    }

    try {
      _isLoading = true;
      notifyListeners();

      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      }

      final XFile picture = await _cameraController!.takePicture();

      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }

      _isLoading = false;
      notifyListeners();

      return picture;
    } catch (e) {
      print('Error taking picture: $e');

      String friendlyMessage = 'Gagal mengambil gambar.';
      if (e.toString().contains('CameraException')) {
        friendlyMessage = 'Terjadi kesalahan pada kamera. Silakan coba lagi.';
      }

      _errorMessage = friendlyMessage;
      _isLoading = false;
      notifyListeners();

      return null;
    }
  }

  Future<XFile?> pickFromGallery() async {
    try {
      _isLoading = true;
      notifyListeners();

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      _isLoading = false;
      notifyListeners();

      return image;
    } catch (e) {
      print('Error picking image: $e');

      _errorMessage = 'Gagal memilih gambar dari galeri.';
      _isLoading = false;
      notifyListeners();

      return null;
    }
  }

  Future<void> disposeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }
    _activeCamera = null;
    _isInitialized = false;
  }

  Future<void> resetCamera() async {
    await disposeCamera();
    await initializeCamera();
  }

  Future<void> switchCamera() async {
    if (!_isInitialized || _cameras == null || _cameras!.length < 2) {
      return;
    }

    final currentIndex = _cameras!.indexWhere(
      (camera) => camera == _activeCamera,
    );
    final nextIndex =
        currentIndex >= 0 ? (currentIndex + 1) % _cameras!.length : 0;
    final nextCamera = _cameras![nextIndex];

    try {
      _isLoading = true;
      notifyListeners();

      await _setupCameraController(nextCamera);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error switching camera: $e');
      _errorMessage = 'Gagal mengganti kamera.';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disposeCamera();
    super.dispose();
  }
}
