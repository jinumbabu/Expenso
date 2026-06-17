import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/repositories/budget_repository.dart';

// Repository Provider
final Provider<BudgetRepository> budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetRepositoryImpl(db.budgetDao);
});

// Budget Status Helper Class
class BudgetStatus {
  final Budget budget;
  final int spentAmount;
  final Category? category;

  BudgetStatus({
    required this.budget,
    required this.spentAmount,
    this.category,
  });

  double get percent => budget.amount == 0 ? 0.0 : spentAmount / budget.amount;
  int get remainingAmount => budget.amount - spentAmount;
  bool get isOverBudget => spentAmount > budget.amount;
}

// Budget List Notifier
class BudgetListNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  final BudgetRepository _repository;
  final String? _userId;

  BudgetListNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final budgets = await _repository.getBudgetsForUser(_userId);
      state = AsyncValue.data(budgets);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addBudget(int amountInCents, String? categoryId) async {
    if (_userId == null) return;
    try {
      state = const AsyncValue.loading();
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final budget = Budget(
        id: const Uuid().v4(),
        userId: _userId,
        categoryId: categoryId,
        period: 'monthly',
        amount: amountInCents,
        startDate: startOfMonth,
        createdAt: now,
        updatedAt: now,
      );
      await _repository.createBudget(budget);
      await loadBudgets();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editBudget(Budget budget) async {
    try {
      state = const AsyncValue.loading();
      final updated = budget.copyWith(updatedAt: DateTime.now());
      await _repository.updateBudget(updated);
      await loadBudgets();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeBudget(String id) async {
    try {
      state = const AsyncValue.loading();
      await _repository.deleteBudget(id);
      await loadBudgets();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Budget List Provider
final StateNotifierProvider<BudgetListNotifier, AsyncValue<List<Budget>>> budgetListNotifierProvider =
    StateNotifierProvider<BudgetListNotifier, AsyncValue<List<Budget>>>((ref) {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  final repo = ref.watch(budgetRepositoryProvider);
  return BudgetListNotifier(repo, userId);
});

// Reactive Combined Budget Status Provider
final Provider<AsyncValue<List<BudgetStatus>>> budgetStatusListProvider =
    Provider<AsyncValue<List<BudgetStatus>>>((ref) {
  final budgetsAsync = ref.watch(budgetListNotifierProvider);
  final txsAsync = ref.watch(expenseListNotifierProvider);
  final categoriesAsync = ref.watch(categoriesProvider);

  return budgetsAsync.when(
    data: (budgets) {
      return txsAsync.when(
        data: (txs) {
          return categoriesAsync.when(
            data: (categories) {
              final categoriesMap = {for (var c in categories) c.id: c};

              // Filter transactions to get current month expenses
              final now = DateTime.now();
              final startOfMonth = DateTime(now.year, now.month, 1);

              final currentMonthExpenses = txs.where((tx) =>
                tx.type == 'expense' &&
                (tx.date.isAfter(startOfMonth) || tx.date.isAtSameMomentAs(startOfMonth))
              ).toList();

              final list = budgets.map((budget) {
                int spent = 0;
                if (budget.categoryId == null) {
                  // Overall budget: sum all current month expenses
                  spent = currentMonthExpenses.fold(0, (sum, tx) => sum + tx.amount);
                } else {
                  // Category budget: sum matching current month expenses
                  spent = currentMonthExpenses
                      .where((tx) => tx.categoryId == budget.categoryId)
                      .fold(0, (sum, tx) => sum + tx.amount);
                }

                final cat = budget.categoryId != null ? categoriesMap[budget.categoryId] : null;

                return BudgetStatus(
                  budget: budget,
                  spentAmount: spent,
                  category: cat,
                );
              }).toList();

              // Sort overall budget (categoryId == null) to the top, then by largest limit
              list.sort((a, b) {
                if (a.budget.categoryId == null && b.budget.categoryId != null) return -1;
                if (a.budget.categoryId != null && b.budget.categoryId == null) return 1;
                return b.budget.amount.compareTo(a.budget.amount);
              });

              return AsyncValue.data(list);
            },
            loading: () => const AsyncValue.loading(),
            error: (e, s) => AsyncValue.error(e, s),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
