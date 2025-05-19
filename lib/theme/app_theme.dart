import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AppTheme {
  static const Color primaryColor = Color(0xFF6A1B9A);
  static const Color secondaryColor = Color(0xFF9C27B0);
  static const Color tertiaryColor = Color(0xFFBA68C8);
  static const Color backgroundLight = Color(0xFFF3E5F5);

  // Colores para tema oscuro
  static const Color primaryColorDark = Color(0xFF9C27B0);
  static const Color secondaryColorDark = Color(0xFFBA68C8);
  static const Color tertiaryColorDark = Color(0xFFD1C4E9);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Clave para almacenar el modo de tema en SharedPreferences
  static const String themePreferenceKey = 'theme_mode';

  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.purple,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      cardColor: Colors.white,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.purple,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      cardColor: const Color(0xFF1E1E1E),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Métodos para guardar y obtener el modo de tema
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themePreferenceKey, mode.index);
  }

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(themePreferenceKey);
    return index != null ? ThemeMode.values[index] : ThemeMode.light;
  }
}

// Clase para notificar cambios de tema
class ThemeChangeNotifier {
  static final ThemeChangeNotifier _instance = ThemeChangeNotifier._internal();

  factory ThemeChangeNotifier() {
    return _instance;
  }

  ThemeChangeNotifier._internal();

  final _themeChangeController = StreamController<ThemeMode>.broadcast();

  Stream<ThemeMode> get themeChangeStream => _themeChangeController.stream;

  void notifyThemeChange(ThemeMode mode) {
    _themeChangeController.add(mode);
  }

  void dispose() {
    _themeChangeController.close();
  }
}

// Instancia global para ser usada en toda la app
final themeChangeNotifier = ThemeChangeNotifier();
