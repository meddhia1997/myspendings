import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart' show SavingsGoal;
import 'database_providers.dart';

final savingsGoalProvider = StreamProvider.autoDispose<SavingsGoal?>((ref) {
  return ref.watch(savingsGoalRepositoryProvider).watchGoal();
});

/// Real spend for today, regardless of which month is being browsed elsewhere
/// in the UI — used to check progress against the daily budget.
final todaySpentProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(transactionRepositoryProvider).watchExpenseTotalForDay(DateTime.now());
});

class DailyBudget {
  const DailyBudget({
    required this.totalBalanceMinor,
    required this.goalMinor,
    required this.targetDate,
    required this.daysRemaining,
    required this.dailyAmountMinor,
    required this.spentTodayMinor,
  });

  final int totalBalanceMinor;
  final int? goalMinor;
  final DateTime? targetDate;
  final int daysRemaining;

  /// Null when no goal is set yet. Zero (never negative) once the balance has
  /// already dropped to or below the goal — there's no room left to spend.
  final int? dailyAmountMinor;

  final int spentTodayMinor;

  bool get isOverBudget => goalMinor != null && totalBalanceMinor <= goalMinor!;

  bool get isPastDeadline {
    if (targetDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate!.year, targetDate!.month, targetDate!.day);
    return target.isBefore(today);
  }

  /// Positive once today's spending has gone past the daily quota.
  int get overTodayByMinor {
    if (dailyAmountMinor == null) return 0;
    final over = spentTodayMinor - dailyAmountMinor!;
    return over > 0 ? over : 0;
  }

  bool get isOverToday => dailyAmountMinor != null && overTodayByMinor > 0;
}

int _daysRemainingUntil(DateTime targetDate, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
  final diff = target.difference(today).inDays + 1; // inclusive of today
  return diff < 1 ? 1 : diff;
}

/// Combines the live total balance with the user's chosen savings goal into a
/// daily spending allowance: (balance - goal) / days left until the target date.
/// Also tracks today's real spending against that allowance.
final dailyBudgetProvider = Provider.autoDispose<AsyncValue<DailyBudget>>((ref) {
  final totalAsync = ref.watch(totalBalanceProvider);
  final goalAsync = ref.watch(savingsGoalProvider);
  final spentTodayAsync = ref.watch(todaySpentProvider);

  if (totalAsync.isLoading || goalAsync.isLoading || spentTodayAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (totalAsync.hasError) {
    return AsyncValue.error(totalAsync.error!, totalAsync.stackTrace ?? StackTrace.current);
  }
  if (goalAsync.hasError) {
    return AsyncValue.error(goalAsync.error!, goalAsync.stackTrace ?? StackTrace.current);
  }
  if (spentTodayAsync.hasError) {
    return AsyncValue.error(
      spentTodayAsync.error!,
      spentTodayAsync.stackTrace ?? StackTrace.current,
    );
  }

  final total = totalAsync.value ?? 0;
  final goal = goalAsync.value;
  final daysRemaining = goal == null ? 0 : _daysRemainingUntil(goal.targetDate, DateTime.now());

  int? daily;
  if (goal != null) {
    final spendable = total - goal.targetAmountMinor;
    daily = spendable <= 0 ? 0 : (spendable / daysRemaining).floor();
  }

  return AsyncValue.data(
    DailyBudget(
      totalBalanceMinor: total,
      goalMinor: goal?.targetAmountMinor,
      targetDate: goal?.targetDate,
      daysRemaining: daysRemaining,
      dailyAmountMinor: daily,
      spentTodayMinor: spentTodayAsync.value ?? 0,
    ),
  );
});
