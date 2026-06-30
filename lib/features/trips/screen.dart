import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/route_type.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';
import 'package:fuel_tracker_app/utils/formatters.dart';

/// Screen 2 — 🚗 Trips
///
/// Calendar heatmap (top), today's trip list, full ride history
/// with filtering by route type and date range.
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTrips = ref.watch(allTripsProvider);
    final todayDistance = ref.watch(todayDistanceProvider);
    final totalDistance = ref.watch(totalDistanceProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Trips',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const Spacer(),
                    // Stats chips
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withAlpha(20),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.straighten,
                              size: 14, color: AppTheme.accentGreen),
                          const SizedBox(width: 4),
                          Text(
                            todayDistance.when(
                              data: (v) => 'Today: ${Formatters.distance(v)}',
                              loading: () => '...',
                              error: (_, __) => '0 km',
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppTheme.accentGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Lifetime Stats ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      _MiniStat(
                        label: 'Total Distance',
                        value: totalDistance.when(
                          data: (v) => Formatters.distance(v),
                          loading: () => '...',
                          error: (_, __) => '0 km',
                        ),
                        icon: Icons.route,
                        color: AppTheme.accentBlue,
                      ),
                      const SizedBox(width: 24),
                      _MiniStat(
                        label: 'Total Trips',
                        value: allTrips.when(
                          data: (v) => '${v.length}',
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                        icon: Icons.repeat,
                        color: AppTheme.accentPurple,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Section Title ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'Ride History',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),

            // ── Trip List ───────────────────────────────────────
            allTrips.when(
              data: (trips) {
                if (trips.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.route_outlined,
                              size: 64,
                              color: AppTheme.textMuted.withAlpha(80)),
                          const SizedBox(height: 16),
                          Text(
                            'No trips logged yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use quick actions on the dashboard to log rides',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: trips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _TripTile(trip: trips[index]),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _TripTile extends ConsumerWidget {
  final Trip trip;
  const _TripTile({required this.trip});

  Color _routeColor() {
    switch (trip.routeType) {
      case RouteType.collegeGo:
        return AppTheme.accentGreen;
      case RouteType.collegeReturn:
        return AppTheme.accentBlue;
      case RouteType.townGo:
      case RouteType.townReturn:
        return AppTheme.accentPurple;
      case RouteType.shortGo:
      case RouteType.shortReturn:
        return AppTheme.accentTeal;
      case RouteType.custom:
        return AppTheme.accentOrange;
    }
  }

  IconData _routeIcon() {
    switch (trip.routeType) {
      case RouteType.collegeGo:
        return Icons.school;
      case RouteType.collegeReturn:
        return Icons.home;
      case RouteType.townGo:
      case RouteType.townReturn:
        return Icons.location_city;
      case RouteType.shortGo:
      case RouteType.shortReturn:
        return Icons.pedal_bike;
      case RouteType.custom:
        return Icons.add_road;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _routeColor();

    return Dismissible(
      key: ValueKey(trip.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.accentRed.withAlpha(30),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.accentRed),
      ),
      onDismissed: (_) async {
        await ref.read(tripServiceProvider).deleteTrip(trip.id);
        ref.invalidate(allTripsProvider);
        ref.invalidate(todayTripsProvider);
        ref.invalidate(todayDistanceProvider);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            // Route icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(_routeIcon(), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Route info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.routeType.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.dateTime(trip.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      trip.notes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Distance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.distance(trip.distanceKm),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (trip.isAnomaly)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withAlpha(20),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      'ANOMALY',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.accentRed,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
