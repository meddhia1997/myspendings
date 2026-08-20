import 'package:drift/drift.dart';

import 'accounts.dart';
import 'categories.dart';

/// A saved expense template (rent, a subscription, a bill) the user can log
/// with a single tap instead of re-entering it every time.
@DataClassName('FixedExpense')
class FixedExpenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get amountMinor => integer()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
