import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/extensions.dart';

class PeriodSelector extends StatefulWidget {
  final String initialPeriod;
  final Function(String) onPeriodChanged;
  final Function(DateTime, DateTime) onCustomRangeSelected;
  final Function(DateTime)? onDateChanged;

  const PeriodSelector({
    super.key,
    this.initialPeriod = 'monthly',
    required this.onPeriodChanged,
    required this.onCustomRangeSelected,
    this.onDateChanged,
  });

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  late String _currentPeriod;
  DateTime _currentDate = DateTime.now();

  // Map to store dates by period type
  final Map<String, DateTime> _datesByPeriodType = {};

  @override
  void initState() {
    super.initState();
    _currentPeriod = widget.initialPeriod;

    // Initialize with the current date
    final now = DateTime.now();

    // Initialize the map with appropriate dates for each period type
    _datesByPeriodType['daily'] = now;

    // For weekly, start with Monday of this week
    final daysToMonday = now.weekday - 1; // 0 for Monday, 1 for Tuesday, etc.
    _datesByPeriodType['weekly'] = now.subtract(Duration(days: daysToMonday));

    // For monthly, use the first day of the current month
    _datesByPeriodType['monthly'] = DateTime(now.year, now.month, 1);

    // For quarterly, use the first day of the current quarter
    final currentQuarter = ((now.month - 1) ~/ 3);
    _datesByPeriodType['quarterly'] = DateTime(
      now.year,
      currentQuarter * 3 + 1,
      1,
    );

    // For semiannual, use the first day of the current half
    final currentHalf = now.month <= 6 ? 1 : 7;
    _datesByPeriodType['semiannual'] = DateTime(now.year, currentHalf, 1);

    // For annual, use the first day of the current year
    _datesByPeriodType['annual'] = DateTime(now.year, 1, 1);

    // For custom, use the current date
    _datesByPeriodType['custom'] = now;

    // Set the current date based on the initial period
    _currentDate = _datesByPeriodType[_currentPeriod] ?? now;
  }

  // Get the title for the current period
  String get periodTitle {
    final DateFormat formatter = DateFormat.yMMM();

    switch (_currentPeriod) {
      case 'daily':
        return DateFormat.yMd().format(_currentDate);
      case 'weekly':
        // Calculate the start and end of the week (Monday to Sunday)
        final startOfWeek = getStartOfWeek(_currentDate);
        final endOfWeek = getEndOfWeek(_currentDate);
        return '${DateFormat.MMMd().format(startOfWeek)} - ${DateFormat.MMMd().format(endOfWeek)}';
      case 'monthly':
        return formatter.format(_currentDate);
      case 'quarterly':
        final quarter = ((_currentDate.month - 1) ~/ 3) + 1;
        return 'Q$quarter ${_currentDate.year}';
      case 'semiannual':
        final half = (_currentDate.month <= 6) ? 1 : 2;
        return 'H$half ${_currentDate.year}';
      case 'annual':
        return _currentDate.year.toString();
      case 'custom':
        return context.tr.translate('custom_period');
      default:
        return formatter.format(_currentDate);
    }
  }

  // Get the start of the week (Monday) for a given date
  DateTime getStartOfWeek(DateTime date) {
    final daysToMonday = date.weekday - 1; // 0 for Monday, 1 for Tuesday, etc.
    return date.subtract(Duration(days: daysToMonday));
  }

  // Get the end of the week (Sunday) for a given date
  DateTime getEndOfWeek(DateTime date) {
    final startOfWeek = getStartOfWeek(date);
    return startOfWeek.add(const Duration(days: 6));
  }

