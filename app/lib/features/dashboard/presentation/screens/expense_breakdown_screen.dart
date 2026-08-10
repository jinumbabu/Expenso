import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/privacy_text.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../providers/privacy_provider.dart';

class ExpenseBreakdownScreen extends ConsumerStatefulWidget {
  const ExpenseBreakdownScreen({super.key});

  @override
  ConsumerState<ExpenseBreakdownScreen> createState() => _ExpenseBreakdownScreenState();
}

class _ExpenseBreakdownScreenState extends ConsumerState<ExpenseBreakdownScreen> {
  String _dateFilter = 'This Month'; // Today, This Week, This Month, This Year, Custom
  DateTimeRange? _customDateRange;
  int _touchedIndex = -1;

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }

  bool _filterByDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(date.year, date.month, date.day);

    switch (_dateFilter) {
      case 'Today':
        return txDate.isAtSameMomentAs(today);
      case 'This Week':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return txDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return txDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1)));
      case 'This Year':
        final startOfYear = DateTime(now.year, 1, 1);
        return txDate.isAfter(startOfYear.subtract(const Duration(seconds: 1)));
      case 'Custom':
        if (_customDateRange == null) return true;
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day);
        return txDate.isAfter(start.subtract(const Duration(seconds: 1))) && 
               txDate.isBefore(end.add(const Duration(days: 1)));
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(expenseListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isPrivate = ref.watch(privacyModeProvider);

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
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(context),

              // Content
              Expanded(
                child: transactionsAsync.when(
                  data: (txs) {
                    return categoriesAsync.when(
                      data: (categories) {
                        // Filter transactions
                        final filteredTxs = txs.where((tx) {
                          final isExp = FinancialCalculationService.isExpense(tx);
                          final matchesDate = _filterByDate(tx.date);
                          return isExp && matchesDate;
                        }).toList();

                        // Group by category
                        final categorySpends = <String, int>{};
                        int totalExpense = 0;
                        for (var tx in filteredTxs) {
                          if (tx.categoryId != null) {
                            categorySpends[tx.categoryId!] = (categorySpends[tx.categoryId!] ?? 0) + tx.amount.toInt();
                            totalExpense += tx.amount.toInt();
                          }
                        }

                        // Map to presentation list
                        final categoriesMap = {for (var c in categories) c.id: c};
                        final List<_CategoryBreakdownItem> breakdownItems = [];
                        
                        // Add mapped categories
                        categorySpends.forEach((catId, amount) {
                          final cat = categoriesMap[catId];
                          final percentage = totalExpense == 0 ? 0.0 : amount / totalExpense;
                          breakdownItems.add(
                            _CategoryBreakdownItem(
                              categoryId: catId,
                              name: cat?.name ?? 'Other',
                              icon: cat?.icon ?? 'category',
                              amount: amount,
                              percentage: percentage,
                              color: _getCategoryColor(cat?.icon),
                            ),
                          );
                        });

                        // Sort by amount descending
                        breakdownItems.sort((a, b) => b.amount.compareTo(a.amount));

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // 1. Time Filters Bar
                            _buildFiltersBar(),
                            const SizedBox(height: 24),

                            // 2. Interactive Pie Chart
                            if (breakdownItems.isNotEmpty) ...[
                              _buildPieChart(breakdownItems, isPrivate),
                              const SizedBox(height: 24),
                            ] else ...[
                              Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.pie_chart_outline, color: Colors.white24, size: 48),
                                    SizedBox(height: 12),
                                    Text('No expenses in this period', style: TextStyle(color: Colors.white30, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // 3. Category Details Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'SPENDING BY CATEGORY',
                                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                ),
                                PrivacyText(
                                  rawValue: _formatMoney(totalExpense),
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 4. Categories List
                            if (breakdownItems.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(40),
                                alignment: Alignment.center,
                                child: const Text('No transactions match filters.', style: TextStyle(color: Colors.white24, fontSize: 13)),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: breakdownItems.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = breakdownItems[index];
                                  final iconData = _getCategoryIcon(item.icon);
                                  
                                  return GestureDetector(
                                    onTap: () => _showCategoryTransactions(context, item, filteredTxs),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.015),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withOpacity(0.03)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: item.color.withOpacity(0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(iconData, color: item.color, size: 16),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                                ),
                                                const SizedBox(height: 2),
                                                AnimatedSwitcher(
                                                  duration: const Duration(milliseconds: 250),
                                                  child: Text(
                                                    isPrivate
                                                        ? 'Percentage: **%'
                                                        : 'Percentage: ${(item.percentage * 100).toStringAsFixed(1)}%',
                                                    key: ValueKey(isPrivate),
                                                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              PrivacyText(
                                                rawValue: _formatMoney(item.amount),
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 60),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                      error: (err, _) => Center(child: Text('Error loading categories: $err', style: const TextStyle(color: Colors.red))),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                  error: (err, _) => Center(child: Text('Error loading transactions: $err', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Expense Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _dateFilter,
                dropdownColor: const Color(0xFF050505),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 18),
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                items: ['Today', 'This Week', 'This Month', 'This Year', 'Custom'].map((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val),
                  );
                }).toList(),
                onChanged: (val) async {
                  if (val == null) return;
                  if (val == 'Custom') {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF0066FF),
                              onPrimary: Colors.white,
                              surface: Color(0xFF0F1A1C),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _dateFilter = 'Custom';
                        _customDateRange = picked;
                      });
                    }
                  } else {
                    setState(() {
                      _dateFilter = val;
                    });
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(List<_CategoryBreakdownItem> items, bool isPrivate) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 3,
          centerSpaceRadius: 55,
          sections: List.generate(items.length, (i) {
            final item = items[i];
            final isTouched = i == _touchedIndex;
            final radius = isTouched ? 28.0 : 20.0;
            
            return PieChartSectionData(
              color: item.color,
              value: item.amount.toDouble(),
              title: isPrivate 
                  ? '**%'
                  : isTouched 
                      ? '${(item.percentage * 100).toStringAsFixed(0)}%' 
                      : '',
              radius: radius,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showCategoryTransactions(BuildContext context, _CategoryBreakdownItem category, List<Transaction> allTxs) {
    final catTxs = allTxs.where((tx) => tx.categoryId == category.categoryId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050505),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${category.name} Expenses',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                Expanded(
                  child: catTxs.isEmpty
                      ? const Center(child: Text('No transactions recorded.', style: TextStyle(color: Colors.white24)))
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: catTxs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final tx = catTxs[idx];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.015),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withOpacity(0.03)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.merchant ?? tx.description ?? 'General Expense',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('dd MMM yyyy').format(tx.date),
                                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PrivacyText(
                                    rawValue: _formatMoney(tx.amount),
                                    style: const TextStyle(
                                      color: Color(0xFFFF3B30),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
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

  Color _getCategoryColor(String? icon) {
    if (icon != null && icon.isNotEmpty) {
      if (icon.contains('fastfood') || icon.contains('dining') || icon.contains('food')) return Colors.orange;
      if (icon.contains('shopping') || icon.contains('cart')) return Colors.purple;
      if (icon.contains('commute') || icon.contains('car') || icon.contains('cab')) return Colors.blue;
      if (icon.contains('movie') || icon.contains('tv') || icon.contains('game')) return Colors.pink;
      if (icon.contains('home') || icon.contains('rent')) return Colors.green;
      if (icon.contains('health') || icon.contains('med')) return Colors.red;
    }
    return const Color(0xFF0066FF);
  }

  IconData _getCategoryIcon(String? icon) {
    if (icon != null && icon.isNotEmpty) {
      if (icon.contains('fastfood') || icon.contains('dining') || icon.contains('food')) return Icons.fastfood_outlined;
      if (icon.contains('shopping') || icon.contains('cart')) return Icons.shopping_bag_outlined;
      if (icon.contains('commute') || icon.contains('car') || icon.contains('cab')) return Icons.directions_car_outlined;
      if (icon.contains('movie') || icon.contains('tv') || icon.contains('game')) return Icons.videogame_asset_outlined;
      if (icon.contains('home') || icon.contains('rent')) return Icons.home_outlined;
      if (icon.contains('health') || icon.contains('med')) return Icons.medical_services_outlined;
    }
    return Icons.category_outlined;
  }
}

class _CategoryBreakdownItem {
  final String categoryId;
  final String name;
  final String icon;
  final int amount;
  final double percentage;
  final Color color;

  _CategoryBreakdownItem({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}
