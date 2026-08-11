import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/privacy_text.dart';
import '../../../../shared/widgets/reusable_donut_chart.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../analytics/presentation/models/analytics_chart_data.dart';
import '../providers/privacy_provider.dart';
import 'dashboard_summary_screen.dart';
import '../../../../shared/utils/analytics_formatter.dart';

class ExpenseBreakdownScreen extends ConsumerStatefulWidget {
  const ExpenseBreakdownScreen({super.key});

  @override
  ConsumerState<ExpenseBreakdownScreen> createState() => _ExpenseBreakdownScreenState();
}

class _ExpenseBreakdownScreenState extends ConsumerState<ExpenseBreakdownScreen> {
  String _selectedPeriod = 'Month'; // Today, Week, Month, Last Month, 3M, 6M, 1Y, Custom
  DateTimeRange? _customDateRange;
  String _selectedCategoryId = '';
  bool _isDetailMode = false;
  String _selectedSubExpenseId = '';

  late ScrollController _categoryScrollController;
  late ScrollController _subExpenseScrollController;
  final Map<String, GlobalKey> _categoryKeys = {};
  final Map<String, GlobalKey> _subExpenseKeys = {};

  @override
  void initState() {
    super.initState();
    _categoryScrollController = ScrollController();
    _subExpenseScrollController = ScrollController();
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    _subExpenseScrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String categoryId, int index) {
    if (index < 0) return;
    final key = _categoryKeys[categoryId];
    if (key == null) return;

    const double estimatedHeight = 66.0; // 58.0 card height + 8.0 separator
    final double targetOffset = index * estimatedHeight;

    if (_categoryScrollController.hasClients) {
      _categoryScrollController.animateTo(
        targetOffset.clamp(0.0, _categoryScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ).then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              alignment: 0.0,
            );
          }
        });
      });
    }
  }

  void _scrollToSubExpense(String transactionId, int index) {
    if (index < 0) return;
    final key = _subExpenseKeys[transactionId];
    if (key == null) return;

    const double estimatedHeight = 66.0; // card height + separator
    final double targetOffset = index * estimatedHeight;

    if (_subExpenseScrollController.hasClients) {
      _subExpenseScrollController.animateTo(
        targetOffset.clamp(0.0, _subExpenseScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ).then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              alignment: 0.0,
            );
          }
        });
      });
    }
  }

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }

  DateTimeRange _getRangeForFilter(String filter, DateTimeRange? customRange, DateTime dashboardMonth) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (filter) {
      case 'Today':
        return DateTimeRange(start: todayStart, end: todayEnd);
      case 'Week':
        final startOfWeek = todayStart.subtract(Duration(days: todayStart.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: startOfWeek, end: endOfWeek);
      case 'Month':
        final startOfMonth = DateTime(dashboardMonth.year, dashboardMonth.month, 1);
        final endOfMonth = DateTime(dashboardMonth.year, dashboardMonth.month + 1, 1).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
      case 'Last Month':
        final lastMonthDate = DateTime(dashboardMonth.year, dashboardMonth.month - 1, 1);
        final startOfLastMonth = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
        final endOfLastMonth = DateTime(lastMonthDate.year, lastMonthDate.month + 1, 1).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: startOfLastMonth, end: endOfLastMonth);
      case '3M':
        final start = todayStart.subtract(const Duration(days: 90));
        return DateTimeRange(start: start, end: todayEnd);
      case '6M':
        final start = todayStart.subtract(const Duration(days: 180));
        return DateTimeRange(start: start, end: todayEnd);
      case '1Y':
        final start = todayStart.subtract(const Duration(days: 365));
        return DateTimeRange(start: start, end: todayEnd);
      case 'Custom':
        if (customRange != null) return customRange;
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: todayEnd);
      default:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: todayEnd);
    }
  }

  List<ChartDatum> _getSubExpenseChartData(List<Transaction> txs, int totalAmount) {
    final colors = [
      const Color(0xFF0066FF),
      const Color(0xFF00E5FF),
      const Color(0xFFFF3B30),
      const Color(0xFFFF9500),
      const Color(0xFF4CD964),
      const Color(0xFFAF52DE),
      const Color(0xFFFF2D55),
      const Color(0xFFE5FF00),
      const Color(0xFF00FFCC),
    ];

    final List<ChartDatum> list = [];
    for (int i = 0; i < txs.length; i++) {
      final tx = txs[i];
      final label = tx.merchant ?? tx.description ?? 'General Expense';
      final percentage = totalAmount == 0 ? 0.0 : (tx.amount.toDouble() / totalAmount * 100);
      list.add(ChartDatum(
        id: tx.id,
        label: label,
        value: tx.amount.toDouble() / 100.0,
        percentage: percentage,
        color: colors[i % colors.length],
        transactionCount: 1,
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(expenseListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isPrivate = ref.watch(privacyModeProvider);
    final dashboardMonth = ref.watch(dashboardMonthProvider);

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
              if (!_isDetailMode) _buildHeader(context),

              // Content
              Expanded(
                child: transactionsAsync.when(
                  data: (txs) {
                    return categoriesAsync.when(
                      data: (categories) {
                        // Filter transactions matching period
                        final activeRange = _getRangeForFilter(_selectedPeriod, _customDateRange, dashboardMonth);
                        final filteredTxs = txs.where((tx) {
                          final isExp = FinancialCalculationService.isExpense(tx);
                          final inRange = tx.date.isAfter(activeRange.start.subtract(const Duration(seconds: 1))) &&
                                          tx.date.isBefore(activeRange.end.add(const Duration(seconds: 1)));
                          return isExp && inRange;
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

                        // Map categories
                        final categoriesMap = {for (var c in categories) c.id: c};
                        final List<ChartDatum> chartData = [];
                        
                        categorySpends.forEach((catId, amount) {
                          final cat = categoriesMap[catId];
                          final percentage = totalExpense == 0 ? 0.0 : (amount / totalExpense * 100);
                          chartData.add(
                            ChartDatum(
                              id: catId,
                              label: cat?.name ?? 'Other',
                              value: amount.toDouble() / 100.0,
                              percentage: percentage,
                              color: _getCategoryColor(cat?.icon),
                              transactionCount: 1,
                            ),
                          );
                        });

                        // Sort by amount descending
                        chartData.sort((a, b) => b.value.compareTo(a.value));

                        if (_isDetailMode) {
                          // Category specific details mode
                          final categoryTxs = filteredTxs.where((tx) => tx.categoryId == _selectedCategoryId).toList()
                            ..sort((a, b) => b.date.compareTo(a.date));
                          final int categoryTotal = categoryTxs.fold(0, (sum, tx) => sum + tx.amount.toInt());
                          final subChartData = _getSubExpenseChartData(categoryTxs, categoryTotal);
                          final currentCatName = categoriesMap[_selectedCategoryId]?.name ?? 'Category';

                          _subExpenseKeys.clear();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: _buildDetailHeader(context, currentCatName),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: ReusableDonutChart(
                                  data: subChartData,
                                  selectedId: _selectedSubExpenseId,
                                  onSelected: (id) {
                                    setState(() {
                                      _selectedSubExpenseId = id;
                                      final index = categoryTxs.indexWhere((tx) => tx.id == id);
                                      _scrollToSubExpense(id, index);
                                    });
                                  },
                                  centerTitle: currentCatName,
                                  centerValue: categoryTotal.toDouble() / 100.0,
                                  isPrivate: isPrivate,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.0),
                                child: Row(
                                  children: [
                                    Text(
                                      'SUB-EXPENSES',
                                      style: TextStyle(
                                        color: Color(0xFF00E5FF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: categoryTxs.isEmpty
                                    ? Container(
                                        padding: const EdgeInsets.all(40),
                                        alignment: Alignment.center,
                                        child: const Text('No transactions in this category.', style: TextStyle(color: Colors.white24, fontSize: 13)),
                                      )
                                    : ListView.separated(
                                        controller: _subExpenseScrollController,
                                        padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 40.0),
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: categoryTxs.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final tx = categoryTxs[index];
                                          final isSelected = _selectedSubExpenseId == tx.id;
                                          final txKey = _subExpenseKeys.putIfAbsent(tx.id, () => GlobalKey());

                                          return GestureDetector(
                                            key: txKey,
                                            onTap: () {
                                              if (_selectedSubExpenseId == tx.id) {
                                                context.push('/expenses/edit/${tx.id}');
                                              } else {
                                                setState(() {
                                                  _selectedSubExpenseId = tx.id;
                                                });
                                              }
                                            },
                                            onDoubleTap: () {
                                              context.push('/expenses/edit/${tx.id}');
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isSelected 
                                                    ? const Color(0xFF051833) 
                                                    : Colors.white.withOpacity(0.015),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isSelected 
                                                      ? const Color(0xFF00E5FF) 
                                                      : Colors.white.withOpacity(0.03),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: (isSelected ? const Color(0xFF00E5FF) : Colors.white).withOpacity(0.12),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.receipt_long_outlined, 
                                                      color: isSelected ? const Color(0xFF00E5FF) : Colors.white70, 
                                                      size: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          tx.merchant ?? tx.description ?? 'General Expense',
                                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          DateFormat('dd MMM yyyy').format(tx.date),
                                                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      PrivacyText(
                                                        rawValue: _formatMoney(tx.amount.toInt()),
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
                              ),
                            ],
                          );
                        }

                        _categoryKeys.clear();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Time Filters Selector
                            _buildFiltersBar(),
                            const SizedBox(height: 24),

                            // 2. Parent Interactive Donut Chart (Fixed)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: ReusableDonutChart(
                                data: chartData,
                                selectedId: _selectedCategoryId,
                                onSelected: (id) {
                                  setState(() {
                                    _selectedCategoryId = id;
                                    final index = chartData.indexWhere((item) => item.id == id);
                                    _scrollToCategory(id, index);
                                  });
                                },
                                centerTitle: 'Total Expense',
                                centerValue: totalExpense.toDouble() / 100.0,
                                isPrivate: isPrivate,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 3. Category Details Header (Fixed)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'SPENDING BY CATEGORY',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  PrivacyText(
                                    rawValue: AnalyticsFormatter.formatCurrency(totalExpense.toDouble() / 100.0),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 4. Categories List (Independently scrollable)
                            Expanded(
                              child: chartData.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(40),
                                      alignment: Alignment.center,
                                      child: const Text('No transactions match filters.', style: TextStyle(color: Colors.white24, fontSize: 13)),
                                    )
                                  : ListView.separated(
                                      controller: _categoryScrollController,
                                      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 40.0),
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: chartData.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final item = chartData[index];
                                        final cat = categoriesMap[item.id];
                                        final iconData = _getCategoryIcon(cat?.icon);
                                        final isSelected = _selectedCategoryId == item.id;
                                        final itemKey = _categoryKeys.putIfAbsent(item.id, () => GlobalKey());
                                        
                                        return GestureDetector(
                                          key: itemKey,
                                          onTap: () {
                                            if (_selectedCategoryId == item.id) {
                                              setState(() {
                                                _isDetailMode = true;
                                                _selectedSubExpenseId = '';
                                              });
                                            } else {
                                              setState(() {
                                                _selectedCategoryId = item.id;
                                              });
                                            }
                                          },
                                          onDoubleTap: () {
                                            setState(() {
                                              _selectedCategoryId = item.id;
                                              _isDetailMode = true;
                                              _selectedSubExpenseId = '';
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isSelected 
                                                  ? const Color(0xFF051833) 
                                                  : Colors.white.withOpacity(0.015),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected 
                                                    ? const Color(0xFF00E5FF) 
                                                    : Colors.white.withOpacity(0.03),
                                              ),
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
                                                        item.label,
                                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      AnimatedSwitcher(
                                                        duration: const Duration(milliseconds: 250),
                                                        child: Text(
                                                          isPrivate
                                                              ? 'Percentage: **%'
                                                              : 'Percentage: ${item.percentage.toStringAsFixed(1)}%',
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
                                                      rawValue: AnalyticsFormatter.formatCurrency(item.value),
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
                            ),
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

  Widget _buildFiltersBar() {
    final periods = ['Today', 'Week', 'Month', 'Last Month', '3M', '6M', '1Y', 'Custom'];
    return Container(
      height: 48,
      color: Colors.transparent,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: periods.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, i) {
          final p = periods[i];
          final isSelected = _selectedPeriod == p;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                if (p == 'Custom') {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF00E5FF),
                            onPrimary: Colors.black,
                            surface: Color(0xFF0F172A),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (range != null) {
                    setState(() {
                      _customDateRange = range;
                      _selectedPeriod = 'Custom';
                      _selectedCategoryId = '';
                    });
                  }
                } else {
                  setState(() {
                    _selectedPeriod = p;
                    _customDateRange = null;
                    _selectedCategoryId = '';
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF051833) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Center(
                  child: Text(
                    p,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }  Widget _buildHeader(BuildContext context) {
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

  Widget _buildDetailHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _isDetailMode = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () {
              setState(() {
                _isDetailMode = false;
              });
            },
          ),
        ],
      ),
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
