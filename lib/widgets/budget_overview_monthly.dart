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
import 'skeleton_loader.dart';

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
  bool _isTransitioning = false; // Estado para transiciones de mes
  bool _transitionInProgress =
      false; // Guardia para evitar transiciones concurrentes
  DateTime? _lastLoadedDate; // Para tracking del último mes cargado
  String? _errorMessage;

  // Animation controllers for fade transitions
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Counter para forzar la reconstrucción del widget de ahorros
  int _savingsRefreshCounter = 0;

  @override
  void initState() {
    super.initState();
    // Initialize fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Initialize with current month
    _currentDate = _dateService.getCurrentMonthDate();
    _fetchBudgetData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Fetch budget data with smooth fade transitions
  Future<void> _fetchBudgetData({bool useTransition = false}) async {
    final formattedDate = _dateService.formatDateForMonth(_currentDate);

    print('📊 BudgetOverviewMonthly: Starting fetch for month: $formattedDate');

    if (useTransition) {
      await _performTransitionDataFetch();
    } else {
      await _performDataFetch();
    }
  }

  /// Data fetch during transitions with fade animations
  Future<void> _performTransitionDataFetch() async {
    // Prevenir transiciones concurrentes
    if (_transitionInProgress) {
      print(
        '🚫 BudgetOverviewMonthly: Transition already in progress, skipping...',
      );
      return;
    }

    _transitionInProgress = true;
    print('🎬 BudgetOverviewMonthly: Starting transition...');

    try {
      // Fade out current content and show skeleton
      await _fadeController.reverse();

      if (mounted) {
        setState(() {
          _isTransitioning = true;
          _isLoading = false;
        });
      }

      // Fade in skeleton
      await _fadeController.forward();

      try {
        final formattedDate = _dateService.formatDateForMonth(_currentDate);
        final budgetData = await _budgetService.fetchBudgetOverview(
          period: 'monthly',
          date: formattedDate,
        );

        if (mounted) {
          // Fade out skeleton
          await _fadeController.reverse();

          setState(() {
            _budgetOverview = budgetData;
            _isTransitioning = false;
            _lastLoadedDate = _currentDate; // Actualizar fecha de último load
            _errorMessage = null;
          });

          // Fade in real data
          await _fadeController.forward();
          print('✅ BudgetOverviewMonthly: Budget data loaded successfully');
        }
      } catch (e) {
        if (mounted) {
          // Fade out skeleton
          await _fadeController.reverse();

          setState(() {
            _errorMessage = e.toString();
            _isTransitioning = false;
            _lastLoadedDate = _currentDate; // Actualizar fecha incluso en error
            _budgetOverview = BudgetOverview.example();
          });

          // Fade in fallback data
          await _fadeController.forward();
          print('❌ BudgetOverviewMonthly: Error occurred, using fallback data');
        }
      }
    } finally {
      _transitionInProgress = false;
      print('🎬 BudgetOverviewMonthly: Transition completed');
    }
  }

  /// Regular data fetch for initial load
  Future<void> _performDataFetch() async {
    // No aplicar guardia en carga inicial, solo en transiciones
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
          _lastLoadedDate = _currentDate; // Actualizar fecha de último load
        });
        _fadeController.forward();
        print('✅ BudgetOverviewMonthly: Budget data loaded successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _lastLoadedDate = _currentDate; // Actualizar fecha incluso en error
          _budgetOverview = BudgetOverview.example();
        });
        _fadeController.forward();
        print('❌ BudgetOverviewMonthly: Error occurred, using fallback data');
      }
    }
  }

  /// Handle date change with smooth fade transition
  Future<void> _onDateChanged(DateTime newDate) async {
    if (!_dateService.isSameMonth(_currentDate, newDate)) {
      setState(() {
        _currentDate = newDate;
      });

      await _fetchBudgetData(useTransition: true);

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

  /// Refresh data manually - with smart checking
  Future<void> refreshBudgetData({bool force = false}) async {
    if (force) {
      print(
        '🔄 BudgetOverviewMonthly: Force refresh requested for ${_dateService.formatDateForMonth(_currentDate)}',
      );
      // When force is true, bypass all guards and fetch fresh data
      await _fetchBudgetData(useTransition: false);
      return;
    }

    // Para refresh manual, evitar transición si ya hay una en progreso
    if (_transitionInProgress) {
      print(
        '🚫 BudgetOverviewMonthly: Manual refresh skipped, transition in progress',
      );
      return;
    }

    // Evitar refresh innecesario si los datos ya están actualizados para el mes actual
    if (_lastLoadedDate != null &&
        _dateService.isSameMonth(_lastLoadedDate!, _currentDate) &&
        _budgetOverview != null) {
      print(
        '🚫 BudgetOverviewMonthly: Manual refresh skipped, data already current for ${_dateService.formatDateForMonth(_currentDate)}',
      );
      return;
    }

    print(
      '🔄 BudgetOverviewMonthly: Manual refresh proceeding for ${_dateService.formatDateForMonth(_currentDate)}',
    );
    await _fetchBudgetData(useTransition: false);
  }

  /// Custom skeleton that matches BudgetOverviewWidget structure exactly
  Widget _buildBudgetOverviewSkeleton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton (title + percentage badge)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SkeletonLoader.circular(size: 32),
                  const SizedBox(width: 8),
                  const SkeletonLoader(width: 120, height: 18),
                ],
              ),
              const SkeletonLoader(width: 50, height: 24, borderRadius: 12),
            ],
          ),

          const SizedBox(height: 20),

          // Remaining amount section (centered)
          Center(
            child: Column(
              children: [
                const SkeletonLoader(width: 140, height: 14),
                const SizedBox(height: 4),
                const SkeletonLoader(width: 180, height: 28),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Previous money flow section
          const SkeletonLoader(width: 200, height: 40, borderRadius: 8),

          const SizedBox(height: 20),

          // Progress bar section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Progress bar
                const SkeletonLoader(
                  width: double.infinity,
                  height: 15,
                  borderRadius: 7.5,
                ),
                const SizedBox(height: 12),
                // Legend items
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const SkeletonLoader.circular(size: 12),
                            const SizedBox(width: 6),
                            const SkeletonLoader(width: 60, height: 12),
                          ],
                        ),
                        const SkeletonLoader(width: 120, height: 12),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const SkeletonLoader.circular(size: 12),
                            const SizedBox(width: 6),
                            const SkeletonLoader(width: 70, height: 12),
                          ],
                        ),
                        const SkeletonLoader(width: 110, height: 12),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Total Income section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const SkeletonLoader.circular(size: 32),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLoader(width: 100, height: 14),
                    const SizedBox(height: 4),
                    const SkeletonLoader(width: 120, height: 18),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Combined expenses section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SkeletonLoader.circular(size: 32),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SkeletonLoader(width: 130, height: 14),
                            const SizedBox(height: 4),
                            const SkeletonLoader(width: 110, height: 18),
                          ],
                        ),
                      ],
                    ),
                    const SkeletonLoader(
                      width: 60,
                      height: 28,
                      borderRadius: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Daily rate section
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Colors.grey.shade800.withOpacity(0.6)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SkeletonLoader.circular(size: 14),
                          const SizedBox(width: 6),
                          const SkeletonLoader(width: 80, height: 12),
                        ],
                      ),
                      const SkeletonLoader(width: 90, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Custom skeleton for Savings Overview Widget
  Widget _buildSavingsOverviewSkeleton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and period
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonLoader(width: 160, height: 18),
              const SizedBox(height: 4),
              const SkeletonLoader(width: 60, height: 12),
            ],
          ),

          const SizedBox(height: 20),

          // Center content (icon + message or progress)
          Center(
            child: Column(
              children: [
                const SkeletonLoader.circular(size: 48),
                const SizedBox(height: 16),
                const SkeletonLoader(width: 200, height: 16),
                const SizedBox(height: 8),
                const SkeletonLoader(width: 250, height: 14),
                const SizedBox(height: 20),
                const SkeletonLoader(width: 180, height: 40, borderRadius: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Custom skeleton for Cash/Bank Distribution Widget
  Widget _buildCashBankDistributionSkeleton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and transfer button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonLoader(width: 180, height: 18),
              const SkeletonLoader(width: 80, height: 32, borderRadius: 8),
            ],
          ),

          const SizedBox(height: 20),

          // No data state or cash/bank rows
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.grey.shade800.withOpacity(0.3)
                      : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDarkMode
                        ? Colors.grey.shade700.withOpacity(0.5)
                        : Colors.grey.shade300,
              ),
            ),
            child: Column(
              children: [
                const SkeletonLoader.circular(size: 32),
                const SizedBox(height: 8),
                const SkeletonLoader(width: 160, height: 14),
                const SizedBox(height: 4),
                const SkeletonLoader(width: 200, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
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
                    onPressed: () => refreshBudgetData(force: true),
                    color: Colors.orange.shade700,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Budget Overview with Fade Animations
          if (_budgetOverview != null && !_isLoading && !_isTransitioning)
            FadeTransition(
              opacity: _fadeAnimation,
              child: BudgetOverviewWidget(budgetOverview: _budgetOverview!),
            ),

          // Custom Skeleton - matches BudgetOverview structure exactly
          if (_isLoading || _isTransitioning)
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBudgetOverviewSkeleton(context),
            ),

          // Spacing between main overview and additional sections
          if (_budgetOverview != null && !_isLoading && !_isTransitioning)
            const SizedBox(height: 16),

          // Monthly Savings Overview Section
          if (_budgetOverview != null && !_isLoading && !_isTransitioning)
            FadeTransition(
              opacity: _fadeAnimation,
              child: ProportionalSavingsOverviewWidget(
                key: ValueKey('savings_monthly_$_savingsRefreshCounter'),
                currentPeriod: 'monthly',
                totalBalance: _budgetOverview!.savingsData.totalBalance,
                onGoalUpdated: () async {
                  print('🔄 Monthly savings goal updated, refreshing data...');
                  await _fetchBudgetData();
                  setState(() {
                    _savingsRefreshCounter++;
                  });
                  print('✅ Monthly savings widget refreshed');
                },
              ),
            ),

          // Savings Overview Skeleton
          if (_isLoading || _isTransitioning)
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildSavingsOverviewSkeleton(context),
            ),

          // Additional spacing
          if (_budgetOverview != null && !_isLoading && !_isTransitioning)
            const SizedBox(height: 16),

          // Spacing for skeleton
          if (_isLoading || _isTransitioning) const SizedBox(height: 16),

          // Monthly Cash/Bank Distribution Section
          if (_budgetOverview != null && !_isLoading && !_isTransitioning)
            FadeTransition(
              opacity: _fadeAnimation,
              child: CashBankDistributionWidget(
                distribution: CashBankDistribution(
                  month: DateTime.now().toString().substring(0, 7),
                  cashAmount: _budgetOverview!.cashBankDistribution.cashAmount,
                  cashPercent:
                      _budgetOverview!.cashBankDistribution.cashPercent,
                  bankAmount: _budgetOverview!.cashBankDistribution.bankAmount,
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
                    () async {
                      // Refresh data after transfer
                      await _fetchBudgetData(useTransition: true);
                    },
                  );
                },
              ),
            ),

          // Cash/Bank Distribution Skeleton
          if (_isLoading || _isTransitioning)
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildCashBankDistributionSkeleton(context),
            ),
        ],
      ),
    );
  }
}
