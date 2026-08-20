import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart' show Account;
import '../../../shared/providers/database_providers.dart';
import '../../../shared/responsive/breakpoints.dart';
import '../../../shared/responsive/responsive_grid.dart';
import '../../../shared/widgets/icon_catalog.dart';
import '../../../shared/widgets/money_format.dart';
import '../../../shared/widgets/total_balance_banner.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        bottom: const TotalBalanceBanner(),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return _EmptyState(scheme: Theme.of(context).colorScheme);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            child: ResponsiveBody(
              child: ResponsiveCardGrid(
                children: [
                  for (final account in accounts)
                    _AccountCard(account: account),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    String type = 'cash';

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New account'),
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
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'bank', child: Text('Bank')),
                      DropdownMenuItem(value: 'card', child: Text('Card')),
                      DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
                    ],
                    onChanged: (value) =>
                        setState(() => type = value ?? 'cash'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Starting balance',
                    ),
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
                    final iconKey =
                        kAccountIconKeys[type == 'bank'
                            ? 1
                            : type == 'card'
                            ? 2
                            : type == 'wallet'
                            ? 0
                            : 3];
                    await ref
                        .read(accountRepositoryProvider)
                        .createAccount(
                          name: name,
                          type: type,
                          currencyCode: 'TND',
                          initialBalanceMinor: parseAmountToMinor(
                            balanceController.text,
                          ),
                          colorValue:
                              kColorPalette[type.hashCode %
                                  kColorPalette.length],
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

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountBalanceProvider(account.id));

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Color(account.colorValue).withValues(alpha: 0.15),
          foregroundColor: Color(account.colorValue),
          child: Icon(iconForKey(account.iconKey)),
        ),
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(account.type),
        trailing: balanceAsync.when(
          data: (balance) => Text(
            formatMoney(balance, account.currencyCode),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, _) => const Icon(Icons.error_outline),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 36,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No accounts yet',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap + to add your first one',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
