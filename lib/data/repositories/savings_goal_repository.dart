import '../../core/database/app_database.dart' show SavingsGoal;
import '../../core/database/daos/savings_goals_dao.dart';

String monthKeyFor(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

class SavingsGoalRepository {
  SavingsGoalRepository(this._dao);

  final SavingsGoalsDao _dao;

  Stream<SavingsGoal?> watchForMonth(DateTime month) => _dao.watchForMonth(monthKeyFor(month));

  Future<void> setForMonth(DateTime month, int targetAmountMinor) =>
      _dao.setForMonth(monthKeyFor(month), targetAmountMinor);
}
