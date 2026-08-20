import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/database_providers.dart';
import '../../../shared/widgets/icon_catalog.dart';
import '../../../shared/widgets/money_format.dart';
import 'add_transaction_screen.dart';

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
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions this month.'));
          }

          final incomeTotal = transactions
              .where((t) => t.transaction.type == 'income')
              .fold<int>(0, (sum, t) => sum + t.transaction.amountMinor);
          final expenseTotal = transactions
              .where((t) => t.transaction.type == 'expense')
              .fold<int>(0, (sum, t) => sum + t.transaction.amountMinor);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryTile(label: 'Income', amountMinor: incomeTotal, color: Colors.green),
                    _SummaryTile(label: 'Expense', amountMinor: expenseTotal, color: Colors.red),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final item = transactions[index];
                    final isExpense = item.transaction.type == 'expense';
                    final category = item.category;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Color(category?.colorValue ?? 0xFF757575).withValues(alpha: 0.15),
                        foregroundColor: Color(category?.colorValue ?? 0xFF757575),
                        child: Icon(iconForKey(category?.iconKey ?? 'category')),
                      ),
                      title: Text(category?.name ?? (isExpense ? 'Expense' : 'Income')),
                      subtitle: Text(
                        '${item.account.name}'
                        '${item.transaction.note != null ? ' • ${item.transaction.note}' : ''}',
                      ),
                      trailing: Text(
                        '${isExpense ? '-' : '+'}${formatMoney(item.transaction.amountMinor, item.account.currencyCode)}',
                        style: TextStyle(
                          color: isExpense ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        child: const Icon(Icons.add),
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

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.amountMinor, required this.color});

  final String label;
  final int amountMinor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Text(
          formatMoney(amountMinor, 'TND'),
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}
