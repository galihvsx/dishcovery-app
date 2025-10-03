import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

import 'onboarding_image_section.dart';

class OnboardingPageData {
  static List<PageViewModel> getPages(BuildContext context, ThemeData theme) {
    return [
      _createPage(
        context: context,
        theme: theme,
        title: "Temukan Makanan Indonesia",
        body: "Jelajahi ribuan resep makanan Indonesia dengan teknologi AI yang canggih",
        imagePath: 'assets/images/onboarding_1.png',
      ),
      _createPage(
        context: context,
        theme: theme,
        title: "Rekomendasi Personal",
        body: "Dapatkan rekomendasi makanan yang sesuai dengan selera dan preferensi Anda",
        imagePath: 'assets/images/onboarding_2.png',
      ),
      _createPage(
        context: context,
        theme: theme,
        title: "Kenali Makanan dengan AI",
        body: "Cukup foto makanan, AI kami akan memberitahu nama, resep, dan informasi nutrisinya",
        imagePath: 'assets/images/onboarding_3.png',
      ),
    ];
  }

  static PageViewModel _createPage({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String body,
    required String imagePath,
  }) {
    return PageViewModel(
      title: title,
      body: body,
      image: OnboardingImageSection(imagePath: imagePath),
      decoration: _getPageDecoration(context, theme),
    );
  }

  static PageDecoration _getPageDecoration(
      BuildContext context, ThemeData theme) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return PageDecoration(
      titleTextStyle: theme.textTheme.headlineMedium!.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        fontSize: isSmallScreen ? 22 : null,
      ),
      bodyTextStyle: theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: isSmallScreen ? 14 : null,
      ),
      bodyPadding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: isSmallScreen ? 8.0 : 16.0,
      ),
      pageColor: theme.colorScheme.surface,
      imagePadding: EdgeInsets.only(top: isSmallScreen ? 20 : 30),
      footerPadding: EdgeInsets.all(isSmallScreen ? 16 : 24),
    );
  }
}
