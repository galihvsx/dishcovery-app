import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/theme_switcher.dart';
import '../widgets/setting_profile_card.dart';
import '../widgets/setting_theme_card.dart';
import '../widgets/setting_language_card.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // String selectedLanguage = 'ID';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings', actions: [ThemeSwitcher()]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Card
            const SettingProfileCard(),

            const SizedBox(height: 24),

            // Theme Settings
            const SettingThemeCard(),

            const SizedBox(height: 24),

            // Language Settings
            const SettingLanguageCard(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
