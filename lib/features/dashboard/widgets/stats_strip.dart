import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';
import 'package:fuel_tracker_app/utils/formatters.dart';

/// Today's stats strip — distance, trips count, estimated fuel.
class StatsStrip extends ConsumerWidget {
  const StatsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayDistance = ref.watch(todayDistanceProvider);
    final todayTrips = ref.watch(todayTripsProvider);
    final averageMileage = ref.watch(averageMileageProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            icon: Icons.straighten,
            label: 'Distance',
            value: todayDistance.when(
              data: (v) => Formatters.distance(v),
              loading: () => '...',
              error: (_, __) => '0.0 km',
            ),
            color: AppTheme.accentGreen,
          ),
          _Divider(),
          _StatItem(
            icon: Icons.repeat,
            label: 'Trips',
            value: todayTrips.when(
              data: (v) => '${v.length}',
              loading: () => '...',
              error: (_, __) => '0',
            ),
            color: AppTheme.accentBlue,
          ),
          _Divider(),
          _StatItem(
            icon: Icons.speed,
            label: 'Avg Mileage',
            value: averageMileage.when(
              data: (v) => v > 0 ? Formatters.mileage(v) : '0.0 km/L',
              loading: () => '...',
              error: (_, __) => '0.0 km/L',
            ),
            color: AppTheme.accentOrange,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}
