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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  periodText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (calculatedRemainingAmount >= 0
                                ? Colors.green
                                : Colors.red)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        calculatedRemainingAmount >= 0
                            ? Icons.savings
                            : Icons.money_off,
                        size: 16,
                        color:
                            calculatedRemainingAmount >= 0
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      remainingAmountText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      formatEuroStyle(calculatedRemainingAmount),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:
                            calculatedRemainingAmount >= 0
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            calculatedRemainingAmount >= 0
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            calculatedRemainingAmount >= 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color:
                                calculatedRemainingAmount >= 0
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${remainingPercentage.abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
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
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBudgetItem(
                  fromPreviousText,
                  fromPrevious,
                  Colors.purple,
                  Icons.history,
                  formatEuroStyle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBudgetItem(
                  incomeText,
                  inflow,
                  Colors.green,
                  Icons.arrow_downward,
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
                  expensesText,
                  outflow,
                  Colors.red,
                  Icons.arrow_upward,
                  formatEuroStyle,
                ),
              ),
              const SizedBox(width: 12),
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

          const SizedBox(height: 24),

          // Gastos combinados (Total expenses)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatEuroStyle(totalExpenses),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalBudget > 0 ? totalExpenses / totalBudget : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getExpenseStatusColor(expensePercentage.toDouble()),
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
