import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/providers/insights_providers.dart';
import '../../../shared/widgets/money_format.dart';

const _incomeColor = Color(0xFF4CAF7D);
const _expenseColor = Color(0xFFE1544C);

/// Day-by-day income vs. expense across the month, with real axis labels,
/// gridlines, and a touch tooltip — not just a bare line.
class SpendingTrendChart extends StatelessWidget {
  const SpendingTrendChart({super.key, required this.daily});

  final List<DailyTotal> daily;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxExpense = daily.fold<int>(0, (m, d) => d.expenseMinor > m ? d.expenseMinor : m);
    final maxIncome = daily.fold<int>(0, (m, d) => d.incomeMinor > m ? d.incomeMinor : m);
    final maxValue = (maxExpense > maxIncome ? maxExpense : maxIncome) / 100;

    if (maxValue == 0) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No activity logged yet this month.')),
      );
    }

    final yInterval = _niceInterval(maxValue);
    final maxY = (yInterval * ((maxValue / yInterval).ceil() + 1));
    final labelEvery = (daily.length / 6).ceil().clamp(1, daily.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: _incomeColor, label: 'Income'),
            const SizedBox(width: 16),
            _LegendDot(color: _expenseColor, label: 'Expense'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              minX: 1,
              maxX: daily.length.toDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: yInterval,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        _shortMoney(value),
                        style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final day = value.toInt();
                      if (day < 1 || day > daily.length) return const SizedBox.shrink();
                      if ((day - 1) % labelEvery != 0 && day != daily.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$day',
                          style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItems: (spots) => spots.map((spot) {
                    final isIncome = spot.barIndex == 0;
                    return LineTooltipItem(
                      'Day ${spot.x.toInt()}\n${isIncome ? 'Income' : 'Expense'}: '
                      '${formatMoney((spot.y * 100).round(), 'TND')}',
                      TextStyle(
                        color: scheme.onInverseSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                _line(daily.map((d) => d.incomeMinor).toList(), _incomeColor),
                _line(daily.map((d) => d.expenseMinor).toList(), _expenseColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _line(List<int> minorValues, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < minorValues.length; i++) FlSpot((i + 1).toDouble(), minorValues[i] / 100),
      ],
      isCurved: true,
      curveSmoothness: 0.25,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        checkToShowDot: (spot, _) => spot.y > 0,
        getDotPainter: (spot, percent, bar, index) =>
            FlDotCirclePainter(radius: 2.5, color: color, strokeWidth: 0),
      ),
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
    );
  }

  String _shortMoney(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  double _niceInterval(double maxValue) {
    final rough = maxValue / 4;
    if (rough <= 0) return 1;
    final magnitude = _pow10Floor(rough);
    final normalized = rough / magnitude;
    final niceNormalized = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    return niceNormalized * magnitude;
  }

  double _pow10Floor(double value) {
    var magnitude = 1.0;
    while (magnitude * 10 <= value) {
      magnitude *= 10;
    }
    while (magnitude > value) {
      magnitude /= 10;
    }
    return magnitude;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
