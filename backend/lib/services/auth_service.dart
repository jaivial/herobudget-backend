import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
      final url = ApiConfig.signupCheckEmailEndpoint;
      print("Checking email at URL: $url");

      // First try to ping the service to check if it's reachable
      try {
        final pingResponse = await http
            .get(Uri.parse('${ApiConfig.signupServiceUrl}'))
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
            .get(Uri.parse('${ApiConfig.signupServiceUrl}'))
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
    print('Sending to URL: ${ApiConfig.signupRegisterEndpoint}');

    try {
      print('Making HTTP POST request to register user...');
      final response = await http.post(
        Uri.parse(ApiConfig.signupRegisterEndpoint),
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
            .get(Uri.parse('${ApiConfig.signupServiceUrl}'))
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
        Uri.parse(ApiConfig.googleAuthEndpoint),
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
      print('Iniciando proceso de cierre de sesión');
      final prefs = await SharedPreferences.getInstance();

      // Eliminar información de usuario
      await prefs.remove(userIdKey);
      await prefs.remove(userDataKey);

      // Eliminar también claves antiguas por si acaso
      await prefs.remove('user_info');
      await prefs.remove('user');

      // Limpiar cualquier otra información de sesión
      // pero mantener preferencias como idioma y tema

      // Cerrar sesión de Google si está activa
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
          print('Sesión de Google cerrada');
        }
      } catch (e) {
        print('Error al cerrar sesión de Google: $e');
      }

      print('Sesión cerrada exitosamente');
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // Get current user from local storage
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');

      if (userJson != null && userJson.isNotEmpty) {
        print(
          'Retrieved user data from SharedPreferences. Length: ${userJson.length}',
        );
        final Map<String, dynamic> userData = json.decode(userJson);

        // Verificar si hay información de imagen
        if (userData.containsKey('picture')) {
          print(
            'picture field exists: ${userData['picture'] != null ? 'not null' : 'null'}',
          );
          if (userData['picture'] != null) {
            final picturePreview = userData['picture'].toString().substring(
              0,
              min(10, userData['picture'].toString().length),
            );
            print('picture preview: $picturePreview...');
          }
        }

        if (userData.containsKey('display_image')) {
          print(
            'display_image field exists: ${userData['display_image'] != null ? 'not null' : 'null'}',
          );
          if (userData['display_image'] != null) {
            final displayImagePreview = userData['display_image']
                .toString()
                .substring(
                  0,
                  min(10, userData['display_image'].toString().length),
                );
            print('display_image preview: $displayImagePreview...');
          }
        }

        if (userData.containsKey('profile_image_blob')) {
          print(
            'profile_image_blob field exists: ${userData['profile_image_blob'] != null ? 'not null' : 'null'}',
          );
          if (userData['profile_image_blob'] != null) {
            final blobPreview = userData['profile_image_blob']
                .toString()
                .substring(
                  0,
                  min(10, userData['profile_image_blob'].toString().length),
                );
            print('profile_image_blob preview: $blobPreview...');
          }
        }

        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}
