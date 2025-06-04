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
        Uri.parse(ApiConfig.signupCheckVerificationEndpoint),
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
        Uri.parse(ApiConfig.signupResendVerificationEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print(
        'Resend verification code response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        String errorMessage = 'Failed to resend verification code';
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
      print('Error resending verification code: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Verify email with code
  static Future<Map<String, dynamic>> verifyEmail(String code) async {
    try {
      print('🔐 Starting verification attempt with OTP code: $code');

      // First, check if we have a locally stored userId and email
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userDataStr = prefs.getString('user_data');
      String? email;

      print('📱 Checking local storage for user data...');
      print('   - User ID: $userId');
      print(
        '   - User Data String: ${userDataStr != null ? 'Found' : 'Not found'}',
      );

      if (userDataStr != null) {
        try {
          final userData = jsonDecode(userDataStr);
          email = userData['email'] as String?;
          print('✅ Found locally stored email: $email for OTP verification');
        } catch (e) {
          print('❌ Error parsing user data: $e');
        }
      }

      if (email == null) {
        print(
          '⚠️  Warning: No email found in local storage, proceeding with null email',
        );
      }

      // Try multiple possible parameter formats that the server might expect
      final requestBody = {
        'email': email,
        'code': code, // Primary parameter name
        'verification_code': code, // Fallback parameter name
        'otp': code, // Alternative parameter name
      };

      print(
        '📤 Sending verification request to: ${ApiConfig.signupVerifyEmailEndpoint}',
      );
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(ApiConfig.signupVerifyEmailEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 Verify email response:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Body: ${response.body}');
      print('   - Headers: ${response.headers}');

      if (response.statusCode == 200) {
        // Successful verification
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'user': responseData,
          'user_id': responseData['user_id'] ?? responseData['id'],
        };
      } else if (response.statusCode == 404) {
        // Special case for 404 - code not found
        print('Verification OTP code not found in database: $code');

        // If we have a user ID and email, try to resend
        if (userId != null && email != null) {
          print('Attempting to resend verification code to $email');

          try {
            final resendResult = await resendVerificationEmail(userId, email);
            if (resendResult['success'] == true) {
              print('Successfully resent verification code');
              return {
                'success': false,
                'error':
                    'Verification code expired. A new verification code has been sent to your email address.',
              };
            } else {
              print(
                'Failed to resend verification code: ${resendResult['error']}',
              );
            }
          } catch (e) {
            print('Error resending verification code: $e');
          }
        }

        return {
          'success': false,
          'error':
              'Invalid verification code. Please request a new verification code.',
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
          print('Error parsing error response: $e');
        }

        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      print('Error in verifyEmail: $e');
      return {'success': false, 'error': 'Network or server error: $e'};
    }
  }
}
