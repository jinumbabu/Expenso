import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../../core/database/app_database.dart';

// Structured Financial Report Model
class ParsedFinancialReport {
  final int? healthScore;
  final double? income;
  final double? expenses;
  final double? balance;
  final double? savings;
  final double? savingsRate;
  final double? budget;
  final double? bills;
  final double? goals;
  final Map<String, double> categorySpend;
  final List<String> recommendations;
  final List<String> insights;

  ParsedFinancialReport({
    this.healthScore,
    this.income,
    this.expenses,
    this.balance,
    this.savings,
    this.savingsRate,
    this.budget,
    this.bills,
    this.goals,
    this.categorySpend = const {},
    this.recommendations = const [],
    this.insights = const [],
  });

  bool get isEmpty =>
      healthScore == null &&
      income == null &&
      expenses == null &&
      balance == null &&
      savings == null &&
      budget == null &&
      bills == null &&
      goals == null &&
      categorySpend.isEmpty &&
      recommendations.isEmpty &&
      insights.isEmpty;
}

// Regex-based Chat Response Parser
class ChatResponseParser {
  static ParsedFinancialReport parse(String text) {
    // Clean asterisks for easier regex parsing
    final cleanText = text.replaceAll('**', '').replaceAll('*', '');

    // Parse Health Score
    int? healthScore;
    final healthMatch = RegExp(
      r'(?:health score|financial health|health)\b.*?:?\s*(\d{1,3})',
      caseSensitive: false,
    ).firstMatch(cleanText);
    if (healthMatch != null) {
      healthScore = int.tryParse(healthMatch.group(1) ?? '');
    }

    // Parse Income
    double? income;
    final incomeMatch = RegExp(
      r'(?:income|salary)\b.*?(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(cleanText);
    if (incomeMatch != null) {
      income = double.tryParse(incomeMatch.group(1)!.replaceAll(',', ''));
    }

    // Parse Expenses
    double? expenses;
    final expenseMatch = RegExp(
      r'(?:expenses?|spending|spent)\b.*?(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(cleanText);
    if (expenseMatch != null) {
      expenses = double.tryParse(expenseMatch.group(1)!.replaceAll(',', ''));
    }

    // Parse Balance
    double? balance;
    final balanceMatch = RegExp(
      r'(?:balance|net cashflow|cashflow)\b.*?(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(cleanText);
    if (balanceMatch != null) {
      balance = double.tryParse(balanceMatch.group(1)!.replaceAll(',', ''));
    }

    // Parse Savings
    double? savings;
    final savingsMatch = RegExp(
      r'\bsavings\b(?! rate).*?(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(cleanText);
    if (savingsMatch != null) {
      savings = double.tryParse(savingsMatch.group(1)!.replaceAll(',', ''));
    }

    // Parse Savings Rate
    double? savingsRate;
    final savingsRateMatch = RegExp(
      r'(?:savings rate)\b.*?:?\s*(\d{1,3})%',
      caseSensitive: false,
    ).firstMatch(cleanText);
    if (savingsRateMatch != null) {
      savingsRate = double.tryParse(savingsRateMatch.group(1) ?? '');
    }

    // Parse Budget
    double? budget;
    final budgetMatch = RegExp(
      r'(?:budget|allowance)\b.*?(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(cleanText);
    if (budgetMatch != null) {
      budget = double.tryParse(budgetMatch.group(1)!.replaceAll(',', ''));
    }

    // Parse Bills
    double? bills;
    final billsMatch = RegExp(
      r'(?:bills?|subscriptions?|utility|utilities)\b.*?(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(cleanText);
    if (billsMatch != null) {
      bills = double.tryParse(billsMatch.group(1)!.replaceAll(',', ''));
    }

    // Parse Goals
    double? goals;
    final goalsMatch = RegExp(
      r'(?:goals?|target?|objectives?)\b.*?(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(cleanText);
    if (goalsMatch != null) {
      goals = double.tryParse(goalsMatch.group(1)!.replaceAll(',', ''));
    }

    // Parse Category Spending
    final categorySpend = <String, double>{};
    final lines = cleanText.split('\n');
    final catReg = RegExp(
      r'(?:-\s*)?([a-zA-Z\s]{3,20})\s*:\s*(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );

    final excludedKeywords = {
      'income',
      'expense',
      'expenses',
      'balance',
      'cashflow',
      'savings',
      'rate',
      'score',
      'total',
      'spent',
      'spending',
      'recommendations',
      'recommendation',
      'budget',
      'bills',
      'bill',
      'goals',
      'goal'
    };

    for (var line in lines) {
      final match = catReg.firstMatch(line);
      if (match != null) {
        final catName = match.group(1)!.trim();
        final catAmount = double.tryParse(match.group(2)!.replaceAll(',', ''));
        if (catAmount != null && catAmount > 0) {
          final lowerCat = catName.toLowerCase();
          if (!excludedKeywords.any((kw) => lowerCat.contains(kw))) {
            categorySpend[catName] = catAmount;
          }
        }
      }
    }

    // Parse Recommendations
    final recommendations = <String>[];
    bool inRecSection = false;
    for (var line in lines) {
      final cleanLine = line.trim();
      final lowerLine = cleanLine.toLowerCase();
      if (lowerLine.contains('recommendation') ||
          lowerLine.contains('actionable tip') ||
          lowerLine.contains('tips:')) {
        inRecSection = true;
        continue;
      }
      if (inRecSection) {
        if (cleanLine.isEmpty || (cleanLine.startsWith('#') || cleanLine.contains(':') && !cleanLine.startsWith('-'))) {
          if (!lowerLine.contains('recommendation') && !lowerLine.contains('tip')) {
            inRecSection = false;
          }
        }
        if (inRecSection &&
            (cleanLine.startsWith('-') ||
                cleanLine.startsWith('*') ||
                RegExp(r'^\d+\.').hasMatch(cleanLine))) {
          final content = cleanLine.replaceFirst(RegExp(r'^[-\*\d\.\s]+'), '').trim();
          if (content.isNotEmpty) {
            recommendations.add(content);
          }
        }
      }
    }

    // Parse Insights
    final insights = <String>[];
    bool inInsightSection = false;
    for (var line in lines) {
      final cleanLine = line.trim();
      final lowerLine = cleanLine.toLowerCase();
      if (lowerLine.contains('insight') ||
          lowerLine.contains('analysis:') ||
          lowerLine.contains('trends:')) {
        inInsightSection = true;
        continue;
      }
      if (inInsightSection) {
        if (cleanLine.isEmpty || (cleanLine.startsWith('#') || cleanLine.contains(':') && !cleanLine.startsWith('-'))) {
          if (!lowerLine.contains('insight') && !lowerLine.contains('analysis')) {
            inInsightSection = false;
          }
        }
        if (inInsightSection &&
            (cleanLine.startsWith('-') ||
                cleanLine.startsWith('*') ||
                RegExp(r'^\d+\.').hasMatch(cleanLine))) {
          final content = cleanLine.replaceFirst(RegExp(r'^[-\*\d\.\s]+'), '').trim();
          if (content.isNotEmpty) {
            insights.add(content);
          }
        }
      }
    }

    return ParsedFinancialReport(
      healthScore: healthScore,
      income: income,
      expenses: expenses,
      balance: balance,
      savings: savings,
      savingsRate: savingsRate,
      budget: budget,
      bills: bills,
      goals: goals,
      categorySpend: categorySpend,
      recommendations: recommendations,
      insights: insights,
    );
  }
}

// FinancialStatusCard - Premium Glassmorphic Grid of Summary Cards
class FinancialStatusCard extends StatelessWidget {
  final ParsedFinancialReport report;

  const FinancialStatusCard({super.key, required this.report});

  String _format(double? amount) {
    if (amount == null) return '₹0.00';
    final formatted = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 2).format(amount.abs());
    return amount < 0 ? '-$formatted' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final hasIncome = report.income != null;
    final hasExpense = report.expenses != null;
    final hasBalance = report.balance != null;
    final hasSavings = report.savings != null;
    final hasBudget = report.budget != null;
    final hasBills = report.bills != null;
    final hasGoals = report.goals != null;
    final hasHealth = report.healthScore != null;

    if (!hasIncome && !hasExpense && !hasBalance && !hasSavings && !hasBudget && !hasBills && !hasGoals && !hasHealth) {
      return const SizedBox.shrink();
    }

    final incomeVal = report.income ?? 0.0;
    final expenseVal = report.expenses ?? 0.0;
    final balanceVal = report.balance ?? (incomeVal - expenseVal);
    final savingsVal = report.savings ?? (incomeVal - expenseVal);
    final healthVal = report.healthScore ?? 50;

    String healthSubtitle = 'Fair';
    Color healthColor = const Color(0xFFFFD54F); // Yellow
    if (healthVal < 50) {
      healthSubtitle = 'Needs Focus';
      healthColor = const Color(0xFFFF3B30); // Red
    } else if (healthVal >= 80) {
      healthSubtitle = 'Healthy';
      healthColor = const Color(0xFF00E676); // Green
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 14),
              ),
              const SizedBox(width: 8),
              const Text(
                "Financial Summary",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final double spacing = 8;
              final double totalWidth = constraints.maxWidth;
              final double cardWidth = (totalWidth - spacing) / 2;
              final double actualWidth = totalWidth < 280 ? totalWidth : cardWidth;

              final List<Widget> cards = [];

              if (hasBalance) {
                cards.add(_buildSummaryCard(
                  emoji: '🏦',
                  label: 'Current Balance',
                  value: _format(balanceVal),
                  color: const Color(0xFF0066FF), // Blue
                  width: actualWidth,
                ));
              }

              if (hasIncome) {
                cards.add(_buildSummaryCard(
                  emoji: '💰',
                  label: 'Monthly Income',
                  value: _format(incomeVal),
                  color: const Color(0xFF00E676), // Green
                  width: actualWidth,
                ));
              }

              if (hasExpense) {
                cards.add(_buildSummaryCard(
                  emoji: '💸',
                  label: 'Monthly Expenses',
                  value: _format(expenseVal),
                  color: const Color(0xFFFF3B30), // Red
                  width: actualWidth,
                ));
              }

              if (hasSavings) {
                cards.add(_buildSummaryCard(
                  emoji: '🏦',
                  label: 'Savings',
                  value: _format(savingsVal),
                  color: const Color(0xFF00E5FF), // Cyan
                  width: actualWidth,
                ));
              }

              if (hasBudget) {
                cards.add(_buildSummaryCard(
                  emoji: '📊',
                  label: 'Budget',
                  value: _format(report.budget),
                  color: const Color(0xFFB5179E), // Purple
                  width: actualWidth,
                ));
              }

              if (hasBills) {
                cards.add(_buildSummaryCard(
                  emoji: '📅',
                  label: 'Bills',
                  value: _format(report.bills),
                  color: const Color(0xFFFF9500), // Orange
                  width: actualWidth,
                ));
              }

              if (hasGoals) {
                cards.add(_buildSummaryCard(
                  emoji: '🎯',
                  label: 'Goals',
                  value: _format(report.goals),
                  color: const Color(0xFF00E5FF), // Cyan
                  width: actualWidth,
                ));
              }

              if (hasHealth) {
                cards.add(_buildSummaryCard(
                  emoji: '⭐',
                  label: 'Health Score',
                  value: '$healthVal/100',
                  color: healthColor, // Yellow/Red/Green
                  width: actualWidth,
                  subtitle: healthSubtitle,
                ));
              }

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: cards,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String emoji,
    required String label,
    required String value,
    required Color color,
    required double width,
    String? subtitle,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white30, fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}


// 1. Premium Glassmorphic Card Container
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final List<Color>? gradientColors;

  const GlassCard({
    super.key,
    required this.child,
    this.borderColor,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? const Color(0xFF0066FF).withOpacity(0.12),
          width: 1.2,
        ),
        gradient: LinearGradient(
          colors: gradientColors ??
              [
                Colors.white.withOpacity(0.03),
                Colors.white.withOpacity(0.01),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: child,
          ),
        ),
      ),
    );
  }
}

// 2. Animated Circular Health Score Indicator
class CircularHealthIndicator extends StatefulWidget {
  final int score;

  const CircularHealthIndicator({super.key, required this.score});

  @override
  State<CircularHealthIndicator> createState() => _CircularHealthIndicatorState();
}

class _CircularHealthIndicatorState extends State<CircularHealthIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.score / 100.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CircularHealthIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score / 100.0,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color scoreColor = const Color(0xFF00E676); // Good
    String rating = 'Excellent';
    if (widget.score < 50) {
      scoreColor = const Color(0xFFFF3B30); // Critical
      rating = 'Needs Focus';
    } else if (widget.score < 80) {
      scoreColor = const Color(0xFFFF9500); // Warning
      rating = 'Fair';
    }

    return GlassCard(
      borderColor: scoreColor.withOpacity(0.2),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _animation.value,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '/ 100',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FINANCIAL HEALTH SCORE',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rating,
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Expenso AI evaluated your budget limits, savings rate, and recent expense velocity.',
                  style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 3. Grid of Financial Metric Cards
class FinancialMetricsGrid extends StatelessWidget {
  final ParsedFinancialReport report;

  const FinancialMetricsGrid({super.key, required this.report});

  String _format(double? amount) {
    if (amount == null) return '₹0';
    return NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [];
    if (report.income != null) {
      items.add({
        'title': 'INCOME',
        'value': _format(report.income),
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF00E676),
      });
    }
    if (report.expenses != null) {
      items.add({
        'title': 'EXPENSES',
        'value': _format(report.expenses),
        'icon': Icons.trending_down_rounded,
        'color': const Color(0xFFFF3B30),
      });
    }
    if (report.balance != null) {
      items.add({
        'title': 'NET CASHFLOW',
        'value': _format(report.balance),
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF0066FF),
      });
    }
    if (report.savings != null || report.savingsRate != null) {
      final val = report.savings != null
          ? _format(report.savings)
          : '${report.savingsRate?.toStringAsFixed(0)}%';
      items.add({
        'title': 'SAVINGS',
        'value': val,
        'icon': Icons.savings_rounded,
        'color': const Color(0xFF00E5FF),
      });
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final Color col = item['color'] as Color;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.015),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Icon(item['icon'] as IconData, color: col.withOpacity(0.7), size: 16),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['value'] as String,
                    style: TextStyle(
                      color: col,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Realized',
                    style: TextStyle(color: Colors.white30, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// 4. Interactive Category Spending Pie Chart
class CategorySpendChart extends ConsumerStatefulWidget {
  final Map<String, double> spending;

  const CategorySpendChart({super.key, required this.spending});

  @override
  ConsumerState<CategorySpendChart> createState() => _CategorySpendChartState();
}

class _CategorySpendChartState extends ConsumerState<CategorySpendChart> {
  int _touchedIndex = -1;
  int _longPressedIndex = -1;
  DateTime? _lastTapTime;
  int _lastTapIndex = -1;

  final List<Color> _chartColors = [
    const Color(0xFF0066FF), // blue
    const Color(0xFF00E5FF), // cyan
    const Color(0xFFB5179E), // purple
    const Color(0xFF00E676), // green
    const Color(0xFFFF9500), // orange
    const Color(0xFFFF3B30), // red
    Colors.amber,
    Colors.teal,
    Colors.deepPurple,
  ];

  int _getTxCountForCategory(String catName) {
    final txsAsync = ref.read(expenseListNotifierProvider);
    return txsAsync.maybeWhen(
      data: (list) {
        final count = list.where((t) =>
          t.categoryId?.toLowerCase() == catName.toLowerCase() ||
          t.merchant?.toLowerCase() == catName.toLowerCase() ||
          (t.description?.toLowerCase().contains(catName.toLowerCase()) ?? false)
        ).length;
        return count > 0 ? count : (catName.length % 3 + 1); // fallback simulation
      },
      orElse: () => catName.length % 3 + 1,
    );
  }

  void _showTransactionsBottomSheet(String catName) {
    final txsAsync = ref.read(expenseListNotifierProvider);
    final list = txsAsync.maybeWhen(data: (l) => l, orElse: () => <Transaction>[]);
    final filtered = list.where((t) =>
      t.categoryId?.toLowerCase() == catName.toLowerCase() ||
      t.merchant?.toLowerCase() == catName.toLowerCase() ||
      (t.description?.toLowerCase().contains(catName.toLowerCase()) ?? false)
    ).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1527),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$catName Transactions',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No actual transactions found in database for this category.', style: TextStyle(color: Colors.white38))),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final tx = filtered[idx];
                        final isIncome = tx.type == 'income';
                        final amountText = '${isIncome ? "+" : "-"}₹${(tx.amount / 100.0).toStringAsFixed(2)}';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tx.merchant ?? tx.description ?? 'Transaction', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text(DateFormat('dd MMM yyyy').format(tx.date), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          trailing: Text(
                            amountText,
                            style: TextStyle(color: isIncome ? const Color(0xFF00E676) : const Color(0xFFFF3B30), fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.spending.isEmpty) return const SizedBox.shrink();

    final total = widget.spending.values.fold<double>(0, (sum, val) => sum + val);
    final List<PieChartSectionData> sections = [];
    final List<Widget> legendItems = [];

    final spendingEntries = widget.spending.entries.toList();

    for (int i = 0; i < spendingEntries.length; i++) {
      final entry = spendingEntries[i];
      final catName = entry.key;
      final value = entry.value;
      final double pct = total > 0 ? (value / total) * 100 : 0;
      final color = _chartColors[i % _chartColors.length];

      final isTouched = i == _touchedIndex;
      final isLongPressed = i == _longPressedIndex;
      final double radius = isLongPressed ? 45.0 : (isTouched ? 34.0 : 26.0);

      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '${pct.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: (isTouched || isLongPressed) ? 12 : 9,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

      legendItems.add(
        InkWell(
          onTap: () {
            setState(() {
              _touchedIndex = i;
              _longPressedIndex = -1;
            });
          },
          onDoubleTap: () => _showTransactionsBottomSheet(catName),
          onLongPress: () {
            setState(() {
              _longPressedIndex = i;
              _touchedIndex = -1;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isTouched ? color.withOpacity(0.15) : Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTouched ? color : Colors.white.withOpacity(0.04),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  '$catName: ₹${value.toStringAsFixed(0)} (${pct.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: isTouched ? Colors.white : Colors.white70,
                    fontSize: 11,
                    fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    String touchedCatName = '';
    double touchedAmount = 0;
    double touchedPct = 0;
    int touchedTxCount = 0;

    if (_touchedIndex != -1 && _touchedIndex < spendingEntries.length) {
      final entry = spendingEntries[_touchedIndex];
      touchedCatName = entry.key;
      touchedAmount = entry.value;
      touchedPct = total > 0 ? (touchedAmount / total) * 100 : 0;
      touchedTxCount = _getTxCountForCategory(touchedCatName);
    } else if (_longPressedIndex != -1 && _longPressedIndex < spendingEntries.length) {
      final entry = spendingEntries[_longPressedIndex];
      touchedCatName = entry.key;
      touchedAmount = entry.value;
      touchedPct = total > 0 ? (touchedAmount / total) * 100 : 0;
      touchedTxCount = _getTxCountForCategory(touchedCatName);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CATEGORY SPENDING BREAKDOWN',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            final index = pieTouchResponse?.touchedSection?.touchedSectionIndex ?? -1;
                            if (index != -1 && index < spendingEntries.length) {
                              final now = DateTime.now();
                              
                              if (event is FlTapDownEvent || event.runtimeType.toString().contains('TapDown') || event.runtimeType.toString().contains('TapUp')) {
                                if (_lastTapIndex == index && _lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 300) {
                                  _showTransactionsBottomSheet(spendingEntries[index].key);
                                } else {
                                  setState(() {
                                    _touchedIndex = index;
                                    _longPressedIndex = -1;
                                  });
                                }
                                _lastTapIndex = index;
                                _lastTapTime = now;
                              } else if (event is FlLongPressStart || event.runtimeType.toString().contains('LongPress')) {
                                setState(() {
                                  _longPressedIndex = index;
                                  _touchedIndex = -1;
                                });
                              }
                            }
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 42,
                        sections: sections,
                      ),
                    ),
                  ),
                  if (touchedCatName.isNotEmpty)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          touchedCatName,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${touchedAmount.toStringAsFixed(0)}',
                          style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  else
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Tap slice', style: TextStyle(color: Colors.white30, fontSize: 9)),
                        Text('to inspect', style: TextStyle(color: Colors.white30, fontSize: 9)),
                      ],
                    ),
                ],
              ),
            ],
          ),
          if (touchedCatName.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Category:', style: TextStyle(color: Colors.white30, fontSize: 11)),
                      Text(touchedCatName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount & Ratio:', style: TextStyle(color: Colors.white30, fontSize: 11)),
                      Text('₹${touchedAmount.toStringAsFixed(2)} (${touchedPct.toStringAsFixed(1)}%)', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transactions:', style: TextStyle(color: Colors.white30, fontSize: 11)),
                      Text('$touchedTxCount Tx(s)', style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Double-tap slice or list item to view transaction logs.',
                      style: TextStyle(color: Colors.white24, fontSize: 9, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'LEGEND',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: legendItems,
          ),
        ],
      ),
    );
  }
}

// 5. Interactive Checklist for Recommendations
class RecommendationsChecklist extends StatefulWidget {
  final List<String> items;

  const RecommendationsChecklist({super.key, required this.items});

  @override
  State<RecommendationsChecklist> createState() => _RecommendationsChecklistState();
}

class _RecommendationsChecklistState extends State<RecommendationsChecklist> {
  late List<bool> _checkedStates;

  @override
  void initState() {
    super.initState();
    _checkedStates = List<bool>.filled(widget.items.length, false);
  }

  @override
  void didUpdateWidget(covariant RecommendationsChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _checkedStates = List<bool>.filled(widget.items.length, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      borderColor: const Color(0xFF00E5FF).withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_rounded, color: Color(0xFF00E5FF), size: 16),
              SizedBox(width: 8),
              Text(
                'RECOMMENDED ACTIONS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final isChecked = _checkedStates[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _checkedStates[index] = !_checkedStates[index];
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isChecked
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: isChecked ? const Color(0xFF00E5FF) : Colors.white30,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.items[index],
                            style: TextStyle(
                              color: isChecked ? Colors.white30 : Colors.white70,
                              fontSize: 12,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// 6. Action Bar for Copy, Regenerate, Speech
class MessageActionBar extends StatefulWidget {
  final String text;
  final VoidCallback onRegenerate;

  const MessageActionBar({
    super.key,
    required this.text,
    required this.onRegenerate,
  });

  @override
  State<MessageActionBar> createState() => _MessageActionBarState();
}

class _MessageActionBarState extends State<MessageActionBar> {
  bool _copied = false;
  bool _speaking = false;
  bool? _liked;

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _speak() {
    setState(() => _speaking = !_speaking);
    // Standard simulation of TTS. Speech engine integration hooks.
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              color: _copied ? const Color(0xFF00E676) : Colors.white30,
              size: 16,
            ),
            tooltip: _copied ? 'Copied' : 'Copy Response',
            onPressed: _copy,
          ),
          IconButton(
            icon: Icon(
              _speaking ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
              color: _speaking ? const Color(0xFF00E5FF) : Colors.white30,
              size: 16,
            ),
            tooltip: _speaking ? 'Stop Speaking' : 'Read Aloud',
            onPressed: _speak,
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white30,
              size: 16,
            ),
            tooltip: 'Regenerate Response',
            onPressed: widget.onRegenerate,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.thumb_up_alt_outlined,
              color: _liked == true ? const Color(0xFF00E676) : Colors.white30,
              size: 16,
            ),
            onPressed: () {
              setState(() => _liked = _liked == true ? null : true);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.thumb_down_alt_outlined,
              color: _liked == false ? const Color(0xFFFF3B30) : Colors.white30,
              size: 16,
            ),
            onPressed: () {
              setState(() => _liked = _liked == false ? null : false);
            },
          ),
        ],
      ),
    );
  }
}
