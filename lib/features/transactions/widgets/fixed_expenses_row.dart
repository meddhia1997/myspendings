import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/fixed_expenses_dao.dart';
import '../../../shared/providers/database_providers.dart';
import '../../../shared/widgets/icon_catalog.dart';
import '../../../shared/widgets/money_format.dart';
import 'add_fixed_expense_sheet.dart';

/// Horizontal strip of saved expense templates (rent, subscriptions, bills) —
/// tap one to log it instantly instead of going through the category+amount flow.
class FixedExpensesRow extends ConsumerWidget {
  const FixedExpensesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixedAsync = ref.watch(fixedExpensesProvider);
    final scheme = Theme.of(context).colorScheme;

    return fixedAsync.when(
      data: (fixed) => SizedBox(
        height: 84,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            for (final template in fixed) _FixedExpenseChip(template: template),
            _AddChip(scheme: scheme),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 84),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _FixedExpenseChip extends ConsumerWidget {
  const _FixedExpenseChip({required this.template});

  final FixedExpenseWithDetails template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(template.category?.colorValue ?? 0xFF757575);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () => _logIt(context, ref),
        onLongPress: () => _confirmDelete(context, ref),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.15),
                foregroundColor: color,
                child: Icon(iconForKey(template.category?.iconKey ?? 'category'), size: 16),
              ),
              const SizedBox(height: 6),
              Text(
                template.fixedExpense.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              Text(
                formatMoney(template.fixedExpense.amountMinor, 'TND'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logIt(BuildContext context, WidgetRef ref) async {
    final defaultAccount = ref.read(defaultAccountProvider);
    if (defaultAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create an account first — Accounts tab.')),
      );
      return;
    }

    final id = await ref
        .read(fixedExpenseRepositoryProvider)
        .log(template, fallbackAccountId: defaultAccount.id);

    // Jump the browsed month to today so the newly logged expense is visible immediately.
    final now = DateTime.now();
    ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, now.month);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${template.fixedExpense.name} logged'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => ref.read(transactionRepositoryProvider).deleteTransaction(id),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove fixed expense?'),
        content: Text('"${template.fixedExpense.name}" will no longer show up here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(fixedExpenseRepositoryProvider).delete(template.fixedExpense.id);
    }
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showAddFixedExpenseSheet(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              'Add fixed',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
