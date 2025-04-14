import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/verification/email_verification_screen.dart';
import 'screens/verification/email_verification_success_screen.dart';
import 'screens/reset_password/reset_password_screen.dart';
import 'utils/deep_link_handler.dart';
import 'theme/app_theme.dart';
import 'services/language_service.dart';
import 'services/signin_service.dart';
import 'services/dashboard_service.dart';
import 'services/auth_service.dart';

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

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
}

class _MyAppState extends State<MyApp> {
  bool _initialURILinkHandled = false;
  String? _verificationCode;
  StreamSubscription? _deepLinkSubscription;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  // Flag to prevent concurrent navigation
  bool _isHandlingDeepLink = false;

  // Reset password parameters
  String? _resetPasswordToken;
  String? _resetPasswordUserId;

  // Flag to show sign-in screen on next build
  bool _showSignIn = false;

  // Add a public method that can be called to force showing the verification success screen
  void showVerificationSuccessScreen(String code) {
    setState(() {
      _verificationCode = code;
    });
  }

  @override
  void initState() {
    super.initState();

    print("MyApp initState - starting app initialization");

    // First handle deep links, then check user status
    _initializeDeepLinking().then((_) {
      // After deep link handling, migrate data and check user
      _migrateOldUserData().then((_) {
        _checkUserAndLanguage();
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

  Future<void> _checkUserAndLanguage() async {
    try {
      // First check if user is already signed in using the enhanced SignInService
      final bool isSignedIn = await SignInService.isSignedIn();

      if (isSignedIn) {
        // Get the actual user ID using dashboard service which checks all possible storage locations
        final userId = await DashboardService.getCurrentUserId();

        if (userId != null && userId.isNotEmpty) {
          print('Startup: Found user ID: $userId in localStorage');

          try {
            // Get the latest user info from the server using this ID
            final userInfo = await DashboardService.fetchUserInfo(userId);

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
    // Handle app cold start from deep link
    if (!_initialURILinkHandled) {
      _initialURILinkHandled = true;
      try {
        print("Checking for initial URI from deep link...");
        final initialURI = await getInitialUri();
        if (initialURI != null) {
          print("Found initial URI: $initialURI");
          _processDeepLink(initialURI.toString());
        } else {
          print("No initial URI found");
        }
      } catch (e) {
        print('Failed to get initial deep link: $e');
      }
    }

    // Handle deep links when app is already running
    print("Setting up stream listener for deep links");
    _deepLinkSubscription = uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          print("Received deep link from stream: $uri");
          _processDeepLink(uri.toString());
        }
      },
      onError: (err) {
        print('Error handling deep link: $err');
      },
    );
  }

  void _processDeepLink(String link) {
    if (_isHandlingDeepLink) {
      return; // Prevent concurrent processing
    }

    _isHandlingDeepLink = true;
    print("Processing deep link: $link");

    // Use the enhanced process method from DeepLinkHandler
    final linkData = DeepLinkHandler.processDeepLink(link);

    if (linkData != null) {
      final linkType = linkData['type'];

      if (linkType == 'verification') {
        // Handle verification deep link
        final verificationCode = linkData['code'];
        print("Extracted verification code: $verificationCode");

        // IMPORTANT: Directly store this verification code in the global handler
        verificationCodeHandler.currentVerificationCode = verificationCode;

        // Simply set the verification code and rebuild
        setState(() {
          _verificationCode = verificationCode;
        });
      } else if (linkType == 'password_reset') {
        // Handle password reset deep link - process it directly here
        final token = linkData['token'];
        final userId = linkData['user_id'];
        print("Extracted password reset token: $token and user_id: $userId");

        // Immediately clear the app state to avoid conflicts
        // This is important to ensure we start with a clean slate
        setState(() {
          // Clear any existing data first
          clearResetPasswordData();

          // Now set the new data
          resetPasswordHandler.setFromDeepLink(token, userId);
          _resetPasswordToken = token;
          _resetPasswordUserId = userId;
        });

        // Force a complete rebuild of the app with a brand new ResetPasswordScreen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print("Post-frame callback for password reset");
          if (mounted) {
            setState(() {});
          }
        });

        // Additional rebuilds to ensure UI updates
        for (var delay in [50, 150, 300, 500]) {
          Future.delayed(Duration(milliseconds: delay), () {
            print("Delayed rebuild after $delay ms");
            if (mounted) {
              setState(() {});
            }
          });
        }
      }
    } else {
      print("No recognized deep link content in: $link");
    }

    // Release flag after a delay to prevent rapid processing
    Future.delayed(const Duration(milliseconds: 800), () {
      _isHandlingDeepLink = false;
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check for verification and reset password data in global handlers on every build
    final codeFromHandler = verificationCodeHandler.currentVerificationCode;
    final resetTokenFromHandler = resetPasswordHandler.currentResetToken;
    final resetUserIdFromHandler = resetPasswordHandler.currentUserId;

    // Process verification code if available
    if (codeFromHandler != null &&
        codeFromHandler.isNotEmpty &&
        (_verificationCode == null || _verificationCode!.isEmpty)) {
      if (verificationCodeHandler.isFromDeepLink) {
        print("Found verification code from deep link: $codeFromHandler");
        _verificationCode = codeFromHandler;
      } else {
        print(
          "Found verification code but not from deep link, ignoring for navigation",
        );
      }
    }

    // Process reset password data if available
    if (resetTokenFromHandler != null &&
        resetUserIdFromHandler != null &&
        resetPasswordHandler.isFromDeepLink) {
      print(
        "Found reset password data from handler - updating state variables",
      );

      // Always update state variables with the handler values
      // This ensures the most recent data is used
      _resetPasswordToken = resetTokenFromHandler;
      _resetPasswordUserId = resetUserIdFromHandler;
    }

    if (_isLoading) {
      return MaterialApp(
        title: 'Hero Budget',
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ),
      );
    }

    // Create appropriate home screen based on state
    Widget homeScreen;

    // Priority 1: If reset password handler has data from deep link, show the reset password screen
    if (resetPasswordHandler.hasResetPasswordData() &&
        resetPasswordHandler.isFromDeepLink) {
      print(
        "Building reset password screen with token from handler: ${resetPasswordHandler.currentResetToken} and user ID: ${resetPasswordHandler.currentUserId}",
      );
      // ALWAYS use the values directly from the handler to prevent state sync issues
      homeScreen = ResetPasswordScreen(
        token: resetPasswordHandler.currentResetToken,
        userIdString: resetPasswordHandler.currentUserId,
      );
    }
    // Priority 2: If verification code exists FROM DEEP LINK, show verification success screen
    else if (_verificationCode != null &&
        _verificationCode!.isNotEmpty &&
        verificationCodeHandler.isFromDeepLink) {
      print(
        "Showing verification success screen with code: $_verificationCode",
      );
      homeScreen = EmailVerificationSuccessScreen(
        verificationCode: _verificationCode!,
      );
    }
    // Priority 3: If user is logged in but not verified, show verification screen
    else if (_isLoggedIn && _userData != null) {
      final bool isEmailVerified = _userData!['verified_email'] ?? false;

      if (!isEmailVerified) {
        homeScreen = EmailVerificationScreen(
          userId: _userData!['id'].toString(),
          userInfo: _userData!,
        );
      } else {
        // User is logged in and verified, show dashboard
        homeScreen = DashboardScreen(
          userId: _userData!['id'].toString(),
          userInfo: _userData!,
        );
      }
    }
    // Priority 4: Not logged in, show onboarding
    else {
      homeScreen = OnboardingScreen(initialShowSignIn: _showSignIn);

      // Reset the flag after using it
      if (_showSignIn) {
        print("Resetting _showSignIn flag after creating OnboardingScreen");
        // Reset the flag after a short delay to avoid rebuilding issues
        Future.delayed(Duration.zero, () {
          if (mounted) {
            setState(() {
              _showSignIn = false;
            });
          }
        });
      }
    }

    return MaterialApp(
      title: 'Hero Budget',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
      home: homeScreen,
    );
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

    // Set flag to show sign-in screen on next build
    setState(() {
      _showSignIn = true;

      // Force the app to rebuild with OnboardingScreen
      _isLoggedIn = false;
      _userData = null;
      _resetPasswordToken = null;
      _resetPasswordUserId = null;
    });
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
