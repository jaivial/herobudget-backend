import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import 'package:intl/intl.dart';

class SavingsOverviewWidget extends StatelessWidget {
  final SavingsOverview savingsOverview;
  final Function()? onEditGoal;

  const SavingsOverviewWidget({
    super.key,
    required this.savingsOverview,
    this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    // Formateo de moneda
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );

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
          // Cabecera con título y porcentaje
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Savings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _PercentageBadge(percentage: savingsOverview.percent),
            ],
          ),

          const SizedBox(height: 20),

          // Cantidad disponible
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormatter.format(savingsOverview.available),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'available',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barra de progreso hacia la meta
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Goal: ${currencyFormatter.format(savingsOverview.goal)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  // Botón para editar la meta
                  if (onEditGoal != null)
                    TextButton(
                      onPressed: onEditGoal,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        backgroundColor: Colors.green.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Edit Goal'),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Barra de progreso
              _SavingsProgressBar(
                available: savingsOverview.available,
                goal: savingsOverview.goal,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Información sobre la meta
          Column(
            children: [
              // Cantidad que falta por ahorrar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Need to save:',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    currencyFormatter.format(savingsOverview.needToSave),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Objetivo diario
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily target:',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    currencyFormatter.format(savingsOverview.dailyTarget),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
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
