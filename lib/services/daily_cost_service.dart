import 'package:fuel_tracker_app/core/database/database_service.dart';
import 'package:fuel_tracker_app/models/daily_cost.dart';

class DailyCostService {
  final DatabaseService _db;

  DailyCostService(this._db);

  Future<List<DailyCost>> getAllDailyCosts() async {
    return _db.getAllDailyCosts();
  }

  Future<void> addDailyCost(DailyCost cost) async {
    await _db.addDailyCost(cost);
  }

  Future<void> deleteDailyCost(String id) async {
    await _db.deleteDailyCost(id);
  }

  /// Calculates the total cost for the current week (Monday-Sunday).
  Future<double> getWeeklyCost() async {
    final costs = await _db.getAllDailyCosts();
    final now = DateTime.now();
    // 1 = Monday, 7 = Sunday
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfToday = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    double total = 0;
    for (var c in costs) {
      if (c.timestamp.isAfter(startOfToday) || c.timestamp.isAtSameMomentAs(startOfToday)) {
        total += c.totalCost;
      }
    }
    return total;
  }

  /// Calculates the total cost for the current month.
  Future<double> getMonthlyCost() async {
    final costs = await _db.getAllDailyCosts();
    final now = DateTime.now();
    
    double total = 0;
    for (var c in costs) {
      if (c.timestamp.year == now.year && c.timestamp.month == now.month) {
        total += c.totalCost;
      }
    }
    return total;
  }
}
