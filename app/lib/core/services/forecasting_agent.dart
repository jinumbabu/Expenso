import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;
import '../database/app_database.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class ForecastingAgent {
  final AppDatabase _db;

  ForecastingAgent(this._db);

  /// Generates month-end projections (balance, expenses, budget risks)
  /// based on historical spending rates and recurring items.
  Future<FinancialPrediction> generateProjections(String userId) async {
    dev.log('ForecastingAgent: Generating financial projections for $userId');
    final now = DateTime.now();

    // 1. Calculate days remaining in the current month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final totalDaysInMonth = lastDayOfMonth.day;
    final currentDay = now.day;
    final daysRemaining = totalDaysInMonth - currentDay;

    // 2. Fetch current balances
    final accounts = await (_db.select(_db.accounts)
      ..where((a) => a.userId.equals(userId))
    ).get();
    
    int currentBalance = 0;
    for (var acc in accounts) {
      currentBalance += acc.balance;
    }

    // 3. Fetch historical transactions
    final txs = await _db.transactionDao.getTransactionsForUser(userId);
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    final thisMonthTxs = txs.where((t) => t.date.isAfter(startOfThisMonth) || t.date.isAtSameMomentAs(startOfThisMonth)).toList();

    int thisMonthExpense = 0;
    // ignore: unused_local_variable
    int thisMonthIncome = 0;
    for (var tx in thisMonthTxs) {
      if (tx.type == 'expense') {
        thisMonthExpense += tx.amount;
      } else if (tx.type == 'income') {
        thisMonthIncome += tx.amount;
      }
    }

    // 4. Daily run rate calculations
    double dailySpendRate = 0.0;
    if (currentDay > 1) {
      dailySpendRate = thisMonthExpense / currentDay;
    } else {
      // Fallback: look at prior month if first day of the month
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthTxs = txs.where((t) => t.date.isAfter(lastMonthStart) && t.date.isBefore(startOfThisMonth)).toList();
      int lastMonthExpense = 0;
      for (var tx in lastMonthTxs) {
        if (tx.type == 'expense') {
          lastMonthExpense += tx.amount;
        }
      }
      dailySpendRate = lastMonthTxs.isEmpty ? 0.0 : lastMonthExpense / 30.0;
    }

    // Projected remaining expenses
    final projectedRemainingExpense = dailySpendRate * daysRemaining;
    final int predictedExpenses = thisMonthExpense + projectedRemainingExpense.toInt();

    // Projected remaining income (e.g. check if salary is expected)
    int projectedRemainingIncome = 0;
    // Simple heuristic: check if user gets salary/deposits and hasn't received it yet this month
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthTxs = txs.where((t) => t.date.isAfter(lastMonthStart) && t.date.isBefore(startOfThisMonth)).toList();
    final salaryReceivedThisMonth = thisMonthTxs.any((t) => t.type == 'income' && (t.description ?? '').toLowerCase().contains('salary'));
    if (!salaryReceivedThisMonth) {
      // Find salary from last month
      final lastMonthSalary = lastMonthTxs.where((t) => t.type == 'income' && (t.description ?? '').toLowerCase().contains('salary')).toList();
      if (lastMonthSalary.isNotEmpty) {
        projectedRemainingIncome = lastMonthSalary.first.amount;
      }
    }

    // Predicted Month-End Balance
    final int predictedBalance = currentBalance + projectedRemainingIncome - projectedRemainingExpense.toInt();

    // 5. Budget Overrun Risk
    final budgets = await _db.budgetDao.getBudgetsForUser(userId);
    final categories = await _db.categoryDao.getCategoriesForUser(userId);
    final categoriesMap = {for (var c in categories) c.id: c};

    final List<Map<String, dynamic>> overrunRisks = [];
    for (var b in budgets) {
      final catName = categoriesMap[b.categoryId]?.name ?? 'Total';
      // Calculate current spending in this category
      int categorySpent = 0;
      for (var tx in thisMonthTxs) {
        if (tx.categoryId == b.categoryId && tx.type == 'expense') {
          categorySpent += tx.amount;
        }
      }

      // Project category spent
      double catDailyRate = 0.0;
      if (currentDay > 1) {
        catDailyRate = categorySpent / currentDay;
      }
      final double projectedCatSpent = categorySpent + (catDailyRate * daysRemaining);
      final double overrunPercent = b.amount > 0 ? (projectedCatSpent / b.amount) * 100 : 0.0;

      if (projectedCatSpent > b.amount) {
        overrunRisks.add({
          'category': catName,
          'limit': b.amount,
          'spent': categorySpent,
          'projected': projectedCatSpent.toInt(),
          'risk': 'high',
          'overrunPercent': overrunPercent,
        });
      } else if (projectedCatSpent > b.amount * 0.8) {
        overrunRisks.add({
          'category': catName,
          'limit': b.amount,
          'spent': categorySpent,
          'projected': projectedCatSpent.toInt(),
          'risk': 'medium',
          'overrunPercent': overrunPercent,
        });
      }
    }

    // 6. Goal Completion Estimate
    final goals = await _db.goalDao.getGoalsForUser(userId);
    final List<Map<String, dynamic>> goalEstimates = [];

    // Monthly savings rate based on past 30 days
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final last30DaysTxs = txs.where((t) => t.date.isAfter(thirtyDaysAgo)).toList();
    int savingsPast30Days = 0;
    for (var t in last30DaysTxs) {
      if (t.type == 'income') {
        savingsPast30Days += t.amount;
      } else if (t.type == 'expense') {
        savingsPast30Days -= t.amount;
      }
    }

    final double monthlySavingsRate = savingsPast30Days > 0 ? savingsPast30Days.toDouble() : 100000.0; // Fallback to ₹1,000 monthly if negative/zero

    for (var g in goals) {
      final remainingAmount = g.targetAmount - g.currentAmount;
      if (remainingAmount <= 0) {
        goalEstimates.add({
          'goalId': g.id,
          'title': g.title,
          'monthsToComplete': 0.0,
          'estimatedDate': now.toIso8601String(),
        });
        continue;
      }

      final monthsToComplete = remainingAmount / monthlySavingsRate;
      final estimatedCompletionDate = now.add(Duration(days: (monthsToComplete * 30.44).toInt()));
      
      goalEstimates.add({
        'goalId': g.id,
        'title': g.title,
        'monthsToComplete': monthsToComplete,
        'estimatedDate': estimatedCompletionDate.toIso8601String(),
        'onTrack': estimatedCompletionDate.isBefore(g.targetDate) || estimatedCompletionDate.isAtSameMomentAs(g.targetDate),
      });
    }

    // Calculate overall confidence based on transactions quantity
    double confidence = 0.91; // Default
    if (txs.length < 10) {
      confidence = 0.60;
    } else if (txs.length < 30) {
      confidence = 0.75;
    }

    final Map<String, dynamic> payload = {
      'dailySpendRate': dailySpendRate,
      'projectedRemainingExpense': projectedRemainingExpense,
      'projectedRemainingIncome': projectedRemainingIncome,
      'overrunRisks': overrunRisks,
      'goalEstimates': goalEstimates,
    };

    final prediction = FinancialPrediction(
      id: const Uuid().v4(),
      userId: userId,
      targetDate: lastDayOfMonth,
      predictedBalance: predictedBalance,
      predictedExpenses: predictedExpenses,
      confidence: confidence,
      metricPayload: jsonEncode(payload),
      createdAt: now,
    );

    // Save prediction
    await _db.predictionDao.insertPrediction(prediction);

    // 7. Log Agent Action
    await _db.agentLogDao.insertLog(
      AgentLog(
        id: const Uuid().v4(),
        agentName: 'Forecasting Agent',
        actionType: 'FORECAST_GENERATED',
        decisionDescription: 'Generated cash flow forecast for end-of-month. Projected Balance: ₹${(predictedBalance / 100.0).toStringAsFixed(2)}, Projected Expenses: ₹${(predictedExpenses / 100.0).toStringAsFixed(2)}. Confidence: ${(confidence * 100).toStringAsFixed(0)}%.',
        confidenceScore: confidence,
        timestamp: now,
      ),
    );

    return prediction;
  }
}

final Provider<ForecastingAgent> forecastingAgentProvider = Provider<ForecastingAgent>((ref) {
  final db = ref.watch(databaseProvider);
  return ForecastingAgent(db);
});
