import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../utils/extensions.dart';
import '../theme/app_theme.dart';
import 'budget_overview.dart'; // Import para usar PeriodCashBankDistribution
import 'transfer_modal.dart';

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Check if all amounts are zero
    final bool hasNoData =
        distribution.cashAmount == 0 &&
        distribution.bankAmount == 0 &&
        distribution.monthlyTotal == 0;

    // Improved color scheme for better contrast
    final Color surfaceColor =
        isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
    final Color secondaryTextColor =
        isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    final Color cashColor =
        isDarkMode ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
    final Color bankColor =
        isDarkMode ? const Color(0xFF42A5F5) : const Color(0xFF1565C0);
    final Color borderColor =
        isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
    final Color transferButtonColor =
        isDarkMode ? const Color(0xFF4FC3F7) : const Color(0xFF1976D2);
    final Color transferButtonBgColor =
        isDarkMode ? const Color(0xFF263238) : const Color(0xFFE3F2FD);
    final Color transferButtonBorderColor =
        isDarkMode ? const Color(0xFF4FC3F7) : const Color(0xFF1976D2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  color: primaryTextColor,
                  letterSpacing: -0.5,
                ),
              ),
              // Transfer button
              Container(
                decoration: BoxDecoration(
                  color: transferButtonBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: transferButtonBorderColor.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: TextButton.icon(
                  onPressed: hasNoData ? null : onTransferTap,
                  icon: Icon(
                    Icons.swap_horiz,
                    size: 18,
                    color: hasNoData ? secondaryTextColor : transferButtonColor,
                  ),
                  label: Text(
                    context.tr.translate('transfer'),
                    style: TextStyle(
                      color:
                          hasNoData ? secondaryTextColor : transferButtonColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Show "No data" message when all values are zero
          if (hasNoData)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: secondaryTextColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: secondaryTextColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 32, color: secondaryTextColor),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.translate('no_cash_bank_data'),
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr.translate(
                      'add_transactions_to_see_distribution',
                    ),
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            // Cash amount
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cashColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cashColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(Icons.attach_money, color: cashColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.translate('cash'),
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr.formatCurrency(distribution.cashAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: primaryTextColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cashColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cashColor.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${distribution.cashPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: cashColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Bank amount
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bankColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: bankColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: bankColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.translate('bank'),
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr.formatCurrency(distribution.bankAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: primaryTextColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bankColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: bankColor.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${distribution.bankPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: bankColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Total amount
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 1.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr.translate('total'),
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    context.tr.formatCurrency(distribution.monthlyTotal),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: primaryTextColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Helper function to show transfer modal
void showTransferModal(
  BuildContext context,
  CashBankDistribution distribution,
  VoidCallback onTransferComplete,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return TransferModal(
        distribution: distribution,
        onTransferComplete: onTransferComplete,
      );
    },
  );
}
