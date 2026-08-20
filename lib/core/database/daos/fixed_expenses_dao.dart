import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/accounts.dart';
import '../tables/categories.dart';
import '../tables/fixed_expenses.dart';

part 'fixed_expenses_dao.g.dart';

class FixedExpenseWithDetails {
  const FixedExpenseWithDetails({required this.fixedExpense, this.category, this.account});

  final FixedExpense fixedExpense;
  final Category? category;
  final Account? account;
}

@DriftAccessor(tables: [FixedExpenses, Categories, Accounts])
class FixedExpensesDao extends DatabaseAccessor<AppDatabase> with _$FixedExpensesDaoMixin {
  FixedExpensesDao(super.db);

  Stream<List<FixedExpenseWithDetails>> watchAll() {
    final query = select(fixedExpenses).join([
      leftOuterJoin(categories, categories.id.equalsExp(fixedExpenses.categoryId)),
      leftOuterJoin(accounts, accounts.id.equalsExp(fixedExpenses.accountId)),
    ])
      ..orderBy([OrderingTerm.asc(fixedExpenses.createdAt)]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => FixedExpenseWithDetails(
                  fixedExpense: row.readTable(fixedExpenses),
                  category: row.readTableOrNull(categories),
                  account: row.readTableOrNull(accounts),
                ),
              )
              .toList(),
        );
  }

  Future<int> insertFixedExpense(FixedExpensesCompanion entry) =>
      into(fixedExpenses).insert(entry);

  Future<int> deleteFixedExpense(int id) =>
      (delete(fixedExpenses)..where((f) => f.id.equals(id))).go();
}
