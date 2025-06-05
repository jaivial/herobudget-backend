import 'package:flutter/material.dart';
import '../widgets/localized_screen_wrapper.dart';
import '../services/app_service.dart';
import '../main.dart';

/// Extensión para widgets que facilita el uso del wrapper de localización
extension LocalizedScreenExtension on Widget {
  /// Envuelve un widget con el wrapper de localización que incluye
  /// un selector de idioma en el AppBar
  Widget withLanguageSelector({
    PreferredSizeWidget? appBar,
    bool showLanguageSelector = true,
    bool? resizeToAvoidBottomInset,
    Color? backgroundColor,
    Widget? floatingActionButton,
    FloatingActionButtonLocation? floatingActionButtonLocation,
    List<Widget>? persistentFooterButtons,
    Widget? bottomNavigationBar,
    Widget? drawer,
    Widget? endDrawer,
  }) {
    return LocalizedScreenWrapper(
      appBar: appBar,
      showLanguageSelector: showLanguageSelector,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      persistentFooterButtons: persistentFooterButtons,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      child: this,
    );
  }
}

/// Extensión para BuildContext que facilita el cambio de idioma
extension LocaleContextExtension on BuildContext {
  /// Cambia el idioma de la aplicación
  void changeAppLanguage(String locale) {
    AppService.changeAppLocale(this, locale);
  }

  /// Verifica si la app está usando el idioma especificado
  bool isCurrentLocale(String localeCode) {
    final currentLocale = Localizations.localeOf(this);
    final parts = localeCode.split('-');
    if (parts.length == 2) {
      return currentLocale.languageCode == parts[0] &&
          currentLocale.countryCode == parts[1];
    }
    return currentLocale.languageCode == parts[0];
  }
}
