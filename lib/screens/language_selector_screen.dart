import 'package:flutter/material.dart';
import '../widgets/language_selector_widget.dart';
import '../utils/app_localizations.dart';

class LanguageSelectorScreen extends StatelessWidget {
  const LanguageSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example of using the new localization system
    final translate = AppLocalizations.of(context).translate;

    return Scaffold(
      appBar: AppBar(title: Text(translate('select_language'))),
      body: const LanguageSelectorWidget(
        isFullScreen: true,
        showCloseButton: false,
      ),
    );
  }
}
