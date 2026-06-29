import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/app/router.dart';

/// Root application widget.
class ActivaTrackerApp extends StatelessWidget {
  const ActivaTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Activa Tracker',
      debugShowCheckedModeBanner: false,

      // Theming
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // dark-first

      // Navigation
      routerConfig: appRouter,
    );
  }
}
