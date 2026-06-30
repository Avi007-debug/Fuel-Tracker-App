import 'package:uuid/uuid.dart';

import 'package:fuel_tracker_app/core/database/database_service.dart';
import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/services/trip_service.dart';

/// Business logic for fuel entry, mileage calculation, and fuel estimation.
class FuelService {
  final DatabaseService _db;
  final TripService _tripService;
  static const _uuid = Uuid();

  FuelService(this._db, this._tripService);

  /// Add a fuel entry by ₹ amount (Mode A).
  /// Litres = amountPaid / pricePerLitre.
  Future<FuelEntry> addFuelByAmount({
    required double amountPaid,
    required double pricePerLitre,
    bool isTankFull = false,
    String? receiptPhotoPath,
  }) async {
    final litres = amountPaid / pricePerLitre;
    return _addFuelEntry(
      amountPaid: amountPaid,
      litresFilled: litres,
      pricePerLitre: pricePerLitre,
      isTankFull: isTankFull,
      receiptPhotoPath: receiptPhotoPath,
    );
  }

  /// Add a fuel entry by litres (Mode B).
  Future<FuelEntry> addFuelByLitres({
    required double litresFilled,
    required double pricePerLitre,
    bool isTankFull = false,
    String? receiptPhotoPath,
  }) async {
    return _addFuelEntry(
      amountPaid: litresFilled * pricePerLitre,
      litresFilled: litresFilled,
      pricePerLitre: pricePerLitre,
      isTankFull: isTankFull,
      receiptPhotoPath: receiptPhotoPath,
    );
  }

  Future<FuelEntry> _addFuelEntry({
    required double amountPaid,
    required double litresFilled,
    required double pricePerLitre,
    required bool isTankFull,
    String? receiptPhotoPath,
  }) async {
    final allEntries = await _db.getAllFuelEntries();

    // Distance since last fill.
    double kmSinceLastFill = 0.0;
    if (allEntries.isNotEmpty) {
      kmSinceLastFill = await _tripService
          .getDistanceSinceLastFuel(allEntries.first.timestamp);
    }

    // Calculated mileage: km / litres.
    final mileage =
        litresFilled > 0 ? kmSinceLastFill / litresFilled : 0.0;

    // Cost per km.
    final costKm =
        kmSinceLastFill > 0 ? amountPaid / kmSinceLastFill : 0.0;

    final entry = FuelEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      amountPaid: amountPaid,
      litresFilled: litresFilled,
      pricePerLitre: pricePerLitre,
      isTankFull: isTankFull,
      kmSinceLastFill: kmSinceLastFill,
      calculatedMileage: mileage,
      costPerKm: costKm,
      receiptPhotoPath: receiptPhotoPath,
    );

    await _db.addFuelEntry(entry);
    return entry;
  }

  /// Get all fuel entries, most recent first.
  Future<List<FuelEntry>> getAllEntries() => _db.getAllFuelEntries();

  /// Rolling average mileage (last N fills).
  Future<double> getRollingAverageMileage({int window = 5}) async {
    final entries = await _db.getAllFuelEntries();
    if (entries.isEmpty) return 0.0;
    final recent = entries.take(window).toList();
    final validEntries =
        recent.where((e) => e.calculatedMileage > 0).toList();
    if (validEntries.isEmpty) return 0.0;
    return validEntries.fold(0.0, (sum, e) => sum + e.calculatedMileage) /
        validEntries.length;
  }

  /// Estimated fuel remaining (litres).
  /// Formula: litres from last fill − (distance since × 1/avg_mileage)
  Future<double> getEstimatedFuelRemaining() async {
    final entries = await _db.getAllFuelEntries();
    if (entries.isEmpty) return 0.0;

    final lastEntry = entries.first;
    final avgMileage = await getRollingAverageMileage();
    if (avgMileage <= 0) return lastEntry.litresFilled;

    final kmSince =
        await _tripService.getDistanceSinceLastFuel(lastEntry.timestamp);
    final fuelUsed = kmSince / avgMileage;
    final remaining = lastEntry.litresFilled - fuelUsed;
    return remaining.clamp(0.0, double.infinity);
  }

  /// Estimated range remaining (km).
  Future<double> getEstimatedRange() async {
    final fuel = await getEstimatedFuelRemaining();
    final mileage = await getRollingAverageMileage();
    return fuel * mileage;
  }

  /// Total fuel spend this month (₹).
  Future<double> getMonthSpend() async {
    final entries = await _db.getAllFuelEntries();
    final start = DateTime(DateTime.now().year, DateTime.now().month);
    return entries
        .where((e) => e.timestamp.isAfter(start))
        .fold<double>(0.0, (sum, e) => sum + (e.amountPaid ?? 0));
  }

  /// Average cost per km (configurable window).
  Future<double> getAverageCostPerKm({int lastNFills = 5}) async {
    final entries = await _db.getAllFuelEntries();
    final recent = entries.take(lastNFills).toList();
    final valid = recent.where((e) => e.costPerKm > 0).toList();
    if (valid.isEmpty) return 0.0;
    return valid.fold(0.0, (s, e) => s + e.costPerKm) / valid.length;
  }

  /// Last petrol price (₹/L).
  Future<double> getLastPetrolPrice() async {
    final entries = await _db.getAllFuelEntries();
    if (entries.isEmpty) return 0.0;
    return entries.first.pricePerLitre;
  }
}
