import 'package:flutter/material.dart';
import '../../utils/extensions.dart';
import '../../theme/app_theme.dart';
import '../../models/dashboard_model.dart';

class MoneyFlowWidget extends StatelessWidget {
  final double inflow;
  final double outflow;
  final String period;

  const MoneyFlowWidget({
    super.key,
    required this.inflow,
    required this.outflow,
    this.period = 'monthly',
  });

  @override
  Widget build(BuildContext context) {
    final netFlow = inflow - outflow;
    final isPositive = netFlow >= 0;

    // Get the localized title
    final title = context.tr.translate('money_flow');

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
                  context.tr.translate('${period}_period'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Money flow diagram
          Row(
            children: [
              // Income column
              Expanded(
                child: _buildFlowColumn(
                  context,
                  Icons.arrow_downward,
                  Colors.green,
                  context.tr.translate('income'),
                  inflow,
                ),
              ),

              // Arrow indicator
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  isPositive ? Icons.arrow_forward : Icons.arrow_back,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 24,
                ),
              ),

              // Expenses column
              Expanded(
                child: _buildFlowColumn(
                  context,
                  Icons.arrow_upward,
                  Colors.red,
                  context.tr.translate('expenses'),
                  outflow,
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
                      ? context.tr.translate('savings')
                      : context.tr.translate('deficit'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${netFlow.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
