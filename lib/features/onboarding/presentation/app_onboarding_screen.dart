import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/routes/app_routes.dart';
import 'widgets/onboarding_controls.dart';
import 'widgets/onboarding_page_data.dart';

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
      pages: OnboardingPageData.getPages(context, theme),
      onDone: _completeOnboarding,
      onSkip: _completeOnboarding,
      showSkipButton: true,
      skip: OnboardingControls.buildSkipButton(colorScheme),
      next: OnboardingControls.buildNextButton(colorScheme),
      done: OnboardingControls.buildDoneButton(colorScheme),
      dotsDecorator: OnboardingControls.buildDotsDecorator(colorScheme),
    );
  }
}
