import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import 'money_format.dart';

/// A slim, always-visible strip showing how much money is left across all accounts.
/// Meant to sit at the bottom of every screen's AppBar so it's a constant reminder.
class TotalBalanceBanner extends ConsumerWidget implements PreferredSizeWidget {
  const TotalBalanceBanner({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalBalanceProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: preferredSize.height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_rounded, size: 16, color: scheme.onPrimary),
            const SizedBox(width: 8),
            totalAsync.when(
              data: (total) => Text(
                formatMoney(total, 'TND'),
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              loading: () => SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
              ),
              error: (_, _) => Text('—', style: TextStyle(color: scheme.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
