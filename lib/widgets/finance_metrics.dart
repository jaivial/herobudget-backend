import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../utils/app_localizations.dart';

class FinanceMetricsWidget extends StatelessWidget {
  final FinanceMetrics metrics;

  const FinanceMetricsWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    // Calculate total
    final double total = metrics.income + metrics.expenses + metrics.bills;

    // Calculate percentages
    final double incomePercent = total > 0 ? (metrics.income / total * 100) : 0;
    final double expensesPercent =
        total > 0 ? (metrics.expenses / total * 100) : 0;
    final double billsPercent = total > 0 ? (metrics.bills / total * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
            context.tr.translate('finance_metrics'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Income vs Expenses Chart
          _MetricCard(
            title: context.tr.translate('income_vs_expenses'),
            child: Column(
              children: [
                // Progress bar showing distribution
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey.shade200,
                  ),
                  child: Row(
                    children: [
                      // Income segment
                      Flexible(
                        flex: incomePercent.toInt(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.horizontal(
                              left: const Radius.circular(6),
                              right: Radius.circular(
                                expensesPercent <= 0 && billsPercent <= 0
                                    ? 6
                                    : 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Expenses segment
                      Flexible(
                        flex: expensesPercent.toInt(),
                        child: Container(color: Colors.red),
                      ),
                      // Bills segment
                      Flexible(
                        flex: billsPercent.toInt(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.horizontal(
                              right: const Radius.circular(6),
                              left: Radius.circular(
                                expensesPercent <= 0 && incomePercent <= 0
                                    ? 6
                                    : 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Legend and values
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricLegendItem(
                      color: Colors.green,
                      label: context.tr.translate('income'),
                      value: context.tr.formatCurrency(metrics.income),
                      percent: incomePercent,
                    ),
                    _MetricLegendItem(
                      color: Colors.red,
                      label: context.tr.translate('expenses'),
                      value: context.tr.formatCurrency(metrics.expenses),
                      percent: expensesPercent,
                    ),
                    _MetricLegendItem(
                      color: Colors.blue,
                      label: context.tr.translate('budget'),
                      value: context.tr.formatCurrency(metrics.bills),
                      percent: billsPercent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Savings Rate Card
          _MetricCard(
            title: context.tr.translate('savings_rate'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Graph or visualization would go here
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.purple, width: 8),
                  ),
                  child: Center(
                    child: Text(
                      '12%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                // Text description
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      '12% of your income is being saved. Try to save at least 20% for financial health.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _MetricCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetricLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final double percent;

  const _MetricLegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
