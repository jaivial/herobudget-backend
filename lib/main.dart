import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/verification/email_verification_screen.dart';
import 'screens/verification/email_otp_verification_screen.dart';
import 'screens/verification/email_verification_success_screen.dart';
import 'screens/reset_password/reset_password_screen.dart';
import 'screens/auth/signin_screen.dart';
import 'screens/language_selector_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'utils/deep_link_handler.dart';
import 'utils/platform_channel_fixes.dart';
import 'theme/app_theme.dart';
import 'services/language_service.dart';
import 'services/signin_service.dart';
import 'services/dashboard_service.dart';
import 'services/auth_service.dart';
import 'utils/app_localizations.dart';
import 'screens/category/fix_emoji_screen.dart';
import 'config/environment.dart';
import 'config/api_config.dart';
import 'config/app_config.dart';
import 'services/api_helper.dart';
import 'services/verification_service.dart';

// Language change notifier singleton
class LanguageChangeNotifier {
  static final LanguageChangeNotifier _instance =
      LanguageChangeNotifier._internal();

  factory LanguageChangeNotifier() {
    return _instance;
  }

  LanguageChangeNotifier._internal();

  final _languageChangeController = StreamController<String>.broadcast();

  Stream<String> get languageChangeStream => _languageChangeController.stream;

  void notifyLanguageChange(String locale) {
    _languageChangeController.add(locale);
  }

  void dispose() {
    _languageChangeController.close();
  }
}

// Create a single instance to be used throughout the app
final languageChangeNotifier = LanguageChangeNotifier();

/// Función para diagnosticar problemas comunes en el startup
Future<void> _performStartupDiagnostics() async {
  try {
    print('\n🚨 === STARTUP DIAGNOSTICS ===');

    // 1. Verificar SharedPreferences y user_id
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final allKeys = prefs.getKeys();

    print('🔍 SharedPreferences Diagnostics:');
    print('  • User ID: ${userId ?? "NULL"}');
    print('  • All keys: ${allKeys.toList()}');

    if (userId == null) {
      print('⚠️  WARNING: No user_id found in SharedPreferences');
      print('   This will cause 404 errors when fetching user-specific data');
    } else {
      print('✅ User ID found: $userId');
    }

    // 2. Verificar configuración de ambiente
    print('\n🌍 Environment Configuration:');
    print('  • Environment: ${EnvironmentConfig.currentEnvironment}');
    print('  • Is Development: ${EnvironmentConfig.isDevelopment}');
    print('  • Base URL: ${EnvironmentConfig.baseUrl}');

    // 3. Mostrar URLs que se van a usar
    print('\n🔗 Key API URLs:');
    print('  • Savings: ${ApiConfig.savingsManagementUrl}');
    if (userId != null) {
      print(
        '  • Savings Full URL: ${ApiConfig.savingsManagementUrl}/fetch?user_id=$userId',
      );
    }

    // 4. Test rápido de conectividad (solo en desarrollo)
    if (EnvironmentConfig.isDevelopment) {
      print('\n🧪 Quick Connectivity Test:');
      await _quickConnectivityTest();
    }

    print('=== END DIAGNOSTICS ===\n');
  } catch (e) {
    print('❌ Error in startup diagnostics: $e');
  }
}

