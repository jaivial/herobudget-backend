import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/dashboard_model.dart';

class SavingsService {
  static String get baseUrl => ApiConfig.savingsManagementUrl;

  // Cache interno para datos de ahorros
  static final Map<String, SavingsData> _cache = {};

  /// Fetch current savings data for a user
  Future<SavingsData> getSavingsData(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fetch?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          return SavingsData.fromJson(data);
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch savings data',
          );
        }
      } else {
        throw Exception('Error fetching savings data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getSavingsData: $e');
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
        Uri.parse('$baseUrl/update'),
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
        Uri.parse('$baseUrl/update'),
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
        Uri.parse('$baseUrl/delete'),
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
        Uri.parse('$baseUrl/health'),
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
