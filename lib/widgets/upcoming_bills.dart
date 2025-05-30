import 'package:flutter/material.dart';

import '../models/transaction_models.dart';
import '../services/transaction_service.dart';
import '../utils/extensions.dart';
import '../utils/icon_utils.dart';
import '../utils/emoji_utils.dart';
import '../theme/app_theme.dart';
import '../screens/invoice/pay_bill_screen.dart';
import '../models/invoice_model.dart';

class UpcomingBillsWidget extends StatefulWidget {
  final String? period;
  final String? date;
  final VoidCallback? onAddBill;
  final VoidCallback? onRefresh;

  const UpcomingBillsWidget({
    super.key,
    this.period,
    this.date,
    this.onAddBill,
    this.onRefresh,
  });

  @override
  State<UpcomingBillsWidget> createState() => _UpcomingBillsWidgetState();
}

class _UpcomingBillsWidgetState extends State<UpcomingBillsWidget> {
  final TransactionService _transactionService = TransactionService();

  UpcomingBillsResponse? _billsResponse;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingBills();
  }

  @override
  void didUpdateWidget(UpcomingBillsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data if period or date changed
    if (oldWidget.period != widget.period || oldWidget.date != widget.date) {
      _fetchUpcomingBills();
    }
  }

  Future<void> _fetchUpcomingBills() async {
    // Evitar múltiples refreshes simultáneos
    if (_isRefreshing || !mounted) return;

    setState(() {
      _isRefreshing = true;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _transactionService.fetchUpcomingBills(
        period: widget.period,
        date: widget.date,
      );

      if (mounted) {
        setState(() {
          _billsResponse = response;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isRefreshing = false;
          // Fallback to empty response
          _billsResponse = const UpcomingBillsResponse(
            bills: [],
            total: 0,
            overdue: 0,
            upcoming: 0,
            thisWeek: 0,
            thisMonth: 0,
          );
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _fetchUpcomingBills();
  }

  // Método público para refrescar los datos desde el widget padre
  Future<void> refreshData() async {
    await _fetchUpcomingBills();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and statistics
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr.translate('upcoming_bills'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : null,
              ),
            ),
          ],
        ),

        // Statistics row
        if (_billsResponse != null && !_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Row(
              children: [
                _StatisticChip(
                  label: context.tr.translate('total'),
                  value: _billsResponse!.total.toString(),
                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                ),
                const SizedBox(width: 8),
                if (_billsResponse!.overdue > 0)
                  _StatisticChip(
                    label: context.tr.translate('overdue'),
                    value: _billsResponse!.overdue.toString(),
                    color: Colors.red,
                  ),
                const SizedBox(width: 8),
                if (_billsResponse!.thisWeek > 0)
                  _StatisticChip(
                    label: context.tr.translate('this_week'),
                    value: _billsResponse!.thisWeek.toString(),
                    color: isDarkMode ? Colors.orange.shade300 : Colors.orange,
                  ),
              ],
            ),
          ),

        // Error message
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr.translate('connection_error'),
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Content area - with scroll
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loading state
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                // Empty state
                else if (_billsResponse == null ||
                    _billsResponse!.bills.isEmpty)
                  _EmptyBillsList(
                    onAddBill: widget.onAddBill,
                    isDarkMode: isDarkMode,
                  )
                // Bills list
                else
                  Column(
                    children: [
                      // Overdue bills section
                      if (_billsResponse!.overdueBills.isNotEmpty) ...[
                        _SectionHeader(
                          title: context.tr.translate('overdue_bills'),
                          count: _billsResponse!.overdueBills.length,
                          color: Colors.red,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 8),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _billsResponse!.overdueBills.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return TransactionBillItem(
                              transaction: _billsResponse!.overdueBills[index],
                              isDarkMode: isDarkMode,
                              onPayBill:
                                  () => _handlePayBill(
                                    _billsResponse!.overdueBills[index],
                                  ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Upcoming bills section
                      if (_billsResponse!.upcomingBills.isNotEmpty) ...[
                        _SectionHeader(
                          title: context.tr.translate('upcoming_bills'),
                          count: _billsResponse!.upcomingBills.length,
                          color:
                              isDarkMode ? Colors.blue.shade300 : Colors.blue,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 8),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _billsResponse!.upcomingBills.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return TransactionBillItem(
                              transaction: _billsResponse!.upcomingBills[index],
                              isDarkMode: isDarkMode,
                              onPayBill:
                                  () => _handlePayBill(
                                    _billsResponse!.upcomingBills[index],
                                  ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Paid bills section (collapsed by default)
                      if (_billsResponse!.paidBills.isNotEmpty) ...[
                        ExpansionTile(
                          title: Text(
                            '${context.tr.translate('paid_bills')} (${_billsResponse!.paidBills.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : null,
                            ),
                          ),
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _billsResponse!.paidBills.length,
                              separatorBuilder:
                                  (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                return TransactionBillItem(
                                  transaction: _billsResponse!.paidBills[index],
                                  isDarkMode: isDarkMode,
                                  showPayButton: false,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                // Button to add new bill
                if (_billsResponse != null && _billsResponse!.bills.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: InkWell(
                      onTap: widget.onAddBill,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? AppTheme.tertiaryColorDark.withOpacity(
                                      0.5,
                                    )
                                    : Theme.of(
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
                              color:
                                  isDarkMode
                                      ? AppTheme.primaryColorDark
                                      : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr.translate('add_bill'),
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppTheme.primaryColorDark
                                        : Theme.of(context).colorScheme.primary,
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
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayBill(Transaction bill) async {
    try {
      // Convert Transaction to Invoice for PayBillScreen compatibility
      final invoice = _convertTransactionToInvoice(bill);

      // Navigate to PayBillScreen with preselected invoice
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PayBillScreen(preselectedInvoice: invoice),
        ),
      );

      // If payment was successful, refresh the data
      if (result == true) {
        await _fetchUpcomingBills();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.translate('payment_successful')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Handle navigation error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr.translate('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Helper method to convert Transaction to Invoice
  Invoice _convertTransactionToInvoice(Transaction transaction) {
    return Invoice(
      id: transaction.id,
      name: transaction.name ?? transaction.displayName,
      amount: transaction.amount,
      dueDate: transaction.date,
      paid: transaction.paid ?? false,
      overdue: transaction.overdue ?? false,
      overdueDays: transaction.overdueDays ?? 0,
      recurring: transaction.recurring ?? false,
      category: transaction.category,
      icon: transaction.icon ?? 'receipt_long',
      description: transaction.description,
      paymentMethod: transaction.paymentMethod.value,
    );
  }
}

class _EmptyBillsList extends StatelessWidget {
  final VoidCallback? onAddBill;
  final bool isDarkMode;

  const _EmptyBillsList({this.onAddBill, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.receipt_long_outlined,
            size: 60,
            color:
                isDarkMode
                    ? Colors.white.withOpacity(0.3)
                    : Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr.translate('no_bills'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color:
                  isDarkMode
                      ? Colors.white.withOpacity(0.7)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAddBill,
            icon: const Icon(Icons.add),
            label: Text(context.tr.translate('add_bill')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: isDarkMode ? AppTheme.primaryColorDark : null,
              foregroundColor: isDarkMode ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widgets for the new upcoming bills widget
class _StatisticChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatisticChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final bool isDarkMode;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDarkMode ? Colors.white : null,
          ),
        ),
      ],
    );
  }
}

class TransactionBillItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onPayBill;
  final bool isDarkMode;
  final bool showPayButton;

  const TransactionBillItem({
    super.key,
    required this.transaction,
    this.onPayBill,
    required this.isDarkMode,
    this.showPayButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on status
    final Color borderColor =
        transaction.overdue == true
            ? Colors.red.shade300
            : isDarkMode
            ? AppTheme.tertiaryColorDark.withOpacity(0.3)
            : Theme.of(context).colorScheme.outline.withOpacity(0.2);

    final Color backgroundColor =
        transaction.overdue == true
            ? isDarkMode
                ? Colors.red.shade900.withOpacity(0.2)
                : Colors.red.shade50
            : isDarkMode
            ? AppTheme.surfaceDark.withOpacity(0.8)
            : Colors.white;

    // Get a user-friendly display name
    String displayName = _getDisplayName();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Side indicator for overdue bills
            if (transaction.overdue == true)
              Container(
                width: 5,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Bill icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? AppTheme.primaryColorDark.withOpacity(0.2)
                                    : Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  _getTransactionIcon(),
                                  style: const TextStyle(fontSize: 24),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Bill details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status badge
                              if (transaction.overdue == true ||
                                  transaction.paid == true)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        transaction.overdue == true
                                            ? Colors.red
                                            : Colors.green,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    transaction.overdue == true
                                        ? context.tr.translate('overdue')
                                        : context.tr.translate('paid'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                              // Bill name
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              // Category with icon
                              Row(
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 14,
                                    color:
                                        isDarkMode
                                            ? Colors.white.withOpacity(0.6)
                                            : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      transaction.category,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isDarkMode
                                                ? Colors.white.withOpacity(0.6)
                                                : Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              // Overdue days info
                              if (transaction.overdue == true &&
                                  transaction.overdueDays != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${context.tr.translate('overdue_by')} ${transaction.overdueDays} ${context.tr.translate('days')}',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Amount and actions
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Amount
                            Text(
                              context.tr.formatCurrency(transaction.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color:
                                    transaction.overdue == true
                                        ? Colors.red.shade700
                                        : isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Due date
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 12,
                                    color:
                                        isDarkMode
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.tr.formatDateWithTranslatedMonths(
                                      DateTime.parse(transaction.date),
                                      pattern: 'MMM d',
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isDarkMode
                                              ? Colors.white.withOpacity(0.7)
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Pay button
                            if (showPayButton &&
                                onPayBill != null &&
                                transaction.paid != true)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ElevatedButton(
                                  onPressed: onPayBill,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    minimumSize: const Size(70, 32),
                                    backgroundColor:
                                        isDarkMode
                                            ? AppTheme.primaryColorDark
                                            : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(context.tr.translate('pay')),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get a user-friendly display name
  String _getDisplayName() {
    // If the name looks like a technical identifier, use category instead
    if (transaction.name != null &&
        !transaction.name!.contains('_') &&
        !transaction.name!.contains('receipt') &&
        transaction.name!.length > 2) {
      return transaction.name!;
    }

    // If description exists and is meaningful, use it
    if (transaction.description != null &&
        transaction.description!.isNotEmpty &&
        !transaction.description!.contains('_')) {
      return transaction.description!;
    }

    // Fallback to category with a prefix
    return '${transaction.category} Bill';
  }

  // Helper method to get appropriate icon/emoji for the transaction
  String _getTransactionIcon() {
    // First try to clean the icon from the transaction
    if (transaction.icon != null && transaction.icon!.isNotEmpty) {
      String cleanIcon = EmojiUtils.cleanEmoji(transaction.icon!);
      if (EmojiUtils.isValidEmoji(cleanIcon)) {
        return cleanIcon;
      }
    }

    // Try to get emoji based on category name
    String categoryEmoji = EmojiUtils.getEmojiForCategory(transaction.category);
    if (EmojiUtils.isValidEmoji(categoryEmoji)) {
      return categoryEmoji;
    }

    // Fallback to IconUtils
    return IconUtils.getAppropriateEmoji(
      categoryName: transaction.category,
      iconName: transaction.icon,
    );
  }
}