/// Test rápido de conectividad para servicios locales
Future<void> _quickConnectivityTest() async {
  final servicesToTest = [
    {'port': 8089, 'name': 'Savings'},
    {'port': 8081, 'name': 'Google Auth'},
    {'port': 8088, 'name': 'Budget'},
  ];

  for (final service in servicesToTest) {
    try {
      final socket = await Socket.connect(
        'localhost',
        service['port'] as int,
      ).timeout(const Duration(seconds: 1));

      socket.destroy();
      print('  ✅ ${service['name']} (port ${service['port']}): OK');
    } catch (e) {
      print('  ❌ ${service['name']} (port ${service['port']}): NOT AVAILABLE');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FORCE PRODUCTION APIs - Use remote VPS endpoints
  // ApiConfig.useProduction();

  // ==========================================
  // 🔧 CONFIGURACIÓN DE AMBIENTE
  // ==========================================
  //
  // OPCIÓN 1: Configuración manual para desarrollo
  // Descomenta la línea que necesites:

  // Para usar servicios locales (localhost) - requiere start_services.sh
  ApiConfig.useLocalhost();

  // OPCIÓN 2: Configuración automática (recomendada)
  // Usar la configuración por defecto basada en el modo de compilación:
  // - DEBUG mode = development (localhost)
  // - RELEASE mode = production
  // EnvironmentConfig.setEnvironment(Environment.development); // Forzar localhost
  // EnvironmentConfig.setEnvironment(Environment.production);  // Forzar producción

  // Initialize API helper with environment configuration
  ApiHelper.initialize();

  // ==========================================
  // 🚨 DEBUG: Verificar configuración y user_id
  // ==========================================
  await _performStartupDiagnostics();

  // Print environment and API configuration for debugging
  if (EnvironmentConfig.enableLogging) {
    print('=== HERO BUDGET APP STARTUP ===');
    EnvironmentConfig.printEnvironmentInfo();
    ApiConfig.printCurrentConfig();
    ApiConfig.printAllEndpoints();
    AppConfig.printAppConfig();

    // Mostrar información adicional sobre los endpoints
    print('\n🔗 Available API Endpoints:');
    final endpoints = ApiConfig.allEndpoints;
    endpoints.forEach((key, value) {
      print('  $key: $value');
    });

    print('\n💡 Quick Setup Tips:');
    if (EnvironmentConfig.isDevelopment) {
      print('  • You are in DEVELOPMENT mode');
      print('  • Make sure to run: ./start_services.sh');
      print('  • Services should be running on localhost ports');
      print('  • To switch to production: ApiConfig.useProduction()');
    } else {
      print('  • You are in PRODUCTION mode');
      print('  • Using: ${EnvironmentConfig.baseUrl}');
      print('  • To switch to localhost: ApiConfig.useLocalhost()');
    }
    print('==============================');
  }

  // Initialize platform channel fixes for macOS
  if (Platform.isMacOS) {
    PlatformChannelFixes.init();
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(MyApp(key: myAppKey));
}

// Create a global key for MyApp state to allow forced refreshes from anywhere
final GlobalKey<_MyAppState> myAppKey = GlobalKey<_MyAppState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  // Add this method to expose the refreshLocale functionality
  static void refreshLocale(BuildContext context, String locale) {
    try {
      print('MyApp.refreshLocale called with: $locale');

      // Cambiar todas las notificaciones por un único flujo centralizado
      // para evitar bucles infinitos utilizando LanguageService
      LanguageService.saveLanguagePreference(locale);

      // No llamamos directamente a myAppKey.currentState?.refreshLocale
      // para evitar ciclos de notificación
    } catch (e) {
      print('Error in static refreshLocale: $e');
    }
  }

  // Add method to expose refreshTheme functionality
  static void refreshTheme(BuildContext context, ThemeMode mode) {
    myAppKey.currentState?.refreshTheme(mode);
  }
}

class _MyAppState extends State<MyApp> {
  bool _initialURILinkHandled = false;
  String? _verificationCode;
  StreamSubscription? _deepLinkSubscription;
  StreamSubscription? _languageChangeSubscription;
  StreamSubscription? _themeChangeSubscription;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  Locale? _appLocale;
  bool _isLocaleSupported = true;
  ThemeMode _themeMode = ThemeMode.dark;

  // Flag to prevent concurrent navigation
  bool _isHandlingDeepLink = false;

  // Reset password parameters
  String? _resetPasswordToken;
  String? _resetPasswordUserId;

  // Flag to show sign-in screen on next build
  bool _showSignIn = false;

  // Email verification parameters
  bool _needsEmailVerification = false;
  String? _pendingVerificationUserId;
  Map<String, dynamic>? _pendingVerificationUserInfo;

  // Add a public method that can be called to force showing the verification success screen
  void showVerificationSuccessScreen(String code) {
    setState(() {
      _verificationCode = code;
    });
  }

  // Method to refresh locale without restarting the app
  // Este método ahora solo es llamado directamente desde el AppHeader
  void refreshLocale(String localeString) async {
    print('refreshLocale called with: $localeString');

    try {
      // Obtener el idioma actual para comparar
      final String? currentLocale =
          await LanguageService.getLanguagePreference();

      // Evitar actualizaciones innecesarias
      if (currentLocale == localeString) {
        print('Locale is already set to $localeString, no update needed');
        return;
      }

      // Create a new Locale object
      final locale = Locale(localeString);

      // Guardar directamente en SharedPreferences para evitar ciclos
      // Hacemos esto de manera segura dentro de un try
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          LanguageService.languagePreferenceKey,
          localeString,
        );
        print('Language preference directly saved: $localeString');
      } catch (e) {
        print('Error saving language preference: $e');
      }

      // Actualizar el estado inmediatamente dentro de un try separado
      // para que si hay un error en la actualización, no afecte al resto
      try {
        if (mounted) {
          setState(() {
            _appLocale = locale;
            _isLocaleSupported = true;
          });
        }
      } catch (e) {
        print('Error updating app locale state: $e');
      }

      // Finalmente notificar el cambio de forma segura
      try {
        languageNotifier.notifyLanguageChanged(localeString);
      } catch (e) {
        print('Error notifying language change: $e');
      }
    } catch (e) {
      print('Error in refreshLocale: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    print("MyApp initState - starting app initialization");

    // Subscribe to language change events from languageNotifier in LanguageService
    // en lugar de languageChangeNotifier para evitar ciclos
    _languageChangeSubscription =
        null; // Desactivamos temporalmente esta suscripción

    // Suscribirse al notificador adecuado
    languageNotifier.addListener(() {
      // Este callback se ejecuta cuando cambia el idioma
      final newLocale = languageNotifier.lastLanguage;
      print(
        'MyApp reacting to language change via languageNotifier: $newLocale',
      );

      // Actualizar directamente el estado
      if (mounted) {
        setState(() {
          _appLocale = Locale(newLocale);
          _isLocaleSupported = true;
        });
      }
    });

    // Subscribe to theme change events
    _themeChangeSubscription = themeChangeNotifier.themeChangeStream.listen((
      mode,
    ) {
      refreshTheme(mode);
    });

    // First handle deep links, then check user status
    _initializeDeepLinking().then((_) {
      // After deep link handling, migrate data and check user
      _migrateOldUserData().then((_) {
        _checkUserStatus();
        _loadThemeMode();
      });
    });
  }

  // Migrate data from old localStorage format to new format
  Future<void> _migrateOldUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we have data in the old 'user_info' key
      final oldUserInfo = prefs.getString('user_info');
      if (oldUserInfo != null && oldUserInfo.isNotEmpty) {
        print('Found old user_info data, migrating to user_data...');

        // Also check if we have a user_id
        final userId = prefs.getString('user_id');

        if (userId != null && userId.isNotEmpty) {
          // Save to the new standardized key
          await prefs.setString(SignInService.userDataKey, oldUserInfo);
          print('Successfully migrated user data to standardized key');

          // Remove the old key
          await prefs.remove('user_info');
          print('Removed old user_info key');
        }
      }
    } catch (e) {
      print('Error during user data migration: $e');
      // Continue with app startup even if migration fails
    }
  }

  Future<void> _checkUserStatus() async {
    try {
      // Get saved locale from local storage
      final savedLocale = await LanguageService.getLanguagePreference();

      // Convert the string locale to Locale object, with better device locale detection
      Locale appLocale;
      if (savedLocale != null && savedLocale.isNotEmpty) {
        appLocale = Locale(savedLocale);
      } else {
        // If no saved locale, detect device locale and ensure it's supported
        final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
        final supportedLanguageCodes =
            AppLocalizations.supportedLocales
                .map((locale) => locale.languageCode)
                .toList();

        if (supportedLanguageCodes.contains(deviceLocale.languageCode)) {
          appLocale = Locale(deviceLocale.languageCode);
          // Save the detected locale for future use
          await LanguageService.saveLanguagePreference(
            deviceLocale.languageCode,
          );
        } else {
          // Fallback to English if device locale is not supported
          appLocale = const Locale('en');
          await LanguageService.saveLanguagePreference('en');
        }
      }

      setState(() {
        _appLocale = appLocale;
        _isLocaleSupported = true;
      });

      print('App locale set to: ${appLocale.languageCode}');

      // Check if user is already signed in
      final bool isSignedIn = await SignInService.isSignedIn();

      if (isSignedIn) {
        // Get the actual user ID using dashboard service which checks all possible storage locations
        final userId = await DashboardService.getCurrentUserId();

        if (userId != null && userId.isNotEmpty) {
          print('Startup: Found user ID: $userId in localStorage');

          try {
            // Get the latest user info from the server using this ID
            final userInfo = await DashboardService.fetchUserInfo(userId);

            // Check if email is verified
            final bool isEmailVerified = userInfo['verified_email'] ?? false;

            if (!isEmailVerified) {
              // Email not verified, redirect to OTP verification screen
              print(
                'Email not verified for user $userId, redirecting to OTP verification',
              );

              // Send a new verification code automatically
              try {
                final resendResult =
                    await VerificationService.resendVerificationEmail(
                      userId,
                      userInfo['email'],
                    );

                if (resendResult['success']) {
                  print('New verification code sent successfully');
                } else {
                  print(
                    'Failed to send new verification code: ${resendResult['error']}',
                  );
                }
              } catch (e) {
                print('Error sending new verification code: $e');
              }

              // Navigate to OTP verification screen
              setState(() {
                _isLoggedIn = false;
                _userData = null;
                _isLoading = false;
                _needsEmailVerification = true;
                _pendingVerificationUserId = userId;
                _pendingVerificationUserInfo = userInfo;
              });
              return;
            }

            // If locale exists in user info, save it and use it
            if (userInfo['locale'] != null && userInfo['locale'].isNotEmpty) {
              // Extract language code if using old format (with country code)
              String languageCode = userInfo['locale'];
              if (languageCode.contains('-')) {
                languageCode = languageCode.split('-')[0];
              }

              await LanguageService.saveLanguagePreference(languageCode);

              // Update locale
              setState(() {
                _appLocale = Locale(languageCode);
                _isLocaleSupported = true;
              });
            }

            setState(() {
              _isLoggedIn = true;
              _userData = userInfo;
              _isLoading = false;
            });
            return;
          } catch (e) {
            print('Error fetching user info: $e');

            // Check if this is a 404 "User not found" error
            if (e.toString().contains('404') ||
                e.toString().contains('Failed to fetch user information') ||
                e.toString().contains('User not found')) {
              print(
                'User not found on server, clearing local data and redirecting to onboarding',
              );

              // Clear user data from localStorage
              await _handleUserNotFound();

              // Update state to not logged in
              setState(() {
                _isLoggedIn = false;
                _userData = null;
                _isLoading = false;
              });
              return;
            }
          }
        }
      }

      // Not signed in or no valid user ID found
      setState(() {
        _isLoggedIn = false;
        _userData = null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error during user check on startup: $e');
      setState(() {
        _isLoggedIn = false;
        _userData = null;
        _isLoading = false;
      });
    }
  }

  // Helper method to handle the case when a user is not found on the server
  Future<void> _handleUserNotFound() async {
    try {
      print('Handling user not found - clearing local data');

      // Use both services to ensure all data is cleared
      await SignInService.signOut();

      // Also clear using SharedPreferences directly for extra safety
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_data');
      await prefs.remove('user_info'); // Also remove old key if it exists

      print('User data cleared from localStorage');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  Future<void> _initializeDeepLinking() async {
    // Skip deep linking on macOS since it's not fully supported
    if (Platform.isMacOS) {
      print("Skipping deep link initialization on macOS");
      return;
    }

    print("Checking for initial URI from deep link...");
    // For other platforms, use the standard uni_links implementation
    if (!_initialURILinkHandled) {
      _initialURILinkHandled = true;
      try {
        final initialURI = await getInitialUri();
        if (initialURI != null) {
          print("Found initial URI: $initialURI");
          // Handle the URI here
          if (mounted) {
            final linkData = DeepLinkHandler.processDeepLink(
              initialURI.toString(),
            );
            if (linkData != null) {
              _processDeepLinkData(linkData);
            }
          }
        } else {
          print("No initial URI found");
        }
      } catch (e) {
        print('Failed to get initial deep link: $e');
      }
    }

    // Listen for deep links while the app is running (non-macOS platforms)
    try {
      _deepLinkSubscription = uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null && mounted) {
            print("Received deep link from stream: $uri");
            // Handle the URI here
            final linkData = DeepLinkHandler.processDeepLink(uri.toString());
            if (linkData != null) {
              _processDeepLinkData(linkData);
            }
          }
        },
        onError: (err) {
          print('Error handling deep link: $err');
        },
      );
    } catch (e) {
      print('Failed to setup deep link stream: $e');
    }
  }

  // Helper method to process deep link data
  void _processDeepLinkData(Map<String, dynamic> linkData) {
    final linkType = linkData['type'];

    if (linkType == 'verification') {
      // Handle verification deep link
      final code = linkData['code'];
      if (code != null) {
        print("Processing verification code: $code");
        // Show verification success screen
        setState(() {
          _verificationCode = code;
        });
      }
    } else if (linkType == 'password_reset') {
      // Handle password reset deep link
      final token = linkData['token'];
      final userId = linkData['user_id'];

      if (token != null && userId != null) {
        print("Processing password reset token: $token, userId: $userId");
        // Show reset password screen
        setState(() {
          _resetPasswordToken = token;
          _resetPasswordUserId = userId;
        });
      }
    }
  }

  // Cargar el modo de tema desde SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final themeMode = await AppTheme.getThemeMode();
      setState(() {
        _themeMode = themeMode;
      });
    } catch (e) {
      print('Error loading theme mode: $e');
    }
  }

  // Método para actualizar el tema sin reiniciar la app
  void refreshTheme(ThemeMode mode) async {
    print('Refreshing theme to: $mode');

    // Guardar la preferencia
    await AppTheme.saveThemeMode(mode);

    // Actualizar el estado
    if (mounted) {
      setState(() {
        _themeMode = mode;
      });
    }
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();

    // No es necesario cancelar _languageChangeSubscription ya que es null
    // pero necesitamos remover el listener de languageNotifier
    languageNotifier.removeListener(() {}); // Eliminar todos los listeners

    _themeChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If loading, show a splash screen
    if (_isLoading) {
      return MaterialApp(
        title: 'Hero Budget',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // If locale is not supported, show language selector first
    if (!_isLocaleSupported) {
      return MaterialApp(
        title: 'Hero Budget',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        home: LanguageSelectorScreen(),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: _appLocale,
      );
    }

    // Determine which screen to show based on app state
    Widget homeScreen;

    if (_verificationCode != null) {
      // Show verification success screen if verification code is set
      homeScreen = EmailVerificationSuccessScreen(
        verificationCode: _verificationCode!,
      );
    } else if (_resetPasswordToken != null && _resetPasswordUserId != null) {
      // Show reset password screen if token and user ID are set
      homeScreen = ResetPasswordScreen(
        token: _resetPasswordToken!,
        userIdString: _resetPasswordUserId!,
      );
    } else if (_needsEmailVerification &&
        _pendingVerificationUserId != null &&
        _pendingVerificationUserInfo != null) {
      // Show email OTP verification screen if user needs email verification
      homeScreen = EmailOTPVerificationScreen(
        userId: _pendingVerificationUserId!,
        userInfo: _pendingVerificationUserInfo!,
      );
    } else if (_showSignIn) {
      // Show sign-in screen if explicitly requested
      homeScreen = const SignInScreen();
    } else if (_isLoggedIn && _userData != null) {
      // Show dashboard if user is logged in
      homeScreen = DashboardScreen(
        userId: _userData!['id'].toString(),
        userInfo: _userData!,
      );
    } else {
      // Show onboarding for new users
      homeScreen = const OnboardingScreen();
    }

    // Final MaterialApp configuration with localization support
    return MaterialApp(
      title: 'Hero Budget',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: homeScreen,
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/fix_emojis': (context) => const FixEmojiScreen(),
      },
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _appLocale,
      builder: (context, child) {
        // Return the child directly without waiting for preloading
        return child ?? const SizedBox();
      },
    );
  }

  // Preload localizations to ensure they're available before building content
  Future<void> _preloadLocalizations(BuildContext context) async {
    try {
      return; // Skip preloading since this is causing performance issues
    } catch (e) {
      print('Error preloading localizations: $e');
      return;
    }
  }

  // Method to navigate to reset password screen
  void navigateToResetPassword(String token, String userId) {
    print(
      "_MyAppState: Navigating to reset password screen with token: $token, userId: $userId",
    );

    // Validate inputs
    if (token.isEmpty || userId.isEmpty) {
      print("Error: Empty token or userId provided to navigateToResetPassword");
      return;
    }

    // Store in the global handler
    resetPasswordHandler.setFromDeepLink(token, userId);

    // Set the token and userId for the reset password screen
    setState(() {
      _resetPasswordToken = token;
      _resetPasswordUserId = userId;
    });

    // Create a fresh ResetPasswordScreen to ensure clean state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });

    // Force two more rebuilds with slight delays to ensure UI updates
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() {});
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() {});
    });

    // Final rebuild to catch any edge cases
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // Final check that we're showing the reset password screen
        if (resetPasswordHandler.hasResetPasswordData() &&
            resetPasswordHandler.isFromDeepLink) {
          setState(() {});
        }
      }
    });
  }

  // Method to clear reset password data
  void clearResetPasswordData() {
    print("_MyAppState: Clearing reset password data");

    // Clear the global handler
    resetPasswordHandler.clear();

    // Clear the state variables
    setState(() {
      _resetPasswordToken = null;
      _resetPasswordUserId = null;
    });
  }

  // Method to navigate to sign in screen in onboarding
  void navigateToSignIn() {
    print("_MyAppState: Navigating to sign in screen");

    // Clear any reset password data first
    clearResetPasswordData();

    // Navigate directly to SignInScreen instead of using flags
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }
}

