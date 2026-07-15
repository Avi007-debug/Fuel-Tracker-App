import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fuel_tracker_app/core/database/database_service.dart';
import 'package:fuel_tracker_app/services/trip_service.dart';
import 'package:fuel_tracker_app/services/fuel_service.dart';
import 'package:fuel_tracker_app/services/vehicle_service.dart';
import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/models/vehicle_profile.dart';
import 'package:fuel_tracker_app/models/service_record.dart';
import 'package:fuel_tracker_app/models/daily_cost.dart';
import 'package:fuel_tracker_app/core/analytics/service_engine.dart';
import 'package:fuel_tracker_app/core/analytics/health_score.dart';
import 'package:fuel_tracker_app/core/analytics/refill_predictor.dart';
import 'package:fuel_tracker_app/core/analytics/mileage_engine.dart';
import 'package:fuel_tracker_app/core/analytics/pattern_analyser.dart';
import 'package:fuel_tracker_app/core/analytics/fuel_estimator.dart';
import 'package:fuel_tracker_app/services/achievement_service.dart';
import 'package:fuel_tracker_app/services/milestone_service.dart';
import 'package:fuel_tracker_app/core/database/backup_service.dart';
import 'package:fuel_tracker_app/features/settings/controller.dart';
import 'package:fuel_tracker_app/core/ai/llm_service.dart';
import 'package:fuel_tracker_app/services/daily_cost_service.dart';

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

final dailyCostServiceProvider = Provider<DailyCostService>((ref) {
  return DailyCostService(ref.read(databaseServiceProvider));
});

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService(ref.read(databaseServiceProvider));
});

final milestoneServiceProvider = Provider<MilestoneService>((ref) {
  return MilestoneService(ref.read(databaseServiceProvider));
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.read(databaseServiceProvider));
});

final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(ref);
});

final llmServiceProvider = Provider<LlmService>((ref) {
  final service = LlmService();
  ref.onDispose(() => service.dispose());
  return service;
});

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPrefsProvider must be overridden');
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  
  ThemeModeNotifier(this._prefs) : super(_loadTheme(_prefs));

  static ThemeMode _loadTheme(SharedPreferences prefs) {
    final themeStr = prefs.getString('themeMode');
    if (themeStr == 'light') return ThemeMode.light;
    return ThemeMode.dark;
  }

  void toggleTheme() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _prefs.setString('themeMode', state.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return ThemeModeNotifier(prefs);
});

// ─── Data Providers ──────────────────────────────────────────────────

/// All trips, refreshable.
final allTripsProvider = FutureProvider<List<Trip>>((ref) async {
  return ref.read(tripServiceProvider).getAllTrips();
});

/// Trashed trips.
final trashTripsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(tripServiceProvider).getTrashedTrips();
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

/// Mileage prediction confidence (percentage 0 - 100).
final mileageConfidenceProvider = FutureProvider<int>((ref) async {
  final entries = await ref.watch(allFuelEntriesProvider.future);
  final confidence = MileageEngine.calculateMileageConfidence(entries);
  return (confidence * 100).round();
});

/// Day of week average distances.
final dayAveragesProvider = FutureProvider<Map<int, double>>((ref) async {
  final trips = await ref.watch(allTripsProvider.future);
  return PatternAnalyser.dayOfWeekAverages(trips);
});

/// 7-day predictive fuel forecast (litres).
final predictiveFuelForecastProvider = FutureProvider<List<double>>((ref) async {
  final currentFuel = await ref.watch(fuelRemainingProvider.future);
  final avgMileage = await ref.watch(averageMileageProvider.future);
  final dayAverages = await ref.watch(dayAveragesProvider.future);
  
  return FuelEstimator.predict7DayForecast(
    currentFuelL: currentFuel,
    averageMileageKmPerL: avgMileage,
    dayAverages: dayAverages,
  );
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

// ─── Daily Costs ─────────────────────────────────────────────────────

final allDailyCostsProvider = FutureProvider<List<DailyCost>>((ref) async {
  return ref.read(dailyCostServiceProvider).getAllDailyCosts();
});

final weeklyDailyCostProvider = FutureProvider<double>((ref) async {
  return ref.read(dailyCostServiceProvider).getWeeklyCost();
});

final monthlyDailyCostProvider = FutureProvider<double>((ref) async {
  return ref.read(dailyCostServiceProvider).getMonthlyCost();
});

// ─── Analytics ───────────────────────────────────────────────────────

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

/// List of all achievements.
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  return ref.watch(achievementServiceProvider).getAchievements();
});

/// List of all milestones.
final milestonesProvider = FutureProvider<List<Milestone>>((ref) async {
  return ref.watch(milestoneServiceProvider).getMilestones();
});

/// App Settings map.
final appSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return (await ref.watch(databaseServiceProvider).getSettings()) ?? {};
});
