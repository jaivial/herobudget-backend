import 'package:flutter/material.dart';
import 'package:hero_budget/utils/app_localizations.dart';

class MoneyFlowWidget extends StatelessWidget {
  final double inflow;
  final double outflow;
  final double fromPrevious;
  final double upcomingBills;
  final double remainingAmount;
  final String period;

  const MoneyFlowWidget({
    super.key,
    required this.inflow,
    required this.outflow,
    required this.fromPrevious,
    required this.upcomingBills,
    required this.remainingAmount,
    this.period = 'monthly',
  });

  @override
  Widget build(BuildContext context) {
    final netFlow = inflow - outflow;
    final totalExpenses = outflow + upcomingBills;
    final isPositive = netFlow >= 0;
    final totalBudget = inflow + fromPrevious;

    // Get the localized title
    final title = AppLocalizations.of(context).translate('money_flow');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with period
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocalizations.of(context).translate('${period}_period'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Money flow diagram with additional components
          Row(
            children: [
              // Income column
              Expanded(
                child: _buildFlowColumn(
                  context,
                  Icons.arrow_downward,
                  Colors.green,
                  AppLocalizations.of(context).translate('income'),
                  inflow,
                ),
              ),

              // From previous period column
              Expanded(
                child: _buildFlowColumn(
                  context,
                  Icons.history,
                  Colors.blue,
                  AppLocalizations.of(context).translate('previous'),
                  fromPrevious,
                ),
              ),

              // Current expenses column
              Expanded(
                child: _buildFlowColumn(
                  context,
                  Icons.arrow_upward,
                  Colors.red,
                  AppLocalizations.of(context).translate('expenses'),
                  outflow,
                ),
              ),

              // Upcoming bills column
              Expanded(
                child: _buildFlowColumn(
                  context,
                  Icons.calendar_today,
                  Colors.orange,
                  AppLocalizations.of(context).translate('upcoming'),
                  upcomingBills,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Budget progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('budget_progress'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${((totalExpenses / totalBudget) * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value:
                      totalBudget > 0
                          ? (totalExpenses / totalBudget).clamp(0.0, 1.0)
                          : 0,
                  minHeight: 12,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    totalExpenses < totalBudget ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Net flow result
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color:
                  isPositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  isPositive
                      ? AppLocalizations.of(context).translate('savings')
                      : AppLocalizations.of(context).translate('deficit'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${remainingAmount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).translate('remaining_amount'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowColumn(
    BuildContext context,
    IconData icon,
    Color color,
    String label,
    double amount,
  ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
