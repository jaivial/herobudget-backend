import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Your Mac's IP address on your local network
  // Use "localhost" for emulators and IP address for physical devices
  static String get baseApiUrl {
    // When running on a physical device, use the Mac's IP address
    if (!kIsWeb &&
        Platform.isIOS &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      if (isRunningOnSimulator()) {
        return 'http://localhost'; // Use localhost for iOS simulators
      }
      return 'http://192.168.0.22'; // Mac's actual IP address from ifconfig for physical devices
    }
    // For emulators and web testing
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

  // This method is simplified as we'll just always use the IP address on iOS devices
  // For more precise detection, you could add device_info_plus package
}
