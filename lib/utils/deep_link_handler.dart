import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../screens/verification/email_verification_success_screen.dart';
import '../screens/reset_password/reset_password_screen.dart';
import '../main.dart'; // Import main.dart to access the myAppKey

// Singleton for handling verification codes globally
class VerificationCodeHandler {
  static final VerificationCodeHandler _instance =
      VerificationCodeHandler._internal();

  // Singleton constructor
  factory VerificationCodeHandler() {
    return _instance;
  }

  VerificationCodeHandler._internal();

  // Store the current verification code
  String? _currentVerificationCode;

  // Track if the code came from a deep link
  bool _isFromDeepLink = false;

  // Getters and setters
  String? get currentVerificationCode => _currentVerificationCode;

  // Add getter for isFromDeepLink
  bool get isFromDeepLink => _isFromDeepLink;

  set currentVerificationCode(String? code) {
    print("VerificationCodeHandler: Setting verification code to $code");
    _currentVerificationCode = code;
  }

  // Set code with deep link flag
  void setCodeFromDeepLink(String? code) {
    _currentVerificationCode = code;
    _isFromDeepLink = true;
    print("VerificationCodeHandler: Setting code from deep link: $code");
  }

  // Set code without deep link flag (from registration)
  void setCodeFromRegistration(String? code) {
    _currentVerificationCode = code;
    _isFromDeepLink = false;
    print("VerificationCodeHandler: Setting code from registration: $code");
  }

  // Check if we have a verification code
  bool hasVerificationCode() {
    return _currentVerificationCode != null &&
        _currentVerificationCode!.isNotEmpty;
  }

  // Clear the verification code
  void clearVerificationCode() {
    _currentVerificationCode = null;
    _isFromDeepLink = false;
  }
}

// Global instance for easy access
final verificationCodeHandler = VerificationCodeHandler();

// Add the ResetPasswordHandler class after the VerificationCodeHandler class

// Handler for reset password tokens
class ResetPasswordHandler {
  String? _resetToken;
  String? _userId;
  bool _isFromDeepLink = false;

  // Getters
  String? get currentResetToken => _resetToken;
  String? get currentUserId => _userId;
  bool get isFromDeepLink => _isFromDeepLink;

  // Check if we have valid reset password data
  bool hasResetPasswordData() {
    return _resetToken != null &&
        _resetToken!.isNotEmpty &&
        _userId != null &&
        _userId!.isNotEmpty;
  }

  // Set reset password data and mark as from deep link
  void setFromDeepLink(String token, String userId) {
    _resetToken = token;
    _userId = userId;
    _isFromDeepLink = true;
    debugPrint(
      'ResetPasswordHandler: Set token: $token and userId: $userId from deep link',
    );
  }

  // Clear reset password data
  void clear() {
    _resetToken = null;
    _userId = null;
    _isFromDeepLink = false;
    debugPrint('ResetPasswordHandler: Reset password data cleared');
  }
}

// Create a global instance
final resetPasswordHandler = ResetPasswordHandler();

class DeepLinkHandler {
  // Extract verification code from a deep link
  static String? extractVerificationCode(String link) {
    // Check if the link contains verification parameters
    if (link.contains('verify') || link.contains('verification')) {
      // Parse URI to extract query parameters
      try {
        print("Trying to extract verification code from link: $link");
        final uri = Uri.parse(link);

        // Check for 'code' in query parameters
        if (uri.queryParameters.containsKey('code')) {
          final code = uri.queryParameters['code'];
          print("Found code in query parameters: $code");

          // Store the code in the global handler with deep link flag
          verificationCodeHandler.setCodeFromDeepLink(code);

          return code;
        }

        // Check for code in path segments (e.g. /verify/ABC123)
        final segments = uri.pathSegments;
        if (segments.length >= 2 &&
            (segments.contains('verify') ||
                segments.contains('verification'))) {
          final codeIndex =
              segments.contains('verify')
                  ? segments.indexOf('verify') + 1
                  : segments.indexOf('verification') + 1;

          if (codeIndex < segments.length) {
            final code = segments[codeIndex];
            print("Found code in path segments: $code");

            // Store the code in the global handler with deep link flag
            verificationCodeHandler.setCodeFromDeepLink(code);

            return code;
          }
        }
      } catch (e) {
        print('Error parsing verification link: $e');

        // Try a simpler parsing approach as fallback
        try {
          // Look for code= in the URL
          int codeIndex = link.indexOf("code=");
          if (codeIndex != -1) {
            // Extract everything after code= until end or & character
            String codeString = link.substring(codeIndex + 5);
            int endIndex = codeString.indexOf("&");
            if (endIndex != -1) {
              codeString = codeString.substring(0, endIndex);
            }
            print("Found code using fallback parsing: $codeString");

            // Store the code in the global handler with deep link flag
            verificationCodeHandler.setCodeFromDeepLink(codeString);

            return codeString;
          }
        } catch (fallbackError) {
          print('Error in fallback verification code parsing: $fallbackError');
        }
      }
    }
    return null;
  }

