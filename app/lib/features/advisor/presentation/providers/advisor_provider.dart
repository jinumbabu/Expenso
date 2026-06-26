import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/notification_service.dart';

class AdvisorState {
  final int healthScore;
  final String healthStatus;
  final Map<String, double> healthBreakdown;
  final int projectedMonthEndSpend;
  final int totalIncome;
  final int totalExpense;
  final int averageDailySpend;
  final List<String> spendingAlerts;
  final List<String> aiInsights;
  final bool isLoadingInsights;
  final String? insightsError;

  AdvisorState({
    required this.healthScore,
    required this.healthStatus,
    required this.healthBreakdown,
    required this.projectedMonthEndSpend,
    required this.totalIncome,
    required this.totalExpense,
    required this.averageDailySpend,
    required this.spendingAlerts,
    required this.aiInsights,
    required this.isLoadingInsights,
    this.insightsError,
  });

  AdvisorState.initial()
      : healthScore = 100,
        healthStatus = 'Excellent',
        healthBreakdown = const {},
        projectedMonthEndSpend = 0,
        totalIncome = 0,
        totalExpense = 0,
        averageDailySpend = 0,
        spendingAlerts = const [],
        aiInsights = const [],
        isLoadingInsights = false,
        insightsError = null;

  AdvisorState copyWith({
    int? healthScore,
    String? healthStatus,
    Map<String, double>? healthBreakdown,
    int? projectedMonthEndSpend,
    int? totalIncome,
    int? totalExpense,
    int? averageDailySpend,
    List<String>? spendingAlerts,
    List<String>? aiInsights,
    bool? isLoadingInsights,
    String? insightsError,
  }) {
    return AdvisorState(
      healthScore: healthScore ?? this.healthScore,
      healthStatus: healthStatus ?? this.healthStatus,
      healthBreakdown: healthBreakdown ?? this.healthBreakdown,
      projectedMonthEndSpend: projectedMonthEndSpend ?? this.projectedMonthEndSpend,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      averageDailySpend: averageDailySpend ?? this.averageDailySpend,
      spendingAlerts: spendingAlerts ?? this.spendingAlerts,
      aiInsights: aiInsights ?? this.aiInsights,
      isLoadingInsights: isLoadingInsights ?? this.isLoadingInsights,
      insightsError: insightsError ?? this.insightsError,
    );
  }
}

class AdvisorNotifier extends StateNotifier<AdvisorState> {
  final Ref _ref;

  AdvisorNotifier(this._ref) : super(AdvisorState.initial()) {
    // Automatically calculate stats on load/changes
    calculateFinancialOverview();
  }

