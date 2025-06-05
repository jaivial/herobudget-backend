import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/income_model.dart';

class IncomeService {
  static String get baseUrl => ApiConfig.incomeManagementServiceUrl;

  // Add a new income
  Future<Income> addIncome(Income income) async {
    try {
      // Get user ID from shared preferences if not provided
      if (income.userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');
        if (userId == null || userId.isEmpty) {
          throw Exception('User not authenticated');
        }
        // Update the income with the user ID
        income = income.copyWith(userId: userId);
      }

      final response = await http.post(
        Uri.parse(ApiConfig.incomeAddEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(income.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Income.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to add income');
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding income: $e');
    }
  }

  // Get all incomes for a user
  Future<List<Income>> getIncomes() async {
    try {
      // Get user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null || userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.incomeFetchEndpoint}?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> incomesData = responseData['data'];
          return incomesData.map((data) => Income.fromJson(data)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting incomes: $e');
    }
  }

  // Update an existing income
  Future<Income> updateIncome(Income income) async {
    try {
      if (income.id == null) {
        throw Exception('Income ID is required for update');
      }

      final response = await http.post(
        Uri.parse(ApiConfig.incomeUpdateEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': income.userId,
          'income_id': income.id,
          'amount': income.amount,
          'date': income.date,
          'category': income.category,
          'payment_method': income.paymentMethod,
          'description': income.description,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Income.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to update income');
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating income: $e');
    }
  }

  // Delete an income
  Future<bool> deleteIncome(int incomeId, String userId) async {
    try {
      // Get user ID from shared preferences if not provided
      if (userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user_id') ?? '';
        if (userId.isEmpty) {
          throw Exception('User not authenticated');
        }
      }

      final response = await http.post(
        Uri.parse(ApiConfig.incomeDeleteEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'income_id': incomeId}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting income: $e');
    }
  }
}
