import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/utils/date_helpers.dart';

/// Monthly expense forecasting engine.
///
/// Algorithm: running daily spend rate × days remaining in month.
class ExpenseForecaster {
  ExpenseForecaster._();

  /// Projected total spend for the current month.
  static double forecastMonthlyExpense(List<FuelEntry> entries) {
    final start = DateHelpers.startOfMonth;
    final monthEntries =
        entries.where((e) => e.timestamp.isAfter(start)).toList();

    final totalSpent = monthEntries.fold(
        0.0, (sum, e) => sum + (e.amountPaid ?? 0));

    final daysPassed = DateTime.now().day;
    if (daysPassed == 0) return 0.0;

    final dailyRate = totalSpent / daysPassed;
    final daysInMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;

    return dailyRate * daysInMonth;
  }

  /// Daily average spend (₹/day).
  static double dailySpendRate(List<FuelEntry> entries) {
    final start = DateHelpers.startOfMonth;
    final monthEntries =
        entries.where((e) => e.timestamp.isAfter(start)).toList();
    final totalSpent = monthEntries.fold(
        0.0, (sum, e) => sum + (e.amountPaid ?? 0));
    final daysPassed = DateTime.now().day;
    if (daysPassed == 0) return 0.0;
    return totalSpent / daysPassed;
  }

  /// Average cost per km over the last N entries.
  static double averageCostPerKm(List<FuelEntry> entries, {int n = 5}) {
    final valid =
        entries.take(n).where((e) => e.costPerKm > 0).toList();
    if (valid.isEmpty) return 0.0;
    return valid.fold(0.0, (s, e) => s + e.costPerKm) / valid.length;
  }
}
