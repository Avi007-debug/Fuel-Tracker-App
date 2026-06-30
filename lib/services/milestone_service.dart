import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/models/service_record.dart';
import 'package:fuel_tracker_app/core/database/database_service.dart';
import 'package:intl/intl.dart';

enum MilestoneType {
  trip,
  fuel,
  odometer,
  service,
  monthlySummary,
}

class Milestone {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final String icon;
  final MilestoneType type;

  const Milestone({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.type,
  });
}

class MilestoneService {
  final DatabaseService _db;

  MilestoneService(this._db);

  Future<List<Milestone>> getMilestones() async {
    final trips = await _db.getAllTrips();
    final fuelEntries = await _db.getAllFuelEntries();
    final serviceRecords = await _db.getAllServiceRecords();

    final milestones = <Milestone>[];

    // Chronological order (oldest first)
    final sortedTrips = List<Trip>.from(trips)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final sortedFuel = List<FuelEntry>.from(fuelEntries)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final sortedService = List<ServiceRecord>.from(serviceRecords)..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    // 1. First Trip
    if (sortedTrips.isNotEmpty) {
      final firstTrip = sortedTrips.first;
      milestones.add(Milestone(
        id: 'first_trip',
        title: 'Your First Trip!',
        subtitle: 'Logged a ${firstTrip.distanceKm} km ride: ${firstTrip.routeType.label}',
        date: firstTrip.timestamp,
        icon: '🛵',
        type: MilestoneType.trip,
      ));
    }

    // 2. First Refill
    if (sortedFuel.isNotEmpty) {
      final firstFuel = sortedFuel.first;
      milestones.add(Milestone(
        id: 'first_refill',
        title: 'First Refill Logged!',
        subtitle: 'Filled ${firstFuel.litresFilled.toStringAsFixed(1)} Litres @ ₹${firstFuel.pricePerLitre.toStringAsFixed(1)}/L',
        date: firstFuel.timestamp,
        icon: '⛽',
        type: MilestoneType.fuel,
      ));
    }

    // 3. Cumulative Odometer Milestones (100 km, 500 km, 1000 km)
    double runningDist = 0.0;
    bool reached100 = false;
    bool reached500 = false;
    bool reached1000 = false;

    for (final t in sortedTrips) {
      runningDist += t.distanceKm;
      if (runningDist >= 100.0 && !reached100) {
        reached100 = true;
        milestones.add(Milestone(
          id: 'odo_100',
          title: '100 km Completed!',
          subtitle: 'You crossed 100 km of total riding!',
          date: t.timestamp,
          icon: '🛣️',
          type: MilestoneType.odometer,
        ));
      }
      if (runningDist >= 500.0 && !reached500) {
        reached500 = true;
        milestones.add(Milestone(
          id: 'odo_500',
          title: '500 km Completed!',
          subtitle: 'Fantastic milestone! Crossed 500 km total.',
          date: t.timestamp,
          icon: '🚀',
          type: MilestoneType.odometer,
        ));
      }
      if (runningDist >= 1000.0 && !reached1000) {
        reached1000 = true;
        milestones.add(Milestone(
          id: 'odo_1000',
          title: '1,000 km Club!',
          subtitle: 'Official member of the 1k club! Crossed 1,000 km.',
          date: t.timestamp,
          icon: '👑',
          type: MilestoneType.odometer,
        ));
      }
    }

    // 4. Best Mileage Refill
    if (sortedFuel.length >= 2) {
      double highestMil = 0.0;
      FuelEntry? bestRefill;
      for (final e in sortedFuel) {
        if (e.calculatedMileage > highestMil) {
          highestMil = e.calculatedMileage;
          bestRefill = e;
        }
      }
      if (bestRefill != null && highestMil > 0.0) {
        milestones.add(Milestone(
          id: 'best_mileage_${bestRefill.id}',
          title: 'Record Mileage Achieved!',
          subtitle: 'Reached your peak mileage of ${highestMil.toStringAsFixed(1)} km/L',
          date: bestRefill.timestamp,
          icon: '✨',
          type: MilestoneType.fuel,
        ));
      }
    }

    // 5. Service Completed
    for (final s in sortedService) {
      milestones.add(Milestone(
        id: 'service_${s.completedAt.millisecondsSinceEpoch}',
        title: '${s.serviceType.label} Completed',
        subtitle: 'Completed service at odometer ${s.odometerKm.toInt()} km',
        date: s.completedAt,
        icon: '🔧',
        type: MilestoneType.service,
      ));
    }

    // 6. Monthly Summaries
    final monthlyTrips = <String, List<Trip>>{};
    final monthlyFuel = <String, List<FuelEntry>>{};
    
    for (final t in sortedTrips) {
      final key = DateFormat('MMMM yyyy').format(t.timestamp);
      monthlyTrips.putIfAbsent(key, () => []).add(t);
    }
    for (final f in sortedFuel) {
      final key = DateFormat('MMMM yyyy').format(f.timestamp);
      monthlyFuel.putIfAbsent(key, () => []).add(f);
    }

    final allMonths = {...monthlyTrips.keys, ...monthlyFuel.keys}.toList();
    for (final mKey in allMonths) {
      final monthTrips = monthlyTrips[mKey] ?? [];
      final monthRefills = monthlyFuel[mKey] ?? [];
      
      final dist = monthTrips.fold<double>(0.0, (sum, t) => sum + t.distanceKm);
      final spend = monthRefills.fold<double>(0.0, (sum, f) => sum + (f.amountPaid ?? 0.0));
      
      if (dist > 0 || spend > 0) {
        DateTime mDate;
        if (monthTrips.isNotEmpty) {
          mDate = monthTrips.last.timestamp;
        } else {
          mDate = monthRefills.last.timestamp;
        }
        
        milestones.add(Milestone(
          id: 'monthly_summary_${mKey.replaceAll(' ', '_')}',
          title: '$mKey Summary',
          subtitle: 'Rode ${dist.toStringAsFixed(0)} km | Spent ₹${spend.toStringAsFixed(0)} on fuel',
          date: DateTime(mDate.year, mDate.month, mDate.day, 23, 59),
          icon: '📅',
          type: MilestoneType.monthlySummary,
        ));
      }
    }

    // Sort milestones most recent first
    return milestones..sort((a, b) => b.date.compareTo(a.date));
  }
}
