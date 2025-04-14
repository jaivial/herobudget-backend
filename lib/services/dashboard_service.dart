import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class DashboardService {
  static String get baseUrl => ApiConfig.fetchDashboardServiceUrl;

  // Constants for localStorage keys - consistent across the app
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';

  // Fetch user information from the backend
  static Future<Map<String, dynamic>> fetchUserInfo(String userId) async {
    try {
      // Debug
      print('Fetching user info for ID: $userId');

      // Check for invalid ID values
      if (userId == "null" || userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/info?id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        print('User not found: ${response.statusCode} - ${response.body}');
        throw Exception('User not found');
      } else {
        print(
          'Failed to fetch user info: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to fetch user information');
      }
    } catch (e) {
      print('Error fetching user info: $e');
      throw Exception('Error connecting to server: $e');
    }
  }

  // Get current user ID from localStorage
  static Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get user_id from SharedPreferences
      String? userId = prefs.getString(userIdKey);

      if (userId != null && userId.isNotEmpty && userId != "null") {
        print('Found user_id in SharedPreferences: $userId');
        return userId;
      }

      // If user_id is not found, try to extract it from user_data
      String? userDataString = prefs.getString(userDataKey);

      if (userDataString != null && userDataString.isNotEmpty) {
        try {
          final userData = jsonDecode(userDataString);
          if (userData != null &&
              userData['id'] != null &&
              userData['id'].toString() != "null") {
            userId = userData['id'].toString();
            print('Extracted user_id from user data: $userId');

            // Store it for future use
            await prefs.setString(userIdKey, userId);

            return userId;
          }
        } catch (e) {
          print('Error parsing user data: $e');
        }
      }

      print('No user ID found in SharedPreferences');
      return null;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  // Get user info from server using stored ID
  static Future<UserModel?> getCurrentUserInfo() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        print('No user ID available to fetch info');
        return null;
      }

      final userInfo = await fetchUserInfo(userId);
      return UserModel.fromJson(userInfo);
    } catch (e) {
      print('Error getting current user info: $e');
      return null;
    }
  }
}
