import 'package:drift/drift.dart';

import 'accounts.dart';
import 'categories.dart';

@DataClassName('TransactionEntry')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get amountMinor => integer()();
  TextColumn get type => text()(); // expense, income
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();

  /// True for expenses logged from a saved Fixed Expense (rent, subscriptions,
  /// bills) — these are recurring/global costs, not discretionary daily
  /// spending, so they're excluded from the "today vs daily quota" check.
  BoolColumn get isFixed => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
