import 'package:drift/drift.dart';

/// One row per calendar month ("2026-08") holding how much the user wants
/// left in their accounts by the end of that month.
@DataClassName('SavingsGoal')
class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get monthKey => text()(); // 'YYYY-MM'
  IntColumn get targetAmountMinor => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {monthKey},
      ];
}
