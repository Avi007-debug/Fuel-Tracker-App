import 'package:uuid/uuid.dart';

import 'package:fuel_tracker_app/core/database/database_service.dart';
import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/route_type.dart';
import 'package:fuel_tracker_app/utils/date_helpers.dart';

/// Business logic for trip logging, editing, and querying.
class TripService {
  final DatabaseService _db;
  static const _uuid = Uuid();

  TripService(this._db);

  /// Get custom distance for route, falling back to enum default.
  Future<double> getRouteDistance(RouteType routeType) async {
    if (routeType == RouteType.custom) return 0.0;
    final settings = await _db.getSettings();
    if (settings != null && settings.containsKey(routeType.key)) {
      final val = settings[routeType.key];
      if (val is num) return val.toDouble();
    }
    return routeType.defaultDistanceKm;
  }

  /// Log a quick-action trip (fixed route).
  Future<Trip> logTrip(RouteType routeType, {String? notes}) async {
    final distance = await getRouteDistance(routeType);
    final trip = Trip(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      routeType: routeType,
      distanceKm: distance,
      notes: notes,
    );
    await _db.addTrip(trip);
    return trip;
  }

  /// Log a custom ride with manual distance.
  Future<Trip> logCustomTrip(double distanceKm, {String? notes}) async {
    final trip = Trip(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      routeType: RouteType.custom,
      distanceKm: distanceKm,
      notes: notes,
    );
    await _db.addTrip(trip);
    return trip;
  }

  /// Get all trips, most recent first.
  Future<List<Trip>> getAllTrips() => _db.getAllTrips();

  /// Get today's trips only.
  Future<List<Trip>> getTodayTrips() async {
    final all = await _db.getAllTrips();
    return all.where((t) => DateHelpers.isToday(t.timestamp)).toList();
  }

  /// Total distance today.
  Future<double> getTodayDistance() async {
    final trips = await getTodayTrips();
    return trips.fold<double>(0.0, (sum, t) => sum + t.distanceKm);
  }

  /// Total distance for the current month.
  Future<double> getMonthDistance() async {
    final all = await _db.getAllTrips();
    final start = DateHelpers.startOfMonth;
    return all
        .where((t) => t.timestamp.isAfter(start))
        .fold<double>(0.0, (sum, t) => sum + t.distanceKm);
  }

  /// Total distance since last fuel entry (for mileage calculation).
  ///
  /// Adjusts the College Return trip (8.4 km) overlapping with refills:
  /// - Starting refill day return trip: only counts 4.6 km (Pump -> Home portion)
  /// - Ending refill day return trip: only counts 3.8 km (Metro -> Pump portion)
  Future<double> getDistanceSinceLastFuel(
    DateTime lastFuelDate, {
    DateTime? endFuelDate,
    bool isEndRefill = false,
  }) async {
    final endDate = endFuelDate ?? DateTime.now();
    final all = await _db.getAllTrips();
    
    double totalDistance = 0.0;
    for (final t in all) {
      if (t.routeType == RouteType.collegeReturn) {
        if (_isSameDay(t.timestamp, lastFuelDate)) {
          // Overlapping return trip at the start of the interval (refill day)
          // Only the portion driven AFTER the refill (Pump -> Home = 4.6 km) belongs to this interval
          totalDistance += 4.6;
        } else if (isEndRefill && _isSameDay(t.timestamp, endDate)) {
          // Overlapping return trip at the end of the interval (refill day)
          // Only the portion driven BEFORE the refill (Metro -> Pump = 3.8 km) belongs to this interval
          totalDistance += 3.8;
        } else if (t.timestamp.isAfter(lastFuelDate) && t.timestamp.isBefore(endDate)) {
          // A regular return trip in the middle of the interval (no refill on this day)
          totalDistance += t.distanceKm;
        }
      } else {
        // All other trips (going, short, custom) are counted fully if they fall within the interval
        if (t.timestamp.isAfter(lastFuelDate) && t.timestamp.isBefore(endDate)) {
          totalDistance += t.distanceKm;
        }
      }
    }
    return totalDistance;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// Lifetime total distance.
  Future<double> getTotalDistance() async {
    final all = await _db.getAllTrips();
    return all.fold<double>(0.0, (sum, t) => sum + t.distanceKm);
  }

  /// Total trip count.
  Future<int> getTripCount() async {
    final all = await _db.getAllTrips();
    return all.length;
  }

  /// Check if a "Going" trip was logged today (for notification suppression).
  Future<bool> hasGoingTripToday() async {
    final trips = await getTodayTrips();
    return trips.any((t) => t.routeType.isGoing);
  }

  /// Check if a "Return" trip was logged today.
  Future<bool> hasReturnTripToday() async {
    final trips = await getTodayTrips();
    return trips.any((t) => t.routeType.isReturn);
  }

  /// Update an existing trip.
  Future<void> updateTrip(Trip trip) => _db.updateTrip(trip);

  /// Delete a trip.
  Future<void> deleteTrip(String id) => _db.deleteTrip(id);

  /// Undo (delete) the most recent trip.
  Future<void> undoLastTrip() async {
    final all = await _db.getAllTrips();
    if (all.isNotEmpty) {
      await _db.deleteTrip(all.first.id);
    }
  }
}
