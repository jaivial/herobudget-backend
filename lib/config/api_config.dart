import 'dart:io';
import 'package:flutter/foundation.dart';
import 'environment.dart';

class ApiConfig {
  // URL base según el ambiente (usa EnvironmentConfig)
  static String get baseApiUrl => EnvironmentConfig.baseUrl;

  // Verificar si estamos en producción
  static bool get isProduction => EnvironmentConfig.isProduction;

  // Helper method to detect if we're running on a simulator
  static bool isRunningOnSimulator() {
    try {
      return Platform.isIOS &&
          !Platform.environment.containsKey('FLUTTER_TEST') &&
          Platform.operatingSystemVersion.toLowerCase().contains('simulator');
    } catch (e) {
      if (EnvironmentConfig.enableLogging) {
        print('Error detecting simulator: $e');
      }
      return false;
    }
  }

  // ===== MÉTODOS DE CONFIGURACIÓN DE AMBIENTE =====

  /// Configura la app para usar servicios locales (localhost)
  /// Útil para desarrollo con backend local usando start_services.sh
  static void useLocalhost() {
    EnvironmentConfig.forceLocalDevelopment();
    if (EnvironmentConfig.enableLogging) {
      print('🔧 Configured for LOCAL DEVELOPMENT');
      print(
        'Backend services should be running on localhost with start_services.sh',
      );
      _printServicePorts();
    }
  }

  /// Configura la app para usar servicios de producción
  /// Útil para testing con el backend real
  static void useProduction() {
    EnvironmentConfig.forceProduction();
    if (EnvironmentConfig.enableLogging) {
      print('🌐 Configured for PRODUCTION');
      print('Using production backend: ${EnvironmentConfig.baseUrl}');
    }
  }

  /// Muestra los puertos que deberían estar corriendo localmente
  static void _printServicePorts() {
    print('\n📋 Local Services Ports:');
    print('Google Auth: $googleAuthServicePort');
    print('Signup: $signupServicePort');
    print('Signin: $signinServicePort');
    print('Language: $languageServicePort');
    print('Dashboard: $fetchDashboardServicePort');
    print('Budget: $budgetManagementServicePort');
    print('And more... (check start_services.sh for complete list)');
    print('💡 Run ./start_services.sh to start all services\n');
  }

  // ===== CONFIGURACIÓN DE PUERTOS (DESARROLLO) =====

  // Service ports (solo usados en desarrollo)
  static const int signupServicePort = 8082;
  static const int languageServicePort = 8083;
  static const int signinServicePort = 8084;
  static const int googleAuthServicePort = 8081;
  static const int fetchDashboardServicePort = 8085;
  static const int resetPasswordServicePort = 8086;
  static const int dashboardDataServicePort = 8087;
  static const int budgetManagementServicePort = 8088;
  static const int savingsManagementServicePort = 8089;
  static const int cashBankManagementServicePort = 8090;
  static const int billsManagementServicePort = 8091;
  static const int incomeManagementServicePort = 8093;
  static const int expenseManagementServicePort = 8094;
  static const int categoriesManagementServicePort = 8095;
  static const int moneyFlowSyncServicePort = 8096;
  static const int budgetOverviewFetchServicePort = 8097;
  static const int profileManagementServicePort = 8092;

  // ===== CONSTRUCCIÓN DE URLs =====

  // Helper para construir URLs según el ambiente
  static String _buildServiceUrl(String path, int port) {
    if (isProduction) {
      return '$baseApiUrl$path';
    } else {
      // Para localhost, necesitamos incluir el path completo
      return '$baseApiUrl:$port$path';
    }
  }

  // URLs base para servicios (sin endpoints específicos)
  static String get signupBaseUrl =>
      _buildServiceUrl('/signup', signupServicePort);
  static String get languageServiceUrl =>
      _buildServiceUrl('/language', languageServicePort);
  static String get signinServiceUrl =>
      _buildServiceUrl('/signin', signinServicePort);
  static String get googleAuthBaseUrl =>
      _buildServiceUrl('/auth/google', googleAuthServicePort);
  static String get fetchDashboardServiceUrl =>
      _buildServiceUrl('', fetchDashboardServicePort);
  static String get resetPasswordServiceUrl =>
      _buildServiceUrl('/reset-password', resetPasswordServicePort);
  static String get dashboardDataServiceUrl =>
      _buildServiceUrl('/dashboard-data', dashboardDataServicePort);
  static String get budgetManagementUrl =>
      _buildServiceUrl('/budget', budgetManagementServicePort);
  static String get savingsManagementUrl =>
      _buildServiceUrl('/savings', savingsManagementServicePort);
  static String get cashBankManagementUrl =>
      _buildServiceUrl('/cash-bank', cashBankManagementServicePort);
  static String get billsManagementUrl =>
      _buildServiceUrl('/bills', billsManagementServicePort);
  static String get incomeManagementServiceUrl =>
      _buildServiceUrl('/incomes', incomeManagementServicePort);
  static String get expenseManagementServiceUrl =>
      _buildServiceUrl('/expenses', expenseManagementServicePort);
  static String get categoriesEndpoint =>
      _buildServiceUrl('/categories', categoriesManagementServicePort);
  static String get profileManagementUrl =>
      _buildServiceUrl('/profile', profileManagementServicePort);

