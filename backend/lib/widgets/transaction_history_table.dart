import 'package:flutter/material.dart';

import '../models/transaction_models.dart';
import '../services/transaction_service.dart';
import '../utils/extensions.dart';
import '../theme/app_theme.dart';
import 'transaction_list_item.dart';
import 'transaction_filters_dialog.dart';
import 'skeleton_loader.dart';

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

  Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      // Show loading indicator
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Call delete service
      await _transactionService.deleteTransaction(
        transactionId: transaction.id,
        transactionType: transaction.type.value,
      );

      // Refresh data from server instead of just removing locally
      // This ensures we get the updated data including any recalculated balances
      await _loadInitialData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.translate('transaction_deleted_successfully'),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh parent widget (dashboard) to update all widgets
        // This will trigger complete dashboard refresh like when adding income/expense
        print(
          '🔄 TransactionHistoryTable: Transaction deleted successfully, triggering dashboard refresh',
        );

        // Small delay to ensure local data is fully loaded before triggering dashboard refresh
        Future.delayed(const Duration(milliseconds: 100), () {
          if (widget.onRefresh != null && mounted) {
            widget.onRefresh!();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.translate('error_deleting_transaction')),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error deleting transaction: $e');
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
                  fontSize: 18,
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
                size: 20,
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
              icon: const Icon(Icons.sort, size: 20),
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
                  ? Column(
                    children: [
                      // Skeleton para el header de la lista
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const SkeletonLoader.circular(size: 24),
                            const SizedBox(width: 12),
                            const Expanded(child: SkeletonLoader(height: 16)),
                            const SizedBox(width: 12),
                            const SkeletonLoader(width: 60, height: 16),
                          ],
                        ),
                      ),
                      // Lista de skeleton items para transacciones
                      Expanded(
                        child: ListView.separated(
                          itemCount: 8, // Mostrar 8 items skeleton
                          separatorBuilder:
                              (context, index) => Divider(
                                height: 1,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                          itemBuilder: (context, index) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const SkeletonLoader.circular(size: 40),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SkeletonLoader(
                                          width: 120,
                                          height: 16,
                                        ),
                                        const SizedBox(height: 8),
                                        const SkeletonLoader(
                                          width: 80,
                                          height: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const SkeletonLoader(
                                        width: 80,
                                        height: 16,
                                      ),
                                      const SizedBox(height: 8),
                                      const SkeletonLoader(
                                        width: 60,
                                        height: 14,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
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
                    controller: _scrollController,
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
                        onDelete: () => _deleteTransaction(transaction),
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
