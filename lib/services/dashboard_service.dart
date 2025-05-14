import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  static String get baseUrl => ApiConfig.fetchDashboardServiceUrl;
  static String get dashboardDataUrl => ApiConfig.dashboardDataServiceUrl;

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

  // Update user information on the backend
  static Future<Map<String, dynamic>> updateUserInfo(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      print('Updating user info for ID: $userId with data: $updateData');

      // Check for invalid ID values
      if (userId == "null" || userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': userId, ...updateData}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Update the local stored user data if we have it
        try {
          final prefs = await SharedPreferences.getInstance();
          final storedUserData = prefs.getString(userDataKey);

          if (storedUserData != null && storedUserData.isNotEmpty) {
            final userData = jsonDecode(storedUserData);

            // Update with new values
            final updatedUserData = {...userData, ...updateData};

            // Save back to storage
            await prefs.setString(userDataKey, jsonEncode(updatedUserData));
            print('Updated local user data with new values');
          }
        } catch (e) {
          print('Error updating local user data: $e');
          // Continue even if local update fails
        }

        return responseData;
      } else {
        print(
          'Failed to update user info: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to update user information');
      }
    } catch (e) {
      print('Error updating user info: $e');
      throw Exception('Error connecting to server: $e');
    }
  }

  // Get dashboard data
  Future<DashboardModel> fetchDashboardData({String period = 'monthly'}) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request using dashboard data service URL
      final response = await http.get(
        Uri.parse(
          '${dashboardDataUrl}/dashboard/data?user_id=$userId&period=$period',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        // Parse JSON response
        final Map<String, dynamic> data = json.decode(response.body);
        return DashboardModel.fromJson(data);
      } else {
        throw Exception(
          'Error fetching dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      // In case of error, return a model with default values
      print('Error in fetchDashboardData: $e');
      throw Exception('Error fetching dashboard data: $e');
    }
  }

  // Change time period
  Future<DashboardModel> changePeriod(String period) async {
    return await fetchDashboardData(period: period);
  }

  // Update savings goal
  Future<bool> updateSavingsGoal(double goal) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/savings/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'goal': goal}),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error updating savings goal: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateSavingsGoal: $e');
      return false;
    }
  }

  // Register a new expense
  Future<bool> addExpense({
    required String name,
    required double amount,
    required String category,
    String? notes,
  }) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/expenses/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'name': name,
          'amount': amount,
          'category': category,
          'notes': notes,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error adding expense: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in addExpense: $e');
      return false;
    }
  }

  // Register a new income
  Future<bool> addIncome({
    required String name,
    required double amount,
    required String category,
    String? notes,
  }) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/income/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'name': name,
          'amount': amount,
          'category': category,
          'notes': notes,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error adding income: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in addIncome: $e');
      return false;
    }
  }

  // Add a new bill
  Future<bool> addBill({
    required String name,
    required double amount,
    required String dueDate,
    required String category,
    required String icon,
    required bool recurring,
  }) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/bills/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'name': name,
          'amount': amount,
          'due_date': dueDate,
          'category': category,
          'icon': icon,
          'recurring': recurring,
          'paid': false,
          'overdue': false,
          'overdue_days': 0,
        }),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error adding bill: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in addBill: $e');
      return false;
    }
  }

  // Mark a bill as paid
  Future<bool> payBill(int billId) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/bills/pay'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'bill_id': billId}),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error paying bill: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in payBill: $e');
      return false;
    }
  }
}
