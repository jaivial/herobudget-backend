import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import '../theme/app_theme.dart';

// Modelo local para desacoplar del backend
class BudgetOverview {
  final double remainingAmount;
  final double expensePercent;
  final double spentAmount;
  final double upcomingAmount;
  final double totalAmount;
  final double combinedExpense;
  final double totalIncome;
  final double dailyRate;
  final bool highSpending;
  final MoneyFlow moneyFlow;

  BudgetOverview({
    required this.remainingAmount,
    required this.expensePercent,
    required this.spentAmount,
    required this.upcomingAmount,
    required this.totalAmount,
    required this.combinedExpense,
    required this.totalIncome,
    required this.dailyRate,
    required this.highSpending,
    required this.moneyFlow,
  });

  // Factory para crear datos de ejemplo
  factory BudgetOverview.example() {
    return BudgetOverview(
      remainingAmount: 1245.30,
      expensePercent: 75.8,
      spentAmount: 3500.00,
      upcomingAmount: 750.50,
      totalAmount: 5000.00,
      combinedExpense: 4250.50,
      totalIncome: 5495.80,
      dailyRate: 141.68,
      highSpending: false,
      moneyFlow: MoneyFlow(fromPrevious: 495.80),
    );
  }
}

// Clase adicional para el modelo MoneyFlow
class MoneyFlow {
  final double fromPrevious;

  MoneyFlow({required this.fromPrevious});
}

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    localizations.translate('money_flow'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : null,
                    ),
                  ),
                ],
              ),
              // Badge de porcentaje con fondo morado
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${budgetOverview.expensePercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Dinero restante (centrado)
          Center(
            child: Column(
              children: [
                Text(
                  localizations.translate('remaining_amount'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrencyEuroStyle(
                    localizations.formatCurrency(
                      budgetOverview.remainingAmount,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color:
                        budgetOverview.remainingAmount >= 0
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Dinero heredado del periodo anterior
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, color: Colors.deepPurple, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${localizations.translate('previous')}: ${_formatCurrencyEuroStyle(localizations.formatCurrency(budgetOverview.moneyFlow.fromPrevious))}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Gráfico de barra para gastos (gastado y próximo)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    budgetOverview.combinedExpense > budgetOverview.totalAmount
                        ? Colors.red.withOpacity(0.3)
                        : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Stack(
                  children: [
                    // Barra de fondo
                    Container(
                      height: 15,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(7.5),
                      ),
                    ),
                    // Barra de gastos realizados
                    FractionallySizedBox(
                      widthFactor:
                          budgetOverview.totalAmount > 0
                              ? (budgetOverview.spentAmount /
                                      budgetOverview.totalAmount)
                                  .clamp(0.0, 1.0)
                              : 0,
                      child: Container(
                        height: 15,
                        decoration: BoxDecoration(
                          color:
                              budgetOverview.expensePercent >= 100
                                  ? Colors.red
                                  : Colors.deepPurple,
                          borderRadius: BorderRadius.circular(7.5),
                        ),
                      ),
                    ),
                    // Barra de facturas pendientes
                    FractionallySizedBox(
                      widthFactor:
                          budgetOverview.totalAmount > 0
                              ? ((budgetOverview.spentAmount +
                                              budgetOverview.upcomingAmount) /
                                          budgetOverview.totalAmount)
                                      .clamp(0.0, 1.0) -
                                  (budgetOverview.spentAmount /
                                          budgetOverview.totalAmount)
                                      .clamp(0.0, 1.0)
                              : 0,
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(7.5),
                        ),
                      ),
                    ),
                    // Indicador de 100%
                    if (budgetOverview.combinedExpense >
                        budgetOverview.totalAmount)
                      Positioned(
                        right: 0,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              '!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Mejorar la legibilidad de las leyendas distribuyéndolas en dos líneas
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getSpentColor(
                                    budgetOverview.expensePercent,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${localizations.translate('spent')}:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isDarkMode
                                            ? Colors.white70
                                            : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_formatCurrencyEuroStyle(localizations.formatCurrency(budgetOverview.spentAmount))} (${_getPercentage(budgetOverview.spentAmount, budgetOverview.totalAmount)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? Colors.white
                                    : _getSpentColor(
                                      budgetOverview.expensePercent,
                                    ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${localizations.translate('upcoming')}:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isDarkMode
                                            ? Colors.white70
                                            : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_formatCurrencyEuroStyle(localizations.formatCurrency(budgetOverview.upcomingAmount))} (${_getPercentage(budgetOverview.upcomingAmount, budgetOverview.totalAmount)}%)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Ingresos Totales (nuevo container)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        size: 16,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.translate('total_income'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrencyEuroStyle(
                            localizations.formatCurrency(
                              budgetOverview.totalIncome,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Gastos combinados (Total expenses)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    budgetOverview.expensePercent > 100
                        ? Colors.red.withOpacity(0.3)
                        : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pie_chart,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('combined_expenses'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatCurrencyEuroStyle(
                                localizations.formatCurrency(
                                  budgetOverview.combinedExpense,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${budgetOverview.expensePercent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Tasa diaria de gasto con mejor visibilidad
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
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            localizations.translate('daily_rate') + ':',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode
                                      ? Colors.white
                                      : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatCurrencyEuroStyle(
                              localizations.formatCurrency(
                                budgetOverview.dailyRate,
                              ),
                            ) +
                            '/día',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  Color _getExpenseStatusColor(double percentage) {
    if (percentage > 100) {
      return Colors.red;
    } else if (percentage > 80) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  double _getPercentage(double part, double total) {
    if (total > 0) {
      return double.parse(((part / total) * 100).toStringAsFixed(1));
    } else {
      return 0;
    }
  }

  Color _getSpentColor(double percentage) {
    if (percentage >= 100) {
      return Colors.red;
    } else {
      return Colors.deepPurple;
    }
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
