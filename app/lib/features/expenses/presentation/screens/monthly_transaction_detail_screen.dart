import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/widgets/privacy_text.dart';
import '../../../../shared/widgets/reusable_donut_chart.dart';
import '../../../../shared/utils/analytics_formatter.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../dashboard/presentation/providers/privacy_provider.dart';
import '../../../analytics/presentation/models/analytics_chart_data.dart';

class MonthlyTransactionDetailScreen extends ConsumerStatefulWidget {
  final String type; // 'income' or 'expense'

  const MonthlyTransactionDetailScreen({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<MonthlyTransactionDetailScreen> createState() => _MonthlyTransactionDetailScreenState();
}

class _MonthlyTransactionDetailScreenState extends ConsumerState<MonthlyTransactionDetailScreen> {

  // New redesigned layout state (exclusively for incomes)
  String _selectedPeriod = 'Month'; // Today, Week, Month, Last Month, 3M, 6M, 1Y, Custom
  bool _isInitialState = true;
  DateTimeRange? _customDateRange;
  String _breakdownMode = 'Category'; // Category, Account, Source
  String _selectedCategoryId = '';
  bool _isDetailMode = false;
  String _selectedSubIncomeId = '';

  // Navigation anchors for each period filter
  late DateTime _anchorToday;
  late DateTime _anchorWeek;
  late DateTime _anchorMonth;
  late DateTime _anchorLastMonth;
  late DateTime _anchor3M;
  late DateTime _anchor6M;
  late DateTime _anchor1Y;

  late ScrollController _categoryScrollController;
  late ScrollController _subIncomeScrollController;
  final Map<String, GlobalKey> _categoryKeys = {};
  final Map<String, GlobalKey> _subIncomeKeys = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    // Redesign state initialization
    _anchorToday = DateTime(now.year, now.month, now.day);
    _anchorWeek = _anchorToday.subtract(Duration(days: _anchorToday.weekday - 1));
    _anchorMonth = DateTime(now.year, now.month, 1);
    _anchorLastMonth = DateTime(now.year, now.month - 1, 1);
    _anchor3M = _anchorToday;
    _anchor6M = _anchorToday;
    _anchor1Y = _anchorToday;
    _isInitialState = true;

    _categoryScrollController = ScrollController();
    _subIncomeScrollController = ScrollController();
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    _subIncomeScrollController.dispose();
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

  void _scrollToSubIncome(String transactionId, int index) {
    if (index < 0) return;
    final key = _subIncomeKeys[transactionId];
    if (key == null) return;

    const double estimatedHeight = 66.0; // card height + separator
    final double targetOffset = index * estimatedHeight;

    if (_subIncomeScrollController.hasClients) {
      _subIncomeScrollController.animateTo(
        targetOffset.clamp(0.0, _subIncomeScrollController.position.maxScrollExtent),
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

  // Helper to check if date navigator RIGHT arrow should be enabled
  bool _canGoForward(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (period) {
      case 'Today':
        return _anchorToday.isBefore(today);
      case 'Week':
        final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
        return _anchorWeek.isBefore(currentWeekStart);
      case 'Month':
        final currentMonthStart = DateTime(today.year, today.month, 1);
        return _anchorMonth.isBefore(currentMonthStart);
      case 'Last Month':
        final currentMonthStart = DateTime(today.year, today.month, 1);
        return _anchorLastMonth.isBefore(currentMonthStart);
      case '1Y':
        final currentMonthStart = DateTime(today.year, today.month, 1);
        return DateTime(_anchor1Y.year, _anchor1Y.month, 1).isBefore(currentMonthStart);
      default:
        return false;
    }
  }

  // Increments or decrements active period range
  void _navigatePeriod(int direction) {
    setState(() {
      switch (_selectedPeriod) {
        case 'Today':
          _anchorToday = _anchorToday.add(Duration(days: direction));
          break;
        case 'Week':
          _anchorWeek = _anchorWeek.add(Duration(days: direction * 7));
          break;
        case 'Month':
          _anchorMonth = DateTime(_anchorMonth.year, _anchorMonth.month + direction, 1);
          break;
        case 'Last Month':
          _anchorLastMonth = DateTime(_anchorLastMonth.year, _anchorLastMonth.month + direction, 1);
          break;
        case '1Y':
          _anchor1Y = DateTime(_anchor1Y.year + direction, _anchor1Y.month, 1);
          break;
      }
      _selectedCategoryId = ''; // Reset segment selection on navigation
    });
  }

  // Get active DateTimeRange based on selection and anchors
  DateTimeRange _getActiveRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return DateTimeRange(
          start: DateTime(_anchorToday.year, _anchorToday.month, _anchorToday.day, 0, 0, 0),
          end: DateTime(_anchorToday.year, _anchorToday.month, _anchorToday.day, 23, 59, 59, 999),
        );
      case 'Week':
        return DateTimeRange(
          start: DateTime(_anchorWeek.year, _anchorWeek.month, _anchorWeek.day, 0, 0, 0),
          end: DateTime(_anchorWeek.year, _anchorWeek.month, _anchorWeek.day, 23, 59, 59, 999).add(const Duration(days: 6)),
        );
      case 'Month':
        final start = DateTime(_anchorMonth.year, _anchorMonth.month, 1, 0, 0, 0);
        final end = DateTime(_anchorMonth.year, _anchorMonth.month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case 'Last Month':
        final start = DateTime(_anchorLastMonth.year, _anchorLastMonth.month, 1, 0, 0, 0);
        final end = DateTime(_anchorLastMonth.year, _anchorLastMonth.month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case '3M':
        final start = DateTime(_anchor3M.year, _anchor3M.month - 2, 1, 0, 0, 0);
        final end = DateTime(_anchor3M.year, _anchor3M.month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case '6M':
        final start = DateTime(_anchor6M.year, _anchor6M.month - 5, 1, 0, 0, 0);
        final end = DateTime(_anchor6M.year, _anchor6M.month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case '1Y':
        final start = DateTime(_anchor1Y.year - 1, _anchor1Y.month + 1, 1, 0, 0, 0);
        final end = DateTime(_anchor1Y.year, _anchor1Y.month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case 'Custom':
        if (_customDateRange != null) return _customDateRange!;
        final todayStart = DateTime(now.year, now.month, 1, 0, 0, 0);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: todayStart, end: todayEnd);
      default:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
    }
  }

  // Get period banner label
  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'Today':
        return DateFormat('d MMMM yyyy').format(_anchorToday).toUpperCase();
      case 'Week':
        final end = _anchorWeek.add(const Duration(days: 6));
        return '${DateFormat('d MMM yyyy').format(_anchorWeek).toUpperCase()} – ${DateFormat('d MMM yyyy').format(end).toUpperCase()}';
      case 'Month':
        return DateFormat('MMMM yyyy').format(_anchorMonth).toUpperCase();
      case 'Last Month':
        return DateFormat('MMMM yyyy').format(_anchorLastMonth).toUpperCase();
      case '3M':
        final start = DateTime(_anchor3M.year, _anchor3M.month - 2, 1);
        return '${DateFormat('MMM yyyy').format(start).toUpperCase()} – ${DateFormat('MMM yyyy').format(_anchor3M).toUpperCase()}';
      case '6M':
        final start = DateTime(_anchor6M.year, _anchor6M.month - 5, 1);
        return '${DateFormat('MMM yyyy').format(start).toUpperCase()} – ${DateFormat('MMM yyyy').format(_anchor6M).toUpperCase()}';
      case '1Y':
        final start = DateTime(_anchor1Y.year - 1, _anchor1Y.month + 1, 1);
        return '${DateFormat('MMM yyyy').format(start).toUpperCase()} – ${DateFormat('MMM yyyy').format(_anchor1Y).toUpperCase()}';
      case 'Custom':
        if (_customDateRange != null) {
          return '${DateFormat('d MMM yyyy').format(_customDateRange!.start).toUpperCase()} – ${DateFormat('d MMM yyyy').format(_customDateRange!.end).toUpperCase()}';
        }
        return 'SELECT CUSTOM RANGE';
      default:
        return '';
    }
  }

  Color _getCategoryColor(Category? cat) {
    if (cat == null) return const Color(0xFF0066FF);
    if (cat.color != null && cat.color!.isNotEmpty) {
      try {
        return Color(int.parse(cat.color!));
      } catch (_) {}
    }
    
    final name = cat.name.toLowerCase();
    if (name.contains('salary')) return const Color(0xFF0066FF); // Blue
    if (name.contains('incentive') || name.contains('freelance')) return const Color(0xFF4CD964); // Green
    if (name.contains('interest')) return const Color(0xFFFF9500); // Orange
    if (name.contains('other') || name.contains('general')) return const Color(0xFFAF52DE); // Purple

    return IconMapper.getColor(cat.icon);
  }

  List<ChartDatum> _getSubIncomeChartData(List<Transaction> txs, int totalAmount) {
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
      final label = tx.merchant ?? tx.description ?? 'General Income';
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

  // Design Helpers for Account mapping
  Color _getAccountColor(String? colorStr) {
    if (colorStr != null && colorStr.isNotEmpty) {
      try {
        return Color(int.parse(colorStr));
      } catch (_) {}
    }
    return const Color(0xFF00E5FF);
  }

  IconData _getAccountIcon(String? iconName) {
    if (iconName != null && iconName.isNotEmpty) {
      switch (iconName.toLowerCase()) {
        case 'cash':
        case 'wallet':
          return Icons.wallet_outlined;
        case 'credit_card':
          return Icons.credit_card_outlined;
        default:
          return Icons.account_balance_outlined;
      }
    }
    return Icons.account_balance_outlined;
  }

  Color _getPaymentMethodColor(String type) {
    switch (type.toLowerCase()) {
      case 'upi':
        return const Color(0xFF00E5FF);
      case 'card':
        return const Color(0xFFFF9500);
      case 'cash':
        return const Color(0xFF4CD964);
      default:
        return const Color(0xFFAF52DE);
    }
  }

  IconData _getPaymentMethodIcon(String type) {
    switch (type.toLowerCase()) {
      case 'upi':
        return Icons.qr_code_scanner_outlined;
      case 'card':
        return Icons.credit_card_outlined;
      case 'cash':
        return Icons.payments_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == 'income';
    final primaryColor = isIncome ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30);

    return _buildRedesignedLayout(context, primaryColor);
  }

  // REDESIGNED LAYOUT FOR BOTH INCOME AND EXPENSE
  Widget _buildRedesignedLayout(BuildContext context, Color primaryColor) {
    final transactionsAsync = ref.watch(expenseListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final isPrivate = ref.watch(privacyModeProvider);
    final isIncome = widget.type == 'income';

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/expenses/add?type=${widget.type}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
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
              if (!_isDetailMode) _buildRedesignHeader(context),

              // Content
              Expanded(
                child: transactionsAsync.when(
                  data: (allTxs) {
                    return categoriesAsync.when(
                      data: (cats) {
                        return accountsAsync.when(
                          data: (allAccounts) {
                            return paymentMethodsAsync.when(
                              data: (allPaymentMethods) {
                                // Filter transactions in active range
                                final activeRange = _getActiveRange();
                                final filteredTxs = allTxs.where((tx) {
                                  if (tx.deletedAt != null) return false;
                                  final isCorrectType = isIncome 
                                      ? FinancialCalculationService.isIncome(tx) 
                                      : FinancialCalculationService.isExpense(tx);
                                  final inRange = tx.date.isAfter(activeRange.start.subtract(const Duration(seconds: 1))) &&
                                                  tx.date.isBefore(activeRange.end.add(const Duration(seconds: 1)));
                                  return isCorrectType && inRange;
                                }).toList();

                                // Sorted by date descending
                                filteredTxs.sort((a, b) => b.date.compareTo(a.date));

                                final categoriesMap = {for (var c in cats) c.id: c};
                                final accountsMap = {for (var a in allAccounts) a.id: a};
                                final paymentMethodsMap = {for (var pm in allPaymentMethods) pm.id: pm};

                                final List<ChartDatum> chartData = [];
                                int totalAmount = 0;

                                if (_breakdownMode == 'Category') {
                                  final spends = <String, int>{};
                                  for (var tx in filteredTxs) {
                                    if (tx.categoryId != null) {
                                      spends[tx.categoryId!] = (spends[tx.categoryId!] ?? 0) + tx.amount.toInt();
                                      totalAmount += tx.amount.toInt();
                                    }
                                  }
                                  spends.forEach((catId, amt) {
                                    final cat = categoriesMap[catId];
                                    final percentage = totalAmount == 0 ? 0.0 : (amt / totalAmount * 100);
                                    chartData.add(ChartDatum(
                                      id: catId,
                                      label: cat?.name ?? (isIncome ? 'Other Income' : 'Other Expense'),
                                      value: amt.toDouble() / 100.0,
                                      percentage: percentage,
                                      color: _getCategoryColor(cat),
                                      transactionCount: 1,
                                    ));
                                  });
                                } else if (_breakdownMode == 'Account') {
                                  final spends = <String, int>{};
                                  for (var tx in filteredTxs) {
                                    if (tx.accountId != null) {
                                      spends[tx.accountId!] = (spends[tx.accountId!] ?? 0) + tx.amount.toInt();
                                      totalAmount += tx.amount.toInt();
                                    }
                                  }
                                  spends.forEach((accId, amt) {
                                    final acc = accountsMap[accId];
                                    final percentage = totalAmount == 0 ? 0.0 : (amt / totalAmount * 100);
                                    chartData.add(ChartDatum(
                                      id: accId,
                                      label: acc?.name ?? 'Other Account',
                                      value: amt.toDouble() / 100.0,
                                      percentage: percentage,
                                      color: _getAccountColor(acc?.colorTheme),
                                      transactionCount: 1,
                                    ));
                                  });
                                } else {
                                  // For Income, group by Source. For Expense, group by Payment Type.
                                  if (isIncome) {
                                    // Group by Source (Merchant Name with Category Fallback)
                                    final spends = <String, int>{};
                                    final Map<String, String> sourceIds = {};
                                    for (var tx in filteredTxs) {
                                      final cat = categoriesMap[tx.categoryId];
                                      final sourceName = tx.merchant ?? tx.description ?? cat?.name ?? 'Other Income';
                                      spends[sourceName] = (spends[sourceName] ?? 0) + tx.amount.toInt();
                                      totalAmount += tx.amount.toInt();
                                      if (tx.categoryId != null) {
                                        sourceIds[sourceName] = tx.categoryId!;
                                      }
                                    }

                                    spends.forEach((sourceName, amt) {
                                      final percentage = totalAmount == 0 ? 0.0 : (amt / totalAmount * 100);
                                      final catId = sourceIds[sourceName];
                                      final cat = categoriesMap[catId];
                                      chartData.add(ChartDatum(
                                        id: sourceName,
                                        label: sourceName,
                                        value: amt.toDouble() / 100.0,
                                        percentage: percentage,
                                        color: cat != null ? _getCategoryColor(cat) : _getCategoryColor(null),
                                        transactionCount: 1,
                                      ));
                                    });
                                  } else {
                                    // Group by Payment Type (Payment Method)
                                    final spends = <String, int>{};
                                    for (var tx in filteredTxs) {
                                      if (tx.paymentMethodId != null) {
                                        spends[tx.paymentMethodId!] = (spends[tx.paymentMethodId!] ?? 0) + tx.amount.toInt();
                                        totalAmount += tx.amount.toInt();
                                      }
                                    }
                                    spends.forEach((pmId, amt) {
                                      final pm = paymentMethodsMap[pmId];
                                      final percentage = totalAmount == 0 ? 0.0 : (amt / totalAmount * 100);
                                      chartData.add(ChartDatum(
                                        id: pmId,
                                        label: pm?.name ?? pmId,
                                        value: amt.toDouble() / 100.0,
                                        percentage: percentage,
                                        color: _getPaymentMethodColor(pm?.type ?? 'upi'),
                                        transactionCount: 1,
                                      ));
                                    });
                                  }
                                }

                                chartData.sort((a, b) => b.value.compareTo(a.value));

                                if (_isDetailMode) {
                                  final List<Transaction> detailTxs;
                                  final String currentTitle;

                                  if (_breakdownMode == 'Category') {
                                    detailTxs = filteredTxs.where((tx) => tx.categoryId == _selectedCategoryId).toList();
                                    currentTitle = categoriesMap[_selectedCategoryId]?.name ?? 'Category';
                                  } else if (_breakdownMode == 'Account') {
                                    detailTxs = filteredTxs.where((tx) => tx.accountId == _selectedCategoryId).toList();
                                    currentTitle = accountsMap[_selectedCategoryId]?.name ?? 'Account';
                                  } else {
                                    if (isIncome) {
                                      detailTxs = filteredTxs.where((tx) => (tx.merchant ?? tx.description ?? categoriesMap[tx.categoryId]?.name ?? 'Other Income') == _selectedCategoryId).toList();
                                      currentTitle = _selectedCategoryId;
                                    } else {
                                      detailTxs = filteredTxs.where((tx) => tx.paymentMethodId == _selectedCategoryId).toList();
                                      currentTitle = paymentMethodsMap[_selectedCategoryId]?.name ?? _selectedCategoryId;
                                    }
                                  }
                                  detailTxs.sort((a, b) => b.date.compareTo(a.date));

                                  final int detailTotal = detailTxs.fold(0, (sum, tx) => sum + tx.amount.toInt());
                                  final subChartData = _getSubIncomeChartData(detailTxs, detailTotal);

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                        child: _buildDetailHeader(context, currentTitle),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                        child: ReusableDonutChart(
                                          data: subChartData,
                                          selectedId: _selectedSubIncomeId,
                                          onSelected: (id) {
                                            setState(() {
                                              _selectedSubIncomeId = id;
                                              final index = detailTxs.indexWhere((tx) => tx.id == id);
                                              _scrollToSubIncome(id, index);
                                            });
                                          },
                                          centerTitle: currentTitle,
                                          centerValue: detailTotal.toDouble() / 100.0,
                                          isPrivate: isPrivate,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                        child: Row(
                                          children: [
                                            Text(
                                              isIncome ? 'SUB-INCOME' : 'SUB-EXPENSES',
                                              style: TextStyle(
                                                color: primaryColor,
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
                                        child: detailTxs.isEmpty
                                            ? Container(
                                                padding: const EdgeInsets.all(40),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  isIncome 
                                                      ? 'No transactions in this category.' 
                                                      : 'No transactions in this category.',
                                                  style: const TextStyle(color: Colors.white24, fontSize: 13),
                                                ),
                                              )
                                            : ListView.separated(
                                                controller: _subIncomeScrollController,
                                                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 40.0),
                                                physics: const BouncingScrollPhysics(),
                                                itemCount: detailTxs.length,
                                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                                itemBuilder: (context, index) {
                                                  final tx = detailTxs[index];
                                                  final isSelected = _selectedSubIncomeId == tx.id;
                                                  final txKey = _subIncomeKeys.putIfAbsent(tx.id, () => GlobalKey());
                                                  final cat = categoriesMap[tx.categoryId];

                                                  return GestureDetector(
                                                    key: txKey,
                                                    behavior: HitTestBehavior.opaque,
                                                    onTap: () {
                                                      if (_selectedSubIncomeId == tx.id) {
                                                        context.push('/expenses/edit/${tx.id}');
                                                      } else {
                                                        setState(() {
                                                          _selectedSubIncomeId = tx.id;
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
                                                                  tx.merchant ?? tx.description ?? (isIncome ? 'General Income' : 'General Expense'),
                                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                                                ),
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  '${cat?.name ?? "General"} • ${DateFormat('dd MMM yyyy').format(tx.date)}',
                                                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              PrivacyText(
                                                                rawValue: isIncome 
                                                                    ? '+${_formatMoney(tx.amount.toInt())}'
                                                                    : '-${_formatMoney(tx.amount.toInt())}',
                                                                style: TextStyle(
                                                                  color: primaryColor, 
                                                                  fontWeight: FontWeight.bold, 
                                                                  fontSize: 13.5,
                                                                ),
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

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // 1. Time Filters Selector
                                    _buildPeriodSelector(),
                                    const SizedBox(height: 16),

                                    // 2. Donut Chart
                                    if (filteredTxs.isEmpty)
                                      _buildEmptyChartState()
                                    else
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
                                          centerTitle: isIncome ? 'Total Income' : 'Total Expense',
                                          centerValue: totalAmount.toDouble() / 100.0,
                                          isPrivate: isPrivate,
                                        ),
                                      ),
                                    const SizedBox(height: 24),

                                    // 3. Breakdown Header (Dropdown Switcher and Amount)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          PopupMenuButton<String>(
                                            offset: const Offset(0, 30),
                                            color: const Color(0xFF0A0F1D),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              side: BorderSide(color: Colors.white.withOpacity(0.08)),
                                            ),
                                            onSelected: (val) {
                                              setState(() {
                                                _breakdownMode = val;
                                                _selectedCategoryId = '';
                                              });
                                            },
                                            itemBuilder: (context) {
                                              return isIncome ? [
                                                PopupMenuItem(
                                                  value: 'Category',
                                                  child: Text(
                                                    'INCOME BY CATEGORY',
                                                    style: TextStyle(
                                                      color: _breakdownMode == 'Category' ? const Color(0xFF00E5FF) : Colors.white70,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Account',
                                                  child: Text(
                                                    'INCOME BY ACCOUNT',
                                                    style: TextStyle(
                                                      color: _breakdownMode == 'Account' ? const Color(0xFF00E5FF) : Colors.white70,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Source',
                                                  child: Text(
                                                    'INCOME BY SOURCE',
                                                    style: TextStyle(
                                                      color: _breakdownMode == 'Source' ? const Color(0xFF00E5FF) : Colors.white70,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ] : [
                                                PopupMenuItem(
                                                  value: 'Category',
                                                  child: Text(
                                                    'SPENDING BY CATEGORY',
                                                    style: TextStyle(
                                                      color: _breakdownMode == 'Category' ? primaryColor : Colors.white70,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Account',
                                                  child: Text(
                                                    'SPENDING BY ACCOUNT',
                                                    style: TextStyle(
                                                      color: _breakdownMode == 'Account' ? primaryColor : Colors.white70,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Payment Type',
                                                  child: Text(
                                                    'SPENDING BY PAYMENT METHOD',
                                                    style: TextStyle(
                                                      color: _breakdownMode == 'Payment Type' ? primaryColor : Colors.white70,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ];
                                            },
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  isIncome
                                                      ? (_breakdownMode == 'Category'
                                                          ? 'INCOME BY CATEGORY'
                                                          : _breakdownMode == 'Account'
                                                              ? 'INCOME BY ACCOUNT'
                                                              : 'INCOME BY SOURCE')
                                                      : (_breakdownMode == 'Category'
                                                          ? 'SPENDING BY CATEGORY'
                                                          : _breakdownMode == 'Account'
                                                              ? 'SPENDING BY ACCOUNT'
                                                              : 'SPENDING BY PAYMENT METHOD'),
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.keyboard_arrow_down,
                                                  color: primaryColor,
                                                  size: 14,
                                                ),
                                              ],
                                            ),
                                          ),
                                          PrivacyText(
                                            rawValue: AnalyticsFormatter.formatCurrency(totalAmount.toDouble() / 100.0),
                                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // 4. Breakdown Cards List
                                    Expanded(
                                      child: chartData.isEmpty
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                                              alignment: Alignment.center,
                                              child: Text(
                                                isIncome 
                                                    ? 'No income recorded for this period.'
                                                    : 'No expense recorded for this period.',
                                                style: const TextStyle(color: Colors.white30, fontSize: 12),
                                              ),
                                            )
                                          : ListView.separated(
                                              controller: _categoryScrollController,
                                              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 40.0),
                                              physics: const BouncingScrollPhysics(),
                                              itemCount: chartData.length,
                                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                                              itemBuilder: (context, index) {
                                                final item = chartData[index];
                                                final isSelected = _selectedCategoryId == item.id;
                                                final itemKey = _categoryKeys.putIfAbsent(item.id, () => GlobalKey());

                                                final IconData iconData;
                                                if (_breakdownMode == 'Category') {
                                                  final cat = categoriesMap[item.id];
                                                  iconData = IconMapper.getIcon(cat?.icon);
                                                } else if (_breakdownMode == 'Account') {
                                                  final acc = accountsMap[item.id];
                                                  iconData = _getAccountIcon(acc?.icon);
                                                } else {
                                                  if (isIncome) {
                                                    final catId = cats.firstWhere((c) => c.name == item.label, orElse: () => cats.first).id;
                                                    iconData = IconMapper.getIcon(categoriesMap[catId]?.icon);
                                                  } else {
                                                    final pm = paymentMethodsMap[item.id];
                                                    iconData = _getPaymentMethodIcon(pm?.type ?? 'upi');
                                                  }
                                                }

                                                return GestureDetector(
                                                  key: itemKey,
                                                  behavior: HitTestBehavior.opaque,
                                                  onTap: () {
                                                    if (_selectedCategoryId == item.id) {
                                                      setState(() {
                                                        _isDetailMode = true;
                                                        _selectedSubIncomeId = '';
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
                                                      _selectedSubIncomeId = '';
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
                                                              Text(
                                                                isPrivate
                                                                    ? 'Percentage: **%'
                                                                    : 'Percentage: ${item.percentage.toStringAsFixed(1)}%',
                                                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            PrivacyText(
                                                              rawValue: isIncome 
                                                                  ? '+${AnalyticsFormatter.formatCurrency(item.value)}'
                                                                  : AnalyticsFormatter.formatCurrency(item.value),
                                                              style: TextStyle(
                                                                color: primaryColor, 
                                                                fontWeight: FontWeight.bold, 
                                                                fontSize: 13.5,
                                                              ),
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
                              error: (e, _) => Center(child: Text('Error loading payment methods: $e', style: const TextStyle(color: Colors.red))),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                          error: (e, _) => Center(child: Text('Error loading accounts: $e', style: const TextStyle(color: Colors.red))),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                      error: (e, _) => Center(child: Text('Error loading categories: $e', style: const TextStyle(color: Colors.red))),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                  error: (e, _) => Center(child: Text('Error loading transactions: $e', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRedesignHeader(BuildContext context) {
    final isIncome = widget.type == 'income';
    if (_isInitialState) {
      // ← MONTHLY INCOME / MONTHLY EXPENSES (Back only)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                child: IconButton(
                  key: const Key('header_back_button'),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                  onPressed: () => context.pop(),
                ),
              ),
              Text(
                isIncome ? 'MONTHLY INCOME' : 'MONTHLY EXPENSES',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final label = _getPeriodLabel();
    final bool showArrows = _selectedPeriod == 'Today' ||
        _selectedPeriod == 'Week' ||
        _selectedPeriod == 'Month' ||
        _selectedPeriod == 'Last Month' ||
        _selectedPeriod == '1Y';

    if (showArrows) {
      final canForward = _canGoForward(_selectedPeriod);
      
      // Calculate responsive font size based on label length to prevent overflow
      double fontSize = 20.0;
      if (label.length > 20) {
        fontSize = 16.0;
      } else if (label.length > 15) {
        fontSize = 18.0;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                child: IconButton(
                  key: const Key('header_chevron_left'),
                  icon: const Icon(Icons.chevron_left, color: Colors.white70),
                  onPressed: () => _navigatePeriod(-1),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48.0),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  key: const Key('header_chevron_right'),
                  icon: const Icon(Icons.chevron_right, color: Colors.white70),
                  disabledColor: Colors.white12,
                  onPressed: canForward ? () => _navigatePeriod(1) : null,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // 3M, 6M, Custom: No arrows at all, just centered text.
      double fontSize = 20.0;
      if (label.length > 20) {
        fontSize = 16.0;
      } else if (label.length > 15) {
        fontSize = 18.0;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }
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

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'Week', 'Month', 'Last Month', '3M', '6M', '1Y', 'Custom'];
    return Container(
      height: 48,
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: periods.length,
        itemBuilder: (context, index) {
          final p = periods[index];
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
                      _isInitialState = false;
                    });
                  }
                } else {
                  setState(() {
                    _selectedPeriod = p;
                    _customDateRange = null;
                    _selectedCategoryId = '';
                    _isInitialState = false;
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
  }

  Widget _buildEmptyChartState() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'NO INCOME',
            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            '₹0',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'No income recorded for this period.',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }



}
