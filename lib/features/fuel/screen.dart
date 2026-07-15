import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/core/constants/app_constants.dart';
import 'package:fuel_tracker_app/models/fuel_entry.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';
import 'package:fuel_tracker_app/utils/formatters.dart';

/// Screen 3 — ⛽ Fuel
///
/// Current estimated fuel + range gauge, "Fuel Filled" action,
/// refill history timeline, petrol price mini-chart,
/// and "Navigate to BP Makali" button.
class FuelScreen extends ConsumerWidget {
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelRemaining = ref.watch(fuelRemainingProvider);
    final estimatedRange = ref.watch(estimatedRangeProvider);
    final allEntries = ref.watch(allFuelEntriesProvider);
    final monthSpend = ref.watch(monthSpendProvider);
    final avgMileage = ref.watch(averageMileageProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Fuel',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
            ),

            // ── Fuel Gauge Card ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _FuelGaugeCard(
                  fuelRemaining: fuelRemaining,
                  estimatedRange: estimatedRange,
                ),
              ),
            ),

            // ── Stats Row ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Month Spend',
                        value: monthSpend.when(
                          data: (v) => Formatters.currency(v),
                          loading: () => '...',
                          error: (_, __) => '₹0',
                        ),
                        icon: Icons.account_balance_wallet,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Mileage',
                        value: avgMileage.when(
                          data: (v) =>
                              v > 0 ? Formatters.mileage(v) : '— km/L',
                          loading: () => '...',
                          error: (_, __) => '— km/L',
                        ),
                        icon: Icons.speed,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Predictive Fuel Timeline ────────────────────────
            const SliverToBoxAdapter(
              child: _PredictiveFuelTimeline(),
            ),

            // ── Navigate to BP ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Material(
                  color: AppTheme.accentBlue.withAlpha(15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    onTap: () async {
                      final uri = Uri.parse(AppConstants.bpMakaliMapsUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                            color: AppTheme.accentBlue.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.navigation,
                              color: AppTheme.accentBlue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Navigate to BP Makali',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: AppTheme.accentBlue),
                                ),
                                Text(
                                  'Open in Google Maps',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.open_in_new,
                              color: AppTheme.accentBlue, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Refill History Title ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'Refill History',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),

            // ── Refill History List ─────────────────────────────
            allEntries.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_gas_station_outlined,
                              size: 64,
                              color: AppTheme.textMuted.withAlpha(80)),
                          const SizedBox(height: 16),
                          Text(
                            'No fuel entries yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Fuel Filled" on the dashboard to log a refill',
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
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _FuelTile(entry: entries[i]),
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

/// Visual fuel gauge card.
class _FuelGaugeCard extends StatelessWidget {
  final AsyncValue<double> fuelRemaining;
  final AsyncValue<double> estimatedRange;

  const _FuelGaugeCard({
    required this.fuelRemaining,
    required this.estimatedRange,
  });

  @override
  Widget build(BuildContext context) {
    final fuel = fuelRemaining.valueOrNull ?? 0.0;
    final range = estimatedRange.valueOrNull ?? 0.0;
    final tankCapacity = AppConstants.defaultTankCapacityL;
    final fraction = (fuel / tankCapacity).clamp(0.0, 1.0);

    // Color based on fuel level.
    Color gaugeColor;
    if (fraction > 0.5) {
      gaugeColor = AppTheme.accentGreen;
    } else if (fraction > 0.25) {
      gaugeColor = AppTheme.accentOrange;
    } else {
      gaugeColor = AppTheme.accentRed;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gaugeColor.withAlpha(15),
            gaugeColor.withAlpha(5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: gaugeColor.withAlpha(40)),
      ),
      child: Column(
        children: [
          // Circular gauge
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: fraction,
                    strokeWidth: 10,
                    backgroundColor: gaugeColor.withAlpha(25),
                    color: gaugeColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_gas_station,
                        color: gaugeColor, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.litres(fuel),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: gaugeColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'remaining',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Range estimate
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: gaugeColor.withAlpha(15),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              'Estimated range: ${Formatters.distance(range)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: gaugeColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }
}

class _FuelTile extends ConsumerWidget {
  final FuelEntry entry;
  const _FuelTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(entry.id),
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
      confirmDismiss: (_) async {
        return true;
      },
      onDismissed: (_) async {
        // Store entry data for undo
        final deletedEntry = entry;

        await ref.read(databaseServiceProvider).deleteFuelEntry(entry.id);
        ref.invalidate(allFuelEntriesProvider);
        ref.invalidate(fuelRemainingProvider);
        ref.invalidate(estimatedRangeProvider);
        ref.invalidate(monthSpendProvider);
        ref.invalidate(averageMileageProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fuel entry deleted (${Formatters.currency(deletedEntry.amountPaid ?? 0)})',
              ),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () async {
                  await ref.read(databaseServiceProvider).addFuelEntry(deletedEntry);
                  ref.invalidate(allFuelEntriesProvider);
                  ref.invalidate(fuelRemainingProvider);
                  ref.invalidate(estimatedRangeProvider);
                  ref.invalidate(monthSpendProvider);
                  ref.invalidate(averageMileageProvider);
                },
              ),
            ),
          );
        }
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
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withAlpha(20),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(Icons.local_gas_station,
                  color: AppTheme.accentOrange, size: 20),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Formatters.litres(entry.litresFilled)} @ ₹${Formatters.decimal1(entry.pricePerLitre)}/L',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.dateTime(entry.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (entry.calculatedMileage > 0)
                    Text(
                      'Mileage: ${Formatters.mileage(entry.calculatedMileage)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentGreen,
                          ),
                    ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.amountPaid != null
                      ? Formatters.currency(entry.amountPaid!)
                      : '—',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentOrange,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (entry.isTankFull)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withAlpha(20),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      'FULL',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.accentGreen,
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

class _PredictiveFuelTimeline extends ConsumerWidget {
  const _PredictiveFuelTimeline();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(predictiveFuelForecastProvider);

    return forecastAsync.when(
      data: (forecast) {
        if (forecast.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now();
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final tankCapacity = AppConstants.defaultTankCapacityL;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '7-Day Fuel Forecast',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Icon(Icons.show_chart, color: AppTheme.accentGreen, size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Estimated tank remaining day-by-day based on patterns',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final fuel = forecast[i];
                  final fraction = (fuel / tankCapacity).clamp(0.0, 1.0);
                  final day = now.add(Duration(days: i + 1));
                  final dayLabel = weekdays[day.weekday - 1];

                  Color barColor = AppTheme.accentGreen;
                  if (fraction < 0.25) {
                    barColor = AppTheme.accentRed;
                  } else if (fraction < 0.5) {
                    barColor = AppTheme.accentOrange;
                  }

                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${fuel.toStringAsFixed(1)}L',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                color: fuel <= 0.8 ? AppTheme.accentRed : AppTheme.textMuted,
                                fontWeight: fuel <= 0.8 ? FontWeight.bold : FontWeight.normal,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 70,
                          width: 14,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: 70 * fraction,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabel,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: day.weekday == DateTime.now().weekday ? FontWeight.bold : FontWeight.normal,
                              ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        child: Text('Forecast Error: $err', style: const TextStyle(color: AppTheme.accentRed)),
      ),
    );
  }
}
