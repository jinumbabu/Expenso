import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../providers/advisor_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../budgets/presentation/screens/budgets_screen.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/ecg_pulse_ring.dart';

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
            colors: [Color(0xFF050E1A), Color(0xFF050505)],
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
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
                        color: state.isLoadingInsights ? const Color(0xFF0066FF).withOpacity(0.5) : const Color(0xFF00E5FF),
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
                    const SizedBox(height: 24),

                    // AI Assistant Tools
                    _buildAssistantToolsGrid(context, ref),
                    const SizedBox(height: 40),
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
    final clampedScore = state.healthScore.clamp(0, 100);
    Color scoreColor = const Color(0xFF00E5FF);
    if (clampedScore < 40) {
      scoreColor = const Color(0xFFFF3B30);
    } else if (clampedScore < 60) {
      scoreColor = Colors.orangeAccent;
    } else if (clampedScore < 80) {
      scoreColor = const Color(0xFF0066FF);
    }

    return GlassCard(
      child: Column(
        children: [
          const Text(
            'FINANCIAL HEALTH INDEX',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          EcgPulseRing(
            healthScore: clampedScore,
            size: 140,
            ringColor: scoreColor,
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
              color: const Color(0xFF0066FF),
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
        color: const Color(0xFFFF3B30).withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: const Color(0xFFFF3B30).withOpacity(0.8), size: 20),
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
                    const Text(
                      '• ',
                      style: TextStyle(color: Color(0xFFFF3B30), fontSize: 14),
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
    final color = isOverspent ? const Color(0xFFFF3B30) : const Color(0xFF00E5FF);

    return GlassCard(
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
                color: isOverspent ? const Color(0xFFFF3B30) : const Color(0xFF0066FF),
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
    final income = state.totalIncome > 0 ? state.totalIncome : 4500000;
    final needs = (income * 0.50).round();
    final wants = (income * 0.30).round();
    final savings = (income * 0.20).round();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline, color: Color(0xFF00E5FF), size: 20),
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
          _buildBudgetRecommendationRow('Needs (50%)', needs, 'Rent, groceries, utilities, loan repayments', const Color(0xFF0066FF)),
          const SizedBox(height: 12),
          _buildBudgetRecommendationRow('Wants (30%)', wants, 'Dining out, hobbies, subscriptions, shopping', const Color(0xFF00E5FF).withOpacity(0.6)),
          const SizedBox(height: 12),
          _buildBudgetRecommendationRow('Savings (20%)', savings, 'Investments, emergency reserves, debt reduction', const Color(0xFF00E5FF).withOpacity(0.3)),
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
        const Row(
          children: [
            Icon(Icons.auto_awesome_outlined, color: Color(0xFF00E5FF), size: 20),
            SizedBox(width: 8),
            Text(
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
              child: CircularProgressIndicator(color: Color(0xFF0066FF)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.aiInsights.length,
            itemBuilder: (context, index) {
              return GlassCard(
                padding: const EdgeInsets.all(16),
                borderColor: const Color(0xFF0066FF).withOpacity(0.12),
                gradientColors: [
                  const Color(0xFF0066FF).withOpacity(0.04),
                  const Color(0xFF050505).withOpacity(0.2),
                ],
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lightbulb_outline, color: Color(0xFF00E5FF), size: 14),
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

  Widget _buildAssistantToolsGrid(BuildContext context, WidgetRef ref) {
    final List<Map<String, dynamic>> tools = [
      {
        'title': 'View Analytics',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFF00E5FF),
        'onTap': () => context.push('/analytics'),
      },
      {
        'title': 'Export PDF',
        'icon': Icons.picture_as_pdf_outlined,
        'color': const Color(0xFFFF9500),
        'onTap': () => _exportFinancialReportPdf(context, ref),
      },
      {
        'title': 'Budget Planner',
        'icon': Icons.playlist_add_check_outlined,
        'color': const Color(0xFFAF52DE),
        'onTap': () => context.push('/budgets'),
      },
      {
        'title': 'Savings Tips',
        'icon': Icons.savings_outlined,
        'color': const Color(0xFF4CD964),
        'onTap': () => _showSavingsTipsSheet(context, ref),
      },
      {
        'title': 'Spending Trends',
        'icon': Icons.trending_up_outlined,
        'color': const Color(0xFFFF2D55),
        'onTap': () => _showSpendingTrendsSheet(context, ref),
      },
      {
        'title': 'Cash Flow',
        'icon': Icons.swap_horizontal_circle_outlined,
        'color': const Color(0xFF0066FF),
        'onTap': () => _showCashFlowSheet(context, ref),
      },
      {
        'title': 'Budget Insights',
        'icon': Icons.pie_chart_outline_outlined,
        'color': const Color(0xFFFFCC00),
        'onTap': () => _showBudgetInsightsSheet(context, ref),
      },
      {
        'title': 'Monthly Report',
        'icon': Icons.summarize_outlined,
        'color': const Color(0xFF00FFCC),
        'onTap': () => _showMonthlyReportSheet(context, ref),
      },
      {
        'title': 'Income Analysis',
        'icon': Icons.monetization_on_outlined,
        'color': const Color(0xFFFF5E3A),
        'onTap': () => _showIncomeAnalysisSheet(context, ref),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'AI ASSISTANT TOOLS',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final t = tools[index];
            return InkWell(
              onTap: t['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.015),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (t['color'] as Color).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        t['icon'] as IconData,
                        color: t['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t['title'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showPremiumBottomSheet({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0B172A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            gradient: LinearGradient(
              colors: [Color(0xFF0B172A), Color(0xFF050914)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              child,
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportFinancialReportPdf(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
      );

      final snapshot = ref.read(financialSnapshotProvider);
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pdfContext) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Expenso AI - Financial Statement', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('Statement Period: ${DateFormat('MMMM yyyy').format(snapshot.periodStart)}', style: const pw.TextStyle(fontSize: 12)),
                  pw.Divider(),
                  pw.SizedBox(height: 20),
                  pw.Text('Summary Metrics', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Income:'),
                      pw.Text('INR ${snapshot.income.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Expenses:'),
                      pw.Text('INR ${snapshot.expenses.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Net Cash Flow:'),
                      pw.Text('INR ${snapshot.netCashFlow.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Carry Forward (Opening Balance):'),
                      pw.Text('INR ${snapshot.carryForward.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Credit Card Outstanding:'),
                      pw.Text('INR ${snapshot.creditCardOutstanding.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Net Worth:'),
                      pw.Text('INR ${snapshot.netWorth.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text('Category Spending Breakdown', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  ...snapshot.categoryTotals.entries.map((e) {
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(e.key),
                        pw.Text('INR ${e.value.toStringAsFixed(2)}'),
                      ],
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/expenso_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        Navigator.pop(context);
      }

      await Share.shareXFiles([XFile(file.path)], text: 'Expenso AI Statement');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSavingsTipsSheet(BuildContext context, WidgetRef ref) {
    final snapshot = ref.read(financialSnapshotProvider);
    final savingsRatePercent = (snapshot.savingsRate * 100).toStringAsFixed(1);
    
    _showPremiumBottomSheet(
      context: context,
      title: 'Savings Tips & Analysis',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CD964).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4CD964).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, color: Color(0xFF4CD964), size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monthly Savings Rate', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('$savingsRatePercent%', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Recommendations', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTipItem('Emergency Fund Allocation', 'Target setting aside 20% of your active income monthly into a high-yield assets account.'),
          _buildTipItem('Category Specific Cutbacks', 'Your top categories account for a major portion of your spends. Consider reducing dining/shopping outlays.'),
          _buildTipItem('Avoid Leakages', 'Small recurring subscription charges can silently add up. Review and prune unused subscriptions.'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF4CD964), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSpendingTrendsSheet(BuildContext context, WidgetRef ref) {
    final snapshot = ref.read(financialSnapshotProvider);
    final dailySpend = snapshot.expenses / 30.0;
    
    _showPremiumBottomSheet(
      context: context,
      title: 'Spending Velocity & Trends',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendMetricRow('Daily Spends Velocity', '₹${dailySpend.toStringAsFixed(2)} / day'),
          _buildTrendMetricRow('Transaction Count', '${snapshot.expenseTransactionCount} expense transactions'),
          _buildTrendMetricRow('Savings/Expense Ratio', '${(snapshot.savingsRate * 100).toStringAsFixed(0)}% saved vs ${(snapshot.expenseRate * 100).toStringAsFixed(0)}% spent'),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          const Text('Observations', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            snapshot.expenses > 0 
                ? 'Your daily spending matches general user patterns. Look out for mid-month bumps in card statements.'
                : 'No expenses recorded yet for the selected statement period.',
            style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendMetricRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCashFlowSheet(BuildContext context, WidgetRef ref) {
    final snapshot = ref.read(financialSnapshotProvider);
    
    _showPremiumBottomSheet(
      context: context,
      title: 'Cash Flow Statement',
      child: Column(
        children: [
          _buildCashFlowRow('💰 Total Cash In (Income)', '₹${snapshot.income.toStringAsFixed(2)}', const Color(0xFF00E5FF)),
          const SizedBox(height: 8),
          _buildCashFlowRow('💸 Total Cash Out (Expenses)', '-₹${snapshot.expenses.toStringAsFixed(2)}', const Color(0xFFFF3B30)),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          _buildCashFlowRow(
            '🏦 Net Cash Flow (Surplus/Deficit)', 
            '${snapshot.netCashFlow >= 0 ? "" : "-"}₹${snapshot.netCashFlow.abs().toStringAsFixed(2)}', 
            snapshot.netCashFlow >= 0 ? const Color(0xFF4CD964) : const Color(0xFFFF3B30),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: isBold ? 14 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: color, fontSize: isBold ? 15 : 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showBudgetInsightsSheet(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetStatusProviderList);
    
    _showPremiumBottomSheet(
      context: context,
      title: 'Budget Insights & Limits',
      child: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
             return const Padding(
               padding: EdgeInsets.symmetric(vertical: 24.0),
               child: Center(child: Text('No budgets configured.', style: TextStyle(color: Colors.white54))),
             );
          }
          return Column(
            children: budgets.map((b) {
              final limit = b.budget.amount / 100.0;
              final spent = b.spentAmount / 100.0;
              final remaining = limit - spent;
              final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
              final color = b.isOverBudget ? const Color(0xFFFF3B30) : const Color(0xFF00E5FF);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(b.category?.name ?? 'Overall', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Spent ₹${spent.toStringAsFixed(0)} of ₹${limit.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white10,
                        color: color,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.isOverBudget 
                          ? 'Over budget by ₹${(spent - limit).toStringAsFixed(2)}' 
                          : '₹${remaining.toStringAsFixed(2)} remaining',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
        error: (err, _) => Center(child: Text('Error loading budgets: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  void _showMonthlyReportSheet(BuildContext context, WidgetRef ref) {
    final snapshot = ref.read(financialSnapshotProvider);
    
    _showPremiumBottomSheet(
      context: context,
      title: 'Monthly Statement Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendMetricRow('Month', DateFormat('MMMM yyyy').format(snapshot.periodStart)),
          _buildTrendMetricRow('Total Income', '₹${snapshot.income.toStringAsFixed(2)}'),
          _buildTrendMetricRow('Total Expenses', '₹${snapshot.expenses.toStringAsFixed(2)}'),
          _buildTrendMetricRow('Savings Surplus', '₹${snapshot.savings.toStringAsFixed(2)}'),
          _buildTrendMetricRow('Carry Forward', '₹${snapshot.carryForward.toStringAsFixed(2)}'),
          _buildTrendMetricRow('Credit Card Outstanding', '₹${snapshot.creditCardOutstanding.toStringAsFixed(2)}'),
          _buildTrendMetricRow('Net Worth', '₹${snapshot.netWorth.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          const Text('Category split', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...snapshot.categoryTotals.entries.take(4).map((e) {
            return _buildTrendMetricRow(e.key, '₹${e.value.toStringAsFixed(2)}');
          }).toList(),
        ],
      ),
    );
  }

  void _showIncomeAnalysisSheet(BuildContext context, WidgetRef ref) {
    final snapshot = ref.read(financialSnapshotProvider);
    
    _showPremiumBottomSheet(
      context: context,
      title: 'Income Sources Analysis',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendMetricRow('Monthly Active Income', '₹${snapshot.income.toStringAsFixed(2)}'),
          _buildTrendMetricRow('Income Transaction Count', '${snapshot.incomeTransactionCount} deposits'),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          const Text('Analysis Notes', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'Income figures explicitly exclude internal self-transfers or credit card settlements. Ensure all external earnings (salary, refunds, interest, reversal credits) are logged correctly under Income categories.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
