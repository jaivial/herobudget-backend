import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/extensions.dart';
import '../services/budget_overview_service.dart';
import '../services/monthly_date_service.dart';
import '../models/dashboard_model.dart' show CashBankDistribution;
import 'budget_overview.dart';
import 'period_selector_monthly.dart';
import 'savings_overview.dart';
import 'cash_bank_distribution.dart';
import 'budget_overview_animations.dart';

class BudgetOverviewMonthly extends StatefulWidget {
  final Function(String period, String date)? onPeriodChanged;
  final Function(String period, String date)? onDateChanged;

  const BudgetOverviewMonthly({
    super.key,
    this.onPeriodChanged,
    this.onDateChanged,
  });

  @override
  State<BudgetOverviewMonthly> createState() => _BudgetOverviewMonthlyState();
}

class _BudgetOverviewMonthlyState extends State<BudgetOverviewMonthly>
    with TickerProviderStateMixin, BudgetOverviewAnimations {
  final BudgetOverviewService _budgetService = BudgetOverviewService();
  final MonthlyDateService _dateService = MonthlyDateService();

  // Current state
  DateTime _currentDate = DateTime.now();
  BudgetOverview? _budgetOverview;
  bool _isLoading = false;
  String? _errorMessage;

  // Counter para forzar la reconstrucción del widget de ahorros
  int _savingsRefreshCounter = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with current month
    _currentDate = _dateService.getCurrentMonthDate();
    _fetchBudgetData();
  }

  /// Fetch budget data from the microservice with smooth transitions
  Future<void> _fetchBudgetData({bool useTransition = false}) async {
    final formattedDate = _dateService.formatDateForMonth(_currentDate);

    print('📊 BudgetOverviewMonthly: Starting fetch for month: $formattedDate');

    if (useTransition) {
      await performFadeTransition(_performDataFetch);
    } else {
      await _performDataFetch();
    }
  }

  /// Internal method to perform the actual data fetch
  Future<void> _performDataFetch() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final formattedDate = _dateService.formatDateForMonth(_currentDate);
      final budgetData = await _budgetService.fetchBudgetOverview(
        period: 'monthly',
        date: formattedDate,
      );

      if (mounted) {
        setState(() {
          _budgetOverview = budgetData;
          _isLoading = false;
        });
        print('✅ BudgetOverviewMonthly: Budget data loaded successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          // Fallback to example data in case of error
          _budgetOverview = BudgetOverview.example();
        });
        print('❌ BudgetOverviewMonthly: Error occurred, using fallback data');
      }
    }
  }

  /// Handle date change with animation
  Future<void> _onDateChanged(DateTime newDate) async {
    if (!_dateService.isSameMonth(_currentDate, newDate)) {
      // Determine direction for animation
      final isForward = newDate.isAfter(_currentDate);
      setNavigationDirection(isForward);

      await performTransition(() {
        setState(() {
          _currentDate = newDate;
        });
      }, _performDataFetch);

      // Notify parent widget about the change
      final formattedDate = _dateService.formatDateForMonth(_currentDate);
      if (widget.onDateChanged != null) {
        widget.onDateChanged!('monthly', formattedDate);
      }
      if (widget.onPeriodChanged != null) {
        widget.onPeriodChanged!('monthly', formattedDate);
      }
    }
  }

  /// Refresh data manually
  Future<void> refreshBudgetData() async {
    await _fetchBudgetData(useTransition: true);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.tr;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Period Selector - Full width
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: PeriodSelectorMonthly(
              initialDate: _currentDate,
              onPeriodChanged: (period) => _onDateChanged(_currentDate),
              onDateChanged: _onDateChanged,
            ),
          ),

          const SizedBox(height: 16),

          // Error Message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.translate('connection_error'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        Text(
                          localizations.translate('showing_sample_data'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: refreshBudgetData,
                    color: Colors.orange.shade700,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Budget Overview with Animations
          if (_budgetOverview != null && !_isLoading)
            AnimatedBuilder(
              animation: slideController,
              builder: (context, child) {
                return SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: BudgetOverviewWidget(
                      budgetOverview: _budgetOverview!,
                    ),
                  ),
                );
              },
            ),

          // Loading indicator
          if (_isLoading)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(localizations.translate('loading_budget_data')),
                  ],
                ),
              ),
            ),

          // Spacing between main overview and additional sections
          if (_budgetOverview != null && !_isLoading)
            const SizedBox(height: 16),

          // Monthly Savings Overview Section
          if (_budgetOverview != null && !_isLoading)
            AnimatedBuilder(
              animation: slideController,
              builder: (context, child) {
                return SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: ProportionalSavingsOverviewWidget(
                      key: ValueKey('savings_monthly_$_savingsRefreshCounter'),
                      currentPeriod: 'monthly',
                      totalBalance: _budgetOverview!.savingsData.totalBalance,
                      onGoalUpdated: () async {
                        print(
                          '🔄 Monthly savings goal updated, refreshing data...',
                        );
                        await _fetchBudgetData();
                        setState(() {
                          _savingsRefreshCounter++;
                        });
                        print('✅ Monthly savings widget refreshed');
                      },
                    ),
                  ),
                );
              },
            ),

          // Additional spacing
          if (_budgetOverview != null && !_isLoading)
            const SizedBox(height: 16),

          // Monthly Cash/Bank Distribution Section
          if (_budgetOverview != null && !_isLoading)
            AnimatedBuilder(
              animation: slideController,
              builder: (context, child) {
                // Debug: Print cash/bank distribution values
                print('🏦 BudgetOverviewMonthly - CashBankDistribution Debug:');
                print(
                  '  - cashAmount: ${_budgetOverview!.cashBankDistribution.cashAmount}',
                );
                print(
                  '  - bankAmount: ${_budgetOverview!.cashBankDistribution.bankAmount}',
                );
                print(
                  '  - totalAmount: ${_budgetOverview!.cashBankDistribution.totalAmount}',
                );

                return SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: CashBankDistributionWidget(
                      distribution: CashBankDistribution(
                        month: DateTime.now().toString().substring(0, 7),
                        cashAmount:
                            _budgetOverview!.cashBankDistribution.cashAmount,
                        cashPercent:
                            _budgetOverview!.cashBankDistribution.cashPercent,
                        bankAmount:
                            _budgetOverview!.cashBankDistribution.bankAmount,
                        bankPercent:
                            _budgetOverview!.cashBankDistribution.bankPercent,
                        monthlyTotal:
                            _budgetOverview!.cashBankDistribution.totalAmount,
                      ),
                      onTransferTap: () {
                        showTransferModal(
                          context,
                          CashBankDistribution(
                            month: DateTime.now().toString().substring(0, 7),
                            cashAmount:
                                _budgetOverview!
                                    .cashBankDistribution
                                    .cashAmount,
                            cashPercent:
                                _budgetOverview!
                                    .cashBankDistribution
                                    .cashPercent,
                            bankAmount:
                                _budgetOverview!
                                    .cashBankDistribution
                                    .bankAmount,
                            bankPercent:
                                _budgetOverview!
                                    .cashBankDistribution
                                    .bankPercent,
                            monthlyTotal:
                                _budgetOverview!
                                    .cashBankDistribution
                                    .totalAmount,
                          ),
                          () async {
                            // Refresh data after transfer
                            await _fetchBudgetData(useTransition: true);
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
