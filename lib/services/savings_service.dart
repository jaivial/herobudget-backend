import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/dashboard_model.dart';

class SavingsService {
  static String get baseUrl => ApiConfig.savingsManagementUrl;

  // Fetch savings data
  Future<SavingsOverview> fetchSavings() async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.get(
        Uri.parse('$baseUrl/savings/data?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        // Parse JSON response
        final Map<String, dynamic> data = json.decode(response.body);
        return SavingsOverview.fromJson(data);
      } else {
        throw Exception('Error fetching savings data: ${response.statusCode}');
      }
    } catch (e) {
      // In case of error, return a model with default values
      print('Error in fetchSavings: $e');
      throw Exception('Error fetching savings data: $e');
    }
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
        Uri.parse('$baseUrl/savings/goal/update'),
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

  // Add savings amount
  Future<bool> addSavingsAmount(double amount, String description) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/savings/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'amount': amount,
          'description': description,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error adding savings amount: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in addSavingsAmount: $e');
      return false;
    }
  }

  // Withdraw savings amount
  Future<bool> withdrawSavingsAmount(double amount, String description) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/savings/withdraw'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'amount': amount,
          'description': description,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Error withdrawing savings amount: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in withdrawSavingsAmount: $e');
      return false;
    }
  }
}
