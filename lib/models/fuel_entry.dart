/// A single fuel refill event.
class FuelEntry {
  final String id;
  final DateTime timestamp;
  final double? amountPaid;
  final double litresFilled;
  final double pricePerLitre;
  final bool isTankFull;
  final double? odometerAtFill;
  final double kmSinceLastFill;
  final double calculatedMileage;
  final double costPerKm;
  final String? receiptPhotoPath;

  const FuelEntry({
    required this.id,
    required this.timestamp,
    this.amountPaid,
    required this.litresFilled,
    required this.pricePerLitre,
    this.isTankFull = false,
    this.odometerAtFill,
    this.kmSinceLastFill = 0.0,
    this.calculatedMileage = 0.0,
    this.costPerKm = 0.0,
    this.receiptPhotoPath,
  });

  FuelEntry copyWith({
    String? id,
    DateTime? timestamp,
    double? amountPaid,
    double? litresFilled,
    double? pricePerLitre,
    bool? isTankFull,
    double? odometerAtFill,
    double? kmSinceLastFill,
    double? calculatedMileage,
    double? costPerKm,
    String? receiptPhotoPath,
  }) {
    return FuelEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      amountPaid: amountPaid ?? this.amountPaid,
      litresFilled: litresFilled ?? this.litresFilled,
      pricePerLitre: pricePerLitre ?? this.pricePerLitre,
      isTankFull: isTankFull ?? this.isTankFull,
      odometerAtFill: odometerAtFill ?? this.odometerAtFill,
      kmSinceLastFill: kmSinceLastFill ?? this.kmSinceLastFill,
      calculatedMileage: calculatedMileage ?? this.calculatedMileage,
      costPerKm: costPerKm ?? this.costPerKm,
      receiptPhotoPath: receiptPhotoPath ?? this.receiptPhotoPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'amountPaid': amountPaid,
        'litresFilled': litresFilled,
        'pricePerLitre': pricePerLitre,
        'isTankFull': isTankFull,
        'odometerAtFill': odometerAtFill,
        'kmSinceLastFill': kmSinceLastFill,
        'calculatedMileage': calculatedMileage,
        'costPerKm': costPerKm,
        'receiptPhotoPath': receiptPhotoPath,
      };

  factory FuelEntry.fromJson(Map<String, dynamic> json) {
    return FuelEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      litresFilled: (json['litresFilled'] as num).toDouble(),
      pricePerLitre: (json['pricePerLitre'] as num).toDouble(),
      isTankFull: json['isTankFull'] as bool? ?? false,
      odometerAtFill: (json['odometerAtFill'] as num?)?.toDouble(),
      kmSinceLastFill: (json['kmSinceLastFill'] as num?)?.toDouble() ?? 0.0,
      calculatedMileage:
          (json['calculatedMileage'] as num?)?.toDouble() ?? 0.0,
      costPerKm: (json['costPerKm'] as num?)?.toDouble() ?? 0.0,
      receiptPhotoPath: json['receiptPhotoPath'] as String?,
    );
  }
}
