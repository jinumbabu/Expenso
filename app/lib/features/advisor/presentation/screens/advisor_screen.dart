import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/advisor_provider.dart';

class AdvisorScreen extends ConsumerWidget {
  const AdvisorScreen({super.key});

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(advisorProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF002B24), Color(0xFF050F0E), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Financial Advisor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: state.isLoadingInsights ? Colors.tealAccent.withOpacity(0.5) : Colors.tealAccent,
                      ),
                      onPressed: state.isLoadingInsights
                          ? null
                          : () {
                              ref.read(advisorProvider.notifier).calculateFinancialOverview();
                            },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Content Area
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  children: [
                    // Score & Radial Gauge
                    _buildScoreGauge(context, state),
                    const SizedBox(height: 24),

                    // Spending Alerts
                    if (state.spendingAlerts.isNotEmpty) ...[
                      _buildAlertsSection(context, state),
                      const SizedBox(height: 24),
                    ],

                    // Forecasting Card
                    _buildForecastCard(context, state),
                    const SizedBox(height: 24),

                    // 50/30/20 Budget Rule Card
                    _buildBudgetRuleCard(context, state),
                    const SizedBox(height: 24),

                    // AI Insights
                    _buildInsightsSection(context, state),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreGauge(BuildContext context, AdvisorState state) {
    Color scoreColor = Colors.tealAccent;
    if (state.healthScore < 40) {
      scoreColor = Colors.redAccent;
    } else if (state.healthScore < 60) {
      scoreColor = Colors.orangeAccent;
    } else if (state.healthScore < 80) {
      scoreColor = Colors.amberAccent;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text(
            'FINANCIAL HEALTH INDEX',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            width: 160,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    height: 150,
                    width: 150,
                    child: CircularProgressIndicator(
                      value: state.healthScore / 100.0,
                      strokeWidth: 12,
                      backgroundColor: Colors.white10,
                      color: scoreColor,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${state.healthScore}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        state.healthStatus.toUpperCase(),
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          _buildScoreRow('Savings Rate', state.healthBreakdown['Savings Rate'] ?? 0, 30),
          const SizedBox(height: 8),
          _buildScoreRow('Budget Compliance', state.healthBreakdown['Budget Compliance'] ?? 0, 25),
          const SizedBox(height: 8),
          _buildScoreRow('Expense Stability', state.healthBreakdown['Expense Stability'] ?? 0, 20),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String title, double score, double maxScore) {
    final percent = score / maxScore;
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white10,
              color: Colors.tealAccent.shade700,
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${score.round()}/${maxScore.round()}',
          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAlertsSection(BuildContext context, AdvisorState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent.shade100, size: 20),
              const SizedBox(width: 8),
              const Text(
                'SPENDING ALERT FLAGS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.spendingAlerts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(color: Colors.redAccent.shade100, fontSize: 14),
                    ),
                    Expanded(
                      child: Text(
                        state.spendingAlerts[index],
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(BuildContext context, AdvisorState state) {
    final isOverspent = state.projectedMonthEndSpend > state.totalIncome;
    final color = isOverspent ? Colors.redAccent : Colors.tealAccent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MONTH-END EXPENDITURE FORECAST',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Expected Spend', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    _formatMoney(state.projectedMonthEndSpend),
                    style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Current Month Income', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    _formatMoney(state.totalIncome),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: state.totalIncome > 0
                    ? (state.projectedMonthEndSpend / state.totalIncome).clamp(0.0, 1.0)
                    : 1.0,
                backgroundColor: Colors.white10,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isOverspent
                ? 'Your projected spending exceeds your monthly income. Consider deferring non-essential purchases.'
                : 'Excellent run-rate! Your projected monthly spending will remain below your recorded income.',
            style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRuleCard(BuildContext context, AdvisorState state) {
    // Calculates the recommended targets based on total monthly income
    final income = state.totalIncome > 0 ? state.totalIncome : 4500000; // Fallback to 45k INR if income not set
    final needs = (income * 0.50).round();
    final wants = (income * 0.30).round();
    final savings = (income * 0.20).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline, color: Colors.tealAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'BUDGET RULE TARGETS (50/30/20)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Recommended budget distribution based on your current income:',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          _buildBudgetRecommendationRow('Needs (50%)', needs, 'Rent, groceries, utilities, loan repayments', Colors.tealAccent),
          const SizedBox(height: 12),
          _buildBudgetRecommendationRow('Wants (30%)', wants, 'Dining out, hobbies, subscriptions, shopping', Colors.amberAccent),
          const SizedBox(height: 12),
          _buildBudgetRecommendationRow('Savings (20%)', savings, 'Investments, emergency reserves, debt reduction', Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _buildBudgetRecommendationRow(String title, int amount, String desc, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 45,
          color: color,
          margin: const EdgeInsets.only(right: 12),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Colors.white30, fontSize: 10)),
            ],
          ),
        ),
        Text(
          _formatMoney(amount),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(BuildContext context, AdvisorState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.purpleAccent, Colors.tealAccent],
              ).createShader(bounds),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'AI FINANCIAL ADVISOR INSIGHTS',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.isLoadingInsights)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.aiInsights.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade900.withOpacity(0.08),
                      Colors.teal.shade900.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lightbulb_outline, color: Colors.purpleAccent, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.aiInsights[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
