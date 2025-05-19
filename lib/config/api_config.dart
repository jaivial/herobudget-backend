import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Usar siempre localhost para los servicios locales
  static String get baseApiUrl {
    return 'http://localhost';
  }

  // Helper method to detect if we're running on a simulator
  static bool isRunningOnSimulator() {
    try {
      // This is a simple way to detect simulator - not completely reliable but works for most cases
      return Platform.isIOS &&
          !Platform.environment.containsKey('FLUTTER_TEST') &&
          Platform.operatingSystemVersion.toLowerCase().contains('simulator');
    } catch (e) {
      print('Error detecting simulator: $e');
      return false;
    }
  }

  // Service ports
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

  // Service endpoints
  static String get signupServiceUrl => '$baseApiUrl:$signupServicePort';
  static String get languageServiceUrl => '$baseApiUrl:$languageServicePort';
  static String get signinServiceUrl => '$baseApiUrl:$signinServicePort';
  static String get googleAuthServiceUrl =>
      '$baseApiUrl:$googleAuthServicePort';
  static String get fetchDashboardServiceUrl =>
      '$baseApiUrl:$fetchDashboardServicePort';
  static String get resetPasswordServiceUrl =>
      '$baseApiUrl:$resetPasswordServicePort';
  static String get dashboardDataServiceUrl =>
      '$baseApiUrl:$dashboardDataServicePort';
  static String get budgetManagementUrl =>
      '$baseApiUrl:$budgetManagementServicePort';
  static String get savingsManagementUrl =>
      '$baseApiUrl:$savingsManagementServicePort';
  static String get cashBankManagementUrl =>
      '$baseApiUrl:$cashBankManagementServicePort';
  static String get billsManagementUrl =>
      '$baseApiUrl:$billsManagementServicePort';
  static String get incomeManagementServiceUrl =>
      '$baseApiUrl:$incomeManagementServicePort';
  static String get expenseManagementServiceUrl =>
      '$baseApiUrl:$expenseManagementServicePort';
  static String get categoriesEndpoint =>
      '$baseApiUrl:$categoriesManagementServicePort/categories';

  // Money Flow Sync Service (8096)
  static String get moneyFlowSyncServiceUrl => '$baseApiUrl:8096';

  // Money Flow Calculation Service (8097)
  static String get moneyFlowCalculationServiceUrl => '$baseApiUrl:8097';
}
