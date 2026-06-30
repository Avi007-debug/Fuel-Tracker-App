import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';
import 'package:fuel_tracker_app/core/analytics/service_engine.dart';
import 'package:fuel_tracker_app/models/service_record.dart';

/// Service Status Panel — shows upcoming service items with km/days remaining.
class ServiceStatusPanel extends ConsumerWidget {
  const ServiceStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(serviceStatusProvider);

    return Container(
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
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(Icons.build, color: AppTheme.accentGreen, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Track maintenance schedule',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          statusAsync.when(
            data: (statuses) {
              if (statuses.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No service data available'),
                  ),
                );
              }

              return Column(
                children: statuses.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ServiceStatusItem(status: status),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Error loading service status'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceStatusItem extends StatelessWidget {
  final ServiceStatus status;

  const _ServiceStatusItem({required this.status});

  Color _getStatusColor() {
    if (status.isDue) return AppTheme.accentRed;
    
    if (status.type == ServiceType.tyrePressure) {
      final days = status.daysSinceService ?? 999;
      if (days > 25) return AppTheme.accentOrange;
      return AppTheme.accentGreen;
    } else {
      final kmRemaining = status.kmUntilDue ?? 999;
      if (kmRemaining < 500) return AppTheme.accentOrange;
      return AppTheme.accentGreen;
    }
  }

  IconData _getIcon() {
    switch (status.type) {
      case ServiceType.engineOil:
        return Icons.opacity;
      case ServiceType.generalService:
        return Icons.handyman;
      case ServiceType.airFilter:
        return Icons.air;
      case ServiceType.brakeInspection:
        return Icons.wifi_protected_setup;
      case ServiceType.tyrePressure:
        return Icons.tire_repair;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(_getIcon(), color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.type.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  status.statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                      ),
                ),
              ],
            ),
          ),
          if (status.isDue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withAlpha(20),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                'DUE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.accentRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
