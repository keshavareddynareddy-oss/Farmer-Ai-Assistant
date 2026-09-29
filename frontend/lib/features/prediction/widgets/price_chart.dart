import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:crop_price_predictor/l10n/app_localizations.dart';

import '../../../models/prediction_model.dart';

class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.points,
  });

  final List<PredictionPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isRising =
        points.length > 1 && points.last.price > points.first.price;
    final trendColor = points.length < 2 || isRising
        ? colorScheme.primary
        : colorScheme.secondary;

    final spots = points
        .map(
          (point) => FlSpot(point.day.toDouble(), point.price),
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.chartPriceForecastTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Icon(
                  points.length < 2
                      ? Icons.horizontal_rule_rounded
                      : isRising
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                  color: trendColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.55,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: trendColor,
                      belowBarData: BarAreaData(
                        show: true,
                        color: trendColor.withValues(alpha: 0.12),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
