import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Extension on BuildContext for easy access to AppLocalizations
extension ContextExtensions on BuildContext {
  /// Get the AppLocalizations instance
  AppLocalizations get tr => AppLocalizations.of(this);

  /// Shorthand for MediaQuery.of(this).size
  Size get screenSize => MediaQuery.of(this).size;

  /// Shorthand for Theme.of(this)
  ThemeData get theme => Theme.of(this);

  /// Shorthand for Navigator.of(this)
  NavigatorState get navigator => Navigator.of(this);

  /// Shorthand for ScaffoldMessenger.of(this)
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);

  /// Show a snackbar with the given message
  void showSnackBar(String message, {Duration? duration}) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }
}
