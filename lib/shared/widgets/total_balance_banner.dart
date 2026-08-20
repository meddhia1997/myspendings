import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import 'money_format.dart';

/// A slim, always-visible strip showing how much money is left across all accounts.
/// Meant to sit at the bottom of every screen's AppBar so it's a constant reminder.
class TotalBalanceBanner extends ConsumerWidget implements PreferredSizeWidget {
  const TotalBalanceBanner({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalBalanceProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: preferredSize.height,
      width: double.infinity,
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: totalAsync.when(
        data: (total) => Text(
          'You have ${formatMoney(total, 'TND')}',
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        loading: () => const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, _) => Text(
          'Balance unavailable',
          style: TextStyle(color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}
