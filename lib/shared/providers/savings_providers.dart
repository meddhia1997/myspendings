import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart' show SavingsGoal;
import 'database_providers.dart';

/// The real current calendar month — the savings goal always targets "this month",
/// independent of whichever month the user is browsing in the transactions list.
final currentMonthProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final savingsGoalProvider = StreamProvider.autoDispose<SavingsGoal?>((ref) {
  final month = ref.watch(currentMonthProvider);
  return ref.watch(savingsGoalRepositoryProvider).watchForMonth(month);
});

class DailyBudget {
  const DailyBudget({
    required this.totalBalanceMinor,
    required this.goalMinor,
    required this.daysRemaining,
    required this.dailyAmountMinor,
  });

  final int totalBalanceMinor;
  final int? goalMinor;
  final int daysRemaining;

  /// Null when no goal is set yet. Zero (never negative) once the balance has
  /// already dropped to or below the goal — there's no room left to spend.
  final int? dailyAmountMinor;

  bool get isOverBudget => goalMinor != null && totalBalanceMinor <= goalMinor!;
}

int _daysRemainingInMonth(DateTime now) {
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  return daysInMonth - now.day + 1; // inclusive of today
}

/// Combines the live total balance with this month's savings goal into a daily
/// spending allowance: (balance - goal) / days left in the month.
final dailyBudgetProvider = Provider.autoDispose<AsyncValue<DailyBudget>>((ref) {
  final totalAsync = ref.watch(totalBalanceProvider);
  final goalAsync = ref.watch(savingsGoalProvider);

  if (totalAsync.isLoading || goalAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (totalAsync.hasError) {
    return AsyncValue.error(totalAsync.error!, totalAsync.stackTrace ?? StackTrace.current);
  }
  if (goalAsync.hasError) {
    return AsyncValue.error(goalAsync.error!, goalAsync.stackTrace ?? StackTrace.current);
  }

  final total = totalAsync.value ?? 0;
  final goal = goalAsync.value?.targetAmountMinor;
  final daysRemaining = _daysRemainingInMonth(DateTime.now());

  int? daily;
  if (goal != null) {
    final spendable = total - goal;
    daily = spendable <= 0 ? 0 : (spendable / daysRemaining).floor();
  }

  return AsyncValue.data(DailyBudget(
    totalBalanceMinor: total,
    goalMinor: goal,
    daysRemaining: daysRemaining,
    dailyAmountMinor: daily,
  ));
});
