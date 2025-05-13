import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/dashboard_model.dart';

class CashBankService {
  static String get baseUrl => ApiConfig.cashBankManagementUrl;

  // Fetch cash and bank distribution data
  Future<CashBankDistribution> fetchCashBankDistribution() async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.get(
        Uri.parse('$baseUrl/cash-bank/distribution?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        // Parse JSON response
        final Map<String, dynamic> data = json.decode(response.body);
        return CashBankDistribution.fromJson(data);
      } else {
        throw Exception(
          'Error fetching cash-bank distribution: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in fetchCashBankDistribution: $e');
      throw Exception('Error fetching cash-bank distribution: $e');
    }
  }

  // Update cash amount
  Future<bool> updateCashAmount(double amount) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/cash/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'amount': amount,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error updating cash amount: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateCashAmount: $e');
      return false;
    }
  }

  // Update bank amount
  Future<bool> updateBankAmount(double amount) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/bank/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'amount': amount,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error updating bank amount: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateBankAmount: $e');
      return false;
    }
  }

  // Transfer from cash to bank
  Future<bool> transferCashToBank(double amount) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/transfer/cash-to-bank'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'amount': amount,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Error transferring cash to bank: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in transferCashToBank: $e');
      return false;
    }
  }

  // Transfer from bank to cash
  Future<bool> transferBankToCash(double amount) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/transfer/bank-to-cash'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'amount': amount,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Error transferring bank to cash: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in transferBankToCash: $e');
      return false;
    }
  }
}
