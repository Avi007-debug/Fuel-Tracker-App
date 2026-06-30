/// Service types and their default intervals from the plan.
enum ServiceType {
  engineOil('Engine Oil', 3000.0),
  generalService('General Service', 6000.0),
  airFilter('Air Filter', 6000.0),
  brakeInspection('Brake Inspection', 6000.0),
  tyrePressure('Tyre Pressure', 0.0); // Monthly, not km-based

  const ServiceType(this.label, this.defaultIntervalKm);

  final String label;

  /// Default interval in km. 0 means time-based (monthly).
  final double defaultIntervalKm;

  String get key => name;

  static ServiceType fromKey(String key) {
    return ServiceType.values.firstWhere(
      (e) => e.name == key,
      orElse: () => ServiceType.generalService,
    );
  }

  /// Notification lead distance (km before due).
  double get notificationLeadKm {
    switch (this) {
      case ServiceType.engineOil:
        return 200.0;
      case ServiceType.generalService:
      case ServiceType.airFilter:
      case ServiceType.brakeInspection:
        return 300.0;
      case ServiceType.tyrePressure:
        return 0.0; // Time-based
    }
  }
}

/// A completed service event.
class ServiceRecord {
  final String id;
  final ServiceType serviceType;
  final DateTime completedAt;
  final double odometerKm;
  final String? notes;
  final double? cost;

  const ServiceRecord({
    required this.id,
    required this.serviceType,
    required this.completedAt,
    required this.odometerKm,
    this.notes,
    this.cost,
  });

  ServiceRecord copyWith({
    String? id,
    ServiceType? serviceType,
    DateTime? completedAt,
    double? odometerKm,
    String? notes,
    double? cost,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      completedAt: completedAt ?? this.completedAt,
      odometerKm: odometerKm ?? this.odometerKm,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceType': serviceType.key,
        'completedAt': completedAt.toIso8601String(),
        'odometerKm': odometerKm,
        'notes': notes,
        'cost': cost,
      };

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    return ServiceRecord(
      id: json['id'] as String,
      serviceType: ServiceType.fromKey(json['serviceType'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      odometerKm: (json['odometerKm'] as num).toDouble(),
      notes: json['notes'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
    );
  }
}
