import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../utils/app_localizations.dart';
import '../theme/app_theme.dart';

class CashBankDistributionWidget extends StatelessWidget {
  final CashBankDistribution distribution;
  final VoidCallback onTransferTap;

  const CashBankDistributionWidget({
    super.key,
    required this.distribution,
    required this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
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
          // Title and Transfer button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr.translate('cash_bank_distribution'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              // Transfer button
              TextButton.icon(
                onPressed: onTransferTap,
                icon: Icon(
                  Icons.swap_horiz,
                  size: 16,
                  color: isDarkMode ? AppTheme.tertiaryColorDark : null,
                ),
                label: Text(
                  context.tr.translate('transfer'),
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

          // Cash amount
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? AppTheme.primaryColorDark.withOpacity(0.3)
                          : Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.attach_money,
                  color: isDarkMode ? AppTheme.primaryColorDark : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.translate('cash'),
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? Colors.white.withOpacity(0.7)
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      context.tr.formatCurrency(distribution.cashAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? AppTheme.primaryColorDark.withOpacity(0.2)
                          : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${distribution.cashPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color:
                        isDarkMode ? AppTheme.primaryColorDark : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bank amount
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? AppTheme.secondaryColorDark.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance,
                  color: isDarkMode ? AppTheme.secondaryColorDark : Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.translate('bank'),
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? Colors.white.withOpacity(0.7)
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      context.tr.formatCurrency(distribution.bankAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? AppTheme.secondaryColorDark.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${distribution.bankPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color:
                        isDarkMode ? AppTheme.secondaryColorDark : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr.translate('total'),
                style: TextStyle(
                  color:
                      isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                context.tr.formatCurrency(distribution.monthlyTotal),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
