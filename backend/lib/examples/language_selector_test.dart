import 'package:flutter/material.dart';
import '../widgets/localized_text.dart';
import '../utils/extensions.dart';
import '../utils/screen_wrapper_extension.dart';
import '../widgets/language_selector_button.dart';

/// Pantalla de prueba para demostrar la actualización en tiempo real
/// de traducciones al cambiar el idioma
class LanguageSelectorTestScreen extends StatefulWidget {
  const LanguageSelectorTestScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSelectorTestScreen> createState() =>
      _LanguageSelectorTestScreenState();
}

class _LanguageSelectorTestScreenState
    extends State<LanguageSelectorTestScreen> {
  final _translationKeys = [
    'welcome',
    'sign_in',
    'sign_up',
    'login',
    'email',
    'password',
    'forgot_password',
    'continue',
    'next',
    'back',
    'select_language',
    'dashboard',
    'expenses',
    'income',
    'budget',
    'settings',
  ];

  @override
  Widget build(BuildContext context) {
    // Crear un AppBar con el botón selector de idioma
    final appBar = AppBar(
      title: const LocalizedText('select_language'),
      backgroundColor: Colors.teal,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: Center(child: LanguageSelectorButton()),
        ),
      ],
    );

    return Scaffold(
      appBar: appBar,
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Mostrar idioma actual
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Idioma actual / Current language:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      Localizations.localeOf(context).toString(),
                      style: const TextStyle(fontSize: 24, color: Colors.teal),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Las traducciones se actualizan automáticamente:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            // Lista de traducciones que se actualizarán en tiempo real
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _translationKeys.length,
                itemBuilder: (context, index) {
                  final key = _translationKeys[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(key),
                      subtitle: LocalizedText(
                        key,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
