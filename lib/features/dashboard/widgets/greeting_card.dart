import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/core/constants/app_constants.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';
import 'package:fuel_tracker_app/utils/date_helpers.dart';
import 'package:fuel_tracker_app/utils/formatters.dart';

/// Morning greeting card widget for the AI Garage dashboard.
///
/// Shows: greeting, expected commute, fuel remaining, estimated range,
/// and monthly spend projection — all rule-based, no LLM.
class GreetingCard extends ConsumerWidget {
  const GreetingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelRemaining = ref.watch(fuelRemainingProvider);
    final estimatedRange = ref.watch(estimatedRangeProvider);
    final monthSpend = ref.watch(monthSpendProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGreen.withAlpha(40),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting ────────────────────────────────────────
          Text(
            '${DateHelpers.greeting}, ${AppConstants.riderName}!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            DateHelpers.isWeekday
                ? 'Ready for your commute today?'
                : 'Enjoy your weekend ride!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(200),
                ),
          ),
          const SizedBox(height: 20),

          // ── Stat Chips ──────────────────────────────────────
          Row(
            children: [
              // Expected commute
              _StatChip(
                icon: Icons.route,
                label: 'Today\'s Commute',
                value: DateHelpers.isWeekday
                    ? '${AppConstants.collegeGoingKm + AppConstants.collegeReturnKm} km'
                    : '— km',
              ),
              const SizedBox(width: 12),
              // Fuel remaining
              _StatChip(
                icon: Icons.local_gas_station,
                label: 'Fuel Left',
                value: fuelRemaining.when(
                  data: (v) => Formatters.litres(v),
                  loading: () => '...',
                  error: (_, __) => '— L',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Estimated range
              _StatChip(
                icon: Icons.speed,
                label: 'Range',
                value: estimatedRange.when(
                  data: (v) => Formatters.distance(v),
                  loading: () => '...',
                  error: (_, __) => '— km',
                ),
              ),
              const SizedBox(width: 12),
              // Monthly spend
              _StatChip(
                icon: Icons.account_balance_wallet,
                label: 'Month Spend',
                value: monthSpend.when(
                  data: (v) => Formatters.currency(v),
                  loading: () => '...',
                  error: (_, __) => '₹—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single stat chip inside the greeting card.
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withAlpha(180),
                          fontSize: 9,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
