import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/accounts.dart';
import '../tables/categories.dart';
import '../tables/transactions.dart';

part 'transactions_dao.g.dart';

class TransactionWithDetails {
  final TransactionEntry transaction;
  final Account account;
  final Category? category;

  TransactionWithDetails({required this.transaction, required this.account, this.category});
}

@DriftAccessor(tables: [Transactions, Accounts, Categories])
class TransactionsDao extends DatabaseAccessor<AppDatabase> with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Stream<List<TransactionWithDetails>> watchAll({DateTime? from, DateTime? to, int? accountId}) {
    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
      leftOuterJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])
      ..orderBy([OrderingTerm.desc(transactions.date)]);

    if (from != null) {
      query.where(transactions.date.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where(transactions.date.isSmallerThanValue(to));
    }
    if (accountId != null) {
      query.where(transactions.accountId.equals(accountId));
    }

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => TransactionWithDetails(
                  transaction: row.readTable(transactions),
                  account: row.readTable(accounts),
                  category: row.readTableOrNull(categories),
                ),
              )
              .toList(),
        );
  }

  Stream<List<TransactionWithDetails>> watchForMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return watchAll(from: start, to: end);
  }

  /// Net minor units for an account: income - expense, excluding the account's initial balance.
  Stream<int> watchAccountNet(int accountId) {
    final query = customSelect(
      'SELECT COALESCE(SUM(CASE WHEN type = ?1 THEN amount_minor ELSE -amount_minor END), 0) AS net '
      'FROM transactions WHERE account_id = ?2',
      variables: [Variable.withString('income'), Variable.withInt(accountId)],
      readsFrom: {transactions},
    );
    return query.watchSingle().map((row) => row.read<int>('net'));
  }

  /// Sum of every account's current balance (initial balance + its net transactions).
  Stream<int> watchTotalBalance() {
    final query = customSelect(
      'SELECT '
      '(SELECT COALESCE(SUM(initial_balance_minor), 0) FROM accounts WHERE is_archived = 0) + '
      '(SELECT COALESCE(SUM(CASE WHEN type = ?1 THEN amount_minor ELSE -amount_minor END), 0) FROM transactions) '
      'AS total',
      variables: [Variable.withString('income')],
      readsFrom: {accounts, transactions},
    );
    return query.watchSingle().map((row) => row.read<int>('total'));
  }

  Future<int> insertTransaction(TransactionsCompanion entry) => into(transactions).insert(entry);

  Future<bool> updateTransaction(TransactionsCompanion entry) =>
      update(transactions).replace(entry);

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();
}
