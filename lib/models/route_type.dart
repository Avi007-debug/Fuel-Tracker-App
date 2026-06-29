/// All route types supported by the app.
///
/// Distances are pre-loaded from the rider's configuration:
/// - College Going: Home → Madavara Metro = 7.2 km
/// - College Return: Madavara Metro → BP Pump → Home = 8.4 km
/// - Nearby Town: 7.4 km one way
/// - Short Ride: 2.0 km one way
enum RouteType {
  collegeGo('College — Going', 7.2),
  collegeReturn('College — Return', 8.4),
  townGo('Nearby Town — Going', 7.4),
  townReturn('Nearby Town — Return', 7.4),
  shortGo('Short Ride — Going', 2.0),
  shortReturn('Short Ride — Return', 2.0),
  custom('Custom Ride', 0.0);

  const RouteType(this.label, this.defaultDistanceKm);

  /// Human-readable label for UI display.
  final String label;

  /// Pre-configured distance in km. For [custom], the user enters manually.
  final double defaultDistanceKm;

  /// Serialization key for JSON persistence.
  String get key => name;

  /// Deserialize from a stored string.
  static RouteType fromKey(String key) {
    return RouteType.values.firstWhere(
      (e) => e.name == key,
      orElse: () => RouteType.custom,
    );
  }

  /// Whether this is a fixed (non-custom) route.
  bool get isFixed => this != RouteType.custom;

  /// Whether this is a "going" direction.
  bool get isGoing =>
      this == collegeGo || this == townGo || this == shortGo;

  /// Whether this is a "return" direction.
  bool get isReturn =>
      this == collegeReturn || this == townReturn || this == shortReturn;

  /// Icon data for quick-action buttons.
  String get emoji {
    switch (this) {
      case RouteType.collegeGo:
        return '🟢';
      case RouteType.collegeReturn:
        return '🔵';
      case RouteType.townGo:
      case RouteType.townReturn:
        return '🟣';
      case RouteType.shortGo:
      case RouteType.shortReturn:
        return '⚪';
      case RouteType.custom:
        return '➕';
    }
  }
}
