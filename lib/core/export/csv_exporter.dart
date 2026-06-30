import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/fuel_entry.dart';

/// CSV exporter — raw data export for trips and fuel entries.
///
/// Uses the `csv` package for tabular data export.
class CsvExporter {
  /// Export trips to CSV and trigger share sheet.
  static Future<void> exportTrips(List<Trip> trips) async {
    final headers = ['Timestamp', 'Route Type', 'Distance (km)'];
    final rows = trips.map((t) => [
      t.timestamp.toIso8601String(),
      t.routeType.label,
      t.distanceKm,
    ]).toList();

    final csvData = const ListToCsvConverter().convert([headers, ...rows]);
    
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/activa_trips_export.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported Commute Trips from Activa Tracker',
    );
  }

  /// Export fuel entries to CSV and trigger share sheet.
  static Future<void> exportFuel(List<FuelEntry> entries) async {
    final headers = [
      'Timestamp',
      'Odometer (km)',
      'Litres Filled (L)',
      'Price Per Litre (₹/L)',
      'Amount Paid (₹)',
      'Distance Since Last Fill (km)',
      'Calculated Mileage (km/L)',
      'Cost Per Km (₹/km)'
    ];
    final rows = entries.map((e) => [
      e.timestamp.toIso8601String(),
      e.odometerKm,
      e.litresFilled,
      e.pricePerLitre,
      e.amountPaid ?? 0.0,
      e.kmSinceLastFill,
      e.calculatedMileage,
      e.costPerKm,
    ]).toList();

    final csvData = const ListToCsvConverter().convert([headers, ...rows]);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/activa_fuel_export.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported Fuel Refills from Activa Tracker',
    );
  }
}
