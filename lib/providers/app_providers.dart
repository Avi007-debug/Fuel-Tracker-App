import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/core/database/database_service.dart';
import 'package:fuel_tracker_app/services/trip_service.dart';
import 'package:fuel_tracker_app/services/fuel_service.dart';
import 'package:fuel_tracker_app/services/vehicle_service.dart';
import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/models/vehicle_profile.dart';
import 'package:fuel_tracker_app/models/service_record.dart';
import 'package:fuel_tracker_app/core/analytics/service_engine.dart';
import 'package:fuel_tracker_app/core/analytics/health_score.dart';
import 'package:fuel_tracker_app/core/analytics/refill_predictor.dart';

// ─── Service Providers ───────────────────────────────────────────────

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final tripServiceProvider = Provider<TripService>((ref) {
  return TripService(ref.read(databaseServiceProvider));
});

final fuelServiceProvider = Provider<FuelService>((ref) {
  return FuelService(
    ref.read(databaseServiceProvider),
    ref.read(tripServiceProvider),
  );
});

final vehicleServiceProvider = Provider<VehicleService>((ref) {
  return VehicleService(ref.read(databaseServiceProvider));
});

// ─── Data Providers ──────────────────────────────────────────────────

/// All trips, refreshable.
final allTripsProvider = FutureProvider<List<Trip>>((ref) async {
  return ref.read(tripServiceProvider).getAllTrips();
});

/// Today's trips only.
final todayTripsProvider = FutureProvider<List<Trip>>((ref) async {
  return ref.read(tripServiceProvider).getTodayTrips();
});

/// Today's total distance.
final todayDistanceProvider = FutureProvider<double>((ref) async {
  return ref.read(tripServiceProvider).getTodayDistance();
});

/// This month's total distance.
final monthDistanceProvider = FutureProvider<double>((ref) async {
  return ref.read(tripServiceProvider).getMonthDistance();
});

/// All fuel entries, refreshable.
final allFuelEntriesProvider = FutureProvider<List<FuelEntry>>((ref) async {
  return ref.read(fuelServiceProvider).getAllEntries();
});

/// Estimated fuel remaining (litres).
final fuelRemainingProvider = FutureProvider<double>((ref) async {
  return ref.read(fuelServiceProvider).getEstimatedFuelRemaining();
});

/// Estimated range remaining (km).
final estimatedRangeProvider = FutureProvider<double>((ref) async {
  return ref.read(fuelServiceProvider).getEstimatedRange();
});

/// Rolling average mileage (km/L).
final averageMileageProvider = FutureProvider<double>((ref) async {
  return ref.read(fuelServiceProvider).getRollingAverageMileage();
});

/// Monthly fuel spend (₹).
final monthSpendProvider = FutureProvider<double>((ref) async {
  return ref.read(fuelServiceProvider).getMonthSpend();
});

/// Vehicle profile.
final vehicleProfileProvider = FutureProvider<VehicleProfile?>((ref) async {
  return ref.read(vehicleServiceProvider).getProfile();
});

/// Whether onboarding is complete.
final isOnboardedProvider = FutureProvider<bool>((ref) async {
  return ref.read(vehicleServiceProvider).isOnboarded();
});

/// Lifetime total distance.
final totalDistanceProvider = FutureProvider<double>((ref) async {
  return ref.read(tripServiceProvider).getTotalDistance();
});

/// Total trip count.
final tripCountProvider = FutureProvider<int>((ref) async {
  return ref.read(tripServiceProvider).getTripCount();
});

/// All service records.
final allServiceRecordsProvider = FutureProvider<List<ServiceRecord>>((ref) async {
  return ref.read(databaseServiceProvider).getAllServiceRecords();
});

/// Service status for all types.
final serviceStatusProvider = FutureProvider<List<ServiceStatus>>((ref) async {
  final records = await ref.read(allServiceRecordsProvider.future);
  final totalDistance = await ref.read(totalDistanceProvider.future);
  final profile = await ref.read(vehicleProfileProvider.future);
  
  if (profile == null) return [];
  
  return ServiceEngine.getAllServiceStatus(
    records: records,
    currentOdometerKm: totalDistance,
    vehicle: profile,
  );
});

/// Composite Vehicle Health Score (0.0 to 1.0).
final vehicleHealthScoreProvider = FutureProvider<double>((ref) async {
  final fuelEntries = await ref.read(allFuelEntriesProvider.future);
  final serviceRecords = await ref.read(allServiceRecordsProvider.future);
  final totalDistance = await ref.read(totalDistanceProvider.future);
  final profile = await ref.read(vehicleProfileProvider.future);
  
  if (profile == null) return 1.0;
  
  return HealthScore.compute(
    fuelEntries: fuelEntries,
    serviceRecords: serviceRecords,
    totalDistanceKm: totalDistance,
    serviceIntervalKm: profile.serviceIntervalKm,
  );
});

/// Category health scores.
final healthCategoryScoresProvider = FutureProvider<Map<String, double>>((ref) async {
  final fuelEntries = await ref.read(allFuelEntriesProvider.future);
  final serviceRecords = await ref.read(allServiceRecordsProvider.future);
  final totalDistance = await ref.read(totalDistanceProvider.future);
  final profile = await ref.read(vehicleProfileProvider.future);
  
  if (profile == null) return {};
  
  return HealthScore.categoryScores(
    fuelEntries: fuelEntries,
    serviceRecords: serviceRecords,
    totalDistanceKm: totalDistance,
    serviceIntervalKm: profile.serviceIntervalKm,
  );
});

/// Next refill prediction.
final refillPredictionProvider = FutureProvider<RefillPrediction>((ref) async {
  final trips = await ref.read(allTripsProvider.future);
  final fuelRemaining = await ref.read(fuelRemainingProvider.future);
  final avgMileage = await ref.read(averageMileageProvider.future);
  final profile = await ref.read(vehicleProfileProvider.future);
  
  if (profile == null) {
    return RefillPrediction(
      predictedDate: DateTime.now(),
      daysRemaining: 0,
      kmRemaining: 0,
      confidence: 0.0,
    );
  }
  
  return RefillPredictor.predictNextRefill(
    trips: trips,
    fuelRemainingL: fuelRemaining,
    averageMileageKmPerL: avgMileage,
    reserveL: profile.reserveL,
  );
});
