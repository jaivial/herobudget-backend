import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../utils/app_localizations.dart';

class SavingsOverviewWidget extends StatelessWidget {
  final SavingsOverview savingsOverview;
  final VoidCallback onEditGoal;

  const SavingsOverviewWidget({
    super.key,
    required this.savingsOverview,
    required this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate percentage of goal achieved
    final double percentage =
        savingsOverview.goal > 0
            ? (savingsOverview.available / savingsOverview.goal * 100).clamp(
              0,
              100,
            )
            : 0;

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
          // Title and Edit Goal button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr.translate('savings_overview'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Edit goal button
              TextButton.icon(
                onPressed: onEditGoal,
                icon: const Icon(Icons.edit, size: 16),
                label: Text(context.tr.translate('edit_goal')),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Current savings amount
          Row(
            children: [
              Text(
                context.tr.formatCurrency(savingsOverview.available),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${context.tr.formatCurrency(savingsOverview.goal)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          Stack(
            children: [
              // Background
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // Foreground (progress)
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade600],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Percentage and goal text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${context.tr.translate('goal')}: ${context.tr.formatCurrency(savingsOverview.goal)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PercentageBadge extends StatelessWidget {
  final double percentage;

  const _PercentageBadge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${percentage.toStringAsFixed(0)}%',
        style: TextStyle(
          color: Colors.green.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SavingsProgressBar extends StatelessWidget {
  final double available;
  final double goal;

  const _SavingsProgressBar({required this.available, required this.goal});

  @override
  Widget build(BuildContext context) {
    // Calcular porcentaje
    double percent = (goal > 0) ? (available / goal * 100) : 0;

    // Limitar porcentaje al 100%
    if (percent > 100) percent = 100;

    return Stack(
      children: [
        // Barra de fondo
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        // Barra de progreso
        FractionallySizedBox(
          widthFactor: percent / 100,
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade300,
                  Colors.green.shade500,
                  Colors.green.shade700,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
