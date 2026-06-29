import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/models/route_type.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';

/// Quick-action grid matching the plan's 6 primary actions:
/// 🟢 Going to College, 🔵 Returned Home, 🟡 Fuel Filled,
/// 🟣 Nearby Town, ⚪ Short Ride, ➕ Custom Ride
class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  void _logTrip(BuildContext context, WidgetRef ref, RouteType route) async {
    final tripService = ref.read(tripServiceProvider);
    await tripService.logTrip(route);

    // Refresh providers.
    ref.invalidate(todayTripsProvider);
    ref.invalidate(todayDistanceProvider);
    ref.invalidate(allTripsProvider);
    ref.invalidate(fuelRemainingProvider);
    ref.invalidate(estimatedRangeProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${route.label} logged — ${route.defaultDistanceKm} km'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              await tripService.undoLastTrip();
              ref.invalidate(todayTripsProvider);
              ref.invalidate(todayDistanceProvider);
              ref.invalidate(allTripsProvider);
            },
          ),
        ),
      );
    }
  }

  void _showCustomRideSheet(BuildContext context, WidgetRef ref) {
    final distanceController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Ride',
              style: Theme.of(ctx).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: distanceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Distance (km)',
                prefixIcon: Icon(Icons.straighten),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () async {
                  final km =
                      double.tryParse(distanceController.text.trim());
                  if (km == null || km <= 0) return;
                  final notes = notesController.text.trim();

                  await ref.read(tripServiceProvider).logCustomTrip(
                        km,
                        notes: notes.isNotEmpty ? notes : null,
                      );
                  ref.invalidate(todayTripsProvider);
                  ref.invalidate(todayDistanceProvider);
                  ref.invalidate(allTripsProvider);

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Custom ride logged — $km km'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Log Ride'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFuelSheet(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final priceController = TextEditingController();
    bool isTankFull = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fuel Filled',
                style: Theme.of(ctx).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount Paid (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price per Litre (₹/L)',
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: isTankFull,
                onChanged: (v) => setState(() => isTankFull = v ?? false),
                title: const Text('Tank Full'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text.trim());
                    final price =
                        double.tryParse(priceController.text.trim());
                    if (amount == null ||
                        amount <= 0 ||
                        price == null ||
                        price <= 0) return;

                    await ref.read(fuelServiceProvider).addFuelByAmount(
                          amountPaid: amount,
                          pricePerLitre: price,
                          isTankFull: isTankFull,
                        );
                    ref.invalidate(allFuelEntriesProvider);
                    ref.invalidate(fuelRemainingProvider);
                    ref.invalidate(estimatedRangeProvider);
                    ref.invalidate(monthSpendProvider);

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Fuel logged — ₹${amount.toStringAsFixed(0)}'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.local_gas_station),
                  label: const Text('Log Fuel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Row 1: College Go, College Return, Fuel Filled
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.school,
                label: 'Going to\nCollege',
                color: AppTheme.accentGreen,
                subtitle: '7.2 km',
                onTap: () => _logTrip(context, ref, RouteType.collegeGo),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.home,
                label: 'Returned\nHome',
                color: AppTheme.accentBlue,
                subtitle: '8.4 km',
                onTap: () => _logTrip(context, ref, RouteType.collegeReturn),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.local_gas_station,
                label: 'Fuel\nFilled',
                color: AppTheme.accentOrange,
                subtitle: '₹',
                onTap: () => _showFuelSheet(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2: Nearby Town, Short Ride, Custom Ride
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.location_city,
                label: 'Nearby\nTown',
                color: AppTheme.accentPurple,
                subtitle: '7.4 km',
                onTap: () => _showDirectionPicker(
                  context,
                  ref,
                  'Nearby Town',
                  RouteType.townGo,
                  RouteType.townReturn,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.pedal_bike,
                label: 'Short\nRide',
                color: AppTheme.accentCyan,
                subtitle: '2.0 km',
                onTap: () => _showDirectionPicker(
                  context,
                  ref,
                  'Short Ride',
                  RouteType.shortGo,
                  RouteType.shortReturn,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.add_road,
                label: 'Custom\nRide',
                color: AppTheme.textSecondary,
                subtitle: '? km',
                onTap: () => _showCustomRideSheet(context, ref),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Shows Going / Return picker for Town and Short routes.
  void _showDirectionPicker(
    BuildContext context,
    WidgetRef ref,
    String title,
    RouteType goRoute,
    RouteType returnRoute,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _logTrip(context, ref, goRoute);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text('Going\n${goRoute.defaultDistanceKm} km',
                        textAlign: TextAlign.center),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _logTrip(context, ref, returnRoute);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: Text(
                        'Return\n${returnRoute.defaultDistanceKm} km',
                        textAlign: TextAlign.center),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// A single quick-action button.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      height: 1.3,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
