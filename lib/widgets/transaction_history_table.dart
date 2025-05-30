import 'package:flutter/material.dart';

import '../models/transaction_models.dart';
import '../services/transaction_service.dart';
import '../utils/extensions.dart';
import '../theme/app_theme.dart';

class TransactionHistoryTable extends StatefulWidget {
  final String? period;
  final String? date;
  final VoidCallback? onRefresh;

  const TransactionHistoryTable({
    super.key,
    this.period,
    this.date,
    this.onRefresh,
  });

  @override
  State<TransactionHistoryTable> createState() =>
      _TransactionHistoryTableState();
}

class _TransactionHistoryTableState extends State<TransactionHistoryTable> {
  final TransactionService _transactionService = TransactionService();
  final ScrollController _scrollController = ScrollController();

  // Data state
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _hasMore = true;
  int _currentOffset = 0;
  final int _limit = 50;

  // Filter state
  TransactionFilters _filters = const TransactionFilters();
  SortOption _currentSort = SortOption.dateDesc;
  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TransactionHistoryTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data if period or date changed
    if (oldWidget.period != widget.period || oldWidget.date != widget.date) {
      _loadInitialData();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadInitialData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentOffset = 0;
        _hasMore = true;
        _transactions.clear();
        _filteredTransactions.clear();
      });
    }

    try {
      // Load categories first
      final categories = await _transactionService.getAvailableCategories();

      // Load transactions
      final response = await _transactionService.fetchTransactionHistory(
        period: widget.period,
        date: widget.date,
        filters: _filters,
        limit: _limit,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _availableCategories = categories;
          _transactions = response.transactions;
          _hasMore = response.hasMore;
          _currentOffset = response.nextOffset;
          _isLoading = false;
          _applyFiltersAndSort();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _transactionService.fetchTransactionHistory(
        period: widget.period,
        date: widget.date,
        filters: _filters,
        limit: _limit,
        offset: _currentOffset,
      );

      if (mounted) {
        setState(() {
          _transactions.addAll(response.transactions);
          _hasMore = response.hasMore;
          _currentOffset = response.nextOffset;
          _isLoadingMore = false;
          _applyFiltersAndSort();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _applyFiltersAndSort() {
    var filtered = _transactionService.filterTransactions(
      _transactions,
      _filters,
    );
    filtered = _transactionService.sortTransactions(filtered, _currentSort);

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  Future<void> _refreshData() async {
    await _loadInitialData();
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  /// Public method to refresh data from external widgets
  Future<void> refreshData() async {
    await _refreshData();
  }

  void _updateFilters(TransactionFilters newFilters) {
    setState(() {
      _filters = newFilters;
      _applyFiltersAndSort();
    });
  }

  void _updateSort(SortOption newSort) {
    setState(() {
      _currentSort = newSort;
      _applyFiltersAndSort();
    });
  }

  void _clearFilters() {
    setState(() {
      _filters = const TransactionFilters();
      _currentSort = SortOption.dateDesc;
      _applyFiltersAndSort();
    });
  }

  Color _getTransactionColor(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.bill:
        if (transaction.paid == true) {
          return Colors.blue;
        } else if (transaction.overdue == true) {
          return Colors.red;
        } else {
          return Colors.orange;
        }
    }
  }

  IconData _getTransactionIcon(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return Icons.arrow_upward;
      case TransactionType.expense:
        return Icons.arrow_downward;
      case TransactionType.bill:
        return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with controls
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr.translate('transaction_history'),
                style: TextStyle(
                  fontSize: 18, // Slightly smaller
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
            ),
            // Compact action buttons
            IconButton(
              onPressed: () => _showFilterDialog(context),
              icon: Icon(
                _filters.hasActiveFilters
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
                size: 20, // Smaller icons
                color:
                    _filters.hasActiveFilters
                        ? (isDarkMode
                            ? AppTheme.primaryColorDark
                            : Theme.of(context).colorScheme.primary)
                        : null,
              ),
              tooltip: context.tr.translate('filters'),
            ),
            PopupMenuButton<SortOption>(
              onSelected: _updateSort,
              icon: const Icon(Icons.sort, size: 20), // Smaller icon
              tooltip: context.tr.translate('sort'),
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: SortOption.dateDesc,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color:
                                _currentSort == SortOption.dateDesc
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              context.tr.translate('date_newest_first'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: SortOption.dateAsc,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color:
                                _currentSort == SortOption.dateAsc
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              context.tr.translate('date_oldest_first'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: SortOption.amountDesc,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color:
                                _currentSort == SortOption.amountDesc
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              context.tr.translate('amount_highest_first'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: SortOption.amountAsc,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color:
                                _currentSort == SortOption.amountAsc
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              context.tr.translate('amount_lowest_first'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Active filters display
        if (_filters.hasActiveFilters)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: (isDarkMode
                      ? AppTheme.primaryColorDark
                      : Theme.of(context).colorScheme.primary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (isDarkMode
                        ? AppTheme.primaryColorDark
                        : Theme.of(context).colorScheme.primary)
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt,
                  size: 16,
                  color:
                      isDarkMode
                          ? AppTheme.primaryColorDark
                          : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr.translate('filters_active'),
                    style: TextStyle(
                      color:
                          isDarkMode
                              ? AppTheme.primaryColorDark
                              : Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    context.tr.translate('clear_filters'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Error message
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr.translate('connection_error'),
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Content area with scroll
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTransactions.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 60,
                          color:
                              isDarkMode
                                  ? Colors.white.withOpacity(0.3)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filters.hasActiveFilters
                              ? context.tr.translate('no_transactions_found')
                              : context.tr.translate('no_transactions'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? Colors.white.withOpacity(0.7)
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_filters.hasActiveFilters) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _clearFilters,
                            child: Text(context.tr.translate('clear_filters')),
                          ),
                        ],
                      ],
                    ),
                  )
                  : ListView.separated(
                    itemCount:
                        _filteredTransactions.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder:
                        (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index >= _filteredTransactions.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final transaction = _filteredTransactions[index];
                      return TransactionListItem(
                        transaction: transaction,
                        isDarkMode: isDarkMode,
                        color: _getTransactionColor(transaction),
                        icon: _getTransactionIcon(transaction),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => TransactionFiltersDialog(
            currentFilters: _filters,
            availableCategories: _availableCategories,
            onFiltersChanged: _updateFilters,
          ),
    );
  }
}

// Transaction list item widget
class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final bool isDarkMode;
  final Color color;
  final IconData icon;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.isDarkMode,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              transaction.displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : null,
              ),
            ),
          ),
          Text(
            context.tr.formatCurrency(transaction.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.category,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Payment method
              Icon(
                transaction.paymentMethod == PaymentMethod.cash
                    ? Icons.money
                    : Icons.credit_card,
                size: 12,
                color:
                    isDarkMode
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                transaction.paymentMethod.value.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              // Date
              Text(
                context.tr.formatDate(
                  DateTime.parse(transaction.date),
                  pattern: 'MMM d, yyyy',
                ),
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          // Bill status for bills
          if (transaction.isBill) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.billStatusText,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (transaction.overdue == true &&
                    transaction.overdueDays != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${transaction.overdueDays} ${context.tr.translate('days_overdue')}',
                    style: TextStyle(fontSize: 10, color: Colors.red.shade700),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Filters dialog widget
class TransactionFiltersDialog extends StatefulWidget {
  final TransactionFilters currentFilters;
  final List<String> availableCategories;
  final Function(TransactionFilters) onFiltersChanged;

  const TransactionFiltersDialog({
    super.key,
    required this.currentFilters,
    required this.availableCategories,
    required this.onFiltersChanged,
  });

  @override
  State<TransactionFiltersDialog> createState() =>
      _TransactionFiltersDialogState();
}

class _TransactionFiltersDialogState extends State<TransactionFiltersDialog> {
  late TransactionFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr.translate('filters'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filters = const TransactionFilters();
                  });
                },
                child: Text(context.tr.translate('clear_all')),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction types
                  _FilterSection(
                    title: context.tr.translate('transaction_types'),
                    child: Wrap(
                      spacing: 8,
                      children:
                          TransactionType.values.map((type) {
                            final isSelected =
                                _filters.transactionTypes?.contains(type) ??
                                false;
                            return FilterChip(
                              label: Text(context.tr.translate(type.value)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  final types = List<TransactionType>.from(
                                    _filters.transactionTypes ?? [],
                                  );
                                  if (selected) {
                                    types.add(type);
                                  } else {
                                    types.remove(type);
                                  }
                                  _filters = _filters.copyWith(
                                    transactionTypes:
                                        types.isEmpty ? null : types,
                                  );
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment methods
                  _FilterSection(
                    title: context.tr.translate('payment_methods'),
                    child: Wrap(
                      spacing: 8,
                      children:
                          PaymentMethod.values.map((method) {
                            final isSelected =
                                _filters.paymentMethods?.contains(method) ??
                                false;
                            return FilterChip(
                              label: Text(context.tr.translate(method.value)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  final methods = List<PaymentMethod>.from(
                                    _filters.paymentMethods ?? [],
                                  );
                                  if (selected) {
                                    methods.add(method);
                                  } else {
                                    methods.remove(method);
                                  }
                                  _filters = _filters.copyWith(
                                    paymentMethods:
                                        methods.isEmpty ? null : methods,
                                  );
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Categories
                  _FilterSection(
                    title: context.tr.translate('categories'),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          widget.availableCategories.map((category) {
                            final isSelected =
                                _filters.categories?.contains(category) ??
                                false;
                            return FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  final categories = List<String>.from(
                                    _filters.categories ?? [],
                                  );
                                  if (selected) {
                                    categories.add(category);
                                  } else {
                                    categories.remove(category);
                                  }
                                  _filters = _filters.copyWith(
                                    categories:
                                        categories.isEmpty ? null : categories,
                                  );
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bill status (only show if bills are included in transaction types)
                  if (_filters.transactionTypes?.contains(
                        TransactionType.bill,
                      ) ??
                      true)
                    _FilterSection(
                      title: context.tr.translate('bill_status'),
                      child: Wrap(
                        spacing: 8,
                        children:
                            BillStatusFilter.values.map((status) {
                              final isSelected = _filters.billStatus == status;
                              return FilterChip(
                                label: Text(context.tr.translate(status.name)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _filters = _filters.copyWith(
                                      billStatus: selected ? status : null,
                                    );
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr.translate('cancel')),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onFiltersChanged(_filters);
                  Navigator.pop(context);
                },
                child: Text(context.tr.translate('apply_filters')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper widget for filter sections
class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDarkMode ? Colors.white : null,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