// Widget to handle verification code display
class VerificationHandler extends StatefulWidget {
  final String? verificationCode;
  final Widget child;

  const VerificationHandler({
    super.key,
    this.verificationCode,
    required this.child,
  });

  @override
  State<VerificationHandler> createState() => _VerificationHandlerState();
}

class _VerificationHandlerState extends State<VerificationHandler> {
  String? _storedVerificationCode;
  bool _hasAttemptedNavigation = false;

  @override
  void initState() {
    super.initState();
    _storedVerificationCode = widget.verificationCode;
  }

  @override
  void didUpdateWidget(VerificationHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update stored code if it changes
    if (widget.verificationCode != null &&
        widget.verificationCode != oldWidget.verificationCode) {
      setState(() {
        _storedVerificationCode = widget.verificationCode;
        _hasAttemptedNavigation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we have a verification code, navigate to verification success screen
    if (_storedVerificationCode != null && !_hasAttemptedNavigation) {
      setState(() {
        _hasAttemptedNavigation = true;
      });

      print(
        "VerificationHandler: Processing verification code: $_storedVerificationCode",
      );

      // Try multiple navigation attempts with delays
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _attemptNavigation(context);
      });

      // Additional delayed attempts
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _attemptNavigation(context);
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _attemptNavigation(context);
      });
    }

    return widget.child;
  }

  void _attemptNavigation(BuildContext context) {
    if (_storedVerificationCode != null && context.mounted) {
      try {
        print("VerificationHandler: Attempting navigation");
        DeepLinkHandler.handleVerificationFromCode(
          _storedVerificationCode,
          context,
        );
      } catch (e) {
        print("VerificationHandler: Navigation attempt failed: $e");
      }
    }
  }
}
