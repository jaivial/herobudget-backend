import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../utils/app_localizations.dart';
import '../theme/app_theme.dart';
import 'budget_overview.dart'; // Import para usar PeriodSavingsData

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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Check if no savings goal is set
    if (savingsOverview.goal <= 0) {
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
            // Title and Edit Goal button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr.translate('savings_overview'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // No goal message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? AppTheme.backgroundDark.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isDarkMode
                          ? Colors.grey.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 48,
                    color:
                        isDarkMode
                            ? Colors.white.withOpacity(0.5)
                            : Colors.grey.shade500,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr.translate('no_savings_goal_set'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.translate('set_savings_goal_message'),
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: onEditGoal,
                    icon: const Icon(Icons.add),
                    label: Text(context.tr.translate('set_savings_goal')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDarkMode
                              ? AppTheme.primaryColorDark
                              : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Show current available savings info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? AppTheme.backgroundDark.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 20,
                    color:
                        isDarkMode
                            ? AppTheme.primaryColorDark
                            : Colors.blue.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.translate('current_savings'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                isDarkMode
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          context.tr.formatCurrency(savingsOverview.available),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? AppTheme.primaryColorDark
                                    : Colors.blue.shade700,
                          ),
                        ),
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
          // Title and Edit Goal button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr.translate('savings_overview'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              // Edit goal button
              TextButton.icon(
                onPressed: onEditGoal,
                icon: Icon(
                  Icons.edit,
                  size: 16,
                  color: isDarkMode ? AppTheme.tertiaryColorDark : null,
                ),
                label: Text(
                  context.tr.translate('edit_goal'),
                  style: TextStyle(
                    color: isDarkMode ? AppTheme.tertiaryColorDark : null,
                  ),
                ),
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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${context.tr.formatCurrency(savingsOverview.goal)}',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
                  color:
                      isDarkMode
                          ? AppTheme.backgroundDark.withOpacity(0.5)
                          : Colors.grey.shade200,
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
                      colors:
                          isDarkMode
                              ? [
                                AppTheme.primaryColorDark,
                                AppTheme.secondaryColorDark,
                              ]
                              : [Colors.blue.shade300, Colors.blue.shade600],
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              Text(
                '${context.tr.translate('goal')}: ${context.tr.formatCurrency(savingsOverview.goal)}',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? AppTheme.primaryColorDark.withOpacity(0.3)
                : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${percentage.toStringAsFixed(0)}%',
        style: TextStyle(
          color: isDarkMode ? AppTheme.primaryColorDark : Colors.green.shade700,
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Limitar porcentaje al 100%
    if (percent > 100) percent = 100;

    return Stack(
      children: [
        // Barra de fondo
        Container(
          height: 10,
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? AppTheme.backgroundDark.withOpacity(0.5)
                    : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        // Barra de progreso
        FractionallySizedBox(
          widthFactor: percent / 100,
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                colors:
                    isDarkMode
                        ? [
                          AppTheme.primaryColorDark,
                          AppTheme.secondaryColorDark,
                        ]
                        : [
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

// Nueva clase para mostrar ahorros basados en período
class PeriodSavingsOverviewWidget extends StatelessWidget {
  final PeriodSavingsData savingsData;
  final String period;
  final String date;

  const PeriodSavingsOverviewWidget({
    super.key,
    required this.savingsData,
    required this.period,
    required this.date,
  });

  String _getPeriodDisplayName(BuildContext context, String period) {
    switch (period) {
      case 'daily':
        return context.tr.translate('daily');
      case 'weekly':
        return context.tr.translate('weekly');
      case 'monthly':
        return context.tr.translate('monthly');
      case 'quarterly':
        return context.tr.translate('quarterly');
      case 'semiannual':
        return context.tr.translate('semiannual');
      case 'annual':
        return context.tr.translate('annual');
      case 'custom':
        return context.tr.translate('custom');
      default:
        return context.tr.translate('period');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Check if no savings goal is set
    if (savingsData.goal <= 0) {
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
            // Title with period information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.translate('savings_overview'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : null,
                        ),
                      ),
                      Text(
                        _getPeriodDisplayName(context, period),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode
                                  ? Colors.white.withOpacity(0.7)
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // No goal message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? AppTheme.backgroundDark.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isDarkMode
                          ? Colors.grey.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 48,
                    color:
                        isDarkMode
                            ? Colors.white.withOpacity(0.5)
                            : Colors.grey.shade500,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr.translate('no_savings_goal_set'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.translate('set_savings_goal_message'),
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to set savings goal screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr.translate(
                              'set_goal_feature_coming_soon',
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(context.tr.translate('set_savings_goal')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDarkMode
                              ? AppTheme.primaryColorDark
                              : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Show current total balance info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? AppTheme.backgroundDark.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 20,
                    color:
                        isDarkMode
                            ? AppTheme.primaryColorDark
                            : Colors.blue.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.translate('current_balance'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                isDarkMode
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          context.tr.formatCurrency(savingsData.totalBalance),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? AppTheme.primaryColorDark
                                    : Colors.blue.shade700,
                          ),
                        ),
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

    // Calculate percentage of goal achieved using totalBalance
    final double percentage =
        savingsData.goal > 0
            ? (savingsData.totalBalance / savingsData.goal * 100).clamp(0, 100)
            : 0;

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
          // Title with period information
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.translate('savings_overview'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : null,
                      ),
                    ),
                    Text(
                      _getPeriodDisplayName(context, period),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDarkMode
                                ? Colors.white.withOpacity(0.7)
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Current savings amount (using totalBalance)
          Row(
            children: [
              Text(
                context.tr.formatCurrency(savingsData.totalBalance),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${context.tr.formatCurrency(savingsData.goal)}',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
                  color:
                      isDarkMode
                          ? AppTheme.backgroundDark.withOpacity(0.5)
                          : Colors.grey.shade200,
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
                      colors:
                          isDarkMode
                              ? [
                                AppTheme.primaryColorDark,
                                AppTheme.secondaryColorDark,
                              ]
                              : [Colors.blue.shade300, Colors.blue.shade600],
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              Text(
                '${context.tr.translate('goal')}: ${context.tr.formatCurrency(savingsData.goal)}',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Additional info about savings calculation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? AppTheme.backgroundDark.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color:
                      isDarkMode
                          ? AppTheme.primaryColorDark
                          : Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr.translate('savings_calculation_info'),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDarkMode
                              ? Colors.white.withOpacity(0.8)
                              : Colors.blue.shade700,
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
