import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/extensions.dart';
import '../services/budget_overview_service.dart';
import '../models/dashboard_model.dart' show CashBankDistribution;
import 'budget_overview.dart';
import 'period_selector.dart';
import 'savings_overview.dart';
import 'cash_bank_distribution.dart';

class BudgetOverviewWithPeriod extends StatefulWidget {
  final Function(String period, String date)? onPeriodChanged;
  final Function(String period, String date)? onDateChanged;

  const BudgetOverviewWithPeriod({
    super.key,
    this.onPeriodChanged,
    this.onDateChanged,
  });

  @override
  State<BudgetOverviewWithPeriod> createState() =>
      _BudgetOverviewWithPeriodState();
}

class _BudgetOverviewWithPeriodState extends State<BudgetOverviewWithPeriod>
    with TickerProviderStateMixin {
  final BudgetOverviewService _budgetService = BudgetOverviewService();

  // Current state
  String _currentPeriod = 'monthly';
  String _currentDate = '';
  BudgetOverview? _budgetOverview;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isChangingPeriod = false;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Direction tracking for slide animations
  bool _isNavigatingForward = true;

  // Counter para forzar la reconstrucción del widget de ahorros
  int _savingsRefreshCounter = 0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Initialize with current month
    _currentDate = _budgetService.getCurrentPeriodDate(_currentPeriod);
    _fetchBudgetData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Fetch budget data from the microservice with smooth transitions
  Future<void> _fetchBudgetData({bool useTransition = false}) async {
    print(
      '📊 BudgetOverviewWithPeriod: Starting fetch for period: $_currentPeriod, date: $_currentDate',
    );

    if (useTransition) {
      // Start fade out animation
      await _fadeController.forward();
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final budgetData = await _budgetService.fetchBudgetOverview(
        period: _currentPeriod,
        date: _currentDate,
      );

      if (mounted) {
        setState(() {
          _budgetOverview = budgetData;
          _isLoading = false;
        });
        print('✅ BudgetOverviewWithPeriod: Budget data loaded successfully');

        if (useTransition) {
          // Fade back in with new data
          _fadeController.reset();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          // Fallback to example data in case of error
          _budgetOverview = BudgetOverview.example();
        });
        print(
          '❌ BudgetOverviewWithPeriod: Error occurred, using fallback data',
        );

        if (useTransition) {
          // Fade back in with fallback data
          _fadeController.reset();
        }
      }
      print('❌ BudgetOverviewWithPeriod: Error fetching budget data: $e');
    }
  }

  /// Handle period change with slide animation
  Future<void> _onPeriodChanged(String newPeriod) async {
    if (_currentPeriod != newPeriod) {
      _isNavigatingForward = true; // Assume forward for period changes
      _isChangingPeriod = true; // Flag to prevent date change interference

      await _performTransition(() {
        setState(() {
          _currentPeriod = newPeriod;
          _currentDate = _budgetService.getCurrentPeriodDate(newPeriod);
        });
      });

      _isChangingPeriod = false; // Reset flag after transition

      // Notify parent widget about the change
      if (widget.onPeriodChanged != null) {
        widget.onPeriodChanged!(_currentPeriod, _currentDate);
      }
    }
  }

  /// Handle date change with slide animation
  Future<void> _onDateChanged(DateTime newDate) async {
    // Skip date change if we're currently changing periods to avoid conflicts
    if (_isChangingPeriod) {
      print('🚫 Skipping date change during period transition');
      return;
    }

    final newDateString = _budgetService.formatDateForPeriod(
      newDate,
      _currentPeriod,
    );
    if (_currentDate != newDateString) {
      // Determine direction based on date comparison
      final currentDateTime = _budgetService.formatDateForPeriod(
        DateTime.now(),
        _currentPeriod,
      );
      _isNavigatingForward = newDateString.compareTo(currentDateTime) > 0;

      await _performTransition(() {
        setState(() {
          _currentDate = newDateString;
        });
      });

      // Notify parent widget about the change
      if (widget.onDateChanged != null) {
        widget.onDateChanged!(_currentPeriod, _currentDate);
      }
    }
  }

  /// Handle custom range selection
  Future<void> _onCustomRangeSelected(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isNavigatingForward = true;

    await _performTransition(() {
      final monthlyDate = _budgetService.formatDateForPeriod(
        startDate,
        'monthly',
      );
      setState(() {
        _currentPeriod = 'custom';
        _currentDate = monthlyDate;
      });
    });

    // Notify parent widget about the change
    if (widget.onPeriodChanged != null) {
      widget.onPeriodChanged!(_currentPeriod, _currentDate);
    }
  }

  /// Perform transition animation and data fetch
  Future<void> _performTransition(VoidCallback updateState) async {
    // Configure slide direction
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(_isNavigatingForward ? 1.0 : -1.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    // Start slide out animation
    await _slideController.forward();

    // Update state
    updateState();

    // Fetch new data
    await _fetchBudgetData();

    // Configure slide in from opposite direction
    _slideAnimation = Tween<Offset>(
      begin: Offset(_isNavigatingForward ? -1.0 : 1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    // Reset and slide in
    _slideController.reset();
    _slideController.forward();
  }

  /// Refresh data manually
  Future<void> _refreshData() async {
    await _fetchBudgetData(useTransition: true);
  }

  /// Public method to refresh data from external widgets
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
          // Period Selector with improved styling - Full width
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
            child: PeriodSelector(
              initialPeriod: _currentPeriod,
              onPeriodChanged: _onPeriodChanged,
              onCustomRangeSelected: _onCustomRangeSelected,
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
                    onPressed: _refreshData,
                    color: Colors.orange.shade700,
                  ),
                ],
              ),
            ),

          // Budget Overview with Animations
          Container(
            width: double.infinity,
            height: _budgetOverview != null || _isLoading ? null : 400,
            child: Stack(
              children: [
                // Loading indicator
                if (_isLoading)
                  Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cargando datos del presupuesto...'),
                        ],
                      ),
                    ),
                  ),

                // Budget Overview with slide animation
                if (_budgetOverview != null && !_isLoading)
                  AnimatedBuilder(
                    animation: _slideController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: BudgetOverviewWidget(
                            budgetOverview: _budgetOverview!,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Spacing between main overview and additional sections
          const SizedBox(height: 16),

          // Period-aware Savings Overview Section
          if (_budgetOverview != null && !_isLoading)
            AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ProportionalSavingsOverviewWidget(
                      key: ValueKey('savings_$_savingsRefreshCounter'),
                      currentPeriod: _currentPeriod,
                      totalBalance: _budgetOverview!.savingsData.totalBalance,
                      onGoalUpdated: () async {
                        print('🔄 Savings goal updated, refreshing data...');

                        // Primero refrescar los datos del budget
                        await _fetchBudgetData();

                        // Luego forzar la reconstrucción del widget de ahorros
                        setState(() {
                          _savingsRefreshCounter++;
                        });

                        print('✅ Savings widget refreshed');
                      },
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Period-aware Cash/Bank Distribution Section
          if (_budgetOverview != null && !_isLoading)
            AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
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
