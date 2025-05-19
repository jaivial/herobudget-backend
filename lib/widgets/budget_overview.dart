import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../utils/app_localizations.dart';
import '../theme/app_theme.dart';

class BudgetOverviewWidget extends StatelessWidget {
  final BudgetOverview budgetOverview;

  const BudgetOverviewWidget({super.key, required this.budgetOverview});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          // Cabecera con título y porcentaje
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('money_flow'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              _PercentageBadge(percentage: budgetOverview.moneyFlow.percent),
            ],
          ),

          const SizedBox(height: 20),

          // Cantidad restante
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrencyEuroStyle(
                  localizations.formatCurrency(budgetOverview.remainingAmount),
                ),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('left'),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // Información desde el periodo anterior
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Text('+'),
                const SizedBox(width: 4),
                Text(
                  _formatCurrencyEuroStyle(
                    localizations.formatCurrency(
                      budgetOverview.moneyFlow.fromPrevious,
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Text(
                  localizations.translate('from_previous_period'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Ingresos totales del periodo
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Text('+'),
                const SizedBox(width: 4),
                Text(
                  _formatCurrencyEuroStyle(
                    localizations.formatCurrency(budgetOverview.totalIncome),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Text(
                  localizations.translate('total_income_period'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Barra de progreso
          _BudgetProgressBar(
            spent: budgetOverview.spentAmount,
            upcoming: budgetOverview.upcomingAmount,
            total: budgetOverview.totalAmount,
          ),

          const SizedBox(height: 16),

          // Leyenda de gastos
          Row(
            children: [
              _LegendItem(
                color: Colors.purple,
                label: localizations.translate('spent'),
                amount: _formatCurrencyEuroStyle(
                  localizations.formatCurrency(budgetOverview.spentAmount),
                ),
              ),
              const SizedBox(width: 16),
              _LegendItem(
                color: Colors.amber,
                label: localizations.translate('upcoming'),
                amount: _formatCurrencyEuroStyle(
                  localizations.formatCurrency(budgetOverview.upcomingAmount),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Información de gastos combinados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('combined_expenses'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${_formatCurrencyEuroStyle(localizations.formatCurrency(budgetOverview.combinedExpense))} (${budgetOverview.expensePercent.toStringAsFixed(0)}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Tasa diaria
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('daily_rate'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatCurrencyEuroStyle(
                  localizations.formatCurrency(budgetOverview.dailyRate),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // Advertencia de gasto elevado (solo si es necesario)
          if (budgetOverview.highSpending)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade800.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      localizations.translate('high_spending_warning'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Aquí se manejaría la acción de "Dismiss"
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(localizations.translate('dismiss')),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to ensure Euro currency format with symbol after the amount
  String _formatCurrencyEuroStyle(String formattedAmount) {
    // Si ya contiene el símbolo €, asegurarse de que está después del número sin espacio
    if (formattedAmount.contains('€')) {
      // Eliminar el símbolo € y cualquier espacio, luego añadirlo al final sin espacio
      return formattedAmount.replaceAll('€', '').trim() + '€';
    } else if (formattedAmount.contains('\$')) {
      // Si contiene $ en su lugar, reemplazarlo con €
      return formattedAmount.replaceAll('\$', '').trim() + '€';
    }
    // Si no tiene símbolo, añadir € al final sin espacio
    return formattedAmount.trim() + '€';
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
        color: Colors.purple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${percentage.toStringAsFixed(0)}%',
        style: TextStyle(
          color: Colors.purple.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double upcoming;
  final double total;

  const _BudgetProgressBar({
    required this.spent,
    required this.upcoming,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular porcentajes
    double spentPercent = (total > 0) ? (spent / total * 100) : 0;
    double upcomingPercent = (total > 0) ? (upcoming / total * 100) : 0;

    // Limitar porcentajes al 100%
    if (spentPercent > 100) spentPercent = 100;
    if (spentPercent + upcomingPercent > 100)
      upcomingPercent = 100 - spentPercent;

    return Container(
      height: 10,
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          // Barra de gastado
          Flexible(
            flex: spentPercent.toInt(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          // Barra de próximos gastos
          Flexible(
            flex: upcomingPercent.toInt(),
            child: Container(
              decoration: const BoxDecoration(color: Colors.amber),
            ),
          ),
          // Espacio restante
          Flexible(
            flex: 100 - spentPercent.toInt() - upcomingPercent.toInt(),
            child: Container(),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $amount',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
