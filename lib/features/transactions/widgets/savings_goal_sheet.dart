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

class _SavingsGoalSheetState extends ConsumerState<_SavingsGoalSheet> {
  late final TextEditingController _controller;
  DateTime? _targetDate;
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

  DateTime _defaultTargetDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0); // last day of this month
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? _defaultTargetDate(),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(savingsGoalProvider);

    if (!_initialized) {
      final existing = goalAsync.valueOrNull;
      if (existing != null) {
        _controller.text = (existing.targetAmountMinor / 100).toStringAsFixed(2);
        _targetDate = existing.targetDate;
      }
      _initialized = true;
    }
    final targetDate = _targetDate ?? _defaultTargetDate();

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
              'How much do you want left in your accounts, and by when?',
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
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('By when', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _formatDate(targetDate),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final minor = parseAmountToMinor(_controller.text);
                  await ref.read(savingsGoalRepositoryProvider).setGoal(
                        targetDate: targetDate,
                        targetAmountMinor: minor,
                      );
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

  String _formatDate(DateTime date) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${names[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SavingsGoalSheet extends ConsumerStatefulWidget {
  const _SavingsGoalSheet();

  @override
  ConsumerState<_SavingsGoalSheet> createState() => _SavingsGoalSheetState();
}
