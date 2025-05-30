import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/language_selector_button.dart';
import '../widgets/localized_screen_wrapper.dart';
import '../utils/extensions.dart';
import '../services/language_service.dart';

/// A service class with static methods to help with common app-wide functionality
class AppService {
  /// Wraps any widget with the language selector in the app bar
  static Widget wrapWithLanguageSelector(
    Widget widget, {
    PreferredSizeWidget? appBar,
    bool showLanguageSelector = true,
  }) {
    return LocalizedScreenWrapper(
      appBar: appBar,
      showLanguageSelector: showLanguageSelector,
      child: widget,
    );
  }

  /// Adds a language selector button to an existing AppBar
  static AppBar addLanguageSelectorToAppBar(
    BuildContext context, {
    String? title,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    Widget? leading,
    bool centerTitle = false,
    Color? backgroundColor,
  }) {
    final List<Widget> updatedActions = [
      ...(actions ?? []),
      const Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: Center(child: LanguageSelectorButton()),
      ),
    ];

    return AppBar(
      title: title != null ? Text(title) : null,
      actions: updatedActions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
    );
  }

  /// Updates the app's locale without restarting
  static void changeAppLocale(BuildContext context, String locale) async {
    print('AppService.changeAppLocale: Changing app locale to: $locale');

    // Usar únicamente el servicio centralizado de idioma para evitar ciclos
    // Esto simplifica el flujo de cambio de idioma
    await LanguageService.saveLanguagePreference(locale);

    // Mostrar la notificación de cambio de idioma
    LanguageService.showLanguageChangeNotification(context, locale);
  }
}
