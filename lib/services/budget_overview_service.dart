import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../widgets/budget_overview.dart';
import 'package:flutter/material.dart';
import '../utils/date_utils.dart' as AppDateUtils;

class BudgetOverviewService {
  static String get baseUrl => ApiConfig.budgetOverviewFetchServiceUrl;

  /// Fetch budget overview data for a specific period and date
  Future<BudgetOverview> fetchBudgetOverview({
    required String period,
    required String date,
    String? startDate,
    String? endDate,
  }) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Prepare request body
      final requestBody = {'user_id': userId, 'period': period, 'date': date};

      // Add custom date range if provided
      if (startDate != null && endDate != null) {
        requestBody['start_date'] = startDate;
        requestBody['end_date'] = endDate;
      }

      print('🔄 BudgetOverviewService: Making request to $baseUrl');
      print('📋 Request body: ${json.encode(requestBody)}');

      // Make HTTP request
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      // Check if response is successful
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final Map<String, dynamic> data = responseData['data'];

          print('✅ Budget data received successfully');

          // Create BudgetOverview from response data
          return BudgetOverview(
            remainingAmount:
                (data['remaining_amount'] as num?)?.toDouble() ?? 0.0,
            expensePercent:
                (data['expense_percent'] as num?)?.toDouble() ?? 0.0,
            spentAmount: (data['spent_amount'] as num?)?.toDouble() ?? 0.0,
            upcomingAmount:
                (data['upcoming_amount'] as num?)?.toDouble() ?? 0.0,
            totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0.0,
            combinedExpense:
                (data['combined_expense'] as num?)?.toDouble() ?? 0.0,
            totalIncome: (data['total_income'] as num?)?.toDouble() ?? 0.0,
            dailyRate: (data['daily_rate'] as num?)?.toDouble() ?? 0.0,
            highSpending: data['high_spending'] as bool? ?? false,
            moneyFlow: MoneyFlow(
              fromPrevious:
                  (data['money_flow']?['from_previous'] as num?)?.toDouble() ??
                  0.0,
            ),
            cashBankDistribution: PeriodCashBankDistribution(
              cashAmount:
                  (data['cash_bank_distribution']?['cash_amount'] as num?)
                      ?.toDouble() ??
                  0.0,
              cashPercent:
                  (data['cash_bank_distribution']?['cash_percent'] as num?)
                      ?.toDouble() ??
                  0.0,
              bankAmount:
                  (data['cash_bank_distribution']?['bank_amount'] as num?)
                      ?.toDouble() ??
                  0.0,
              bankPercent:
                  (data['cash_bank_distribution']?['bank_percent'] as num?)
                      ?.toDouble() ??
                  0.0,
              totalAmount:
                  (data['cash_bank_distribution']?['total_amount'] as num?)
                      ?.toDouble() ??
                  0.0,
            ),
            savingsData: PeriodSavingsData(
              available:
                  (data['savings_data']?['available'] as num?)?.toDouble() ??
                  0.0,
              goal: (data['savings_data']?['goal'] as num?)?.toDouble() ?? 0.0,
              percent:
                  (data['savings_data']?['percent'] as num?)?.toDouble() ?? 0.0,
              totalBalance: (data['total_balance'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch budget overview',
          );
        }
      } else {
        throw Exception(
          'Error fetching budget overview: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error in fetchBudgetOverview: $e');
      throw Exception('Error fetching budget overview: $e');
    }
  }

  /// Format date according to period type for the API
  String formatDateForPeriod(DateTime date, String period) {
    return AppDateUtils.DateUtils.formatDateForPeriod(date, period);
  }

  /// Get current period's formatted date
  String getCurrentPeriodDate(String period) {
    return formatDateForPeriod(DateTime.now(), period);
  }

  /// Navigate to previous period
  String getPreviousPeriodDate(String currentDate, String period) {
    final DateTime current = _parseDate(currentDate, period);
    final DateTime previous = _navigatePeriod(current, period, -1);
    return formatDateForPeriod(previous, period);
  }

  /// Navigate to next period
  String getNextPeriodDate(String currentDate, String period) {
    final DateTime current = _parseDate(currentDate, period);
    final DateTime next = _navigatePeriod(current, period, 1);
    return formatDateForPeriod(next, period);
  }

  /// Parse date string back to DateTime based on period
  DateTime _parseDate(String dateString, String period) {
    return AppDateUtils.DateUtils.parseDateForPeriod(dateString, period);
  }

  /// Navigate period by specified amount
  DateTime _navigatePeriod(DateTime current, String period, int direction) {
    switch (period.toLowerCase()) {
      case 'daily':
        return current.add(Duration(days: direction));
      case 'weekly':
        return current.add(Duration(days: direction * 7));
      case 'monthly':
        final newMonth = current.month + direction;
        if (newMonth > 12) {
          return DateTime(current.year + 1, newMonth - 12, 1);
        } else if (newMonth < 1) {
          return DateTime(current.year - 1, newMonth + 12, 1);
        }
        return DateTime(current.year, newMonth, 1);
      case 'quarterly':
        final newMonth = current.month + (direction * 3);
        if (newMonth > 12) {
          return DateTime(current.year + 1, newMonth - 12, 1);
        } else if (newMonth < 1) {
          return DateTime(current.year - 1, newMonth + 12, 1);
        }
        return DateTime(current.year, newMonth, 1);
      case 'semiannual':
        final newMonth = current.month + (direction * 6);
        if (newMonth > 12) {
          return DateTime(current.year + 1, newMonth - 12, 1);
        } else if (newMonth < 1) {
          return DateTime(current.year - 1, newMonth + 12, 1);
        }
        return DateTime(current.year, newMonth, 1);
      case 'annual':
        return DateTime(current.year + direction, 1, 1);
      default:
        // Default to monthly
        final newMonth = current.month + direction;
        if (newMonth > 12) {
          return DateTime(current.year + 1, newMonth - 12, 1);
        } else if (newMonth < 1) {
          return DateTime(current.year - 1, newMonth + 12, 1);
        }
        return DateTime(current.year, newMonth, 1);
    }
  }

  /// Check service health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.budgetOverviewHealthEndpoint),
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
