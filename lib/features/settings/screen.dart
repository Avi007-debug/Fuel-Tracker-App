import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';
import 'package:fuel_tracker_app/core/constants/app_constants.dart';

/// Screen 5 — ⚙️ Settings
///
/// Vehicle profile editor, route distance editor, notification controls,
/// service intervals, AI model management, backup/restore, dark mode, data wipe.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleProfile = ref.watch(vehicleProfileProvider);

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
                  'Settings',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
            ),

            // ── Vehicle Profile ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _SettingsSection(
                  title: 'Vehicle Profile',
                  icon: Icons.two_wheeler,
                  color: AppTheme.accentGreen,
                  children: [
                    _SettingsTile(
                      icon: Icons.badge_outlined,
                      title: 'Vehicle Name',
                      subtitle: vehicleProfile.when(
                        data: (p) => p?.name ?? AppConstants.defaultVehicleName,
                        loading: () => '...',
                        error: (_, __) => AppConstants.defaultVehicleName,
                      ),
                      onTap: () {
                        // TODO: edit vehicle name
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.directions_car,
                      title: 'Model',
                      subtitle: vehicleProfile.when(
                        data: (p) =>
                            p?.model ?? AppConstants.defaultVehicleModel,
                        loading: () => '...',
                        error: (_, __) => AppConstants.defaultVehicleModel,
                      ),
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.local_gas_station,
                      title: 'Tank Capacity',
                      subtitle: '${AppConstants.defaultTankCapacityL} L',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.warning_amber,
                      title: 'Reserve',
                      subtitle: '${AppConstants.defaultReserveL} L',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── Route Distances ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SettingsSection(
                  title: 'Route Distances',
                  icon: Icons.route,
                  color: AppTheme.accentBlue,
                  children: [
                    _SettingsTile(
                      icon: Icons.school,
                      title: 'College — Going',
                      subtitle:
                          '${AppConstants.collegeGoingKm} km  (Home → Madavara Metro)',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.home,
                      title: 'College — Return',
                      subtitle:
                          '${AppConstants.collegeReturnKm} km  (Metro → BP Pump → Home)',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.location_city,
                      title: 'Nearby Town',
                      subtitle: '${AppConstants.nearbyTownKm} km  (one way)',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.pedal_bike,
                      title: 'Short Ride',
                      subtitle: '${AppConstants.shortRideKm} km  (one way)',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── Notifications ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SettingsSection(
                  title: 'Notifications',
                  icon: Icons.notifications_outlined,
                  color: AppTheme.accentOrange,
                  children: [
                    _SettingsTile(
                      icon: Icons.wb_sunny_outlined,
                      title: 'Morning Reminder',
                      subtitle:
                          '${AppConstants.morningReminderHour}:${AppConstants.morningReminderMinute.toString().padLeft(2, '0')} AM — Weekdays',
                      trailing: Switch(
                        value: true,
                        onChanged: (v) {},
                        activeColor: AppTheme.accentOrange,
                      ),
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.nights_stay_outlined,
                      title: 'Evening Reminder',
                      subtitle:
                          '${AppConstants.eveningReminderHour - 12}:${AppConstants.eveningReminderMinute.toString().padLeft(2, '0')} PM',
                      trailing: Switch(
                        value: true,
                        onChanged: (v) {},
                        activeColor: AppTheme.accentOrange,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── Service Intervals ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SettingsSection(
                  title: 'Service Intervals',
                  icon: Icons.build_outlined,
                  color: AppTheme.accentPurple,
                  children: [
                    _SettingsTile(
                      icon: Icons.oil_barrel,
                      title: 'Engine Oil',
                      subtitle:
                          'Every ${AppConstants.engineOilIntervalKm.toInt()} km  (lead: 200 km)',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.handyman,
                      title: 'General Service',
                      subtitle:
                          'Every ${AppConstants.generalServiceIntervalKm.toInt()} km  (lead: 300 km)',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.air,
                      title: 'Air Filter',
                      subtitle:
                          'Every ${AppConstants.airFilterIntervalKm.toInt()} km',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.disc_full,
                      title: 'Brake Inspection',
                      subtitle:
                          'Every ${AppConstants.brakeInspectionIntervalKm.toInt()} km',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.tire_repair,
                      title: 'Tyre Pressure',
                      subtitle: 'Monthly reminder — 1st of each month',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── Data Management ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SettingsSection(
                  title: 'Data',
                  icon: Icons.storage_outlined,
                  color: AppTheme.accentCyan,
                  children: [
                    _SettingsTile(
                      icon: Icons.backup_outlined,
                      title: 'Backup',
                      subtitle: 'Export all data as JSON',
                      onTap: () {
                        // TODO: backup
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.restore,
                      title: 'Restore',
                      subtitle: 'Import from backup file',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Wipe All Data',
                      subtitle: 'Permanently delete everything',
                      titleColor: AppTheme.accentRed,
                      onTap: () {
                        // TODO: confirmation dialog + wipe
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── About ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SettingsSection(
                  title: 'About',
                  icon: Icons.info_outline,
                  color: AppTheme.textSecondary,
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outline,
                      title: AppConstants.appName,
                      subtitle: '${AppConstants.appTagline}\nVersion 1.0.0',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

/// A section container for grouped settings.
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// A single settings row.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: titleColor,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(Icons.chevron_right,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(80)),
          ],
        ),
      ),
    );
  }
}
