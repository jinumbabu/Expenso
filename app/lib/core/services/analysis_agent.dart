import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;
import '../database/app_database.dart';
import 'ai_provider_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AnalysisAgent {
  final AppDatabase _db;
  final AiProviderManager _aiManager;

  AnalysisAgent(this._db, this._aiManager);

  /// Performs full analysis on user's finances and yields list of insights.
  Future<Map<String, dynamic>> analyzeFinances(String userId, {String provider = 'gemini'}) async {
    dev.log('AnalysisAgent: Beginning financial analysis for user $userId');
    final now = DateTime.now();
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    
    // Last month boundary calculations
    final startOfLastMonth = DateTime(now.month == 1 ? now.year - 1 : now.year, now.month == 1 ? 12 : now.month - 1, 1);
    
    // Fetch transactions
    final allTxs = await _db.transactionDao.getTransactionsForUser(userId);
    final thisMonthTxs = allTxs.where((tx) => tx.date.isAfter(startOfThisMonth) || tx.date.isAtSameMomentAs(startOfThisMonth)).toList();
    final lastMonthTxs = allTxs.where((tx) => tx.date.isAfter(startOfLastMonth) && tx.date.isBefore(startOfThisMonth)).toList();

    // Fetch Categories and map them
    final categories = await _db.categoryDao.getCategoriesForUser(userId);
    final categoriesMap = {for (var c in categories) c.id: c};

    // 1. Calculate basics for this month
    int thisMonthIncome = 0;
    int thisMonthExpense = 0;
    final Map<String, int> categorySpendingThisMonth = {};
    int weekendSpendingThisMonth = 0;

    for (var tx in thisMonthTxs) {
      if (tx.type == 'income') {
        thisMonthIncome += tx.amount;
      } else if (tx.type == 'expense') {
        thisMonthExpense += tx.amount;
        final catName = categoriesMap[tx.categoryId]?.name ?? 'Uncategorized';
        categorySpendingThisMonth[catName] = (categorySpendingThisMonth[catName] ?? 0) + tx.amount;
        
        // Weekend spending check (Saturday = 6, Sunday = 7)
        if (tx.date.weekday == DateTime.saturday || tx.date.weekday == DateTime.sunday) {
          weekendSpendingThisMonth += tx.amount;
        }
      }
    }

    // 2. Calculate basics for last month
    int lastMonthIncome = 0;
    int lastMonthExpense = 0;
    final Map<String, int> categorySpendingLastMonth = {};

    for (var tx in lastMonthTxs) {
      if (tx.type == 'income') {
        lastMonthIncome += tx.amount;
      } else if (tx.type == 'expense') {
        lastMonthExpense += tx.amount;
        final catName = categoriesMap[tx.categoryId]?.name ?? 'Uncategorized';
        categorySpendingLastMonth[catName] = (categorySpendingLastMonth[catName] ?? 0) + tx.amount;
      }
    }

    // 3. Compare discretionary and non-discretionary spending
    int discretionarySpend = 0;
    int nonDiscretionarySpend = 0;
    categorySpendingThisMonth.forEach((cat, amount) {
      final lower = cat.toLowerCase();
      if (lower.contains('food') || lower.contains('shopping') || lower.contains('entertainment') || lower.contains('fuel')) {
        discretionarySpend += amount;
      } else {
        nonDiscretionarySpend += amount;
      }
    });

    // 4. Generate local rule-based insights
    final List<String> localInsights = [];

    // Savings rate insight
    final double savingsRate = thisMonthIncome > 0 ? (thisMonthIncome - thisMonthExpense) / thisMonthIncome : 0.0;
    final double savingsRatePct = savingsRate * 100;
    if (savingsRatePct < 10) {
      localInsights.add('Your savings rate is ${savingsRatePct.toStringAsFixed(1)}%. Aim for 20% to reach your goals faster.');
    } else {
      localInsights.add('Great job! Your savings rate is ${savingsRatePct.toStringAsFixed(1)}% this month.');
    }

    // Food spending comparison
    final foodThis = categorySpendingThisMonth['Food'] ?? 0;
    final foodLast = categorySpendingLastMonth['Food'] ?? 0;
    if (foodThis > 0 && foodLast > 0) {
      final changePct = ((foodThis - foodLast) / foodLast) * 100;
      if (changePct > 10) {
        localInsights.add('Food spending increased by ${changePct.toStringAsFixed(0)}% compared to last month.');
      } else if (changePct < -10) {
        localInsights.add('Awesome! You reduced your food spending by ${changePct.abs().toStringAsFixed(0)}% compared to last month.');
      }
    } else if (foodThis > 500000) { // > ₹5000
      localInsights.add('Food spending accounts for ₹${(foodThis / 100.0).toStringAsFixed(0)}. Reducing dining out could save you around ₹2,000 monthly.');
    }

    // Discretionary and Weekend spending insights
    if (discretionarySpend > 0) {
      final double weekendPct = (weekendSpendingThisMonth / discretionarySpend) * 100;
      if (weekendPct > 30) {
        localInsights.add('Weekend spending accounts for ${weekendPct.toStringAsFixed(0)}% of discretionary expenses.');
      }
    }

    // Subscription cost warnings
    final activeSubscriptions = await _db.subscriptionDao.getActiveSubscriptions(userId);
    if (activeSubscriptions.isNotEmpty) {
      int totalSubscriptionMonthly = 0;
      for (var sub in activeSubscriptions) {
        totalSubscriptionMonthly += sub.monthlyCost;
      }
      final double annualSubCost = (totalSubscriptionMonthly * 12) / 100.0;
      if (annualSubCost > 5000) {
        localInsights.add('You can save ₹${(totalSubscriptionMonthly / 100.0).toStringAsFixed(0)} monthly (₹${annualSubCost.toStringAsFixed(0)} annually) by reducing subscription expenses.');
      }
    }

    // Cash flow health check
    if (thisMonthExpense > thisMonthIncome && thisMonthIncome > 0) {
      localInsights.add('Warning: Your expenses exceed your income this month by ₹${((thisMonthExpense - thisMonthIncome) / 100.0).toStringAsFixed(2)}.');
    }

    // 5. Query active AI Provider for Advanced Insights if enabled
    String aiResponse = 'LOCAL_MODE';
    final StringBuffer promptBuffer = StringBuffer();
    promptBuffer.writeln('Review the user\'s financial details for this month and generate 3 bullet points of short, actionable financial advice or insights.');
    promptBuffer.writeln('This Month Income: ₹${(thisMonthIncome / 100.0).toStringAsFixed(2)}');
    promptBuffer.writeln('This Month Expenses: ₹${(thisMonthExpense / 100.0).toStringAsFixed(2)}');
    promptBuffer.writeln('Last Month Income: ₹${(lastMonthIncome / 100.0).toStringAsFixed(2)}');
    promptBuffer.writeln('Last Month Expenses: ₹${(lastMonthExpense / 100.0).toStringAsFixed(2)}');
    promptBuffer.writeln('Top spending categories:');
    categorySpendingThisMonth.forEach((cat, val) {
      promptBuffer.writeln('- $cat: ₹${(val / 100.0).toStringAsFixed(2)}');
    });

    aiResponse = await _aiManager.analyzeWithActiveProvider(
      promptBuffer.toString(),
      systemInstruction: 'You are Expenso Financial Analysis Agent. Write brief, professional financial advice. Speak directly to the user.',
      provider: provider,
    );

    final List<String> finalInsights = [];
    if (aiResponse == 'LOCAL_MODE') {
      finalInsights.addAll(localInsights);
    } else {
      // Split AI lines into individual bullets
      final lines = aiResponse.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty && (l.startsWith('-') || l.startsWith('*') || RegExp(r'^\d+\.').hasMatch(l))).toList();
      if (lines.isNotEmpty) {
        for (var line in lines) {
          final cleanLine = line.replaceFirst(RegExp(r'^[\-\*\d\.\s]+'), '');
          if (cleanLine.isNotEmpty) {
            finalInsights.add(cleanLine);
          }
        }
      } else {
        finalInsights.addAll(localInsights);
      }
    }

    // Ensure we have at least some insights
    if (finalInsights.isEmpty) {
      finalInsights.add('Track your daily expenses diligently to generate personalized budgeting insights.');
    }

    // 6. Log Agent Action
    await _db.agentLogDao.insertLog(
      AgentLog(
        id: const Uuid().v4(),
        agentName: 'Financial Analysis Agent',
        actionType: 'FINANCIAL_ANALYSIS_COMPLETED',
        decisionDescription: 'Completed financial analysis. Savings rate: ${savingsRatePct.toStringAsFixed(1)}%. Discretionary: ₹${(discretionarySpend / 100.0).toStringAsFixed(0)}. Generated ${finalInsights.length} insights.',
        confidenceScore: 0.95,
        timestamp: DateTime.now(),
      ),
    );

    return {
      'thisMonthIncome': thisMonthIncome,
      'thisMonthExpense': thisMonthExpense,
      'lastMonthIncome': lastMonthIncome,
      'lastMonthExpense': lastMonthExpense,
      'savingsRate': savingsRate,
      'discretionarySpend': discretionarySpend,
      'nonDiscretionarySpend': nonDiscretionarySpend,
      'categorySpendingThisMonth': categorySpendingThisMonth,
      'insights': finalInsights,
    };
  }
}

final Provider<AnalysisAgent> analysisAgentProvider = Provider<AnalysisAgent>((ref) {
  final db = ref.watch(databaseProvider);
  final aiManager = ref.watch(aiProviderManagerProvider);
  return AnalysisAgent(db, aiManager);
});
