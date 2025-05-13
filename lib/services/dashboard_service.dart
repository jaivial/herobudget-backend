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

  // Obtener los datos del dashboard
  Future<DashboardModel> fetchDashboardData({String period = 'monthly'}) async {
    try {
      // Obtener el ID de usuario de SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Realizar la petición HTTP usando la URL del servicio de datos del dashboard
      final response = await http.get(
        Uri.parse(
          '${dashboardDataUrl}/dashboard/data?user_id=$userId&period=$period',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        // Parsear la respuesta JSON
        final Map<String, dynamic> data = json.decode(response.body);
        return DashboardModel.fromJson(data);
      } else {
        throw Exception(
          'Error al obtener datos del dashboard: ${response.statusCode}',
        );
      }
    } catch (e) {
      // En caso de error, devolver un modelo con valores por defecto
      print('Error en fetchDashboardData: $e');
      throw Exception('Error al obtener datos del dashboard: $e');
    }
  }

  // Cambiar el periodo de tiempo
  Future<DashboardModel> changePeriod(String period) async {
    return await fetchDashboardData(period: period);
  }

  // Actualizar el objetivo de ahorro
  Future<bool> updateSavingsGoal(double goal) async {
    try {
      // Obtener el ID de usuario de SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Realizar la petición HTTP
      final response = await http.post(
        Uri.parse('$baseUrl/savings/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'goal': goal}),
      );

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Error al actualizar objetivo de ahorro: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error en updateSavingsGoal: $e');
      return false;
    }
  }

  // Registrar un nuevo gasto
  Future<bool> addExpense({
    required String name,
    required double amount,
    required String category,
    String? notes,
  }) async {
    try {
      // Obtener el ID de usuario de SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Realizar la petición HTTP
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

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error al registrar gasto: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en addExpense: $e');
      return false;
    }
  }

  // Registrar un nuevo ingreso
  Future<bool> addIncome({
    required String name,
    required double amount,
    required String category,
    String? notes,
  }) async {
    try {
      // Obtener el ID de usuario de SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Realizar la petición HTTP
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

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error al registrar ingreso: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en addIncome: $e');
      return false;
    }
  }

  // Agregar una nueva factura
  Future<bool> addBill({
    required String name,
    required double amount,
    required String dueDate,
    required String category,
    required String icon,
    required bool recurring,
  }) async {
    try {
      // Obtener el ID de usuario de SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Realizar la petición HTTP
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

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error al agregar factura: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en addBill: $e');
      return false;
    }
  }

  // Marcar una factura como pagada
  Future<bool> payBill(int billId) async {
    try {
      // Obtener el ID de usuario de SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Realizar la petición HTTP
      final response = await http.post(
        Uri.parse('$baseUrl/bills/pay'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'bill_id': billId}),
      );

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error al pagar factura: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en payBill: $e');
      return false;
    }
  }
}
