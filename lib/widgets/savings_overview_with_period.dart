import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import '../theme/app_theme.dart';
import 'period_selector.dart';
import 'savings_overview.dart';

class SavingsOverviewWithPeriodSelector extends StatefulWidget {
  const SavingsOverviewWithPeriodSelector({super.key});

  @override
  State<SavingsOverviewWithPeriodSelector> createState() =>
      _SavingsOverviewWithPeriodSelectorState();
}

class _SavingsOverviewWithPeriodSelectorState
    extends State<SavingsOverviewWithPeriodSelector>
    with TickerProviderStateMixin {
  // Current state
  String _currentPeriod = 'monthly';

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Handle period change with smooth transition
  Future<void> _onPeriodChanged(String newPeriod) async {
    if (_currentPeriod != newPeriod) {
      // Start fade out animation
      await _fadeController.forward();

      if (mounted) {
        setState(() {
          _currentPeriod = newPeriod;
        });

        // Fade back in with new data
        _fadeController.reset();
      }
    }
  }

  /// Handle date change (for period selector)
  Future<void> _onDateChanged(DateTime newDate) async {
    // For savings, we don't need to handle date changes specifically
    // as savings goals are not date-dependent like budget data
  }

  /// Handle custom range selection (for period selector)
  Future<void> _onCustomRangeSelected(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // For savings, we don't need custom ranges
    // but we need this for the period selector interface
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period Selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? AppTheme.surfaceDark : Colors.white,
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
                context.tr.translate('savings_period_view'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr.translate('select_period_to_view_savings'),
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              PeriodSelector(
                initialPeriod: _currentPeriod,
                onPeriodChanged: _onPeriodChanged,
                onCustomRangeSelected: _onCustomRangeSelected,
                onDateChanged: _onDateChanged,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Savings Overview with proportional calculations
        FadeTransition(
          opacity: _fadeAnimation,
          child: SavingsOverviewWithPeriod(currentPeriod: _currentPeriod),
        ),
      ],
    );
  }
}
