import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../utils/app_localizations.dart';
import '../theme/app_theme.dart';

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
      padding: const EdgeInsets.all(16),
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
            AppLocalizations.of(context).translate('finance_distribution'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 20),

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
          AppLocalizations.of(context).translate(label),
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
