import 'dart:math' as math;
import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/core/constants/app_constants.dart';

/// Mileage calculation engine — per-fill and rolling average.
///
/// Algorithms from the plan:
/// - Calculated per refill interval: km_since_last_refill ÷ litres_added
/// - Running average (last 5 refills) for smoothed mileage display
/// - Mileage drop detection: if current fill < 90% of 5-fill avg → flag
class MileageEngine {
  MileageEngine._();

  /// Calculate mileage for a single fill interval.
  static double calculateMileage(double kmSinceLastFill, double litresFilled) {
    if (litresFilled <= 0) return 0.0;
    return kmSinceLastFill / litresFilled;
  }

  /// Rolling average mileage from the last [window] fills.
  static double rollingAverage(
    List<FuelEntry> entries, {
    int window = AppConstants.mileageRollingWindow,
  }) {
    final valid = entries
        .take(window)
        .where((e) => e.calculatedMileage > 0)
        .toList();
    if (valid.isEmpty) return 0.0;
    return valid.fold(0.0, (s, e) => s + e.calculatedMileage) / valid.length;
  }

  /// Whether the latest fill shows a mileage drop.
  ///
  /// Returns `true` if current fill mileage < [threshold] × rolling average.
  static bool isMileageDrop(
    List<FuelEntry> entries, {
    double threshold = AppConstants.mileageDropThreshold,
  }) {
    if (entries.length < 2) return false;
    final current = entries.first.calculatedMileage;
    if (current <= 0) return false;
    final avg = rollingAverage(entries.skip(1).toList());
    if (avg <= 0) return false;
    return current < threshold * avg;
  }

  /// Mileage trend — list of (timestamp, km/L) pairs for graphing.
  static List<MileagePoint> mileageTrend(List<FuelEntry> entries) {
    return entries
        .where((e) => e.calculatedMileage > 0)
        .map((e) => MileagePoint(e.timestamp, e.calculatedMileage))
        .toList()
        .reversed
        .toList();
  }

  /// Calculate mileage prediction confidence based on number of refills and consistency.
  /// Returns a score between 0.0 and 1.0.
  static double calculateMileageConfidence(List<FuelEntry> entries) {
    final valid = entries.where((e) => e.calculatedMileage > 0).toList();
    if (valid.isEmpty) return 0.0;

    // Factor 1: Data density (number of refills)
    // More refills = more reliable average. 5 refills is our target.
    final countFactor = (valid.length / 5).clamp(0.0, 1.0);

    if (valid.length < 2) {
      return countFactor * 0.5; // low confidence with only 1 entry
    }

    // Factor 2: Consistency (Coefficient of Variation of the last 5 refills)
    final recent = valid.take(5).toList();
    final mean = recent.fold(0.0, (s, e) => s + e.calculatedMileage) / recent.length;
    if (mean <= 0) return 0.0;

    double varianceSum = 0.0;
    for (final e in recent) {
      final diff = e.calculatedMileage - mean;
      varianceSum += diff * diff;
    }
    final variance = varianceSum / recent.length;
    final stdDev = math.sqrt(variance);
    final cv = stdDev / mean;

    // CV < 0.05 is highly consistent (1.0), CV > 0.20 is irregular/low consistency (0.5)
    // Map CV to a factor between 0.5 and 1.0
    final consistencyFactor = (1.0 - (cv * 3.0)).clamp(0.5, 1.0);

    return countFactor * consistencyFactor;
  }
}

/// A single data point for mileage trend charts.
class MileagePoint {
  final DateTime timestamp;
  final double kmPerLitre;
  MileagePoint(this.timestamp, this.kmPerLitre);
}
