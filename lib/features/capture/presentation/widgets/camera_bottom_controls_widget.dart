import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dishcovery_app/providers/camera_provider.dart';

class CameraBottomControlsWidget extends StatelessWidget {
  final CameraProvider provider;
  final Function(String? imagePath) onPictureTaken;

  const CameraBottomControlsWidget({
    super.key,
    required this.provider,
    required this.onPictureTaken,
  });

  @override
  Widget build(BuildContext context) {
    final canSwitchCamera = (provider.cameras?.length ?? 0) > 1;
    final isBusy = provider.isLoading;

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 32,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(width: 64),

          // Capture Button
          GestureDetector(
            onTap: () async {
              final XFile? picture = await provider.takePicture();
              onPictureTaken(picture?.path);
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
                  : const Icon(Icons.camera_alt, color: Colors.black, size: 32),
            ),
          ),

          // Switch camera button
          IconButton(
            onPressed: !canSwitchCamera || isBusy
                ? null
                : () {
                    provider.switchCamera();
                  },
            icon: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (!canSwitchCamera || isBusy)
                    ? Colors.black26
                    : Colors.black54,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.cameraswitch, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
