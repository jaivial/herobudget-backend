import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/language_selector_button.dart';
import '../widgets/localized_screen_wrapper.dart';
import '../utils/app_localizations.dart';

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
    print('Changing app locale to: $locale');

    // Notify the language change so that listening widgets update
    languageChangeNotifier.notifyLanguageChange(locale);

    // Update the application globally using the static function from MyApp
    // This will force a rebuild of the application with the new language
    MyApp.refreshLocale(context, locale);
  }
}
