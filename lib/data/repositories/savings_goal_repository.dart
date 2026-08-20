import '../../core/database/app_database.dart' show SavingsGoal;
import '../../core/database/daos/savings_goals_dao.dart';

class SavingsGoalRepository {
  SavingsGoalRepository(this._dao);

  final SavingsGoalsDao _dao;

  Stream<SavingsGoal?> watchGoal() => _dao.watchGoal();

  Future<void> setGoal({
    required DateTime targetDate,
    required int targetAmountMinor,
  }) => _dao.setGoal(
    targetDate: targetDate,
    targetAmountMinor: targetAmountMinor,
  );
}
