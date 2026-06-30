import 'package:fuel_tracker_app/models/trip.dart';

/// Next refill predictor — estimates when the next refill will be needed.
/// 
/// Algorithm:
/// - Calculate average daily km from the last 2 weeks
/// - Use current fuel remaining and average mileage
/// - Project days until tank hits reserve level
class RefillPredictor {
  RefillPredictor._();

  /// Predict the next refill date based on riding patterns.
  static RefillPrediction predictNextRefill({
    required List<Trip> trips,
    required double fuelRemainingL,
    required double averageMileageKmPerL,
    required double reserveL,
  }) {
    if (averageMileageKmPerL <= 0 || fuelRemainingL <= 0) {
      return RefillPrediction(
        predictedDate: DateTime.now(),
        daysRemaining: 0,
        kmRemaining: 0,
        confidence: 0.0,
      );
    }

    // Calculate average daily km from last 14 days
    final avgDailyKm = _calculateAverageDailyKm(trips, days: 14);

    if (avgDailyKm <= 0) {
      // No riding pattern — estimate based on typical usage
      final estimatedDailyKm = 20.0; // Conservative estimate
      final usableFuel = fuelRemainingL - reserveL;
      final kmRemaining = usableFuel * averageMileageKmPerL;
      final daysRemaining = (kmRemaining / estimatedDailyKm).ceil();

      return RefillPrediction(
        predictedDate: DateTime.now().add(Duration(days: daysRemaining)),
        daysRemaining: daysRemaining,
        kmRemaining: kmRemaining,
        confidence: 0.3, // Low confidence due to lack of data
      );
    }

    // Calculate with actual riding pattern
    final usableFuel = (fuelRemainingL - reserveL).clamp(0, double.infinity);
    final kmRemaining = usableFuel * averageMileageKmPerL;
    final daysRemaining = (kmRemaining / avgDailyKm).ceil().clamp(0, 30);

    // Confidence based on data consistency
    final confidence = _calculateConfidence(trips, days: 14);

    return RefillPrediction(
      predictedDate: DateTime.now().add(Duration(days: daysRemaining)),
      daysRemaining: daysRemaining,
      kmRemaining: kmRemaining,
      confidence: confidence,
    );
  }

  /// Calculate average daily km from recent trip history.
  static double _calculateAverageDailyKm(List<Trip> trips, {required int days}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recentTrips = trips.where((t) => t.timestamp.isAfter(cutoff)).toList();

    if (recentTrips.isEmpty) return 0.0;

    final totalKm = recentTrips.fold<double>(0.0, (sum, t) => sum + t.distanceKm);
    final actualDays = DateTime.now().difference(recentTrips.last.timestamp).inDays.clamp(1, days);

    return totalKm / actualDays;
  }

  /// Calculate prediction confidence based on riding pattern consistency.
  /// 
  /// Returns 0.0 - 1.0 where:
  /// - 1.0 = very consistent daily riding
  /// - 0.5 = moderate variation
  /// - 0.0 = highly irregular or no data
  static double _calculateConfidence(List<Trip> trips, {required int days}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recentTrips = trips.where((t) => t.timestamp.isAfter(cutoff)).toList();

    if (recentTrips.length < 5) return 0.3;

    // Group trips by day
    final dailyDistances = <DateTime, double>{};
    for (final trip in recentTrips) {
      final day = DateTime(trip.timestamp.year, trip.timestamp.month, trip.timestamp.day);
      dailyDistances[day] = (dailyDistances[day] ?? 0) + trip.distanceKm;
    }

    if (dailyDistances.isEmpty) return 0.0;

    final distances = dailyDistances.values.toList();
    final avgDistance = distances.reduce((a, b) => a + b) / distances.length;

    // Calculate coefficient of variation
    final variance = distances.fold(0.0, (sum, d) => sum + ((d - avgDistance) * (d - avgDistance))) / distances.length;
    final stdDev = variance > 0 ? (variance).abs().clamp(0, double.infinity).toDouble() : 0.0;
    final cv = avgDistance > 0 ? stdDev / avgDistance : 1.0;

    // Map CV to confidence: lower CV = higher confidence
    // CV < 0.3 = high confidence, CV > 1.0 = low confidence
    final confidence = (1.0 - cv).clamp(0.2, 1.0);

    return confidence;
  }

  /// Get refuel recommendation message.
  static String getRefuelRecommendation(RefillPrediction prediction) {
    if (prediction.daysRemaining <= 1) {
      return 'Refuel today! Running low on fuel.';
    } else if (prediction.daysRemaining <= 3) {
      return 'Consider refueling in the next ${prediction.daysRemaining} days.';
    } else if (prediction.daysRemaining <= 7) {
      return 'You have about ${prediction.daysRemaining} days before refueling.';
    } else {
      return 'Fuel level is comfortable. Refuel in ${prediction.daysRemaining}+ days.';
    }
  }
}

/// Next refill prediction result.
class RefillPrediction {
  final DateTime predictedDate;
  final int daysRemaining;
  final double kmRemaining;
  final double confidence; // 0.0 - 1.0

  RefillPrediction({
    required this.predictedDate,
    required this.daysRemaining,
    required this.kmRemaining,
    required this.confidence,
  });

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final predDate = DateTime(predictedDate.year, predictedDate.month, predictedDate.day);

    final diff = predDate.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return 'In $diff days';
    
    return '${predictedDate.day}/${predictedDate.month}/${predictedDate.year}';
  }

  String get confidenceLabel {
    if (confidence >= 0.8) return 'High confidence';
    if (confidence >= 0.5) return 'Moderate confidence';
    return 'Low confidence';
  }
}
