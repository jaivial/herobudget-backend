import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../config/api_config.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '204913639838-lt4jcl1cc0b9qjq4lh8ef6u19trudech.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // Constants for localStorage keys
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';

  // Check if email already exists
  static Future<bool> checkEmailExists(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      print("Invalid email format: $email");
      return false;
    }

    try {
      final url = '${ApiConfig.signupServiceUrl}/signup/check-email';
      print("Checking email at URL: $url");

      // First try to ping the service to check if it's reachable
      try {
        final pingResponse = await http
            .get(Uri.parse('${ApiConfig.signupServiceUrl}/ping'))
            .timeout(const Duration(seconds: 5));
        print('Ping response: ${pingResponse.statusCode}');
      } catch (pingError) {
        print('Ping error - service might be down or unreachable: $pingError');
        // Continue with the main request anyway
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      print('Email check response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      } else {
        print('Server error: ${response.statusCode} - ${response.body}');
        // Return false on server error so user can continue
        return false;
      }
    } catch (e) {
      print('Error checking email: $e');
      // For debugging connectivity issues - this is redundant but kept for back-compatibility
      try {
        final pingResponse = await http
            .get(Uri.parse('${ApiConfig.signupServiceUrl}/ping'))
            .timeout(const Duration(seconds: 3));
        print('Secondary ping response: ${pingResponse.statusCode}');
      } catch (pingError) {
        print(
          'Secondary ping error - service is definitely down or unreachable: $pingError',
        );
      }
      // Return false on error so user can continue
      return false;
    }
  }

  // Handle manual signup
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String givenName,
    required String familyName,
    required String locale,
    required bool verifiedEmail,
    File? profileImage,
  }) async {
    // Combine first and last name to create full name
    final fullName = '$givenName $familyName'.trim();

    String? base64Image;
    // Convert profile image to base64 if available
    if (profileImage != null) {
      final bytes = await profileImage.readAsBytes();
      base64Image = base64Encode(bytes);
      print('Profile image converted to base64 (${bytes.length} bytes)');
    } else {
      print('No profile image provided');
    }

    final signupData = {
      'email': email,
      'password': password,
      'name': fullName,
      'given_name': givenName,
      'family_name': familyName,
      'locale': locale,
      'verified_email': verifiedEmail,
    };

    if (base64Image != null) {
      signupData['picture_base64'] = base64Image;
    }

    print('Prepared signup data with email: $email, name: $fullName');
    print('Sending to URL: ${ApiConfig.signupServiceUrl}/signup/register');

    try {
      print('Making HTTP POST request to register user...');
      final response = await http.post(
        Uri.parse('${ApiConfig.signupServiceUrl}/signup/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(signupData),
      );

      print('Signup response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final userInfo = jsonDecode(response.body);
        final userId = userInfo['id'].toString();
        print('Registration successful for user ID: $userId');

        // Save user info to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(userIdKey, userId);
        await prefs.setString(userDataKey, jsonEncode(userInfo));
        print('User info saved to local storage');

        return {'success': true, 'user': userInfo};
      } else {
        // Other error
        String errorMessage = 'Registration failed';
        try {
          // Try to parse the error message from the response body
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> &&
              errorData.containsKey('error')) {
            errorMessage = errorData['error'] ?? errorMessage;
          } else {
            errorMessage = response.body;
          }
        } catch (e) {
          // If we can't parse the response body, use it as is
          errorMessage = response.body;
        }
        print('Registration failed with error: $errorMessage');
        return {'success': false, 'error': errorMessage};
      }
    } catch (error) {
      print('Exception during signup: $error');
      // Try to ping server to check connectivity
      try {
        print('Attempting to ping server to check connectivity...');
        final pingResponse = await http
            .get(Uri.parse('${ApiConfig.signupServiceUrl}/ping'))
            .timeout(const Duration(seconds: 3));
        print(
          'Ping response: ${pingResponse.statusCode} - ${pingResponse.body}',
        );
      } catch (e) {
        print('Could not reach server: $e');
      }
      return {'success': false, 'error': 'An error occurred: $error'};
    }
  }

  // Handle Google sign in
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('User cancelled sign in');
        return {'success': false, 'error': 'Sign in cancelled'};
      }

      print('Got google user: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print('Got auth tokens');

      // Detect device locale
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final String languageCode = deviceLocale.languageCode;
      final String countryCode = deviceLocale.countryCode ?? 'US';
      final String normalizedLocale = languageCode;

      print('Detected device locale: $normalizedLocale');

      final response = await http.post(
        Uri.parse('${ApiConfig.googleAuthServiceUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': googleAuth.idToken,
          'accessToken': googleAuth.accessToken,
          'deviceLocale': normalizedLocale, // Send normalized locale
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final userInfo = jsonDecode(response.body);
        final userId = userInfo['id'].toString();

        print('GOOGLE AUTH: Received user ID from server: $userId');

        // Save user info to local storage using standardized keys
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(userIdKey, userId);
        await prefs.setString(userDataKey, jsonEncode(userInfo));

        print('GOOGLE AUTH: Saved user info to localStorage with ID: $userId');

        // Verify the data was actually saved
        final savedUserId = prefs.getString(userIdKey);
        final savedUserData = prefs.getString(userDataKey);
        print(
          'GOOGLE AUTH: Verification - user_id in localStorage: $savedUserId',
        );
        print(
          'GOOGLE AUTH: Verification - user_data exists: ${savedUserData != null}',
        );

        return {'success': true, 'user': userInfo};
      } else {
        return {
          'success': false,
          'error': 'Failed to sign in: ${response.body}',
        };
      }
    } catch (error) {
      print('Error during sign in: $error');
      return {'success': false, 'error': 'An error occurred: $error'};
    }
  }

  // Sign out
  static Future<void> signOut(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(userIdKey);
      await prefs.remove(userDataKey);

      // Also sign out from Google if needed
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Get current user from local storage
  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(userDataKey);

    if (userDataString != null) {
      try {
        final userInfo = jsonDecode(userDataString);
        return UserModel.fromJson(userInfo);
      } catch (e) {
        print('Error parsing user info: $e');
      }
    }

    return null;
  }
}