  // URLs específicas manteniendo compatibilidad
  static String get signupServiceUrl => signupBaseUrl;
  static String get googleAuthServiceUrl => googleAuthBaseUrl;

  // Money Flow Sync Service
  static String get moneyFlowSyncServiceUrl =>
      _buildServiceUrl('/money-flow-sync', moneyFlowSyncServicePort);

  // Budget Overview Fetch Service - FIXED: Uses /budget-overview endpoint
  static String get budgetOverviewFetchServiceUrl =>
      _buildServiceUrl('/budget-overview', budgetOverviewFetchServicePort);

  // ===== MÉTODOS DE DEBUG Y UTILIDAD =====

  // Método para debug - mostrar configuración actual
  static void printCurrentConfig() {
    if (!EnvironmentConfig.enableLogging) return;

    print('=== API Configuration ===');
    EnvironmentConfig.printEnvironmentInfo();
    print('\n📡 Current API Endpoints:');
    print('Signup: $signupServiceUrl');
    print('Signin: $signinServiceUrl');
    print('Google Auth: $googleAuthServiceUrl');
    print('Dashboard: $fetchDashboardServiceUrl');
    print('Budget Management: $budgetManagementUrl');
    print('Categories: $categoriesEndpoint');
    print('========================');
  }

  /// Método para debug - mostrar TODAS las URLs generadas
  static void printAllEndpoints() {
    if (!EnvironmentConfig.enableLogging) return;

    print('\n🔗 ALL GENERATED ENDPOINTS:');
    print('Environment: ${EnvironmentConfig.currentEnvironment}');
    print('Base URL: $baseApiUrl');
    print('Is Production: $isProduction');
    print('\n📋 Generated URLs:');

    final endpoints = allEndpoints;
    endpoints.forEach((key, value) {
      print('  $key: $value');
    });

    print('\n🧪 Test URLs:');
    print('Google Auth Test: curl -X POST $googleAuthServiceUrl');
    print('Signup Test: curl -X POST $signupServiceUrl');
    print('========================\n');
  }

  /// Método de utilidad para cambiar rápidamente entre ambientes
  /// durante el desarrollo
  static void quickEnvironmentSwitch() {
    if (EnvironmentConfig.isDevelopment) {
      print('🔄 Switching to PRODUCTION mode');
      useProduction();
    } else {
      print('🔄 Switching to LOCALHOST mode');
      useLocalhost();
    }
    printCurrentConfig();
  }

  // Endpoints completos para referencia rápida
  static Map<String, String> get allEndpoints => {
    'signup': signupServiceUrl,
    'signin': signinServiceUrl,
    'googleAuth': googleAuthServiceUrl,
    'language': languageServiceUrl,
    'fetchDashboard': fetchDashboardServiceUrl,
    'resetPassword': resetPasswordServiceUrl,
    'dashboardData': dashboardDataServiceUrl,
    'budget': budgetManagementUrl,
    'savings': savingsManagementUrl,
    'cashBank': cashBankManagementUrl,
    'bills': billsManagementUrl,
    'income': incomeManagementServiceUrl,
    'expense': expenseManagementServiceUrl,
    'categories': categoriesEndpoint,
    'moneyFlowSync': moneyFlowSyncServiceUrl,
    'budgetOverview': budgetOverviewFetchServiceUrl,
    'profile': profileManagementUrl,
  };

  /// Valida que todos los servicios locales estén disponibles
  /// Útil para verificar que start_services.sh está funcionando
  static Future<void> validateLocalServices() async {
    if (isProduction) {
      print('⚠️  Currently in production mode. Switch to localhost first.');
      return;
    }

    print('🔍 Checking local services availability...');

    final servicesToCheck = [
      {'name': 'Google Auth', 'port': googleAuthServicePort},
      {'name': 'Signup', 'port': signupServicePort},
      {'name': 'Signin', 'port': signinServicePort},
      {'name': 'Dashboard', 'port': fetchDashboardServicePort},
    ];

    for (final service in servicesToCheck) {
      try {
        final socket = await Socket.connect(
          'localhost',
          service['port'] as int,
        ).timeout(const Duration(seconds: 2));
        socket.destroy();
        print('✅ ${service['name']} (port ${service['port']}) - OK');
      } catch (e) {
        print('❌ ${service['name']} (port ${service['port']}) - NOT AVAILABLE');
      }
    }

    print('\n💡 If services are not available, run: ./start_services.sh');
  }

