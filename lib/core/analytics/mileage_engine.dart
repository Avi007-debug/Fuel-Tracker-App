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
}

/// A single data point for mileage trend charts.
class MileagePoint {
  final DateTime timestamp;
  final double kmPerLitre;
  MileagePoint(this.timestamp, this.kmPerLitre);
}
