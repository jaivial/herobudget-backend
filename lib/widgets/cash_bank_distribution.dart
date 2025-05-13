import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import 'package:intl/intl.dart';

class CashBankDistributionWidget extends StatelessWidget {
  final CashBankDistribution distribution;
  final VoidCallback? onTransferTap;

  const CashBankDistributionWidget({
    super.key,
    required this.distribution,
    this.onTransferTap,
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
          // Título con fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cash & Bank Distribution',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                distribution.month,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Distribución de efectivo
          _DistributionItem(
            icon: Icons.attach_money,
            iconBackground: Colors.green,
            title: 'Cash',
            percentage: distribution.cashPercent,
            amount: distribution.cashAmount,
          ),

          const SizedBox(height: 16),

          // Distribución de banco
          _DistributionItem(
            icon: Icons.account_balance,
            iconBackground: Colors.blue,
            title: 'Bank',
            percentage: distribution.bankPercent,
            amount: distribution.bankAmount,
          ),

          // Línea separadora
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),

          // Total mensual y botón de transferencia
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total for monthly',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    currencyFormatter.format(distribution.monthlyTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              // Botón de transferencia
              if (onTransferTap != null)
                OutlinedButton.icon(
                  onPressed: onTransferTap,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Transfer'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionItem extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final double percentage;
  final double amount;

  const _DistributionItem({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.percentage,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    // Formateo de moneda
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );

    return Row(
      children: [
        // Icono
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBackground.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconBackground, size: 24),
        ),

        const SizedBox(width: 16),

        // Información
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y porcentaje
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: iconBackground,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Barra de progreso
              Stack(
                children: [
                  // Barra de fondo
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Barra de progreso
                  FractionallySizedBox(
                    widthFactor: percentage / 100,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Cantidad
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  currencyFormatter.format(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
