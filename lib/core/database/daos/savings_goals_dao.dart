import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/savings_goals.dart';

part 'savings_goals_dao.g.dart';

@DriftAccessor(tables: [SavingsGoals])
class SavingsGoalsDao extends DatabaseAccessor<AppDatabase> with _$SavingsGoalsDaoMixin {
  SavingsGoalsDao(super.db);

  /// There's only ever one active goal — the most recently set one.
  Stream<SavingsGoal?> watchGoal() {
    final query = select(savingsGoals)
      ..orderBy([(g) => OrderingTerm.desc(g.updatedAt)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Future<void> setGoal({required DateTime targetDate, required int targetAmountMinor}) {
    return transaction(() async {
      await delete(savingsGoals).go();
      await into(savingsGoals).insert(
        SavingsGoalsCompanion.insert(
          targetDate: targetDate,
          targetAmountMinor: targetAmountMinor,
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }
}
