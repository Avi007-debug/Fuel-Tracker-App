import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';
import 'package:fuel_tracker_app/utils/formatters.dart';
import 'package:fuel_tracker_app/features/insights/widgets/charts.dart';
import 'package:fuel_tracker_app/features/insights/widgets/service_status_panel.dart';
import 'package:fuel_tracker_app/core/export/csv_exporter.dart';
import 'package:fuel_tracker_app/core/export/pdf_exporter.dart';

/// Screen 4 — 📊 Insights
///
/// Monthly summary card, AI insight chips, graph browser,
/// Vehicle Health Score gauge, service status panel, export buttons.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String _selectedCategory = 'Riding';

  Widget _buildCategoryChip(String category) {
    final selected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(category),
      selected: selected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedCategory = category;
          });
        }
      },
      selectedColor: AppTheme.accentGreen.withAlpha(50),
      labelStyle: TextStyle(
        color: selected ? AppTheme.accentGreen : AppTheme.textMuted,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  List<Widget> _getCategoryCharts() {
    switch (_selectedCategory) {
      case 'Riding':
        return const [
          DailyDistanceChart(),
          CalendarHeatmap(),
          MonthlyDistanceChart(),
          CumulativeDistanceChart(),
          WeeklyPatternChart(),
          RouteDistributionChart(),
          StackedMonthlyDistanceChart(),
        ];
      case 'Fuel':
        return const [
          MileageTrendChart(),
          AiPredictionOverlayChart(),
          FuelEconomyDistributionChart(),
          FuelTankLevelGauge(),
          FuelConsumptionChart(),
          PetrolPriceTrendChart(),
        ];
      case 'Expenses':
        return const [
          MonthlySpendChart(),
          MonthlyExpenseForecastChart(),
          CostPerKmChart(),
          ScatterPlotPriceVsCostChart(),
          SankeyFuelFlowChart(),
          ExpenseBreakdownChart(),
          RefillHistoryTimelineChart(),
        ];
      case 'AI Diagnostics':
        return const [
          VehicleHealthScoreGauge(),
          RadarHealthMetricsChart(),
          AiInsightsGrid(),
          AchievementsGrid(),
          AiTimelineFeed(),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthDistance = ref.watch(monthDistanceProvider);
    final monthSpend = ref.watch(monthSpendProvider);
    final avgMileage = ref.watch(averageMileageProvider);
    final totalDistance = ref.watch(totalDistanceProvider);
    final tripCount = ref.watch(tripCountProvider);

    final charts = _getCategoryCharts();

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
                      'Insights',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const Spacer(),
                    // Export buttons
                    IconButton(
                      onPressed: () async {
                        try {
                          final profile = await ref.read(vehicleProfileProvider.future);
                          final trips = await ref.read(allTripsProvider.future);
                          final entries = await ref.read(allFuelEntriesProvider.future);
                          final totalDistance = await ref.read(totalDistanceProvider.future);
                          final totalSpent = entries.fold<double>(0.0, (s, e) => s + (e.amountPaid ?? 0.0));
                          final averageMileage = await ref.read(averageMileageProvider.future);

                          await PdfExporter.exportMonthlyReport(
                            profile: profile,
                            trips: trips,
                            entries: entries,
                            totalDistance: totalDistance,
                            totalSpent: totalSpent,
                            averageMileage: averageMileage,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to export PDF: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      tooltip: 'Export PDF',
                    ),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (ctx) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.directions_run_outlined),
                                title: const Text('Export Trips to CSV'),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  try {
                                    final trips = await ref.read(allTripsProvider.future);
                                    await CsvExporter.exportTrips(trips);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to export trips: $e')),
                                    );
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.local_gas_station_outlined),
                                title: const Text('Export Refill Logs to CSV'),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  try {
                                    final entries = await ref.read(allFuelEntriesProvider.future);
                                    await CsvExporter.exportFuel(entries);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to export refills: $e')),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.table_chart_outlined),
                      tooltip: 'Export CSV',
                    ),
                  ],
                ),
              ),
            ),

            // ── Monthly Summary Card ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGreen.withAlpha(30),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Month',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _SummaryItem(
                            label: 'Distance',
                            value: monthDistance.when(
                              data: (v) => Formatters.distance(v),
                              loading: () => '...',
                              error: (_, __) => '0 km',
                            ),
                          ),
                          _SummaryItem(
                            label: 'Spend',
                            value: monthSpend.when(
                              data: (v) => Formatters.currency(v),
                              loading: () => '...',
                              error: (_, __) => '₹0',
                            ),
                          ),
                          _SummaryItem(
                            label: 'Avg Mileage',
                            value: avgMileage.when(
                              data: (v) =>
                                  v > 0 ? Formatters.mileage(v) : '—',
                              loading: () => '...',
                              error: (_, __) => '—',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Vehicle Health Score ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _HealthScoreCard(),
              ),
            ),

            // ── Service Status Panel ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: const ServiceStatusPanel(),
              ),
            ),

            // ── Quick Stats Grid ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'Lifetime Stats',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _InsightCard(
                        icon: Icons.route,
                        label: 'Total Distance',
                        value: totalDistance.when(
                          data: (v) => Formatters.distance(v),
                          loading: () => '...',
                          error: (_, __) => '0 km',
                        ),
                        color: AppTheme.accentBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InsightCard(
                        icon: Icons.repeat,
                        label: 'Total Trips',
                        value: tripCount.when(
                          data: (v) => '$v',
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                        color: AppTheme.accentPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Charts Section ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'Analytics',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),

            // Horizontal Category Selector Chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildCategoryChip('Riding'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Fuel'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Expenses'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('AI Diagnostics'),
                  ],
                ),
              ),
            ),

            // Dynamically Render Category Charts
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: charts[index],
                  );
                },
                childCount: charts.length,
              ),
            ),

            // Bottom padding.
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withAlpha(180),
                ),
          ),
        ],
      ),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder health score — will be calculated by analytics engine.
    const score = 0.93;
    const scorePercent = 93;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          // Circular score gauge
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: score,
                    strokeWidth: 6,
                    backgroundColor: AppTheme.accentGreen.withAlpha(25),
                    color: AppTheme.accentGreen,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '$scorePercent',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle Health',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _HealthBar(label: 'Fuel Efficiency', value: 0.92, color: AppTheme.accentGreen),
                const SizedBox(height: 6),
                _HealthBar(label: 'Maintenance', value: 1.0, color: AppTheme.accentBlue),
                const SizedBox(height: 6),
                _HealthBar(label: 'Ride Consistency', value: 0.84, color: AppTheme.accentOrange),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _HealthBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withAlpha(20),
            color: color,
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}


