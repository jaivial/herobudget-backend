class DateUtils {
  /// Calculate ISO week number for a given date
  /// This implementation follows the ISO 8601 standard:
  /// - Week 1 is the first week that contains January 4th
  /// - Weeks start on Monday
  /// - Returns the ISO week year and week number
  static (int year, int week) getISOWeek(DateTime date) {
    // Get the first Thursday of the year (it's always in week 1)
    final jan1 = DateTime(date.year, 1, 1);

    // Find the first Thursday (January 4th is always in week 1)
    final jan4 = DateTime(date.year, 1, 4);

    // Find Monday of week 1 (the week containing January 4th)
    final mondayOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));

    // Calculate days since Monday of week 1
    final daysSinceWeek1 = date.difference(mondayOfWeek1).inDays;

    int year = date.year;
    int week;

    if (daysSinceWeek1 < 0) {
      // This date is in the previous ISO year
      year = date.year - 1;
      final prevYearJan4 = DateTime(year, 1, 4);
      final prevYearMondayOfWeek1 = prevYearJan4.subtract(
        Duration(days: prevYearJan4.weekday - 1),
      );
      final daysInPrevYear = date.difference(prevYearMondayOfWeek1).inDays;
      week = (daysInPrevYear / 7).floor() + 1;
    } else {
      week = (daysSinceWeek1 / 7).floor() + 1;

      // Check if this week belongs to next year
      if (week >= 53) {
        final nextYearJan4 = DateTime(date.year + 1, 1, 4);
        final nextYearMondayOfWeek1 = nextYearJan4.subtract(
          Duration(days: nextYearJan4.weekday - 1),
        );

        if (date.isAtSameMomentAs(nextYearMondayOfWeek1) ||
            date.isAfter(nextYearMondayOfWeek1)) {
          year = date.year + 1;
          week = 1;
        }
      }
    }

    return (year, week);
  }

  /// Format date for weekly period using ISO week standard
  static String formatWeeklyDate(DateTime date) {
    final (year, week) = getISOWeek(date);
    return '$year-W${week.toString().padLeft(2, '0')}';
  }

  /// Parse weekly date string back to DateTime
  /// Returns the Monday of the specified ISO week
  static DateTime parseWeeklyDate(String weeklyDateString) {
    final parts = weeklyDateString.split('-W');
    if (parts.length != 2) {
      throw ArgumentError('Invalid weekly date format: $weeklyDateString');
    }

    final year = int.parse(parts[0]);
    final week = int.parse(parts[1]);

    // Find January 4th of the year (it's always in week 1)
    final jan4 = DateTime(year, 1, 4);

    // Find Monday of week 1
    final mondayOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));

    // Calculate Monday of the target week
    return mondayOfWeek1.add(Duration(days: (week - 1) * 7));
  }

  /// Format date according to period type
  static String formatDateForPeriod(DateTime date, String period) {
    switch (period.toLowerCase()) {
      case 'daily':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case 'weekly':
        return formatWeeklyDate(date);
      case 'monthly':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case 'quarterly':
        final quarter = ((date.month - 1) ~/ 3) + 1;
        return '${date.year}-Q$quarter';
      case 'semiannual':
        final half = date.month <= 6 ? 1 : 2;
        return '${date.year}-H$half';
      case 'annual':
        return date.year.toString();
      default:
        // Default to monthly
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    }
  }

  /// Parse date string back to DateTime based on period
  static DateTime parseDateForPeriod(String dateString, String period) {
    switch (period.toLowerCase()) {
      case 'daily':
        return DateTime.parse(dateString);
      case 'weekly':
        return parseWeeklyDate(dateString);
      case 'monthly':
        final parts = dateString.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      case 'quarterly':
        final parts = dateString.split('-Q');
        final year = int.parse(parts[0]);
        final quarter = int.parse(parts[1]);
        final month = (quarter - 1) * 3 + 1;
        return DateTime(year, month, 1);
      case 'semiannual':
        final parts = dateString.split('-H');
        final year = int.parse(parts[0]);
        final half = int.parse(parts[1]);
        final month = half == 1 ? 1 : 7;
        return DateTime(year, month, 1);
      case 'annual':
        return DateTime(int.parse(dateString), 1, 1);
      default:
        // Default to monthly
        final parts = dateString.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    }
  }
}
