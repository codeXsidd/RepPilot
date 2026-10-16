import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:rep_pilot/core/constants.dart';
import 'package:rep_pilot/models/body_weight_entry.dart';

class WeightChart extends StatelessWidget {
  final List<BodyWeightEntry> entries;
  final List<({DateTime date, double average})> movingAveragePoints;
  final String weightUnit;

  const WeightChart({
    super.key,
    required this.entries,
    required this.movingAveragePoints,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final unitLabel = weightUnit == 'lb' ? 'lb' : 'kg';

    final rawSpots = _buildRawSpots();
    final avgSpots = _buildAvgSpots();

    final allValues = rawSpots.map((s) => s.y).toList();
    if (avgSpots.isNotEmpty) {
      allValues.addAll(avgSpots.map((s) => s.y));
    }
    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.15;
    final chartMinY = (minY - padding).floorToDouble();
    final chartMaxY = (maxY + padding).ceilToDouble();

    final minX = rawSpots.first.x;
    final maxX = rawSpots.last.x;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: chartMinY == chartMaxY ? chartMinY - 1 : chartMinY,
          maxY: chartMinY == chartMaxY ? chartMaxY + 1 : chartMaxY,
          gridData: FlGridData(
            horizontalInterval: _yInterval(chartMinY, chartMaxY),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _xInterval(minX, maxX),
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    value.toInt(),
                  );
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      DateFormat.MMMd().format(date),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: _yInterval(chartMinY, chartMaxY),
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      value.toStringAsFixed(0),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    spot.x.toInt(),
                  );
                  final label = spot.barIndex == 0 ? '' : '(avg) ';
                  return LineTooltipItem(
                    '$label${spot.y.toStringAsFixed(1)} $unitLabel\n'
                    '${DateFormat.yMMMd().format(date)}',
                    TextStyle(
                      color: theme.colorScheme.onInverseSurface,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: rawSpots,
              isCurved: false,
              color: theme.colorScheme.primary,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: theme.colorScheme.primary,
                      strokeWidth: 0,
                    ),
              ),
            ),
            if (avgSpots.length >= 2)
              LineChartBarData(
                spots: avgSpots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: theme.colorScheme.tertiary.withAlpha(180),
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildRawSpots() {
    return entries.map((e) {
      final x = e.date.millisecondsSinceEpoch.toDouble();
      final y = displayWeight(e.weightKg, weightUnit);
      return FlSpot(x, y);
    }).toList();
  }

  List<FlSpot> _buildAvgSpots() {
    return movingAveragePoints.map((p) {
      final x = p.date.millisecondsSinceEpoch.toDouble();
      final y = displayWeight(p.average, weightUnit);
      return FlSpot(x, y);
    }).toList();
  }

  double _xInterval(double minX, double maxX) {
    final range = maxX - minX;
    if (range <= 0) return 86400000;
    final days = range / 86400000;
    if (days <= 7) return 86400000;
    if (days <= 30) return 86400000 * 7;
    if (days <= 90) return 86400000 * 14;
    return 86400000 * 30;
  }

  double _yInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 2) return 0.5;
    if (range <= 10) return 2;
    if (range <= 30) return 5;
    return 10;
  }
}
