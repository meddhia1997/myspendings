import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/database_providers.dart';
import '../../../shared/widgets/icon_catalog.dart';
import '../../../shared/widgets/money_format.dart';

/// Big-keypad amount entry — no keyboard, no fields, just tap in the number and save.
Future<void> showAddTransactionAmountSheet(
  BuildContext context, {
  required int accountId,
  required Category category,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AmountSheet(accountId: accountId, category: category),
  );
}

class _AmountSheet extends ConsumerStatefulWidget {
  const _AmountSheet({required this.accountId, required this.category});

  final int accountId;
  final Category category;

  @override
  ConsumerState<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends ConsumerState<_AmountSheet> {
  String _digits = '';
  bool _saving = false;

  double get _value => _digits.isEmpty ? 0 : int.parse(_digits) / 100;

  void _tapDigit(String d) {
    if (_digits.length + d.length > 9) return;
    setState(() => _digits += d);
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  Future<void> _save() async {
    if (_value <= 0 || _saving) return;
    setState(() => _saving = true);
    final date = DateTime.now();
    await ref
        .read(transactionRepositoryProvider)
        .addTransaction(
          accountId: widget.accountId,
          categoryId: widget.category.id,
          amountMinor: (_value * 100).round(),
          type: 'expense',
          date: date,
        );
    // Jump the browsed month to wherever this landed so it's visible immediately.
    ref.read(selectedMonthProvider.notifier).state = DateTime(date.year, date.month);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.category.colorValue);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withValues(alpha: 0.15),
                  foregroundColor: color,
                  child: Icon(iconForKey(widget.category.iconKey), size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.category.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              child: Text(
                formatMoney((_value * 100).round(), 'TND'),
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Keypad(onDigit: _tapDigit, onBackspace: _backspace),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _value > 0 && !_saving ? _save : null,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('Save expense'),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '00',
    '0',
    '⌫',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.9,
      children: [
        for (final key in _keys)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => key == '⌫' ? onBackspace() : onDigit(key),
            child: Center(
              child: key == '⌫'
                  ? const Icon(Icons.backspace_outlined)
                  : Text(key, style: const TextStyle(fontSize: 24)),
            ),
          ),
      ],
    );
  }
}
