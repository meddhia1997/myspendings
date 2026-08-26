import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/database_providers.dart';
import '../../../shared/providers/insights_providers.dart';
import '../../../shared/responsive/breakpoints.dart';
import '../../../shared/widgets/icon_catalog.dart';
import '../../../shared/widgets/money_format.dart';
import '../../../shared/widgets/total_balance_banner.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/spending_trend_chart.dart';

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
                      child: CategoryPieChart(totals: totals, grandTotal: grandTotal),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Daily spending',
                      child: dailyAsync.when(
                        data: (daily) => SpendingTrendChart(daily: daily),
                        loading: () => const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
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
