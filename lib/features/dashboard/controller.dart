import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/models/route_type.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';

/// Dashboard controller — orchestrates greeting logic, insight generation,
/// and quick-action handling for the AI Garage screen.
class DashboardController {
  final Ref _ref;

  DashboardController(this._ref);

  /// Log a fixed-route trip from a quick action button.
  Future<void> logQuickTrip(RouteType routeType) async {
    final tripService = _ref.read(tripServiceProvider);
    await tripService.logTrip(routeType);
    _refreshDashboard();
  }

  /// Log a custom ride.
  Future<void> logCustomRide(double km, {String? notes}) async {
    final tripService = _ref.read(tripServiceProvider);
    await tripService.logCustomTrip(km, notes: notes);
    _refreshDashboard();
  }

  /// Undo the last trip.
  Future<void> undoLastTrip() async {
    final tripService = _ref.read(tripServiceProvider);
    await tripService.undoLastTrip();
    _refreshDashboard();
  }

  /// Refresh all dashboard-relevant providers.
  void _refreshDashboard() {
    _ref.invalidate(todayTripsProvider);
    _ref.invalidate(todayDistanceProvider);
    _ref.invalidate(fuelRemainingProvider);
    _ref.invalidate(estimatedRangeProvider);
    _ref.invalidate(monthSpendProvider);
    _ref.invalidate(allTripsProvider);
  }
}
