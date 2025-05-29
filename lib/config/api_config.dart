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

  // Helper para construir URLs según el ambiente
  static String _buildServiceUrl(String path, int port) {
    if (isProduction) {
      return '$baseApiUrl$path';
    } else {
      return '$baseApiUrl:$port';
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
      _buildServiceUrl('/fetch-dashboard', fetchDashboardServicePort);
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
      _buildServiceUrl('/income', incomeManagementServicePort);
  static String get expenseManagementServiceUrl =>
      _buildServiceUrl('/expense', expenseManagementServicePort);
  static String get categoriesEndpoint =>
      isProduction
          ? '$baseApiUrl/categories'
          : '$baseApiUrl:$categoriesManagementServicePort/categories';
  static String get profileManagementUrl =>
      _buildServiceUrl('/profile', profileManagementServicePort);

  // URLs específicas manteniendo compatibilidad
  static String get signupServiceUrl => signupBaseUrl;
  static String get googleAuthServiceUrl => googleAuthBaseUrl;

  // Money Flow Sync Service
  static String get moneyFlowSyncServiceUrl =>
      _buildServiceUrl('/money-flow-sync', moneyFlowSyncServicePort);

  // Budget Overview Fetch Service
  static String get budgetOverviewFetchServiceUrl =>
      isProduction
          ? '$baseApiUrl/budget-overview'
          : '$baseApiUrl:$budgetOverviewFetchServicePort';

  // Método para debug - mostrar configuración actual
  static void printCurrentConfig() {
    if (!EnvironmentConfig.enableLogging) return;

    print('=== API Configuration ===');
    EnvironmentConfig.printEnvironmentInfo();
    print('Signup URL: $signupServiceUrl');
    print('Signin URL: $signinServiceUrl');
    print('Google Auth URL: $googleAuthServiceUrl');
    print('Dashboard URL: $fetchDashboardServiceUrl');
    print('Budget Management URL: $budgetManagementUrl');
    print('========================');
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
}
