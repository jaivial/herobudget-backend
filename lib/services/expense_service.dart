import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/expense_model.dart';

class ExpenseService {
  static String get baseUrl => ApiConfig.expenseManagementServiceUrl;

  // Add a new expense
  Future<Expense> addExpense(Expense expense) async {
    try {
      // Get user ID from shared preferences if not provided
      if (expense.userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');
        if (userId == null || userId.isEmpty) {
          throw Exception('User not authenticated');
        }
        // Update the expense with the user ID
        expense = expense.copyWith(userId: userId);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/expenses/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(expense.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Expense.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to add expense');
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding expense: $e');
    }
  }

  // Get all expenses for a user
  Future<List<Expense>> getExpenses() async {
    try {
      // Get user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null || userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/expenses?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> expensesData = responseData['data'];
          return expensesData.map((data) => Expense.fromJson(data)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting expenses: $e');
    }
  }

  // Update an existing expense
  Future<Expense> updateExpense(Expense expense) async {
    try {
      if (expense.id == null) {
        throw Exception('Expense ID is required for update');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/expenses/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': expense.userId,
          'expense_id': expense.id,
          'amount': expense.amount,
          'date': expense.date,
          'category': expense.category,
          'payment_method': expense.paymentMethod,
          'description': expense.description,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Expense.fromJson(responseData['data']);
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to update expense',
          );
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating expense: $e');
    }
  }

  // Delete an expense
  Future<bool> deleteExpense(int expenseId, String userId) async {
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
        Uri.parse('$baseUrl/expenses/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'expense_id': expenseId}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting expense: $e');
    }
  }
}
