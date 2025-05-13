import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/dashboard_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPreferredLanguage();
  }

  Future<void> _loadPreferredLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentLocale = prefs.getString('locale') ?? 'es';
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
          // Sección izquierda - Avatar del usuario
          UserAvatar(user: widget.user),

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
          LanguageSelector(
            currentLocale: currentLocale,
            onLanguageChanged: (locale) {
              setState(() {
                currentLocale = locale;
              });
              if (widget.onLanguageChanged != null) {
                widget.onLanguageChanged!(locale);
              }
            },
          ),
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
        backgroundImage: _getProfileImage(user),
        child:
            user == null
                ? const Icon(Icons.person, color: Colors.white70)
                : null,
      ),
    );
  }

  ImageProvider? _getProfileImage(UserModel? user) {
    if (user == null) {
      return null;
    }

    // Si hay una imagen de perfil disponible en displayImage
    if (user.displayImage != null && user.displayImage!.isNotEmpty) {
      // Si es usuario de Google, displayImage es una URL
      if (user.googleId != null && user.googleId!.isNotEmpty) {
        return NetworkImage(user.displayImage!);
      }
      // Si es usuario regular, displayImage es base64
      try {
        return MemoryImage(base64Decode(user.displayImage!));
      } catch (e) {
        print('Error decoding profile image: $e');
      }
    }

    // Fallback a la imagen de assets
    return const AssetImage('assets/avatars/default_avatar.png');
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
  final List<Map<String, dynamic>> _languages = [
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
  ];

  String get _currentLanguageFlag {
    final language = _languages.firstWhere(
      (lang) => lang['code'] == widget.currentLocale,
      orElse: () => _languages.first,
    );
    return language['flag'];
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Selecciona un idioma',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ..._languages.map((language) {
                return ListTile(
                  leading: Text(
                    language['flag'],
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(language['name']),
                  trailing:
                      widget.currentLocale == language['code']
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                  onTap: () {
                    widget.onLanguageChanged(language['code']);
                    _savePreferredLanguage(language['code']);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _savePreferredLanguage(String locale) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLanguageSelector(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Text(_currentLanguageFlag, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
