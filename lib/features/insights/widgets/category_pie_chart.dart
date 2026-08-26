import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/providers/insights_providers.dart';
import '../../../shared/widgets/icon_catalog.dart';
import '../../../shared/widgets/money_format.dart';

/// Interactive spending-by-category donut: tap a wedge to pop it out and see
/// its share, with the running total always visible in the center. The full
/// legend lists every category (not just the top few), each with its own
/// amount, share, and transaction count.
class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({super.key, required this.totals, required this.grandTotal});

  final List<CategoryTotal> totals;
  final int grandTotal;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 56,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response?.touchedSection == null) {
                        setState(() => _touchedIndex = null);
                        return;
                      }
                      setState(
                        () => _touchedIndex = response!.touchedSection!.touchedSectionIndex,
                      );
                    },
                  ),
                  sections: [
                    for (var i = 0; i < widget.totals.length; i++)
                      _section(context, i, widget.totals[i]),
                  ],
                ),
              ),
              _CenterLabel(
                totals: widget.totals,
                grandTotal: widget.grandTotal,
                highlighted: _touchedIndex == null ? null : widget.totals[_touchedIndex!],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            for (var i = 0; i < widget.totals.length; i++)
              _LegendChip(
                total: widget.totals[i],
                grandTotal: widget.grandTotal,
                selected: _touchedIndex == i,
                onTap: () => setState(() => _touchedIndex = _touchedIndex == i ? null : i),
              ),
          ],
        ),
      ],
    );
  }

  PieChartSectionData _section(BuildContext context, int index, CategoryTotal total) {
    final color = Color(total.category?.colorValue ?? 0xFF757575);
    final isTouched = _touchedIndex == index;
    final percent = widget.grandTotal == 0 ? 0.0 : total.totalMinor / widget.grandTotal * 100;

    return PieChartSectionData(
      value: total.totalMinor.toDouble(),
      color: color,
      radius: isTouched ? 52 : 44,
      showTitle: percent >= 8,
      title: '${percent.toStringAsFixed(0)}%',
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      titlePositionPercentageOffset: 0.62,
      borderSide: isTouched ? BorderSide(color: color, width: 2) : BorderSide.none,
    );
  }
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel({required this.totals, required this.grandTotal, this.highlighted});

  final List<CategoryTotal> totals;
  final int grandTotal;
  final CategoryTotal? highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (highlighted != null) {
      final color = Color(highlighted!.category?.colorValue ?? 0xFF757575);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconForKey(highlighted!.category?.iconKey ?? 'category'), color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            highlighted!.category?.name ?? 'Uncategorized',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
          ),
          Text(
            formatMoney(highlighted!.totalMinor, 'TND'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Total',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        FittedBox(
          child: Text(
            formatMoney(grandTotal, 'TND'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        Text(
          '${totals.length} categor${totals.length == 1 ? 'y' : 'ies'}',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.total,
    required this.grandTotal,
    required this.selected,
    required this.onTap,
  });

  final CategoryTotal total;
  final int grandTotal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(total.category?.colorValue ?? 0xFF757575);
    final percent = grandTotal == 0 ? 0 : (total.totalMinor / grandTotal * 100);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.5) : scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              total.category?.name ?? 'Uncategorized',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