  /// Mostrar URLs específicas de Income, Expense y Cash/Bank para debugging
  static void printFinancialUrls() {
    print('\n💰 FINANCIAL OPERATIONS URLs:');
    print('Environment: ${EnvironmentConfig.currentEnvironment}');

    print('\n📥 Income Management:');
    print('  Base: $incomeManagementServiceUrl');
    print('  Add: $incomeManagementServiceUrl/add');
    print('  Get: $incomeManagementServiceUrl?user_id=X');
    print('  Update: $incomeManagementServiceUrl/update');
    print('  Delete: $incomeManagementServiceUrl/delete');

    print('\n📤 Expense Management:');
    print('  Base: $expenseManagementServiceUrl');
    print('  Add: $expenseManagementServiceUrl/add');
    print('  Get: $expenseManagementServiceUrl?user_id=X');
    print('  Update: $expenseManagementServiceUrl/update');
    print('  Delete: $expenseManagementServiceUrl/delete');

    print('\n🏦 Cash/Bank Management:');
    print('  Base: $cashBankManagementUrl');
    print('  Distribution: $cashBankManagementUrl/distribution?user_id=X');
    print('  Cash Update: $cashBankManagementUrl/cash/update');
    print('  Bank Update: $cashBankManagementUrl/bank/update');

    final transferBaseUrl =
        isProduction
            ? baseApiUrl
            : '$baseApiUrl:$cashBankManagementServicePort';
    print('  Transfer (Cash→Bank): $transferBaseUrl/transfer/cash-to-bank');
    print('  Transfer (Bank→Cash): $transferBaseUrl/transfer/bank-to-cash');

    print('\n📊 Transaction History:');
    final transactionBaseUrl =
        isProduction
            ? baseApiUrl
            : '$baseApiUrl:$budgetOverviewFetchServicePort';
    print('  Base: $transactionBaseUrl');
    print('  History: $transactionBaseUrl/transactions/history');
    print('  Budget Overview: $budgetOverviewFetchServiceUrl');

    print('========================\n');
  }

  /// Mantener el método anterior para compatibilidad
  static void printIncomeExpenseUrls() => printFinancialUrls();

  /// Test de producción - Imprime todos los endpoints de producción
  static void printProductionUrls() {
    if (!isProduction) {
      print('⚠️  Currently in development mode. Switch to production first.');
      print('💡 Use: EnvironmentConfig.forceProduction()');
      return;
    }

    print('\n🚀 PRODUCTION URLs VERIFICATION:');
    print('Base URL: $baseApiUrl');
    print('\n🔐 Authentication:');
    print('  Google Auth: $googleAuthServiceUrl');
    print('  Signup: $signupServiceUrl');
    print('  Signin: $signinServiceUrl');

    print('\n📊 Core Services:');
    print('  Budget Overview: $budgetOverviewFetchServiceUrl');
    print('  Dashboard: $fetchDashboardServiceUrl');
    print('  User Profile: $profileManagementUrl');

    print('\n📈 Transaction Services:');
    print('  Transaction History: $baseApiUrl/transactions/history');
    print('  Budget Overview Endpoint: $budgetOverviewFetchServiceUrl');

    print('\n💰 Financial Operations:');
    print('  Income: $incomeManagementServiceUrl');
    print('  Expense: $expenseManagementServiceUrl');
    print('  Bills: $billsManagementUrl');
    print('  Budget: $budgetManagementUrl');

    print('\n🏦 Cash/Bank Operations:');
    print('  Cash/Bank: $cashBankManagementUrl');
    print('  Transfer (Cash→Bank): $baseApiUrl/transfer/cash-to-bank');
    print('  Transfer (Bank→Cash): $baseApiUrl/transfer/bank-to-cash');

    print('\n📂 Support Services:');
    print('  Categories: $categoriesEndpoint');
    print('  Savings: $savingsManagementUrl');

    print('\n🧪 Test Commands:');
    print('  curl -X POST "$googleAuthServiceUrl"');
    print(
      '  curl -X POST "$incomeManagementServiceUrl/add" -d \'{"user_id":"test"}\'',
    );
    print(
      '  curl -X POST "$expenseManagementServiceUrl/add" -d \'{"user_id":"test"}\'',
    );
    print(
      '  curl -X POST "$baseApiUrl/transfer/bank-to-cash" -d \'{"user_id":"test","amount":100}\'',
    );
    print(
      '  curl -X POST "$baseApiUrl/transactions/history" -d \'{"user_id":"test","limit":10}\'',
    );
    print('========================\n');
  }

  /// Método conveniente para alternar y mostrar configuración
  static void switchToProductionAndShow() {
    EnvironmentConfig.forceProduction();
    printProductionUrls();
  }

  /// Método conveniente para alternar y mostrar configuración
  static void switchToLocalhostAndShow() {
    EnvironmentConfig.forceLocalDevelopment();
    printAllEndpoints();
  }
}
