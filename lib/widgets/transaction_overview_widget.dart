import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../utils/extensions.dart';
import '../theme/app_theme.dart';
import '../screens/invoice/add_invoice_screen.dart';
import '../services/budget_overview_service.dart';
import 'upcoming_bills.dart';
import 'transaction_history_table.dart';

class TransactionOverviewWidget extends StatefulWidget {
  final String? period;
  final String? date;
  final VoidCallback? onAddBill;
  final VoidCallback? onRefresh;

  const TransactionOverviewWidget({
    super.key,
    this.period,
    this.date,
    this.onAddBill,
    this.onRefresh,
  });

  @override
  State<TransactionOverviewWidget> createState() =>
      _TransactionOverviewWidgetState();
}

class _TransactionOverviewWidgetState extends State<TransactionOverviewWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  final GlobalKey<State<UpcomingBillsWidget>> _upcomingBillsKey = GlobalKey();
  final GlobalKey<State<TransactionHistoryTable>> _transactionHistoryKey =
      GlobalKey();

  final BudgetOverviewService _budgetService = BudgetOverviewService();

  String _currentPeriod = 'monthly';
  String _formattedDate = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });

    _updatePeriodAndDate();
  }

  @override
  void didUpdateWidget(TransactionOverviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period || oldWidget.date != widget.date) {
      _updatePeriodAndDate();
      // Defer refresh until after the build phase completes
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleRefresh();
        }
      });
    }
  }

  void _updatePeriodAndDate() {
    _currentPeriod = widget.period ?? 'monthly';

    if (widget.date != null) {
      try {
        final DateTime dateTime = DateTime.parse(widget.date!);
        _formattedDate = _budgetService.formatDateForPeriod(
          dateTime,
          _currentPeriod,
        );
      } catch (e) {
        _formattedDate =
            widget.date!.length <= 7
                ? widget.date!
                : _budgetService.getCurrentPeriodDate(_currentPeriod);
      }
    } else {
      _formattedDate = _budgetService.getCurrentPeriodDate(_currentPeriod);
    }

    print(
      '🔄 TransactionOverviewWidget: Updated period=$_currentPeriod, date=$_formattedDate',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleAddBill() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddInvoiceScreen()),
    );

    if (result == true) {
      _handleRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? AppTheme.surfaceDark
                : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? AppTheme.surfaceDark.withOpacity(0.8)
                      : Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          context.tr.translate('transactions'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Colors.grey.shade800.withOpacity(0.3)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    isScrollable: false,
                    tabAlignment: TabAlignment.fill,
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color:
                          isDarkMode
                              ? AppTheme.primaryColorDark
                              : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor:
                        isDarkMode
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade700,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 10,
                    ),
                    tabs: [
                      Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 12,
                                color:
                                    _currentTabIndex == 0
                                        ? Colors.white
                                        : (isDarkMode
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.grey.shade700),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  context.tr.translate('upcoming_bills'),
                                  style: const TextStyle(fontSize: 9),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history,
                                size: 12,
                                color:
                                    _currentTabIndex == 1
                                        ? Colors.white
                                        : (isDarkMode
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.grey.shade700),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  context.tr.translate('transaction_history'),
                                  style: const TextStyle(fontSize: 9),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 600,
            child: TabBarView(
              controller: _tabController,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: UpcomingBillsWidget(
                    key: _upcomingBillsKey,
                    period: _currentPeriod,
                    date: _formattedDate,
                    onAddBill: _handleAddBill,
                    onRefresh: _handleRefresh,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: TransactionHistoryTable(
                    key: _transactionHistoryKey,
                    period: _currentPeriod,
                    date: _formattedDate,
                    onRefresh: _handleRefresh,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleRefresh() {
    // Prevent multiple simultaneous refresh calls
    if (_isRefreshing) {
      print(
        '🔄 TransactionOverviewWidget: Refresh already in progress, skipping...',
      );
      return;
    }

    _isRefreshing = true;
    print(
      '🔄 TransactionOverviewWidget: Refreshing with period=$_currentPeriod, date=$_formattedDate',
    );

    try {
      final upcomingBillsState = _upcomingBillsKey.currentState;
      if (upcomingBillsState != null) {
        final dynamic state = upcomingBillsState;
        if (state.mounted) {
          try {
            state.refreshData();
          } catch (e) {
            print('Error refreshing upcoming bills: $e');
          }
        }
      }

      final transactionHistoryState = _transactionHistoryKey.currentState;
      if (transactionHistoryState != null) {
        final dynamic state = transactionHistoryState;
        if (state.mounted) {
          try {
            state.refreshData();
          } catch (e) {
            print('Error refreshing transaction history: $e');
          }
        }
      }

      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    } finally {
      // Reset refresh flag after a delay to prevent rapid successive calls
      Future.delayed(const Duration(milliseconds: 1000), () {
        _isRefreshing = false;
      });
    }
  }
}

class CompactTransactionOverview extends StatelessWidget {
  final String? period;
  final String? date;
  final VoidCallback? onAddBill;
  final VoidCallback? onRefresh;
  final VoidCallback? onViewAll;

  const CompactTransactionOverview({
    super.key,
    this.period,
    this.date,
    this.onAddBill,
    this.onRefresh,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? AppTheme.surfaceDark
                : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr.translate('transactions'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : null,
                  ),
                ),
                Row(
                  children: [
                    if (onViewAll != null)
                      TextButton(
                        onPressed: onViewAll,
                        child: Text(context.tr.translate('view_all')),
                      ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: UpcomingBillsWidget(
              period: period,
              date: date,
              onAddBill: onAddBill,
              onRefresh: onRefresh,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class TransactionQuickActions extends StatelessWidget {
  final VoidCallback? onAddIncome;
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddBill;
  final VoidCallback? onViewHistory;

  const TransactionQuickActions({
    super.key,
    this.onAddIncome,
    this.onAddExpense,
    this.onAddBill,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? AppTheme.surfaceDark
                : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.translate('quick_actions'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.arrow_upward,
                  label: context.tr.translate('add_income'),
                  color: Colors.green,
                  onTap: onAddIncome,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.arrow_downward,
                  label: context.tr.translate('add_expense'),
                  color: Colors.red,
                  onTap: onAddExpense,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.receipt,
                  label: context.tr.translate('add_bill'),
                  color: Colors.orange,
                  onTap: onAddBill,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.history,
                  label: context.tr.translate('transaction_history'),
                  color:
                      isDarkMode
                          ? AppTheme.primaryColorDark
                          : Theme.of(context).colorScheme.primary,
                  onTap: onViewHistory,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isDarkMode;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
