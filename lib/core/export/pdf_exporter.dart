import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/models/vehicle_profile.dart';

/// PDF exporter — monthly styled report with stats and history.
///
/// Uses the `pdf` Dart library for pure-Dart PDF generation.
class PdfExporter {
  /// Generate a PDF report of commute stats and trigger share sheet.
  static Future<void> exportMonthlyReport({
    required VehicleProfile? profile,
    required List<Trip> trips,
    required List<FuelEntry> entries,
    required double totalDistance,
    required double totalSpent,
    required double averageMileage,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Activa Smart Tracker — Monthly Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text(monthLabel, style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Vehicle Profile Summary
            pw.Text('Vehicle Profile Info', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headers: ['Vehicle', 'Model', 'Tank Capacity', 'Reserve Level'],
              data: [
                [
                  profile?.name ?? 'Activa',
                  profile?.model ?? 'Honda Activa 6G',
                  '${profile?.tankCapacityL ?? 5.3} L',
                  '${profile?.reserveL ?? 0.8} L'
                ]
              ],
            ),
            pw.SizedBox(height: 15),

            // Key Metrics Summary Grid
            pw.Text('Summary Performance Metrics', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headers: ['Total Distance Ridden', 'Total Fuel Spend', 'Average Mileage', 'Log Count'],
              data: [
                [
                  '${totalDistance.toStringAsFixed(1)} km',
                  '₹${totalSpent.toStringAsFixed(0)}',
                  '${averageMileage.toStringAsFixed(1)} km/L',
                  '${trips.length} trips, ${entries.length} refills'
                ]
              ],
            ),
            pw.SizedBox(height: 15),

            // Fuel Refills History
            pw.Text('Recent Refill Logs (Max 15)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headers: ['Date', 'Odometer', 'Litres', 'Price/Litre', 'Amount Paid', 'Mileage'],
              data: entries.take(15).map((e) => [
                DateFormat('dd/MM/yyyy').format(e.timestamp),
                '${(e.odometerAtFill ?? 0).toStringAsFixed(0)} km',
                '${e.litresFilled.toStringAsFixed(2)} L',
                '₹${e.pricePerLitre.toStringAsFixed(2)}',
                '₹${(e.amountPaid ?? 0).toStringAsFixed(0)}',
                e.calculatedMileage > 0 ? '${e.calculatedMileage.toStringAsFixed(1)} km/L' : 'N/A'
              ]).toList(),
            ),
            pw.SizedBox(height: 15),

            // Commute Trips Summary
            pw.Text('Recent Commute Trips (Max 15)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headers: ['Date', 'Commute Route', 'Distance'],
              data: trips.take(15).map((t) => [
                DateFormat('dd/MM/yyyy HH:mm').format(t.timestamp),
                t.routeType.label,
                '${t.distanceKm} km'
              ]).toList(),
            ),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/activa_monthly_report.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Monthly Fuel and Ride Report - $monthLabel',
    );
  }
}
