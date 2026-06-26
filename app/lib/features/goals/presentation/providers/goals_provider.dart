import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class GoalsListNotifier extends StateNotifier<List<Goal>> {
  final Ref _ref;

  GoalsListNotifier(this._ref) : super([]) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    final userId = _ref.read(authProvider).user?.id;
    if (userId == null) return;

    final db = _ref.read(databaseProvider);
    final goalsList = await db.goalDao.getGoalsForUser(userId);
    state = goalsList;
  }

  Future<void> addGoal(Goal goal) async {
    final db = _ref.read(databaseProvider);
    await db.goalDao.insertGoal(goal);
    await loadGoals();
  }

  Future<void> updateGoal(Goal goal) async {
    final db = _ref.read(databaseProvider);
    await db.goalDao.updateGoal(goal);
    await loadGoals();
  }

  Future<void> removeGoal(String id) async {
    final db = _ref.read(databaseProvider);
    await db.goalDao.deleteGoal(id);
    await loadGoals();
  }
}

final goalsListNotifierProvider = StateNotifierProvider<GoalsListNotifier, List<Goal>>((ref) {
  return GoalsListNotifier(ref);
});
