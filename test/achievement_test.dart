import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/models/route_type.dart';
import 'package:fuel_tracker_app/models/service_record.dart';
import 'package:fuel_tracker_app/models/vehicle_profile.dart';
import 'package:fuel_tracker_app/services/achievement_service.dart';
import 'package:fuel_tracker_app/services/milestone_service.dart';
import 'package:fuel_tracker_app/core/database/database_service.dart';

class TestFakeDatabase implements DatabaseService {
  List<Trip> trips = [];
  List<FuelEntry> fuelEntries = [];
  List<ServiceRecord> serviceRecords = [];

  @override
  Future<List<Trip>> getAllTrips() async => trips;

  @override
  Future<List<FuelEntry>> getAllFuelEntries() async => fuelEntries;

  @override
  Future<List<ServiceRecord>> getAllServiceRecords() async => serviceRecords;

  @override
  Future<Map<String, dynamic>?> getSettings() async => {};

  @override
  Future<VehicleProfile?> getVehicleProfile() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Achievements Evaluation tests', () {
    late TestFakeDatabase db;
    late AchievementService service;

    setUp(() {
      db = TestFakeDatabase();
      service = AchievementService(db);
    });

    test('Kilometer Club calculations', () async {
      db.trips = [
        Trip(id: '1', timestamp: DateTime(2026, 6, 25), routeType: RouteType.collegeGo, distanceKm: 500.0),
        Trip(id: '2', timestamp: DateTime(2026, 6, 26), routeType: RouteType.collegeGo, distanceKm: 400.0),
      ];

      var achievements = await service.getAchievements();
      var kmClub = achievements.firstWhere((a) => a.id == 'km_club');
      expect(kmClub.isUnlocked, false);
      expect(kmClub.progress, 0.9); // 900 / 1000

      db.trips.add(
        Trip(id: '3', timestamp: DateTime(2026, 6, 27), routeType: RouteType.collegeGo, distanceKm: 200.0),
      );

      achievements = await service.getAchievements();
      kmClub = achievements.firstWhere((a) => a.id == 'km_club');
      expect(kmClub.isUnlocked, true);
      expect(kmClub.progress, 1.0);
      expect(kmClub.unlockDate, DateTime(2026, 6, 27));
    });

    test('Efficiency Master (Peak mileage)', () async {
      db.fuelEntries = [
        FuelEntry(
          id: '1',
          timestamp: DateTime(2026, 6, 20),
          odometerAtFill: 100.0,
          litresFilled: 4.0,
          pricePerLitre: 100.0,
          amountPaid: 400.0,
          kmSinceLastFill: 160.0,
          calculatedMileage: 40.0,
        ),
      ];

      var achievements = await service.getAchievements();
      var efficiency = achievements.firstWhere((a) => a.id == 'efficiency_master');
      expect(efficiency.isUnlocked, false);

      db.fuelEntries.add(
        FuelEntry(
          id: '2',
          timestamp: DateTime(2026, 6, 25),
          odometerAtFill: 300.0,
          litresFilled: 4.0,
          pricePerLitre: 100.0,
          amountPaid: 400.0,
          kmSinceLastFill: 190.0,
          calculatedMileage: 47.5,
        ),
      );

      achievements = await service.getAchievements();
      efficiency = achievements.firstWhere((a) => a.id == 'efficiency_master');
      expect(efficiency.isUnlocked, true);
      expect(efficiency.unlockDate, DateTime(2026, 6, 25));
    });

    test('Consistent Rider streak calculations', () async {
      db.trips = [
        Trip(id: '1', timestamp: DateTime(2026, 6, 1), routeType: RouteType.shortGo, distanceKm: 2.0),
        Trip(id: '2', timestamp: DateTime(2026, 6, 2), routeType: RouteType.shortGo, distanceKm: 2.0),
        Trip(id: '3', timestamp: DateTime(2026, 6, 3), routeType: RouteType.shortGo, distanceKm: 2.0),
        Trip(id: '4', timestamp: DateTime(2026, 6, 4), routeType: RouteType.shortGo, distanceKm: 2.0),
      ];

      var achievements = await service.getAchievements();
      var streak = achievements.firstWhere((a) => a.id == 'consistent_rider');
      expect(streak.isUnlocked, false);
      expect(streak.progress, 0.8); // 4 / 5 days

      db.trips.add(
        Trip(id: '5', timestamp: DateTime(2026, 6, 5), routeType: RouteType.shortGo, distanceKm: 2.0),
      );

      achievements = await service.getAchievements();
      streak = achievements.firstWhere((a) => a.id == 'consistent_rider');
      expect(streak.isUnlocked, true);
    });
  });

  group('Milestones extraction tests', () {
    late TestFakeDatabase db;
    late MilestoneService service;

    setUp(() {
      db = TestFakeDatabase();
      service = MilestoneService(db);
    });

    test('Chronological Milestones matching', () async {
      db.trips = [
        Trip(id: '1', timestamp: DateTime(2026, 6, 1, 10, 0), routeType: RouteType.collegeGo, distanceKm: 120.0),
      ];
      db.fuelEntries = [
        FuelEntry(
          id: '1',
          timestamp: DateTime(2026, 6, 2, 18, 0),
          odometerAtFill: 120.0,
          litresFilled: 5.0,
          pricePerLitre: 104.0,
          amountPaid: 520.0,
          kmSinceLastFill: 120.0,
          calculatedMileage: 24.0,
        ),
      ];

      final milestones = await service.getMilestones();
      expect(milestones.any((m) => m.id == 'first_trip'), true);
      expect(milestones.any((m) => m.id == 'first_refill'), true);
      expect(milestones.any((m) => m.id == 'odo_100'), true);
    });
  });
}
