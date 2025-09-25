import 'package:dishcovery_app/features/capture/presentation/preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../providers/camera_provider.dart';
import 'widgets/camera_bottom_controls_widget.dart';
import 'widgets/camera_error_widget.dart';
import 'widgets/camera_permission_widget.dart';
import 'widgets/camera_preview_widget.dart';
import 'widgets/camera_top_controls_widget.dart';
import 'widgets/focus_indicator_widget.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraProvider? _cameraProvider;
  Offset? _focusPoint;
  late AnimationController _focusAnimationController;
  late Animation<double> _focusAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _focusAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusAnimationController.dispose();
    // Pastikan camera controller di-dispose dengan benar saat navigasi keluar
    if (_cameraProvider != null) {
      _cameraProvider!.controller.pausePreview();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraProvider == null) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // Aggressively pause camera saat app tidak aktif
        _cameraProvider!.controller.pausePreview();
        break;
      case AppLifecycleState.resumed:
        // Resume camera saat app kembali aktif dengan delay
        if (_cameraProvider!.isInitialized) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _cameraProvider!.isInitialized) {
              _cameraProvider!.controller.resumePreview();
            }
          });
        }
        break;
      case AppLifecycleState.detached:
        // Dispose kamera saat app ditutup
        _cameraProvider!.controller.pausePreview();
        break;
      case AppLifecycleState.hidden:
        // Pause saat hidden
        _cameraProvider!.controller.pausePreview();
        break;
    }
  }

  void _onTapToFocus(TapDownDetails details, CameraProvider provider) {
    if (!provider.isInitialized) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(
      details.globalPosition,
    );

    // Normalize the tap position to camera coordinates (0.0 to 1.0)
    final double x = localPosition.dx / renderBox.size.width;
    final double y = localPosition.dy / renderBox.size.height;

    // Clamp values to ensure they're within bounds
    final double clampedX = x.clamp(0.0, 1.0);
    final double clampedY = y.clamp(0.0, 1.0);

    final Offset focusPoint = Offset(clampedX, clampedY);

    // Set focus point and show visual feedback
    provider.setFocusPoint(focusPoint);

    setState(() {
      _focusPoint = localPosition;
    });

    // Start focus animation
    _focusAnimationController.reset();
    _focusAnimationController.forward().then((_) {
      // Hide focus indicator after animation completes
      if (mounted) {
        setState(() {
          _focusPoint = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = CameraProvider();
        _cameraProvider = provider;
        // Initialize camera setelah provider dibuat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.initializeCamera();
        });
        return provider;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<CameraProvider>(
          builder: (context, cameraProvider, child) {
            debugPrint('hasPermission: ${cameraProvider.hasPermission}');
            debugPrint(
              'isPermanentlyDenied: ${cameraProvider.isPermanentlyDenied}',
            );
            debugPrint('errorMessage: ${cameraProvider.errorMessage}');

            // Tampilkan loading view jika sedang loading, tanpa mempedulikan permission status
            if (cameraProvider.isLoading) {
              return _buildLoadingView();
            }

            if (!cameraProvider.hasPermission) {
              return _buildPermissionView(cameraProvider);
            }

            if (cameraProvider.errorMessage != null &&
                cameraProvider.hasPermission) {
              return _buildErrorView(cameraProvider);
            }

            if (!cameraProvider.isInitialized) {
              return _buildLoadingView();
            }

            return _buildCameraView(cameraProvider);
          },
        ),
      ),
    );
  }

  Widget _buildErrorView(CameraProvider provider) {
    return CameraErrorWidget(
      errorMessage: provider.errorMessage!,
      onRetry: () {
        provider.clearError();
        provider.initializeCamera();
      },
    );
  }

  Widget _buildPermissionView(CameraProvider provider) {
    final bool isPermanentlyDenied = provider.isPermanentlyDenied;

    return CameraPermissionWidget(
      onRequestPermission: () async {
        if (isPermanentlyDenied) {
          await openAppSettings();
        } else {
          provider.initializeCamera();
        }
      },
    );
  }

  Widget _buildLoadingView() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildCameraView(CameraProvider provider) {
    return Stack(
      children: [
        // Camera Preview with GestureDetector
        CameraPreviewWidget(provider: provider, onTapToFocus: _onTapToFocus),

        // Focus indicator
        if (_focusPoint != null)
          FocusIndicatorWidget(
            focusPoint: _focusPoint!,
            focusAnimation: _focusAnimation,
          ),

        // Top Controls
        CameraTopControlsWidget(
          provider: provider,
          onBackPressed: () => Navigator.of(context).pop(),
        ),

        // Bottom Controls
        CameraBottomControlsWidget(
          provider: provider,
          onPictureTaken: (imagePath) {
            if (imagePath != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PreviewScreen(imagePath: imagePath),
                ),
              );
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text('Foto disimpan: $imagePath'),
              //     backgroundColor: Colors.green,
              //   ),
              // );
            }
          },
        ),
      ],
    );
  }
}
