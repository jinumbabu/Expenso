import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/goals.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  Future<List<Goal>> getGoalsForUser(String userId) =>
      (select(goals)..where((t) => t.userId.equals(userId))).get();

  Stream<List<Goal>> watchGoalsForUser(String userId) =>
      (select(goals)..where((t) => t.userId.equals(userId))).watch();

  Future<Goal?> getGoalById(String id) =>
      (select(goals)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertGoal(Goal goal) => into(goals).insert(goal);
  Future<bool> updateGoal(Goal goal) => update(goals).replace(goal);
  Future<int> deleteGoal(String id) =>
      (delete(goals)..where((t) => t.id.equals(id))).go();
}
