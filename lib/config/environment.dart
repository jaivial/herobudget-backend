import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.development;

  // Configurar el ambiente actual
  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
  }

  // Obtener ambiente actual
  static Environment get currentEnvironment {
    // Auto-detectar basado en el modo de compilación
    if (kReleaseMode) {
      return Environment.production;
    }
    return _currentEnvironment;
  }

  // Verificar si estamos en producción
  static bool get isProduction => currentEnvironment == Environment.production;
  static bool get isDevelopment =>
      currentEnvironment == Environment.development;
  static bool get isStaging => currentEnvironment == Environment.staging;

  // URLs base por ambiente
  static String get baseUrl {
    // TEMPORAL: Siempre usar producción para testing
    return 'https://herobudget.jaimedigitalstudio.com';

    // switch (currentEnvironment) {
    //   case Environment.production:
    //     return 'https://herobudget.jaimedigitalstudio.com';
    //   case Environment.staging:
    //     return 'https://staging.herobudget.jaimedigitalstudio.com'; // Para futuro
    //   case Environment.development:
    //     return 'http://localhost';
    // }
  }

  // Configuración de debug
  static bool get enableLogging => !isProduction;
  static bool get enableDebugMode => isDevelopment;

  // Información del ambiente actual
  static Map<String, dynamic> get environmentInfo => {
    'environment': currentEnvironment.toString().split('.').last,
    'baseUrl': baseUrl,
    'isProduction': isProduction,
    'isDevelopment': isDevelopment,
    'enableLogging': enableLogging,
    'enableDebugMode': enableDebugMode,
  };

  // Imprimir configuración actual
  static void printEnvironmentInfo() {
    print('=== Environment Configuration ===');
    environmentInfo.forEach((key, value) {
      print('$key: $value');
    });
    print('================================');
  }
}
