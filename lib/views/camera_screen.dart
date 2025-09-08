import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/camera_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().initializeCamera();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraProvider = context.read<CameraProvider>();

    if (state == AppLifecycleState.inactive) {
      // Pause camera saat app tidak aktif untuk mengurangi buffer buildup
      cameraProvider.cameraController?.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      // Resume camera saat app kembali aktif
      if (cameraProvider.isInitialized) {
        cameraProvider.cameraController?.resumePreview();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CameraProvider>(
        builder: (context, cameraProvider, child) {
          debugPrint('hasPermission: ${cameraProvider.hasPermission}');
          debugPrint(
            'isPermanentlyDenied: ${cameraProvider.isPermanentlyDenied}',
          );
          debugPrint('errorMessage: ${cameraProvider.errorMessage}');

          if (!cameraProvider.hasPermission) {
            return _buildPermissionView(cameraProvider);
          }

          if (cameraProvider.errorMessage != null &&
              cameraProvider.hasPermission) {
            return _buildErrorView(cameraProvider);
          }

          if (!cameraProvider.isInitialized || cameraProvider.isLoading) {
            return _buildLoadingView();
          }

          return _buildCameraView(cameraProvider);
        },
      ),
    );
  }

  Widget _buildErrorView(CameraProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Kesalahan Kamera',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                provider.initializeCamera();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionView(CameraProvider provider) {
    final bool isPermanentlyDenied = provider.isPermanentlyDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              isPermanentlyDenied ? Icons.settings : Icons.camera_alt_outlined,
              size: 64,
              color: isPermanentlyDenied ? Colors.orange : Colors.white70,
            ),
            const SizedBox(height: 16),
            Text(
              isPermanentlyDenied
                  ? 'Izin Kamera Diblokir'
                  : 'Izin Kamera Diperlukan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPermanentlyDenied
                  ? 'Izin kamera telah diblokir secara permanen. Silakan buka pengaturan aplikasi untuk mengizinkan akses kamera secara manual.'
                  : 'Mohon izinkan akses kamera untuk memotret makanan Anda.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      if (isPermanentlyDenied) {
                        await openAppSettings();
                      } else {
                        provider.initializeCamera();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPermanentlyDenied ? Colors.orange : null,
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isPermanentlyDenied ? 'Buka Pengaturan' : 'Beri Izin'),
            ),
            if (isPermanentlyDenied) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Kembali',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Menginisialisasi Kamera...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView(CameraProvider provider) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: Center(child: CameraPreview(provider.cameraController!)),
          ),
        ),

        // Top Controls
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),

              // Flash Toggle
              IconButton(
                onPressed: provider.toggleFlash,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    provider.isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: provider.isFlashOn ? Colors.yellow : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Controls
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 32,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: 64),
              GestureDetector(
                onTap: () async {
                  final imagePath = await provider.takePicture();
                  if (imagePath != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Foto disimpan: $imagePath'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 4),
                  ),
                  child: provider.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 32,
                        ),
                ),
              ),

              // Switch Camera Button
              IconButton(
                onPressed: provider.switchCamera,
                icon: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.cameraswitch, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
