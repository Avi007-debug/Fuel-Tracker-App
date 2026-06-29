/// Application-wide constants derived from the product plan.
///
/// Route distances, notification schedules, thresholds, and default
/// configuration values are centralised here.
class AppConstants {
  AppConstants._();

  // ─── App Info ───────────────────────────────────────────────────────
  static const String appName = 'Activa Tracker';
  static const String appTagline = 'Smart Personal Vehicle Companion';
  static const String riderName = 'Avishkar';

  // ─── Route Distances (km) ──────────────────────────────────────────
  /// Home → Madavara Metro
  static const double collegeGoingKm = 7.2;

  /// Madavara Metro → BP Pump → Home
  static const double collegeReturnKm = 8.4;

  /// Nearby Town — one way
  static const double nearbyTownKm = 7.4;

  /// Short Ride — one way
  static const double shortRideKm = 2.0;

  // ─── Vehicle Defaults ──────────────────────────────────────────────
  static const double defaultTankCapacityL = 5.3;
  static const double defaultReserveL = 0.8;
  static const double defaultServiceIntervalKm = 3000.0;
  static const String defaultVehicleName = 'Activa';
  static const String defaultVehicleModel = 'Honda Activa 6G';

  // ─── Notification Schedule ─────────────────────────────────────────
  /// Morning trip reminder — 7:30 AM on weekdays
  static const int morningReminderHour = 7;
  static const int morningReminderMinute = 30;

  /// Evening return reminder — 6:00 PM
  static const int eveningReminderHour = 18;
  static const int eveningReminderMinute = 0;

  /// Evening escalation interval (minutes) — repeats until 10 PM
  static const int eveningEscalationIntervalMin = 10;
  static const int eveningEscalationStopHour = 22;

  // ─── Analytics Thresholds ──────────────────────────────────────────
  /// Low fuel alert when estimated range < this value (km).
  static const double lowFuelAlertRangeKm = 40.0;

  /// Mileage drop threshold — flag if < 90% of rolling average.
  static const double mileageDropThreshold = 0.90;

  /// Rolling average window for mileage smoothing.
  static const int mileageRollingWindow = 5;

  /// Trip anomaly threshold — flag if > 2× day-of-week average.
  static const double tripAnomalyMultiplier = 2.0;

  /// Riding pattern history window (weeks).
  static const int patternHistoryWeeks = 8;

  // ─── Health Score Weights (must sum to 1.0) ────────────────────────
  static const double healthWeightMileageStability = 0.30;
  static const double healthWeightServiceCompliance = 0.40;
  static const double healthWeightFuelEfficiency = 0.30;

  // ─── Service Intervals (km) ────────────────────────────────────────
  static const double engineOilIntervalKm = 3000.0;
  static const double generalServiceIntervalKm = 6000.0;
  static const double airFilterIntervalKm = 6000.0;
  static const double brakeInspectionIntervalKm = 6000.0;

  // ─── Navigation ────────────────────────────────────────────────────
  /// BP Makali petrol pump coordinates for Google Maps navigation.
  static const String bpMakaliQuery = 'BP+Makali+Petrol+Pump';
  static const String bpMakaliMapsUrl =
      'https://www.google.com/maps/search/?api=1&query=$bpMakaliQuery';

  // ─── LLM (v2.0) ───────────────────────────────────────────────────
  static const String llmModelName = 'Qwen2.5 0.5B Instruct';
  static const int llmContextDays = 30;
  static const int llmLastRefills = 5;
}
