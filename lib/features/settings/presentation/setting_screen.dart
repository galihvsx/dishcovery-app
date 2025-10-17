import 'package:dishcovery_app/features/settings/widgets/settings_menu_item.dart';
import 'package:dishcovery_app/features/settings/widgets/settings_profile_header.dart';
import 'package:dishcovery_app/features/settings/widgets/settings_section_header.dart';
import 'package:dishcovery_app/providers/auth_provider.dart';
import 'package:dishcovery_app/providers/theme_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  static const String path = '/settings';

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String get _currentLanguage {
    final currentLocale = context.locale.languageCode;
    return currentLocale == 'id' ? 'language.id'.tr() : 'language.en'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'settings.settings'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsProfileHeader(),

            SettingsSectionHeader(title: 'settings.account'.tr()),
            SettingsMenuItem(
              icon: Icons.person_outline,
              title: 'settings.personal_information'.tr(),
              subtitle: 'settings.manage_account_details'.tr(),
              onTap: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
            ),
            SettingsMenuItem(
              icon: Icons.restaurant_menu,
              title: 'settings.food_preferences'.tr(),
              subtitle: 'settings.set_taste_allergies'.tr(),
              onTap: () {
                Navigator.pushNamed(context, '/preferences');
              },
            ),

            SettingsSectionHeader(title: 'settings.appearance'.tr()),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                final isDark = themeProvider.isDarkMode(context);
                final isSystemMode =
                    themeProvider.themeMode == ThemeMode.system;

                return SettingsMenuItem(
                  icon: Icons.palette_outlined,
                  title: 'theme.theme'.tr(),
                  subtitle: isSystemMode
                      ? '${isDark ? 'theme.dark'.tr() : 'theme.light'.tr()} (${'theme.system'.tr()})'
                      : (isDark ? 'theme.dark'.tr() : 'theme.light'.tr()),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) {
                      themeProvider.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
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
              title: 'language.language'.tr(),
              subtitle: _currentLanguage,
              onTap: () {
                _showLanguageDialog();
              },
            ),

            SettingsSectionHeader(title: 'settings.general'.tr()),
            SettingsMenuItem(
              icon: Icons.notifications_outlined,
              title: 'settings.notifications'.tr(),
              subtitle: 'settings.manage_notification_settings'.tr(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'notifications.notifications_settings_coming_soon'.tr(),
                    ),
                  ),
                );
              },
            ),
            SettingsMenuItem(
              icon: Icons.security_outlined,
              title: 'settings.security'.tr(),
              subtitle: 'settings.privacy_security_settings'.tr(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'notifications.security_settings_coming_soon'.tr(),
                    ),
                  ),
                );
              },
            ),
            SettingsMenuItem(
              icon: Icons.help_outline,
              title: 'settings.help_center'.tr(),
              subtitle: 'settings.get_help_support'.tr(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('notifications.help_center_coming_soon'.tr()),
                  ),
                );
              },
            ),

            SettingsSectionHeader(title: 'settings.account_actions'.tr()),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return SettingsMenuItem(
                  icon: Icons.logout,
                  title: 'auth.logout'.tr(),
                  subtitle: 'settings.sign_out_subtitle'.tr(),
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

            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'app.version'.tr(),
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
        title: Text('language.language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇮🇩'),
              title: Text('language.id'.tr()),
              trailing: currentLanguage == 'language.id'.tr()
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                if (currentLanguage != 'language.id'.tr() && mounted) {
                  await context.setLocale(const Locale('id'));
                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'notifications.language_changed_to_indonesian'.tr(),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    setState(() {});
                  }
                }
              },
            ),
            ListTile(
              leading: const Text('🇺🇸'),
              title: Text('language.en'.tr()),
              trailing: currentLanguage == 'language.en'.tr()
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                if (currentLanguage != 'language.en'.tr() && mounted) {
                  await context.setLocale(const Locale('en'));
                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'notifications.language_changed_to_english'.tr(),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    setState(() {});
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('auth.logout'.tr()),
        content: Text('auth.confirm_sign_out'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
            child: Text('auth.logout'.tr()),
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
