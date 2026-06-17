import '../../domain/repositories/budget_repository.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/dao/budget_dao.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetDao _budgetDao;

  BudgetRepositoryImpl(this._budgetDao);

  @override
  Future<List<Budget>> getBudgetsForUser(String userId) => _budgetDao.getBudgetsForUser(userId);

  @override
  Future<Budget?> getBudgetById(String id) => _budgetDao.getBudgetById(id);

  @override
  Future<void> createBudget(Budget budget) => _budgetDao.insertBudget(budget);

  @override
  Future<void> updateBudget(Budget budget) => _budgetDao.updateBudget(budget);

  @override
  Future<void> deleteBudget(String id) => _budgetDao.deleteBudget(id);
}