  // Navigate to the previous period with date validation
  void _navigateToPreviousPeriod() {
    DateTime newDate;

    debugPrint(
      'Navigating back from: $_currentPeriod - ${_formatDebugDate(_currentDate)}',
    );

    switch (_currentPeriod) {
      case 'daily':
        newDate = _currentDate.subtract(const Duration(days: 1));
        break;
      case 'weekly':
        newDate = _currentDate.subtract(const Duration(days: 7));
        break;
      case 'monthly':
        // Calculate the first day of the previous month to avoid issues with different month lengths
        final year =
            _currentDate.month > 1 ? _currentDate.year : _currentDate.year - 1;
        final month = _currentDate.month > 1 ? _currentDate.month - 1 : 12;
        newDate = DateTime(year, month, 1);
        break;
      case 'quarterly':
        // Go back 3 months but ensure we're on the first day of the month
        final year =
            _currentDate.month > 3 ? _currentDate.year : _currentDate.year - 1;
        final month =
            _currentDate.month > 3
                ? _currentDate.month - 3
                : _currentDate.month + 9;
        newDate = DateTime(year, month, 1);
        break;
      case 'semiannual':
        // Go back 6 months but ensure we're on the first day of the month
        final year =
            _currentDate.month > 6 ? _currentDate.year : _currentDate.year - 1;
        final month =
            _currentDate.month > 6
                ? _currentDate.month - 6
                : _currentDate.month + 6;
        newDate = DateTime(year, month, 1);
        break;
      case 'annual':
        newDate = DateTime(_currentDate.year - 1, 1, 1);
        break;
      default:
        return;
    }

    // Verify that the new date is valid before applying it
    // Allow navigation up to 10 years back
    final minAllowedDate = DateTime.now().subtract(
      const Duration(days: 365 * 10),
    );
    if (newDate.isAfter(minAllowedDate) &&
        newDate.isBefore(DateTime.now().add(const Duration(days: 365 * 5)))) {
      debugPrint('Navigating to: ${_formatDebugDate(newDate)}');
      setState(() {
        _currentDate = newDate;
        _datesByPeriodType[_currentPeriod] =
            newDate; // Store the date for this period type
      });

      widget.onPeriodChanged(_currentPeriod);
      if (widget.onDateChanged != null) {
        widget.onDateChanged!(_currentDate);
      }
    } else {
      debugPrint(
        'Navigation blocked: ${_formatDebugDate(newDate)} is outside the allowed range',
      );
    }
  }

  // Navigate to the next period with date validation
  void _navigateToNextPeriod() {
    // Allow navigation to future dates up to 5 years
    final maxAllowedDate = DateTime.now().add(const Duration(days: 365 * 5));
    DateTime newDate;

    debugPrint(
      'Navigating forward from: $_currentPeriod - ${_formatDebugDate(_currentDate)}',
    );

    switch (_currentPeriod) {
      case 'daily':
        newDate = _currentDate.add(const Duration(days: 1));
        break;
      case 'weekly':
        newDate = _currentDate.add(const Duration(days: 7));
        break;
      case 'monthly':
        // Calculate the first day of the next month to avoid issues with different month lengths
        final year =
            _currentDate.month < 12 ? _currentDate.year : _currentDate.year + 1;
        final month = _currentDate.month < 12 ? _currentDate.month + 1 : 1;
        newDate = DateTime(year, month, 1);
        break;
      case 'quarterly':
        // Advance 3 months but ensure we're on the first day of the month
        final year =
            _currentDate.month < 10 ? _currentDate.year : _currentDate.year + 1;
        final month =
            _currentDate.month < 10
                ? _currentDate.month + 3
                : (_currentDate.month - 9);
        newDate = DateTime(year, month, 1);
        break;
      case 'semiannual':
        // Advance 6 months but ensure we're on the first day of the month
        final year =
            _currentDate.month <= 6 ? _currentDate.year : _currentDate.year + 1;
        final month =
            _currentDate.month <= 6
                ? _currentDate.month + 6
                : (_currentDate.month - 6);
        newDate = DateTime(year, month, 1);
        break;
      case 'annual':
        newDate = DateTime(_currentDate.year + 1, 1, 1);
        break;
      default:
        return;
    }

    // Only allow dates until the established limit of 5 years
    if (newDate.isBefore(maxAllowedDate)) {
      debugPrint('Navigating to: ${_formatDebugDate(newDate)}');
      setState(() {
        _currentDate = newDate;
        _datesByPeriodType[_currentPeriod] =
            newDate; // Store the date for this period type
      });

      widget.onPeriodChanged(_currentPeriod);
      if (widget.onDateChanged != null) {
        widget.onDateChanged!(_currentDate);
      }
    } else {
      debugPrint(
        'Navigation blocked: ${_formatDebugDate(newDate)} is beyond the allowed limit',
      );
    }
  }

