import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/providers/backup_providers.dart';
import '../../../shared/providers/database_providers.dart';

/// Overflow menu on the Home AppBar for backing data up to Excel and
/// restoring it back in — accounts, categories, and transactions round-trip.
class BackupMenuButton extends ConsumerWidget {
  const BackupMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        if (value == 'export') _export(context, ref);
        if (value == 'import') _import(context, ref);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'export',
          child: ListTile(
            leading: Icon(Icons.upload_file_rounded),
            title: Text('Export to Excel'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'import',
          child: ListTile(
            leading: Icon(Icons.download_rounded),
            title: Text('Import from Excel'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final accounts = await ref.read(accountRepositoryProvider).watchAccounts().first;
      final categories = await ref.read(categoryRepositoryProvider).watchCategories().first;
      final transactions = await ref.read(transactionRepositoryProvider).watchAll().first;

      final file = await ref.read(excelBackupServiceProvider).exportToExcel(
            accounts: accounts,
            categories: categories,
            transactions: transactions,
          );

      await Share.shareXFiles([XFile(file.path)], text: 'My Spendings backup');
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      final path = result?.files.single.path;
      if (path == null) return;

      final summary = await ref
          .read(excelBackupServiceProvider)
          .importFromExcel(
            File(path),
            accountRepo: ref.read(accountRepositoryProvider),
            categoryRepo: ref.read(categoryRepositoryProvider),
            transactionRepo: ref.read(transactionRepositoryProvider),
          );

      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${summary.transactionsImported} transactions '
              '(${summary.accountsCreated} new accounts, '
              '${summary.categoriesCreated} new categories'
              '${summary.transactionsSkipped > 0 ? ', ${summary.transactionsSkipped} rows skipped' : ''})',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }
}
