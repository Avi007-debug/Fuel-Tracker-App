import 'package:fuel_tracker_app/models/route_type.dart';

/// A single logged trip/ride.
class Trip {
  final String id;
  final DateTime timestamp;
  final RouteType routeType;
  final double distanceKm;
  final String? notes;
  final bool isAnomaly;

  const Trip({
    required this.id,
    required this.timestamp,
    required this.routeType,
    required this.distanceKm,
    this.notes,
    this.isAnomaly = false,
  });

  Trip copyWith({
    String? id,
    DateTime? timestamp,
    RouteType? routeType,
    double? distanceKm,
    String? notes,
    bool? isAnomaly,
  }) {
    return Trip(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      routeType: routeType ?? this.routeType,
      distanceKm: distanceKm ?? this.distanceKm,
      notes: notes ?? this.notes,
      isAnomaly: isAnomaly ?? this.isAnomaly,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'routeType': routeType.key,
        'distanceKm': distanceKm,
        'notes': notes,
        'isAnomaly': isAnomaly,
      };

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      routeType: RouteType.fromKey(json['routeType'] as String),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      notes: json['notes'] as String?,
      isAnomaly: json['isAnomaly'] as bool? ?? false,
    );
  }
}
