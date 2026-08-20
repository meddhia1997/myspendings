import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/database_providers.dart';
import '../../../shared/providers/insights_providers.dart';
import '../../../shared/responsive/breakpoints.dart';
import '../../../shared/widgets/icon_catalog.dart';
import '../../../shared/widgets/money_format.dart';
import '../../../shared/widgets/total_balance_banner.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final totalsAsync = ref.watch(categoryTotalsProvider);
    final dailyAsync = ref.watch(dailyTotalsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month + 1),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const TotalBalanceBanner(),
      ),
      body: totalsAsync.when(
        data: (totals) {
          if (totals.isEmpty) {
            return _EmptyState(scheme: scheme, month: month);
          }

          final grandTotal = totals.fold<int>(
            0,
            (sum, t) => sum + t.totalMinor,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
            children: [
              ResponsiveBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _monthLabel(month),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatMoney(grandTotal, 'TND')} spent across ${totals.length} categories',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'By category',
                      child: SizedBox(
                        height: 220,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 42,
                                  sections: [
                                    for (final t in totals)
                                      PieChartSectionData(
                                        value: t.totalMinor.toDouble(),
                                        color: Color(
                                          t.category?.colorValue ?? 0xFF757575,
                                        ),
                                        radius: 46,
                                        showTitle: false,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  for (final t in totals.take(6))
                                    _LegendRow(
                                      total: t,
                                      grandTotal: grandTotal,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Daily spending',
                      child: SizedBox(
                        height: 160,
                        child: dailyAsync.when(
                          data: (daily) => _DailyTrendChart(
                            daily: daily,
                            color: scheme.primary,
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Breakdown',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _CategoryTable(totals: totals, grandTotal: grandTotal),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  String _monthLabel(DateTime month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.total, required this.grandTotal});

  final CategoryTotal total;
  final int grandTotal;

  @override
  Widget build(BuildContext context) {
    final color = Color(total.category?.colorValue ?? 0xFF757575);
    final percent = grandTotal == 0 ? 0 : (total.totalMinor / grandTotal * 100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              total.category?.name ?? 'Uncategorized',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTrendChart extends StatelessWidget {
  const _DailyTrendChart({required this.daily, required this.color});

  final List<DailyTotal> daily;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = daily.fold<int>(
      0,
      (m, d) => d.expenseMinor > m ? d.expenseMinor : m,
    );
    if (maxValue == 0) {
      return const Center(child: Text('No expenses logged yet this month.'));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          show: true,
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final d in daily)
                FlSpot(d.day.toDouble(), d.expenseMinor / 100),
            ],
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTable extends StatelessWidget {
  const _CategoryTable({required this.totals, required this.grandTotal});

  final List<CategoryTotal> totals;
  final int grandTotal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var i = 0; i < totals.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            _CategoryTableRow(total: totals[i], grandTotal: grandTotal),
          ],
        ],
      ),
    );
  }
}

class _CategoryTableRow extends StatelessWidget {
  const _CategoryTableRow({required this.total, required this.grandTotal});

  final CategoryTotal total;
  final int grandTotal;

  @override
  Widget build(BuildContext context) {
    final color = Color(total.category?.colorValue ?? 0xFF757575);
    final percent = grandTotal == 0 ? 0 : (total.totalMinor / grandTotal * 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            foregroundColor: color,
            child: Icon(
              iconForKey(total.category?.iconKey ?? 'category'),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total.category?.name ?? 'Uncategorized',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${total.count} transaction${total.count == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(total.totalMinor, 'TND'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scheme, required this.month});

  final ColorScheme scheme;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insights_rounded,
              size: 36,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No expenses to analyze yet',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Log a few expenses to see charts here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
