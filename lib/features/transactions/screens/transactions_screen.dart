import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/transactions_dao.dart';
import '../../../shared/providers/database_providers.dart';
import '../../../shared/providers/savings_providers.dart';
import '../../../shared/responsive/breakpoints.dart';
import '../../../shared/widgets/icon_catalog.dart';
import '../../../shared/widgets/money_format.dart';
import '../widgets/backup_menu_button.dart';
import '../widgets/fixed_expenses_row.dart';
import '../widgets/quick_expense_sheet.dart';
import '../widgets/savings_goal_sheet.dart';

const _expenseColor = Color(0xFFE1544C);
const _incomeColor = Color(0xFF4CAF7D);

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final transactionsAsync = ref.watch(monthlyTransactionsProvider);
    final totalAsync = ref.watch(totalBalanceProvider);
    final budgetAsync = ref.watch(dailyBudgetProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Spendings'),
        actions: const [BackupMenuButton()],
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _BalanceCard(totalAsync: totalAsync, budgetAsync: budgetAsync),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: FixedExpensesRow(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_monthLabel(month), style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => ref.read(selectedMonthProvider.notifier).state =
                            DateTime(month.year, month.month - 1),
                      ),
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: () => ref.read(selectedMonthProvider.notifier).state =
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
                      .fold<int>(0, (sum, t) => sum + t.transaction.amountMinor);
                  final expenseTotal = transactions
                      .where((t) => t.transaction.type == 'expense')
                      .fold<int>(0, (sum, t) => sum + t.transaction.amountMinor);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _PillStat(
                              label: 'Income',
                              amountMinor: incomeTotal,
                              color: _incomeColor,
                              icon: Icons.south_west_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PillStat(
                              label: 'Expense',
                              amountMinor: expenseTotal,
                              color: _expenseColor,
                              icon: Icons.north_east_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      for (final item in transactions) _TransactionCard(item: item),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => showQuickExpenseSheet(context),
        tooltip: 'Add expense',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _monthLabel(DateTime month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }
}

/// One flat card: total balance up top, the daily-budget summary underneath —
/// replaces two separately-styled cards that used to stack here.
class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.totalAsync, required this.budgetAsync});

  final AsyncValue<int> totalAsync;
  final AsyncValue<DailyBudget> budgetAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 4),
                totalAsync.when(
                  data: (total) => FittedBox(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatMoney(total, 'TND'),
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  loading: () => SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                  ),
                  error: (_, _) => Text('—', style: TextStyle(color: scheme.primary, fontSize: 38)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          _BudgetRow(budgetAsync: budgetAsync),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.budgetAsync});

  final AsyncValue<DailyBudget> budgetAsync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return budgetAsync.when(
      loading: () => const SizedBox(height: 56),
      error: (_, _) => const SizedBox.shrink(),
      data: (budget) {
        if (budget.goalMinor == null) {
          return InkWell(
            onTap: () => showSavingsGoalSheet(context),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, color: scheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Set a savings goal to see your daily budget',
                      style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          );
        }

        final over = budget.isOverBudget;
        final pastDeadline = budget.isPastDeadline;
        final overToday = budget.isOverToday;
        final warn = over || pastDeadline || overToday;
        final color = warn ? _expenseColor : scheme.primary;

        String title;
        String subtitle;
        IconData icon;
        if (pastDeadline) {
          title = 'Goal date has passed';
          subtitle = 'Set a new date to keep tracking';
          icon = Icons.event_busy_rounded;
        } else if (over) {
          title = 'No room left to spend';
          subtitle = 'At or below your ${formatMoney(budget.goalMinor!, 'TND')} goal';
          icon = Icons.warning_rounded;
        } else if (overToday) {
          title = "Stop — today's quota is spent";
          subtitle = '${formatMoney(budget.overTodayByMinor, 'TND')} over today';
          icon = Icons.block_rounded;
        } else {
          title = 'Daily budget · ${_shortDate(budget.targetDate!)}';
          subtitle =
              '${formatMoney(budget.spentTodayMinor, 'TND')}/'
              '${formatMoney(budget.dailyAmountMinor ?? 0, 'TND')} today · '
              '${budget.daysRemaining}d left';
          icon = Icons.bolt_rounded;
        }

        return InkWell(
          onTap: () => showSavingsGoalSheet(context),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  String _shortDate(DateTime date) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
                Text(
                  formatMoney(amountMinor, 'TND'),
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15),
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: _expenseColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: _expenseColor),
      ),
      onDismissed: (_) =>
          ref.read(transactionRepositoryProvider).deleteTransaction(item.transaction.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 48,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
            Expanded(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  foregroundColor: color,
                  child: Icon(iconForKey(category?.iconKey ?? 'category')),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        category?.name ?? (isExpense ? 'Expense' : 'Income'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (item.transaction.isFixed) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.push_pin_rounded, size: 12, color: scheme.onSurfaceVariant),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${item.account.name}'
                  '${item.transaction.note != null ? ' • ${item.transaction.note}' : ''}',
                ),
                trailing: Text(
                  '${isExpense ? '-' : '+'}${formatMoney(item.transaction.amountMinor, item.account.currencyCode)}',
                  style: TextStyle(
                    color: isExpense ? _expenseColor : _incomeColor,
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
            decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded, size: 36, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          const Text('Nothing logged yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Tap + below to add your first one', style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
