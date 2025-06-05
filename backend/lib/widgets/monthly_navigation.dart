import 'package:flutter/material.dart';
import '../utils/extensions.dart';

class MonthlyNavigation extends StatefulWidget {
  final DateTime currentDate;
  final Function(DateTime) onDateChanged;
  final bool showMonthPicker;
  final EdgeInsets? padding;

  const MonthlyNavigation({
    super.key,
    required this.currentDate,
    required this.onDateChanged,
    this.showMonthPicker = true,
    this.padding,
  });

  @override
  State<MonthlyNavigation> createState() => _MonthlyNavigationState();
}

class _MonthlyNavigationState extends State<MonthlyNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Check if we can navigate to previous month
  bool get canNavigatePrevious {
    final previousMonth = DateTime(
      widget.currentDate.year,
      widget.currentDate.month - 1,
      1,
    );
    final minDate = DateTime.now().subtract(const Duration(days: 365 * 10));
    return previousMonth.isAfter(minDate);
  }

  /// Check if we can navigate to next month
  bool get canNavigateNext {
    final nextMonth = DateTime(
      widget.currentDate.year,
      widget.currentDate.month + 1,
      1,
    );
    final maxDate = DateTime.now().add(const Duration(days: 365 * 5));
    return nextMonth.isBefore(maxDate);
  }

  /// Navigate to previous month with animation
  void _navigateToPrevious() async {
    if (!canNavigatePrevious) return;

    await _animationController.forward();

    final previousMonth = DateTime(
      widget.currentDate.year,
      widget.currentDate.month - 1,
      1,
    );

    widget.onDateChanged(previousMonth);

    _animationController.reverse();
  }

  /// Navigate to next month with animation
  void _navigateToNext() async {
    if (!canNavigateNext) return;

    await _animationController.forward();

    final nextMonth = DateTime(
      widget.currentDate.year,
      widget.currentDate.month + 1,
      1,
    );

    widget.onDateChanged(nextMonth);

    _animationController.reverse();
  }

  /// Show month picker dialog
  Future<void> _showMonthPickerDialog() async {
    if (!widget.showMonthPicker) return;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: widget.currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      initialDatePickerMode: DatePickerMode.year,
      helpText: context.tr.translate('select_month'),
    );

    if (selectedDate != null) {
      final monthDate = DateTime(selectedDate.year, selectedDate.month, 1);
      widget.onDateChanged(monthDate);
    }
  }

  /// Format the current month for display
  String get formattedMonth {
    return context.tr.formatDateWithTranslatedMonths(
      widget.currentDate,
      pattern: 'MMM yyyy',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous month button
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: IconButton(
                  onPressed: canNavigatePrevious ? _navigateToPrevious : null,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: context.tr.translate('previous_month'),
                  iconSize: 28,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[100],
                    disabledBackgroundColor:
                        isDark ? Colors.grey[900] : Colors.grey[50],
                  ),
                ),
              );
            },
          ),

          // Current month display
          Expanded(
            child: GestureDetector(
              onTap: widget.showMonthPicker ? _showMonthPickerDialog : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  formattedMonth,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
          ),

          // Next month button
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: IconButton(
                  onPressed: canNavigateNext ? _navigateToNext : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: context.tr.translate('next_month'),
                  iconSize: 28,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[100],
                    disabledBackgroundColor:
                        isDark ? Colors.grey[900] : Colors.grey[50],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
