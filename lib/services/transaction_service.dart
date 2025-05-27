import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/transaction_models.dart';

class TransactionService {
  static String get baseUrl => ApiConfig.budgetOverviewFetchServiceUrl;

  /// Fetch transaction history with filters and pagination
  Future<TransactionHistoryResponse> fetchTransactionHistory({
    String? period,
    String? date,
    String? startDate,
    String? endDate,
    TransactionFilters? filters,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Prepare request body
      final requestBody = <String, dynamic>{
        'user_id': userId,
        'limit': limit,
        'offset': offset,
      };

      // Add period and date information
      if (period != null && period.isNotEmpty) {
        requestBody['period'] = period;
      }
      if (date != null && date.isNotEmpty) {
        requestBody['date'] = date;
      }
      if (startDate != null && endDate != null) {
        requestBody['start_date'] = startDate;
        requestBody['end_date'] = endDate;
      }

      // Add filters if provided
      if (filters != null) {
        final filterParams = filters.toQueryParams();
        requestBody.addAll(filterParams);
      }

      print(
        '🔄 TransactionService: Making request to $baseUrl/transactions/history',
      );
      print('📋 Request body: ${json.encode(requestBody)}');

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/history'),
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
          print('✅ Transaction history received successfully');

          return TransactionHistoryResponse.fromJson(data);
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch transaction history',
          );
        }
      } else {
        throw Exception(
          'Error fetching transaction history: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error in fetchTransactionHistory: $e');
      throw Exception('Error fetching transaction history: $e');
    }
  }

  /// Fetch upcoming bills
  Future<UpcomingBillsResponse> fetchUpcomingBills() async {
    try {
      // Get user ID from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Prepare request body
      final requestBody = {'user_id': userId};

      print(
        '🔄 TransactionService: Making request to $baseUrl/transactions/upcoming-bills',
      );
      print('📋 Request body: ${json.encode(requestBody)}');

      // Make HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/upcoming-bills'),
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
          print('✅ Upcoming bills received successfully');

          return UpcomingBillsResponse.fromJson(data);
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch upcoming bills',
          );
        }
      } else {
        throw Exception(
          'Error fetching upcoming bills: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error in fetchUpcomingBills: $e');
      throw Exception('Error fetching upcoming bills: $e');
    }
  }

  /// Fetch transactions for a specific period (convenience method)
  Future<TransactionHistoryResponse> fetchTransactionsForPeriod({
    required String period,
    required String date,
    List<TransactionType>? transactionTypes,
    List<PaymentMethod>? paymentMethods,
    SortOption? sortBy,
    int limit = 100,
    int offset = 0,
  }) async {
    final filters = TransactionFilters(
      transactionTypes: transactionTypes,
      paymentMethods: paymentMethods,
      sortBy: sortBy,
    );

    return fetchTransactionHistory(
      period: period,
      date: date,
      filters: filters,
      limit: limit,
      offset: offset,
    );
  }

  /// Fetch transactions with custom date range
  Future<TransactionHistoryResponse> fetchTransactionsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    List<TransactionType>? transactionTypes,
    List<PaymentMethod>? paymentMethods,
    SortOption? sortBy,
    int limit = 100,
    int offset = 0,
  }) async {
    final filters = TransactionFilters(
      transactionTypes: transactionTypes,
      paymentMethods: paymentMethods,
      sortBy: sortBy,
    );

    return fetchTransactionHistory(
      startDate: startDate.toIso8601String().split('T')[0],
      endDate: endDate.toIso8601String().split('T')[0],
      filters: filters,
      limit: limit,
      offset: offset,
    );
  }

  /// Get all available categories from transactions
  Future<List<String>> getAvailableCategories() async {
    try {
      // Fetch a sample of transactions to extract categories
      final response = await fetchTransactionHistory(limit: 1000);

      final categories = <String>{};
      for (final transaction in response.transactions) {
        categories.add(transaction.category);
      }

      final sortedCategories = categories.toList()..sort();
      return sortedCategories;
    } catch (e) {
      print('❌ Error fetching categories: $e');
      // Return some default categories if the request fails
      return [
        'Food & Dining',
        'Transportation',
        'Shopping',
        'Entertainment',
        'Bills & Utilities',
        'Healthcare',
        'Education',
        'Travel',
        'Income',
        'Other',
      ];
    }
  }

  /// Apply local sorting to transactions (for client-side sorting)
  List<Transaction> sortTransactions(
    List<Transaction> transactions,
    SortOption sortOption,
  ) {
    final sortedList = List<Transaction>.from(transactions);

    switch (sortOption) {
      case SortOption.amountAsc:
        sortedList.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case SortOption.amountDesc:
        sortedList.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOption.dateAsc:
        sortedList.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.dateDesc:
        sortedList.sort((a, b) => b.date.compareTo(a.date));
        break;
    }

    return sortedList;
  }

  /// Apply local filtering to transactions (for client-side filtering)
  List<Transaction> filterTransactions(
    List<Transaction> transactions,
    TransactionFilters filters,
  ) {
    var filteredList = List<Transaction>.from(transactions);

    // Filter by transaction types
    if (filters.transactionTypes != null &&
        filters.transactionTypes!.isNotEmpty) {
      filteredList =
          filteredList
              .where((t) => filters.transactionTypes!.contains(t.type))
              .toList();
    }

    // Filter by payment methods
    if (filters.paymentMethods != null && filters.paymentMethods!.isNotEmpty) {
      filteredList =
          filteredList
              .where((t) => filters.paymentMethods!.contains(t.paymentMethod))
              .toList();
    }

    // Filter by categories
    if (filters.categories != null && filters.categories!.isNotEmpty) {
      filteredList =
          filteredList
              .where((t) => filters.categories!.contains(t.category))
              .toList();
    }

    // Filter by bill status
    if (filters.billStatus != null) {
      switch (filters.billStatus!) {
        case BillStatusFilter.paid:
          filteredList =
              filteredList.where((t) => t.isBill && t.paid == true).toList();
          break;
        case BillStatusFilter.unpaid:
          filteredList =
              filteredList.where((t) => t.isBill && t.paid != true).toList();
          break;
        case BillStatusFilter.overdue:
          filteredList =
              filteredList.where((t) => t.isBill && t.overdue == true).toList();
          break;
        case BillStatusFilter.all:
          // No additional filtering needed
          break;
      }
    }

    // Filter by search query
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final query = filters.searchQuery!.toLowerCase();
      filteredList =
          filteredList.where((t) {
            return t.displayName.toLowerCase().contains(query) ||
                t.category.toLowerCase().contains(query) ||
                (t.description?.toLowerCase().contains(query) ?? false);
          }).toList();
    }

    // Filter by overdue days range
    if (filters.minOverdueDays != null || filters.maxOverdueDays != null) {
      filteredList =
          filteredList.where((t) {
            if (!t.isBill || t.overdueDays == null) return false;

            final overdueDays = t.overdueDays!;
            final minDays = filters.minOverdueDays ?? 0;
            final maxDays = filters.maxOverdueDays ?? 999;

            return overdueDays >= minDays && overdueDays <= maxDays;
          }).toList();
    }

    return filteredList;
  }

  /// Format date according to period type for the API (reused from BudgetOverviewService)
  String formatDateForPeriod(DateTime date, String period) {
    switch (period.toLowerCase()) {
      case 'daily':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case 'weekly':
        // Calculate ISO week
        final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
        final week = ((dayOfYear - date.weekday + 10) / 7).floor();
        return '${date.year}-W${week.toString().padLeft(2, '0')}';
      case 'monthly':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case 'quarterly':
        final quarter = ((date.month - 1) ~/ 3) + 1;
        return '${date.year}-Q$quarter';
      case 'semiannual':
        final half = date.month <= 6 ? 1 : 2;
        return '${date.year}-H$half';
      case 'annual':
        return date.year.toString();
      default:
        // Default to monthly
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    }
  }

  /// Get current period's formatted date
  String getCurrentPeriodDate(String period) {
    return formatDateForPeriod(DateTime.now(), period);
  }

  /// Calculate date range for a given period and date
  Map<String, String> calculatePeriodDateRange(String period, String date) {
    try {
      final DateTime periodStart = _parseDate(date, period);
      final DateTime periodEnd = _getPeriodEnd(periodStart, period);

      return {
        'start_date': periodStart.toIso8601String().split('T')[0],
        'end_date': periodEnd.toIso8601String().split('T')[0],
      };
    } catch (e) {
      print('Error calculating period date range: $e');
      // Return current month as fallback
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      return {
        'start_date': monthStart.toIso8601String().split('T')[0],
        'end_date': monthEnd.toIso8601String().split('T')[0],
      };
    }
  }

  /// Parse date string back to DateTime based on period
  DateTime _parseDate(String dateString, String period) {
    switch (period.toLowerCase()) {
      case 'daily':
        return DateTime.parse(dateString);
      case 'weekly':
        // Parse format like "2024-W03"
        final parts = dateString.split('-W');
        final year = int.parse(parts[0]);
        final week = int.parse(parts[1]);
        // Calculate first day of week (Monday)
        final jan1 = DateTime(year, 1, 1);
        final daysToFirstMonday = (8 - jan1.weekday) % 7;
        final firstMonday = jan1.add(Duration(days: daysToFirstMonday));
        return firstMonday.add(Duration(days: (week - 1) * 7));
      case 'monthly':
        final parts = dateString.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      case 'quarterly':
        // Parse format like "2024-Q1"
        final parts = dateString.split('-Q');
        final year = int.parse(parts[0]);
        final quarter = int.parse(parts[1]);
        final month = (quarter - 1) * 3 + 1;
        return DateTime(year, month, 1);
      case 'semiannual':
        // Parse format like "2024-H1"
        final parts = dateString.split('-H');
        final year = int.parse(parts[0]);
        final half = int.parse(parts[1]);
        final month = half == 1 ? 1 : 7;
        return DateTime(year, month, 1);
      case 'annual':
        return DateTime(int.parse(dateString), 1, 1);
      default:
        // Default to monthly
        final parts = dateString.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    }
  }

  /// Get the end date for a given period start
  DateTime _getPeriodEnd(DateTime periodStart, String period) {
    switch (period.toLowerCase()) {
      case 'daily':
        return periodStart
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1));
      case 'weekly':
        return periodStart
            .add(const Duration(days: 7))
            .subtract(const Duration(seconds: 1));
      case 'monthly':
        final nextMonth = DateTime(periodStart.year, periodStart.month + 1, 1);
        return nextMonth.subtract(const Duration(seconds: 1));
      case 'quarterly':
        final nextQuarter = DateTime(
          periodStart.year,
          periodStart.month + 3,
          1,
        );
        return nextQuarter.subtract(const Duration(seconds: 1));
      case 'semiannual':
        final nextHalf = DateTime(periodStart.year, periodStart.month + 6, 1);
        return nextHalf.subtract(const Duration(seconds: 1));
      case 'annual':
        final nextYear = DateTime(periodStart.year + 1, 1, 1);
        return nextYear.subtract(const Duration(seconds: 1));
      default:
        // Default to monthly
        final nextMonth = DateTime(periodStart.year, periodStart.month + 1, 1);
        return nextMonth.subtract(const Duration(seconds: 1));
    }
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
