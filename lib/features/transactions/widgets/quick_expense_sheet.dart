import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/database_providers.dart';
import '../../../shared/widgets/icon_catalog.dart';
import '../screens/add_transaction_screen.dart';
import 'add_transaction_sheet.dart';

/// Shows the "bubbles" of expense categories that appear when the + button is tapped.
/// Picking one jumps straight to a big-keypad amount entry — built for logging a
/// coffee or a taxi fare in two taps, not filling out a form.
Future<void> showQuickExpenseSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _QuickExpenseSheet(),
  );
}

class _QuickExpenseSheet extends ConsumerWidget {
  const _QuickExpenseSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider('expense'));
    final defaultAccount = ref.watch(defaultAccountProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            Text(
              'What did you spend on?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            if (defaultAccount == null)
              const Text(
                'Create an account first — accounts tab.',
                style: TextStyle(color: Colors.red),
              )
            else
              Text(
                'Booked to ${defaultAccount.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 20),
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Text(
                    'No expense categories yet — add one in Categories.',
                  );
                }
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final category in categories)
                      _CategoryBubble(
                        category: category,
                        enabled: defaultAccount != null,
                        onTap: defaultAccount == null
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                showAddTransactionAmountSheet(
                                  context,
                                  accountId: defaultAccount.id,
                                  category: category,
                                );
                              },
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Income or a different account? Use the full form',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({
    required this.category,
    required this.enabled,
    required this.onTap,
  });

  final Category category;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  iconForKey(category.iconKey),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
