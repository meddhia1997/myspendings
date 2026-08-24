import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/fixed_expenses_dao.dart';
import 'transaction_repository.dart';

class FixedExpenseRepository {
  FixedExpenseRepository(this._dao, this._transactionRepository);

  final FixedExpensesDao _dao;
  final TransactionRepository _transactionRepository;

  Stream<List<FixedExpenseWithDetails>> watchAll() => _dao.watchAll();

  Future<int> create({
    required String name,
    required int amountMinor,
    int? categoryId,
    int? accountId,
  }) {
    return _dao.insertFixedExpense(
      FixedExpensesCompanion.insert(
        name: name,
        amountMinor: amountMinor,
        categoryId: Value(categoryId),
        accountId: Value(accountId),
      ),
    );
  }

  Future<void> delete(int id) => _dao.deleteFixedExpense(id);

  /// Logs a fixed expense as a real transaction today, using its own account
  /// if it has one, otherwise falling back to [fallbackAccountId].
  Future<int> log(FixedExpenseWithDetails template, {required int fallbackAccountId}) {
    return _transactionRepository.addTransaction(
      accountId: template.fixedExpense.accountId ?? fallbackAccountId,
      categoryId: template.fixedExpense.categoryId,
      amountMinor: template.fixedExpense.amountMinor,
      type: 'expense',
      date: DateTime.now(),
      note: template.fixedExpense.name,
      isFixed: true,
    );
  }
}
