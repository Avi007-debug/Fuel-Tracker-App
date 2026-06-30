import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';

/// Trips controller — handles trip management actions.
class TripsController {
  final Ref _ref;

  TripsController(this._ref);

  Future<void> deleteTrip(String id) async {
    await _ref.read(tripServiceProvider).deleteTrip(id);
    _ref.invalidate(allTripsProvider);
    _ref.invalidate(todayTripsProvider);
    _ref.invalidate(todayDistanceProvider);
    _ref.invalidate(totalDistanceProvider);
    _ref.invalidate(tripCountProvider);
  }

  Future<void> undoLastTrip() async {
    await _ref.read(tripServiceProvider).undoLastTrip();
    _ref.invalidate(allTripsProvider);
    _ref.invalidate(todayTripsProvider);
    _ref.invalidate(todayDistanceProvider);
    _ref.invalidate(totalDistanceProvider);
    _ref.invalidate(tripCountProvider);
  }
}
