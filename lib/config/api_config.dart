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
  static const int transactionDeleteServicePort = 8095;
  static const int categoriesManagementServicePort = 8096;
  static const int moneyFlowSyncServicePort = 8097;
  static const int budgetOverviewFetchServicePort = 8098;
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

  // URLs base para servicios - CORREGIDAS PARA USAR RUTAS ESPECÍFICAS QUE FUNCIONAN
  static String get signupBaseUrl =>
      _buildServiceUrl('/signup/register', signupServicePort);
  static String get languageServiceUrl =>
      _buildServiceUrl('/language/get', languageServicePort);
  static String get signinServiceUrl => _buildServiceUrl('', signinServicePort);
  static String get googleAuthBaseUrl =>
      _buildServiceUrl('/auth/google', googleAuthServicePort);
  static String get fetchDashboardServiceUrl =>
      _buildServiceUrl('', fetchDashboardServicePort);
  static String get resetPasswordServiceUrl =>
      _buildServiceUrl('/reset-password/request', resetPasswordServicePort);
  static String get dashboardDataServiceUrl =>
      _buildServiceUrl('/dashboard/data', dashboardDataServicePort);
  static String get budgetManagementUrl =>
      _buildServiceUrl('/budget/fetch', budgetManagementServicePort);
  static String get savingsManagementUrl =>
      _buildServiceUrl('/savings/fetch', savingsManagementServicePort);
  static String get cashBankManagementUrl => _buildServiceUrl(
    '/cash-bank/distribution',
    cashBankManagementServicePort,
  );
  static String get billsManagementUrl =>
      _buildServiceUrl('/bills', billsManagementServicePort);
  static String get incomeManagementServiceUrl =>
      _buildServiceUrl('/incomes', incomeManagementServicePort);
  static String get expenseManagementServiceUrl =>
      _buildServiceUrl('/expenses', expenseManagementServicePort);
  static String get categoriesEndpoint =>
      _buildServiceUrl('/categories', categoriesManagementServicePort);
  static String get profileManagementUrl =>
      _buildServiceUrl('/profile/update', profileManagementServicePort);

  // URLs específicas manteniendo compatibilidad
  static String get signupServiceUrl => signupBaseUrl;
  static String get googleAuthServiceUrl => googleAuthBaseUrl;

  // Money Flow Sync Service - REVERTIDA A URL ORIGINAL
  static String get moneyFlowSyncServiceUrl =>
      _buildServiceUrl('/money-flow/sync', moneyFlowSyncServicePort);

  // Budget Overview Fetch Service - FIXED: Uses /budget-overview endpoint
  static String get budgetOverviewFetchServiceUrl =>
      _buildServiceUrl('/budget-overview', budgetOverviewFetchServicePort);

  // Transaction History Service - Uses same service as budget overview (port 8098)
  static String get transactionHistoryServiceUrl =>
      _buildServiceUrl('', budgetOverviewFetchServicePort);

  // ===== ENDPOINTS ESPECÍFICOS CENTRALIZADOS =====

  // 🔐 Authentication Endpoints
  static String get signinEndpoint =>
      _buildServiceUrl('/signin', signinServicePort);
  static String get signinCheckEmailEndpoint =>
      _buildServiceUrl('/signin/check-email', signinServicePort);
  static String get signupRegisterEndpoint => signupServiceUrl;
  static String get signupCheckEmailEndpoint =>
      _buildServiceUrl('/signup/check-email', signupServicePort);
  static String get signupCheckVerificationEndpoint =>
      _buildServiceUrl('/signup/check-verification', signupServicePort);
  static String get signupResendVerificationEndpoint =>
      _buildServiceUrl('/signup/resend-verification', signupServicePort);
  static String get signupVerifyEmailEndpoint =>
      _buildServiceUrl('/signup/verify-email', signupServicePort);
  static String get googleAuthEndpoint => googleAuthServiceUrl;

  // 🔑 Reset Password Endpoints
  static String get resetPasswordCheckEmailEndpoint =>
      _buildServiceUrl('/reset-password/check-email', resetPasswordServicePort);
  static String get resetPasswordRequestEndpoint => resetPasswordServiceUrl;
  static String get resetPasswordValidateTokenEndpoint => _buildServiceUrl(
    '/reset-password/validate-token',
    resetPasswordServicePort,
  );
  static String get resetPasswordUpdateEndpoint =>
      _buildServiceUrl('/reset-password/update', resetPasswordServicePort);

  // 💰 Savings Management Endpoints
  static String get savingsFetchEndpoint => savingsManagementUrl;
  static String get savingsUpdateEndpoint =>
      _buildServiceUrl('/savings/update', savingsManagementServicePort);
  static String get savingsDeleteEndpoint =>
      _buildServiceUrl('/savings/delete', savingsManagementServicePort);
  static String get savingsHealthEndpoint =>
      _buildServiceUrl('/savings/health', savingsManagementServicePort);

  // 📊 Income Management Endpoints
  static String get incomeAddEndpoint =>
      _buildServiceUrl('/incomes/add', incomeManagementServicePort);
  static String get incomeFetchEndpoint => incomeManagementServiceUrl;
  static String get incomeUpdateEndpoint =>
      _buildServiceUrl('/incomes/update', incomeManagementServicePort);
  static String get incomeDeleteEndpoint =>
      _buildServiceUrl('/incomes/delete', incomeManagementServicePort);

  // 📉 Expense Management Endpoints
  static String get expenseAddEndpoint =>
      _buildServiceUrl('/expenses/add', expenseManagementServicePort);
  static String get expenseFetchEndpoint => expenseManagementServiceUrl;
  static String get expenseUpdateEndpoint =>
      _buildServiceUrl('/expenses/update', expenseManagementServicePort);
  static String get expenseDeleteEndpoint =>
      _buildServiceUrl('/expenses/delete', expenseManagementServicePort);

  // 🏦 Cash Bank Management Endpoints
  static String get cashBankDistributionEndpoint => cashBankManagementUrl;
  static String get cashUpdateEndpoint =>
      _buildServiceUrl('/cash-bank/cash/update', cashBankManagementServicePort);
  static String get bankUpdateEndpoint =>
      _buildServiceUrl('/cash-bank/bank/update', cashBankManagementServicePort);
  static String get transferCashToBankEndpoint =>
      isProduction
          ? '$baseApiUrl/transfer/cash-to-bank'
          : '$baseApiUrl:$cashBankManagementServicePort/transfer/cash-to-bank';
  static String get transferBankToCashEndpoint =>
      isProduction
          ? '$baseApiUrl/transfer/bank-to-cash'
          : '$baseApiUrl:$cashBankManagementServicePort/transfer/bank-to-cash';

  // 🧾 Bills Management Endpoints
  static String get billsFetchEndpoint => billsManagementUrl;
  static String get billsAddEndpoint =>
      _buildServiceUrl('/bills/add', billsManagementServicePort);
  static String get billsPayEndpoint =>
      _buildServiceUrl('/bills/pay', billsManagementServicePort);
  static String get billsUpdateEndpoint =>
      _buildServiceUrl('/bills/update', billsManagementServicePort);
  static String get billsDeleteEndpoint =>
      _buildServiceUrl('/bills/delete', billsManagementServicePort);
  static String get billsUpcomingEndpoint =>
      _buildServiceUrl('/bills/upcoming', billsManagementServicePort);

  // 🗂️ Categories Management Endpoints
  static String get categoriesFetchEndpoint => categoriesEndpoint;
  static String get categoriesAddEndpoint =>
      _buildServiceUrl('/categories/add', categoriesManagementServicePort);
  static String get categoriesUpdateEndpoint =>
      _buildServiceUrl('/categories/update', categoriesManagementServicePort);
  static String get categoriesDeleteEndpoint =>
      _buildServiceUrl('/categories/delete', categoriesManagementServicePort);

  // 👤 Profile Management Endpoints
  static String get profileUpdateEndpoint => profileManagementUrl;
  static String get profileUpdatePasswordEndpoint => _buildServiceUrl(
    '/profile/update-password',
    profileManagementServicePort,
  );
  static String get profilePingEndpoint =>
      _buildServiceUrl('/profile/ping', profileManagementServicePort);
  static String get profileTestImageUpdateEndpoint => _buildServiceUrl(
    '/profile/test-image-update',
    profileManagementServicePort,
  );
  static String get profileUpdateLocaleEndpoint =>
      _buildServiceUrl('/update/locale', profileManagementServicePort);

  // 📈 Transaction & Dashboard Endpoints
  static String get transactionHistoryEndpoint =>
      _buildServiceUrl('/transactions/history', budgetOverviewFetchServicePort);
  static String get transactionDeleteEndpoint =>
      _buildServiceUrl('/transactions/delete', transactionDeleteServicePort);
  static String get budgetOverviewEndpoint => budgetOverviewFetchServiceUrl;
  static String get budgetOverviewHealthEndpoint =>
      _buildServiceUrl('/health', budgetOverviewFetchServicePort);
  static String get dashboardUserInfoEndpoint =>
      _buildServiceUrl('/user/info', fetchDashboardServicePort);
  static String get dashboardUserUpdateEndpoint =>
      _buildServiceUrl('/user/update', fetchDashboardServicePort);
  static String get dashboardHealthEndpoint =>
      _buildServiceUrl('/health', fetchDashboardServicePort);
  static String get dashboardDataEndpoint =>
      _buildServiceUrl('/dashboard/data', dashboardDataServicePort);
  static String get dashboardSavingsUpdateEndpoint =>
      _buildServiceUrl('/savings/update', fetchDashboardServicePort);
  static String get dashboardBillsAddEndpoint =>
      _buildServiceUrl('/bills/add', fetchDashboardServicePort);
  static String get dashboardBillsPayEndpoint =>
      _buildServiceUrl('/bills/pay', fetchDashboardServicePort);
  static String get moneyFlowDataEndpoint =>
      _buildServiceUrl('/money-flow/data', moneyFlowSyncServicePort);

  // 🌐 Language Management Endpoints
  static String get languageGetEndpoint => languageServiceUrl;
  static String get languageSetEndpoint =>
      _buildServiceUrl('/language/set', languageServicePort);

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
    'transactionHistory': transactionHistoryServiceUrl,
    'profile': profileManagementUrl,

    // 🔐 Authentication Endpoints
    'signinEndpoint': signinEndpoint,
    'signinCheckEmail': signinCheckEmailEndpoint,
    'signupRegister': signupRegisterEndpoint,
    'signupCheckEmail': signupCheckEmailEndpoint,
    'signupCheckVerification': signupCheckVerificationEndpoint,
    'signupResendVerification': signupResendVerificationEndpoint,
    'signupVerifyEmail': signupVerifyEmailEndpoint,
    'googleAuthEndpoint': googleAuthEndpoint,

    // 🔑 Reset Password Endpoints
    'resetPasswordCheckEmail': resetPasswordCheckEmailEndpoint,
    'resetPasswordRequest': resetPasswordRequestEndpoint,
    'resetPasswordValidateToken': resetPasswordValidateTokenEndpoint,
    'resetPasswordUpdate': resetPasswordUpdateEndpoint,

    // 💰 Savings Management Endpoints
    'savingsFetch': savingsFetchEndpoint,
    'savingsUpdate': savingsUpdateEndpoint,
    'savingsDelete': savingsDeleteEndpoint,
    'savingsHealth': savingsHealthEndpoint,

    // 📊 Income Management Endpoints
    'incomeAdd': incomeAddEndpoint,
    'incomeFetch': incomeFetchEndpoint,
    'incomeUpdate': incomeUpdateEndpoint,
    'incomeDelete': incomeDeleteEndpoint,

    // 📉 Expense Management Endpoints
    'expenseAdd': expenseAddEndpoint,
    'expenseFetch': expenseFetchEndpoint,
    'expenseUpdate': expenseUpdateEndpoint,
    'expenseDelete': expenseDeleteEndpoint,

    // 🏦 Cash Bank Management Endpoints
    'cashBankDistribution': cashBankDistributionEndpoint,
    'cashUpdate': cashUpdateEndpoint,
    'bankUpdate': bankUpdateEndpoint,
    'transferCashToBank': transferCashToBankEndpoint,
    'transferBankToCash': transferBankToCashEndpoint,

    // 🧾 Bills Management Endpoints
    'billsFetch': billsFetchEndpoint,
    'billsAdd': billsAddEndpoint,
    'billsPay': billsPayEndpoint,
    'billsUpdate': billsUpdateEndpoint,
    'billsDelete': billsDeleteEndpoint,
    'billsUpcoming': billsUpcomingEndpoint,

    // 🗂️ Categories Management Endpoints
    'categoriesFetch': categoriesFetchEndpoint,
    'categoriesAdd': categoriesAddEndpoint,
    'categoriesUpdate': categoriesUpdateEndpoint,
    'categoriesDelete': categoriesDeleteEndpoint,

    // 👤 Profile Management Endpoints
    'profileUpdate': profileUpdateEndpoint,
    'profileUpdatePassword': profileUpdatePasswordEndpoint,
    'profilePing': profilePingEndpoint,
    'profileTestImageUpdate': profileTestImageUpdateEndpoint,
    'profileUpdateLocale': profileUpdateLocaleEndpoint,

    // 📈 Transaction & Dashboard Endpoints
    'transactionHistoryEndpoint': transactionHistoryEndpoint,
    'transactionDelete': transactionDeleteEndpoint,
    'budgetOverviewEndpoint': budgetOverviewEndpoint,
    'budgetOverviewHealth': budgetOverviewHealthEndpoint,
    'dashboardUserInfo': dashboardUserInfoEndpoint,
    'dashboardUserUpdate': dashboardUserUpdateEndpoint,
    'dashboardHealth': dashboardHealthEndpoint,
    'dashboardData': dashboardDataEndpoint,
    'dashboardSavingsUpdate': dashboardSavingsUpdateEndpoint,
    'dashboardBillsAdd': dashboardBillsAddEndpoint,
    'dashboardBillsPay': dashboardBillsPayEndpoint,
    'moneyFlowData': moneyFlowDataEndpoint,

    // 🌐 Language Management Endpoints
    'languageGet': languageGetEndpoint,
    'languageSet': languageSetEndpoint,
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

  /// Mostrar URLs específicas corregidas para servicios con rutas específicas
  static void printCorrectedUrls() {
    print('\n🔧 URLS CORREGIDAS CON RUTAS ESPECÍFICAS:');
    print('Environment: ${EnvironmentConfig.currentEnvironment}');

    print('\n🔐 Authentication (corregidas):');
    print('  Signup Register: $signupServiceUrl');
    print('  Reset Password Request: $resetPasswordServiceUrl');
    print('  Google Auth: $googleAuthServiceUrl');
    print('  Signin: $signinServiceUrl');

    print('\n📊 Management (corregidas):');
    print('  Dashboard Data: $dashboardDataServiceUrl');
    print('  Profile Update: $profileManagementUrl');
    print('  Language Get: $languageServiceUrl');

    print('\n💰 Financial (corregidas):');
    print('  Budget Fetch: $budgetManagementUrl');
    print('  Savings Fetch: $savingsManagementUrl');
    print('  Cash-Bank Distribution: $cashBankManagementUrl');
    print('  Categories: $categoriesEndpoint');

    print('\n🚀 Specialized (corregidas):');
    print('  Money Flow Sync: $moneyFlowSyncServiceUrl');

    print('\n🧪 Test Commands (rutas específicas):');
    print('  curl -X POST "$signupServiceUrl"');
    print('  curl -X GET "$languageServiceUrl"');
    print('  curl -X GET "$budgetManagementUrl"');
    print('  curl -X GET "$cashBankManagementUrl"');
    print('========================\n');
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
    print('  Distribution: $cashBankManagementUrl?user_id=X');
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

  /// Método específico para debug de reset password URLs
  static void printResetPasswordUrls() {
    print('\n🔐 RESET PASSWORD URLs DEBUG:');
    print('Environment: ${EnvironmentConfig.currentEnvironment}');
    print('Base URL: $baseApiUrl');
    print('Is Production: $isProduction');

    print('\nReset Password Service Configuration:');
    print('  Port: $resetPasswordServicePort');
    print('  Base URL: $resetPasswordServiceUrl');

    print('\nExpected Endpoints:');
    print('  Check Email: $resetPasswordServiceUrl/check-email');
    print('  Request Reset: $resetPasswordServiceUrl/request');
    print('  Validate Token: $resetPasswordServiceUrl/validate-token');
    print('  Update Password: $resetPasswordServiceUrl/update');

    print('\n🧪 Test Commands:');
    print(
      '  curl -X POST "$resetPasswordServiceUrl/check-email" -H "Content-Type: application/json" -d \'{"email":"test@example.com"}\'',
    );
    print(
      '  curl -X POST "$resetPasswordServiceUrl/request" -H "Content-Type: application/json" -d \'{"email":"test@example.com"}\'',
    );
    print(
      '  curl -X POST "$resetPasswordServiceUrl/validate-token" -H "Content-Type: application/json" -d \'{"token":"test-token"}\'',
    );
    print(
      '  curl -X POST "$resetPasswordServiceUrl/update" -H "Content-Type: application/json" -d \'{"token":"test-token","user_id":1,"new_password":"newpass"}\'',
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
