import 'package:dishcovery_app/core/navigation/navigation_models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SettingLanguageCard extends StatefulWidget {
  const SettingLanguageCard({super.key});

  @override
  State<SettingLanguageCard> createState() => _SettingLanguageCardState();
}

class _SettingLanguageCardState extends State<SettingLanguageCard> {
  String _selectedLanguage = 'id';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLanguage = context.locale.languageCode;
    if (_selectedLanguage != currentLanguage) {
      _selectedLanguage = currentLanguage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'settings_widgets.language_card.title'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.onSurface,
                  ),
                  style: theme.textTheme.bodyLarge,
                  onChanged: (String? newValue) {
                    if (newValue == null || _selectedLanguage == newValue) {
                      return;
                    }

                    setState(() => _selectedLanguage = newValue);
                    context.setLocale(Locale(newValue));
                    NavigationContext.showSnackBar(
                      'settings_widgets.language_card.snackbar_changed'.tr(
                        args: [newValue.toUpperCase()],
                      ),
                    );
                  },
                  items: [
                    _buildLanguageOption(
                      value: 'id',
                      labelKey: 'settings_widgets.language_card.indonesian',
                      color: Colors.red,
                      code: 'ID',
                    ),
                    _buildLanguageOption(
                      value: 'en',
                      labelKey: 'settings_widgets.language_card.english',
                      color: Colors.blue,
                      code: 'EN',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildLanguageOption({
    required String value,
    required String labelKey,
    required Color color,
    required String code,
  }) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: color,
            ),
            child: Center(
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(labelKey.tr()),
        ],
      ),
    );
  }
}
