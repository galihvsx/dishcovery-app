import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/app_logo.dart';
import '../../../utils/routes/app_routes.dart';

class AppOnboardingScreen extends StatefulWidget {
  const AppOnboardingScreen({super.key});
  static const String path = '/onboarding';

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen> {
  final _introKey = GlobalKey<IntroductionScreenState>();

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntroductionScreen(
      key: _introKey,
      globalBackgroundColor: colorScheme.surface,
      pages: [
        PageViewModel(
          title: "Temukan Makanan Indonesia",
          body:
              "Jelajahi ribuan resep makanan Indonesia dengan teknologi AI yang canggih",
          image: _buildImage(
            context,
            imagePath: 'assets/images/onboarding_1.png',
          ),
          decoration: _getPageDecoration(theme),
        ),
        PageViewModel(
          title: "Rekomendasi Personal",
          body:
              "Dapatkan rekomendasi makanan yang sesuai dengan selera dan preferensi Anda",
          image: _buildImage(
            context,
            imagePath: 'assets/images/onboarding_2.png',
          ),
          decoration: _getPageDecoration(theme),
        ),
        PageViewModel(
          title: "Kenali Makanan dengan AI",
          body:
              "Cukup foto makanan, AI kami akan memberitahu nama, resep, dan informasi nutrisinya",
          image: _buildImage(
            context,
            imagePath: 'assets/images/onboarding_3.png',
          ),
          decoration: _getPageDecoration(theme),
        ),
      ],
      onDone: _completeOnboarding,
      onSkip: _completeOnboarding,
      showSkipButton: true,
      skip: Text(
        'Lewati',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
      next: Icon(Icons.arrow_forward, color: colorScheme.primary),
      done: Text(
        'Mulai',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: colorScheme.primary,
        color: colorScheme.outlineVariant,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, {required String imagePath}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        const AppLogo(size: 80),
        const SizedBox(height: 40),
        Image.asset(imagePath, height: 300, fit: BoxFit.contain),
      ],
    );
  }

  PageDecoration _getPageDecoration(ThemeData theme) {
    return PageDecoration(
      titleTextStyle: theme.textTheme.headlineMedium!.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      bodyTextStyle: theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      pageColor: theme.colorScheme.surface,
      imagePadding: const EdgeInsets.only(top: 40),
    );
  }
}
