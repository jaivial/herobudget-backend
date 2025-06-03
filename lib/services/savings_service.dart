import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/environment.dart';
import '../models/dashboard_model.dart';

class SavingsService {
  static String get baseUrl => ApiConfig.savingsManagementUrl;

  // Cache interno para datos de ahorros
  static final Map<String, SavingsData> _cache = {};

  /// Fetch current savings data for a user
  Future<SavingsData> getSavingsData(String userId) async {
    try {
      // 🚨 DEBUG: Logging detallado para diagnóstico
      final fullUrl = '$baseUrl?user_id=$userId';
      print('\n🚨 === SAVINGS SERVICE DEBUG ===');
      print('📍 Method: getSavingsData');
      print('👤 User ID: $userId');
      print('🏠 Base URL: $baseUrl');
      print('🔗 Full URL: $fullUrl');
      print('🌍 Environment: ${EnvironmentConfig.currentEnvironment}');
      print('🏭 Is Production: ${EnvironmentConfig.isProduction}');
      print('🔧 API Config baseUrl: ${ApiConfig.baseApiUrl}');
      print('================================');

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
      );

      print('📊 Response received:');
      print('  • Status Code: ${response.statusCode}');
      print('  • Response Body: ${response.body}');
      print('  • Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          print('✅ Savings data fetched successfully');
          return SavingsData.fromJson(data);
        } else {
          final errorMsg =
              responseData['message'] ?? 'Failed to fetch savings data';
          print('❌ Server returned success=false: $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorMsg = 'Error fetching savings data: ${response.statusCode}';
        print('❌ HTTP Error: $errorMsg');
        print('📄 Response body: ${response.body}');

        // Información adicional para debugging 404
        if (response.statusCode == 404) {
          print('🔍 404 DEBUG INFO:');
          print('  • This means the URL path was not found on the server');
          print('  • Check if the backend service is running on port 8089');
          print('  • Verify the route /fetch is correctly implemented');
          print('  • Current full URL: $fullUrl');
        }

        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ Exception in getSavingsData: $e');
      print('🔧 Debug info:');
      print('  • User ID: $userId');
      print('  • Base URL: $baseUrl');
      print('  • Environment: ${EnvironmentConfig.currentEnvironment}');
      print('  • Full URL would be: $baseUrl?user_id=$userId');
      throw Exception('Error fetching savings data: $e');
    }
  }

  /// Update savings goal for a user
  Future<SavingsData> setSavingsGoal(
    String userId,
    double goal, {
    String period = 'monthly',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.savingsUpdateEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'goal': goal, 'period': period}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          return SavingsData.fromJson(data);
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to update savings goal',
          );
        }
      } else {
        throw Exception('Error updating savings goal: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in setSavingsGoal: $e');
      throw Exception('Error updating savings goal: $e');
    }
  }

  /// Update savings goal and period for a user
  Future<SavingsData> setSavingsGoalWithPeriod(
    String userId,
    double goal,
    String period,
  ) async {
    return setSavingsGoal(userId, goal, period: period);
  }

  /// Update available savings amount for a user
  Future<SavingsData> updateAvailableSavings(
    String userId,
    double available,
  ) async {
    try {
      final requestBody = {'user_id': userId, 'available': available};

      final response = await http.post(
        Uri.parse(ApiConfig.savingsUpdateEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          return SavingsData.fromJson(data);
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to update available savings',
          );
        }
      } else {
        throw Exception(
          'Error updating available savings: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error in updateAvailableSavings: $e');
      throw Exception('Error updating available savings: $e');
    }
  }

  /// Delete savings goal for a user
  Future<bool> deleteSavingsGoal(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.savingsDeleteEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // Limpiar cache después de eliminar exitosamente
          _cache.remove(userId);
          print('🗑️ Cache cleared for user $userId after deletion');
          return true;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to delete savings goal',
          );
        }
      } else {
        throw Exception('Error deleting savings goal: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in deleteSavingsGoal: $e');
      throw Exception('Error deleting savings goal: $e');
    }
  }

  /// Clear cache for a specific user
  static void clearCacheForUser(String userId) {
    _cache.remove(userId);
    print('🗑️ Cache cleared for user $userId');
  }

  /// Clear all cache
  static void clearAllCache() {
    _cache.clear();
    print('🗑️ All cache cleared');
  }

  /// Check service health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.savingsHealthEndpoint),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
}

/// Model class for savings data
class SavingsData {
  final String userId;
  final double available;
  final double goal;
  final String period;
  final double percent;
  final double needToSave;
  final double dailyTarget;

  SavingsData({
    required this.userId,
    required this.available,
    required this.goal,
    required this.period,
    required this.percent,
    required this.needToSave,
    required this.dailyTarget,
  });

  factory SavingsData.fromJson(Map<String, dynamic> json) {
    return SavingsData(
      userId: json['user_id'] ?? '',
      available: (json['available'] as num?)?.toDouble() ?? 0.0,
      goal: (json['goal'] as num?)?.toDouble() ?? 0.0,
      period: json['period'] ?? 'monthly',
      percent: (json['percent'] as num?)?.toDouble() ?? 0.0,
      needToSave: (json['need_to_save'] as num?)?.toDouble() ?? 0.0,
      dailyTarget: (json['daily_target'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'available': available,
      'goal': goal,
      'period': period,
      'percent': percent,
      'need_to_save': needToSave,
      'daily_target': dailyTarget,
    };
  }
}
