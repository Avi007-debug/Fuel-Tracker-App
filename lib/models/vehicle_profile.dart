/// Vehicle profile — configured once during onboarding.
///
/// Default values match the plan for Honda Activa 6G.
class VehicleProfile {
  final String id;
  final String name;
  final String model;
  final String? registrationNo;
  final double tankCapacityL;
  final double reserveL;
  final double? initialOdometer;
  final double serviceIntervalKm;
  final double lastServiceKm;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleProfile({
    required this.id,
    this.name = 'Activa',
    this.model = 'Honda Activa 6G',
    this.registrationNo,
    this.tankCapacityL = 5.3,
    this.reserveL = 0.8,
    this.initialOdometer,
    this.serviceIntervalKm = 3000.0,
    this.lastServiceKm = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  VehicleProfile copyWith({
    String? id,
    String? name,
    String? model,
    String? registrationNo,
    double? tankCapacityL,
    double? reserveL,
    double? initialOdometer,
    double? serviceIntervalKm,
    double? lastServiceKm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      registrationNo: registrationNo ?? this.registrationNo,
      tankCapacityL: tankCapacityL ?? this.tankCapacityL,
      reserveL: reserveL ?? this.reserveL,
      initialOdometer: initialOdometer ?? this.initialOdometer,
      serviceIntervalKm: serviceIntervalKm ?? this.serviceIntervalKm,
      lastServiceKm: lastServiceKm ?? this.lastServiceKm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'model': model,
        'registrationNo': registrationNo,
        'tankCapacityL': tankCapacityL,
        'reserveL': reserveL,
        'initialOdometer': initialOdometer,
        'serviceIntervalKm': serviceIntervalKm,
        'lastServiceKm': lastServiceKm,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VehicleProfile.fromJson(Map<String, dynamic> json) {
    return VehicleProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Activa',
      model: json['model'] as String? ?? 'Honda Activa 6G',
      registrationNo: json['registrationNo'] as String?,
      tankCapacityL: (json['tankCapacityL'] as num?)?.toDouble() ?? 5.3,
      reserveL: (json['reserveL'] as num?)?.toDouble() ?? 0.8,
      initialOdometer: (json['initialOdometer'] as num?)?.toDouble(),
      serviceIntervalKm:
          (json['serviceIntervalKm'] as num?)?.toDouble() ?? 3000.0,
      lastServiceKm: (json['lastServiceKm'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Usable fuel before hitting reserve.
  double get usableFuelL => tankCapacityL - reserveL;
}
