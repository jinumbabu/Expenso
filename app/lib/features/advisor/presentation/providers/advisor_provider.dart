import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../goals/presentation/providers/goals_provider.dart';
import '../../../../core/services/financial_calculation_service.dart';

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

  // Forecast details
  final int expectedSavings;
  final int remainingBalance;
  final double forecastConfidence;

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
    required this.expectedSavings,
    required this.remainingBalance,
    required this.forecastConfidence,
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
        insightsError = null,
        expectedSavings = 0,
        remainingBalance = 0,
        forecastConfidence = 0.0;

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
    int? expectedSavings,
    int? remainingBalance,
    double? forecastConfidence,
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
      expectedSavings: expectedSavings ?? this.expectedSavings,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      forecastConfidence: forecastConfidence ?? this.forecastConfidence,
    );
  }
}

class AdvisorNotifier extends StateNotifier<AdvisorState> {
  final Ref _ref;

  AdvisorNotifier(this._ref) : super(AdvisorState.initial()) {
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
      final endOfCurrentMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 1).subtract(const Duration(milliseconds: 1));

      // Fetch from db
      final transactions = await db.transactionDao.getTransactionsForUser(userId);
      final budgets = await db.budgetDao.getBudgetsForUser(userId);
      final categories = await db.categoryDao.getCategoriesForUser(userId);
      final categoriesMap = {for (var c in categories) c.id: c.name};
      final accounts = await db.accountDao.getAccountsForUser(userId);

