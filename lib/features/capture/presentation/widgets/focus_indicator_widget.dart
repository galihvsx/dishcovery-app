import 'package:flutter/material.dart';

class FocusIndicatorWidget extends StatelessWidget {
  final Offset? focusPoint;
  final Animation<double> focusAnimation;

  const FocusIndicatorWidget({
    super.key,
    required this.focusPoint,
    required this.focusAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (focusPoint == null) return const SizedBox.shrink();

    return Positioned(
      left: focusPoint!.dx - 30,
      top: focusPoint!.dy - 30,
      child: AnimatedBuilder(
        animation: focusAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: focusAnimation.value,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.center_focus_strong,
                color: Colors.white,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}
