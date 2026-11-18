import '../../../core/database/app_database.dart';
import '../models/savings_goal_model.dart';

class GoalRepository {
  /// Every goal with the amount saved so far (deadline first, no-deadline
  /// goals last).
  Future<List<GoalProgress>> getGoals() async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery('''
      SELECT g.*, COALESCE(SUM(c.amount), 0) AS saved_amount
      FROM savings_goals g
      LEFT JOIN savings_goal_contributions c ON c.goal_id = g.id
      GROUP BY g.id
      ORDER BY (g.target_date IS NULL), g.target_date ASC, g.id ASC
    ''');
    return rows
        .map(
          (r) => GoalProgress(
            goal: SavingsGoalModel.fromMap(r),
            saved: (r['saved_amount'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();
  }

  Future<int> addGoal(SavingsGoalModel goal) async {
    final db = await AppDatabase.database;
    final map = goal.toMap()..remove('id');
    return db.insert('savings_goals', map);
  }

  Future<void> updateGoal(SavingsGoalModel goal) async {
    final db = await AppDatabase.database;
    await db.update(
      'savings_goals',
      {
        'name': goal.name,
        'target_amount': goal.targetAmount,
        'target_date': goal.targetDate,
      },
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteGoal(int id) async {
    final db = await AppDatabase.database;
    await db.transaction((txn) async {
      await txn.delete(
        'savings_goal_contributions',
        where: 'goal_id = ?',
        whereArgs: [id],
      );
      await txn.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<GoalContributionModel>> getContributions(int goalId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'savings_goal_contributions',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(GoalContributionModel.fromMap).toList();
  }

  Future<void> addContribution(GoalContributionModel c) async {
    final db = await AppDatabase.database;
    final map = c.toMap()..remove('id');
    await db.insert('savings_goal_contributions', map);
  }

  Future<void> deleteContribution(int id) async {
    final db = await AppDatabase.database;
    await db.delete(
      'savings_goal_contributions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
