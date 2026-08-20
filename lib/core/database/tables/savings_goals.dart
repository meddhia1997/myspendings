import 'package:drift/drift.dart';

/// The user's single active savings target: how much they want left in their
/// accounts by a date they choose themselves.
@DataClassName('SavingsGoal')
class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get targetDate => dateTime()();
  IntColumn get targetAmountMinor => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
