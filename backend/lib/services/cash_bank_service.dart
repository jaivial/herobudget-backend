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
        Uri.parse(ApiConfig.cashBankDistributionEndpoint + '?user_id=$userId'),
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
        Uri.parse(ApiConfig.cashUpdateEndpoint),
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
        Uri.parse(ApiConfig.bankUpdateEndpoint),
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

      // Validate amount
      if (amount <= 0) {
        throw Exception('Amount must be greater than zero');
      }

      print(
        '🔄 Transferring \$${amount.toStringAsFixed(2)} from cash to bank for user: $userId',
      );

      // Make HTTP request - Use ApiConfig transfer endpoint
      final response = await http.post(
        Uri.parse(ApiConfig.transferCashToBankEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'amount': amount,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      print('📡 Transfer response status: ${response.statusCode}');
      print('📦 Transfer response body: ${response.body}');

      // Check if response is successful
      if (response.statusCode == 200) {
        print('✅ Transfer successful');
        return true;
      } else {
        // Try to parse error message from response
        String errorMessage =
            'Error transferring cash to bank: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // If can't parse JSON, use default message
        }

        print('❌ Transfer failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error in transferCashToBank: $e');
      rethrow; // Re-throw to preserve the original error
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

      // Validate amount
      if (amount <= 0) {
        throw Exception('Amount must be greater than zero');
      }

      print(
        '🔄 Transferring \$${amount.toStringAsFixed(2)} from bank to cash for user: $userId',
      );

      // Make HTTP request - Use ApiConfig transfer endpoint
      final response = await http.post(
        Uri.parse(ApiConfig.transferBankToCashEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'amount': amount,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      print('📡 Transfer response status: ${response.statusCode}');
      print('📦 Transfer response body: ${response.body}');

      // Check if response is successful
      if (response.statusCode == 200) {
        print('✅ Transfer successful');
        return true;
      } else {
        // Try to parse error message from response
        String errorMessage =
            'Error transferring bank to cash: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // If can't parse JSON, use default message
        }

        print('❌ Transfer failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error in transferBankToCash: $e');
      rethrow; // Re-throw to preserve the original error
    }
  }
}
