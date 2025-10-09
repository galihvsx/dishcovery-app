import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dishcovery_app/providers/camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:dishcovery_app/utils/routes/app_routes.dart';
import 'package:dishcovery_app/features/result/presentation/result_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  static const String path = '/capture';

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  late CameraProvider _cameraProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize camera after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cameraProvider = context.read<CameraProvider>();
      _cameraProvider.initializeCamera();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Dispose camera when leaving the screen
    _cameraProvider.disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _cameraProvider.cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraProvider.disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _cameraProvider.initializeCamera();
    }
  }

  Future<void> _takePicture() async {
    final cameraProvider = context.read<CameraProvider>();

    if (cameraProvider.cameraController == null ||
        !cameraProvider.cameraController!.value.isInitialized) {
      _showSnackBar('capture.camera_not_ready'.tr());
      return;
    }

    if (cameraProvider.isLoading) return;

    final picture = await cameraProvider.takePicture();

    if (picture != null && mounted) {
      // Navigate to result screen
      Navigator.of(context).pushReplacementNamed(
        ResultScreen.path,
        arguments: AppRoutes.createArguments(imagePath: picture.path),
      );
    } else if (cameraProvider.errorMessage != null) {
      _showSnackBar(cameraProvider.errorMessage!);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final cameraProvider = context.read<CameraProvider>();

    if (cameraProvider.isLoading || !cameraProvider.isInitialized) return;

    final image = await cameraProvider.pickFromGallery();

    if (!mounted) return;

    // If user canceled selection, just return without doing anything
    if (image == null) {
      // Reinitialize camera if it was disposed during picker lifecycle
      if (!cameraProvider.isInitialized) {
        await cameraProvider.initializeCamera();
      }
      return;
    }

    // Navigate to result screen with selected image
    Navigator.of(context).pushReplacementNamed(
      ResultScreen.path,
      arguments: AppRoutes.createArguments(imagePath: image.path),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildCameraPreview(CameraProvider provider) {
    if (provider.cameraController == null ||
        !provider.cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final previewSize = provider.cameraController!.value.previewSize!;
    final previewRatio = previewSize.height / previewSize.width;

    return OverflowBox(
      maxHeight: deviceRatio < previewRatio
          ? size.height
          : size.width / previewRatio,
      maxWidth: deviceRatio < previewRatio
          ? size.height * previewRatio
          : size.width,
      child: CameraPreview(provider.cameraController!),
    );
  }

  Widget _buildGamificationOverlay() {
    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(painter: _FoodFramePainter()),
      ),
    );
  }

  Widget _buildErrorState(CameraProvider provider, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.isPermanentlyDenied
                  ? Icons.camera_alt_outlined
                  : Icons.error_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              provider.errorMessage ?? 'capture.error_occurred'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (provider.isPermanentlyDenied)
              FilledButton.icon(
                onPressed: () async {
                  await openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: Text('capture.open_settings'.tr()),
              )
            else if (!provider.hasPermission)
              FilledButton.icon(
                onPressed: () => provider.initializeCamera(),
                icon: const Icon(Icons.camera_alt),
                label: Text('capture.grant_camera_permission'.tr()),
              )
            else
              FilledButton.icon(
                onPressed: () => provider.initializeCamera(),
                icon: const Icon(Icons.refresh),
                label: Text('capture.try_again'.tr()),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CameraProvider>(
        builder: (context, cameraProvider, child) {
          return Stack(
            children: [
              // Camera Preview
              if (cameraProvider.isInitialized)
                _buildCameraPreview(cameraProvider),

              // Gamification Overlay (frame guide)
              if (cameraProvider.isInitialized)
                _buildGamificationOverlay(),

              // Loading State
              if (cameraProvider.isLoading && !cameraProvider.isInitialized)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white)
                    ],
                  ),
                ),

              // Error State
              if (cameraProvider.errorMessage != null &&
                  !cameraProvider.isInitialized)
                _buildErrorState(cameraProvider, theme),

              // Top gradient overlay
              if (cameraProvider.isInitialized)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).padding.top + 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // Bottom gradient overlay
              if (cameraProvider.isInitialized)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).padding.bottom + 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // Top Controls (Back button) - ABOVE gradients
              if (cameraProvider.isInitialized)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      _ControlButton(
                        icon: Icons.close,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

              // Bottom instruction and tips
              if (cameraProvider.isInitialized)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 140,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      // Instruction text
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'capture.instruction'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Lighting tip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.tips_and_updates,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'capture.lighting_tip'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Bottom Controls (Capture Button and Gallery Button) - ABOVE gradients
              if (cameraProvider.isInitialized)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery Button
                      GestureDetector(
                        onTap: cameraProvider.isLoading
                            ? null
                            : _pickImageFromGallery,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.photo_library,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                      ),

                      // Capture Button (Main)
                      GestureDetector(
                        onTap: cameraProvider.isLoading
                            ? null
                            : _takePicture,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.primaryColor,
                              width: 5
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: cameraProvider.isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4,
                                    color: theme.primaryColor,
                                  ),
                                )
                              : Container(
                                  margin: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                      ),

                      // Flash Toggle Button
                      GestureDetector(
                        onTap: cameraProvider.isLoading
                            ? null
                            : () => cameraProvider.toggleFlash(),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: cameraProvider.isFlashOn
                                ? theme.primaryColor.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cameraProvider.isFlashOn
                                  ? theme.primaryColor
                                  : Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            cameraProvider.isFlashOn
                                ? Icons.flash_on
                                : Icons.flash_off,
                            color: cameraProvider.isFlashOn
                                ? Colors.white
                                : Colors.black87,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Custom control button widget
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// Custom painter for food frame overlay
class _FoodFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Draw circular frame
    canvas.drawCircle(center, radius, paint);

    // Draw corner guides
    final cornerLength = 30.0;
    final cornerOffset = radius * 0.7;

    // Top-left corner
    canvas.drawLine(
      Offset(center.dx - cornerOffset - cornerLength, center.dy - cornerOffset),
      Offset(center.dx - cornerOffset, center.dy - cornerOffset),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - cornerOffset, center.dy - cornerOffset - cornerLength),
      Offset(center.dx - cornerOffset, center.dy - cornerOffset),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(center.dx + cornerOffset + cornerLength, center.dy - cornerOffset),
      Offset(center.dx + cornerOffset, center.dy - cornerOffset),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + cornerOffset, center.dy - cornerOffset - cornerLength),
      Offset(center.dx + cornerOffset, center.dy - cornerOffset),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(center.dx - cornerOffset - cornerLength, center.dy + cornerOffset),
      Offset(center.dx - cornerOffset, center.dy + cornerOffset),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - cornerOffset, center.dy + cornerOffset + cornerLength),
      Offset(center.dx - cornerOffset, center.dy + cornerOffset),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(center.dx + cornerOffset + cornerLength, center.dy + cornerOffset),
      Offset(center.dx + cornerOffset, center.dy + cornerOffset),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + cornerOffset, center.dy + cornerOffset + cornerLength),
      Offset(center.dx + cornerOffset, center.dy + cornerOffset),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}