  // Helper for date debugging
  String _formatDebugDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Change the period type preserving the navigation context
  void _changePeriodType(String periodType) {
    // Don't change if we're already on this period type
    if (_currentPeriod == periodType) {
      return;
    }

    // Use cached date if available, otherwise use current date for the new period type
    final DateTime dateToUse =
        _datesByPeriodType.containsKey(periodType)
            ? _datesByPeriodType[periodType]!
            : _getCurrentDateForPeriodType(periodType);

    setState(() {
      _currentPeriod = periodType;
      _currentDate = dateToUse;
      // Update the date for this period type
      _datesByPeriodType[_currentPeriod] = _currentDate;
    });

    widget.onPeriodChanged(_currentPeriod);
    if (widget.onDateChanged != null) {
      widget.onDateChanged!(_currentDate);
    }
  }

  // Function to convert a date when changing between period types
  // maintaining the temporal context (same month/year when possible)
  DateTime _convertCurrentDateToNewPeriodType(
    String fromPeriod,
    String toPeriod,
    DateTime currentDate,
  ) {
    // If we don't have a saved date for the target period type,
    // we try to preserve the same temporal context (month/year)
    final int year = currentDate.year;
    final int month = currentDate.month;

    switch (toPeriod) {
      case 'daily':
        // For daily, use day 1 of the current month
        // Consider using current day if within the same month
        if (month == DateTime.now().month && year == DateTime.now().year) {
          return DateTime(year, month, DateTime.now().day);
        }
        return DateTime(year, month, 1);
      case 'weekly':
        // For weekly, start with the Monday of the week containing day 1 of the month
        final firstDayOfMonth = DateTime(year, month, 1);
        int daysToSubtract = firstDayOfMonth.weekday - 1; // Monday as first day
        return firstDayOfMonth.subtract(Duration(days: daysToSubtract));
      case 'monthly':
        // For monthly, use the first day of the month
        return DateTime(year, month, 1);
      case 'quarterly':
        // For quarterly, use the first day of the quarter that contains the current month
        final quarter = ((month - 1) ~/ 3);
        return DateTime(year, quarter * 3 + 1, 1);
      case 'semiannual':
        // For semiannual, use the first day of the half that contains the current month
        final half = month <= 6 ? 1 : 7;
        return DateTime(year, half, 1);
      case 'annual':
        // For annual, use the first day of the year
        return DateTime(year, 1, 1);
      case 'custom':
        // For custom, keep the current date
        return currentDate;
      default:
        return DateTime(year, month, 1);
    }
  }

