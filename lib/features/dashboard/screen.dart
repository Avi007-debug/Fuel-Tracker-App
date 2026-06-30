import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';
import 'package:fuel_tracker_app/features/dashboard/widgets/greeting_card.dart';
import 'package:fuel_tracker_app/features/dashboard/widgets/stats_strip.dart';
import 'package:fuel_tracker_app/features/dashboard/widgets/quick_actions.dart';

/// Screen 1 — 🏠 AI Garage (Dashboard)
///
/// Personalized greeting, fuel gauge, today's stats, quick actions,
/// and a pinned AI suggestion card.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.accentGreen,
          onRefresh: () async {
            // Refresh all dashboard providers.
            ref.invalidate(todayDistanceProvider);
            ref.invalidate(fuelRemainingProvider);
            ref.invalidate(estimatedRangeProvider);
            ref.invalidate(monthSpendProvider);
            ref.invalidate(averageMileageProvider);
            ref.invalidate(todayTripsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      // Animated vehicle icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: const Icon(
                          Icons.two_wheeler,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Activa Tracker',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'AI Garage',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.accentGreen,
                                ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Theme toggle
                      IconButton(
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                        icon: Icon(
                          ref.watch(themeModeProvider) == ThemeMode.light
                              ? Icons.dark_mode_outlined
                              : Icons.lightbulb_outline,
                        ),
                      ),
                      // Notification bell
                      IconButton(
                        onPressed: () {
                          // TODO: show notifications
                        },
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Greeting Card ───────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: GreetingCard(),
                ),
              ),

              // ── Today's Stats Strip ─────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: StatsStrip(),
                ),
              ),

              // ── Quick Actions ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: QuickActions(),
                ),
              ),

              // ── AI Suggestion Card ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _AiSuggestionCard(),
                ),
              ),

              // Bottom padding.
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pinned AI insight / suggestion card (rule-based).
class _AiSuggestionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPurple.withAlpha(25),
            AppTheme.accentBlue.withAlpha(15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.accentPurple.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withAlpha(30),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppTheme.accentPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.accentPurple,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your first ride to unlock personalised insights about your riding patterns.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppTheme.accentPurple,
          ),
        ],
      ),
    );
  }
}
