import '../../../../core/database/app_database.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getBudgetsForUser(String userId);
  Future<Budget?> getBudgetById(String id);
  Future<void> createBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String id);
}