  // Get the current appropriate date for a specific period type
  // This ensures we always start with relevant, current data
  DateTime _getCurrentDateForPeriodType(String periodType) {
    final DateTime now = DateTime.now();

    switch (periodType) {
      case 'daily':
        // For daily, use today's date
        return now;
      case 'weekly':
        // For weekly, use the Monday of the current week
        final daysToMonday =
            now.weekday - 1; // 0 for Monday, 1 for Tuesday, etc.
        return now.subtract(Duration(days: daysToMonday));
      case 'monthly':
        // For monthly, use the first day of the current month
        return DateTime(now.year, now.month, 1);
      case 'quarterly':
        // For quarterly, use the first day of the current quarter
        final currentQuarter = ((now.month - 1) ~/ 3);
        return DateTime(now.year, currentQuarter * 3 + 1, 1);
      case 'semiannual':
        // For semiannual, use the first day of the current half
        final currentHalf = now.month <= 6 ? 1 : 7;
        return DateTime(now.year, currentHalf, 1);
      case 'annual':
        // For annual, use the first day of the current year
        return DateTime(now.year, 1, 1);
      case 'custom':
        // For custom, use the current date
        return now;
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  // Show the custom range selector
  void _showCustomRangeSelector() {
    // Set up initial dates
    DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
    DateTime endDate = DateTime.now();
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr.translate('select_date_range'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDarkMode ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Start date selector
                  ListTile(
                    title: Text(
                      context.tr.translate('start_date'),
                      style: TextStyle(
                        color:
                            isDarkMode ? Colors.white.withOpacity(0.9) : null,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().format(startDate),
                      style: TextStyle(
                        color:
                            isDarkMode ? Colors.white.withOpacity(0.7) : null,
                      ),
                    ),
                    trailing: Icon(
                      Icons.calendar_today,
                      color:
                          isDarkMode
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2010),
                        lastDate: endDate,
                      );
                      if (pickedDate != null) {
                        setModalState(() {
                          startDate = pickedDate;
                        });
                      }
                    },
                  ),

                  // End date selector
                  ListTile(
                    title: Text(
                      context.tr.translate('end_date'),
                      style: TextStyle(
                        color:
                            isDarkMode ? Colors.white.withOpacity(0.9) : null,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().format(endDate),
                      style: TextStyle(
                        color:
                            isDarkMode ? Colors.white.withOpacity(0.7) : null,
                      ),
                    ),
                    trailing: Icon(
                      Icons.calendar_today,
                      color:
                          isDarkMode
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate,
                        // Allow selecting future dates for the custom range
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (pickedDate != null) {
                        setModalState(() {
                          endDate = pickedDate;
                        });
                      }
                    },
                  ),

                  const Spacer(),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDarkMode
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                        ),
                        child: Text(context.tr.translate('cancel')),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentPeriod = 'custom';
                          });
                          Navigator.pop(context);
                          widget.onCustomRangeSelected(startDate, endDate);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(context.tr.translate('apply')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Period navigation controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous period button
            IconButton(
              onPressed: _navigateToPreviousPeriod,
              icon: const Icon(Icons.chevron_left),
              tooltip: context.tr.translate('previous_period'),
            ),

            // Current period title
            Expanded(
              child: GestureDetector(
                onTap: () => _showCustomRangeSelector(),
                child: Text(
                  periodTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    // Improve contrast in dark mode
                    color: isDarkMode ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Next period button
            IconButton(
              onPressed: _navigateToNextPeriod,
              icon: const Icon(Icons.chevron_right),
              tooltip: context.tr.translate('next_period'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Period type selector with improved carousel
        SizedBox(
          height: 50, // Fixed height for the carousel
          child: Stack(
            children: [
              // Main scrollable content
              ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7, // Number of period types
                itemBuilder: (context, index) {
                  final periods = [
                    {
                      'key': 'daily',
                      'label': context.tr.translate('daily_period'),
                    },
                    {
                      'key': 'weekly',
                      'label': context.tr.translate('weekly_period'),
                    },
                    {
                      'key': 'monthly',
                      'label': context.tr.translate('monthly_period'),
                    },
                    {
                      'key': 'quarterly',
                      'label': context.tr.translate('quarterly_period'),
                    },
                    {
                      'key': 'semiannual',
                      'label': context.tr.translate('semiannual_period'),
                    },
                    {
                      'key': 'annual',
                      'label': context.tr.translate('annual_period'),
                    },
                    {
                      'key': 'custom',
                      'label': context.tr.translate('custom_period'),
                    },
                  ];

                  final period = periods[index];
                  final isCustom = period['key'] == 'custom';

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _PeriodTypeButton(
                      label: period['label']!,
                      isSelected: _currentPeriod == period['key'],
                      onTap:
                          isCustom
                              ? _showCustomRangeSelector
                              : () => _changePeriodType(period['key']!),
                      icon: isCustom ? Icons.calendar_today : null,
                    ),
                  );
                },
              ),

              // Left fade gradient
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
                        (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                            .withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Right fade gradient
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
                        (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                            .withOpacity(0.0),
                      ],
                    ),
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

class _PeriodTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PeriodTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Use fixed colors that ensure visibility in dark mode
    final Color backgroundColor =
        isSelected
            ? (isDarkMode
                ? const Color(0xFF6A1B9A)
                : Theme.of(context).colorScheme.primaryContainer)
            : (isDarkMode
                ? const Color(0xFF2D2D2D)
                : Theme.of(context).colorScheme.surface);

    // Use white text color to ensure visibility in dark mode
    final Color textColor =
        isSelected
            ? Colors.white
            : (isDarkMode
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              width: 1.5,
              color:
                  isSelected
                      ? (isDarkMode
                          ? Colors.purple.shade300
                          : Theme.of(context).colorScheme.primary)
                      : (isDarkMode
                          ? Colors.grey
                          : Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.3)),
            ),
          ),
          elevation: isSelected ? 1 : 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
