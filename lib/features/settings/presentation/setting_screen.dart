import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../widgets/settings_menu_item.dart';
import '../widgets/settings_profile_header.dart';
import '../widgets/settings_section_header.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  static const String path = '/settings';

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String get _currentLanguage {
    final currentLocale = context.locale.languageCode;
    return currentLocale == 'id' ? 'Bahasa Indonesia' : 'English';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'settings'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('notifications_coming_soon'.tr())),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            const SettingsProfileHeader(),

            // Account Section
            SettingsSectionHeader(title: 'account'.tr()),
            SettingsMenuItem(
              icon: Icons.person_outline,
              title: 'personal_information'.tr(),
              subtitle: 'manage_account_details'.tr(),
              onTap: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
            ),
            SettingsMenuItem(
              icon: Icons.restaurant_menu,
              title: 'food_preferences'.tr(),
              subtitle: 'set_taste_allergies'.tr(),
              onTap: () {
                Navigator.pushNamed(context, '/preferences');
              },
            ),

            // Appearance Section
            SettingsSectionHeader(title: 'appearance'.tr()),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                final isDark = themeProvider.themeMode == ThemeMode.dark;
                return SettingsMenuItem(
                  icon: Icons.palette_outlined,
                  title: 'theme'.tr(),
                  subtitle: isDark ? 'dark'.tr() : 'light'.tr(),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) {
                      themeProvider.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () {
                    themeProvider.setThemeMode(
                      isDark ? ThemeMode.light : ThemeMode.dark,
                    );
                  },
                );
              },
            ),
            SettingsMenuItem(
              icon: Icons.language_outlined,
              title: 'language'.tr(),
              subtitle: _currentLanguage,
              onTap: () {
                _showLanguageDialog();
              },
            ),

            // General Section
            SettingsSectionHeader(title: 'general'.tr()),
            SettingsMenuItem(
              icon: Icons.notifications_outlined,
              title: 'notifications'.tr(),
              subtitle: 'manage_notification_settings'.tr(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('notifications_settings_coming_soon'.tr()),
                  ),
                );
              },
            ),
            SettingsMenuItem(
              icon: Icons.security_outlined,
              title: 'security'.tr(),
              subtitle: 'privacy_security_settings'.tr(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('security_settings_coming_soon'.tr())),
                );
              },
            ),
            SettingsMenuItem(
              icon: Icons.help_outline,
              title: 'help_center'.tr(),
              subtitle: 'get_help_support'.tr(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('help_center_coming_soon'.tr())),
                );
              },
            ),

            // Sign Out
            SettingsSectionHeader(title: 'account_actions'.tr()),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return SettingsMenuItem(
                  icon: Icons.logout,
                  title: 'logout'.tr(),
                  subtitle: 'sign_out_subtitle'.tr(),
                  iconColor: Theme.of(context).colorScheme.error,
                  textColor: Theme.of(context).colorScheme.error,
                  showDivider: false,
                  onTap: authProvider.isLoading
                      ? null
                      : () async {
                          _showSignOutDialog(authProvider);
                        },
                );
              },
            ),

            const SizedBox(height: 32),

            // Version Info
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Dishcovery v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.4 * 255).round()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final currentLanguage = _currentLanguage;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇮🇩'),
              title: const Text('Bahasa Indonesia'),
              trailing: currentLanguage == 'Bahasa Indonesia'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                if (currentLanguage != 'Bahasa Indonesia' && mounted) {
                  await context.setLocale(const Locale('id'));
                  if (mounted) {
                    navigator.pop(); // Use stored navigator
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('language_changed_to_indonesian'.tr()),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    setState(() {}); // Refresh UI
                  }
                }
              },
            ),
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English'),
              trailing: currentLanguage == 'English'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                if (currentLanguage != 'English' && mounted) {
                  await context.setLocale(const Locale('en'));
                  if (mounted) {
                    navigator.pop(); // Use stored navigator
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('language_changed_to_english'.tr()),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    setState(() {}); // Refresh UI
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('confirm_sign_out'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      await authProvider.signOut();

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('signed_out_successfully'.tr())),
      );

      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
