import 'package:flutter/material.dart';

/// Enum for transaction types
enum TransactionType { income, expense, bill }

/// Enum for payment methods
enum PaymentMethod { cash, bank }

/// Enum for sorting options
enum SortOption { amountAsc, amountDesc, dateAsc, dateDesc }

/// Enum for bill status filters
enum BillStatusFilter { all, paid, unpaid, overdue }

/// Extension to convert TransactionType to string
extension TransactionTypeExtension on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.bill:
        return 'bill';
    }
  }

  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'bill':
        return TransactionType.bill;
      default:
        throw ArgumentError('Invalid transaction type: $value');
    }
  }
}

/// Extension to convert PaymentMethod to string
extension PaymentMethodExtension on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.bank:
        return 'bank';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'bank':
        return PaymentMethod.bank;
      default:
        throw ArgumentError('Invalid payment method: $value');
    }
  }
}

/// Transaction model that represents income, expense, or bill
class Transaction {
  final int id;
  final TransactionType type;
  final double amount;
  final String date;
  final String category;
  final PaymentMethod paymentMethod;
  final String? description;
  final String? name; // For bills
  final bool? paid; // For bills
  final bool? overdue; // For bills
  final int? overdueDays; // For bills
  final bool? recurring; // For bills
  final String? icon; // For bills

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
    required this.paymentMethod,
    this.description,
    this.name,
    this.paid,
    this.overdue,
    this.overdueDays,
    this.recurring,
    this.icon,
  });

  /// Factory constructor from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      type: TransactionTypeExtension.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] as String,
      category: json['category'] as String,
      paymentMethod: PaymentMethodExtension.fromString(
        json['payment_method'] as String,
      ),
      description: json['description'] as String?,
      name: json['name'] as String?,
      paid: json['paid'] as bool?,
      overdue: json['overdue'] as bool?,
      overdueDays: json['overdue_days'] as int?,
      recurring: json['recurring'] as bool?,
      icon: json['icon'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'amount': amount,
      'date': date,
      'category': category,
      'payment_method': paymentMethod.value,
      'description': description,
      'name': name,
      'paid': paid,
      'overdue': overdue,
      'overdue_days': overdueDays,
      'recurring': recurring,
      'icon': icon,
    };
  }

  /// Check if this transaction is a bill
  bool get isBill => type == TransactionType.bill;

  /// Check if this transaction is an income
  bool get isIncome => type == TransactionType.income;

  /// Check if this transaction is an expense
  bool get isExpense => type == TransactionType.expense;

  /// Get display name (name for bills, description for others)
  String get displayName {
    if (isBill && name != null) {
      return name!;
    }
    return description ?? category;
  }

  /// Get bill status text
  String get billStatusText {
    if (!isBill) return '';
    if (overdue == true) return 'Overdue';
    if (paid == true) return 'Paid';
    return 'Pending';
  }

  /// Copy with method for creating modified instances
  Transaction copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? date,
    String? category,
    PaymentMethod? paymentMethod,
    String? description,
    String? name,
    bool? paid,
    bool? overdue,
    int? overdueDays,
    bool? recurring,
    String? icon,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      name: name ?? this.name,
      paid: paid ?? this.paid,
      overdue: overdue ?? this.overdue,
      overdueDays: overdueDays ?? this.overdueDays,
      recurring: recurring ?? this.recurring,
      icon: icon ?? this.icon,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.type == type &&
        other.amount == amount &&
        other.date == date &&
        other.category == category &&
        other.paymentMethod == paymentMethod;
  }

  @override
  int get hashCode {
    return Object.hash(id, type, amount, date, category, paymentMethod);
  }

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, date: $date, category: $category)';
  }
}

/// Response model for transaction history
class TransactionHistoryResponse {
  final List<Transaction> transactions;
  final int total;
  final int limit;
  final int offset;
  final String? period;
  final String? startDate;
  final String? endDate;

  const TransactionHistoryResponse({
    required this.transactions,
    required this.total,
    required this.limit,
    required this.offset,
    this.period,
    this.startDate,
    this.endDate,
  });

  /// Factory constructor from JSON
  factory TransactionHistoryResponse.fromJson(Map<String, dynamic> json) {
    // Handle null transactions array from backend
    final transactionsData = json['transactions'] as List<dynamic>?;
    final transactions =
        transactionsData != null
            ? transactionsData
                .map(
                  (item) => Transaction.fromJson(item as Map<String, dynamic>),
                )
                .toList()
            : <Transaction>[];

    return TransactionHistoryResponse(
      transactions: transactions,
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
      period: json['period'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'total': total,
      'limit': limit,
      'offset': offset,
      'period': period,
      'start_date': startDate,
      'end_date': endDate,
    };
  }

  /// Check if there are more transactions to load
  bool get hasMore => offset + transactions.length < total;

  /// Get next offset for pagination
  int get nextOffset => offset + limit;

  @override
  String toString() {
    return 'TransactionHistoryResponse(total: $total, transactions: ${transactions.length}, hasMore: $hasMore)';
  }
}

/// Response model for upcoming bills
class UpcomingBillsResponse {
  final List<Transaction> bills;
  final int total;
  final int overdue;
  final int upcoming;
  final int thisWeek;
  final int thisMonth;

