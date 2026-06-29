import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/core/analytics/mileage_engine.dart';
import 'package:fuel_tracker_app/core/constants/app_constants.dart';

/// Fuel level estimation engine.
///
/// Formula: estimated_fuel = litres_on_hand − (distance × 1/avg_mileage)
class FuelEstimator {
  FuelEstimator._();

  /// Estimate remaining fuel in litres.
  ///
  /// [lastEntry] — the most recent fuel refill
  /// [kmSinceLastFill] — total distance since that refill
  /// [entries] — all fuel entries for rolling average calculation
  static double estimateRemaining({
    required FuelEntry lastEntry,
    required double kmSinceLastFill,
    required List<FuelEntry> entries,
  }) {
    final avgMileage = MileageEngine.rollingAverage(entries);
    if (avgMileage <= 0) return lastEntry.litresFilled;

    final fuelUsed = kmSinceLastFill / avgMileage;
    final remaining = lastEntry.litresFilled - fuelUsed;
    return remaining.clamp(0.0, double.infinity);
  }

  /// Estimate remaining range in km.
  static double estimateRange({
    required double fuelRemainingL,
    required List<FuelEntry> entries,
  }) {
    final avgMileage = MileageEngine.rollingAverage(entries);
    return fuelRemainingL * avgMileage;
  }

  /// Fuel level as a fraction of tank capacity (0.0 – 1.0).
  static double fuelFraction({
    required double fuelRemainingL,
    double tankCapacity = AppConstants.defaultTankCapacityL,
  }) {
    return (fuelRemainingL / tankCapacity).clamp(0.0, 1.0);
  }

  /// Whether fuel is below the low-fuel alert threshold.
  static bool isLowFuel({
    required double estimatedRangeKm,
    double threshold = AppConstants.lowFuelAlertRangeKm,
  }) {
    return estimatedRangeKm < threshold;
  }
}
