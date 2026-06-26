import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class HealthScoreData {
  final int healthScore;
  final String status;
  final double savingsRate;
  final double budgetCompliance;
  final double expenseStability;
  final double goalsProgress;

  HealthScoreData({
    required this.healthScore,
    required this.status,
    required this.savingsRate,
    required this.budgetCompliance,
    required this.expenseStability,
    required this.goalsProgress,
  });

  factory HealthScoreData.initial() => HealthScoreData(
        healthScore: 74,
        status: 'Healthy',
        savingsRate: 0.75,
        budgetCompliance: 0.85,
        expenseStability: 0.90,
        goalsProgress: 0.50,
      );
}

class HealthEngineService extends StateNotifier<HealthScoreData> {
  final Ref _ref;

  HealthEngineService(this._ref) : super(HealthScoreData.initial());

  Future<void> recalculate(String userId) async {
    try {
      final db = _ref.read(databaseProvider);
      final transactions = await db.transactionDao.getTransactionsForUser(userId);
      final budgets = await db.budgetDao.getBudgetsForUser(userId);
      final goals = await db.goalDao.getGoalsForUser(userId);

      final now = DateTime.now();
      final startOfCurrentMonth = DateTime(now.year, now.month, 1);
      final endOfCurrentMonth = DateTime(now.year, now.month + 1, 0);

      final currentMonthTxs = transactions.where((tx) =>
          tx.date.isAfter(startOfCurrentMonth.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(endOfCurrentMonth.add(const Duration(seconds: 1)))).toList();

      int income = 0;
      int expense = 0;
      final Map<String, int> catSpend = {};

      for (var tx in currentMonthTxs) {
        if (tx.type == 'income') {
          income += tx.amount;
        } else if (tx.type == 'expense') {
          expense += tx.amount;
          if (tx.categoryId != null) {
            catSpend[tx.categoryId!] = (catSpend[tx.categoryId!] ?? 0) + tx.amount;
          }
        }
      }

      // 1. Savings Rate Points (max 30)
      double savingsRatePct = 0;
      double savingsPoints = 0;
      if (income > 0) {
        savingsRatePct = (income - expense) / income;
        if (savingsRatePct >= 0.3) {
          savingsPoints = 30.0;
        } else if (savingsRatePct > 0) {
          savingsPoints = (savingsRatePct / 0.3) * 30.0;
        }
      } else {
        savingsPoints = expense > 0 ? 0 : 30.0;
      }

      // 2. Budget Compliance Points (max 30)
      double compliancePct = 1.0;
      double budgetPoints = 30.0;
      if (budgets.isNotEmpty) {
        int compliantCount = 0;
        for (var b in budgets) {
          final spent = catSpend[b.categoryId] ?? 0;
          if (spent <= b.amount) {
            compliantCount++;
          }
        }
        compliancePct = compliantCount / budgets.length;
        budgetPoints = compliancePct * 30.0;
      }

      // 3. Runrate Stability (max 20)
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);
      final lastMonthTxs = transactions.where((tx) =>
          tx.date.isAfter(startOfLastMonth.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(endOfLastMonth.add(const Duration(seconds: 1)))).toList();
      int lastMonthExpense = 0;
      for (var tx in lastMonthTxs) {
        if (tx.type == 'expense') {
          lastMonthExpense += tx.amount;
        }
      }
      double stabilityPct = 1.0;
      double stabilityPoints = 20.0;
      if (lastMonthExpense > 0) {
        if (expense > lastMonthExpense) {
          final increase = (expense - lastMonthExpense) / lastMonthExpense;
          stabilityPct = max(0.0, 1.0 - increase);
          stabilityPoints = stabilityPct * 20.0;
        }
      }

      // 4. Goals Progress Points (max 20)
      double goalsPct = 1.0;
      double goalsPoints = 20.0;
      if (goals.isNotEmpty) {
        double totalTarget = 0;
        double totalSaved = 0;
        for (var g in goals) {
          totalTarget += g.targetAmount;
          totalSaved += g.currentAmount;
        }
        if (totalTarget > 0) {
          goalsPct = (totalSaved / totalTarget).clamp(0.0, 1.0);
          goalsPoints = goalsPct * 20.0;
        }
      }

      final totalScore = (savingsPoints + budgetPoints + stabilityPoints + goalsPoints).round().clamp(0, 100);

      String status = 'Excellent';
      if (totalScore < 40) {
        status = 'Critical';
      } else if (totalScore < 60) {
        status = 'Fair';
      } else if (totalScore < 80) {
        status = 'Healthy';
      }

      state = HealthScoreData(
        healthScore: totalScore,
        status: status,
        savingsRate: savingsRatePct,
        budgetCompliance: compliancePct,
        expenseStability: stabilityPct,
        goalsProgress: goalsPct,
      );
    } catch (e) {
      // Keep state as initial or fallback on error
    }
  }
}

final StateNotifierProvider<HealthEngineService, HealthScoreData> healthEngineServiceProvider =
    StateNotifierProvider<HealthEngineService, HealthScoreData>((ref) {
  return HealthEngineService(ref);
});
