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
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
      ),
      fontFamily: 'Montserrat',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: primaryColor,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  static ThemeData get darkTheme {
    // Definir colores de alto contraste para el tema oscuro
    const Color primaryColorHC = Color(0xFF9C27B0); // Púrpura más brillante
    const Color primaryContainerHC = Color(
      0xFF6A1B9A,
    ); // Púrpura profundo pero visible
    const Color surfaceColorHC = Color(
      0xFF1E1E1E,
    ); // Superficie oscura pero no negra
    const Color backgroundColor = Color(0xFF121212); // Fondo casi negro
    const Color textColorHC =
        Colors.white; // Texto blanco puro para máximo contraste

    return ThemeData(
      primarySwatch: Colors.purple,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColorHC,
        secondary: secondaryColorDark,
        tertiary: tertiaryColorDark,
        background: backgroundColor,
        surface: surfaceColorHC,
        // Colores de contenedor primario con alto contraste
        primaryContainer: primaryContainerHC,
        onPrimaryContainer: textColorHC,
        // Asegurar que los textos en todas las superficies tengan alto contraste
        onSurface: textColorHC,
        onBackground: textColorHC,
        onPrimary: textColorHC,
        onSecondary: textColorHC,
      ),
      // Colores base
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColorHC,
      canvasColor: backgroundColor,
      dialogBackgroundColor: surfaceColorHC,
      fontFamily: 'Montserrat',

      // Tema de texto con alta visibilidad
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textColorHC),
        bodyMedium: TextStyle(color: textColorHC),
        titleLarge: TextStyle(color: textColorHC, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textColorHC, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textColorHC),
        labelLarge: TextStyle(color: textColorHC),
        labelMedium: TextStyle(color: textColorHC),
        labelSmall: TextStyle(color: textColorHC),
      ),

      // Asegurar que los controles tengan suficiente contraste
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColorHC,
          foregroundColor: textColorHC,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: primaryColorHC, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: primaryColorHC,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColorHC),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColorHC,
        foregroundColor: textColorHC,
        elevation: 0,
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceColorHC,
        contentTextStyle: TextStyle(color: textColorHC),
      ),

      // Asegurar que las entradas tengan buen contraste
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColorHC,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColorHC, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        // Colores de texto para inputs
        hintStyle: TextStyle(color: textColorHC.withOpacity(0.6)),
        labelStyle: const TextStyle(color: primaryColorHC),
      ),

      // Asegurar que los iconos sean visibles
      iconTheme: const IconThemeData(color: textColorHC, size: 24),
      primaryIconTheme: const IconThemeData(color: textColorHC, size: 24),
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
