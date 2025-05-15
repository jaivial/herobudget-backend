import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/dashboard_service.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import '../services/app_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';
import '../main.dart';
import 'language_selector_widget.dart';
import 'language_selector_button.dart';
import 'dart:convert';

class AppHeader extends StatefulWidget {
  final UserModel? user;
  final Function(String)? onLanguageChanged;

  const AppHeader({super.key, this.user, this.onLanguageChanged});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  String currentLocale = 'es';
  ThemeMode currentThemeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadPreferredLanguage();
    _loadThemeMode();

    // Escuchar cambios de idioma desde otros lugares de la app
    languageNotifier.addListener(_updateLocale);
  }

  @override
  void dispose() {
    languageNotifier.removeListener(_updateLocale);
    super.dispose();
  }

  // Método para actualizar el idioma cuando cambie en otro lugar
  void _updateLocale() {
    setState(() {
      currentLocale = languageNotifier.lastLanguage;
    });
  }

  Future<void> _loadPreferredLanguage() async {
    final locale = await LanguageService.getLanguagePreference();
    setState(() {
      currentLocale = locale ?? 'es';
    });
  }

  Future<void> _loadThemeMode() async {
    final mode = await AppTheme.getThemeMode();
    setState(() {
      currentThemeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sección izquierda - Toggle de tema
          ThemeToggleButton(
            currentThemeMode: currentThemeMode,
            onThemeModeChanged: (ThemeMode mode) {
              setState(() {
                currentThemeMode = mode;
              });
              themeChangeNotifier.notifyThemeChange(mode);
            },
          ),

          // Sección central - Logo de la aplicación
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/herobudgeticon.png',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Sección derecha - Selector de idioma
          const LanguageSelectorButton(),
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final UserModel? user;

  const UserAvatar({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/profile');
      },
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        backgroundImage: user?.getProfileImage(),
        child:
            user == null
                ? const Icon(Icons.person, color: Colors.white70)
                : null,
      ),
    );
  }
}

class LanguageSelector extends StatefulWidget {
  final String currentLocale;
  final Function(String) onLanguageChanged;

  const LanguageSelector({
    super.key,
    required this.currentLocale,
    required this.onLanguageChanged,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  void _showLanguageSelectorModal(BuildContext context) {
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
            onLocaleSelected: (locale) {
              widget.onLanguageChanged(locale);
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  String _getLanguageFlag(String code) {
    return LanguageService.getLanguageFlag(code);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showLanguageSelectorModal(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.2)
                  : Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          _getLanguageFlag(widget.currentLocale),
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeModeChanged;

  const ThemeToggleButton({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = currentThemeMode == ThemeMode.dark;
    final iconColor = Theme.of(context).colorScheme.primary;
    final backgroundColor =
        isDarkMode
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
            : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1);

    return GestureDetector(
      onTap: () {
        // Alternar entre modos claro y oscuro
        final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
        onThemeModeChanged(newMode);
        _saveThemeMode(newMode);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          isDarkMode ? Icons.light_mode : Icons.dark_mode,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    await AppTheme.saveThemeMode(mode);
  }
}
