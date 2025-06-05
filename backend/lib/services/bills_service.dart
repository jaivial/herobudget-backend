import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/dashboard_model.dart';

class BillsService {
  static String get baseUrl => ApiConfig.billsManagementUrl;

  // Fetch upcoming bills
  Future<List<Bill>> fetchBills() async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.get(
        Uri.parse('${ApiConfig.billsFetchEndpoint}?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        // Parse JSON response
        final List<dynamic> data = json.decode(response.body);
        return data.map((bill) => Bill.fromJson(bill)).toList();
      } else {
        throw Exception('Error fetching bills: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchBills: $e');
      throw Exception('Error fetching bills: $e');
    }
  }

  // Add new bill
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
        Uri.parse(ApiConfig.billsAddEndpoint),
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

  // Mark bill as paid
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
        Uri.parse(ApiConfig.billsPayEndpoint),
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

  // Update bill details
  Future<bool> updateBill({
    required int billId,
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
        Uri.parse(ApiConfig.billsUpdateEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'bill_id': billId,
          'name': name,
          'amount': amount,
          'due_date': dueDate,
          'category': category,
          'icon': icon,
          'recurring': recurring,
        }),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error updating bill: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateBill: $e');
      return false;
    }
  }

  // Delete bill
  Future<bool> deleteBill(int billId) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make HTTP request
      final response = await http.post(
        Uri.parse(ApiConfig.billsDeleteEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'bill_id': billId}),
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error deleting bill: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteBill: $e');
      return false;
    }
  }
}
