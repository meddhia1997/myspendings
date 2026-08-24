import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/transactions_dao.dart';
import '../repositories/account_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';

class ImportSummary {
  const ImportSummary({
    required this.accountsCreated,
    required this.categoriesCreated,
    required this.transactionsImported,
    required this.transactionsSkipped,
  });

  final int accountsCreated;
  final int categoriesCreated;
  final int transactionsImported;
  final int transactionsSkipped;
}

/// Round-trips the app's data through a .xlsx workbook: one sheet each for
/// accounts, categories, and transactions, in a format the importer reads back.
class ExcelBackupService {
  static const _sheetAccounts = 'Accounts';
  static const _sheetCategories = 'Categories';
  static const _sheetTransactions = 'Transactions';

  Future<File> exportToExcel({
    required List<Account> accounts,
    required List<Category> categories,
    required List<TransactionWithDetails> transactions,
  }) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', _sheetAccounts);

    final accSheet = excel[_sheetAccounts];
    accSheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Type'),
      TextCellValue('Currency'),
      TextCellValue('InitialBalance'),
      TextCellValue('Color'),
      TextCellValue('Icon'),
    ]);
    for (final a in accounts) {
      accSheet.appendRow([
        TextCellValue(a.name),
        TextCellValue(a.type),
        TextCellValue(a.currencyCode),
        DoubleCellValue(a.initialBalanceMinor / 100),
        TextCellValue(a.colorValue.toRadixString(16)),
        TextCellValue(a.iconKey),
      ]);
    }

    final catSheet = excel[_sheetCategories];
    catSheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Type'),
      TextCellValue('Color'),
      TextCellValue('Icon'),
    ]);
    for (final c in categories) {
      catSheet.appendRow([
        TextCellValue(c.name),
        TextCellValue(c.type),
        TextCellValue(c.colorValue.toRadixString(16)),
        TextCellValue(c.iconKey),
      ]);
    }

    final txSheet = excel[_sheetTransactions];
    txSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Amount'),
      TextCellValue('Account'),
      TextCellValue('Category'),
      TextCellValue('Note'),
      TextCellValue('Fixed'),
    ]);
    for (final t in transactions) {
      txSheet.appendRow([
        TextCellValue(t.transaction.date.toIso8601String()),
        TextCellValue(t.transaction.type),
        DoubleCellValue(t.transaction.amountMinor / 100),
        TextCellValue(t.account.name),
        TextCellValue(t.category?.name ?? ''),
        TextCellValue(t.transaction.note ?? ''),
        TextCellValue(t.transaction.isFixed ? 'yes' : 'no'),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Failed to encode the Excel workbook.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now();
    final fileName =
        'myspendings_${stamp.year}${_pad(stamp.month)}${_pad(stamp.day)}_'
        '${_pad(stamp.hour)}${_pad(stamp.minute)}.xlsx';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<ImportSummary> importFromExcel(
    File file, {
    required AccountRepository accountRepo,
    required CategoryRepository categoryRepo,
    required TransactionRepository transactionRepo,
  }) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    var accountsCreated = 0;
    var categoriesCreated = 0;
    var transactionsImported = 0;
    var transactionsSkipped = 0;

    final accountsByName = <String, Account>{
      for (final a in await accountRepo.watchAccounts().first) a.name: a,
    };
    final categoriesByKey = <String, Category>{
      for (final c in await categoryRepo.watchCategories().first) '${c.type}::${c.name}': c,
    };

    final accSheet = excel.tables[_sheetAccounts];
    if (accSheet != null) {
      for (final row in accSheet.rows.skip(1)) {
        final name = _text(row, 0);
        if (name == null || name.isEmpty || accountsByName.containsKey(name)) continue;
        final type = _text(row, 1) ?? 'cash';
        final currency = _text(row, 2) ?? 'TND';
        final initial = _double(row, 3) ?? 0;
        final color = int.tryParse(_text(row, 4) ?? '', radix: 16) ?? 0xFF757575;
        final icon = _text(row, 5) ?? 'account_balance_wallet';
        final id = await accountRepo.createAccount(
          name: name,
          type: type,
          currencyCode: currency,
          initialBalanceMinor: (initial * 100).round(),
          colorValue: color,
          iconKey: icon,
        );
        final created = await accountRepo.getAccount(id);
        if (created != null) accountsByName[name] = created;
        accountsCreated++;
      }
    }

    final catSheet = excel.tables[_sheetCategories];
    if (catSheet != null) {
      for (final row in catSheet.rows.skip(1)) {
        final name = _text(row, 0);
        final type = _text(row, 1) ?? 'expense';
        if (name == null || name.isEmpty) continue;
        final key = '$type::$name';
        if (categoriesByKey.containsKey(key)) continue;
        final color = int.tryParse(_text(row, 2) ?? '', radix: 16) ?? 0xFF757575;
        final icon = _text(row, 3) ?? 'category';
        final id = await categoryRepo.createCategory(
          name: name,
          type: type,
          colorValue: color,
          iconKey: icon,
        );
        final created = await categoryRepo.getCategory(id);
        if (created != null) categoriesByKey[key] = created;
        categoriesCreated++;
      }
    }

    final txSheet = excel.tables[_sheetTransactions];
    if (txSheet != null) {
      for (final row in txSheet.rows.skip(1)) {
        final dateText = _text(row, 0);
        final type = _text(row, 1);
        final amount = _double(row, 2);
        final accountName = _text(row, 3);
        final categoryName = _text(row, 4);
        final note = _text(row, 5);
        final fixed = (_text(row, 6) ?? '').toLowerCase() == 'yes';

        if (dateText == null || type == null || amount == null || accountName == null) {
          transactionsSkipped++;
          continue;
        }
        final account = accountsByName[accountName];
        if (account == null) {
          transactionsSkipped++;
          continue;
        }
        final date = DateTime.tryParse(dateText);
        if (date == null) {
          transactionsSkipped++;
          continue;
        }
        final category = (categoryName == null || categoryName.isEmpty)
            ? null
            : categoriesByKey['$type::$categoryName'];

        await transactionRepo.addTransaction(
          accountId: account.id,
          categoryId: category?.id,
          amountMinor: (amount * 100).round(),
          type: type,
          date: date,
          note: (note == null || note.isEmpty) ? null : note,
          isFixed: fixed,
        );
        transactionsImported++;
      }
    }

    return ImportSummary(
      accountsCreated: accountsCreated,
      categoriesCreated: categoriesCreated,
      transactionsImported: transactionsImported,
      transactionsSkipped: transactionsSkipped,
    );
  }

  String? _text(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final value = row[index]?.value;
    return switch (value) {
      TextCellValue() => value.value.toString(),
      IntCellValue() => value.value.toString(),
      DoubleCellValue() => value.value.toString(),
      BoolCellValue() => value.value.toString(),
      null => null,
      _ => value.toString(),
    };
  }

  double? _double(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final value = row[index]?.value;
    return switch (value) {
      DoubleCellValue() => value.value,
      IntCellValue() => value.value.toDouble(),
      TextCellValue() => double.tryParse(value.value.toString()),
      _ => null,
    };
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
