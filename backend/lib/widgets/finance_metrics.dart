import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../utils/extensions.dart';
import '../theme/app_theme.dart';
import '../services/dashboard_service.dart';

class FinanceMetricsWidget extends StatelessWidget {
  final FinanceMetrics metrics;

  const FinanceMetricsWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    // Calculate total
    final double total = metrics.income + metrics.expenses + metrics.bills;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculate percentages
    final double incomePercent = total > 0 ? (metrics.income / total * 100) : 0;
    final double expensesPercent =
        total > 0 ? (metrics.expenses / total * 100) : 0;
    final double billsPercent = total > 0 ? (metrics.bills / total * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(12),
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
            context.tr.translate('finance_distribution'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            height: 20,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // Income section
                Expanded(
                  flex: incomePercent.round(),
                  child: Container(
                    color:
                        isDarkMode ? AppTheme.primaryColorDark : Colors.green,
                  ),
                ),
                // Expenses section
                Expanded(
                  flex: expensesPercent.round(),
                  child: Container(
                    color:
                        isDarkMode ? AppTheme.secondaryColorDark : Colors.red,
                  ),
                ),
                // Bills section
                Expanded(
                  flex: billsPercent.round(),
                  child: Container(
                    color:
                        isDarkMode ? AppTheme.tertiaryColorDark : Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          _buildLegendItem(
            context,
            'income',
            metrics.income,
            incomePercent,
            isDarkMode ? AppTheme.primaryColorDark : Colors.green,
            isDarkMode,
          ),
          const SizedBox(height: 8),
          _buildLegendItem(
            context,
            'expenses',
            metrics.expenses,
            expensesPercent,
            isDarkMode ? AppTheme.secondaryColorDark : Colors.red,
            isDarkMode,
          ),
          const SizedBox(height: 8),
          _buildLegendItem(
            context,
            'bills',
            metrics.bills,
            billsPercent,
            isDarkMode ? AppTheme.tertiaryColorDark : Colors.blue,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    double amount,
    double percentage,
    Color color,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          context.tr.translate(label),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white.withOpacity(0.9) : null,
          ),
        ),
        const Spacer(),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '(${percentage.toStringAsFixed(0)}%)',
          style: TextStyle(
            color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// NEW WIDGET: FinanceMetricsWithPeriod - Dynamic widget controlled by parent
class FinanceMetricsWithPeriod extends StatefulWidget {
  final String currentPeriod;
  final DateTime currentDate;

  const FinanceMetricsWithPeriod({
    super.key,
    required this.currentPeriod,
    required this.currentDate,
  });

  @override
  State<FinanceMetricsWithPeriod> createState() =>
      _FinanceMetricsWithPeriodState();
}

class _FinanceMetricsWithPeriodState extends State<FinanceMetricsWithPeriod> {
  final DashboardService _dashboardService = DashboardService();

  String _currentPeriod = 'monthly';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  FinanceMetrics? _financeMetrics;

  @override
  void initState() {
    super.initState();
    _currentPeriod = widget.currentPeriod;
    _selectedDate = widget.currentDate;
    _fetchFinanceMetrics();
  }

  @override
  void didUpdateWidget(FinanceMetricsWithPeriod oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update data when parent changes period or date
    if (oldWidget.currentPeriod != widget.currentPeriod ||
        oldWidget.currentDate != widget.currentDate) {
      _currentPeriod = widget.currentPeriod;
      _selectedDate = widget.currentDate;
      _fetchFinanceMetrics();
    }
  }

  Future<void> _fetchFinanceMetrics() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print(
        '🔄 Fetching finance metrics for period: $_currentPeriod, date: $_selectedDate',
      );

      // Fetch budget overview from our new backend
      final budgetOverview = await _dashboardService.fetchBudgetOverview(
        period: _currentPeriod,
        selectedDate: _selectedDate,
      );

      // Create FinanceMetrics from BudgetOverview
      final financeMetrics = _dashboardService
          .createFinanceMetricsFromBudgetOverview(budgetOverview);

      if (mounted) {
        setState(() {
          _financeMetrics = financeMetrics;
          _isLoading = false;
        });

        print('✅ Finance metrics updated successfully');
        print('   Income: \$${financeMetrics.income.toStringAsFixed(2)}');
        print('   Expenses: \$${financeMetrics.expenses.toStringAsFixed(2)}');
        print('   Bills: \$${financeMetrics.bills.toStringAsFixed(2)}');
      }
    } catch (e) {
      print('❌ Error fetching finance metrics: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
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
          // Content area
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading data',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchFinanceMetrics,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_financeMetrics != null)
            // Use the original FinanceMetricsWidget to display the data
            FinanceMetricsWidget(metrics: _financeMetrics!)
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No data available',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
