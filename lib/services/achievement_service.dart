import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/core/database/database_service.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockDate;
  final double progress; // 0.0 to 1.0

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.unlockDate,
    required this.progress,
  });
}

class AchievementService {
  final DatabaseService _db;

  AchievementService(this._db);

  Future<List<Achievement>> getAchievements() async {
    final trips = await _db.getAllTrips();
    final fuelEntries = await _db.getAllFuelEntries();

    // 1. Kilometer Club (1000 km)
    final totalDist = trips.fold<double>(0.0, (sum, t) => sum + t.distanceKm);
    final kmProgress = (totalDist / 1000.0).clamp(0.0, 1.0);
    final kmUnlocked = totalDist >= 1000.0;
    DateTime? kmUnlockDate;
    if (kmUnlocked) {
      double currentKm = 0.0;
      final sortedTrips = List<Trip>.from(trips)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (final t in sortedTrips) {
        currentKm += t.distanceKm;
        if (currentKm >= 1000.0) {
          kmUnlockDate = t.timestamp;
          break;
        }
      }
    }

    // 2. Efficiency Master (Best mileage > 45 km/L)
    final validMileages = fuelEntries.where((e) => e.calculatedMileage > 0).map((e) => e.calculatedMileage).toList();
    final bestMileage = validMileages.isNotEmpty ? validMileages.reduce((a, b) => a > b ? a : b) : 0.0;
    final mileageProgress = (bestMileage / 45.0).clamp(0.0, 1.0);
    final mileageUnlocked = bestMileage >= 45.0;
    DateTime? mileageUnlockDate;
    if (mileageUnlocked) {
      final sortedEntries = List<FuelEntry>.from(fuelEntries)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (final e in sortedEntries) {
        if (e.calculatedMileage >= 45.0) {
          mileageUnlockDate = e.timestamp;
          break;
        }
      }
    }

    // 3. Eco Rider (Lowest monthly spend < ₹1,000)
    final monthlySpends = <String, double>{};
    for (final e in fuelEntries) {
      final key = "${e.timestamp.year}-${e.timestamp.month}";
      monthlySpends[key] = (monthlySpends[key] ?? 0.0) + (e.amountPaid ?? 0.0);
    }
    final spentLessThan1000 = monthlySpends.isNotEmpty && monthlySpends.values.any((s) => s > 0 && s < 1000.0);
    final ecoProgress = (monthlySpends.isNotEmpty)
        ? (1.0 - (monthlySpends.values.reduce((a, b) => a < b ? a : b) / 1000.0)).clamp(0.0, 1.0)
        : 0.0;
    final ecoUnlocked = spentLessThan1000;
    DateTime? ecoUnlockDate;
    if (ecoUnlocked) {
      final sortedEntries = List<FuelEntry>.from(fuelEntries)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final months = <String, double>{};
      for (final e in sortedEntries) {
        final key = "${e.timestamp.year}-${e.timestamp.month}";
        months[key] = (months[key] ?? 0.0) + (e.amountPaid ?? 0.0);
        if (months[key]! > 0 && months[key]! < 1000.0) {
          ecoUnlockDate = e.timestamp;
        }
      }
    }

    // 4. Consistent Rider (Rode 5+ consecutive days)
    final dates = trips.map((t) => DateTime(t.timestamp.year, t.timestamp.month, t.timestamp.day)).toSet().toList()
      ..sort();
    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? streakUnlockDate;

    if (dates.isNotEmpty) {
      currentStreak = 1;
      longestStreak = 1;
      for (int i = 1; i < dates.length; i++) {
        final diff = dates[i].difference(dates[i - 1]).inDays;
        if (diff == 1) {
          currentStreak++;
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
            if (longestStreak >= 5 && streakUnlockDate == null) {
              streakUnlockDate = dates[i];
            }
          }
        } else if (diff > 1) {
          currentStreak = 1;
        }
      }
    }
    final streakProgress = (longestStreak / 5.0).clamp(0.0, 1.0);
    final streakUnlocked = longestStreak >= 5;

    return [
      Achievement(
        id: 'km_club',
        title: 'Kilometer Club',
        description: 'Ride a total of 1,000 km',
        icon: '🏆',
        isUnlocked: kmUnlocked,
        unlockDate: kmUnlockDate,
        progress: kmProgress,
      ),
      Achievement(
        id: 'efficiency_master',
        title: 'Efficiency Master',
        description: 'Achieve a mileage of 45+ km/L',
        icon: '⚡',
        isUnlocked: mileageUnlocked,
        unlockDate: mileageUnlockDate,
        progress: mileageProgress,
      ),
      Achievement(
        id: 'eco_rider',
        title: 'Eco Rider',
        description: 'Keep monthly fuel spend under ₹1,000',
        icon: '🌱',
        isUnlocked: ecoUnlocked,
        unlockDate: ecoUnlockDate,
        progress: ecoProgress,
      ),
      Achievement(
        id: 'consistent_rider',
        title: 'Consistent Rider',
        description: 'Ride for 5 consecutive days',
        icon: '🔥',
        isUnlocked: streakUnlocked,
        unlockDate: streakUnlockDate,
        progress: streakProgress,
      ),
    ];
  }
}
