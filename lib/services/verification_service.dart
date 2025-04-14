import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerificationService {
  // Check verification status
  static Future<bool> checkVerificationStatus(String userId) async {
    try {
      // Make an API call to check verification status
      final response = await http.post(
        Uri.parse('${ApiConfig.signupServiceUrl}/signup/check-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      print(
        'Check verification response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if the verification status is included in the response
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('verified')) {
            return responseData['verified'] == true;
          } else if (responseData.containsKey('verified_email')) {
            return responseData['verified_email'] == true;
          } else if (responseData.containsKey('is_verified')) {
            return responseData['is_verified'] == true;
          } else if (responseData.containsKey('email_verified')) {
            return responseData['email_verified'] == true;
          }
        }
      }

      // Default to false if we can't determine the status
      return false;
    } catch (e) {
      print('Error checking verification status: $e');
      return false;
    }
  }

  // Resend verification email
  static Future<Map<String, dynamic>> resendVerificationEmail(
    String userId,
    String email,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.signupServiceUrl}/signup/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'email': email}),
      );

      print(
        'Resend verification response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        String errorMessage = 'Failed to resend verification email';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> &&
              errorData.containsKey('error')) {
            errorMessage = errorData['error'] ?? errorMessage;
          }
        } catch (e) {
          // If we can't parse the response, use the default error message
        }
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      print('Error resending verification email: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Verify email with code
  static Future<Map<String, dynamic>> verifyEmail(String code) async {
    try {
      print('Starting verification attempt with code: $code');

      // First, check if we have a locally stored userId and email
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userDataStr = prefs.getString('user_data');
      String? email;

      if (userDataStr != null) {
        try {
          final userData = jsonDecode(userDataStr);
          email = userData['email'] as String?;
          print('Found locally stored email: $email for verification');
        } catch (e) {
          print('Error parsing user data: $e');
        }
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.signupServiceUrl}/signup/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'user_id': userId, // Include user_id if available
          'email': email, // Include email if available
        }),
      );

      print('Verify email response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // Parse the response data
        try {
          final responseData = jsonDecode(response.body);
          print('Verification successful! User ID: ${responseData['user_id']}');

          // Format the data to match what the SuccessScreen expects
          Map<String, dynamic> userData = {
            'user_id':
                responseData['user_id'] ?? responseData['id'] ?? userId ?? '0',
            'email': responseData['email'] ?? email ?? '',
            'verified_email': true,
          };

          // Merge any additional user data from the response
          if (responseData is Map<String, dynamic>) {
            userData.addAll(responseData);
          }

          return {'success': true, 'user': userData};
        } catch (e) {
          print('Error parsing success response: $e');

          // Even if we can't parse the response, consider it a success
          // if we got a 200 OK response
          return {
            'success': true,
            'user': {
              'user_id': userId ?? '0',
              'email': email ?? 'user@example.com',
              'verified_email': true,
            },
          };
        }
      } else if (response.statusCode == 404) {
        // Special case for 404 - code not found
        print('Verification code not found in database: $code');

        // If we have a user ID and email, try to resend
        if (userId != null && email != null) {
          print('Attempting to resend verification email to $email');

          try {
            final resendResult = await resendVerificationEmail(userId, email);
            if (resendResult['success'] == true) {
              print('Successfully resent verification email');
              return {
                'success': false,
                'error':
                    'Verification code expired. A new verification email has been sent to your email address.',
              };
            } else {
              print(
                'Failed to resend verification email: ${resendResult['error']}',
              );
            }
          } catch (e) {
            print('Error resending verification email: $e');
          }
        }

        return {
          'success': false,
          'error':
              'Invalid verification code. Please request a new verification email.',
        };
      } else {
        // Handle other error responses
        String errorMessage = 'Failed to verify email';
        try {
          // Try to parse JSON response
          if (response.body.trim().startsWith('{')) {
            final errorData = jsonDecode(response.body);
            if (errorData is Map<String, dynamic> &&
                errorData.containsKey('error')) {
              errorMessage = errorData['error'] ?? errorMessage;
            } else if (errorData is Map<String, dynamic> &&
                errorData.containsKey('message')) {
              errorMessage = errorData['message'] ?? errorMessage;
            }
          } else {
            // If not JSON, use the response body directly
            errorMessage = response.body.trim();
          }
        } catch (e) {
          // If we can't parse the response, use the raw response body
          print('Error parsing error response: $e');
          errorMessage = response.body.trim();
        }

        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      print('Error verifying email: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
}
