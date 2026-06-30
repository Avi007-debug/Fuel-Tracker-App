import 'package:uuid/uuid.dart';

import 'package:fuel_tracker_app/core/database/database_service.dart';
import 'package:fuel_tracker_app/models/vehicle_profile.dart';
import 'package:fuel_tracker_app/core/constants/app_constants.dart';

/// Business logic for vehicle profile management.
class VehicleService {
  final DatabaseService _db;
  static const _uuid = Uuid();

  VehicleService(this._db);

  /// Get the saved vehicle profile, or null if onboarding not completed.
  Future<VehicleProfile?> getProfile() => _db.getVehicleProfile();

  /// Whether onboarding has been completed (vehicle profile exists).
  Future<bool> isOnboarded() async {
    final profile = await _db.getVehicleProfile();
    return profile != null;
  }

  /// Save the initial vehicle profile (during onboarding).
  Future<VehicleProfile> createProfile({
    String? name,
    String? model,
    String? registrationNo,
    double? tankCapacityL,
    double? reserveL,
    double? initialOdometer,
    double? serviceIntervalKm,
  }) async {
    final now = DateTime.now();
    final profile = VehicleProfile(
      id: _uuid.v4(),
      name: name ?? AppConstants.defaultVehicleName,
      model: model ?? AppConstants.defaultVehicleModel,
      registrationNo: registrationNo,
      tankCapacityL: tankCapacityL ?? AppConstants.defaultTankCapacityL,
      reserveL: reserveL ?? AppConstants.defaultReserveL,
      initialOdometer: initialOdometer,
      serviceIntervalKm:
          serviceIntervalKm ?? AppConstants.defaultServiceIntervalKm,
      createdAt: now,
      updatedAt: now,
    );
    await _db.saveVehicleProfile(profile);
    return profile;
  }

  /// Save a vehicle profile directly (for onboarding).
  Future<void> saveProfile(VehicleProfile profile) async {
    await _db.saveVehicleProfile(profile);
  }

  /// Update the vehicle profile.
  Future<VehicleProfile> updateProfile(VehicleProfile profile) async {
    final updated = profile.copyWith(updatedAt: DateTime.now());
    await _db.saveVehicleProfile(updated);
    return updated;
  }
}
