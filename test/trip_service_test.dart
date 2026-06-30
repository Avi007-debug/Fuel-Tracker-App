import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/models/route_type.dart';
import 'package:fuel_tracker_app/services/trip_service.dart';
import 'package:fuel_tracker_app/core/database/database_service.dart';

class FakeDatabase implements DatabaseService {
  List<Trip> trips = [];
  List<FuelEntry> fuelEntries = [];

  @override
  Future<List<Trip>> getAllTrips() async => trips;

  @override
  Future<List<FuelEntry>> getAllFuelEntries() async => fuelEntries;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TripService distance calculations', () {
    late FakeDatabase db;
    late TripService service;

    setUp(() {
      db = FakeDatabase();
      service = TripService(db);
    });

    test('Regular trips without refill splits', () async {
      final now = DateTime.now();
      db.trips = [
        Trip(
          id: '1',
          timestamp: now.subtract(const Duration(hours: 1)),
          routeType: RouteType.collegeGo,
          distanceKm: 7.2,
        ),
        Trip(
          id: '2',
          timestamp: now.subtract(const Duration(hours: 2)),
          routeType: RouteType.shortGo,
          distanceKm: 2.0,
        ),
      ];

      final dist = await service.getDistanceSinceLastFuel(now.subtract(const Duration(hours: 3)));
      expect(dist, 9.2); // 7.2 + 2.0
    });

    test('Refill split on starting day', () async {
      final lastRefillDate = DateTime(2026, 6, 30, 17, 30);
      
      db.trips = [
        // Return trip logged on the same day as the starting refill (at 18:00)
        Trip(
          id: '1',
          timestamp: DateTime(2026, 6, 30, 18, 0),
          routeType: RouteType.collegeReturn,
          distanceKm: 8.4,
        ),
        // Going trip logged next morning
        Trip(
          id: '2',
          timestamp: DateTime(2026, 7, 1, 8, 30),
          routeType: RouteType.collegeGo,
          distanceKm: 7.2,
        ),
      ];

      // Distance since lastRefillDate (June 30 17:30) up to next day
      final dist = await service.getDistanceSinceLastFuel(
        lastRefillDate,
        endFuelDate: DateTime(2026, 7, 1, 18, 0),
      );
      
      // Expected:
      // - The return trip on starting day (June 30) is split, contributing 4.6 km
      // - The going trip contributes 7.2 km
      // Total = 4.6 + 7.2 = 11.8 km
      expect(dist, closeTo(11.8, 1e-9));
    });

    test('Refill split on ending day', () async {
      final lastRefillDate = DateTime(2026, 6, 30, 17, 30);
      final newRefillDate = DateTime(2026, 7, 2, 17, 30);
      
      db.trips = [
        // Return trip of starting day (June 30)
        Trip(
          id: '1',
          timestamp: DateTime(2026, 6, 30, 18, 0),
          routeType: RouteType.collegeReturn,
          distanceKm: 8.4,
        ),
        // Going trip (July 1)
        Trip(
          id: '2',
          timestamp: DateTime(2026, 7, 1, 8, 30),
          routeType: RouteType.collegeGo,
          distanceKm: 7.2,
        ),
        // Return trip of ending day (July 2) - logged at 18:00, refill at 17:30
        Trip(
          id: '3',
          timestamp: DateTime(2026, 7, 2, 18, 0),
          routeType: RouteType.collegeReturn,
          distanceKm: 8.4,
        ),
      ];

      final dist = await service.getDistanceSinceLastFuel(
        lastRefillDate,
        endFuelDate: newRefillDate,
        isEndRefill: true,
      );
      
      // Expected:
      // - Starting return trip contributes 4.6 km
      // - Going trip contributes 7.2 km
      // - Ending return trip contributes 3.8 km
      // Total = 4.6 + 7.2 + 3.8 = 15.6 km
      expect(dist, closeTo(15.6, 1e-9));
    });
  });
}
