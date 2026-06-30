import 'package:fuel_tracker_app/models/service_record.dart';
import 'package:fuel_tracker_app/models/vehicle_profile.dart';

/// Service reminder engine — tracks km-based and time-based service intervals.
/// 
/// From the plan:
/// - Engine Oil: Every 3,000 km (200 km lead)
/// - General Service: Every 6,000 km (300 km lead)
/// - Air Filter: Every 6,000 km (300 km lead)
/// - Brake Inspection: Every 6,000 km (300 km lead)
/// - Tyre Pressure: Monthly (1st of each month)
class ServiceEngine {
  ServiceEngine._();

  /// Check which services are due soon (within lead distance).
  static List<ServiceDue> checkServicesDue({
    required List<ServiceRecord> records,
    required double currentOdometerKm,
    required VehicleProfile vehicle,
  }) {
    final due = <ServiceDue>[];

    for (final type in ServiceType.values) {
      if (type == ServiceType.tyrePressure) {
        // Time-based check (monthly)
        final lastTyreService = _getLastService(records, type);
        if (lastTyreService == null) {
          due.add(ServiceDue(type: type, kmRemaining: 0, isOverdue: true));
        } else {
          final daysSince = DateTime.now().difference(lastTyreService.completedAt).inDays;
          if (daysSince >= 30) {
            due.add(ServiceDue(type: type, kmRemaining: 0, isOverdue: true));
          }
        }
      } else {
        // Km-based check
        final result = _checkKmBasedService(
          type: type,
          records: records,
          currentOdometerKm: currentOdometerKm,
          serviceIntervalKm: vehicle.serviceIntervalKm,
        );
        
        if (result != null) {
          due.add(result);
        }
      }
    }

    return due;
  }

  /// Check a single km-based service type.
  static ServiceDue? _checkKmBasedService({
    required ServiceType type,
    required List<ServiceRecord> records,
    required double currentOdometerKm,
    required double serviceIntervalKm,
  }) {
    final lastService = _getLastService(records, type);
    final intervalKm = type.defaultIntervalKm > 0 
        ? type.defaultIntervalKm 
        : serviceIntervalKm;

    final kmSinceLast = lastService == null
        ? currentOdometerKm
        : currentOdometerKm - lastService.odometerKm;

    final kmUntilDue = intervalKm - kmSinceLast;

    // Check if within lead distance or overdue
    if (kmUntilDue <= type.notificationLeadKm || kmUntilDue <= 0) {
      return ServiceDue(
        type: type,
        kmRemaining: kmUntilDue.clamp(0, double.infinity),
        isOverdue: kmUntilDue <= 0,
      );
    }

    return null;
  }

  /// Get the most recent service record for a type.
  static ServiceRecord? _getLastService(
    List<ServiceRecord> records,
    ServiceType type,
  ) {
    final filtered = records.where((r) => r.serviceType == type).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return filtered.first;
  }

  /// Calculate next service km for a given type.
  static double nextServiceKm({
    required ServiceType type,
    required List<ServiceRecord> records,
    required double serviceIntervalKm,
  }) {
    final lastService = _getLastService(records, type);
    final intervalKm = type.defaultIntervalKm > 0 
        ? type.defaultIntervalKm 
        : serviceIntervalKm;

    if (lastService == null) {
      return intervalKm;
    }

    return lastService.odometerKm + intervalKm;
  }

  /// Get all service status summaries.
  static List<ServiceStatus> getAllServiceStatus({
    required List<ServiceRecord> records,
    required double currentOdometerKm,
    required VehicleProfile vehicle,
  }) {
    final statuses = <ServiceStatus>[];

    for (final type in ServiceType.values) {
      if (type == ServiceType.tyrePressure) {
        // Time-based
        final lastService = _getLastService(records, type);
        final daysSince = lastService == null
            ? 999
            : DateTime.now().difference(lastService.completedAt).inDays;

        statuses.add(ServiceStatus(
          type: type,
          lastServiceDate: lastService?.completedAt,
          daysSinceService: daysSince,
          isDue: daysSince >= 30,
        ));
      } else {
        // Km-based
        final lastService = _getLastService(records, type);
        final intervalKm = type.defaultIntervalKm > 0 
            ? type.defaultIntervalKm 
            : vehicle.serviceIntervalKm;

        final kmSinceLast = lastService == null
            ? currentOdometerKm
            : currentOdometerKm - lastService.odometerKm;

        final kmUntilDue = intervalKm - kmSinceLast;

        statuses.add(ServiceStatus(
          type: type,
          lastServiceKm: lastService?.odometerKm,
          kmSinceService: kmSinceLast,
          kmUntilDue: kmUntilDue,
          isDue: kmUntilDue <= type.notificationLeadKm,
        ));
      }
    }

    return statuses;
  }
}

/// A service that is due or overdue.
class ServiceDue {
  final ServiceType type;
  final double kmRemaining; // 0 if overdue
  final bool isOverdue;

  ServiceDue({
    required this.type,
    required this.kmRemaining,
    required this.isOverdue,
  });

  String get message {
    if (isOverdue) {
      return '${type.label} is overdue!';
    } else {
      return '${type.label} due in ${kmRemaining.toStringAsFixed(0)} km';
    }
  }
}

/// Full service status for a given type.
class ServiceStatus {
  final ServiceType type;
  
  // Km-based fields
  final double? lastServiceKm;
  final double? kmSinceService;
  final double? kmUntilDue;
  
  // Time-based fields
  final DateTime? lastServiceDate;
  final int? daysSinceService;
  
  final bool isDue;

  ServiceStatus({
    required this.type,
    this.lastServiceKm,
    this.kmSinceService,
    this.kmUntilDue,
    this.lastServiceDate,
    this.daysSinceService,
    required this.isDue,
  });

  String get statusText {
    if (type == ServiceType.tyrePressure) {
      if (lastServiceDate == null) {
        return 'Not yet done';
      }
      return isDue 
          ? 'Due now (${daysSinceService} days since last check)'
          : 'Done ${daysSinceService} days ago';
    } else {
      if (lastServiceKm == null) {
        return 'Not yet done';
      }
      return isDue
          ? 'Due in ${kmUntilDue!.toStringAsFixed(0)} km'
          : '${kmSinceService!.toStringAsFixed(0)} km since last service';
    }
  }
}
