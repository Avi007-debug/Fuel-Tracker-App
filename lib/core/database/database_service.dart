import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/models/vehicle_profile.dart';
import 'package:fuel_tracker_app/models/service_record.dart';

/// JSON-file-backed persistence layer.
///
/// Each collection is stored as a separate JSON file under the app's
/// documents directory. This can be swapped for Isar/Hive later without
/// touching the rest of the codebase — all access goes through this service.
class DatabaseService {
  static DatabaseService? _instance;
  late final Directory _dataDir;

  DatabaseService._();

  /// Singleton accessor. Call [init] before using.
  static DatabaseService get instance {
    if (_instance == null) {
      throw StateError('DatabaseService not initialized. Call init() first.');
    }
    return _instance!;
  }

  /// Initialise the database directory.
  static Future<DatabaseService> init() async {
    if (_instance != null) return _instance!;

    final service = DatabaseService._();
    final appDir = await getApplicationDocumentsDirectory();
    service._dataDir = Directory('${appDir.path}/activa_tracker_data');
    if (!service._dataDir.existsSync()) {
      service._dataDir.createSync(recursive: true);
    }
    _instance = service;
    return service;
  }

  // ─── File helpers ──────────────────────────────────────────────────

  File _file(String name) => File('${_dataDir.path}/$name.json');

  Future<List<Map<String, dynamic>>> _readList(String name) async {
    final file = _file(name);
    if (!file.existsSync()) return [];
    final raw = await file.readAsString();
    if (raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    return (decoded as List).cast<Map<String, dynamic>>();
  }

  Future<void> _writeList(String name, List<Map<String, dynamic>> data) async {
    final file = _file(name);
    await file.writeAsString(jsonEncode(data));
  }

  Future<Map<String, dynamic>?> _readSingle(String name) async {
    final file = _file(name);
    if (!file.existsSync()) return null;
    final raw = await file.readAsString();
    if (raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _writeSingle(String name, Map<String, dynamic> data) async {
    final file = _file(name);
    await file.writeAsString(jsonEncode(data));
  }

  // ─── Vehicle Profile ──────────────────────────────────────────────

  Future<VehicleProfile?> getVehicleProfile() async {
    final json = await _readSingle('vehicle_profile');
    if (json == null) return null;
    return VehicleProfile.fromJson(json);
  }

  Future<void> saveVehicleProfile(VehicleProfile profile) async {
    await _writeSingle('vehicle_profile', profile.toJson());
  }

  // ─── Trips ─────────────────────────────────────────────────────────

  Future<List<Trip>> getAllTrips() async {
    final list = await _readList('trips');
    return list.map((e) => Trip.fromJson(e)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addTrip(Trip trip) async {
    final list = await _readList('trips');
    list.add(trip.toJson());
    await _writeList('trips', list);
  }

  Future<void> updateTrip(Trip trip) async {
    final list = await _readList('trips');
    final idx = list.indexWhere((e) => e['id'] == trip.id);
    if (idx != -1) {
      list[idx] = trip.toJson();
      await _writeList('trips', list);
    }
  }

  Future<void> deleteTrip(String id) async {
    final list = await _readList('trips');
    list.removeWhere((e) => e['id'] == id);
    await _writeList('trips', list);
  }

  // ─── Fuel Entries ──────────────────────────────────────────────────

  Future<List<FuelEntry>> getAllFuelEntries() async {
    final list = await _readList('fuel_entries');
    return list.map((e) => FuelEntry.fromJson(e)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addFuelEntry(FuelEntry entry) async {
    final list = await _readList('fuel_entries');
    list.add(entry.toJson());
    await _writeList('fuel_entries', list);
  }

  Future<void> updateFuelEntry(FuelEntry entry) async {
    final list = await _readList('fuel_entries');
    final idx = list.indexWhere((e) => e['id'] == entry.id);
    if (idx != -1) {
      list[idx] = entry.toJson();
      await _writeList('fuel_entries', list);
    }
  }

  Future<void> deleteFuelEntry(String id) async {
    final list = await _readList('fuel_entries');
    list.removeWhere((e) => e['id'] == id);
    await _writeList('fuel_entries', list);
  }

  // ─── Service Records ──────────────────────────────────────────────

  Future<List<ServiceRecord>> getAllServiceRecords() async {
    final list = await _readList('service_records');
    return list.map((e) => ServiceRecord.fromJson(e)).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  Future<void> addServiceRecord(ServiceRecord record) async {
    final list = await _readList('service_records');
    list.add(record.toJson());
    await _writeList('service_records', list);
  }

  // ─── Settings ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getSettings() async {
    return _readSingle('settings');
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _writeSingle('settings', settings);
  }

  // ─── Backup & Restore ─────────────────────────────────────────────

  /// Export everything as a single JSON map.
  Future<Map<String, dynamic>> exportAll() async {
    return {
      'vehicle_profile': (await getVehicleProfile())?.toJson(),
      'trips': (await getAllTrips()).map((e) => e.toJson()).toList(),
      'fuel_entries':
          (await getAllFuelEntries()).map((e) => e.toJson()).toList(),
      'service_records':
          (await getAllServiceRecords()).map((e) => e.toJson()).toList(),
      'settings': await getSettings(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Wipe all data.
  Future<void> wipeAll() async {
    for (final name in ['vehicle_profile', 'trips', 'fuel_entries', 'service_records', 'settings']) {
      final file = _file(name);
      if (file.existsSync()) await file.delete();
    }
  }

  /// Restore database from an exported map.
  Future<void> restoreAll(Map<String, dynamic> data) async {
    // Save vehicle profile
    if (data['vehicle_profile'] != null) {
      await _writeSingle('vehicle_profile', data['vehicle_profile']);
    } else {
      final file = _file('vehicle_profile');
      if (file.existsSync()) await file.delete();
    }

    // Save settings
    if (data['settings'] != null) {
      await _writeSingle('settings', data['settings']);
    } else {
      final file = _file('settings');
      if (file.existsSync()) await file.delete();
    }

    // Save trips
    if (data['trips'] != null) {
      final list = (data['trips'] as List).cast<Map<String, dynamic>>();
      await _writeList('trips', list);
    } else {
      await _writeList('trips', []);
    }

    // Save fuel entries
    if (data['fuel_entries'] != null) {
      final list = (data['fuel_entries'] as List).cast<Map<String, dynamic>>();
      await _writeList('fuel_entries', list);
    } else {
      await _writeList('fuel_entries', []);
    }

    // Save service records
    if (data['service_records'] != null) {
      final list = (data['service_records'] as List).cast<Map<String, dynamic>>();
      await _writeList('service_records', list);
    } else {
      await _writeList('service_records', []);
    }
  }
}
