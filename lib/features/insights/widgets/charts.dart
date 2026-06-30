import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:fuel_tracker_app/services/achievement_service.dart';
import 'package:fuel_tracker_app/services/milestone_service.dart';

import 'package:fuel_tracker_app/app/theme.dart';
import 'package:fuel_tracker_app/providers/app_providers.dart';
import 'package:fuel_tracker_app/models/route_type.dart';
import 'package:fuel_tracker_app/utils/formatters.dart';
import 'package:fuel_tracker_app/core/analytics/mileage_engine.dart';
import 'package:fuel_tracker_app/core/analytics/expense_forecaster.dart';

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
  final double? height;

  const _ChartContainer({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
          if (height != null) Expanded(child: child) else child,
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
  final String? message;
  const _ErrorChart({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message ?? 'Error loading chart', style: Theme.of(context).textTheme.bodySmall),
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
          color: AppTheme.accentTeal,
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
                  color: AppTheme.accentTeal,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentTeal.withAlpha(40),
                        AppTheme.accentTeal.withAlpha(0),
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
                  color: AppTheme.accentTeal,
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
          color: AppTheme.accentTeal,
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

/// Fuel Tank Level Gauge Widget.
class FuelTankLevelGauge extends ConsumerWidget {
  const FuelTankLevelGauge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelAsync = ref.watch(fuelRemainingProvider);
    final profileAsync = ref.watch(vehicleProfileProvider);

    return fuelAsync.when(
      data: (fuel) {
        final capacity = profileAsync.valueOrNull?.tankCapacityL ?? 5.3;
        final fraction = (fuel / capacity).clamp(0.0, 1.0);
        final levelPercent = (fraction * 100).round();

        Color gaugeColor = AppTheme.accentGreen;
        if (fraction < 0.15) {
          gaugeColor = AppTheme.accentRed;
        } else if (fraction < 0.4) {
          gaugeColor = AppTheme.accentOrange;
        }

        return _ChartContainer(
          title: 'Fuel Tank Level',
          subtitle: 'Remaining fuel vs capacity',
          color: gaugeColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: fraction,
                          strokeWidth: 8,
                          backgroundColor: gaugeColor.withAlpha(20),
                          color: gaugeColor,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$levelPercent%',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: gaugeColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            '${Formatters.litres(fuel)} / ${Formatters.litres(capacity)}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
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

/// Vehicle Health Score Gauge Widget.
class VehicleHealthScoreGauge extends ConsumerWidget {
  const VehicleHealthScoreGauge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(vehicleHealthScoreProvider);

    return scoreAsync.when(
      data: (score) {
        final scorePercent = (score * 100).round();
        Color scoreColor = AppTheme.accentGreen;
        if (score < 0.6) {
          scoreColor = AppTheme.accentRed;
        } else if (score < 0.85) {
          scoreColor = AppTheme.accentOrange;
        }

        return _ChartContainer(
          title: 'Health Diagnostics',
          subtitle: 'Composite vehicle health index',
          color: scoreColor,
          child: Center(
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: score,
                      strokeWidth: 8,
                      backgroundColor: scoreColor.withAlpha(20),
                      color: scoreColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$scorePercent',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Diagnostics',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}

/// Calendar Heatmap Widget showing daily ride intensities.
class CalendarHeatmap extends ConsumerWidget {
  const CalendarHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(allTripsProvider);

    return tripsAsync.when(
      data: (trips) {
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final startDayOfWeek = DateTime(now.year, now.month, 1).weekday; // 1 = Monday, 7 = Sunday

        // Group distances by day of current month
        final dailyDistances = Map<int, double>.fromIterable(
          List.generate(daysInMonth, (i) => i + 1),
          value: (_) => 0.0,
        );

        for (final trip in trips) {
          if (trip.timestamp.year == now.year && trip.timestamp.month == now.month) {
            dailyDistances[trip.timestamp.day] = (dailyDistances[trip.timestamp.day] ?? 0.0) + trip.distanceKm;
          }
        }

        final maxDistance = dailyDistances.values.fold<double>(1.0, (m, d) => d > m ? d : m);

        // Calendar Grid layout elements
        final gridItems = <Widget>[];

        // Empty spaces for padding before day 1
        final spaces = (startDayOfWeek - 1) % 7;
        for (var i = 0; i < spaces; i++) {
          gridItems.add(const SizedBox());
        }

        // Calendar days
        for (var day = 1; day <= daysInMonth; day++) {
          final distance = dailyDistances[day] ?? 0.0;
          final intensity = maxDistance > 0 ? (distance / maxDistance).clamp(0.0, 1.0) : 0.0;
          
          Color cellColor = Colors.transparent;
          if (distance > 0) {
            cellColor = AppTheme.accentGreen.withAlpha((50 + (intensity * 205)).round());
          }

          gridItems.add(
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: distance > 0 ? Colors.transparent : Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
              ),
              child: Text(
                '$day',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: distance > 0 ? FontWeight.bold : FontWeight.normal,
                      color: distance > 0 ? Colors.white : AppTheme.textMuted,
                    ),
              ),
            ),
          );
        }

        return _ChartContainer(
          title: 'Riding Calendar Heatmap',
          subtitle: 'Daily distance logged this month',
          color: AppTheme.accentGreen,
          child: Column(
            children: [
              // Weekday labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Heatmap grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: gridItems,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}

/// Fuel Economy Distribution Histogram.
class FuelEconomyDistributionChart extends ConsumerWidget {
  const FuelEconomyDistributionChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        final validEntries = entries.where((e) => e.calculatedMileage > 0).toList();
        if (validEntries.isEmpty) {
          return _EmptyChart(message: 'Log refills to view mileage distribution');
        }

        // Setup buckets
        int under30 = 0;
        int t30to35 = 0;
        int t35to40 = 0;
        int t40to45 = 0;
        int over45 = 0;

        for (final entry in validEntries) {
          final mileage = entry.calculatedMileage;
          if (mileage < 30) {
            under30++;
          } else if (mileage < 35) {
            t30to35++;
          } else if (mileage < 40) {
            t35to40++;
          } else if (mileage < 45) {
            t40to45++;
          } else {
            over45++;
          }
        }

        final counts = [under30, t30to35, t35to40, t40to45, over45];
        final labels = ['<30', '30-35', '35-40', '40-45', '45+'];

        final barGroups = List.generate(5, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: counts[index].toDouble(),
                color: AppTheme.accentOrange,
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        });

        final maxVal = counts.reduce((a, b) => a > b ? a : b).toDouble();

        return _ChartContainer(
          title: 'Mileage Distribution',
          subtitle: 'Refill occurrences per mileage range (km/L)',
          color: AppTheme.accentOrange,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal > 0 ? maxVal + 1 : 5,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
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
                      final idx = value.toInt();
                      if (idx < 0 || idx >= labels.length) return const SizedBox();
                      return Text(
                        labels[idx],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
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

/// Expense Breakdown Pie Chart.
class ExpenseBreakdownChart extends ConsumerWidget {
  const ExpenseBreakdownChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);
    final serviceAsync = ref.watch(allServiceRecordsProvider);

    return entriesAsync.when(
      data: (entries) {
        return serviceAsync.when(
          data: (records) {
            final fuelTotal = entries.fold<double>(0.0, (sum, e) => sum + (e.amountPaid ?? 0));
            final serviceTotal = records.fold<double>(0.0, (sum, r) => sum + (r.cost ?? 0));

            if (fuelTotal == 0 && serviceTotal == 0) {
              return _EmptyChart(message: 'Log expenses to see breakdown');
            }

            final total = fuelTotal + serviceTotal;
            final fuelPercent = total > 0 ? (fuelTotal / total * 100).round() : 0;
            final servicePercent = total > 0 ? (serviceTotal / total * 100).round() : 0;

            return _ChartContainer(
              title: 'Expense Split',
              subtitle: 'Fuel refills vs Service records spend',
              color: AppTheme.accentPurple,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 30,
                        sections: [
                          if (fuelTotal > 0)
                            PieChartSectionData(
                              value: fuelTotal,
                              title: '$fuelPercent%',
                              color: AppTheme.accentOrange,
                              radius: 35,
                              titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          if (serviceTotal > 0)
                            PieChartSectionData(
                              value: serviceTotal,
                              title: '$servicePercent%',
                              color: AppTheme.accentPurple,
                              radius: 35,
                              titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendItem(color: AppTheme.accentOrange, label: 'Fuel: ₹${fuelTotal.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      _LegendItem(color: AppTheme.accentPurple, label: 'Service: ₹${serviceTotal.toStringAsFixed(0)}'),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const _LoadingChart(),
          error: (_, __) => const _ErrorChart(),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Visual Refill History Timeline Chart.
class RefillHistoryTimelineChart extends ConsumerWidget {
  const RefillHistoryTimelineChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _EmptyChart(message: 'Log fuel refills to populate timeline');
        }

        final recent = entries.take(3).toList();

        return _ChartContainer(
          title: 'Refill Timeline',
          subtitle: 'Visual summary of recent fills',
          color: AppTheme.accentOrange,
          child: ListView.builder(
            itemCount: recent.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final entry = recent[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (index < recent.length - 1)
                        Container(
                          width: 2,
                          height: 38,
                          color: AppTheme.accentOrange.withAlpha(50),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${entry.amountPaid?.toStringAsFixed(0) ?? "0"} Refill',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              Formatters.dateShort(entry.timestamp),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        Text(
                          '${Formatters.litres(entry.litresFilled)} @ ₹${entry.pricePerLitre.toStringAsFixed(1)}/L  |  ${entry.calculatedMileage > 0 ? "${entry.calculatedMileage.toStringAsFixed(1)} km/L" : "Calculating..."}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (_, __) => const _ErrorChart(),
    );
  }
}

/// AI Insights Grid Dashboard.
class AiInsightsGrid extends ConsumerWidget {
  const AiInsightsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);
    final healthAsync = ref.watch(vehicleHealthScoreProvider);
    final predictionAsync = ref.watch(refillPredictionProvider);

    return _ChartContainer(
      title: 'AI Diagnostic Insights',
      subtitle: 'Rule-based analytics & pattern tracking',
      color: AppTheme.accentPurple,
      child: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _InsightBlock(
                  icon: Icons.local_gas_station,
                  title: 'Refill Due',
                  value: predictionAsync.when(
                    data: (p) => p.daysRemaining > 0 ? 'In ${p.daysRemaining} days' : 'Refill soon!',
                    loading: () => '...',
                    error: (_, __) => 'N/A',
                  ),
                  color: AppTheme.accentOrange,
                ),
                _InsightBlock(
                  icon: Icons.speed,
                  title: 'Avg Mileage',
                  value: entriesAsync.when(
                    data: (entries) {
                      final avg = MileageEngine.rollingAverage(entries);
                      return avg > 0 ? '${avg.toStringAsFixed(1)} km/L' : '—';
                    },
                    loading: () => '...',
                    error: (_, __) => '—',
                  ),
                  color: AppTheme.accentGreen,
                ),
                _InsightBlock(
                  icon: Icons.healing,
                  title: 'Health Index',
                  value: healthAsync.when(
                    data: (score) => '${(score * 100).round()}%',
                    loading: () => '...',
                    error: (_, __) => '—',
                  ),
                  color: AppTheme.accentBlue,
                ),
                _InsightBlock(
                  icon: Icons.trending_down,
                  title: 'Mileage Drop',
                  value: entriesAsync.when(
                    data: (entries) => MileageEngine.isMileageDrop(entries) ? 'Detected!' : 'Normal',
                    loading: () => '...',
                    error: (_, __) => '—',
                  ),
                  color: AppTheme.accentRed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InsightBlock({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  void _showInsightDetails(BuildContext context) {
    String header = '';
    String observation = '';
    List<String> causes = [];
    List<String> recommendations = [];
    
    if (title == 'Refill Due') {
      header = 'Refill Prediction Analysis';
      observation = 'Your fuel tank is estimated to hit reserve level based on your typical daily commute patterns.';
      causes = [
        'Riding pattern predicts standard college commute trips this week.',
        'Current remaining fuel level is low.',
      ];
      recommendations = [
        'Refuel at BP Makali on your next return commute trip.',
        'Avoid letting the fuel drop below reserve level to maintain fuel pump health.',
      ];
    } else if (title == 'Avg Mileage') {
      header = 'Average Mileage Analysis';
      observation = 'Your current rolling average mileage is calculated over the last 5 fuel entries.';
      causes = [
        'Commuting style, route consistency, and riding speeds.',
        'Vehicle health and service compliance status.',
      ];
      recommendations = [
        'Maintain a steady speed of 40-50 km/h on highway stretches.',
        'Ensure tyre pressure is maintained at recommended levels (22/36 PSI).',
        'Clean/change the air filter if it is clogged.',
      ];
    } else if (title == 'Health Index') {
      header = 'Vehicle Health Diagnostics';
      observation = 'Health score is calculated based on mileage stability (30%), service compliance (40%), and fuel efficiency (30%).';
      causes = [
        'Maintenance interval adherence.',
        'Mileage consistency across refill cycles.',
      ];
      recommendations = [
        'Clean the spark plug and adjust chain tension during general service.',
        'Change engine oil every 3,000 km for engine longevity.',
        'Log services regularly in the app to maintain an accurate health index.',
      ];
    } else if (title == 'Mileage Drop') {
      header = 'Mileage Drop Analysis';
      observation = value == 'Detected!' 
          ? 'Alert: Your latest fill shows a mileage drop of > 10% compared to your rolling average!'
          : 'Your mileage stability is healthy and within normal boundaries.';
      causes = value == 'Detected!' ? [
        'Under-inflated tyres causing higher road friction.',
        'Dirty air filter or poor petrol quality.',
        'High throttle variation or heavy payloads.',
      ] : [
        'Consistent riding speeds and throttle usage.',
        'Tyres and air filter are in good condition.',
      ];
      recommendations = [
        'Check tyre pressure (front 22 psi, rear 36 psi) immediately.',
        'Check and clean the air filter if it hasn\'t been serviced recently.',
        'Ensure you refill with quality fuel from trusted pumps like BP Makali.',
      ];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    header,
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              'Observation',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              observation,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Potential Causes',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...causes.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(c, style: Theme.of(ctx).textTheme.bodyMedium)),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            Text(
              'Recommendations',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
            ),
            const SizedBox(height: 8),
            ...recommendations.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✓ ', style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(r, style: Theme.of(ctx).textTheme.bodyMedium)),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                ),
                child: const Text('Dismiss'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showInsightDetails(context),
        borderRadius: BorderRadius.circular(12),
        highlightColor: color.withAlpha(20),
        splashColor: color.withAlpha(30),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Monthly Expense Forecast Area Chart.
class MonthlyExpenseForecastChart extends ConsumerWidget {
  const MonthlyExpenseForecastChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _EmptyChart(message: 'Log expenses to see monthly forecast');
        }

        final now = DateTime.now();
        final currentMonth = now.month;
        final currentYear = now.year;

        // Cumulative spent daily
        final dailySpent = <int, double>{};
        for (var day = 1; day <= 30; day++) {
          dailySpent[day] = 0.0;
        }

        for (final entry in entries) {
          if (entry.timestamp.month == currentMonth && entry.timestamp.year == currentYear) {
            final day = entry.timestamp.day.clamp(1, 30);
            dailySpent[day] = (dailySpent[day] ?? 0.0) + (entry.amountPaid ?? 0.0);
          }
        }

        double cumulative = 0.0;
        final actualSpots = <FlSpot>[];
        for (var day = 1; day <= now.day; day++) {
          cumulative += dailySpent[day] ?? 0.0;
          actualSpots.add(FlSpot(day.toDouble(), cumulative));
        }

        final forecastTotal = ExpenseForecaster.forecastMonthlyExpense(entries);
        final forecastSpots = <FlSpot>[];
        for (var day = 1; day <= 30; day++) {
          // Linearly project the forecast
          final projectedVal = (forecastTotal / 30) * day;
          forecastSpots.add(FlSpot(day.toDouble(), projectedVal));
        }

        final maxVal = (forecastTotal > cumulative ? forecastTotal : cumulative).clamp(100.0, double.infinity);

        return _ChartContainer(
          title: 'Spend & Forecast',
          subtitle: 'Actual spend vs linear month forecast',
          color: AppTheme.accentOrange,
          child: LineChart(
            LineChartData(
              maxY: maxVal,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.textMuted.withAlpha(20),
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
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: 5,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Forecast line
                LineChartBarData(
                  spots: forecastSpots,
                  isCurved: false,
                  color: AppTheme.accentOrange.withAlpha(80),
                  barWidth: 2,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),
                // Actual spend line
                LineChartBarData(
                  spots: actualSpots,
                  isCurved: true,
                  color: AppTheme.accentOrange,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.accentOrange.withAlpha(15),
                  ),
                  dotData: const FlDotData(show: false),
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

/// Achievements Badge Grid.
class AchievementsGrid extends ConsumerWidget {
  const AchievementsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return achievementsAsync.when(
      data: (achievements) {
        return _ChartContainer(
          title: 'Achievements & Badges',
          subtitle: 'Milestone badges unlocked by your riding',
          color: AppTheme.accentGreen,
          height: null,
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.3,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final ach = achievements[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ach.isUnlocked
                          ? AppTheme.accentGreen.withAlpha(10)
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ach.isUnlocked
                            ? AppTheme.accentGreen.withAlpha(35)
                            : Theme.of(context).colorScheme.outline.withAlpha(50),
                        width: ach.isUnlocked ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ach.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            if (ach.isUnlocked)
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.accentGreen,
                                size: 16,
                              )
                            else
                              Text(
                                '${(ach.progress * 100).toInt()}%',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ach.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: ach.isUnlocked ? AppTheme.accentGreen : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ach.description,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 8,
                                    color: AppTheme.textMuted,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (e, s) => _ErrorChart(message: 'Error loading achievements: $e'),
    );
  }
}

/// Google Photos-style AI Timeline of Milestones.
class AiTimelineFeed extends ConsumerWidget {
  const AiTimelineFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(milestonesProvider);

    return milestonesAsync.when(
      data: (milestones) {
        if (milestones.isEmpty) {
          return const _EmptyChart(message: 'Log rides or fuel refills to start your timeline!');
        }

        return _ChartContainer(
          title: 'AI Riding Milestones',
          subtitle: 'History feed of accomplishments & summaries',
          color: AppTheme.accentBlue,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              final ms = milestones[index];
              final formattedDate = "${ms.date.day}/${ms.date.month}/${ms.date.year}";

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            ms.icon,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (index < milestones.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: Theme.of(context).colorScheme.outline.withAlpha(100),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withAlpha(55),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    ms.title,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppTheme.textMuted,
                                          fontSize: 9,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ms.subtitle,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (e, s) => _ErrorChart(message: 'Error loading milestones: $e'),
    );
  }
}

/// Scatter Plot Chart: Petrol Price vs Cost per km.
class ScatterPlotPriceVsCostChart extends ConsumerWidget {
  const ScatterPlotPriceVsCostChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        final valid = entries.where((e) => e.costPerKm > 0 && e.pricePerLitre > 0).toList();
        if (valid.isEmpty) {
          return const _EmptyChart(message: 'Log refills with mileage to see scatter plot');
        }

        final spots = valid.map((e) => ScatterSpot(e.costPerKm, e.pricePerLitre)).toList();

        double minX = valid.map((e) => e.costPerKm).reduce(math.min);
        double maxX = valid.map((e) => e.costPerKm).reduce(math.max);
        double minY = valid.map((e) => e.pricePerLitre).reduce(math.min);
        double maxY = valid.map((e) => e.pricePerLitre).reduce(math.max);

        // Add padding
        minX = (minX - 0.5).clamp(0.0, double.infinity);
        maxX = maxX + 0.5;
        minY = (minY - 5.0).clamp(0.0, double.infinity);
        maxY = maxY + 5.0;

        return _ChartContainer(
          title: 'Price vs Cost per km',
          subtitle: 'Petrol Price (₹/L) vs Cost/km (₹) scatter analysis',
          color: AppTheme.accentOrange,
          child: SizedBox(
            height: 180,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: spots,
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (val) => FlLine(color: AppTheme.textMuted.withAlpha(15)),
                  getDrawingVerticalLine: (val) => FlLine(color: AppTheme.textMuted.withAlpha(15)),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) => Text(
                        '₹${value.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) => Text(
                        '₹${value.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                scatterTouchData: ScatterTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (e, _) => _ErrorChart(message: 'Error loading scatter chart: $e'),
    );
  }
}

/// Radar Chart: Vehicle Health Metrics (Efficiency, Maintenance, Consistency).
class RadarHealthMetricsChart extends ConsumerWidget {
  const RadarHealthMetricsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);
    final profileAsync = ref.watch(vehicleProfileProvider);
    final tripsAsync = ref.watch(allTripsProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        return entriesAsync.when(
          data: (entries) {
            return tripsAsync.when(
              data: (trips) {
                // 1. Efficiency: rolling avg mileage / 45.0 (Activa target)
                final avgMileage = MileageEngine.rollingAverage(entries);
                final efficiencyScore = (avgMileage / 45.0).clamp(0.0, 1.0);

                // 2. Maintenance: distance since last service / interval
                final totalDistance = trips.fold<double>(0.0, (s, t) => s + t.distanceKm);
                final odometer = (profile.initialOdometer ?? 0.0) + totalDistance;
                final distSinceService = (odometer - profile.lastServiceKm).clamp(0.0, double.infinity);
                final maintenanceScore = (1.0 - (distSinceService / profile.serviceIntervalKm)).clamp(0.0, 1.0);

                // 3. Consistency: mileage confidence score
                final consistencyScore = MileageEngine.calculateMileageConfidence(entries);

                return _ChartContainer(
                  title: 'Vehicle Performance Radar',
                  subtitle: 'Multi-axis health & consistency metrics',
                  color: AppTheme.accentPurple,
                  child: SizedBox(
                    height: 200,
                    child: RadarChart(
                      RadarChartData(
                        dataSets: [
                          RadarDataSet(
                            fillColor: AppTheme.accentPurple.withAlpha(40),
                            borderColor: AppTheme.accentPurple,
                            entryRadius: 3,
                            borderWidth: 2,
                            dataEntries: [
                              RadarEntry(value: efficiencyScore * 100),
                              RadarEntry(value: maintenanceScore * 100),
                              RadarEntry(value: consistencyScore * 100),
                            ],
                          ),
                        ],
                        radarShape: RadarShape.polygon,
                        getTitle: (index, angle) {
                          switch (index) {
                            case 0:
                              return RadarChartTitle(text: 'Efficiency (${(efficiencyScore * 100).round()}%)', angle: angle);
                            case 1:
                              return RadarChartTitle(text: 'Maintenance (${(maintenanceScore * 100).round()}%)', angle: angle);
                            case 2:
                              return RadarChartTitle(text: 'Consistency (${(consistencyScore * 100).round()}%)', angle: angle);
                            default:
                              return const RadarChartTitle(text: '');
                          }
                        },
                        tickCount: 4,
                        ticksTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8, color: AppTheme.textMuted),
                        gridBorderData: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(80)),
                        tickBorderData: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(40)),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const _LoadingChart(),
              error: (e, _) => _ErrorChart(message: 'Error: $e'),
            );
          },
          loading: () => const _LoadingChart(),
          error: (e, _) => _ErrorChart(message: 'Error: $e'),
        );
      },
      loading: () => const _LoadingChart(),
      error: (e, _) => _ErrorChart(message: 'Error: $e'),
    );
  }
}

/// Sankey Diagram Custom Flow Painter
class SankeyPainter extends CustomPainter {
  final double totalSpent;
  final Map<String, double> routeSpents;
  final BuildContext context;

  SankeyPainter({
    required this.totalSpent,
    required this.routeSpents,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalSpent <= 0) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );
    final valueStyle = TextStyle(
      color: AppTheme.textMuted,
      fontSize: 9,
    );

    final leftNodeWidth = 65.0;
    final rightNodeWidth = 65.0;
    final nodeHeight = 35.0;

    // Draw Left Node (Total Spend)
    final leftX = 10.0;
    final leftY = size.height / 2 - nodeHeight / 2;
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(leftX, leftY, leftNodeWidth, nodeHeight),
      const Radius.circular(6),
    );
    final leftPaint = Paint()..color = AppTheme.accentOrange.withAlpha(200);
    canvas.drawRRect(leftRect, leftPaint);

    _drawText(canvas, 'Total Spent', Offset(leftX + 6, leftY + 6), textStyle.copyWith(fontSize: 8.5));
    _drawText(canvas, '₹${totalSpent.toStringAsFixed(0)}', Offset(leftX + 6, leftY + 18), valueStyle);

    // Draw Right Nodes and Flows
    final rightX = size.width - rightNodeWidth - 10.0;
    final rightItems = routeSpents.entries.where((e) => e.value > 0).toList();
    if (rightItems.isEmpty) return;

    final totalRightSpace = size.height;
    final gap = 12.0;
    final totalHeightForNodes = (rightItems.length * nodeHeight) + ((rightItems.length - 1) * gap);
    double currentRightY = (totalRightSpace - totalHeightForNodes) / 2;

    double leftFlowAccumulator = 0.0;

    for (int i = 0; i < rightItems.length; i++) {
      final item = rightItems[i];
      final itemSpent = item.value;
      final fraction = itemSpent / totalSpent;

      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rightX, currentRightY, rightNodeWidth, nodeHeight),
        const Radius.circular(6),
      );
      final rPaint = Paint()..color = AppTheme.accentBlue.withAlpha(200);
      canvas.drawRRect(rRect, rPaint);

      _drawText(canvas, item.key, Offset(rightX + 4, currentRightY + 6), textStyle.copyWith(fontSize: 8.0));
      _drawText(canvas, '₹${itemSpent.toStringAsFixed(0)}', Offset(rightX + 4, currentRightY + 18), valueStyle);

      final flowThickness = nodeHeight * fraction;
      final flowLeftY = leftY + leftFlowAccumulator + (flowThickness / 2);
      final flowRightY = currentRightY + (nodeHeight / 2);

      final path = Path();
      path.moveTo(leftX + leftNodeWidth, flowLeftY - flowThickness / 2);

      final controlX1 = (leftX + leftNodeWidth) + (rightX - (leftX + leftNodeWidth)) / 2;
      final controlX2 = controlX1;

      path.cubicTo(
        controlX1, flowLeftY - flowThickness / 2,
        controlX2, flowRightY - flowThickness / 2,
        rightX, flowRightY - flowThickness / 2,
      );
      path.lineTo(rightX, flowRightY + flowThickness / 2);
      path.cubicTo(
        controlX2, flowRightY + flowThickness / 2,
        controlX1, flowLeftY + flowThickness / 2,
        leftX + leftNodeWidth, flowLeftY + flowThickness / 2,
      );
      path.close();

      final flowPaint = Paint()
        ..color = AppTheme.accentBlue.withAlpha((80 * fraction + 30).round())
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, flowPaint);

      leftFlowAccumulator += flowThickness;
      currentRightY += nodeHeight + gap;
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Sankey Diagram: Fuel -> Route -> Cost
class SankeyFuelFlowChart extends ConsumerWidget {
  const SankeyFuelFlowChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(allTripsProvider);
    final entriesAsync = ref.watch(allFuelEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        return tripsAsync.when(
          data: (trips) {
            final totalSpent = entries.fold<double>(0.0, (s, e) => s + (e.amountPaid ?? 0.0));

            final routeDists = <String, double>{};
            for (final t in trips) {
              final label = t.routeType.label;
              routeDists[label] = (routeDists[label] ?? 0.0) + t.distanceKm;
            }

            final totalDist = routeDists.values.fold<double>(0.0, (s, d) => s + d);

            final routeSpents = <String, double>{};
            if (totalDist > 0) {
              routeDists.forEach((key, dist) {
                routeSpents[key] = (dist / totalDist) * totalSpent;
              });
            }

            return _ChartContainer(
              title: 'Fuel Flow Sankey',
              subtitle: 'Apportioning total fuel expense by route distances',
              color: AppTheme.accentBlue,
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: SankeyPainter(
                    totalSpent: totalSpent,
                    routeSpents: routeSpents,
                    context: context,
                  ),
                ),
              ),
            );
          },
          loading: () => const _LoadingChart(),
          error: (e, _) => _ErrorChart(message: 'Error: $e'),
        );
      },
      loading: () => const _LoadingChart(),
      error: (e, _) => _ErrorChart(message: 'Error: $e'),
    );
  }
}

/// Stacked Bar Chart: Stacked monthly distance comparison split by RouteType.
class StackedMonthlyDistanceChart extends ConsumerWidget {
  const StackedMonthlyDistanceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(allTripsProvider);

    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return const _EmptyChart(message: 'Log rides to see stacked comparison');
        }

        final monthlyData = <String, Map<String, double>>{};
        for (final t in trips) {
          final key = DateFormat('yyyy-MM').format(t.timestamp);
          final route = t.routeType.label;
          final mData = monthlyData.putIfAbsent(key, () => {});
          mData[route] = (mData[route] ?? 0.0) + t.distanceKm;
        }

        final sortedMonths = monthlyData.keys.toList()..sort();
        final recentMonths = sortedMonths.skip(math.max(0, sortedMonths.length - 6)).toList();

        final routeColors = {
          'College Going': AppTheme.accentGreen,
          'Returned Home': AppTheme.accentBlue,
          'Nearby Town': AppTheme.accentPurple,
          'Short Ride': AppTheme.accentOrange,
          'Custom Ride': AppTheme.textMuted,
        };

        final barGroups = <BarChartGroupData>[];
        for (int i = 0; i < recentMonths.length; i++) {
          final mKey = recentMonths[i];
          final routeDists = monthlyData[mKey] ?? {};

          double currentY = 0.0;
          final stackItems = <BarChartRodStackItem>[];

          routeDists.forEach((route, dist) {
            if (dist > 0) {
              final color = routeColors[route] ?? AppTheme.textMuted.withAlpha(100);
              stackItems.add(BarChartRodStackItem(currentY, currentY + dist, color));
              currentY += dist;
            }
          });

          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: currentY,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  rodStackItems: stackItems,
                  color: Colors.transparent,
                ),
              ],
            ),
          );
        }

        return _ChartContainer(
          title: 'Monthly Distance Breakdown',
          subtitle: 'Cumulative riding split by route type (last 6 months)',
          color: AppTheme.accentGreen,
          height: 320,
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: barGroups.isNotEmpty
                        ? barGroups.map((g) => g.barRods[0].toY).reduce(math.max) * 1.15
                        : 10.0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (val) => FlLine(color: AppTheme.textMuted.withAlpha(15)),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()} km',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= recentMonths.length) return const Text('');
                            final parts = recentMonths[idx].split('-');
                            final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormat('MMM').format(date),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: routeColors.entries.map((entry) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, color: entry.value),
                      const SizedBox(width: 4),
                      Text(entry.key, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (e, _) => _ErrorChart(message: 'Error: $e'),
    );
  }
}

/// AI Prediction Overlay: Actual Mileage vs Smooth Rolling Predicted Mileage.
class AiPredictionOverlayChart extends ConsumerWidget {
  const AiPredictionOverlayChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allFuelEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        final valid = entries.where((e) => e.calculatedMileage > 0).toList().reversed.toList();
        if (valid.length < 2) {
          return const _EmptyChart(message: 'Need 2+ fills to compare actual vs predicted mileage');
        }

        final actualSpots = <FlSpot>[];
        final predictedSpots = <FlSpot>[];

        for (int i = 0; i < valid.length; i++) {
          final idxDouble = i.toDouble();
          actualSpots.add(FlSpot(idxDouble, valid[i].calculatedMileage));

          final rolling = MileageEngine.rollingAverage(valid.take(i + 1).toList().reversed.toList());
          predictedSpots.add(FlSpot(idxDouble, rolling));
        }

        final allY = [...actualSpots, ...predictedSpots].map((s) => s.y).toList();
        final minY = allY.reduce(math.min) * 0.95;
        final maxY = allY.reduce(math.max) * 1.05;

        return _ChartContainer(
          title: 'Actual vs AI Predicted Mileage',
          subtitle: 'Actual per-refill mileage vs rolling smooth mileage overlay',
          color: AppTheme.accentOrange,
          height: 320,
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (val) => FlLine(color: AppTheme.textMuted.withAlpha(15)),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toStringAsFixed(1)}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= valid.length) return const Text('');
                            return Text('Fill ${idx + 1}', style: Theme.of(context).textTheme.labelSmall);
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: actualSpots,
                        isCurved: true,
                        color: AppTheme.accentOrange.withAlpha(130),
                        barWidth: 1.5,
                        dashArray: [4, 4],
                        dotData: const FlDotData(show: true),
                      ),
                      LineChartBarData(
                        spots: predictedSpots,
                        isCurved: true,
                        color: AppTheme.accentGreen,
                        barWidth: 3.0,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.accentGreen.withAlpha(15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 10, height: 2, color: AppTheme.accentGreen),
                  const SizedBox(width: 4),
                  Text('Rolling Target Trend', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(width: 16),
                  Container(width: 10, height: 2, color: AppTheme.accentOrange.withAlpha(130)),
                  const SizedBox(width: 4),
                  Text('Actual Refill Mileage', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const _LoadingChart(),
      error: (e, _) => _ErrorChart(message: 'Error: $e'),
    );
  }
}
