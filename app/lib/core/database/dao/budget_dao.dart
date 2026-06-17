import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/budgets.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Future<List<Budget>> getBudgetsForUser(String userId) =>
      (select(budgets)..where((t) => t.userId.equals(userId))).get();

  Future<Budget?> getBudgetById(String id) =>
      (select(budgets)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertBudget(Budget budget) => into(budgets).insert(budget);
  Future<bool> updateBudget(Budget budget) => update(budgets).replace(budget);
  Future<int> deleteBudget(String id) =>
      (delete(budgets)..where((t) => t.id.equals(id))).go();
}
