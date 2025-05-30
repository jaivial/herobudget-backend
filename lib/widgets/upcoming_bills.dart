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
    print('🔄 UpcomingBillsWidget: External refresh requested');
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
      print(
        '💳 UpcomingBillsWidget: Starting payment process for bill ${bill.id}',
      );

      // Convert Transaction to Invoice for PayBillScreen compatibility
      final invoice = _convertTransactionToInvoice(bill);

      // Navigate to PayBillScreen with preselected invoice
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PayBillScreen(preselectedInvoice: invoice),
        ),
      );

      print('💳 UpcomingBillsWidget: Payment result: $result');

      // If payment was successful, refresh the data
      if (result == true) {
        print('💳 UpcomingBillsWidget: Payment successful, refreshing data...');
        await _fetchUpcomingBills();

        // Notify parent widget to refresh
        if (widget.onRefresh != null) {
          print('💳 UpcomingBillsWidget: Notifying parent widget to refresh');
          widget.onRefresh!();
        }

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
      } else {
        print('💳 UpcomingBillsWidget: Payment was cancelled or failed');
      }
    } catch (e) {
      print('💳 UpcomingBillsWidget: Error in payment process: $e');

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
    final bool isOverdue = transaction.overdue == true;
    final bool isPaid = transaction.paid == true;

    // Enhanced color scheme
    final Color primaryColor =
        isOverdue
            ? Colors.red.shade600
            : isPaid
            ? Colors.green.shade600
            : (isDarkMode
                ? AppTheme.primaryColorDark
                : Theme.of(context).colorScheme.primary);

    final Color borderColor =
        isOverdue
            ? Colors.red.shade300
            : isPaid
            ? Colors.green.shade300
            : isDarkMode
            ? AppTheme.tertiaryColorDark.withOpacity(0.3)
            : Theme.of(context).colorScheme.outline.withOpacity(0.2);

    final Color backgroundColor =
        isOverdue
            ? isDarkMode
                ? Colors.red.shade900.withOpacity(0.15)
                : Colors.red.shade50
            : isPaid
            ? isDarkMode
                ? Colors.green.shade900.withOpacity(0.15)
                : Colors.green.shade50
            : isDarkMode
            ? AppTheme.surfaceDark.withOpacity(0.9)
            : Colors.white;

    // Get a user-friendly display name
    String displayName = _getDisplayName();

    // Check if bill is due soon (within 3 days)
    final DateTime dueDate = DateTime.parse(transaction.date);
    final DateTime now = DateTime.now();
    final int daysUntilDue = dueDate.difference(now).inDays;
    final bool isDueSoon =
        daysUntilDue <= 3 && daysUntilDue >= 0 && !isOverdue && !isPaid;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isOverdue ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Side indicator for overdue bills
            if (isOverdue)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                  ),
                ),
              ),

            // Due soon indicator
            if (isDueSoon)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                  ),
                ),
              ),

            // Main content
            Padding(
              padding: EdgeInsets.only(
                left: (isOverdue || isDueSoon) ? 20 : 20,
                right: 20,
                top: 20,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with icon, title and status badges
                  Row(
                    children: [
                      // Enhanced bill icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor.withOpacity(0.2),
                              primaryColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getTransactionIcon(),
                            style: const TextStyle(fontSize: 28),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Title and status badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status badges row - usando Wrap para evitar overflow
                            if (isOverdue || isPaid || isDueSoon)
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  if (isOverdue)
                                    _StatusBadge(
                                      label: context.tr.translate('overdue'),
                                      color: Colors.red,
                                      icon: Icons.warning_rounded,
                                    ),
                                  if (isPaid)
                                    _StatusBadge(
                                      label: context.tr.translate('paid'),
                                      color: Colors.green,
                                      icon: Icons.check_circle_rounded,
                                    ),
                                  if (isDueSoon && !isOverdue && !isPaid)
                                    _StatusBadge(
                                      label: context.tr.translate('due_soon'),
                                      color: Colors.orange,
                                      icon: Icons.schedule_rounded,
                                    ),
                                ],
                              ),

                            if (isOverdue || isPaid || isDueSoon)
                              const SizedBox(height: 8),

                            // Bill name
                            Text(
                              displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Amount column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            context.tr.formatCurrency(transaction.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color:
                                  isOverdue
                                      ? Colors.red.shade700
                                      : isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                          ),
                          if (isOverdue && transaction.overdueDays != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${transaction.overdueDays}d ${context.tr.translate('overdue').toLowerCase()}',
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Details row
                  Row(
                    children: [
                      // Due date info (expanded to take more space)
                      Expanded(
                        flex: 2,
                        child: _InfoChip(
                          icon: Icons.schedule_rounded,
                          label: context.tr.formatDateWithTranslatedMonths(
                            DateTime.parse(transaction.date),
                            pattern: 'MMM d, yyyy',
                          ),
                          isDarkMode: isDarkMode,
                          color: isDueSoon ? Colors.orange : null,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Action button
                      if (showPayButton && onPayBill != null && !isPaid)
                        Flexible(
                          flex: 1,
                          child: _PayButton(
                            onPressed: onPayBill!,
                            isOverdue: isOverdue,
                            isDarkMode: isDarkMode,
                            context: context,
                          ),
                        ),
                    ],
                  ),
                ],
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

// Helper widget for status badges
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for info chips
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDarkMode;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDarkMode,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? (isDarkMode ? Colors.white70 : Colors.grey.shade600);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border:
            color != null
                ? Border.all(color: color!.withOpacity(0.3), width: 1)
                : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: effectiveColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for pay button
class _PayButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isOverdue;
  final bool isDarkMode;
  final BuildContext context;

  const _PayButton({
    required this.onPressed,
    required this.isOverdue,
    required this.isDarkMode,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final Color buttonColor =
        isOverdue
            ? Colors.red.shade600
            : (isDarkMode
                ? AppTheme.primaryColorDark
                : Theme.of(context).colorScheme.primary);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          isOverdue ? Icons.priority_high_rounded : Icons.payment_rounded,
          size: 16,
        ),
        label: Text(
          isOverdue
              ? context.tr.translate('pay_now')
              : context.tr.translate('pay'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