  Future<void> calculateFinancialOverview() async {
    try {
      final db = _ref.read(databaseProvider);
      final auth = _ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final startOfCurrentMonth = DateTime(now.year, now.month, 1);
      final endOfCurrentMonth = DateTime(now.year, now.month + 1, 0);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);

      // Fetch all transactions and budgets
      final transactions = await db.transactionDao.getTransactionsForUser(userId);
      final budgets = await db.budgetDao.getBudgetsForUser(userId);
      final categories = await db.categoryDao.getCategoriesForUser(userId);
      final categoriesMap = {for (var c in categories) c.id: c.name};
      final existingNotifications = await db.notificationDao.getNotificationsForUser(userId);

      // 1. Split transactions
      final currentMonthTxs = transactions.where((tx) =>
          tx.date.isAfter(startOfCurrentMonth.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(endOfCurrentMonth.add(const Duration(seconds: 1)))).toList();

      final lastMonthTxs = transactions.where((tx) =>
          tx.date.isAfter(startOfLastMonth.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(endOfLastMonth.add(const Duration(seconds: 1)))).toList();

      // 2. Sum current month totals
      int currentIncome = 0;
      int currentExpense = 0;
      final currentCategorySpend = <String, int>{};

      for (var tx in currentMonthTxs) {
        if (tx.type == 'income') {
          currentIncome += tx.amount.toInt();
        } else if (tx.type == 'expense') {
          currentExpense += tx.amount.toInt();
          if (tx.categoryId != null) {
            currentCategorySpend[tx.categoryId!] = (currentCategorySpend[tx.categoryId!] ?? 0) + tx.amount.toInt();
          }
        }
      }

      // Sum last month totals
      int lastMonthExpense = 0;
      final lastCategorySpend = <String, int>{};
      for (var tx in lastMonthTxs) {
        if (tx.type == 'expense') {
          lastMonthExpense += tx.amount.toInt();
          if (tx.categoryId != null) {
            lastCategorySpend[tx.categoryId!] = (lastCategorySpend[tx.categoryId!] ?? 0) + tx.amount.toInt();
          }
        }
      }

      // 3. Health Score Calculations
      double savingsRatePoints = 0;
      if (currentIncome > 0) {
        final savingsRate = (currentIncome - currentExpense) / currentIncome;
        if (savingsRate >= 0.30) {
          savingsRatePoints = 30.0;
        } else if (savingsRate > 0) {
          savingsRatePoints = (savingsRate / 0.30) * 30.0;
        }
      } else {
        savingsRatePoints = currentExpense > 0 ? 0 : 30.0; // Perfect if zero expense, otherwise 0
      }

      double budgetCompliancePoints = 25.0;
      final List<String> alerts = [];
      if (budgets.isNotEmpty) {
        int compliantCount = 0;
        for (var budget in budgets) {
          final spent = currentCategorySpend[budget.categoryId] ?? 0;
          final catName = categoriesMap[budget.categoryId] ?? 'Category';
          if (spent <= budget.amount.toInt()) {
            compliantCount++;
            if (budget.amount > 0 && spent > budget.amount * 0.85) {
              final percent = ((spent / budget.amount) * 100).toStringAsFixed(0);
              final alertText = 'Budget for $catName is at $percent% of limit.';
              alerts.add(alertText);

              // Send proactive alert if not already sent in the last 24 hours
              final alreadySent = existingNotifications.any((n) =>
                  n.body == alertText &&
                  n.createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 24))));
              if (!alreadySent) {
                _ref.read(notificationServiceProvider).sendProactiveAlert(
                  userId,
                  title: 'Budget Warning',
                  body: alertText,
                  priority: 'medium',
                );
              }
            }
          } else {
            final over = ((spent - budget.amount) / 100.0).toStringAsFixed(2);
            final alertText = 'Budget for $catName exceeded by ₹$over!';
            alerts.add(alertText);

            // Send proactive alert if not already sent in the last 24 hours
            final alreadySent = existingNotifications.any((n) =>
                n.body == alertText &&
                n.createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 24))));
            if (!alreadySent) {
              _ref.read(notificationServiceProvider).sendProactiveAlert(
                userId,
                title: 'Budget Exceeded',
                body: alertText,
                priority: 'high',
              );
            }
          }
        }
        budgetCompliancePoints = (compliantCount / budgets.length) * 25.0;
      }

      double expenseStabilityPoints = 20.0;
      if (lastMonthExpense > 0) {
        if (currentExpense <= lastMonthExpense) {
          expenseStabilityPoints = 20.0;
        } else {
          final increase = (currentExpense - lastMonthExpense) / lastMonthExpense;
          expenseStabilityPoints = max(0.0, 20.0 - (increase * 20.0));
        }
      }

      double incomeConsistencyPoints = currentIncome > 0 ? 10.0 : 0.0;
      double savingsProgressPoints = (currentIncome - currentExpense) > 0 ? 15.0 : 0.0;

      final totalScore = (savingsRatePoints +
              budgetCompliancePoints +
              expenseStabilityPoints +
              incomeConsistencyPoints +
              savingsProgressPoints)
          .round()
          .clamp(0, 100);

      String status = 'Excellent';
      if (totalScore < 40) {
        status = 'Critical';
      } else if (totalScore < 60) {
        status = 'Fair';
      } else if (totalScore < 80) {
        status = 'Healthy';
      }

      // 4. Forecast Calculations
      final currentDay = now.day;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final avgDaily = currentDay > 0 ? (currentExpense ~/ currentDay) : 0;
      final projectedSpend = avgDaily * daysInMonth;

      if (currentExpense > currentIncome && currentIncome > 0) {
        alerts.add('Warning: Your spending exceeds your income this month.');
      }

      // Detect Spikes
      currentCategorySpend.forEach((catId, currentSpend) {
        final lastSpend = lastCategorySpend[catId] ?? 0;
        final catName = categoriesMap[catId] ?? 'Category';
        if (lastSpend > 2000 && currentSpend > lastSpend * 1.5) {
          final percent = (((currentSpend - lastSpend) / lastSpend) * 100).toStringAsFixed(0);
          alerts.add('Spending on $catName spiked by $percent% compared to last month!');
        }
      });

      // Update state with local analysis
      state = state.copyWith(
        healthScore: totalScore,
        healthStatus: status,
        healthBreakdown: {
          'Savings Rate': savingsRatePoints,
          'Budget Compliance': budgetCompliancePoints,
          'Expense Stability': expenseStabilityPoints,
          'Income Consistency': incomeConsistencyPoints,
          'Savings Progress': savingsProgressPoints,
        },
        projectedMonthEndSpend: projectedSpend,
        totalIncome: currentIncome,
        totalExpense: currentExpense,
        averageDailySpend: avgDaily,
        spendingAlerts: alerts,
      );

      // Load insights (local or cloud)
      if (state.aiInsights.isEmpty) {
        await loadInsights();
      }
    } catch (e) {
      debugPrint('Error calculating advisor overview: $e');
    }
  }

  Future<void> loadInsights() async {
    state = state.copyWith(isLoadingInsights: true, insightsError: null);
    try {
      final dio = _ref.read(dioClientProvider).dio;
      final auth = _ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Compile financial context summary
      final contextText = _buildFinancialSummaryString();

      final response = await dio.post('/ai/insights', data: {'context': contextText});
      if (response.statusCode == 200 && response.data != null) {
        final insightsList = List<String>.from(response.data['insights']);
        state = state.copyWith(
          aiInsights: insightsList,
          isLoadingInsights: false,
        );
        return;
      }
    } catch (e) {
      debugPrint('AI insights loading failed: $e. Falling back to local rule-based insights.');
    }

    // Fallback to local rule-based insights
    final localInsights = _generateLocalRuleInsights();
    state = state.copyWith(
      aiInsights: localInsights,
      isLoadingInsights: false,
    );
  }

  String _buildFinancialSummaryString() {
    final savingsRateText = state.totalIncome > 0
        ? '${(((state.totalIncome - state.totalExpense) / state.totalIncome) * 100).toStringAsFixed(0)}%'
        : '0%';
    final projectedOverIncomeText = state.projectedMonthEndSpend > state.totalIncome ? 'Yes' : 'No';

    return 'Financial Health Score: ${state.healthScore}/100. '
        'Monthly Income: ₹${(state.totalIncome / 100).toStringAsFixed(2)}. '
        'Monthly Expenses: ₹${(state.totalExpense / 100).toStringAsFixed(2)}. '
        'Savings Rate: $savingsRateText. '
        'Projected Month-End Spend: ₹${(state.projectedMonthEndSpend / 100).toStringAsFixed(2)}. '
        'Does projected spend exceed income: $projectedOverIncomeText. '
        'Alerts present: ${state.spendingAlerts.join("; ")}';
  }

  List<String> _generateLocalRuleInsights() {
    final List<String> insights = [];

    // 1. Savings rate insight
    if (state.totalIncome > 0) {
      final rate = (state.totalIncome - state.totalExpense) / state.totalIncome;
      if (rate >= 0.3) {
        insights.add('Great job! Your savings rate is above 30%. Consider putting excess funds into recurring investments.');
      } else if (rate > 0) {
        insights.add('Your current savings rate is ${ (rate * 100).toStringAsFixed(0) }%. Try reducing shopping or dining out to hit a target of 20%.');
      } else {
        insights.add('You spent more than you earned this month. Review your transactions and cut down on non-essential categories.');
      }
    } else {
      insights.add('No income recorded this month. Set up your regular salary deposits to get savings rate analysis.');
    }

    // 2. Forecast insight
    if (state.projectedMonthEndSpend > state.totalIncome && state.totalIncome > 0) {
      insights.add('At your current pace, you will overspend your income by ₹${ ((state.projectedMonthEndSpend - state.totalIncome) / 100).toStringAsFixed(0) } at month end.');
    } else {
      insights.add('Your month-end spending forecast is ₹${ (state.projectedMonthEndSpend / 100).toStringAsFixed(0) }, keeping you well within safe balance limits.');
    }

    // 3. General financial advice
    insights.add('Building a solid emergency reserve covering 3 months of expenses is the most effective way to secure your financial plan.');

    return insights;
  }
}

final StateNotifierProvider<AdvisorNotifier, AdvisorState> advisorProvider =
    StateNotifierProvider<AdvisorNotifier, AdvisorState>((ref) {
  return AdvisorNotifier(ref);
});
