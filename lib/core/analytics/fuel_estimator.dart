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

  /// Predict fuel remaining day-by-day for the next 7 days.
  /// Returns a list of predicted fuel levels (in Litres).
  static List<double> predict7DayForecast({
    required double currentFuelL,
    required double averageMileageKmPerL,
    required Map<int, double> dayAverages,
  }) {
    final forecast = <double>[];
    double tempFuel = currentFuelL;
    final now = DateTime.now();

    for (int i = 1; i <= 7; i++) {
      final day = now.add(Duration(days: i));
      final weekday = day.weekday;

      // Expected distance for this day of week.
      // If 0, use a fallback: 15.6 km on weekdays, 2.0 km on weekends
      double expectedDistance = dayAverages[weekday] ?? 0.0;
      if (expectedDistance <= 0.0) {
        expectedDistance = (weekday == DateTime.saturday || weekday == DateTime.sunday) ? 2.0 : 15.6;
      }

      final fuelUsed = averageMileageKmPerL > 0 ? expectedDistance / averageMileageKmPerL : 0.0;
      tempFuel = (tempFuel - fuelUsed).clamp(0.0, double.infinity);
      forecast.add(tempFuel);
    }
    return forecast;
  }
}
