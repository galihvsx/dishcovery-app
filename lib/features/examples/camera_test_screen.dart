import 'package:dishcovery_app/features/capture/presentation/capture_screen.dart';
import 'package:flutter/material.dart';

class CameraExampleScreen extends StatelessWidget {
  const CameraExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: CaptureScreen());
  }
}