  const UpcomingBillsResponse({
    required this.bills,
    required this.total,
    required this.overdue,
    required this.upcoming,
    required this.thisWeek,
    required this.thisMonth,
  });

  /// Factory constructor from JSON
  factory UpcomingBillsResponse.fromJson(Map<String, dynamic> json) {
    // Handle null bills array from backend
    final billsData = json['bills'] as List<dynamic>?;
    final bills =
        billsData != null
            ? billsData
                .map(
                  (item) => Transaction.fromJson(item as Map<String, dynamic>),
                )
                .toList()
            : <Transaction>[];

    return UpcomingBillsResponse(
      bills: bills,
      total: json['total'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      upcoming: json['upcoming'] as int? ?? 0,
      thisWeek: json['this_week'] as int? ?? 0,
      thisMonth: json['this_month'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'bills': bills.map((b) => b.toJson()).toList(),
      'total': total,
      'overdue': overdue,
      'upcoming': upcoming,
      'this_week': thisWeek,
      'this_month': thisMonth,
    };
  }

  /// Get overdue bills
  List<Transaction> get overdueBills {
    return bills.where((bill) => bill.overdue == true).toList();
  }

  /// Get upcoming bills (not overdue, not paid)
  List<Transaction> get upcomingBills {
    return bills
        .where((bill) => bill.overdue != true && bill.paid != true)
        .toList();
  }

  /// Get paid bills
  List<Transaction> get paidBills {
    return bills.where((bill) => bill.paid == true).toList();
  }

  @override
  String toString() {
    return 'UpcomingBillsResponse(total: $total, overdue: $overdue, upcoming: $upcoming)';
  }
}

/// Filter options for transaction history
class TransactionFilters {
  final List<TransactionType>? transactionTypes;
  final List<PaymentMethod>? paymentMethods;
  final List<String>? categories;
  final BillStatusFilter? billStatus;
  final SortOption? sortBy;
  final String? searchQuery;
  final DateTimeRange? dateRange;
  final int? minOverdueDays;
  final int? maxOverdueDays;

  const TransactionFilters({
    this.transactionTypes,
    this.paymentMethods,
    this.categories,
    this.billStatus,
    this.sortBy,
    this.searchQuery,
    this.dateRange,
    this.minOverdueDays,
    this.maxOverdueDays,
  });

  /// Convert to query parameters for API
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (transactionTypes != null && transactionTypes!.isNotEmpty) {
      params['transaction_types'] =
          transactionTypes!.map((t) => t.value).toList();
    }

    if (paymentMethods != null && paymentMethods!.isNotEmpty) {
      params['payment_methods'] = paymentMethods!.map((p) => p.value).toList();
    }

    if (categories != null && categories!.isNotEmpty) {
      params['categories'] = categories;
    }

    if (dateRange != null) {
      params['start_date'] = dateRange!.start.toIso8601String().split('T')[0];
      params['end_date'] = dateRange!.end.toIso8601String().split('T')[0];
    }

    return params;
  }

  /// Copy with method for creating modified filters
  TransactionFilters copyWith({
    List<TransactionType>? transactionTypes,
    List<PaymentMethod>? paymentMethods,
    List<String>? categories,
    BillStatusFilter? billStatus,
    SortOption? sortBy,
    String? searchQuery,
    DateTimeRange? dateRange,
    int? minOverdueDays,
    int? maxOverdueDays,
  }) {
    return TransactionFilters(
      transactionTypes: transactionTypes ?? this.transactionTypes,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      categories: categories ?? this.categories,
      billStatus: billStatus ?? this.billStatus,
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: dateRange ?? this.dateRange,
      minOverdueDays: minOverdueDays ?? this.minOverdueDays,
      maxOverdueDays: maxOverdueDays ?? this.maxOverdueDays,
    );
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return (transactionTypes != null && transactionTypes!.isNotEmpty) ||
        (paymentMethods != null && paymentMethods!.isNotEmpty) ||
        (categories != null && categories!.isNotEmpty) ||
        billStatus != null ||
        sortBy != null ||
        (searchQuery != null && searchQuery!.isNotEmpty) ||
        dateRange != null ||
        minOverdueDays != null ||
        maxOverdueDays != null;
  }

  /// Clear all filters
  TransactionFilters clear() {
    return const TransactionFilters();
  }

  @override
  String toString() {
    return 'TransactionFilters(hasActiveFilters: $hasActiveFilters)';
  }
}
