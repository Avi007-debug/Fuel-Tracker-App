import 'package:uuid/uuid.dart';

enum CommuteType {
  metro,
  bus,
  custom,
}

extension CommuteTypeExt on CommuteType {
  String get label {
    switch (this) {
      case CommuteType.metro:
        return 'Metro';
      case CommuteType.bus:
        return 'Bus';
      case CommuteType.custom:
        return 'Custom';
    }
  }
}

/// A daily commute cost entry
class DailyCost {
  final String id;
  final DateTime timestamp;
  final CommuteType type;
  final double baseCost;
  final double parkingFee;
  final double extraCost;
  final String? extraCostNote;
  final double totalCost;

  const DailyCost({
    required this.id,
    required this.timestamp,
    required this.type,
    this.baseCost = 0.0,
    this.parkingFee = 0.0,
    this.extraCost = 0.0,
    this.extraCostNote,
    this.totalCost = 0.0,
  });

  factory DailyCost.create({
    required DateTime timestamp,
    required CommuteType type,
    double baseCost = 0.0,
    double parkingFee = 0.0,
    double extraCost = 0.0,
    String? extraCostNote,
  }) {
    return DailyCost(
      id: const Uuid().v4(),
      timestamp: timestamp,
      type: type,
      baseCost: baseCost,
      parkingFee: parkingFee,
      extraCost: extraCost,
      extraCostNote: extraCostNote,
      totalCost: baseCost + parkingFee + extraCost,
    );
  }

  DailyCost copyWith({
    String? id,
    DateTime? timestamp,
    CommuteType? type,
    double? baseCost,
    double? parkingFee,
    double? extraCost,
    String? extraCostNote,
    double? totalCost,
  }) {
    return DailyCost(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      baseCost: baseCost ?? this.baseCost,
      parkingFee: parkingFee ?? this.parkingFee,
      extraCost: extraCost ?? this.extraCost,
      extraCostNote: extraCostNote ?? this.extraCostNote,
      totalCost: totalCost ?? this.totalCost,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'baseCost': baseCost,
        'parkingFee': parkingFee,
        'extraCost': extraCost,
        'extraCostNote': extraCostNote,
        'totalCost': totalCost,
      };

  factory DailyCost.fromJson(Map<String, dynamic> json) {
    return DailyCost(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: CommuteType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CommuteType.custom,
      ),
      baseCost: (json['baseCost'] as num?)?.toDouble() ?? 0.0,
      parkingFee: (json['parkingFee'] as num?)?.toDouble() ?? 0.0,
      extraCost: (json['extraCost'] as num?)?.toDouble() ?? 0.0,
      extraCostNote: json['extraCostNote'] as String?,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
