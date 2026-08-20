import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart' show Category;
import 'database_providers.dart';

class CategoryTotal {
  const CategoryTotal({required this.category, required this.totalMinor, required this.count});

  final Category? category;
  final int totalMinor;
  final int count;
}

/// Expense totals for the selected month, grouped by category and sorted
/// highest-spend first. Computed client-side from the already-fetched
/// monthly transaction list — cheap for a personal-finance-sized dataset.
final categoryTotalsProvider = Provider.autoDispose<AsyncValue<List<CategoryTotal>>>((ref) {
  final transactionsAsync = ref.watch(monthlyTransactionsProvider);

  return transactionsAsync.whenData((transactions) {
    final byCategory = <int?, (Category?, int, int)>{};
    for (final item in transactions) {
      if (item.transaction.type != 'expense') continue;
      final key = item.category?.id;
      final existing = byCategory[key];
      if (existing == null) {
        byCategory[key] = (item.category, item.transaction.amountMinor, 1);
      } else {
        byCategory[key] = (
          existing.$1,
          existing.$2 + item.transaction.amountMinor,
          existing.$3 + 1,
        );
      }
    }

    final totals = byCategory.values
        .map((v) => CategoryTotal(category: v.$1, totalMinor: v.$2, count: v.$3))
        .toList()
      ..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));
    return totals;
  });
});

class DailyTotal {
  const DailyTotal({required this.day, required this.expenseMinor, required this.incomeMinor});

  final int day; // day of month, 1-based
  final int expenseMinor;
  final int incomeMinor;
}

/// One entry per day of the selected month (including days with no activity),
/// used to plot the spending trend across the month.
final dailyTotalsProvider = Provider.autoDispose<AsyncValue<List<DailyTotal>>>((ref) {
  final transactionsAsync = ref.watch(monthlyTransactionsProvider);
  final month = ref.watch(selectedMonthProvider);

  return transactionsAsync.whenData((transactions) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final expenseByDay = List<int>.filled(daysInMonth + 1, 0);
    final incomeByDay = List<int>.filled(daysInMonth + 1, 0);

    for (final item in transactions) {
      final day = item.transaction.date.day;
      if (item.transaction.type == 'expense') {
        expenseByDay[day] += item.transaction.amountMinor;
      } else if (item.transaction.type == 'income') {
        incomeByDay[day] += item.transaction.amountMinor;
      }
    }

    return [
      for (var d = 1; d <= daysInMonth; d++)
        DailyTotal(day: d, expenseMinor: expenseByDay[d], incomeMinor: incomeByDay[d]),
    ];
  });
});
