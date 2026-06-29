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

  /// Log a quick-action trip (fixed route).
  Future<Trip> logTrip(RouteType routeType, {String? notes}) async {
    final trip = Trip(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      routeType: routeType,
      distanceKm: routeType.defaultDistanceKm,
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
  Future<double> getDistanceSinceLastFuel(DateTime lastFuelDate) async {
    final all = await _db.getAllTrips();
    return all
        .where((t) => t.timestamp.isAfter(lastFuelDate))
        .fold<double>(0.0, (sum, t) => sum + t.distanceKm);
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
