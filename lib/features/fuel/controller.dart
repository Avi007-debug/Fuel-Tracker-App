import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';

/// Fuel screen controller — handles fuel entry actions.
class FuelController {
  final Ref _ref;

  FuelController(this._ref);

  Future<void> addFuelByAmount({
    required double amountPaid,
    required double pricePerLitre,
    bool isTankFull = false,
    String? receiptPhotoPath,
  }) async {
    await _ref.read(fuelServiceProvider).addFuelByAmount(
          amountPaid: amountPaid,
          pricePerLitre: pricePerLitre,
          isTankFull: isTankFull,
          receiptPhotoPath: receiptPhotoPath,
        );
    _refreshFuel();
  }

  Future<void> addFuelByLitres({
    required double litresFilled,
    required double pricePerLitre,
    bool isTankFull = false,
    String? receiptPhotoPath,
  }) async {
    await _ref.read(fuelServiceProvider).addFuelByLitres(
          litresFilled: litresFilled,
          pricePerLitre: pricePerLitre,
          isTankFull: isTankFull,
          receiptPhotoPath: receiptPhotoPath,
        );
    _refreshFuel();
  }

  void _refreshFuel() {
    _ref.invalidate(allFuelEntriesProvider);
    _ref.invalidate(fuelRemainingProvider);
    _ref.invalidate(estimatedRangeProvider);
    _ref.invalidate(monthSpendProvider);
    _ref.invalidate(averageMileageProvider);
  }
}
