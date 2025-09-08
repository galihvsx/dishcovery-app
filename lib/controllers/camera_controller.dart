import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/camera_model.dart';

class CameraViewController extends ChangeNotifier {
  CameraController? _cameraController;
  CameraModel _model = const CameraModel();
  List<CameraDescription> _cameras = [];

  CameraModel get model => _model;

  CameraController? get cameraController => _cameraController;

  bool get isInitialized => _model.isInitialized;

  Future<void> initializeCamera() async {
    try {
      _updateModel(_model.copyWith(isLoading: true, errorMessage: null));

      // Check current permission status first
      final permissionStatus = await Permission.camera.status;

      if (permissionStatus.isPermanentlyDenied) {
        _updateModel(
          _model.copyWith(
            isLoading: false,
            hasPermission: false,
            isPermanentlyDenied: true,
            // Don't set error message for permanent denial - let permission view handle it
          ),
        );
        return;
      }

      if (permissionStatus.isDenied) {
        // Try to request permission
        final requestResult = await Permission.camera.request();

        if (requestResult.isPermanentlyDenied) {
          _updateModel(
            _model.copyWith(
              isLoading: false,
              hasPermission: false,
              isPermanentlyDenied: true,
              // Don't set error message for permanent denial - let permission view handle it
            ),
          );
          return;
        }

        if (!requestResult.isGranted) {
          _updateModel(
            _model.copyWith(
              isLoading: false,
              hasPermission: false,
              isPermanentlyDenied: false,
              // Don't set error message for regular denial either - let permission view handle it
            ),
          );
          return;
        }
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _updateModel(
          _model.copyWith(
            isLoading: false,
            hasPermission: true,
            errorMessage: 'Tidak ada kamera tersedia',
          ),
        );
        return;
      }

      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      await _setupCamera(backCamera);

      _updateModel(
        _model.copyWith(
          isLoading: false,
          hasPermission: true,
          isInitialized: true,
          isPermanentlyDenied: false,
          lensDirection: backCamera.lensDirection,
        ),
      );
    } catch (e) {
      _updateModel(
        _model.copyWith(
          isLoading: false,
          errorMessage: 'Gagal menginisialisasi kamera: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    await _cameraController?.dispose();

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
  }

  void toggleFlash() {
    if (!_model.isInitialized || _cameraController == null) return;

    try {
      final newFlashState = !_model.isFlashOn;
      _cameraController!.setFlashMode(
        newFlashState ? FlashMode.torch : FlashMode.off,
      );

      _updateModel(_model.copyWith(isFlashOn: newFlashState));
    } catch (e) {
      _updateModel(
        _model.copyWith(errorMessage: 'Gagal mengubah flash: ${e.toString()}'),
      );
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2 || !_model.isInitialized) return;

    try {
      _updateModel(_model.copyWith(isLoading: true));

      final currentDirection = _model.lensDirection;
      final targetDirection = currentDirection == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      final targetCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == targetDirection,
        orElse: () => _cameras.first,
      );

      await _setupCamera(targetCamera);

      _updateModel(
        _model.copyWith(
          isLoading: false,
          lensDirection: targetCamera.lensDirection,
          isFlashOn: false,
        ),
      );
    } catch (e) {
      _updateModel(
        _model.copyWith(
          isLoading: false,
          errorMessage: 'Gagal mengganti kamera: ${e.toString()}',
        ),
      );
    }
  }

  Future<String?> takePicture() async {
    if (!_model.isInitialized || _cameraController == null) {
      _updateModel(
        _model.copyWith(errorMessage: 'Kamera belum diinisialisasi'),
      );
      return null;
    }

    try {
      _updateModel(_model.copyWith(isLoading: true, errorMessage: null));

      final XFile photo = await _cameraController!.takePicture();

      final String savedPath = await _savePhotoToAppDirectory(photo);

      // Pause preview sebentar untuk mengurangi buffer buildup
      _updateModel(_model.copyWith(isLoading: false, imagePath: savedPath));

      return savedPath;
    } catch (e) {
      _updateModel(
        _model.copyWith(
          isLoading: false,
          errorMessage: 'Gagal mengambil foto: ${e.toString()}',
        ),
      );
      return null;
    }
  }

  Future<String> _savePhotoToAppDirectory(XFile photo) async {
    final directory = await getApplicationDocumentsDirectory();
    final String fileName =
        'dishcovery_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String filePath = '${directory.path}/$fileName';

    final File savedFile = await File(photo.path).copy(filePath);
    return savedFile.path;
  }

  void clearError() {
    if (_model.errorMessage != null) {
      _updateModel(_model.copyWith(errorMessage: null));
    }
  }

  void _updateModel(CameraModel newModel) {
    _model = newModel;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }
}
