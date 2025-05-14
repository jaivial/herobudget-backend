import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_model.dart';
import '../utils/app_localizations.dart';

class UpcomingBillsWidget extends StatelessWidget {
  final List<Bill> bills;
  final VoidCallback? onAddBill;

  const UpcomingBillsWidget({super.key, required this.bills, this.onAddBill});

  @override
  Widget build(BuildContext context) {
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
          // Title and description
          Text(
            context.tr.translate('upcoming_bills'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // List of bills
          bills.isEmpty
              ? _EmptyBillsList(onAddBill: onAddBill)
              : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bills.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return BillItem(bill: bills[index]);
                },
              ),

          // Button to add new bill
          if (bills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: InkWell(
                onTap: onAddBill,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr.translate('add_bill'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyBillsList extends StatelessWidget {
  final VoidCallback? onAddBill;

  const _EmptyBillsList({this.onAddBill});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(
          Icons.receipt_long_outlined,
          size: 60,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.3),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr.translate('no_bills'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onAddBill,
          icon: const Icon(Icons.add),
          label: Text(context.tr.translate('add_bill')),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class BillItem extends StatelessWidget {
  final Bill bill;
  final VoidCallback? onPayBill;

  const BillItem({super.key, required this.bill, this.onPayBill});

  @override
  Widget build(BuildContext context) {
    // Determine colors based on status
    final Color borderColor =
        bill.overdue
            ? Colors.red.shade300
            : Theme.of(context).colorScheme.outline.withOpacity(0.2);

    final Color backgroundColor =
        bill.overdue
            ? Colors.red.shade50
            : Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Side bar for overdue bills
          if (bill.overdue)
            Container(
              width: 4,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Bill icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      bill.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Bill details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bill status (if overdue)
                        if (bill.overdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              context.tr.translate('overdue'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        // Name and category
                        Text(
                          bill.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        if (bill.overdue)
                          Text(
                            '${context.tr.translate('overdue_by')} ${bill.overdueDays} ${context.tr.translate('days')}',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Amount and due date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        context.tr.formatCurrency(bill.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            context.tr.formatDate(
                              DateTime.parse(bill.dueDate),
                              pattern: 'MMM d',
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (onPayBill != null)
                        ElevatedButton(
                          onPressed: onPayBill,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                            minimumSize: const Size(60, 30),
                          ),
                          child: Text(context.tr.translate('pay')),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
