import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:fuel_tracker_app/core/database/database_service.dart';
import 'package:fuel_tracker_app/core/notifications/notification_service.dart';
import 'package:fuel_tracker_app/core/analytics/fuel_estimator.dart';
import 'package:fuel_tracker_app/core/analytics/service_engine.dart';
import 'package:fuel_tracker_app/models/route_type.dart';
import 'package:fuel_tracker_app/utils/date_helpers.dart';
import 'package:fuel_tracker_app/services/trip_service.dart';
import 'package:fuel_tracker_app/services/fuel_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    dev.log('Background task running: $taskName');
    
    try {
      // 1. Initialise core services
      await DatabaseService.init();
      await NotificationService.init();
      
      final db = DatabaseService.instance;
      final trips = await db.getAllTrips();
      final tripService = TripService(db);
      final fuelService = FuelService(db, tripService);
      final fuelEntries = await fuelService.getAllEntries();
      final serviceRecords = await db.getAllServiceRecords();
      final vehicle = await db.getVehicleProfile();

      // ─── 1. Evening Return Trip Escalation ───────────────────────
      // If it's a weekday between 6:00 PM and 10:00 PM
      final now = DateTime.now();
      final isWeekday = now.weekday != DateTime.saturday && now.weekday != DateTime.sunday;
      final isEvening = now.hour >= 18 && now.hour < 22;

      if (isWeekday && isEvening) {
        final todayTrips = trips.where((t) => DateHelpers.isToday(t.timestamp)).toList();
        final hasGo = todayTrips.any((t) => t.routeType == RouteType.collegeGo);
        final hasReturn = todayTrips.any((t) => t.routeType == RouteType.collegeReturn);

        if (hasGo && !hasReturn) {
          dev.log('Evening return trip missing! Alerting user.');
          await NotificationService.instance.showEveningEscalation();
        } else {
          // If return logged or go not logged, ensure notification is cleared/not shown
          await NotificationService.instance.cancelEveningEscalation();
        }
      }

      // ─── 2. Low Fuel Alert Check ──────────────────────────────────
      if (fuelEntries.isNotEmpty && vehicle != null) {
        final fuelRemaining = await fuelService.getEstimatedFuelRemaining();
        final rangeRemaining = await fuelService.getEstimatedRange();

        if (FuelEstimator.isLowFuel(estimatedRangeKm: rangeRemaining)) {
          dev.log('Low fuel alert range remaining: $rangeRemaining km');
          await NotificationService.instance.showLowFuelAlert(rangeRemaining);
        } else {
          await NotificationService.instance.cancelLowFuelAlert();
        }
      }

      // ─── 3. Service Alerts Check ──────────────────────────────────
      if (vehicle != null) {
        // Calculate current odometer: initial odometer + total trips distance
        final totalDistance = trips.fold<double>(0.0, (sum, t) => sum + t.distanceKm);
        final currentOdometer = (vehicle.initialOdometer ?? 0.0) + totalDistance;

        final dueServices = ServiceEngine.checkServicesDue(
          records: serviceRecords,
          currentOdometerKm: currentOdometer,
          vehicle: vehicle,
        );

        for (final service in dueServices) {
          dev.log('Service due: ${service.type.label}, remaining: ${service.kmRemaining} km');
          await NotificationService.instance.showServiceAlert(
            serviceType: service.type.label,
            kmRemaining: service.kmRemaining,
          );
        }
      }

      return true;
    } catch (e, stackTrace) {
      dev.log('Error executing background task: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  });
}

class BackgroundWorker {
  static const String periodicTaskName = 'com.fuel_tracker_app.periodic_analytics';
  static const String periodicTaskUniqueId = 'periodic_analytics_task';

  /// Initialise the Workmanager scheduler.
  static Future<void> initialize() async {
    if (kIsWeb) return;
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  /// Register the periodic background task (runs every 15 minutes).
  static Future<void> registerPeriodicTask() async {
    if (kIsWeb) return;
    await Workmanager().registerPeriodicTask(
      periodicTaskUniqueId,
      periodicTaskName,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  /// Cancel all background tasks.
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await Workmanager().cancelAll();
  }
}
