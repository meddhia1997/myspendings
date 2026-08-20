import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/accounts_dao.dart';

class AccountRepository {
  AccountRepository(this._dao, this._db);

  final AccountsDao _dao;
  final AppDatabase _db;

  Stream<List<Account>> watchAccounts({bool includeArchived = false}) =>
      _dao.watchAll(includeArchived: includeArchived);

  Future<Account?> getAccount(int id) => _dao.getById(id);

  /// Current balance = initial balance + net of all transactions on this account.
  Stream<int> watchBalance(int accountId) {
    return _dao.getById(accountId).asStream().asyncExpand((account) {
      if (account == null) return Stream.value(0);
      return _db.transactionsDao
          .watchAccountNet(accountId)
          .map((net) => account.initialBalanceMinor + net);
    });
  }

  Future<int> createAccount({
    required String name,
    required String type,
    required String currencyCode,
    required int initialBalanceMinor,
    required int colorValue,
    required String iconKey,
  }) {
    return _dao.insertAccount(
      AccountsCompanion.insert(
        name: name,
        type: type,
        currencyCode: Value(currencyCode),
        initialBalanceMinor: Value(initialBalanceMinor),
        colorValue: colorValue,
        iconKey: iconKey,
      ),
    );
  }

  Future<bool> updateAccount(Account account) =>
      _dao.updateAccount(account.toCompanion(false));

  Future<void> archiveAccount(int id) => _dao.archiveAccount(id);
}
