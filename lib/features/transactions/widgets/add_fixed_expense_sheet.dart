import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/database_providers.dart';
import '../../../shared/widgets/money_format.dart';

Future<void> showAddFixedExpenseSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AddFixedExpenseSheet(),
  );
}

class _AddFixedExpenseSheet extends ConsumerStatefulWidget {
  const _AddFixedExpenseSheet();

  @override
  ConsumerState<_AddFixedExpenseSheet> createState() => _AddFixedExpenseSheetState();
}

class _AddFixedExpenseSheetState extends ConsumerState<_AddFixedExpenseSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  int? _categoryId;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = parseAmountToMinor(_amountController.text);
    if (name.isEmpty || amount <= 0 || _saving) return;

    setState(() => _saving = true);
    await ref.read(fixedExpenseRepositoryProvider).create(
          name: name,
          amountMinor: amount,
          categoryId: _categoryId,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider('expense'));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
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
            Text('New fixed expense', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Save it once, log it with one tap from now on.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'Rent, Netflix, gym…'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(prefixText: 'TND  ', labelText: 'Amount'),
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  for (final category in categories)
                    DropdownMenuItem(value: category.id, child: Text(category.name)),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save fixed expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
