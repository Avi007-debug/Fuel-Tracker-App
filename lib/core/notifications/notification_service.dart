import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Notification service — handles all local notifications.
/// 
/// Notifications:
/// - Morning trip reminder (7:30 AM weekdays)
/// - Evening return reminder (6:00 PM)
/// - Low fuel alert (range < 40 km)
/// - Service due alerts (5 types)
class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  NotificationService._();

  static NotificationService get instance {
    if (_instance == null) {
      throw StateError('NotificationService not initialized. Call init() first.');
    }
    return _instance!;
  }

  /// Initialize the notification service.
  static Future<NotificationService> init() async {
    if (_instance != null) return _instance!;

    final service = NotificationService._();
    
    // Initialize timezone data
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await service._notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap
        // TODO: Navigate to relevant screen
      },
    );

    // Request permissions
    await service._requestPermissions();

    _instance = service;
    return service;
  }

  Future<void> _requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // ─── Notification Channels ──────────────────────────────────────

  static const _channelIdReminders = 'trip_reminders';
  static const _channelNameReminders = 'Trip Reminders';
  static const _channelDescReminders = 'Morning and evening trip reminders';

  static const _channelIdAlerts = 'alerts';
  static const _channelNameAlerts = 'Alerts';
  static const _channelDescAlerts = 'Low fuel and service alerts';

  // ─── Morning Trip Reminder ──────────────────────────────────────

  static const _idMorningReminder = 100;

  /// Schedule morning trip reminder at 7:30 AM on weekdays.
  Future<void> scheduleMorningReminder() async {
    await _notifications.zonedSchedule(
      _idMorningReminder,
      '🏫 Going to college today?',
      'Tap to log your trip',
      _nextMorningTime(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdReminders,
          _channelNameReminders,
          channelDescription: _channelDescReminders,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Cancel morning trip reminder.
  Future<void> cancelMorningReminder() async {
    await _notifications.cancel(_idMorningReminder);
  }

  tz.TZDateTime _nextMorningTime() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7, // 7:30 AM
      30,
    );

    // If already past 7:30 today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Skip weekends (Saturday = 6, Sunday = 7)
    while (scheduled.weekday == DateTime.saturday ||
        scheduled.weekday == DateTime.sunday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  // ─── Evening Return Reminder ────────────────────────────────────

  static const _idEveningReminder = 101;

  /// Schedule evening return reminder at 6:00 PM.
  Future<void> scheduleEveningReminder() async {
    await _notifications.zonedSchedule(
      _idEveningReminder,
      '🏠 Did you return home?',
      'Tap to log your return trip',
      _nextEveningTime(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdReminders,
          _channelNameReminders,
          channelDescription: _channelDescReminders,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel evening return reminder.
  Future<void> cancelEveningReminder() async {
    await _notifications.cancel(_idEveningReminder);
  }

  static const _idEveningEscalation = 102;

  /// Immediately show evening escalation reminder.
  Future<void> showEveningEscalation() async {
    await _notifications.show(
      _idEveningEscalation,
      '🏠 Return trip pending!',
      'You logged going to college but haven\'t logged returning home yet.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdReminders,
          _channelNameReminders,
          channelDescription: _channelDescReminders,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Cancel evening escalation.
  Future<void> cancelEveningEscalation() async {
    await _notifications.cancel(_idEveningEscalation);
  }

  tz.TZDateTime _nextEveningTime() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      18, // 6:00 PM
      0,
    );

    // If already past 6:00 PM today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  // ─── Low Fuel Alert ─────────────────────────────────────────────

  static const _idLowFuelAlert = 200;

  /// Show low fuel alert (immediate).
  Future<void> showLowFuelAlert(double remainingKm) async {
    await _notifications.show(
      _idLowFuelAlert,
      '⛽ Low Fuel Alert',
      'Only ${remainingKm.toStringAsFixed(1)} km remaining. Time to refuel!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdAlerts,
          _channelNameAlerts,
          channelDescription: _channelDescAlerts,
          importance: Importance.max,
          priority: Priority.max,
          color: Color(0xFFD4641A), // AppTheme.accentOrange
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Cancel low fuel alert.
  Future<void> cancelLowFuelAlert() async {
    await _notifications.cancel(_idLowFuelAlert);
  }

  // ─── Service Alerts ─────────────────────────────────────────────

  static const _idServiceEngineOil = 300;
  static const _idServiceGeneral = 301;
  static const _idServiceAirFilter = 302;
  static const _idServiceBrake = 303;
  static const _idServiceTyre = 304;

  /// Show service due alert for a specific service type.
  Future<void> showServiceAlert({
    required String serviceType,
    required double kmRemaining,
  }) async {
    final id = _getServiceNotificationId(serviceType);
    
    await _notifications.show(
      id,
      '🔧 Service Reminder',
      '$serviceType due in ${kmRemaining.toStringAsFixed(0)} km',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdAlerts,
          _channelNameAlerts,
          channelDescription: _channelDescAlerts,
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF0F7A55), // AppTheme.accentGreen
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Cancel all service alerts.
  Future<void> cancelAllServiceAlerts() async {
    await _notifications.cancel(_idServiceEngineOil);
    await _notifications.cancel(_idServiceGeneral);
    await _notifications.cancel(_idServiceAirFilter);
    await _notifications.cancel(_idServiceBrake);
    await _notifications.cancel(_idServiceTyre);
  }

  int _getServiceNotificationId(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'engine oil':
        return _idServiceEngineOil;
      case 'general service':
        return _idServiceGeneral;
      case 'air filter':
        return _idServiceAirFilter;
      case 'brake inspection':
        return _idServiceBrake;
      case 'tyre pressure':
        return _idServiceTyre;
      default:
        return _idServiceGeneral;
    }
  }

  // ─── Utility ────────────────────────────────────────────────────

  /// Show a WhatsApp style heads-up notification for model status.
  Future<void> showModelStatus(bool isAvailable) async {
    await _notifications.show(
      999,
      isAvailable ? '✅ Model Available' : '❌ Model Offline',
      isAvailable ? 'The offline AI model is loaded and ready to chat.' : 'The offline AI model is currently offline or loading.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'model_status',
          'Model Status',
          channelDescription: 'Updates about the AI model status',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Get list of pending notifications (for debugging).
  Future<List<PendingNotificationRequest>> getPending() async {
    return await _notifications.pendingNotificationRequests();
  }
}
