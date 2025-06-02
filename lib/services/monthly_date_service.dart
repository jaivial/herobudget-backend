import 'package:intl/intl.dart';

/// Service for handling monthly date operations and formatting
class MonthlyDateService {
  static const int _maxYearsBack = 10;
  static const int _maxYearsForward = 5;

  /// Get the current month date (first day of current month)
  DateTime getCurrentMonthDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Format a date for monthly display (YYYY-MM)
  String formatDateForMonth(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  /// Format a date for display with month name (MMM yyyy)
  String formatDateForDisplay(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  /// Parse a monthly date string (YYYY-MM) to DateTime
  DateTime? parseDateString(String dateStr) {
    try {
      if (dateStr.contains('-') && dateStr.length == 7) {
        final parts = dateStr.split('-');
        if (parts.length == 2) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          return DateTime(year, month, 1);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get the previous month
  DateTime getPreviousMonth(DateTime currentDate) {
    return DateTime(currentDate.year, currentDate.month - 1, 1);
  }

  /// Get the next month
  DateTime getNextMonth(DateTime currentDate) {
    return DateTime(currentDate.year, currentDate.month + 1, 1);
  }

  /// Check if a date is within allowed range for navigation
  bool isWithinAllowedRange(DateTime date) {
    final now = DateTime.now();
    final minDate = DateTime(now.year - _maxYearsBack, now.month, 1);
    final maxDate = DateTime(now.year + _maxYearsForward, now.month, 1);

    return date.isAfter(minDate.subtract(const Duration(days: 1))) &&
        date.isBefore(maxDate.add(const Duration(days: 1)));
  }

  /// Check if we can navigate to previous month
  bool canNavigateToPrevious(DateTime currentDate) {
    final previousMonth = getPreviousMonth(currentDate);
    return isWithinAllowedRange(previousMonth);
  }

  /// Check if we can navigate to next month
  bool canNavigateToNext(DateTime currentDate) {
    final nextMonth = getNextMonth(currentDate);
    return isWithinAllowedRange(nextMonth);
  }

  /// Get the minimum allowed date for navigation
  DateTime getMinimumDate() {
    final now = DateTime.now();
    return DateTime(now.year - _maxYearsBack, 1, 1);
  }

  /// Get the maximum allowed date for navigation
  DateTime getMaximumDate() {
    final now = DateTime.now();
    return DateTime(now.year + _maxYearsForward, 12, 1);
  }

  /// Calculate months difference between two dates
  int getMonthsDifference(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + to.month - from.month;
  }

  /// Get a list of months within range from a starting date
  List<DateTime> getMonthsInRange(DateTime startDate, int monthsCount) {
    final months = <DateTime>[];
    for (int i = 0; i < monthsCount; i++) {
      final monthDate = DateTime(startDate.year, startDate.month + i, 1);
      if (isWithinAllowedRange(monthDate)) {
        months.add(monthDate);
      }
    }
    return months;
  }

  /// Check if two dates are in the same month
  bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  /// Get the first day of the month for any date
  DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get the last day of the month for any date
  DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
}
