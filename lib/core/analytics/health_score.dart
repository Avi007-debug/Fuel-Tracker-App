import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/models/service_record.dart';
import 'package:fuel_tracker_app/core/constants/app_constants.dart';
import 'package:fuel_tracker_app/core/analytics/mileage_engine.dart';

/// Vehicle Health Score — composite of mileage stability, service compliance,
/// and fuel efficiency trend.
///
/// Weights from the plan:
///   Mileage stability:     30%
///   Service compliance:    40%
///   Fuel efficiency trend: 30%
class HealthScore {
  HealthScore._();

  /// Compute overall health score (0.0 – 1.0).
  static double compute({
    required List<FuelEntry> fuelEntries,
    required List<ServiceRecord> serviceRecords,
    required double totalDistanceKm,
    double serviceIntervalKm = AppConstants.defaultServiceIntervalKm,
  }) {
    final mileageScore = _mileageStabilityScore(fuelEntries);
    final serviceScore = _serviceComplianceScore(
      serviceRecords,
      totalDistanceKm,
      serviceIntervalKm,
    );
    final efficiencyScore = _fuelEfficiencyScore(fuelEntries);

    return (mileageScore * AppConstants.healthWeightMileageStability) +
        (serviceScore * AppConstants.healthWeightServiceCompliance) +
        (efficiencyScore * AppConstants.healthWeightFuelEfficiency);
  }

  /// Mileage stability — lower variance = higher score.
  static double _mileageStabilityScore(List<FuelEntry> entries) {
    final values =
        entries.where((e) => e.calculatedMileage > 0).toList();
    if (values.length < 2) return 1.0; // Not enough data.

    final avg = MileageEngine.rollingAverage(entries);
    if (avg <= 0) return 1.0;

    final variance = values.fold(
            0.0,
            (sum, e) =>
                sum +
                ((e.calculatedMileage - avg) * (e.calculatedMileage - avg))) /
        values.length;
    final cv = variance / (avg * avg); // Coefficient of variation squared.

    // Map CV to score: 0% variance = 1.0, 25%+ variance = 0.0
    return (1.0 - (cv * 4)).clamp(0.0, 1.0);
  }

  /// Service compliance — how on-time are services?
  static double _serviceComplianceScore(
    List<ServiceRecord> records,
    double totalDistanceKm,
    double serviceIntervalKm,
  ) {
    if (totalDistanceKm < serviceIntervalKm) return 1.0; // No service due yet.
    if (records.isEmpty) return 0.5; // No records logged.

    final lastService = records.first;
    final kmSinceService = totalDistanceKm - lastService.odometerKm;
    final overdue = kmSinceService - serviceIntervalKm;

    if (overdue <= 0) return 1.0; // On time.
    // Linearly degrade: 1000 km overdue = 0.0
    return (1.0 - (overdue / 1000)).clamp(0.0, 1.0);
  }

  /// Fuel efficiency trend — improving = higher score.
  static double _fuelEfficiencyScore(List<FuelEntry> entries) {
    final recent = entries
        .where((e) => e.calculatedMileage > 0)
        .take(10)
        .toList();
    if (recent.length < 2) return 1.0;

    // Compare first half to second half.
    final mid = recent.length ~/ 2;
    final recentHalf = recent.sublist(0, mid);
    final olderHalf = recent.sublist(mid);

    final recentAvg =
        recentHalf.fold(0.0, (s, e) => s + e.calculatedMileage) /
            recentHalf.length;
    final olderAvg =
        olderHalf.fold(0.0, (s, e) => s + e.calculatedMileage) /
            olderHalf.length;

    if (olderAvg <= 0) return 1.0;
    final ratio = recentAvg / olderAvg;

    // 1.0+ = improving (score 1.0), 0.8 = declining (score 0.5), 0.6 = bad (score 0.0)
    return ((ratio - 0.6) / 0.4).clamp(0.0, 1.0);
  }

  /// Get individual category scores for the categorized health dashboard.
  static Map<String, double> categoryScores({
    required List<FuelEntry> fuelEntries,
    required List<ServiceRecord> serviceRecords,
    required double totalDistanceKm,
    double serviceIntervalKm = AppConstants.defaultServiceIntervalKm,
  }) {
    return {
      'Fuel Efficiency': _fuelEfficiencyScore(fuelEntries),
      'Maintenance': _serviceComplianceScore(
          serviceRecords, totalDistanceKm, serviceIntervalKm),
      'Ride Consistency': _mileageStabilityScore(fuelEntries),
      'Service Health': _serviceComplianceScore(
          serviceRecords, totalDistanceKm, serviceIntervalKm),
    };
  }
}
