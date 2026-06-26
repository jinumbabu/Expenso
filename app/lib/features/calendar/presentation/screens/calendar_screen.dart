import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../../shared/widgets/glass_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(expenseListNotifierProvider);
    final now = DateTime.now();

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
              // 1. Group transaction amounts by day for heatmap
              final Map<int, int> dailyExpenses = {};
              int maxDailyExpense = 1;
              
              for (var tx in txs) {
                if (tx.date.year == now.year && tx.date.month == now.month && tx.type == 'expense') {
                  final day = tx.date.day;
                  dailyExpenses[day] = (dailyExpenses[day] ?? 0) + tx.amount.toInt();
                  if (dailyExpenses[day]! > maxDailyExpense) {
                    maxDailyExpense = dailyExpenses[day]!;
                  }
                }
              }

              // 2. Filter transactions for the selected day
              final selectedTxs = txs.where((tx) =>
                  tx.date.year == _selectedDate.year &&
                  tx.date.month == _selectedDate.month &&
                  tx.date.day == _selectedDate.day).toList();

                      return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Calendar Intelligence',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Divider(color: Colors.white10, height: 1),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMMM yyyy').format(_selectedDate).toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF00E5FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const Text('HEATMAP ACTIVE', style: TextStyle(color: Colors.white30, fontSize: 9)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemCount: DateTime(now.year, now.month + 1, 0).day,
                              itemBuilder: (context, index) {
                                final day = index + 1;
                                final expense = dailyExpenses[day] ?? 0;
                                final ratio = (expense / maxDailyExpense).clamp(0.0, 1.0);
                                final isSelected = _selectedDate.day == day;

                                final cellColor = expense > 0
                                    ? const Color(0xFF0066FF).withOpacity(0.15 + (ratio * 0.75))
                                    : Colors.white.withOpacity(0.03);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = DateTime(now.year, now.month, day);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cellColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF00E5FF)
                                            : (expense > 0 ? const Color(0xFF0066FF).withOpacity(0.3) : Colors.transparent),
                                        width: isSelected ? 1.8 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF00E5FF).withOpacity(0.35),
                                                blurRadius: 8,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$day',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : (expense > 0 ? Colors.white : Colors.white38),
                                          fontWeight: isSelected || expense > 0 ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'TIMELINE LOG: ${DateFormat('dd MMMM yyyy').format(_selectedDate).toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),
                  selectedTxs.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
                                  const SizedBox(height: 12),
                                  const Text('No transactions recorded for this day.', style: TextStyle(color: Colors.white30, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final tx = selectedTxs[index];
                                final isIncome = tx.type == 'income';
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: (isIncome ? const Color(0xFF0066FF) : const Color(0xFFFF3B30)).withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                          color: isIncome ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30),
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tx.description ?? tx.merchant ?? 'Transaction',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat('hh:mm a').format(tx.date),
                                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        (isIncome ? '+' : '-') + _formatMoney(tx.amount.toInt()),
                                        style: TextStyle(
                                          color: isIncome ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              childCount: selectedTxs.length,
                            ),
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
