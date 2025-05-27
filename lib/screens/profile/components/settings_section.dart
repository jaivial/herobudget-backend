import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/language_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/extensions.dart';
import '../../../widgets/language_selector_widget.dart';

class SettingsSection extends StatelessWidget {
  final UserModel? user;
  final ThemeMode currentThemeMode;
  final VoidCallback onUserUpdated;

  const SettingsSection({
    super.key,
    required this.user,
    required this.currentThemeMode,
    required this.onUserUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.translate('settings'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Language configuration
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(context.tr.translate('language')),
              subtitle: Text(_getLanguageName(user?.locale ?? 'en')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageSelector(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const Divider(),

            // Theme configuration
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: Text(context.tr.translate('theme')),
              subtitle: Text(_getThemeName(currentThemeMode, context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeSelector(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const Divider(),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String languageCode) {
    final supportedLanguages = LanguageService.getSupportedLanguagesList();
    for (final language in supportedLanguages) {
      if (language['code'] == languageCode) {
        final fullName = language['name'] ?? languageCode;
        if (fullName.contains('(')) {
          final match = RegExp(r'\((.*?)\)').firstMatch(fullName);
          if (match != null && match.groupCount >= 1) {
            return match.group(1)!;
          }
        }
        return fullName;
      }
    }
    return languageCode;
  }

  String _getThemeName(ThemeMode mode, BuildContext context) {
    switch (mode) {
      case ThemeMode.system:
        return context.tr.translate('theme_system');
      case ThemeMode.light:
        return context.tr.translate('theme_light');
      case ThemeMode.dark:
        return context.tr.translate('theme_dark');
      default:
        return context.tr.translate('theme_system');
    }
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: LanguageSelectorWidget(
            showCloseButton: true,
            onLocaleSelected: (locale) async {
              await LanguageService.saveLanguagePreference(locale);
              languageNotifier.notifyLanguageChanged(locale);
              Navigator.pop(context);
              onUserUpdated();
            },
          ),
        );
      },
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.translate('select_theme'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.brightness_auto),
                title: Text(context.tr.translate('theme_system')),
                onTap: () => _changeTheme(ThemeMode.system, context),
                selected: currentThemeMode == ThemeMode.system,
              ),
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: Text(context.tr.translate('theme_light')),
                onTap: () => _changeTheme(ThemeMode.light, context),
                selected: currentThemeMode == ThemeMode.light,
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: Text(context.tr.translate('theme_dark')),
                onTap: () => _changeTheme(ThemeMode.dark, context),
                selected: currentThemeMode == ThemeMode.dark,
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeTheme(ThemeMode mode, BuildContext context) async {
    await AppTheme.saveThemeMode(mode);
    themeChangeNotifier.notifyThemeChange(mode);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
