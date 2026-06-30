import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/app/router.dart';
import 'package:fuel_tracker_app/features/onboarding/screen.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';

/// Root application widget.
/// Handles onboarding redirect before showing the main app.
class VoyageApp extends ConsumerWidget {
  const VoyageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnboardedAsync = ref.watch(isOnboardedProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Voyage',
      debugShowCheckedModeBanner: false,

      // Theming
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Navigation
      routerConfig: appRouter,

      // Show loading or redirect to onboarding
      builder: (context, child) {
        return isOnboardedAsync.when(
          data: (isOnboarded) {
            if (!isOnboarded) {
              // Show onboarding screen
              return const OnboardingScreen();
            }
            return child ?? const SizedBox();
          },
          loading: () => const _SplashScreen(),
          error: (_, __) => child ?? const SizedBox(),
        );
      },
    );
  }
}

/// Splash screen shown while loading.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.two_wheeler,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppTheme.accentGreen),
            ],
          ),
        ),
      ),
    );
  }
}
