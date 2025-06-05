import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/extensions.dart';

class PeriodSelectorMonthly extends StatefulWidget {
  final Function(String) onPeriodChanged;
  final Function(DateTime)? onDateChanged;
  final DateTime? initialDate;

  const PeriodSelectorMonthly({
    super.key,
    required this.onPeriodChanged,
    this.onDateChanged,
    this.initialDate,
  });

  @override
  State<PeriodSelectorMonthly> createState() => _PeriodSelectorMonthlyState();
}

class _PeriodSelectorMonthlyState extends State<PeriodSelectorMonthly> {
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    // Initialize with provided date or current month
    _currentDate = widget.initialDate ?? DateTime.now();
    // Ensure we're on the first day of the month
    _currentDate = DateTime(_currentDate.year, _currentDate.month, 1);
  }

  /// Get the formatted title for the current month
  String get monthTitle {
    return context.tr.formatDateWithTranslatedMonths(
      _currentDate,
      pattern: 'MMM yyyy',
    );
  }

  /// Navigate to the previous month
  void _navigateToPreviousMonth() {
    final previousMonth = DateTime(
      _currentDate.year,
      _currentDate.month - 1,
      1,
    );

    // Validate date range (10 years back)
    final minAllowedDate = DateTime.now().subtract(
      const Duration(days: 365 * 10),
    );
    if (previousMonth.isAfter(minAllowedDate)) {
      setState(() {
        _currentDate = previousMonth;
      });

      // Notify parent widgets
      widget.onPeriodChanged('monthly');
      if (widget.onDateChanged != null) {
        widget.onDateChanged!(_currentDate);
      }
    }
  }

  /// Navigate to the next month
  void _navigateToNextMonth() {
    final nextMonth = DateTime(_currentDate.year, _currentDate.month + 1, 1);

    // Validate date range (5 years forward)
    final maxAllowedDate = DateTime.now().add(const Duration(days: 365 * 5));
    if (nextMonth.isBefore(maxAllowedDate)) {
      setState(() {
        _currentDate = nextMonth;
      });

      // Notify parent widgets
      widget.onPeriodChanged('monthly');
      if (widget.onDateChanged != null) {
        widget.onDateChanged!(_currentDate);
      }
    }
  }

  /// Show month picker dialog
  Future<void> _showMonthPicker() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (selectedDate != null) {
      setState(() {
        _currentDate = DateTime(selectedDate.year, selectedDate.month, 1);
      });

      // Notify parent widgets
      widget.onPeriodChanged('monthly');
      if (widget.onDateChanged != null) {
        widget.onDateChanged!(_currentDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous month button
          IconButton(
            onPressed: _navigateToPreviousMonth,
            icon: const Icon(Icons.chevron_left),
            tooltip: context.tr.translate('previous_month'),
          ),

          // Current month display (tappable)
          Expanded(
            child: GestureDetector(
              onTap: _showMonthPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  monthTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Next month button
          IconButton(
            onPressed: _navigateToNextMonth,
            icon: const Icon(Icons.chevron_right),
            tooltip: context.tr.translate('next_month'),
          ),
        ],
      ),
    );
  }
}
