import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';

/// Settings controller — handles profile edits, backup/restore, data wipe.
class SettingsController {
  final Ref _ref;

  SettingsController(this._ref);

  /// Update a single vehicle profile field.
  Future<void> updateProfileField({
    String? name,
    String? model,
    double? tankCapacityL,
    double? reserveL,
  }) async {
    final vehicleService = _ref.read(vehicleServiceProvider);
    final current = await vehicleService.getProfile();
    if (current != null) {
      final updated = current.copyWith(
        name: name,
        model: model,
        tankCapacityL: tankCapacityL,
        reserveL: reserveL,
      );
      await vehicleService.updateProfile(updated);
      _ref.invalidate(vehicleProfileProvider);
    }
  }

  /// Update a settings field (e.g., custom route distances or reminders).
  Future<void> updateSetting(String key, dynamic value) async {
    final db = _ref.read(databaseServiceProvider);
    final current = (await db.getSettings()) ?? {};
    current[key] = value;
    await db.saveSettings(current);
    _ref.invalidate(appSettingsProvider);
  }

  /// Backup database data to JSON and trigger share.
  Future<void> backupData() async {
    final backup = _ref.read(backupServiceProvider);
    await backup.exportBackup();
  }

  /// Restore database from JSON string.
  Future<void> restoreData(String jsonStr) async {
    final backup = _ref.read(backupServiceProvider);
    await backup.restoreBackup(jsonStr);
    
    // Invalidate all provider states so UI reloads fresh data
    _ref.invalidate(vehicleProfileProvider);
    _ref.invalidate(allTripsProvider);
    _ref.invalidate(allFuelEntriesProvider);
    _ref.invalidate(allServiceRecordsProvider);
    _ref.invalidate(appSettingsProvider);
    _ref.invalidate(fuelRemainingProvider);
    _ref.invalidate(estimatedRangeProvider);
    _ref.invalidate(averageMileageProvider);
    _ref.invalidate(monthSpendProvider);
    _ref.invalidate(achievementsProvider);
    _ref.invalidate(milestonesProvider);
  }

  /// Wipe all app database collections.
  Future<void> wipeAllData() async {
    final db = _ref.read(databaseServiceProvider);
    await db.wipeAll();
    
    // Invalidate everything to clear screen state
    _ref.invalidate(vehicleProfileProvider);
    _ref.invalidate(allTripsProvider);
    _ref.invalidate(allFuelEntriesProvider);
    _ref.invalidate(allServiceRecordsProvider);
    _ref.invalidate(appSettingsProvider);
    _ref.invalidate(fuelRemainingProvider);
    _ref.invalidate(estimatedRangeProvider);
    _ref.invalidate(averageMileageProvider);
    _ref.invalidate(monthSpendProvider);
    _ref.invalidate(achievementsProvider);
    _ref.invalidate(milestonesProvider);
  }

  /// Delete the offline LLM model file to free up cache space.
  Future<void> deleteModel() async {
    await _ref.read(aiChatProvider.notifier).deleteModel();
  }
}
