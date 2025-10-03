import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnboardingControls {
  static Widget buildSkipButton(ColorScheme colorScheme) {
    return Text(
      'Lewati',
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
      ),
    );
  }

  static Widget buildNextButton(ColorScheme colorScheme) {
    return Icon(Icons.arrow_forward, color: colorScheme.primary);
  }

  static Widget buildDoneButton(ColorScheme colorScheme) {
    return Text(
      'Mulai',
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
      ),
    );
  }

  static DotsDecorator buildDotsDecorator(ColorScheme colorScheme) {
    return DotsDecorator(
      size: const Size.square(10.0),
      activeSize: const Size(20.0, 10.0),
      activeColor: colorScheme.primary,
      color: colorScheme.outlineVariant,
      spacing: const EdgeInsets.symmetric(horizontal: 3.0),
      activeShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
      ),
    );
  }
}
