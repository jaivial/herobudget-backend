import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  static String get baseUrl => ApiConfig.fetchDashboardServiceUrl;
  static String get dashboardDataUrl => ApiConfig.dashboardDataServiceUrl;
  static String get moneyFlowCalculationUrl =>
      ApiConfig.budgetOverviewFetchServiceUrl;

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
  Future<DashboardModel> fetchDashboardData({
    String period = 'monthly',
    DateTime? selectedDate,
  }) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Usar la fecha seleccionada o la fecha actual si no se proporciona
      final date = selectedDate ?? DateTime.now();
      final dateString =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      // Log para debug de navegación temporal
      print(
        '⏱️ fetchDashboardData - Period: $period, Selected Date: $dateString (${_getReadableDate(date)})',
      );

      // Make HTTP request using dashboard data service URL with additional date parameter
      final apiUrl =
          '${dashboardDataUrl}/dashboard/data?user_id=$userId&period=$period&date=$dateString';
      print('📊 Requesting dashboard data from: $apiUrl');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        print('✅ Dashboard data received successfully');
        // Parse JSON response
        final Map<String, dynamic> data = json.decode(response.body);

        // Obtain money flow data from the new microservice
        try {
          // Implementar sistema de reintentos para money flow
          const maxRetries = 3;
          int currentRetry = 0;
          bool success = false;
          dynamic moneyFlowData;

          // Log para debug de money flow request
          final moneyFlowUrl =
              '${moneyFlowCalculationUrl}/money-flow/data?user_id=$userId&period=$period&date=$dateString';
          print('💰 Requesting money flow data from: $moneyFlowUrl');

          while (currentRetry < maxRetries && !success) {
            try {
              final moneyFlowResponse = await http
                  .get(
                    Uri.parse(moneyFlowUrl),
                    headers: {'Content-Type': 'application/json'},
                  )
                  .timeout(const Duration(seconds: 5));

              if (moneyFlowResponse.statusCode == 200) {
                moneyFlowData = json.decode(moneyFlowResponse.body);
                success = true;
                print('✅ Money flow data received successfully');
              } else {
                currentRetry++;
                print(
                  '⚠️ Money flow request failed with status: ${moneyFlowResponse.statusCode}, retry $currentRetry/$maxRetries',
                );
                if (currentRetry < maxRetries) {
                  // Esperar antes de reintentar (backoff exponencial)
                  await Future.delayed(
                    Duration(milliseconds: 500 * currentRetry),
                  );
                  print(
                    'Reintentando obtener money flow data (intento $currentRetry/$maxRetries)',
                  );
                }
              }
            } catch (retryError) {
              currentRetry++;
              print('❌ Money flow request error: $retryError');
              if (currentRetry < maxRetries) {
                // Esperar antes de reintentar (backoff exponencial)
                await Future.delayed(
                  Duration(milliseconds: 500 * currentRetry),
                );
                print(
                  'Error al obtener money flow data, reintentando (intento $currentRetry/$maxRetries): $retryError',
                );
              }
            }
          }

          // Procesar los datos si se obtuvieron correctamente
          if (success && moneyFlowData != null) {
            // If the money flow data is available, update the budget_overview in the response
            if (moneyFlowData['success'] == true &&
                moneyFlowData['data'] != null) {
              final moneyFlow = moneyFlowData['data'];

              // Update budget_overview with accurate money flow data
              if (data['budget_overview'] != null) {
                print('🔄 Updating dashboard data with money flow information');
                data['budget_overview']['remaining_amount'] =
                    moneyFlow['remaining_amount'];
                data['budget_overview']['total_amount'] =
                    moneyFlow['total_budget'];
                data['budget_overview']['spent_amount'] =
                    moneyFlow['spent_amount'];
                data['budget_overview']['upcoming_amount'] =
                    moneyFlow['upcoming_bills'];
                data['budget_overview']['combined_expense'] =
                    moneyFlow['combined_expenses'];
                data['budget_overview']['expense_percent'] =
                    moneyFlow['expense_percent'];
                data['budget_overview']['total_income'] =
                    moneyFlow['total_income'];

                // Update money_flow inside budget_overview
                if (data['budget_overview']['money_flow'] != null) {
                  data['budget_overview']['money_flow']['from_previous'] =
                      moneyFlow['from_previous'];
                  print(
                    '💲 Updated from_previous: ${moneyFlow['from_previous']}',
                  );
                }
              }
            }
          } else {
            print(
              '❌ No se pudo obtener money flow data después de $maxRetries intentos',
            );
          }
        } catch (e) {
          print('❌ Error fetching money flow data: $e');
          // Continue with original data if money flow calculation fails
        }

        return DashboardModel.fromJson(data);
      } else {
        print('❌ Dashboard API error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
          'Error fetching dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      // In case of error, return a model with default values
      print('❌ Error in fetchDashboardData: $e');
      throw Exception('Error fetching dashboard data: $e');
    }
  }

  // Helper para mostrar fecha legible en logs
  String _getReadableDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Change time period
  Future<DashboardModel> changePeriod(
    String period, {
    DateTime? selectedDate,
  }) async {
    return await fetchDashboardData(period: period, selectedDate: selectedDate);
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

  // Register a new income
  Future<bool> addIncome({
    required double amount,
    required String date,
    required String category,
    required String paymentMethod,
    String? description,
  }) async {
    try {
      // Get user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null || userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/income/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'amount': amount,
          'date': date,
          'category': category,
          'payment_method': paymentMethod,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Error adding income: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in addIncome: $e');
      throw Exception('Failed to add income');
    }
  }

  // Register a new expense
  Future<bool> addExpense({
    required double amount,
    required String date,
    required String category,
    required String paymentMethod,
    String? description,
  }) async {
    try {
      // Get user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null || userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/expense/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'amount': amount,
          'date': date,
          'category': category,
          'payment_method': paymentMethod,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Error adding expense: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in addExpense: $e');
      throw Exception('Failed to add expense');
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
