import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/transactions_dao.dart';

class TransactionRepository {
  TransactionRepository(this._dao);

  final TransactionsDao _dao;

  Stream<List<TransactionWithDetails>> watchAll({int? accountId}) =>
      _dao.watchAll(accountId: accountId);

  Stream<List<TransactionWithDetails>> watchForMonth(DateTime month, {int? accountId}) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return _dao.watchAll(from: start, to: end, accountId: accountId);
  }

  Future<int> addTransaction({
    required int accountId,
    int? categoryId,
    required int amountMinor,
    required String type,
    required DateTime date,
    String? note,
  }) {
    return _dao.insertTransaction(
      TransactionsCompanion.insert(
        accountId: accountId,
        categoryId: Value(categoryId),
        amountMinor: amountMinor,
        type: type,
        date: date,
        note: Value(note),
      ),
    );
  }

  Future<bool> updateTransaction(TransactionEntry entry) {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    return _dao.updateTransaction(updated.toCompanion(false));
  }

  Future<int> deleteTransaction(int id) => _dao.deleteTransaction(id);

  Stream<int> watchTotalBalance() => _dao.watchTotalBalance();
}
