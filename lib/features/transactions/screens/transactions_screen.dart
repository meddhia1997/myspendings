import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/database_providers.dart';
import '../../../shared/widgets/icon_catalog.dart';
import '../../../shared/widgets/money_format.dart';
import '../../../shared/widgets/total_balance_banner.dart';
import '../widgets/quick_expense_sheet.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final transactionsAsync = ref.watch(monthlyTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_monthLabel(month)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month + 1),
          ),
        ],
        bottom: const TotalBalanceBanner(),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final incomeTotal = transactions
              .where((t) => t.transaction.type == 'income')
              .fold<int>(0, (sum, t) => sum + t.transaction.amountMinor);
          final expenseTotal = transactions
              .where((t) => t.transaction.type == 'expense')
              .fold<int>(0, (sum, t) => sum + t.transaction.amountMinor);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Income',
                        amountMinor: incomeTotal,
                        color: Colors.green,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Expense',
                        amountMinor: expenseTotal,
                        color: Colors.red,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('No transactions this month.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final item = transactions[index];
                          final isExpense = item.transaction.type == 'expense';
                          final category = item.category;
                          final color = Color(category?.colorValue ?? 0xFF757575);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.15),
                                foregroundColor: color,
                                child: Icon(iconForKey(category?.iconKey ?? 'category')),
                              ),
                              title: Text(
                                category?.name ?? (isExpense ? 'Expense' : 'Income'),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${item.account.name}'
                                '${item.transaction.note != null ? ' • ${item.transaction.note}' : ''}',
                              ),
                              trailing: Text(
                                '${isExpense ? '-' : '+'}${formatMoney(item.transaction.amountMinor, item.account.currencyCode)}',
                                style: TextStyle(
                                  color: isExpense ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickExpenseSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Expense'),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
                ),
                Text(
                  formatMoney(amountMinor, 'TND'),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
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
