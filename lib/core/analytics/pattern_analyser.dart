import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/core/constants/app_constants.dart';

/// Riding pattern analysis — day-of-week averages, trip anomaly detection.
class PatternAnalyser {
  PatternAnalyser._();

  /// Average distance by day of week (Mon=1, Sun=7).
  /// Uses rolling [weeks]-week history.
  static Map<int, double> dayOfWeekAverages(
    List<Trip> trips, {
    int weeks = AppConstants.patternHistoryWeeks,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: weeks * 7));
    final recentTrips =
        trips.where((t) => t.timestamp.isAfter(cutoff)).toList();

    final totals = <int, double>{};
    final counts = <int, int>{};

    for (final trip in recentTrips) {
      final day = trip.timestamp.weekday;
      totals[day] = (totals[day] ?? 0) + trip.distanceKm;
      counts[day] = (counts[day] ?? 0) + 1;
    }

    final averages = <int, double>{};
    for (int d = 1; d <= 7; d++) {
      final total = totals[d] ?? 0;
      final count = counts[d] ?? 0;
      averages[d] = count > 0 ? total / (weeks > 0 ? weeks : 1) : 0;
    }
    return averages;
  }

  /// Whether a trip is an anomaly (> 2× day-of-week average).
  static bool isAnomaly(
    Trip trip,
    Map<int, double> dayAverages, {
    double multiplier = AppConstants.tripAnomalyMultiplier,
  }) {
    final avg = dayAverages[trip.timestamp.weekday] ?? 0;
    if (avg <= 0) return false;
    return trip.distanceKm > multiplier * avg;
  }

  /// Expected daily distance for today based on pattern.
  static double expectedTodayDistance(Map<int, double> dayAverages) {
    return dayAverages[DateTime.now().weekday] ?? 0;
  }
}
