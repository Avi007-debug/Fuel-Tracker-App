import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';
import 'package:fuel_tracker_app/models/daily_cost.dart';

class DailyCostsScreen extends ConsumerStatefulWidget {
  const DailyCostsScreen({super.key});

  @override
  ConsumerState<DailyCostsScreen> createState() => _DailyCostsScreenState();
}

class _DailyCostsScreenState extends ConsumerState<DailyCostsScreen> {
  CommuteType _selectedType = CommuteType.metro;
  bool _addParking = false;

  void _logCommute() async {
    double baseCost = _selectedType == CommuteType.metro ? 166.0 : 114.0;
    double parking = _addParking ? 30.0 : 0.0;

    final cost = DailyCost.create(
      timestamp: DateTime.now(),
      type: _selectedType,
      baseCost: baseCost,
      parkingFee: parking,
    );

    await ref.read(dailyCostServiceProvider).addDailyCost(cost);
    
    // Refresh providers
    ref.invalidate(allDailyCostsProvider);
    ref.invalidate(weeklyDailyCostProvider);
    ref.invalidate(monthlyDailyCostProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Commute logged: ₹${cost.totalCost.toStringAsFixed(0)}')),
      );
    }
  }

  void _deleteCost(DailyCost cost) async {
    await ref.read(dailyCostServiceProvider).deleteDailyCost(cost.id);
    ref.invalidate(allDailyCostsProvider);
    ref.invalidate(weeklyDailyCostProvider);
    ref.invalidate(monthlyDailyCostProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final weeklyCost = ref.watch(weeklyDailyCostProvider).valueOrNull ?? 0.0;
    final monthlyCost = ref.watch(monthlyDailyCostProvider).valueOrNull ?? 0.0;
    final historyAsync = ref.watch(allDailyCostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commute Costs'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Analytics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'This Week',
                          amount: weeklyCost,
                          icon: Icons.calendar_view_week,
                          color: AppTheme.accentTeal,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: _StatCard(
                          title: 'This Month',
                          amount: monthlyCost,
                          icon: Icons.calendar_month,
                          color: AppTheme.accentPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  // Logging Section
                  Text('Log Today\'s Commute', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingMd),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<CommuteType>(
                          segments: const [
                            ButtonSegment(
                              value: CommuteType.metro,
                              label: Text('Metro (₹166)'),
                              icon: Icon(Icons.train),
                            ),
                            ButtonSegment(
                              value: CommuteType.bus,
                              label: Text('Bus (₹114)'),
                              icon: Icon(Icons.directions_bus),
                            ),
                          ],
                          selected: {_selectedType},
                          onSelectionChanged: (Set<CommuteType> newSelection) {
                            setState(() {
                              _selectedType = newSelection.first;
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppTheme.accentPurple.withAlpha(51);
                                }
                                return Colors.transparent;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        SwitchListTile(
                          title: const Text('Add Parking Fee (₹30)'),
                          value: _addParking,
                          onChanged: (val) => setState(() => _addParking = val),
                          activeColor: AppTheme.accentPurple,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        ElevatedButton(
                          onPressed: _logCommute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                          child: const Text('Log Commute', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXl),
                  Text('History', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingMd),
                ],
              ),
            ),
          ),
          
          // History List
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text('No commute costs logged yet.', style: theme.textTheme.bodyMedium),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = history[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: AppTheme.accentRed,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteCost(item),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPurple.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.type == CommuteType.metro ? Icons.train : Icons.directions_bus,
                            color: AppTheme.accentPurple,
                          ),
                        ),
                        title: Text('${item.type.label} Commute'),
                        subtitle: Text(DateFormat('MMM d, yyyy - HH:mm').format(item.timestamp)),
                        trailing: Text(
                          '₹${item.totalCost.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  },
                  childCount: history.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
