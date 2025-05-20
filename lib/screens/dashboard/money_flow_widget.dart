import 'package:flutter/material.dart';
import 'package:hero_budget/utils/app_localizations.dart';
import 'package:intl/intl.dart';

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
    // Cálculo del dinero restante según la fórmula: ingresos totales - gastos realizados - facturas pendientes
    // El dinero heredado de periodos anteriores ya está incluido en los ingresos totales (totalBudget)
    final totalBudget = inflow + fromPrevious;
    final totalExpenses = outflow + upcomingBills;
    final calculatedRemainingAmount = totalBudget - totalExpenses;

    final expensePercentage =
        totalBudget > 0 ? (totalExpenses / totalBudget) * 100 : 0;
    final remainingPercentage =
        totalBudget > 0 ? (calculatedRemainingAmount / totalBudget) * 100 : 0;

    // Format numbers with Euro currency
    final currencyFormat = NumberFormat.currency(
      symbol: '€',
      decimalDigits: 2,
      locale: 'es_ES',
    );

    // Format function to ensure correct Euro style (symbol after the number)
    String formatEuroStyle(double amount) {
      final formatted = currencyFormat.format(amount);
      // Ensure € symbol is after the number without space
      if (formatted.startsWith('€')) {
        return formatted.substring(1).trim() + '€';
      }
      // Si tiene espacios entre el número y el símbolo, quitarlos
      return formatted.replaceAll(' €', '€');
    }

    // Get localized texts
    final appLocalizations = AppLocalizations.of(context);
    final String periodText = appLocalizations.translate('${period}_period');
    final String moneyFlowText = appLocalizations.translate('money_flow');
    final String remainingAmountText = appLocalizations.translate(
      'remaining_amount',
    );
    final String fromPreviousText = appLocalizations.translate('previous');
    final String incomeText = appLocalizations.translate('income');
    final String expensesText = appLocalizations.translate('expenses');
    final String upcomingText = appLocalizations.translate('upcoming');
    final String totalExpensesText = appLocalizations.translate(
      'total_expenses',
    );
    final String budgetUsedText = appLocalizations.translate('budget_used');
    final String totalBudgetText = appLocalizations.translate('total_budget');

    // Determine if we're in dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Título "Flujo de Dinero" y porcentaje de gastado en morado
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
                    moneyFlowText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
                  '${expensePercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Dinero restante en grande y los ingresos totales a la derecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remainingAmountText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatEuroStyle(calculatedRemainingAmount),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color:
                            calculatedRemainingAmount >= 0
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      totalBudgetText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatEuroStyle(totalBudget),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Dinero heredado del periodo anterior
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, color: Colors.purple, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$fromPreviousText: ${formatEuroStyle(fromPrevious)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildBudgetItem(
                  incomeText,
                  inflow,
                  Colors.green,
                  Icons.arrow_downward,
                  formatEuroStyle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBudgetItem(
                  expensesText,
                  outflow,
                  Colors.red,
                  Icons.arrow_upward,
                  formatEuroStyle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildBudgetItem(
                  upcomingText,
                  upcomingBills,
                  Colors.orange,
                  Icons.calendar_today,
                  formatEuroStyle,
                ),
              ),
            ],
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
                    totalExpenses > totalBudget
                        ? Colors.red.withOpacity(0.3)
                        : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budgetUsedText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    // Barra de fondo
                    Container(
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(7.5),
                      ),
                    ),
                    // Barra de gastos realizados
                    FractionallySizedBox(
                      widthFactor:
                          totalBudget > 0
                              ? (outflow / totalBudget).clamp(0.0, 1.0)
                              : 0,
                      child: Container(
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(7.5),
                        ),
                      ),
                    ),
                    // Barra de facturas pendientes
                    FractionallySizedBox(
                      widthFactor:
                          totalBudget > 0
                              ? ((outflow + upcomingBills) / totalBudget).clamp(
                                    0.0,
                                    1.0,
                                  ) -
                                  (outflow / totalBudget).clamp(0.0, 1.0)
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
                    if (totalExpenses > totalBudget)
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expensesText,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          upcomingText,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      '${(expensePercentage).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getExpenseStatusColor(
                          expensePercentage.toDouble(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Gastos combinados (Total expenses)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    expensePercentage > 100
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
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pie_chart,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              totalExpensesText,
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
                              formatEuroStyle(totalExpenses),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getExpenseStatusColor(
                                  expensePercentage.toDouble(),
                                ),
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
                        color: _getExpenseStatusColor(
                          expensePercentage.toDouble(),
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${expensePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getExpenseStatusColor(
                            expensePercentage.toDouble(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Tasa diaria de gasto
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
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
                            'Tasa diaria:', // Añadir a AppLocalizations
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        // Este valor vendrá de la API
                        _calculateDailyRate(totalExpenses, period),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
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

  String _calculateDailyRate(double expenses, String period) {
    // Cálculo temporal hasta que se implemente en la API
    int days = 30; // Por defecto (mensual)

    switch (period) {
      case 'daily':
        days = 1;
      case 'weekly':
        days = 7;
      case 'monthly':
        days = 30;
      case 'quarterly':
        days = 90;
      case 'yearly':
        days = 365;
    }

    final dailyRate = expenses / days;

    // Format with currency
    final currencyFormat = NumberFormat.currency(
      symbol: '€',
      decimalDigits: 2,
      locale: 'es_ES',
    );

    final formatted = currencyFormat.format(dailyRate);
    // Ensure € symbol is after the number without space
    if (formatted.startsWith('€')) {
      return formatted.substring(1).trim() + '€';
    }
    return formatted.replaceAll(' €', '€') + '/día'; // Add /día suffix
  }

  Widget _buildBudgetItem(
    String title,
    double amount,
    Color color,
    IconData icon,
    String Function(double) formatter,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatter(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getExpenseStatusColor(double expensePercentage) {
    if (expensePercentage > 100) {
      return Colors.red;
    } else if (expensePercentage > 80) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