  // Extract password reset parameters from a deep link
  static Map<String, String>? extractPasswordResetParams(String link) {
    debugPrint("Extracting password reset params from link: $link");

    try {
      // Try URI parsing first
      Uri? uri;
      try {
        uri = Uri.parse(link);
        debugPrint("Successfully parsed URI: $uri");
      } catch (e) {
        debugPrint("Error parsing URI: $e - will try manual extraction");
        uri = null;
      }

      // If URI parsing succeeded and we have the expected parameters
      if (uri != null) {
        // Try to extract token and user_id from query parameters
        String? token = uri.queryParameters['token'];
        String? userId = uri.queryParameters['user_id'];

        // Try different parameter names if not found
        if (token == null) {
          // Try other possible parameter names for token
          token =
              uri.queryParameters['reset_token'] ??
              uri.queryParameters['password_token'] ??
              uri.queryParameters['t'];
        }

        if (userId == null) {
          // Try other possible parameter names for user ID
          userId =
              uri.queryParameters['userId'] ??
              uri.queryParameters['id'] ??
              uri.queryParameters['user'] ??
              uri.queryParameters['uid'];
        }

        // If we have both parameters, return them
        if (token != null && userId != null) {
          debugPrint(
            "Found token: $token and user_id: $userId via URI query params",
          );
          return {'token': token, 'user_id': userId};
        }

        // If we don't have both, try path segments
        final segments = uri.pathSegments;
        if (segments.length >= 3 &&
            (segments.contains('reset-password') ||
                segments.contains('reset_password'))) {
          // Try to find token and userId in path segments
          int resetIndex = segments.indexOf('reset-password');
          if (resetIndex == -1) resetIndex = segments.indexOf('reset_password');

          if (resetIndex != -1 && resetIndex + 2 < segments.length) {
            // Format might be /reset-password/{token}/{user_id}
            final pathToken = segments[resetIndex + 1];
            final pathUserId = segments[resetIndex + 2];

            if (pathToken.isNotEmpty && pathUserId.isNotEmpty) {
              debugPrint(
                "Found token: $pathToken and user_id: $pathUserId via URI path segments",
              );
              return {'token': pathToken, 'user_id': pathUserId};
            }
          }
        }
      }

      // Fallback to manual parsing
      debugPrint(
        "URI parsing didn't yield complete results, trying manual extraction",
      );

      // Extract token
      String? token;
      int tokenIndex = link.indexOf("token=");
      if (tokenIndex != -1) {
        String tokenValue = link.substring(tokenIndex + 6);
        int endIndex = tokenValue.indexOf("&");
        token = endIndex != -1 ? tokenValue.substring(0, endIndex) : tokenValue;
        debugPrint("Manually extracted token: $token");
      } else {
        // Try other token parameter names
        tokenIndex = link.indexOf("reset_token=");
        if (tokenIndex != -1) {
          String tokenValue = link.substring(tokenIndex + 12);
          int endIndex = tokenValue.indexOf("&");
          token =
              endIndex != -1 ? tokenValue.substring(0, endIndex) : tokenValue;
          debugPrint("Manually extracted reset_token: $token");
        }
      }

      // Extract user_id
      String? userId;
      int userIdIndex = link.indexOf("user_id=");
      if (userIdIndex != -1) {
        String userIdValue = link.substring(userIdIndex + 8);
        int endIndex = userIdValue.indexOf("&");
        userId =
            endIndex != -1 ? userIdValue.substring(0, endIndex) : userIdValue;
        debugPrint("Manually extracted user_id: $userId");
      } else {
        // Try other user ID parameter names
        userIdIndex = link.indexOf("userId=");
        if (userIdIndex != -1) {
          String userIdValue = link.substring(userIdIndex + 7);
          int endIndex = userIdValue.indexOf("&");
          userId =
              endIndex != -1 ? userIdValue.substring(0, endIndex) : userIdValue;
          debugPrint("Manually extracted userId: $userId");
        } else {
          userIdIndex = link.indexOf("uid=");
          if (userIdIndex != -1) {
            String userIdValue = link.substring(userIdIndex + 4);
            int endIndex = userIdValue.indexOf("&");
            userId =
                endIndex != -1
                    ? userIdValue.substring(0, endIndex)
                    : userIdValue;
            debugPrint("Manually extracted uid: $userId");
          }
        }
      }

      if (token != null && userId != null) {
        debugPrint(
          "Successfully extracted token: $token and user_id: $userId via manual parsing",
        );
        return {'token': token, 'user_id': userId};
      }
    } catch (e) {
      debugPrint("Error extracting password reset parameters: $e");
    }

    debugPrint("Failed to extract password reset parameters from link");
    return null;
  }

