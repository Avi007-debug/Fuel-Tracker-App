import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:fuel_tracker_app/app/app.dart';
import 'package:fuel_tracker_app/core/database/database_service.dart';
import 'package:fuel_tracker_app/core/notifications/notification_service.dart';
import 'package:fuel_tracker_app/core/notifications/background_worker.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences first
  final prefs = await SharedPreferences.getInstance();

  // Initialize the database service.
  await DatabaseService.init();

  // Initialize the notification service.
  await NotificationService.init();

  // Initialize background worker
  await BackgroundWorker.initialize();
  await BackgroundWorker.registerPeriodicTask();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const VoyageApp(),
    ),
  );
}
