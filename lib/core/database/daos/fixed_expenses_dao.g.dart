// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_expenses_dao.dart';

// ignore_for_file: type=lint
mixin _$FixedExpensesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $FixedExpensesTable get fixedExpenses => attachedDatabase.fixedExpenses;
  FixedExpensesDaoManager get managers => FixedExpensesDaoManager(this);
}

class FixedExpensesDaoManager {
  final _$FixedExpensesDaoMixin _db;
  FixedExpensesDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$FixedExpensesTableTableManager get fixedExpenses =>
      $$FixedExpensesTableTableManager(_db.attachedDatabase, _db.fixedExpenses);
}
