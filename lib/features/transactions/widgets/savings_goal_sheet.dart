import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/database_providers.dart';
import '../../../shared/providers/savings_providers.dart';
import '../../../shared/widgets/money_format.dart';

Future<void> showSavingsGoalSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _SavingsGoalSheet(),
  );
}

class _SavingsGoalSheet extends ConsumerStatefulWidget {
  const _SavingsGoalSheet();

  @override
  ConsumerState<_SavingsGoalSheet> createState() => _SavingsGoalSheetState();
}

class _SavingsGoalSheetState extends ConsumerState<_SavingsGoalSheet> {
  late final TextEditingController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(savingsGoalProvider);
    final month = ref.watch(currentMonthProvider);

    if (!_initialized) {
      final existing = goalAsync.valueOrNull;
      if (existing != null) {
        _controller.text = (existing.targetAmountMinor / 100).toStringAsFixed(2);
      }
      _initialized = true;
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Savings goal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'How much do you want left in your accounts by the end of ${_monthName(month)}?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: 'TND  ',
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final minor = parseAmountToMinor(_controller.text);
                  await ref.read(savingsGoalRepositoryProvider).setForMonth(month, minor);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Save goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(DateTime month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month.month - 1];
  }
}
