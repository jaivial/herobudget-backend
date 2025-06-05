import 'environment.dart';

class AppConfig {
  // Configuración de timeouts de red
  static Duration get apiTimeout {
    switch (EnvironmentConfig.currentEnvironment) {
      case Environment.production:
        return const Duration(seconds: 30);
      case Environment.staging:
        return const Duration(seconds: 45);
      case Environment.development:
        return const Duration(seconds: 60); // Más tiempo para debug
    }
  }

  // Configuración de reintentos de red
  static int get maxRetries {
    switch (EnvironmentConfig.currentEnvironment) {
      case Environment.production:
        return 3;
      case Environment.staging:
        return 2;
      case Environment.development:
        return 1; // Menos reintentos para debug más rápido
    }
  }

  // Configuración de logging detallado
  static bool get enableDetailedLogging => EnvironmentConfig.enableLogging;
  static bool get enableNetworkLogging => !EnvironmentConfig.isProduction;
  static bool get enableErrorReporting => EnvironmentConfig.isProduction;

  // Configuración de caché
  static Duration get cacheTimeout {
    switch (EnvironmentConfig.currentEnvironment) {
      case Environment.production:
        return const Duration(minutes: 30);
      case Environment.staging:
        return const Duration(minutes: 15);
      case Environment.development:
        return const Duration(minutes: 5); // Caché más corto para desarrollo
    }
  }

  // Headers HTTP adicionales según el ambiente
  static Map<String, String> get defaultHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (EnvironmentConfig.isDevelopment) {
      headers['X-Debug-Mode'] = 'true';
    }

    if (EnvironmentConfig.isProduction) {
      headers['X-Client-Version'] = appVersion;
    }

    return headers;
  }

  // Versión de la app
  static String get appVersion => '1.0.0'; // Esto debería venir de pubspec.yaml

  // Configuración de autenticación
  static Duration get tokenRefreshBuffer => const Duration(minutes: 5);

  // URLs de soporte según ambiente
  static String get supportUrl {
    switch (EnvironmentConfig.currentEnvironment) {
      case Environment.production:
        return 'https://support.herobudget.com';
      case Environment.staging:
        return 'https://staging-support.herobudget.com';
      case Environment.development:
        return 'https://dev-support.herobudget.com';
    }
  }

  // Configuración de deep linking
  static String get appScheme {
    switch (EnvironmentConfig.currentEnvironment) {
      case Environment.production:
        return 'herobudget';
      case Environment.staging:
        return 'herobudget-staging';
      case Environment.development:
        return 'herobudget-dev';
    }
  }

  // Configuración de Google Auth (si es diferente por ambiente)
  static String get googleClientId {
    switch (EnvironmentConfig.currentEnvironment) {
      case Environment.production:
        return 'production-google-client-id'; // Reemplazar con ID real
      case Environment.staging:
        return 'staging-google-client-id';
      case Environment.development:
        return 'development-google-client-id';
    }
  }

  // Métodos de utilidad
  static void printAppConfig() {
    if (!enableDetailedLogging) return;

    print('=== App Configuration ===');
    print('API Timeout: ${apiTimeout.inSeconds}s');
    print('Max Retries: $maxRetries');
    print('Cache Timeout: ${cacheTimeout.inMinutes}m');
    print('Enable Network Logging: $enableNetworkLogging');
    print('Enable Error Reporting: $enableErrorReporting');
    print('App Scheme: $appScheme');
    print('Support URL: $supportUrl');
    print('========================');
  }

  // Verificar si una feature está habilitada según el ambiente
  static bool isFeatureEnabled(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'analytics':
        return EnvironmentConfig.isProduction;
      case 'crash_reporting':
        return EnvironmentConfig.isProduction;
      case 'debug_panel':
        return EnvironmentConfig.isDevelopment;
      case 'performance_monitoring':
        return EnvironmentConfig.isProduction || EnvironmentConfig.isStaging;
      default:
        return true; // Por defecto, todas las features están habilitadas
    }
  }
}
