import 'package:flutter/material.dart';
import '../widgets/language_selector_widget.dart';

class LanguageSelectorScreen extends StatelessWidget {
  const LanguageSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LanguageSelectorWidget(
      isFullScreen: true,
      showCloseButton: false,
    );
  }
}
