import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';
import 'package:fuel_tracker_app/core/constants/app_constants.dart';
import 'package:fuel_tracker_app/features/settings/controller.dart';
import 'package:fuel_tracker_app/models/route_type.dart';

/// Screen 5 — ⚙️ Settings
///
/// Vehicle profile editor, route distance editor, notification controls,
/// service intervals, backup/restore, dark mode, data wipe.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required ValueChanged<String> onSaved,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final textController = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: textController,
            keyboardType: keyboardType,
            autofocus: true,
            validator: validator ?? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Value cannot be empty';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: title,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onSaved(textController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, String currentStr, ValueChanged<String> onSelected) async {
    final parts = currentStr.split(':');
    final initialTime = parts.length == 2
        ? TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]))
        : const TimeOfDay(hour: 7, minute: 30);

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final hourStr = selectedTime.hour.toString().padLeft(2, '0');
      final minStr = selectedTime.minute.toString().padLeft(2, '0');
      onSelected('$hourStr:$minStr');
    }
  }

  String _formatTimeStr(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final min = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final formattedMin = min.toString().padLeft(2, '0');
      return '$formattedHour:$formattedMin $period';
    } catch (_) {
      return timeStr;
    }
  }

  void _showRestoreDialog(BuildContext context, SettingsController controller) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste the JSON backup text here to restore database:'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"vehicle_profile": ...}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final json = textController.text.trim();
              if (json.isNotEmpty) {
                try {
                  await controller.restoreData(json);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Database restored successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore failed: $e')),
                  );
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showWipeConfirmation(BuildContext context, SettingsController controller) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wipe All Data', style: TextStyle(color: AppTheme.accentRed)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Warning: This action is permanent and cannot be undone. All vehicle profile settings, trips, and refills will be deleted.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Type "DELETE" below to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'DELETE',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (textController.text.trim() == 'DELETE') {
                await controller.wipeAllData();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been wiped.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Confirmation mismatched. Wipe cancelled.')),
                );
              }
            },
            child: const Text('DELETE ALL', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleProfileAsync = ref.watch(vehicleProfileProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final controller = ref.watch(settingsControllerProvider);

    final profile = vehicleProfileAsync.valueOrNull;
    final settings = settingsAsync.valueOrNull ?? {};

    // Load dynamic route distances (fall back to enum defaults)
    final collegeGoDist = settings[RouteType.collegeGo.key] ?? RouteType.collegeGo.defaultDistanceKm;
    final collegeReturnDist = settings[RouteType.collegeReturn.key] ?? RouteType.collegeReturn.defaultDistanceKm;
    final townDist = settings[RouteType.townGo.key] ?? RouteType.townGo.defaultDistanceKm;
    final shortDist = settings[RouteType.shortGo.key] ?? RouteType.shortGo.defaultDistanceKm;

    // Load specific service type intervals (fall back to constant defaults)
    final oilInterval = settings['interval_engineOil'] ?? AppConstants.engineOilIntervalKm;
    final generalInterval = settings['interval_generalService'] ?? AppConstants.generalServiceIntervalKm;
    final airInterval = settings['interval_airFilter'] ?? AppConstants.airFilterIntervalKm;
    final brakeInterval = settings['interval_brakeInspection'] ?? AppConstants.brakeInspectionIntervalKm;

    // Load reminder configurations
    final morningEnabled = settings['morningReminderEnabled'] ?? true;
    final morningTime = settings['morningReminderTime'] ?? '07:30';
    final eveningEnabled = settings['eveningReminderEnabled'] ?? true;
    final eveningTime = settings['eveningReminderTime'] ?? '18:00';

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
                      subtitle: profile?.name ?? AppConstants.defaultVehicleName,
                      onTap: () => _showEditDialog(
                        context: context,
                        title: 'Vehicle Name',
                        initialValue: profile?.name ?? AppConstants.defaultVehicleName,
                        onSaved: (val) => controller.updateProfileField(name: val),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.directions_car,
                      title: 'Model',
                      subtitle: profile?.model ?? AppConstants.defaultVehicleModel,
                      onTap: () => _showEditDialog(
                        context: context,
                        title: 'Model',
                        initialValue: profile?.model ?? AppConstants.defaultVehicleModel,
                        onSaved: (val) => controller.updateProfileField(model: val),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.local_gas_station,
                      title: 'Tank Capacity',
                      subtitle: '${profile?.tankCapacityL ?? AppConstants.defaultTankCapacityL} L',
                      onTap: () => _showEditDialog(
                        context: context,
                        title: 'Tank Capacity (L)',
                        initialValue: (profile?.tankCapacityL ?? AppConstants.defaultTankCapacityL).toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          final num = double.tryParse(val ?? '');
                          if (num == null || num <= 0) return 'Enter a valid positive number';
                          return null;
                        },
                        onSaved: (val) => controller.updateProfileField(tankCapacityL: double.parse(val)),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.warning_amber,
                      title: 'Reserve',
                      subtitle: '${profile?.reserveL ?? AppConstants.defaultReserveL} L',
                      onTap: () => _showEditDialog(
                        context: context,
                        title: 'Reserve Capacity (L)',
                        initialValue: (profile?.reserveL ?? AppConstants.defaultReserveL).toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          final num = double.tryParse(val ?? '');
                          if (num == null || num <= 0) return 'Enter a valid positive number';
                          return null;
                        },
                        onSaved: (val) => controller.updateProfileField(reserveL: double.parse(val)),
                      ),
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
                      subtitle: '${collegeGoDist.toStringAsFixed(1)} km  (Home → Madavara Metro)',
                      onTap: () => _showEditDialog(
                        context: context,
                        title: 'College Going Distance (km)',
                        initialValue: collegeGoDist.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          final num = double.tryParse(val ?? '');
                          if (num == null || num <= 0) return 'Enter a valid positive number';
                          return null;
                        },
                        onSaved: (val) => controller.updateSetting(RouteType.collegeGo.key, double.parse(val)),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.home,
                      title: 'College — Return',
                      subtitle: '${collegeReturnDist.toStringAsFixed(1)} km  (Metro → BP Pump → Home)',
                      onTap: () => _showEditDialog(
                        context: context,
                        title: 'College Return Distance (km)',
                        initialValue: collegeReturnDist.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          final num = double.tryParse(val ?? '');
                          if (num == null || num <= 0) return 'Enter a valid positive number';
                          return null;
                        },
                        onSaved: (val) => controller.updateSetting(RouteType.collegeReturn.key, double.parse(val)),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.location_city,
                      title: 'Nearby Town',
                      subtitle: '${townDist.toStringAsFixed(1)} km  (one way)',
                      onTap: () => _showEditDialog(
                        context: context,
                        title: 'Nearby Town Distance (km)',
                        initialValue: townDist.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          final num = double.tryParse(val ?? '');
                          if (num == null || num <= 0) return 'Enter a valid positive number';
                          return null;
                        },
                        onSaved: (val) {
                          controller.updateSetting(RouteType.townGo.key, double.parse(val));
                          controller.updateSetting(RouteType.townReturn.key, double.parse(val));
                        },
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.pedal_bike,
                      title: 'Short Ride',
                      subtitle: '${shortDist.toStringAsFixed(1)} km  (one way)',
                      onTap: () => _showEditDialog(
                        context: context,
                        title: 'Short Ride Distance (km)',
                        initialValue: shortDist.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          final num = double.tryParse(val ?? '');
                          if (num == null || num <= 0) return 'Enter a valid positive number';
                          return null;
                        },
                        onSaved: (val) {
                          controller.updateSetting(RouteType.shortGo.key, double.parse(val));
                          controller.updateSetting(RouteType.shortReturn.key, double.parse(val));
                        },
                      ),
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
                      subtitle: '${_formatTimeStr(morningTime)} — Weekdays',
                      trailing: Switch(
                        value: morningEnabled,
                        onChanged: (v) => controller.updateSetting('morningReminderEnabled', v),
                        activeColor: AppTheme.accentOrange,
                      ),
                      onTap: () => _selectTime(
                        context,
                        morningTime,
                        (time) => controller.updateSetting('morningReminderTime', time),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.nights_stay_outlined,
                      title: 'Evening Reminder',
                      subtitle: _formatTimeStr(eveningTime),
                      trailing: Switch(
                        value: eveningEnabled,
                        onChanged: (v) => controller.updateSetting('eveningReminderEnabled', v),
                        activeColor: AppTheme.accentOrange,
                      ),
                      onTap: () => _selectTime(
                        context,
                        eveningTime,
                        (time) => controller.updateSetting('eveningReminderTime', time),
                      ),
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
                      subtitle: 'Every ${(oilInterval as num).toInt()} km  (lead: 200 km)',
                      onTap: () => _showEditDialog(
                        context: context,
                        title: 'Engine Oil Interval (km)',
                        initialValue: oilInterval.toString(),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          final num = int.tryParse(val ?? '');
                          if (num == null || num <= 0) return 'Enter a valid positive integer';
                          return null;
                        },
                        onSaved: (val) => controller.updateSetting('interval_engineOil', int.parse(val)),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.handyman,
                      title: 'General Service',
                      subtitle: 'Every ${(generalInterval as num).toInt()} km  (lead: 300 km)',
                      onTap: () => _showEditDialog(
                        context: context,
                        title: 'General Service Interval (km)',
                        initialValue: generalInterval.toString(),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          final num = int.tryParse(val ?? '');
                          if (num == null || num <= 0) return 'Enter a valid positive integer';
                          return null;
                        },
                        onSaved: (val) => controller.updateSetting('interval_generalService', int.parse(val)),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.air,
                      title: 'Air Filter',
                      subtitle: 'Every ${(airInterval as num).toInt()} km',
                      onTap: () => _showEditDialog(
                        context: context,
                        title: 'Air Filter Interval (km)',
                        initialValue: airInterval.toString(),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          final num = int.tryParse(val ?? '');
                          if (num == null || num <= 0) return 'Enter a valid positive integer';
                          return null;
                        },
                        onSaved: (val) => controller.updateSetting('interval_airFilter', int.parse(val)),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.disc_full,
                      title: 'Brake Inspection',
                      subtitle: 'Every ${(brakeInterval as num).toInt()} km',
                      onTap: () => _showEditDialog(
                        context: context,
                        title: 'Brake Inspection Interval (km)',
                        initialValue: brakeInterval.toString(),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          final num = int.tryParse(val ?? '');
                          if (num == null || num <= 0) return 'Enter a valid positive integer';
                          return null;
                        },
                        onSaved: (val) => controller.updateSetting('interval_brakeInspection', int.parse(val)),
                      ),
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
                      subtitle: 'Export all data as JSON file',
                      onTap: () async {
                        try {
                          await controller.backupData();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Backup failed: $e')),
                          );
                        }
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.restore,
                      title: 'Restore',
                      subtitle: 'Import database state from backup JSON',
                      onTap: () => _showRestoreDialog(context, controller),
                    ),
                    _SettingsTile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Wipe All Data',
                      subtitle: 'Permanently delete everything',
                      titleColor: AppTheme.accentRed,
                      onTap: () => _showWipeConfirmation(context, controller),
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
                      subtitle: '${AppConstants.appTagline}\nVersion 1.5.0',
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
