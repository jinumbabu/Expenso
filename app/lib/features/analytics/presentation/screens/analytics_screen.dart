import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../../shared/widgets/glass_card.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _touchedIndex = -1;

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(expenseListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

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
          child: txsAsync.when(
            data: (txs) {
              if (txs.isEmpty) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Analytics Dashboard',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bar_chart_outlined, size: 64, color: Colors.white24),
                              const SizedBox(height: 16),
                              const Text(
                                'No Transaction History',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add transactions to unlock spending insights and interactive charts.',
                                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              final now = DateTime.now();
              final List<DateTime> months = List.generate(6, (i) => DateTime(now.year, now.month - i, 1)).reversed.toList();
              
              final List<double> monthlyIncome = List.filled(6, 0.0);
              final List<double> monthlyExpense = List.filled(6, 0.0);

              for (var tx in txs) {
                for (int i = 0; i < 6; i++) {
                  final m = months[i];
                  if (tx.date.year == m.year && tx.date.month == m.month) {
                    if (tx.type == 'income') {
                      monthlyIncome[i] += tx.amount / 100.0;
                    } else if (tx.type == 'expense') {
                      monthlyExpense[i] += tx.amount / 100.0;
                    }
                  }
                }
              }

              final Map<String, double> categorySpend = {};
              double totalExpense = 0.0;
              
              for (var tx in txs) {
                if (tx.date.year == now.year && tx.date.month == now.month && tx.type == 'expense') {
                  if (tx.categoryId != null) {
                    categorySpend[tx.categoryId!] = (categorySpend[tx.categoryId!] ?? 0) + tx.amount / 100.0;
                    totalExpense += tx.amount / 100.0;
                  }
                }
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Analytics Dashboard',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      children: [
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'INCOME VS EXPENSES',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.lens, color: Color(0xFF0066FF), size: 10),
                                      SizedBox(width: 4),
                                      Text('In', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                      SizedBox(width: 10),
                                      Icon(Icons.lens, color: Color(0xFFFF3B30), size: 10),
                                      SizedBox(width: 4),
                                      Text('Out', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 180,
                                child: LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            if (idx >= 0 && idx < 6) {
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: Text(
                                                  DateFormat('MMM').format(months[idx]),
                                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: List.generate(6, (i) => FlSpot(i.toDouble(), monthlyIncome[i])),
                                        isCurved: true,
                                        color: const Color(0xFF0066FF),
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: const Color(0xFF0066FF).withOpacity(0.08),
                                        ),
                                      ),
                                      LineChartBarData(
                                        spots: List.generate(6, (i) => FlSpot(i.toDouble(), monthlyExpense[i])),
                                        isCurved: true,
                                        color: const Color(0xFFFF3B30),
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: const Color(0xFFFF3B30).withOpacity(0.08),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        categoriesAsync.when(
                          data: (cats) {
                            if (totalExpense == 0) {
                              return const GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CATEGORY SHARE',
                                      style: TextStyle(
                                        color: Color(0xFF00E5FF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 32),
                                    Center(
                                      child: Text(
                                        'No expenses recorded in the current month.',
                                        style: TextStyle(color: Colors.white38, fontSize: 12),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                  ],
                                ),
                              );
                            }
                            final categoriesMap = {for (var c in cats) c.id: c};
                            final List<PieChartSectionData> sections = [];
                            final List<Widget> legend = [];

                            int colorIndex = 0;
                            categorySpend.forEach((catId, val) {
                              final cat = categoriesMap[catId];
                              final color = IconMapper.getColor(cat?.icon);
                              final pct = (val / totalExpense) * 100;
                              final isTouched = colorIndex == _touchedIndex;

                              sections.add(
                                PieChartSectionData(
                                  color: color,
                                  value: val,
                                  title: '${pct.toStringAsFixed(0)}%',
                                  radius: isTouched ? 55.0 : 45.0,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );

                              legend.add(
                                Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(IconMapper.getIcon(cat?.icon), color: color, size: 16),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          cat?.name ?? 'Category',
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        _formatMoney((val * 100).round()),
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                              colorIndex++;
                            });

                            return GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CATEGORY SHARE',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 140,
                                        width: 140,
                                        child: PieChart(
                                          PieChartData(
                                            sections: sections,
                                            centerSpaceRadius: 40,
                                            sectionsSpace: 2,
                                            pieTouchData: PieTouchData(
                                              touchCallback: (event, response) {
                                                setState(() {
                                                  if (!event.isInterestedForInteractions ||
                                                      response == null ||
                                                      response.touchedSection == null) {
                                                    _touchedIndex = -1;
                                                    return;
                                                  }
                                                  _touchedIndex = response.touchedSection!.touchedSectionIndex;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  ...legend,
                                ],
                              ),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => const Text('Error loading categories'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
            error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
          ),
        ),
      ),
    );
  }
}
