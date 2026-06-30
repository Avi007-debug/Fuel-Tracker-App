import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';
import 'package:fuel_tracker_app/models/trip.dart';
import 'package:fuel_tracker_app/models/route_type.dart';

/// Mileage Trend Line Chart — km/L per refill interval.
class MileageTrendChart extends ConsumerWidget {
  const MileageTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        final validEntries = entries.where((e) => e.calculatedMileage > 0).toList();
        if (validEntries.isEmpty) {
          return _EmptyChart(message: 'Log fuel entries to see mileage trend');
        }

        final spots = <FlSpot>[];
        for (var i = 0; i < validEntries.length; i++) {
          spots.add(FlSpot(i.toDouble(), validEntries[i].calculatedMileage));
        }

        return _ChartContainer(
          title: 'Mileage Trend',
          subtitle: 'km/L per refill',
          color: AppTheme.accentGreen,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.textMuted.withAlpha(30),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 5,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() % 2 != 0) return const SizedBox();
                      return Text(
                        '#${value.toInt() + 1}',
                        style: Theme.of(context).textTheme.labelSmall,
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (spots.length - 1).toDouble().clamp(0, double.infinity),
              minY: 0,
              maxY: (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 5).clamp(20, 60),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.accentGreen,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4,
                      color: AppTheme.accentGreen,
                      strokeWidth: 2,
                      strokeColor: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentGreen.withAlpha(60),
                        AppTheme.accentGreen.withAlpha(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}

/// Daily Distance Line Chart.
class DailyDistanceChart extends ConsumerWidget {
  const DailyDistanceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(allTripsProvider);

    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return _EmptyChart(message: 'Log trips to see daily distance');
        }

        // Group by day
        final dailyDistances = <DateTime, double>{};
        for (final trip in trips) {
          final day = DateTime(trip.timestamp.year, trip.timestamp.month, trip.timestamp.day);
          dailyDistances[day] = (dailyDistances[day] ?? 0) + trip.distanceKm;
        }

        final sortedDays = dailyDistances.keys.toList()..sort();
        final last14Days = sortedDays.length > 14 ? sortedDays.sublist(sortedDays.length - 14) : sortedDays;

        final spots = <FlSpot>[];
        for (var i = 0; i < last14Days.length; i++) {
          spots.add(FlSpot(i.toDouble(), dailyDistances[last14Days[i]]!));
        }

        if (spots.isEmpty) {
          return _EmptyChart(message: 'Log trips to see daily distance');
        }

        return _ChartContainer(
          title: 'Daily Distance',
          subtitle: 'Last 14 days',
          color: AppTheme.accentBlue,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.textMuted.withAlpha(30),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: AppTheme.accentBlue,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentBlue.withAlpha(40),
                        AppTheme.accentBlue.withAlpha(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}

/// Monthly Fuel Spend Bar Chart.
class MonthlySpendChart extends ConsumerWidget {
  const MonthlySpendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _EmptyChart(message: 'Log fuel to see monthly spend');
        }

        // Group by month
        final monthlySpend = <String, double>{};
        for (final entry in entries) {
          final key = '${entry.timestamp.year}-${entry.timestamp.month.toString().padLeft(2, '0')}';
          monthlySpend[key] = (monthlySpend[key] ?? 0) + (entry.amountPaid ?? 0);
        }

        final sortedMonths = monthlySpend.keys.toList()..sort();
        final last6Months = sortedMonths.length > 6 ? sortedMonths.sublist(sortedMonths.length - 6) : sortedMonths;

        final barGroups = <BarChartGroupData>[];
        for (var i = 0; i < last6Months.length; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: monthlySpend[last6Months[i]]!,
                  color: AppTheme.accentOrange,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          );
        }

        if (barGroups.isEmpty) {
          return _EmptyChart(message: 'Log fuel to see monthly spend');
        }

        return _ChartContainer(
          title: 'Monthly Fuel Spend',
          subtitle: 'Last 6 months',
          color: AppTheme.accentOrange,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (barGroups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b) * 1.2).clamp(100, 5000),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) => Text(
                      '₹${value.toInt()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= last6Months.length) return const SizedBox();
                      final month = last6Months[value.toInt()];
                      return Text(
                        month?.split('-').last ?? '',
                        style: Theme.of(context).textTheme.labelSmall,
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}

/// Route Distribution Pie Chart.
class RouteDistributionChart extends ConsumerWidget {
  const RouteDistributionChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(allTripsProvider);

    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return _EmptyChart(message: 'Log trips to see route distribution');
        }

        // Count by route type category
        final counts = <String, int>{};
        for (final trip in trips) {
          final category = _getCategory(trip.routeType);
          counts[category] = (counts[category] ?? 0) + 1;
        }

        if (counts.isEmpty) {
          return _EmptyChart(message: 'Log trips to see route distribution');
        }

        final sections = <PieChartSectionData>[];
        final colors = [AppTheme.accentGreen, AppTheme.accentBlue, AppTheme.accentPurple, AppTheme.accentOrange];
        final total = counts.values.reduce((a, b) => a + b);
        var colorIndex = 0;

        for (final entry in counts.entries) {
          final percentage = (entry.value / total * 100).round();
          sections.add(
            PieChartSectionData(
              value: entry.value.toDouble(),
              color: colors[colorIndex % colors.length],
              title: '${entry.key}\n$percentage%',
              titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
              radius: 50,
            ),
          );
          colorIndex++;
        }

        return _ChartContainer(
          title: 'Route Distribution',
          subtitle: 'By trip type',
          color: AppTheme.accentPurple,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }

  String _getCategory(RouteType type) {
    switch (type) {
      case RouteType.collegeGo:
      case RouteType.collegeReturn:
        return 'College';
      case RouteType.townGo:
      case RouteType.townReturn:
        return 'Town';
      case RouteType.shortGo:
      case RouteType.shortReturn:
        return 'Short';
      case RouteType.custom:
        return 'Custom';
    }
  }
}

/// Weekly Riding Pattern Bar Chart.
class WeeklyPatternChart extends ConsumerWidget {
  const WeeklyPatternChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(allTripsProvider);

    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return _EmptyChart(message: 'Log trips to see weekly pattern');
        }

