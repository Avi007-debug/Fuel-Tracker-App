import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/app/app.dart';
import 'package:fuel_tracker_app/core/database/database_service.dart';
import 'package:fuel_tracker_app/core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database service.
  await DatabaseService.init();

  // Initialize the notification service.
  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: ActivaTrackerApp(),
    ),
  );
}
