import 'package:flutter/material.dart';
import '../../widgets/localized_text.dart';
import '../../utils/extensions.dart';
import '../../examples/language_selector_test.dart';
import '../../widgets/language_selector_modal.dart';
import '../../services/language_service.dart';
import '../../utils/locale_util.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentLocale = 'en-US';

  @override
  void initState() {
    super.initState();
    _loadCurrentLocale();
  }

  Future<void> _loadCurrentLocale() async {
    final locale = await LanguageService.getLanguagePreference();
    if (locale != null && mounted) {
      setState(() {
        _currentLocale = locale;
      });
    }
  }

  String _getLocaleName() {
    final languageName =
        LocaleUtil.supportedLanguages[_currentLocale.split('-')[0]] ??
        'Unknown';
    final regionName = LocaleUtil.getRegionName(_currentLocale);
    return '$languageName ($regionName)';
  }

  void _showLanguageSelector() async {
    final selectedLocale = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return const LanguageSelectorModal();
      },
    );

    if (selectedLocale != null && mounted) {
      setState(() {
        _currentLocale = selectedLocale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: LocalizedText('settings')),
      body: ListView(
        children: [
          // Cabecera de la sección de configuración
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.settings, size: 40, color: Colors.blue),
                const SizedBox(height: 8),
                LocalizedText(
                  'settings',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Personaliza tu experiencia en la aplicación'),
              ],
            ),
          ),

          const Divider(),

          // Sección de idioma y localización
          ListTile(
            title: const Text(
              'Idioma y Localización',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: const Icon(
              Icons.translate,
              size: 30,
              color: Colors.indigo,
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Opción para cambiar el idioma
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blue),
                  title: LocalizedText('language'),
                  subtitle: Text(_getLocaleName()),
                  onTap: _showLanguageSelector,
                ),

                const Divider(),

                // Opción para probar el cambio de idioma en tiempo real
                ListTile(
                  leading: const Icon(Icons.translate, color: Colors.green),
                  title: const Text('Test Language Selector'),
                  subtitle: const Text('Prueba de cambio en tiempo real'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const LanguageSelectorTestScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Sección de tema de la aplicación
          ListTile(
            title: const Text(
              'Apariencia',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.palette, size: 30, color: Colors.purple),
          ),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Opción de tema oscuro (por implementar)
                ListTile(
                  leading: Icon(Icons.dark_mode, color: Colors.grey[800]),
                  title: LocalizedText('dark_mode'),
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      // TODO: Implementar cambio de tema
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Sección de notificaciones
          ListTile(
            title: const Text(
              'Notificaciones',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: const Icon(
              Icons.notifications,
              size: 30,
              color: Colors.orange,
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Opción de notificaciones (por implementar)
                ListTile(
                  leading: const Icon(
                    Icons.notifications_active,
                    color: Colors.orange,
                  ),
                  title: LocalizedText('notification'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // TODO: Implementar control de notificaciones
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Información de la aplicación
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Hero Budget',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('Versión 1.0.0'),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // TODO: Mostrar información sobre la app
                  },
                  child: const Text('Acerca de'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
