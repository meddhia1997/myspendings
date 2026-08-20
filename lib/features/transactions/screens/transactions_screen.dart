import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/transactions_dao.dart';
import '../../../shared/providers/database_providers.dart';
import '../../../shared/providers/savings_providers.dart';
import '../../../shared/responsive/breakpoints.dart';
import '../../../shared/widgets/icon_catalog.dart';
import '../../../shared/widgets/money_format.dart';
import '../widgets/quick_expense_sheet.dart';
import '../widgets/savings_goal_sheet.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final transactionsAsync = ref.watch(monthlyTransactionsProvider);
    final totalAsync = ref.watch(totalBalanceProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Spendings')),
      body: ResponsiveBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _HeroBalanceCard(totalAsync: totalAsync),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _DailyBudgetCard(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _monthLabel(month),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () =>
                            ref.read(selectedMonthProvider.notifier).state =
                                DateTime(month.year, month.month - 1),
                      ),
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: () =>
                            ref.read(selectedMonthProvider.notifier).state =
                                DateTime(month.year, month.month + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return _EmptyState(scheme: scheme);
                  }

                  final incomeTotal = transactions
                      .where((t) => t.transaction.type == 'income')
                      .fold<int>(
                        0,
                        (sum, t) => sum + t.transaction.amountMinor,
                      );
                  final expenseTotal = transactions
                      .where((t) => t.transaction.type == 'expense')
                      .fold<int>(
                        0,
                        (sum, t) => sum + t.transaction.amountMinor,
                      );

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _PillStat(
                              label: 'Income',
                              amountMinor: incomeTotal,
                              color: const Color(0xFF2E9E5B),
                              icon: Icons.south_west_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PillStat(
                              label: 'Expense',
                              amountMinor: expenseTotal,
                              color: const Color(0xFFE1544C),
                              icon: Icons.north_east_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      for (final item in transactions)
                        _TransactionCard(item: item),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickExpenseSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Expense'),
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

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({required this.totalAsync});

  final AsyncValue<int> totalAsync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, const Color(0xFF0B5C4C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'You have',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          totalAsync.when(
            data: (total) => FittedBox(
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(total, 'TND'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            loading: () => const SizedBox(
              height: 32,
              width: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            error: (_, _) => const Text(
              '—',
              style: TextStyle(color: Colors.white, fontSize: 40),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyBudgetCard extends ConsumerWidget {
  const _DailyBudgetCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(dailyBudgetProvider);
    final scheme = Theme.of(context).colorScheme;

    return budgetAsync.when(
      loading: () => const SizedBox(height: 64),
      error: (_, _) => const SizedBox.shrink(),
      data: (budget) {
        if (budget.goalMinor == null) {
          return InkWell(
            onTap: () => showSavingsGoalSheet(context),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Set a savings goal to see how much you can spend per day',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        }

        final over = budget.isOverBudget;
        final pastDeadline = budget.isPastDeadline;
        final warn = over || pastDeadline;
        final color = warn ? const Color(0xFFE1544C) : scheme.primary;

        String title;
        String subtitle;
        IconData icon;
        if (pastDeadline) {
          title = 'Goal date has passed';
          subtitle = 'Set a new date to keep tracking';
          icon = Icons.event_busy_rounded;
        } else if (over) {
          title = 'No room left to spend';
          subtitle =
              'You are at or below your ${formatMoney(budget.goalMinor!, 'TND')} goal';
          icon = Icons.warning_rounded;
        } else {
          title = 'Daily budget · ${_shortDate(budget.targetDate!)}';
          subtitle =
              '${formatMoney(budget.dailyAmountMinor ?? 0, 'TND')} / day · ${budget.daysRemaining} days left';
          icon = Icons.bolt_rounded;
        }

        return InkWell(
          onTap: () => showSavingsGoalSheet(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_rounded, color: color, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  String _shortDate(DateTime date) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[date.month - 1]} ${date.day}';
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _PillStat extends StatelessWidget {
  const _PillStat({
    required this.label,
    required this.amountMinor,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amountMinor;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: color),
                ),
                Text(
                  formatMoney(amountMinor, 'TND'),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends ConsumerWidget {
  const _TransactionCard({required this.item});

  final TransactionWithDetails item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = item.transaction.type == 'expense';
    final category = item.category;
    final color = Color(category?.colorValue ?? 0xFF757575);
    final scheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(item.transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      onDismissed: (_) => ref
          .read(transactionRepositoryProvider)
          .deleteTransaction(item.transaction.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 52,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  foregroundColor: color,
                  child: Icon(iconForKey(category?.iconKey ?? 'category')),
                ),
                title: Text(
                  category?.name ?? (isExpense ? 'Expense' : 'Income'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${item.account.name}'
                  '${item.transaction.note != null ? ' • ${item.transaction.note}' : ''}',
                ),
                trailing: Text(
                  '${isExpense ? '-' : '+'}${formatMoney(item.transaction.amountMinor, item.account.currencyCode)}',
                  style: TextStyle(
                    color: isExpense
                        ? const Color(0xFFE1544C)
                        : const Color(0xFF2E9E5B),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scheme});

  final ColorScheme scheme;

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
              Icons.receipt_long_rounded,
              size: 36,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nothing logged yet',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "Expense" below to add your first one',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
