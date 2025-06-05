import 'package:flutter/material.dart';

import '../models/transaction_models.dart';
import '../utils/extensions.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final bool isDarkMode;
  final Color color;
  final IconData icon;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.isDarkMode,
    required this.color,
    required this.icon,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('transaction_${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Show confirmation dialog
          return await _showDeleteConfirmation(context);
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart && onDelete != null) {
          onDelete!();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  transaction.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : null,
                  ),
                ),
              ),
              Text(
                context.tr.formatCurrency(transaction.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Payment method
                  Icon(
                    transaction.paymentMethod == PaymentMethod.cash
                        ? Icons.money
                        : Icons.credit_card,
                    size: 12,
                    color:
                        isDarkMode
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.tr.translate(transaction.paymentMethod.value),
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  // Date
                  Text(
                    context.tr.formatDateWithTranslatedMonths(
                      DateTime.parse(transaction.date),
                      pattern: 'MMM d, yyyy',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              // Bill status for bills
              if (transaction.isBill) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.tr.translate(transaction.billStatusTextKey),
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (transaction.overdue == true &&
                        transaction.overdueDays != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${transaction.overdueDays} ${context.tr.translate('days_overdue')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            context.tr.translate('delete_transaction'),
            style: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : null,
            ),
          ),
          content: Text(
            context.tr.translate('delete_transaction_confirmation'),
            style: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.7)
                      : null,
            ),
          ),
          backgroundColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(context.tr.translate('delete')),
            ),
          ],
        );
      },
    );
  }
}
