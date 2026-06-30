import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fuel_tracker_app/core/database/database_service.dart';

/// Service to handle database backups (exporting and importing database state).
class BackupService {
  final DatabaseService _db;

  BackupService(this._db);

  /// Export the entire database to a JSON file and trigger share sheet.
  Future<void> exportBackup() async {
    final data = await _db.exportAll();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/activa_tracker_backup.json');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Activa Tracker Data Backup',
    );
  }

  /// Restore the database from a backup JSON string.
  Future<void> restoreBackup(String jsonStr) async {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup: Root is not a JSON object');
    }
    await _db.restoreAll(decoded);
  }
}
