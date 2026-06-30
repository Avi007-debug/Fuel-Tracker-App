import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fuel_tracker_app/features/dashboard/screen.dart';
import 'package:fuel_tracker_app/features/trips/screen.dart';
import 'package:fuel_tracker_app/features/fuel/screen.dart';
import 'package:fuel_tracker_app/features/insights/screen.dart';
import 'package:fuel_tracker_app/features/settings/screen.dart';
import 'package:fuel_tracker_app/features/ai_chat/screen.dart';
import 'package:fuel_tracker_app/features/onboarding/screen.dart';

/// Named route paths.
class AppRoutes {
  AppRoutes._();

  static const String dashboard = '/';
  static const String trips = '/trips';
  static const String fuel = '/fuel';
  static const String insights = '/insights';
  static const String settings = '/settings';
  static const String aiChat = '/ai-chat';
  static const String onboarding = '/onboarding';
}

/// GoRouter configuration with a bottom-nav shell.
/// 
/// Note: Redirect logic for onboarding is handled in app.dart
/// using a FutureBuilder that checks isOnboardedProvider.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  routes: [
    // Onboarding route (outside shell)
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: OnboardingScreen(),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.trips,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TripsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.fuel,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FuelScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.insights,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: InsightsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    // AI Chat is a full-screen overlay, outside the shell.
    GoRoute(
      path: AppRoutes.aiChat,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const AiChatScreen(),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),
  ],
);

/// Bottom navigation shell — wraps the 5 main screens.
class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    switch (location) {
      case AppRoutes.trips:
        return 1;
      case AppRoutes.fuel:
        return 2;
      case AppRoutes.insights:
        return 3;
      case AppRoutes.settings:
        return 4;
      default:
        return 0;
    }
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.trips);
        break;
      case 2:
        context.go(AppRoutes.fuel);
        break;
      case 3:
        context.go(AppRoutes.insights);
        break;
      case 4:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        heroTag: 'ai_chat_fab',
        onPressed: () => context.push(AppRoutes.aiChat),
        tooltip: 'AI Chat',
        child: const Icon(Icons.auto_awesome, size: 24),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => _onTap(context, i),
        height: 68,
        animationDuration: const Duration(milliseconds: 400),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Garage',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_gas_station_outlined),
            selectedIcon: Icon(Icons.local_gas_station),
            label: 'Fuel',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
