class SavingsPeriodCalculator {
  // Conversion factors to daily basis
  static const Map<String, double> _periodToDaysMap = {
    'daily': 1.0,
    'weekly': 7.0,
    'monthly': 30.0,
    'quarterly': 90.0,
    'semiannual': 180.0,
    'annual': 365.0,
  };

  /// Convert a savings goal from one period to another
  /// [originalGoal] - The original goal amount
  /// [fromPeriod] - The period the goal was originally set for
  /// [toPeriod] - The period to convert the goal to
  static double convertGoalBetweenPeriods(
    double originalGoal,
    String fromPeriod,
    String toPeriod,
  ) {
    if (fromPeriod == toPeriod) {
      return originalGoal;
    }

    // Get the daily equivalent of the original goal
    final double fromDays = _periodToDaysMap[fromPeriod] ?? 30.0;
    final double toDays = _periodToDaysMap[toPeriod] ?? 30.0;

    // Calculate daily rate
    final double dailyRate = originalGoal / fromDays;

    // Convert to target period
    return dailyRate * toDays;
  }

  /// Calculate proportional amounts based on the selected period
  /// [savingsData] - Original savings data
  /// [targetPeriod] - Period to display the data for
  static ProportionalSavingsData calculateProportionalSavings(
    SavingsDataWithPeriod savingsData,
    String targetPeriod,
  ) {
    final double proportionalGoal = convertGoalBetweenPeriods(
      savingsData.goal,
      savingsData.period,
      targetPeriod,
    );

    final double proportionalAvailable = convertGoalBetweenPeriods(
      savingsData.available,
      savingsData.period,
      targetPeriod,
    );

    final double proportionalNeedToSave =
        proportionalGoal - proportionalAvailable;
    final double percent =
        proportionalGoal > 0
            ? (proportionalAvailable / proportionalGoal) * 100
            : 0.0;

    return ProportionalSavingsData(
      originalGoal: savingsData.goal,
      originalPeriod: savingsData.period,
      proportionalGoal: proportionalGoal,
      proportionalAvailable: proportionalAvailable,
      proportionalNeedToSave:
          proportionalNeedToSave > 0 ? proportionalNeedToSave : 0.0,
      percent: percent,
      targetPeriod: targetPeriod,
    );
  }

  /// Get display name for period
  static String getPeriodDisplayName(String period) {
    switch (period) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'semiannual':
        return 'Semiannual';
      case 'annual':
        return 'Annual';
      default:
        return 'Period';
    }
  }

  /// Get all available periods
  static List<String> getAllPeriods() {
    return ['daily', 'weekly', 'monthly', 'quarterly', 'semiannual', 'annual'];
  }

  /// Get period mapping for conversion calculations
  static Map<String, double> getPeriodMapping() {
    return Map.from(_periodToDaysMap);
  }

  /// Get all available periods with their display names
  static Map<String, String> getAllPeriodsWithNames() {
    return {
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'quarterly': 'Quarterly',
      'semiannual': 'Semiannual',
      'annual': 'Annual',
    };
  }
}

/// Data class for savings with period information
class SavingsDataWithPeriod {
  final double available;
  final double goal;
  final String period;

  SavingsDataWithPeriod({
    required this.available,
    required this.goal,
    required this.period,
  });
}

/// Data class for proportional savings calculations
class ProportionalSavingsData {
  final double originalGoal;
  final String originalPeriod;
  final double proportionalGoal;
  final double proportionalAvailable;
  final double proportionalNeedToSave;
  final double percent;
  final String targetPeriod;

  ProportionalSavingsData({
    required this.originalGoal,
    required this.originalPeriod,
    required this.proportionalGoal,
    required this.proportionalAvailable,
    required this.proportionalNeedToSave,
    required this.percent,
    required this.targetPeriod,
  });
}
