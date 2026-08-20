import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/database_providers.dart';
import '../../../shared/widgets/icon_catalog.dart';
import '../../../shared/widgets/total_balance_banner.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories'), bottom: const TotalBalanceBanner()),
      body: categoriesAsync.when(
        data: (categories) {
          final expense = categories.where((c) => c.type == 'expense').toList();
          final income = categories.where((c) => c.type == 'income').toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              Text('Expense', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final category in expense) _CategoryTile(category: category),
              const SizedBox(height: 16),
              Text('Income', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final category in income) _CategoryTile(category: category),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String type = 'expense';
    String iconKey = kCategoryIconKeys.first;
    int colorValue = kColorPalette.first;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('Expense')),
                      DropdownMenuItem(value: 'income', child: Text('Income')),
                    ],
                    onChanged: (value) => setState(() => type = value ?? 'expense'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final key in kCategoryIconKeys)
                        ChoiceChip(
                          label: Icon(iconForKey(key), size: 18),
                          selected: iconKey == key,
                          onSelected: (_) => setState(() => iconKey = key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final color in kColorPalette)
                        GestureDetector(
                          onTap: () => setState(() => colorValue = color),
                          child: CircleAvatar(
                            backgroundColor: Color(color),
                            radius: colorValue == color ? 16 : 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    await ref.read(categoryRepositoryProvider).createCategory(
                          name: name,
                          type: type,
                          colorValue: colorValue,
                          iconKey: iconKey,
                        );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Color(category.colorValue).withValues(alpha: 0.15),
          foregroundColor: Color(category.colorValue),
          child: Icon(iconForKey(category.iconKey)),
        ),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