        // Calculate average by day of week
        final dayDistances = <int, List<double>>{};
        for (final trip in trips) {
          final day = trip.timestamp.weekday; // 1 = Monday, 7 = Sunday
          dayDistances.putIfAbsent(day, () => []);
          dayDistances[day]!.add(trip.distanceKm);
        }

        final avgByDay = <int, double>{};
        for (final entry in dayDistances.entries) {
          avgByDay[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
        }

        final barGroups = <BarChartGroupData>[];
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        for (var i = 1; i <= 7; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i - 1,
              barRods: [
                BarChartRodData(
                  toY: avgByDay[i] ?? 0,
                  color: i <= 5 ? AppTheme.accentBlue : AppTheme.accentPurple,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          );
        }

        return _ChartContainer(
          title: 'Weekly Riding Pattern',
          subtitle: 'Avg km by day',
          color: AppTheme.accentBlue,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (barGroups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b) * 1.3).clamp(10, 50),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(
                      days[value.toInt()],
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}

// ─── Chart Helpers ────────────────────────────────────────────────────────

class _ChartContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;

  const _ChartContainer({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
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
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart, size: 48, color: AppTheme.textMuted.withAlpha(50)),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LoadingChart extends StatelessWidget {
  const _LoadingChart();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorChart extends StatelessWidget {
  const _ErrorChart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Error loading chart', style: Theme.of(context).textTheme.bodySmall),
    );
  }
}


/// Cost per km Line Chart.
class CostPerKmChart extends ConsumerWidget {
  const CostPerKmChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        final validEntries = entries.where((e) => e.costPerKm > 0).toList();
        if (validEntries.isEmpty) {
          return _EmptyChart(message: 'Log fuel to see cost per km');
        }

        final spots = <FlSpot>[];
        for (var i = 0; i < validEntries.length; i++) {
          spots.add(FlSpot(i.toDouble(), validEntries[i].costPerKm));
        }

        return _ChartContainer(
          title: 'Cost per km',
          subtitle: '₹/km per refill',
          color: AppTheme.accentPurple,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.textMuted.withAlpha(30),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      '₹${value.toInt()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.accentPurple,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentPurple.withAlpha(40),
                        AppTheme.accentPurple.withAlpha(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}

/// Cumulative Distance Line Chart.
class CumulativeDistanceChart extends ConsumerWidget {
  const CumulativeDistanceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(allTripsProvider);

    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return _EmptyChart(message: 'Log trips to see cumulative distance');
        }

        // Sort trips chronologically (oldest first)
        final sorted = trips.reversed.toList();
        final spots = <FlSpot>[];
        double cumulative = 0;

        for (var i = 0; i < sorted.length; i++) {
          cumulative += sorted[i].distanceKm;
          spots.add(FlSpot(i.toDouble(), cumulative));
        }

        if (spots.isEmpty) {
          return _EmptyChart(message: 'Log trips to see cumulative distance');
        }

        return _ChartContainer(
          title: 'Cumulative Distance',
          subtitle: 'Total km over time',
          color: AppTheme.accentCyan,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.textMuted.withAlpha(30),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: AppTheme.accentCyan,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentCyan.withAlpha(40),
                        AppTheme.accentCyan.withAlpha(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}

/// Fuel Consumption Area Chart.
class FuelConsumptionChart extends ConsumerWidget {
  const FuelConsumptionChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _EmptyChart(message: 'Log fuel to see consumption');
        }

        final last10 = entries.take(10).toList().reversed.toList();
        final spots = <FlSpot>[];
        for (var i = 0; i < last10.length; i++) {
          spots.add(FlSpot(i.toDouble(), last10[i].litresFilled));
        }

        return _ChartContainer(
          title: 'Fuel Consumption',
          subtitle: 'Litres per refill (last 10)',
          color: AppTheme.accentOrange,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.textMuted.withAlpha(30),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}L',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.accentOrange,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentOrange.withAlpha(60),
                        AppTheme.accentOrange.withAlpha(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}

/// Petrol Price Trend Line Chart.
class PetrolPriceTrendChart extends ConsumerWidget {
  const PetrolPriceTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _EmptyChart(message: 'Log fuel to see price trend');
        }

        final last10 = entries.take(10).toList().reversed.toList();
        final spots = <FlSpot>[];
        for (var i = 0; i < last10.length; i++) {
          spots.add(FlSpot(i.toDouble(), last10[i].pricePerLitre));
        }

        return _ChartContainer(
          title: 'Petrol Price Trend',
          subtitle: '₹/L (last 10 refills)',
          color: AppTheme.accentRed,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.textMuted.withAlpha(30),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      '₹${value.toInt()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.accentRed,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3,
                      color: AppTheme.accentRed,
                      strokeWidth: 2,
                      strokeColor: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}

/// Monthly Distance Bar Chart.
class MonthlyDistanceChart extends ConsumerWidget {
  const MonthlyDistanceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(allTripsProvider);

    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return _EmptyChart(message: 'Log trips to see monthly distance');
        }

        // Group by month
        final monthlyDistance = <String, double>{};
        for (final trip in trips) {
          final key = '${trip.timestamp.year}-${trip.timestamp.month.toString().padLeft(2, '0')}';
          monthlyDistance[key] = (monthlyDistance[key] ?? 0) + trip.distanceKm;
        }

        final sortedMonths = monthlyDistance.keys.toList()..sort();
        final last6Months = sortedMonths.length > 6 ? sortedMonths.sublist(sortedMonths.length - 6) : sortedMonths;

        final barGroups = <BarChartGroupData>[];
        for (var i = 0; i < last6Months.length; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: monthlyDistance[last6Months[i]]!,
                  color: AppTheme.accentCyan,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          );
        }

        return _ChartContainer(
          title: 'Monthly Distance',
          subtitle: 'Last 6 months',
          color: AppTheme.accentCyan,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (barGroups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b) * 1.2).clamp(50, 1000),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= last6Months.length) return const SizedBox();
                      final month = last6Months[value.toInt()];
                      return Text(
                        month?.split('-').last ?? '',
                        style: Theme.of(context).textTheme.labelSmall,
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}
