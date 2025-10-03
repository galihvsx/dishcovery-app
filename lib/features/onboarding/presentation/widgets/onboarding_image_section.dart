import 'package:flutter/material.dart';

import '../../../../core/widgets/app_logo.dart';

class OnboardingImageSection extends StatelessWidget {
  final String imagePath;

  const OnboardingImageSection({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Flexible(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: isSmallScreen ? 20 : 40),
          AppLogo(size: isSmallScreen ? 60 : 80),
          SizedBox(height: isSmallScreen ? 20 : 30),
          Flexible(
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