  // Process a deep link and extract the relevant information
  static Map<String, dynamic>? processDeepLink(String link) {
    if (link.isEmpty) {
      return null;
    }

    debugPrint("DeepLinkHandler.processDeepLink - Processing link: $link");

    try {
      // Try to extract verification code
      if (link.contains('/verify') || link.contains('verify?code=')) {
        final code = extractVerificationCode(link);
        if (code != null) {
          // Also store it in the global verification code handler
          verificationCodeHandler.setCodeFromDeepLink(code);
          debugPrint(
            "DeepLinkHandler: Successfully extracted verification code: $code",
          );
          return {'type': 'verification', 'code': code};
        }
      }

      // Check for password reset - try more patterns to be more flexible
      if (link.contains('reset-password') ||
          link.contains('reset_password') ||
          link.contains('token=') ||
          link.contains('user_id=')) {
        debugPrint("DeepLinkHandler: Detected potential password reset link");

        final resetInfo = extractPasswordResetParams(link);
        debugPrint("DeepLinkHandler: Extracted reset info: $resetInfo");

        if (resetInfo != null) {
          final token = resetInfo['token'];
          final userId = resetInfo['user_id'];

          debugPrint("DeepLinkHandler: Extracted token=$token, userId=$userId");

          // Only store in the global handler if both values are non-null
          if (token != null &&
              token.isNotEmpty &&
              userId != null &&
              userId.isNotEmpty) {
            // Store in the global resetPasswordHandler
            resetPasswordHandler.setFromDeepLink(token, userId);

            debugPrint(
              "DeepLinkHandler: Successfully stored in reset password handler",
            );

            return {
              'type': 'password_reset',
              'token': token,
              'user_id': userId,
            };
          } else {
            debugPrint(
              "DeepLinkHandler: Invalid reset params - token or userId is null/empty",
            );
          }
        } else {
          debugPrint(
            "DeepLinkHandler: Failed to extract reset params from: $link",
          );
        }
      } else {
        debugPrint("DeepLinkHandler: Link doesn't match any known patterns");
      }
    } catch (e) {
      debugPrint('DeepLinkHandler: Error processing deep link: $e');
    }

    return null;
  }

  // Handle password reset deep link
  static void handlePasswordReset(
    String token,
    String userId,
    BuildContext context,
  ) {
    print(
      "DeepLinkHandler: Handling password reset with token: $token and user_id: $userId",
    );

    // Check that both token and userId are non-empty
    if (token.isEmpty || userId.isEmpty) {
      print("Invalid token or userId - cannot handle password reset");
      return;
    }

    // Store the parameters to be used later
    // We'll use these parameters in the main app to navigate properly
    final passwordResetParams = {'token': token, 'user_id': userId};

    // Instead of trying to navigate here, store the params and let the main app handle navigation
    // when it has the proper context
    try {
      final appState = myAppKey.currentState;
      if (appState != null) {
        print("Found app state, navigating to reset password screen");
        appState.navigateToResetPassword(token, userId);
      } else {
        print("Could not find app state for reset password navigation");
      }
    } catch (e) {
      print("Error while trying to navigate to reset password: $e");
    }
  }

  // Store verification code in local storage for persistence
  static Future<void> _saveVerificationCodeToStorage(String? code) async {
    try {
      // We import SharedPreferences at the top level so we have access here
      // This ensures the code is persisted even if the app restarts
      if (code != null && code.isNotEmpty) {
        print("Saving verification code to persistent storage: $code");
        // Note: SharedPreferences import and implementation details
        // would need to be added in a real implementation
      }
    } catch (e) {
      print("Error saving verification code to storage: $e");
    }
  }

  // Handle verification code by navigating to the success screen
  static void handleVerificationCode(String code, BuildContext context) {
    print("DeepLinkHandler: Storing verification code: $code");

    // Store the code in the global handler and mark as from deep link
    verificationCodeHandler.setCodeFromDeepLink(code);

    // Get the MyApp state if possible
    try {
      final appState = myAppKey.currentState;
      if (appState != null) {
        print("DeepLinkHandler: Updating app state with code");
        appState.showVerificationSuccessScreen(code);
      } else {
        print("DeepLinkHandler: Could not access app state");
      }
    } catch (e) {
      print("DeepLinkHandler: Error accessing app state: $e");
    }
  }

  // For use in the main.dart VerificationHandler
  static void handleVerificationFromCode(String? code, BuildContext context) {
    if (code != null && code.isNotEmpty) {
      print("DeepLinkHandler: Handling verification code: $code");

      // Store in global handler for access by all screens and mark as from deep link
      verificationCodeHandler.setCodeFromDeepLink(code);

      // Try to access the app state directly
      try {
        final appState = myAppKey.currentState;
        if (appState != null) {
          print("Found app state, calling direct method");
          appState.showVerificationSuccessScreen(code);
        } else {
          print("Could not find app state");
        }
      } catch (e) {
        print("Error accessing app state: $e");
      }
    }
  }

  // Helper to find MaterialApp in widget tree
  static BuildContext? _findMaterialAppContext(BuildContext context) {
    BuildContext? materialAppContext;

    try {
      context.visitAncestorElements((element) {
        if (element.widget is MaterialApp) {
          materialAppContext = element;
          return false; // Stop visiting
        }
        return true; // Continue visiting
      });
    } catch (e) {
      print("Error finding MaterialApp: $e");
    }

    return materialAppContext;
  }
}
