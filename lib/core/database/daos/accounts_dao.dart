import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/accounts.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase> with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Stream<List<Account>> watchAll({bool includeArchived = false}) {
    final query = select(accounts)
      ..where((a) => includeArchived ? const Constant(true) : a.isArchived.equals(false))
      ..orderBy([(a) => OrderingTerm.asc(a.name)]);
    return query.watch();
  }

  Future<Account?> getById(int id) =>
      (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<int> insertAccount(AccountsCompanion entry) => into(accounts).insert(entry);

  Future<bool> updateAccount(AccountsCompanion entry) => update(accounts).replace(entry);

  Future<void> archiveAccount(int id) => (update(accounts)..where((a) => a.id.equals(id)))
      .write(const AccountsCompanion(isArchived: Value(true)));

  Future<int> deleteAccount(int id) => (delete(accounts)..where((a) => a.id.equals(id))).go();
}