      // 1. Current month transactions
      final currentMonthTxs = transactions.where((tx) =>
          tx.date.isAfter(startOfCurrentMonth.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(endOfCurrentMonth.add(const Duration(seconds: 1)))).toList();

      final lastMonthTxs = transactions.where((tx) =>
          tx.date.isAfter(startOfLastMonth.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(endOfLastMonth.add(const Duration(seconds: 1)))).toList();

      // Use shared calculation service
      final currentFinancialData = FinancialCalculationService.calculate(
        transactions: transactions,
        selectedMonth: now,
      );
      final lastFinancialData = FinancialCalculationService.calculate(
        transactions: transactions,
        selectedMonth: DateTime(now.year, now.month - 1, 1),
      );

      // 2. Sum totals
      int currentIncome = currentFinancialData.monthlyIncome;
      int currentExpense = currentFinancialData.monthlyExpenses;
      final currentCategorySpend = <String, int>{};

      for (var tx in currentMonthTxs) {
        if (FinancialCalculationService.isExpense(tx)) {
          if (tx.categoryId != null) {
            currentCategorySpend[tx.categoryId!] = (currentCategorySpend[tx.categoryId!] ?? 0) + tx.amount.toInt();
          }
        }
      }

      int lastMonthExpense = lastFinancialData.monthlyExpenses;
      final lastCategorySpend = <String, int>{};
      for (var tx in lastMonthTxs) {
        if (FinancialCalculationService.isExpense(tx)) {
          if (tx.categoryId != null) {
            lastCategorySpend[tx.categoryId!] = (lastCategorySpend[tx.categoryId!] ?? 0) + tx.amount.toInt();
          }
        }
      }

      // 3. Score Calculations (STEP 16)
      
      // Savings Rate (30 pts)
      double savingsRatePoints = 0;
      if (currentIncome > 0) {
        final rate = (currentIncome - currentExpense) / currentIncome;
        if (rate >= 0.30) {
          savingsRatePoints = 30.0;
        } else if (rate > 0) {
          savingsRatePoints = (rate / 0.30) * 30.0;
        }
      } else {
        savingsRatePoints = currentExpense > 0 ? 0.0 : 30.0;
      }

      // Budget Compliance (20 pts)
      double budgetCompliancePoints = 20.0;
      final List<String> alerts = [];
      if (budgets.isNotEmpty) {
        int compliantCount = 0;
        for (var budget in budgets) {
          final spent = currentCategorySpend[budget.categoryId] ?? 0;
          final catName = categoriesMap[budget.categoryId] ?? 'Category';
          if (spent <= budget.amount.toInt()) {
            compliantCount++;
          } else {
            final over = ((spent - budget.amount) / 100.0).toStringAsFixed(2);
            alerts.add('Budget for $catName exceeded by ₹$over!');
          }
        }
        budgetCompliancePoints = (compliantCount / budgets.length) * 20.0;
      }

      // Expense Stability (15 pts)
      double expenseStabilityPoints = 15.0;
      if (lastMonthExpense > 0) {
        if (currentExpense <= lastMonthExpense) {
          expenseStabilityPoints = 15.0;
        } else {
          final increase = (currentExpense - lastMonthExpense) / lastMonthExpense;
          expenseStabilityPoints = max(0.0, 15.0 - (increase * 15.0));
        }
      }

      // Emergency Fund (15 pts)
      double emergencyFundPoints = 0;
      int reserves = 0;
      int savingsCashBalance = 0;
      for (var acc in accounts) {
        if (acc.type == 'bank' || acc.type == 'cash' || acc.type == 'savings' || acc.type == 'wallet') {
          reserves += acc.balance;
          savingsCashBalance += acc.balance;
        }
      }
      double fundRatio = 0.0;
      if (accounts.isEmpty) {
        emergencyFundPoints = 15.0;
        fundRatio = 3.0; // Assume compliant when empty
      } else {
        final double monthlyExpenseBaseline = currentExpense > 0 ? currentExpense.toDouble() : 1000000.0; // Min ₹10,000 cents
        fundRatio = reserves / monthlyExpenseBaseline;
        if (fundRatio >= 3.0) {
          emergencyFundPoints = 15.0;
        } else if (fundRatio > 0) {
          emergencyFundPoints = (fundRatio / 3.0) * 15.0;
        }
      }

      // Debt Ratio (10 pts)
      double debtPoints = 10.0;
      int ccDebt = 0;
      int loanDebt = 0;
      for (var acc in accounts) {
        if (acc.type == 'credit_card') {
          ccDebt += max(0, 1000000 - acc.balance); // outstanding
        } else if (acc.type == 'loan') {
          loanDebt += max(0, 1000000 - acc.balance);
        }
      }
      final totalDebt = ccDebt + loanDebt;
      if (totalDebt > 0 && savingsCashBalance > 0) {
        final debtRatio = totalDebt / savingsCashBalance;
        if (debtRatio <= 0.3) {
          debtPoints = (1.0 - debtRatio / 0.3) * 10.0;
        } else {
          debtPoints = 0.0;
        }
      } else if (totalDebt > 0) {
        debtPoints = 0.0;
      }

      // Bill Payment History (10 pts)
      double billPoints = 10.0;
      final billTxs = transactions.where((t) =>
          t.type == 'upcoming_bill' ||
          t.type == 'credit_card_bill' ||
          t.type == 'credit_card_bill_reminder').toList();
      if (billTxs.isNotEmpty) {
        final paidCount = billTxs.where((t) => t.billStatus == 'paid').length;
        billPoints = (paidCount / billTxs.length) * 10.0;
      }

      final totalScore = (savingsRatePoints +
              budgetCompliancePoints +
              expenseStabilityPoints +
              emergencyFundPoints +
              debtPoints +
              billPoints)
          .round()
          .clamp(0, 100);

      String status = 'Excellent';
      if (totalScore < 50) {
        status = 'Poor';
      } else if (totalScore < 70) {
        status = 'Average';
      } else if (totalScore < 90) {
        status = 'Good';
      }

      // 4. Forecast Calculations (STEP 17)
      final currentDay = now.day;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final avgDaily = currentDay > 0 ? (currentExpense ~/ currentDay) : 0;
      final projectedSpend = avgDaily * daysInMonth;
      final expectedSavings = currentIncome - projectedSpend;
      final confidence = (currentDay / daysInMonth) * 100.0;

      // Update State
      state = state.copyWith(
        healthScore: totalScore,
        healthStatus: status,
        healthBreakdown: {
          'Savings Rate': savingsRatePoints,
          'Budget Compliance': budgetCompliancePoints,
          'Expense Stability': expenseStabilityPoints,
          'Emergency Fund': emergencyFundPoints,
          'Debt Ratio': debtPoints,
          'Bill Payment History': billPoints,
        },
        projectedMonthEndSpend: projectedSpend,
        totalIncome: currentIncome,
        totalExpense: currentExpense,
        averageDailySpend: avgDaily,
        spendingAlerts: alerts,
        expectedSavings: expectedSavings,
        remainingBalance: reserves,
        forecastConfidence: confidence,
      );

      // Generate Prioritized AI Insights (STEP 18)
      final List<String> dynamicInsights = [];

      // Check for Salary
      final recentSalary = transactions.any((tx) =>
          tx.type == 'income' &&
          tx.transactionType == 'Income' &&
          tx.merchant?.toLowerCase() == 'salary' &&
          tx.date.isAfter(DateTime.now().subtract(const Duration(days: 2))));
      if (recentSalary) {
        dynamicInsights.add('Salary received yesterday! Budget your savings first.');
      }

      // Spikes
      currentCategorySpend.forEach((catId, currentSpend) {
        final lastSpend = lastCategorySpend[catId] ?? 0;
        final catName = categoriesMap[catId] ?? 'Category';
        if (lastSpend > 200000 && currentSpend > lastSpend * 1.20) {
          final percent = (((currentSpend - lastSpend) / lastSpend) * 100).toStringAsFixed(0);
          dynamicInsights.add('$catName spending increased $percent% compared to last month.');
        }
      });

      // Budget compliance
      if (budgetCompliancePoints < 20.0) {
        dynamicInsights.add('Entertainment or shopping budget exceeded. Pause non-essential purchases.');
      }

      // Bill Reminders
      final pendingBills = transactions.where((t) =>
          (t.type == 'upcoming_bill' || t.type == 'credit_card_bill') &&
          t.billStatus == 'pending' &&
          t.dueDate != null).toList();
      for (var bill in pendingBills) {
        final diff = bill.dueDate!.difference(now).inDays;
        if (diff >= 0 && diff <= 3) {
          dynamicInsights.add('${bill.merchant ?? "Credit card bill"} due in $diff days.');
        }
      }

      // Emergency Fund
      if (fundRatio < 3.0) {
        dynamicInsights.add('Emergency fund covers only ${fundRatio.toStringAsFixed(1)} months of expenses. Target 3 months.');
      }

      // Expected Savings
      if (expectedSavings > 0) {
        dynamicInsights.add('You will save ₹${(expectedSavings / 100.0).toStringAsFixed(0)} this month.');
      } else if (expectedSavings < 0) {
        dynamicInsights.add('Warning: Forecasted monthly spend exceeds income by ₹${(-expectedSavings / 100.0).toStringAsFixed(0)}.');
      }

      // Fallback
      if (dynamicInsights.isEmpty) {
        dynamicInsights.add('Building a solid emergency reserve is the most effective way to secure your financial plan.');
      }

      state = state.copyWith(
        projectedMonthEndSpend: projectedSpend,
        totalIncome: currentIncome,
        totalExpense: currentExpense,
        averageDailySpend: avgDaily,
        spendingAlerts: alerts,
        expectedSavings: expectedSavings,
        remainingBalance: reserves,
        forecastConfidence: confidence,
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
        insights.add('Your current savings rate is ${(rate * 100).toStringAsFixed(0)}%. Try reducing shopping or dining out to hit a target of 20%.');
      } else {
        insights.add('You spent more than you earned this month. Review your transactions and cut down on non-essential categories.');
      }
    } else {
      insights.add('No income recorded this month. Set up your regular salary deposits to get savings rate analysis.');
    }

    // 2. Forecast insight
    if (state.projectedMonthEndSpend > state.totalIncome && state.totalIncome > 0) {
      insights.add('At your current pace, you will overspend your income by ₹${((state.projectedMonthEndSpend - state.totalIncome) / 100).toStringAsFixed(0)} at month end.');
    } else {
      insights.add('Your month-end spending forecast is ₹${(state.projectedMonthEndSpend / 100).toStringAsFixed(0)}, keeping you well within safe balance limits.');
    }

    // 3. General financial advice
    insights.add('Building a solid emergency reserve covering 3 months of expenses is the most effective way to secure your financial plan.');

    return insights;
  }
}

// Watching Riverpod providers triggers automatic recalculation in real-time (STEP 19)
final StateNotifierProvider<AdvisorNotifier, AdvisorState> advisorProvider =
    StateNotifierProvider<AdvisorNotifier, AdvisorState>((ref) {
  ref.watch(expenseListNotifierProvider);
  ref.watch(budgetListNotifierProvider);
  ref.watch(goalsListNotifierProvider);
  return AdvisorNotifier(ref);
});
