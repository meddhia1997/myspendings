import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/savings_goals.dart';

part 'savings_goals_dao.g.dart';

@DriftAccessor(tables: [SavingsGoals])
class SavingsGoalsDao extends DatabaseAccessor<AppDatabase> with _$SavingsGoalsDaoMixin {
  SavingsGoalsDao(super.db);

  Stream<SavingsGoal?> watchForMonth(String monthKey) {
    final query = select(savingsGoals)..where((g) => g.monthKey.equals(monthKey));
    return query.watchSingleOrNull();
  }

  Future<void> setForMonth(String monthKey, int targetAmountMinor) {
    return into(savingsGoals).insertOnConflictUpdate(
      SavingsGoalsCompanion.insert(
        monthKey: monthKey,
        targetAmountMinor: targetAmountMinor,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
