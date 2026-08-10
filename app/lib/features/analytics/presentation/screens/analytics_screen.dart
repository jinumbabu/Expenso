import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../goals/presentation/providers/goals_provider.dart';
import '../../../advisor/presentation/providers/advisor_provider.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../../../../core/database/app_database.dart';
import '../models/analytics_chart_data.dart';
import '../services/analytics_aggregation_service.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  // Period states
  String _selectedPeriod = 'Month';
  DateTimeRange? _customDateRange;

  // Filter Drawer toggles
  bool _filtersExpanded = false;
  String? _filterCategoryId;
  String? _filterAccountId;
  String? _filterPaymentMethodId;
  String _filterTxType = 'all'; // 'all', 'income', 'expense', 'transfer'
  bool _comparePreviousPeriod = true;

  // Toggles for Cash Flow Trend Card
  bool _showIncomeSeries = true;
  bool _showExpenseSeries = true;

  // Selection states
  String? _selectedCategoryId;
  String? _selectedIncomeCategoryId;
  String? _selectedPaymentMethodId;
  String? _selectedAccountId;
  
  // Category Trend selection
  String? _selectedTrendCategoryId;

  // Sankey flow node selection
  String? _selectedSankeyNodeId;

  // Chart type selections
  String _categoryChartType = 'Donut';
  String _incomeChartType = 'Donut';
  String _paymentChartType = 'Donut';
  String _paymentSplitType = 'expense';
  String _accountChartType = 'Donut';
  String _trendChartType = 'Line';

  int _touchedMonthlyGroupIndex = -1;
  int _touchedMonthlyRodIndex = -1;
  String _monthlyChartType = 'Grouped Bar'; // 'Grouped Bar', 'Stacked Bar', 'Line', 'Area'

  // Heatmap selections
  DateTime? _selectedHeatmapDate;

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0).format(amount);
  }

  String _formatMoneyDouble(double amount) {
    return NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0).format(amount);
  }

  Color _getCategoryColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('food') || n.contains('dining') || n.contains('grocery') || n.contains('groceries')) {
      return const Color(0xFF4CAF50); // Green
    }
    if (n.contains('shop') || n.contains('shopping') || n.contains('clothes')) {
      return const Color(0xFF9C27B0); // Purple
    }
    if (n.contains('bill') || n.contains('utility') || n.contains('utilities') || n.contains('rent')) {
      return const Color(0xFFFF9800); // Orange
    }
    if (n.contains('recharge') || n.contains('mobile') || n.contains('phone')) {
      return const Color(0xFF2196F3); // Blue
    }
    if (n.contains('travel') || n.contains('cab') || n.contains('taxi') || n.contains('transport') || n.contains('flight')) {
      return const Color(0xFF00BCD4); // Cyan
    }
    if (n.contains('entertainment') || n.contains('movie') || n.contains('show') || n.contains('ott') || n.contains('netflix')) {
      return const Color(0xFFE91E63); // Pink
    }
    if (n.contains('fuel') || n.contains('petrol') || n.contains('diesel') || n.contains('gas')) {
      return const Color(0xFFFFEB3B); // Yellow
    }
    if (n.contains('medical') || n.contains('health') || n.contains('doctor') || n.contains('hospital') || n.contains('medicine')) {
      return const Color(0xFFF44336); // Red
    }
    if (n.contains('education') || n.contains('school') || n.contains('college') || n.contains('book')) {
      return const Color(0xFF009688); // Teal
    }
    final hash = name.hashCode.abs();
    final List<Color> palette = [
      const Color(0xFFE57373), const Color(0xFFF06292), const Color(0xFFBA68C8),
      const Color(0xFF9575CD), const Color(0xFF7986CB), const Color(0xFF64B5F6),
      const Color(0xFF4FC3F7), const Color(0xFF4DB6AC), const Color(0xFF81C784),
      const Color(0xFFD4E157), const Color(0xFFFFD54F), const Color(0xFFFFB74D),
    ];
    return palette[hash % palette.length];
  }

  Color _getIncomeSourceColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('salary') || n.contains('wage') || n.contains('paycheck')) {
      return const Color(0xFF4CAF50); // Green
    }
    if (n.contains('business') || n.contains('sales') || n.contains('revenue')) {
      return const Color(0xFFFF9800); // Orange
    }
    if (n.contains('investment') || n.contains('dividend') || n.contains('stock')) {
      return const Color(0xFF9C27B0); // Purple
    }
    if (n.contains('interest') || n.contains('bank') || n.contains('fixed deposit')) {
      return const Color(0xFF00BCD4); // Cyan
    }
    if (n.contains('freelance') || n.contains('gig') || n.contains('contract')) {
      return const Color(0xFF2196F3); // Blue
    }
    if (n.contains('rental') || n.contains('rent')) {
      return const Color(0xFFFFEB3B); // Yellow
    }
    final hash = name.hashCode.abs();
    final List<Color> palette = [
      const Color(0xFF81C784), const Color(0xFFFFB74D), const Color(0xFFBA68C8),
      const Color(0xFF4FC3F7), const Color(0xFF64B5F6), const Color(0xFFFFF176),
    ];
    return palette[hash % palette.length];
  }

  List<ChartDatum> _getCategoryChartData(List<Transaction> txs, List<Category> cats) {
    return AnalyticsAggregationService.getCategoryChartData(txs, cats);
  }

  List<ChartDatum> _getIncomeChartData(List<Transaction> txs, List<Category> cats) {
    return AnalyticsAggregationService.getIncomeChartData(txs, cats);
  }

  List<ChartDatum> _getPaymentChartData(List<Transaction> txs, List<PaymentMethod> pms) {
    return AnalyticsAggregationService.getPaymentChartData(txs, pms);
  }

  List<ChartDatum> _getAccountChartData(List<Account> accounts) {
    return AnalyticsAggregationService.getAccountChartData(accounts);
  }

  DateTimeRange _getRangeForFilter(String filter, DateTimeRange? customRange) {
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
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
      case 'Last Month':
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final lastYear = now.month == 1 ? now.year - 1 : now.year;
        final startOfLastMonth = DateTime(lastYear, lastMonth, 1);
        final endOfLastMonth = DateTime(lastYear, lastMonth + 1, 1).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: startOfLastMonth, end: endOfLastMonth);
      case '3M':
        final start = todayStart.subtract(const Duration(days: 90));
        return DateTimeRange(start: start, end: todayEnd);
      case '6M':
        final start = todayStart.subtract(const Duration(days: 180));
        return DateTimeRange(start: start, end: todayEnd);
      case 'Year':
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        return DateTimeRange(start: startOfYear, end: endOfYear);
      case 'Custom':
        if (customRange != null) return customRange;
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: todayEnd);
      default:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: todayEnd);
    }
  }

  DateTimeRange _getPrevPeriodDateRange(DateTimeRange currentRange) {
    final duration = currentRange.end.difference(currentRange.start);
    final start = currentRange.start.subtract(duration);
    final end = currentRange.start.subtract(const Duration(milliseconds: 1));
    return DateTimeRange(start: start, end: end);
  }

  bool _applyFilters(Transaction tx, Map<String, Category> cats, Map<String, Account> accs, Map<String, String> pms) {
    // 1. Transaction Type filter
    if (_filterTxType != 'all') {
      if (_filterTxType == 'income' && !FinancialCalculationService.isIncome(tx)) return false;
      if (_filterTxType == 'expense' && !FinancialCalculationService.isExpense(tx)) return false;
      if (_filterTxType == 'transfer' && tx.type != 'transfer_debit' && tx.type != 'transfer_credit') return false;
    }

    // 2. Category filter
    if (_filterCategoryId != null && tx.categoryId != _filterCategoryId) return false;

    // 3. Account filter
    if (_filterAccountId != null && tx.accountId != _filterAccountId) return false;

    // 4. Payment Method filter
    if (_filterPaymentMethodId != null && tx.paymentMethodId != _filterPaymentMethodId) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(expenseListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final accountsAsync = ref.watch(recalculatedAccountsProvider);
    final goals = ref.watch(goalsListNotifierProvider);
    final advisorState = ref.watch(advisorProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020612), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: txsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
            error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            data: (allTxs) {
              final cats = categoriesAsync.maybeWhen(data: (c) => c, orElse: () => <Category>[]);
              final accounts = accountsAsync.maybeWhen(data: (a) => a, orElse: () => <Account>[]);
              final pms = paymentMethodsAsync.maybeWhen(data: (p) => p, orElse: () => <PaymentMethod>[]);

              final categoriesMap = {for (var c in cats) c.id: c};
              final accountsMap = {for (var a in accounts) a.id: a};
              final idToPmNameMap = {for (var p in pms) p.id: p.name};

              final activeRange = _getRangeForFilter(_selectedPeriod, _customDateRange);
              final prevRange = _getPrevPeriodDateRange(activeRange);

              // Segment period transactions
              final periodTxs = allTxs.where((tx) => tx.date.isAfter(activeRange.start.subtract(const Duration(seconds: 1))) &&
                  tx.date.isBefore(activeRange.end.add(const Duration(seconds: 1)))).toList();
              final prevPeriodTxs = allTxs.where((tx) => tx.date.isAfter(prevRange.start.subtract(const Duration(seconds: 1))) &&
                  tx.date.isBefore(prevRange.end.add(const Duration(seconds: 1)))).toList();

              // Derived filter states
              final filteredTxs = periodTxs.where((tx) => _applyFilters(tx, categoriesMap, accountsMap, idToPmNameMap)).toList();
              final prevFilteredTxs = prevPeriodTxs.where((tx) => _applyFilters(tx, categoriesMap, accountsMap, idToPmNameMap)).toList();

              return Column(
                children: [
                  // Top Title Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Analytics Dashboard',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _filtersExpanded ? Icons.filter_alt_off : Icons.filter_alt,
                            color: _filtersExpanded ? const Color(0xFF00E5FF) : Colors.white70,
                          ),
                          onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),

                  // Global Period Selector pills
                  _buildGlobalPeriodSelector(),
                  const Divider(color: Colors.white10, height: 1),

                  // Collapsible Filter panel
                  _buildCollapsibleFilterPanel(cats, accounts, pms),
                  if (_filtersExpanded) const Divider(color: Colors.white10, height: 1),

                  Expanded(
                    child: filteredTxs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off, size: 64, color: Colors.white24),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No Matching Results',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Adjust your filters to explore other periods or categories.',
                                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                            children: [
                              // Summary stats header
                              _buildSummaryHeader(),
                              const SizedBox(height: 10),

                              // 1. Summary cards grid
                              _buildSummaryGrid(filteredTxs, prevFilteredTxs),
                              const SizedBox(height: 16),

                              // 2. Cash flow trend line graph
                              _buildCashFlowTrendCard(filteredTxs, activeRange),
                              const SizedBox(height: 16),

                              // 3. Expense Breakdown Donut chart
                              _buildExpenseBreakdownCard(filteredTxs, cats),
                              const SizedBox(height: 16),

                              // 4. Income Sources card
                              _buildIncomeSourcesCard(filteredTxs, cats),
                              const SizedBox(height: 16),

                              // Payment Method Split
                              _buildPaymentMethodSplitCard(filteredTxs, pms),
                              const SizedBox(height: 16),

                              // Account Distribution
                              _buildAccountDistributionCard(accounts),
                              const SizedBox(height: 16),

                              // Category Trend
                              _buildCategoryTrendCard(filteredTxs, cats, activeRange),
                              const SizedBox(height: 16),

                              // Sankey Flow Diagram
                              _buildSankeyFlowCard(filteredTxs, cats, accounts, pms),
                              const SizedBox(height: 16),

                              // 5. Monthly comparison bar chart
                              _buildMonthlyComparisonCard(filteredTxs, activeRange),
                              const SizedBox(height: 16),

                              // 6. Merchant Leaderboard bars
                              _buildMerchantLeaderboard(filteredTxs),
                              const SizedBox(height: 16),

                              // 7. Savings goals progress card
                              _buildSavingsGoalsCard(goals),
                              const SizedBox(height: 16),

                              // 8. Daily spending Heatmap card
                              _buildDailySpendingHeatmapCard(filteredTxs, cats, accounts, activeRange),
                              const SizedBox(height: 16),

                              // 9. AI Financial Insights card
                              _buildAIFinancialInsightsCard(advisorState),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- COMPONENT BUILDERS ---

  Widget _buildGlobalPeriodSelector() {
    final periods = ['Today', 'Week', 'Month', 'Last Month', '3M', '6M', 'Year', 'Custom'];
    return Container(
      height: 48,
      color: Colors.transparent,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: periods.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    });
                  }
                } else {
                  setState(() {
                    _selectedPeriod = p;
                    _customDateRange = null;
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

  Widget _buildCollapsibleFilterPanel(List<Category> cats, List<Account> accs, List<PaymentMethod> pms) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: !_filtersExpanded
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Category Filter
                      Expanded(
                        child: _buildPanelDropdown(
                          label: 'Category',
                          value: _filterCategoryId,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Categories')),
                            ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (val) => setState(() => _filterCategoryId = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Account Filter
                      Expanded(
                        child: _buildPanelDropdown(
                          label: 'Account',
                          value: _filterAccountId,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Accounts')),
                            ...accs.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                          ],
                          onChanged: (val) => setState(() => _filterAccountId = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Payment Method Filter
                      Expanded(
                        child: _buildPanelDropdown(
                          label: 'Payment',
                          value: _filterPaymentMethodId,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Methods')),
                            ...pms.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                          ],
                          onChanged: (val) => setState(() => _filterPaymentMethodId = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Transaction Type Filter
                      Expanded(
                        child: _buildPanelDropdown(
                          label: 'Tx Type',
                          value: _filterTxType,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Types')),
                            DropdownMenuItem(value: 'income', child: Text('Income')),
                            DropdownMenuItem(value: 'expense', child: Text('Expense')),
                            DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                          ],
                          onChanged: (val) => setState(() => _filterTxType = val),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _filterCategoryId = null;
                          _filterAccountId = null;
                          _filterPaymentMethodId = null;
                          _filterTxType = 'all';
                          _selectedCategoryId = null;
                          _selectedIncomeCategoryId = null;
                          _selectedPaymentMethodId = null;
                          _selectedAccountId = null;
                          _selectedTrendCategoryId = null;
                          _selectedSankeyNodeId = null;
                        });
                      },
                      child: const Text('Reset Filters', style: TextStyle(color: Color(0xFFFF3B30), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPanelDropdown({
    required String label,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required ValueChanged<dynamic> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: value,
          dropdownColor: const Color(0xFF0F172A),
          style: const TextStyle(color: Colors.white, fontSize: 11),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white30, size: 18),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'SUMMARY',
          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        Row(
          children: [
            const Text('Compare Prev. Period', style: TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(width: 4),
            Switch(
              value: _comparePreviousPeriod,
              activeColor: const Color(0xFF00E5FF),
              onChanged: (val) => setState(() => _comparePreviousPeriod = val),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(List<Transaction> current, List<Transaction> prev) {
    double currentInc = 0;
    double currentExp = 0;
    for (var tx in current) {
      if (FinancialCalculationService.isIncome(tx)) currentInc += tx.amount / 100.0;
      if (FinancialCalculationService.isExpense(tx)) currentExp += tx.amount / 100.0;
    }

    double prevInc = 0;
    double prevExp = 0;
    for (var tx in prev) {
      if (FinancialCalculationService.isIncome(tx)) prevInc += tx.amount / 100.0;
      if (FinancialCalculationService.isExpense(tx)) prevExp += tx.amount / 100.0;
    }

    final double currentSav = currentInc - currentExp;
    final double prevSav = prevInc - prevExp;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard('Income', _formatMoneyDouble(currentInc), currentInc, prevInc, const Color(0xFF0066FF)),
        _buildStatCard('Expenses', _formatMoneyDouble(currentExp), currentExp, prevExp, const Color(0xFFFF3B30)),
        _buildStatCard('Savings', _formatMoneyDouble(currentSav), currentSav, prevSav, const Color(0xFF4CAF50)),
        _buildStatCard(
          'Transactions',
          current.length.toString(),
          current.length.toDouble(),
          prev.length.toDouble(),
          const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, double curVal, double preVal, Color accent) {
    double change = 0.0;
    if (preVal != 0) {
      change = ((curVal - preVal) / preVal) * 100.0;
    } else {
      change = curVal > 0 ? 100.0 : 0.0;
    }

    final isPositive = change >= 0;
    final displayChange = '${isPositive ? "+" : ""}${change.toStringAsFixed(0)}%';

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              if (_comparePreviousPeriod)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    displayChange,
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                height: 2,
                width: 32,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowTrendCard(List<Transaction> txs, DateTimeRange range) {
    // Group txs daily/weekly depending on duration
    final days = range.end.difference(range.start).inDays;
    final List<CashFlowPoint> points = [];

    if (days <= 1) {
      // Hourly segments for Today
      for (int hour = 0; hour < 24; hour += 2) {
        final label = '${hour.toString().padLeft(2, '0')}:00';
        double inc = 0;
        double exp = 0;
        for (var tx in txs) {
          if (tx.date.hour >= hour && tx.date.hour < hour + 2) {
            if (FinancialCalculationService.isIncome(tx)) {
              inc += tx.amount / 100.0;
            } else if (FinancialCalculationService.isExpense(tx)) {
              exp += tx.amount / 100.0;
            }
          }
        }
        points.add(CashFlowPoint(
          label: label,
          income: inc,
          expense: exp,
          savings: inc - exp,
          netCashFlow: inc - exp,
        ));
      }
    } else if (days <= 31) {
      // Daily segments
      var current = DateTime(range.start.year, range.start.month, range.start.day);
      final targetEnd = DateTime(range.end.year, range.end.month, range.end.day);
      while (!current.isAfter(targetEnd)) {
        final label = DateFormat('dd').format(current);
        double inc = 0;
        double exp = 0;
        for (var tx in txs) {
          if (tx.date.year == current.year && tx.date.month == current.month && tx.date.day == current.day) {
            if (FinancialCalculationService.isIncome(tx)) {
              inc += tx.amount / 100.0;
            } else if (FinancialCalculationService.isExpense(tx)) {
              exp += tx.amount / 100.0;
            }
          }
        }
        points.add(CashFlowPoint(
          label: label,
          income: inc,
          expense: exp,
          savings: inc - exp,
          netCashFlow: inc - exp,
        ));
        current = current.add(const Duration(days: 1));
      }
    } else {
      // Monthly segments
      var current = DateTime(range.start.year, range.start.month, 1);
      final targetEnd = DateTime(range.end.year, range.end.month, 1);
      while (!current.isAfter(targetEnd)) {
        final label = DateFormat('MMM').format(current);
        double inc = 0;
        double exp = 0;
        for (var tx in txs) {
          if (tx.date.year == current.year && tx.date.month == current.month) {
            if (FinancialCalculationService.isIncome(tx)) {
              inc += tx.amount / 100.0;
            } else if (FinancialCalculationService.isExpense(tx)) {
              exp += tx.amount / 100.0;
            }
          }
        }
        points.add(CashFlowPoint(
          label: label,
          income: inc,
          expense: exp,
          savings: inc - exp,
          netCashFlow: inc - exp,
        ));
        current = DateTime(current.year, current.month + 1, 1);
      }
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CASH FLOW TREND', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Row(
                children: [
                  _buildLegendToggle('Income', const Color(0xFF0066FF), _showIncomeSeries, (v) => setState(() => _showIncomeSeries = v)),
                  const SizedBox(width: 8),
                  _buildLegendToggle('Expense', const Color(0xFFFF3B30), _showExpenseSeries, (v) => setState(() => _showExpenseSeries = v)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: points.isEmpty
                ? const Center(child: Text('No Data', style: TextStyle(color: Colors.white24)))
                : LineChart(
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
                              if (idx >= 0 && idx < points.length && (idx % (max(1, points.length ~/ 5)) == 0)) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(points[idx].label, style: const TextStyle(color: Colors.white38, fontSize: 8)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        if (_showIncomeSeries)
                          _lineBarData(points.map((p) => p.income).toList(), const Color(0xFF0066FF), true, true),
                        if (_showExpenseSeries)
                          _lineBarData(points.map((p) => p.expense).toList(), const Color(0xFFFF3B30), true, true),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendToggle(String label, Color color, bool isActive, ValueChanged<bool> onTap) {
    return InkWell(
      onTap: () => onTap(!isActive),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.4,
        child: Row(
          children: [
            Icon(Icons.lens, color: color, size: 8),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSplitToggle(String label, Color color, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Opacity(
        opacity: isSelected ? 1.0 : 0.4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.lens, color: color, size: 8),
              const SizedBox(width: 4),
            ],
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildUniversalChart({
    required String chartType,
    required List<ChartDatum> data,
    required String? selectedId,
    required Function(String id) onSelected,
    required String centerTitle,
    required double centerValue,
  }) {
    if (data.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const Text(
          'NO DATA FOR THIS PERIOD',
          style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    Widget chartWidget;

    if (chartType == 'Donut' || chartType == 'Pie') {
      final isDonut = chartType == 'Donut';
      final List<PieChartSectionData> sections = [];
      
      for (int i = 0; i < data.length; i++) {
        final datum = data[i];
        final isSelected = selectedId == datum.id;
        final baseColor = datum.color;
        
        Color sectionColor;
        if (selectedId != null) {
          sectionColor = isSelected ? baseColor : baseColor.withOpacity(0.3);
        } else {
          sectionColor = baseColor;
        }

        final double radius = isSelected ? (isDonut ? 48.0 : 38.0) : (isDonut ? 38.0 : 28.0);

        sections.add(PieChartSectionData(
          color: sectionColor,
          value: datum.value,
          title: isSelected ? '${datum.percentage.toStringAsFixed(0)}%' : '',
          radius: radius,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ));
      }

      final centerDatum = selectedId != null ? data.firstWhere((d) => d.id == selectedId, orElse: () => data.first) : null;
      final String label = centerDatum != null ? centerDatum.label.toUpperCase() : centerTitle.toUpperCase();
      final String amount = centerDatum != null ? _formatMoneyDouble(centerDatum.value) : _formatMoneyDouble(centerValue);
      final String? pctText = centerDatum != null ? '${centerDatum.percentage.toStringAsFixed(0)}%' : null;

      final pieChartWidget = PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: isDonut ? 46 : 0,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              if (event is FlTapUpEvent) {
                if (response == null || response.touchedSection == null) {
                  onSelected('');
                  return;
                }
                final touchedIdx = response.touchedSection!.touchedSectionIndex;
                if (touchedIdx >= 0 && touchedIdx < data.length) {
                  onSelected(data[touchedIdx].id);
                } else {
                  onSelected('');
                }
              }
            },
          ),
        ),
      );

      if (isDonut) {
        chartWidget = Stack(
          alignment: Alignment.center,
          children: [
            pieChartWidget,
            IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amount,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (pctText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      pctText,
                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      } else {
        chartWidget = pieChartWidget;
      }
    } else if (chartType == 'Bar') {
      double maxVal = 0.0;
      for (var datum in data) {
        if (datum.value > maxVal) maxVal = datum.value;
      }
      if (maxVal == 0) maxVal = 1.0;

      chartWidget = BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < data.length) {
                    final datum = data[idx];
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        datum.label.length > 5 ? '${datum.label.substring(0, 5)}.' : datum.label,
                        style: const TextStyle(color: Colors.white38, fontSize: 8),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchCallback: (event, response) {
              if (event is FlTapUpEvent) {
                if (response == null || response.spot == null) {
                  onSelected('');
                  return;
                }
                final touchedIdx = response.spot!.touchedBarGroupIndex;
                if (touchedIdx >= 0 && touchedIdx < data.length) {
                  onSelected(data[touchedIdx].id);
                } else {
                  onSelected('');
                }
              }
            },
          ),
          barGroups: List.generate(data.length, (i) {
            final datum = data[i];
            final isSelected = selectedId == datum.id;
            Color barColor = datum.color;
            if (selectedId != null) {
              barColor = isSelected ? barColor : barColor.withOpacity(0.3);
            }
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: datum.value,
                  color: barColor,
                  width: isSelected ? 18 : 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      );
    } else {
      double maxVal = 0.0;
      for (var datum in data) {
        if (datum.value > maxVal) maxVal = datum.value;
      }
      if (maxVal == 0) maxVal = 1.0;

      chartWidget = ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        itemBuilder: (context, i) {
          final datum = data[i];
          final isSelected = selectedId == datum.id;
          final opacity = selectedId == null ? 1.0 : (isSelected ? 1.0 : 0.3);
          final ratio = datum.value / maxVal;

          return GestureDetector(
            onTap: () => onSelected(datum.id),
            child: Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0A1E3D) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          datum.label,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_formatMoneyDouble(datum.value)} (${datum.percentage.toStringAsFixed(0)}%)',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: ratio.clamp(0.0, 1.0),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: datum.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey('${chartType}_${selectedId ?? 'none'}_${data.length}'),
        child: chartWidget,
      ),
    );
  }

  Widget _buildExpenseBreakdownCard(List<Transaction> txs, List<Category> cats) {
    final data = _getCategoryChartData(txs, cats);
    double totalExpense = 0;
    for (var d in data) {
      totalExpense += d.value;
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CATEGORY SHARE', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              _buildChartTypeSelector(
                currentType: _categoryChartType,
                options: const ['Donut', 'Pie', 'Bar', 'Horizontal Bar'],
                onChanged: (val) => setState(() => _categoryChartType = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const SizedBox(
              height: 140,
              child: Center(child: Text('No Expense Data', style: TextStyle(color: Colors.white38, fontSize: 11))),
            )
          else ...[
            if (_categoryChartType != 'Horizontal Bar') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: _buildUniversalChart(
                      chartType: _categoryChartType,
                      data: data,
                      selectedId: _selectedCategoryId,
                      onSelected: (id) {
                        setState(() {
                          if (_selectedCategoryId == id) {
                            _selectedCategoryId = null;
                          } else {
                            _selectedCategoryId = id;
                          }
                        });
                      },
                      centerTitle: 'TOTAL EXPENSE',
                      centerValue: totalExpense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              _buildUniversalChart(
                chartType: _categoryChartType,
                data: data,
                selectedId: _selectedCategoryId,
                onSelected: (id) {
                  setState(() {
                    if (_selectedCategoryId == id) {
                      _selectedCategoryId = null;
                    } else {
                      _selectedCategoryId = id;
                    }
                  });
                },
                centerTitle: 'TOTAL EXPENSE',
                centerValue: totalExpense,
              ),
              const SizedBox(height: 16),
            ],
            if (_categoryChartType != 'Horizontal Bar')
              ...List.generate(data.length, (i) {
                final d = data[i];
                final isSelected = d.id == _selectedCategoryId;
                final opacity = _selectedCategoryId == null ? 1.0 : (isSelected ? 1.0 : 0.3);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategoryId = null;
                      } else {
                        _selectedCategoryId = d.id;
                      }
                    });
                  },
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0A1E3D) : Colors.white.withOpacity(0.015),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lens, color: d.color, size: 10),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d.label,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '${_formatMoneyDouble(d.value)} (${d.percentage.toStringAsFixed(0)}%)',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildIncomeSourcesCard(List<Transaction> txs, List<Category> cats) {
    final data = _getIncomeChartData(txs, cats);
    double totalIncome = 0;
    for (var d in data) {
      totalIncome += d.value;
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('INCOME SOURCES', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              _buildChartTypeSelector(
                currentType: _incomeChartType,
                options: const ['Donut', 'Pie', 'Bar', 'Horizontal Bar'],
                onChanged: (val) => setState(() => _incomeChartType = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const SizedBox(
              height: 140,
              child: Center(child: Text('No Income Data', style: TextStyle(color: Colors.white38, fontSize: 11))),
            )
          else ...[
            if (_incomeChartType != 'Horizontal Bar') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: _buildUniversalChart(
                      chartType: _incomeChartType,
                      data: data,
                      selectedId: _selectedIncomeCategoryId,
                      onSelected: (id) {
                        setState(() {
                          if (_selectedIncomeCategoryId == id) {
                            _selectedIncomeCategoryId = null;
                          } else {
                            _selectedIncomeCategoryId = id;
                          }
                        });
                      },
                      centerTitle: 'TOTAL INCOME',
                      centerValue: totalIncome,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              _buildUniversalChart(
                chartType: _incomeChartType,
                data: data,
                selectedId: _selectedIncomeCategoryId,
                onSelected: (id) {
                  setState(() {
                    if (_selectedIncomeCategoryId == id) {
                      _selectedIncomeCategoryId = null;
                    } else {
                      _selectedIncomeCategoryId = id;
                    }
                  });
                },
                centerTitle: 'TOTAL INCOME',
                centerValue: totalIncome,
              ),
              const SizedBox(height: 16),
            ],
            if (_incomeChartType != 'Horizontal Bar')
              ...List.generate(data.length, (i) {
                final d = data[i];
                final isSelected = d.id == _selectedIncomeCategoryId;
                final opacity = _selectedIncomeCategoryId == null ? 1.0 : (isSelected ? 1.0 : 0.3);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIncomeCategoryId = null;
                      } else {
                        _selectedIncomeCategoryId = d.id;
                      }
                    });
                  },
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0A1E3D) : Colors.white.withOpacity(0.015),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lens, color: d.color, size: 10),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d.label,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '${_formatMoneyDouble(d.value)} (${d.percentage.toStringAsFixed(0)}%)',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildMerchantLeaderboard(List<Transaction> txs) {
    final Map<String, double> merchantSpend = {};
    for (var tx in txs) {
      if (FinancialCalculationService.isExpense(tx)) {
        final m = tx.merchant ?? tx.description ?? 'General';
        merchantSpend[m] = (merchantSpend[m] ?? 0) + tx.amount / 100.0;
      }
    }

    final sorted = merchantSpend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final limitList = sorted.take(5).toList();
    final double maxVal = limitList.isNotEmpty ? limitList.first.value : 1.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('MERCHANT LEADERBOARD', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          if (limitList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No merchant spend records found', style: TextStyle(color: Colors.white38, fontSize: 11))),
            )
          else
            ...limitList.map((entry) {
              final pct = maxVal > 0 ? (entry.value / maxVal) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(_formatMoneyDouble(entry.value), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(3)),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              height: 6,
                              width: constraints.maxWidth * pct,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF00E5FF)]),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSavingsGoalsCard(List<Goal> goals) {
    if (goals.isEmpty) {
      return const GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('SAVINGS GOALS', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            SizedBox(height: 24),
            Center(child: Text('No savings goals set', style: TextStyle(color: Colors.white38, fontSize: 11))),
          ],
        ),
      );
    }

    final firstGoal = goals.first;
    final target = firstGoal.targetAmount / 100.0;
    final current = firstGoal.currentAmount / 100.0;
    final pct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SAVINGS GOALS', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 64,
                width: 64,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.04),
                  color: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(firstGoal.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Saved ${_formatMoneyDouble(current)} of ${_formatMoneyDouble(target)} (${(pct * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    if (firstGoal.targetDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Target Date: ${DateFormat('MMMM dd, yyyy').format(firstGoal.targetDate!)}',
                        style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSplitCard(List<Transaction> txs, List<PaymentMethod> pms) {
    // Filter transactions based on the selected split type
    final filteredTxsForPm = txs.where((tx) {
      if (_paymentSplitType == 'income') {
        return FinancialCalculationService.isIncome(tx);
      } else {
        return FinancialCalculationService.isExpense(tx);
      }
    }).toList();

    final data = _getPaymentChartData(filteredTxsForPm, pms);
    double totalSpends = 0;
    for (var d in data) {
      totalSpends += d.value;
    }

    final bool isEmpty = data.isEmpty;
    final List<ChartDatum> displayData = isEmpty
        ? [
            ChartDatum(
              id: 'dummy',
              label: '',
              value: 0.0001,
              percentage: 0.0,
              color: Colors.white.withOpacity(0.05),
              transactionCount: 0,
            )
          ]
        : data;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PAYMENT METHOD SPLIT', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              _buildChartTypeSelector(
                currentType: _paymentChartType,
                options: const ['Donut', 'Pie', 'Bar', 'Horizontal Bar'],
                onChanged: (val) => setState(() => _paymentChartType = val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPaymentSplitToggle(
                'Income',
                const Color(0xFF0066FF),
                _paymentSplitType == 'income',
                () => setState(() {
                  _paymentSplitType = 'income';
                  _selectedPaymentMethodId = null;
                }),
              ),
              const SizedBox(width: 24),
              _buildPaymentSplitToggle(
                'Expense',
                const Color(0xFFFF3B30),
                _paymentSplitType == 'expense',
                () => setState(() {
                  _paymentSplitType = 'expense';
                  _selectedPaymentMethodId = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isEmpty) ...[
            if (_paymentChartType != 'Horizontal Bar') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: _buildUniversalChart(
                      chartType: _paymentChartType,
                      data: displayData,
                      selectedId: _selectedPaymentMethodId,
                      onSelected: (id) {},
                      centerTitle: _paymentSplitType == 'income' ? 'TOTAL INCOME' : 'TOTAL EXPENSE',
                      centerValue: 0.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              _buildUniversalChart(
                chartType: _paymentChartType,
                data: displayData,
                selectedId: _selectedPaymentMethodId,
                onSelected: (id) {},
                centerTitle: _paymentSplitType == 'income' ? 'TOTAL INCOME' : 'TOTAL EXPENSE',
                centerValue: 0.0,
              ),
              const SizedBox(height: 16),
            ],
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  _paymentSplitType == 'income'
                      ? 'No income transactions for this period.'
                      : 'No expense transactions for this period.',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ),
          ] else ...[
            if (_paymentChartType != 'Horizontal Bar') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: _buildUniversalChart(
                      chartType: _paymentChartType,
                      data: data,
                      selectedId: _selectedPaymentMethodId,
                      onSelected: (id) {
                        setState(() {
                          if (_selectedPaymentMethodId == id) {
                            _selectedPaymentMethodId = null;
                          } else {
                            _selectedPaymentMethodId = id;
                          }
                        });
                      },
                      centerTitle: _paymentSplitType == 'income' ? 'TOTAL INCOME' : 'TOTAL EXPENSE',
                      centerValue: totalSpends,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              _buildUniversalChart(
                chartType: _paymentChartType,
                data: data,
                selectedId: _selectedPaymentMethodId,
                onSelected: (id) {
                  setState(() {
                    if (_selectedPaymentMethodId == id) {
                      _selectedPaymentMethodId = null;
                    } else {
                      _selectedPaymentMethodId = id;
                    }
                  });
                },
                centerTitle: _paymentSplitType == 'income' ? 'TOTAL INCOME' : 'TOTAL EXPENSE',
                centerValue: totalSpends,
              ),
              const SizedBox(height: 16),
            ],
            if (_paymentChartType != 'Horizontal Bar')
              ...List.generate(data.length, (i) {
                final d = data[i];
                final isSelected = d.id == _selectedPaymentMethodId;
                final opacity = _selectedPaymentMethodId == null ? 1.0 : (isSelected ? 1.0 : 0.3);

                final double avg = d.transactionCount > 0 ? (d.value / d.transactionCount) : 0.0;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedPaymentMethodId = null;
                      } else {
                        _selectedPaymentMethodId = d.id;
                      }
                    });
                  },
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0A1E3D) : Colors.white.withOpacity(0.015),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lens, color: d.color, size: 10),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.label,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${d.transactionCount} txs • Avg: ${_formatMoneyDouble(avg)}',
                                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${_formatMoneyDouble(d.value)} (${d.percentage.toStringAsFixed(0)}%)',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountDistributionCard(List<Account> accounts) {
    final data = _getAccountChartData(accounts);
    double totalAbsoluteValue = 0;
    for (var d in data) {
      totalAbsoluteValue += d.value.abs();
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACCOUNT DISTRIBUTION', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              _buildChartTypeSelector(
                currentType: _accountChartType,
                options: const ['Donut', 'Pie', 'Bar', 'Horizontal Bar'],
                onChanged: (val) => setState(() => _accountChartType = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const SizedBox(
              height: 140,
              child: Center(child: Text('No Account Data', style: TextStyle(color: Colors.white38, fontSize: 11))),
            )
          else ...[
            if (_accountChartType != 'Horizontal Bar') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: _buildUniversalChart(
                      chartType: _accountChartType,
                      data: data.map((d) => ChartDatum(
                        id: d.id,
                        label: d.label,
                        value: d.value.abs(),
                        percentage: d.percentage,
                        color: d.color,
                        transactionCount: 0,
                      )).toList(),
                      selectedId: _selectedAccountId,
                      onSelected: (id) {
                        setState(() {
                          if (_selectedAccountId == id) {
                            _selectedAccountId = null;
                          } else {
                            _selectedAccountId = id;
                          }
                        });
                      },
                      centerTitle: 'TOTAL PROPORTION',
                      centerValue: totalAbsoluteValue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              _buildUniversalChart(
                chartType: _accountChartType,
                data: data.map((d) => ChartDatum(
                  id: d.id,
                  label: d.label,
                  value: d.value.abs(),
                  percentage: d.percentage,
                  color: d.color,
                  transactionCount: 0,
                )).toList(),
                selectedId: _selectedAccountId,
                onSelected: (id) {
                  setState(() {
                    if (_selectedAccountId == id) {
                      _selectedAccountId = null;
                    } else {
                      _selectedAccountId = id;
                    }
                  });
                },
                centerTitle: 'TOTAL PROPORTION',
                centerValue: totalAbsoluteValue,
              ),
              const SizedBox(height: 16),
            ],
            if (_accountChartType != 'Horizontal Bar')
              ...List.generate(data.length, (i) {
                final d = data[i];
                final isSelected = d.id == _selectedAccountId;
                final opacity = _selectedAccountId == null ? 1.0 : (isSelected ? 1.0 : 0.3);

                final isNegative = d.value < 0;
                final displayAmt = (isNegative ? '-' : '') + _formatMoneyDouble(d.value.abs());

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedAccountId = null;
                      } else {
                        _selectedAccountId = d.id;
                      }
                    });
                  },
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0A1E3D) : Colors.white.withOpacity(0.015),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lens, color: d.color, size: 10),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d.label,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '$displayAmt (${d.percentage.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              color: isNegative ? const Color(0xFFFF3B30) : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryTrendCard(List<Transaction> txs, List<Category> cats, DateTimeRange range) {
    final expenseTxs = txs.where((tx) => FinancialCalculationService.isExpense(tx)).toList();
    final Map<String, String> catIdToNameMap = {};
    for (var tx in expenseTxs) {
      if (tx.categoryId != null) {
        final cat = cats.firstWhere((c) => c.id == tx.categoryId, orElse: () => Category(id: tx.categoryId!, userId: '', name: 'Others', type: 'expense', usageCount: 0, isSystemDefault: true, createdAt: DateTime.now()));
        catIdToNameMap[cat.id] = cat.name;
      }
    }

    if (catIdToNameMap.isEmpty) {
      return const GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('CATEGORY TREND', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            SizedBox(height: 24),
            Center(child: Text('No expense trend data available', style: TextStyle(color: Colors.white38, fontSize: 11))),
          ],
        ),
      );
    }

    if (_selectedTrendCategoryId == null || !catIdToNameMap.containsKey(_selectedTrendCategoryId)) {
      _selectedTrendCategoryId = catIdToNameMap.keys.first;
    }

    final activeCatId = _selectedTrendCategoryId!;
    final catTxs = expenseTxs.where((tx) => tx.categoryId == activeCatId).toList();
    double totalSpent = 0;
    for (var tx in catTxs) {
      totalSpent += tx.amount / 100.0;
    }

    final days = range.end.difference(range.start).inDays;
    final List<MapEntry<String, double>> points = [];

    if (days <= 1) {
      for (int hour = 0; hour < 24; hour += 2) {
        final label = '${hour.toString().padLeft(2, '0')}:00';
        double amt = 0;
        for (var tx in catTxs) {
          if (tx.date.hour >= hour && tx.date.hour < hour + 2) {
            amt += tx.amount / 100.0;
          }
        }
        points.add(MapEntry(label, amt));
      }
    } else if (days <= 31) {
      var current = DateTime(range.start.year, range.start.month, range.start.day);
      final targetEnd = DateTime(range.end.year, range.end.month, range.end.day);
      while (!current.isAfter(targetEnd)) {
        final label = DateFormat('dd').format(current);
        double amt = 0;
        for (var tx in catTxs) {
          if (tx.date.year == current.year && tx.date.month == current.month && tx.date.day == current.day) {
            amt += tx.amount / 100.0;
          }
        }
        points.add(MapEntry(label, amt));
        current = current.add(const Duration(days: 1));
      }
    } else {
      var current = DateTime(range.start.year, range.start.month, 1);
      final targetEnd = DateTime(range.end.year, range.end.month, 1);
      while (!current.isAfter(targetEnd)) {
        final label = DateFormat('MMM').format(current);
        double amt = 0;
        for (var tx in catTxs) {
          if (tx.date.year == current.year && tx.date.month == current.month) {
            amt += tx.amount / 100.0;
          }
        }
        points.add(MapEntry(label, amt));
        current = DateTime(current.year, current.month + 1, 1);
      }
    }

    Widget trendChartWidget;

    if (_trendChartType == 'Bar') {
      trendChartWidget = BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < points.length && (idx % max(1, points.length ~/ 5) == 0)) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(points[idx].key, style: const TextStyle(color: Colors.white38, fontSize: 8)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => const Color(0xFF0F1A1C),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final pt = points[groupIndex];
                return BarTooltipItem(
                  'Date: ${pt.key}\nAmount: ${_formatMoneyDouble(pt.value)}',
                  const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          barGroups: List.generate(points.length, (i) {
            final pt = points[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: pt.value,
                  color: const Color(0xFFFF3B30),
                  width: 6,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            );
          }),
        ),
      );
    } else {
      final isArea = _trendChartType == 'Area';
      final isSmooth = _trendChartType == 'Smooth Line';

      trendChartWidget = LineChart(
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
                  if (idx >= 0 && idx < points.length && (idx % max(1, points.length ~/ 5) == 0)) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(points[idx].key, style: const TextStyle(color: Colors.white38, fontSize: 8)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (group) => const Color(0xFF0F1A1C),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final pt = points[spot.x.toInt()];
                  return LineTooltipItem(
                    'Date: ${pt.key}\nAmount: ${_formatMoneyDouble(pt.value)}',
                    const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].value)),
              isCurved: isSmooth,
              color: const Color(0xFFFF3B30),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: isArea,
                color: const Color(0xFFFF3B30).withOpacity(0.08),
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CATEGORY TREND', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeCatId,
                        dropdownColor: const Color(0xFF0A1120),
                        style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                        items: catIdToNameMap.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedTrendCategoryId = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              _buildChartTypeSelector(
                currentType: _trendChartType,
                options: const ['Line', 'Smooth Line', 'Area', 'Bar'],
                onChanged: (val) => setState(() => _trendChartType = val),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total Spent: ${_formatMoneyDouble(totalSpent)}',
            style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey('${_trendChartType}_${activeCatId}_${points.length}'),
                child: trendChartWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSankeyFlowCard(List<Transaction> txs, List<Category> cats, List<Account> accounts, List<PaymentMethod> pms) {
    final Map<String, double> incomeToAccountFlow = {};
    final Map<String, double> accountToCategoryFlow = {};

    final Map<String, String> catIdToName = {for (var c in cats) c.id: c.name};
    final Map<String, Color> catIdToColor = {for (var c in cats) c.id: _getCategoryColor(c.name)};
    final Map<String, Color> incIdToColor = {for (var c in cats) c.id: _getIncomeSourceColor(c.name)};
    
    final Map<String, String> accIdToName = {for (var a in accounts) a.id: a.name};
    final Map<String, Color> accIdToColor = {};
    for (var acc in accounts) {
      Color getAccountColor(String type, String name) {
        final t = type.toLowerCase();
        final n = name.toLowerCase();
        if (t.contains('cash') || n.contains('cash')) return const Color(0xFF4CAF50);
        if (t.contains('wallet') || n.contains('wallet') || n.contains('pay')) return const Color(0xFF9C27B0);
        if (t.contains('credit') || n.contains('credit') || n.contains('card')) return const Color(0xFFFF9800);
        if (t.contains('loan') || n.contains('loan')) return const Color(0xFFF44336);
        return const Color(0xFF00BCD4);
      }
      accIdToColor[acc.id] = getAccountColor(acc.type, acc.name);
    }

    double totalFlowValue = 0;

    for (var tx in txs) {
      final double amt = tx.amount.abs() / 100.0;
      if (amt <= 0) continue;

      if (FinancialCalculationService.isIncome(tx)) {
        final srcId = tx.categoryId ?? 'unknown_income';
        final accId = tx.accountId ?? 'unknown_account';
        final flowKey = '$srcId->$accId';
        incomeToAccountFlow[flowKey] = (incomeToAccountFlow[flowKey] ?? 0) + amt;
        totalFlowValue += amt;
      } else if (FinancialCalculationService.isExpense(tx)) {
        final accId = tx.accountId ?? 'unknown_account';
        final destCatId = tx.categoryId ?? 'unknown_expense';
        final flowKey = '$accId->$destCatId';
        accountToCategoryFlow[flowKey] = (accountToCategoryFlow[flowKey] ?? 0) + amt;
        totalFlowValue += amt;
      }
    }

    if (totalFlowValue == 0) {
      return const GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('SANKEY FLOW DIAGRAM', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            SizedBox(height: 24),
            Center(child: Text('NO FLOW DATA FOR THIS PERIOD', style: TextStyle(color: Colors.white38, fontSize: 11))),
          ],
        ),
      );
    }

    final Map<String, SankeyNode> leftNodes = {};
    final Map<String, SankeyNode> centerNodes = {};
    final Map<String, SankeyNode> rightNodes = {};
    final List<SankeyLink> links = [];

    incomeToAccountFlow.forEach((key, val) {
      final parts = key.split('->');
      final srcId = parts[0];
      final accId = parts[1];
      final srcName = catIdToName[srcId] ?? 'Income Source';
      final accName = accIdToName[accId] ?? 'Account';
      final srcColor = incIdToColor[srcId] ?? const Color(0xFF4CAF50);

      leftNodes[srcId] = leftNodes[srcId] ?? SankeyNode(
        id: srcId,
        label: srcName,
        type: 'income_source',
        color: srcColor,
        totalValue: 0,
      );
      leftNodes[srcId] = SankeyNode(
        id: srcId,
        label: srcName,
        type: 'income_source',
        color: srcColor,
        totalValue: leftNodes[srcId]!.totalValue + val,
      );

      centerNodes[accId] = centerNodes[accId] ?? SankeyNode(
        id: accId,
        label: accName,
        type: 'account',
        color: accIdToColor[accId] ?? const Color(0xFF00BCD4),
        totalValue: 0,
      );
      centerNodes[accId] = SankeyNode(
        id: accId,
        label: accName,
        type: 'account',
        color: accIdToColor[accId] ?? const Color(0xFF00BCD4),
        totalValue: centerNodes[accId]!.totalValue + val,
      );

      links.add(SankeyLink(
        fromId: srcId,
        toId: accId,
        amount: val,
        color: srcColor.withOpacity(0.25),
      ));
    });

    accountToCategoryFlow.forEach((key, val) {
      final parts = key.split('->');
      final accId = parts[0];
      final catId = parts[1];
      final accName = accIdToName[accId] ?? 'Account';
      final catName = catIdToName[catId] ?? 'Category';
      final accColor = accIdToColor[accId] ?? const Color(0xFF00BCD4);
      final catColor = catIdToColor[catId] ?? const Color(0xFFFF9800);

      centerNodes[accId] = centerNodes[accId] ?? SankeyNode(
        id: accId,
        label: accName,
        type: 'account',
        color: accColor,
        totalValue: 0,
      );
      centerNodes[accId] = SankeyNode(
        id: accId,
        label: accName,
        type: 'account',
        color: accColor,
        totalValue: centerNodes[accId]!.totalValue + val,
      );

      rightNodes[catId] = rightNodes[catId] ?? SankeyNode(
        id: catId,
        label: catName,
        type: 'category',
        color: catColor,
        totalValue: 0,
      );
      rightNodes[catId] = SankeyNode(
        id: catId,
        label: catName,
        type: 'category',
        color: catColor,
        totalValue: rightNodes[catId]!.totalValue + val,
      );

      links.add(SankeyLink(
        fromId: accId,
        toId: catId,
        amount: val,
        color: accColor.withOpacity(0.25),
      ));
    });

    final sortedLeft = leftNodes.values.toList()..sort((a, b) => b.totalValue.compareTo(a.totalValue));
    final sortedCenter = centerNodes.values.toList()..sort((a, b) => b.totalValue.compareTo(a.totalValue));
    final sortedRight = rightNodes.values.toList()..sort((a, b) => b.totalValue.compareTo(a.totalValue));

    final displayLeft = sortedLeft.take(4).toList();
    final displayCenter = sortedCenter.take(4).toList();
    final displayRight = sortedRight.take(4).toList();

    final activeLeftIds = displayLeft.map((n) => n.id).toSet();
    final activeCenterIds = displayCenter.map((n) => n.id).toSet();
    final activeRightIds = displayRight.map((n) => n.id).toSet();

    final List<SankeyNode> nodesList = [...displayLeft, ...displayCenter, ...displayRight];
    final List<SankeyLink> activeLinks = links.where((link) {
      return (activeLeftIds.contains(link.fromId) && activeCenterIds.contains(link.toId)) ||
             (activeCenterIds.contains(link.fromId) && activeRightIds.contains(link.toId));
    }).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SANKEY FLOW DIAGRAM', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          GestureDetector(
            onTapDown: (details) {
              String? hitNodeId;
              for (var node in nodesList) {
                if (node.rect != null && node.rect!.contains(details.localPosition)) {
                  hitNodeId = node.id;
                  break;
                }
              }
              setState(() {
                if (hitNodeId != null) {
                  if (_selectedSankeyNodeId == hitNodeId) {
                    _selectedSankeyNodeId = null;
                  } else {
                    _selectedSankeyNodeId = hitNodeId;
                  }
                } else {
                  _selectedSankeyNodeId = null;
                }
              });
            },
            child: SizedBox(
              height: 200,
              child: CustomPaint(
                painter: SankeyPainter(
                  leftNodes: displayLeft,
                  centerNodes: displayCenter,
                  rightNodes: displayRight,
                  links: activeLinks,
                  selectedNodeId: _selectedSankeyNodeId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySpendingHeatmapCard(List<Transaction> txs, List<Category> cats, List<Account> accounts, DateTimeRange range) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('DAILY SPENDING (HEATMAP)', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildDailySpendingHeatmap(txs, cats, accounts, range),
        ],
      ),
    );
  }



  Widget _buildDailySpendingHeatmap(List<Transaction> txs, List<Category> cats, List<Account> accounts, DateTimeRange range) {
    final Map<String, List<Transaction>> txsByDate = {};
    for (var tx in txs) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      if (!txsByDate.containsKey(key)) {
        txsByDate[key] = [];
      }
      txsByDate[key]!.add(tx);
    }

    final weeks = _generateHeatmapWeeks(range);
    final categoriesMap = {for (var c in cats) c.id: c};
    final accountsMap = {for (var a in accounts) a.id: a};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((label) {
                    return Container(
                      height: 18,
                      width: 18,
                      margin: const EdgeInsets.all(2),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 8),
                ...weeks.map((week) {
                  return Column(
                    children: week.map((date) {
                      if (date == null) {
                        return Container(
                          height: 18,
                          width: 18,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.01),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }

                      final key = DateFormat('yyyy-MM-dd').format(date);
                      final dayTxs = txsByDate[key] ?? [];
                      double totalExp = 0;
                      for (var tx in dayTxs) {
                        if (FinancialCalculationService.isExpense(tx)) {
                          totalExp += tx.amount / 100.0;
                        }
                      }

                      Color color;
                      if (totalExp == 0) {
                        color = Colors.white.withOpacity(0.04);
                      } else if (totalExp <= 500) {
                        color = const Color(0xFF0066FF).withOpacity(0.25);
                      } else if (totalExp <= 2000) {
                        color = const Color(0xFF0066FF).withOpacity(0.55);
                      } else if (totalExp <= 5000) {
                        color = const Color(0xFF0066FF).withOpacity(0.85);
                      } else {
                        color = const Color(0xFF00E5FF);
                      }

                      final isSelected = _selectedHeatmapDate != null &&
                          _selectedHeatmapDate!.year == date.year &&
                          _selectedHeatmapDate!.month == date.month &&
                          _selectedHeatmapDate!.day == date.day;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedHeatmapDate = null;
                            } else {
                              _selectedHeatmapDate = date;
                            }
                          });
                        },
                        child: Container(
                          height: 18,
                          width: 18,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? Border.all(color: const Color(0xFF00E5FF), width: 1.5)
                                : Border.all(color: Colors.transparent),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
        // Heatmap Details list inside card
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                child: child,
              ),
            );
          },
          child: _selectedHeatmapDate == null
              ? const SizedBox.shrink()
              : KeyedSubtree(
                  key: ValueKey(DateFormat('yyyy-MM-dd').format(_selectedHeatmapDate!)),
                  child: _buildHeatmapDetailsList(txsByDate, categoriesMap, accountsMap),
                ),
        ),
      ],
    );
  }

  Widget _buildHeatmapDetailsList(
    Map<String, List<Transaction>> txsByDate,
    Map<String, Category> categoriesMap,
    Map<String, Account> accountsMap,
  ) {
    final key = DateFormat('yyyy-MM-dd').format(_selectedHeatmapDate!);
    final dayTxs = txsByDate[key] ?? [];
    double expense = 0;
    double income = 0;
    for (var tx in dayTxs) {
      if (FinancialCalculationService.isIncome(tx)) {
        income += tx.amount / 100.0;
      } else if (FinancialCalculationService.isExpense(tx)) {
        expense += tx.amount / 100.0;
      }
    }
    final double netFlow = income - expense;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMMM dd').format(_selectedHeatmapDate!),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                '${dayTxs.length} transactions',
                style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeatmapStatItem('OUT', _formatMoneyDouble(expense), const Color(0xFFFF3B30)),
              _buildHeatmapStatItem('IN', _formatMoneyDouble(income), const Color(0xFF00E5FF)),
              _buildHeatmapStatItem(
                'NET FLOW',
                _formatMoneyDouble(netFlow),
                netFlow >= 0 ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          if (dayTxs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Text('No transactions recorded for this day.', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayTxs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final tx = dayTxs[idx];
                final isInc = FinancialCalculationService.isIncome(tx);
                final amt = tx.amount / 100.0;
                final accName = accountsMap[tx.accountId]?.name ?? 'Unknown';

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.015),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.02)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.merchant ?? tx.description ?? 'General',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SMS Alert: $accName',
                              style: const TextStyle(color: Colors.white38, fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isInc ? '+' : '-'}₹${amt.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isInc ? const Color(0xFF0066FF) : const Color(0xFFFF3B30),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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

  Widget _buildHeatmapStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAIFinancialInsightsCard(AdvisorState state) {
    final score = state.healthScore.toDouble();
    final status = state.healthStatus;
    Color statusColor = const Color(0xFF4CAF50);
    if (score < 40) {
      statusColor = const Color(0xFFFF3B30);
    } else if (score < 75) {
      statusColor = const Color(0xFFFF9800);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('AI FINANCIAL ADVISOR', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 70,
                width: 70,
                child: CustomPaint(
                  painter: GaugePainter(score: score, color: statusColor),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${score.round()}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(status, style: TextStyle(color: statusColor, fontSize: 7, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Financial Health Score', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Analyzed by Expenso AI based on savings velocity, spending trends, and debt ratios.', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          if (state.spendingAlerts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('ALERTS', style: TextStyle(color: Color(0xFFFF3B30), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            ...state.spendingAlerts.take(2).map((alert) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30), size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(alert, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // --- MONTHLY COMPARISON GRAPH BUILDERS ---

  Widget _buildMonthlyComparisonCard(List<Transaction> txs, DateTimeRange range) {
    final points = _generateMonthlyCompPoints(txs, range);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MONTHLY', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  Text('COMPARISON', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  Text('(2026)', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              _buildChartTypeSelector(
                currentType: _monthlyChartType,
                options: ['Grouped Bar', 'Stacked Bar', 'Line', 'Area'],
                onChanged: (val) => setState(() => _monthlyChartType = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (points.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: Text('No Data Available', style: TextStyle(color: Colors.white38, fontSize: 12))),
            )
          else ...[
            SizedBox(
              height: 180,
              child: _monthlyChartType == 'Line' || _monthlyChartType == 'Area'
                  ? _buildMonthlyComparisonLineChart(points, _monthlyChartType == 'Area')
                  : _buildMonthlyComparisonBarChart(points, _monthlyChartType == 'Stacked Bar'),
            ),
            const SizedBox(height: 12),
            _buildLegend(
              [
                _LegendItem('In', const Color(0xFF0066FF)),
                _LegendItem('Out', const Color(0xFFFF3B30)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyComparisonLineChart(List<MonthlyCompPoint> points, bool isArea) {
    return LineChart(
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
                if (idx >= 0 && idx < 12) {
                  final label = (idx + 1).toString().padLeft(2, '0');
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 6,
                    child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF0F1A1C),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final point = points[spot.x.toInt()];
                String metric = '';
                if (spot.barIndex == 0) metric = 'Income';
                if (spot.barIndex == 1) metric = 'Expense';
                return LineTooltipItem(
                  '${point.label}\n$metric: ${_formatMoneyDouble(spot.y)}',
                  const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          _lineBarData(points.map((p) => p.income).toList(), const Color(0xFF0066FF), isArea, true),
          _lineBarData(points.map((p) => p.expense).toList(), const Color(0xFFFF3B30), isArea, true),
        ],
      ),
    );
  }

  Widget _buildMonthlyComparisonBarChart(List<MonthlyCompPoint> points, bool isStacked) {
    double maxVal = 0.0;
    for (var p in points) {
      if (p.income > maxVal) maxVal = p.income;
      if (p.expense > maxVal) maxVal = p.expense;
    }
    if (maxVal == 0) maxVal = 1000.0;
    final double computedMaxY = maxVal * 1.15;

    double interval = 1000.0;
    if (computedMaxY > 100000) {
      interval = 25000.0;
    } else if (computedMaxY > 50000) {
      interval = 10000.0;
    } else if (computedMaxY > 20000) {
      interval = 5000.0;
    } else if (computedMaxY > 10000) {
      interval = 2000.0;
    } else if (computedMaxY > 5000) {
      interval = 1000.0;
    } else if (computedMaxY > 1000) {
      interval = 250.0;
    } else {
      interval = 100.0;
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        maxY: computedMaxY,
        minY: 0,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const Text('₹0', style: TextStyle(color: Colors.white38, fontSize: 8));
                }
                if (value == meta.max) return const SizedBox.shrink();
                if (value >= 1000) {
                  final kVal = (value / 1000).toStringAsFixed(0);
                  return Text('₹${kVal}K', style: const TextStyle(color: Colors.white38, fontSize: 8));
                }
                return Text('₹${value.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white38, fontSize: 8));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < 12) {
                  final label = (idx + 1).toString().padLeft(2, '0');
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 6,
                    child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchCallback: (event, response) {
            setState(() {
              if (!event.isInterestedForInteractions || response == null || response.spot == null) {
                _touchedMonthlyGroupIndex = -1;
                _touchedMonthlyRodIndex = -1;
                return;
              }
              _touchedMonthlyGroupIndex = response.spot!.touchedBarGroupIndex;
              _touchedMonthlyRodIndex = response.spot!.touchedRodDataIndex;
            });
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF0F1A1C),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = points[groupIndex];
              final monthNum = (groupIndex + 1).toString().padLeft(2, '0');
              return BarTooltipItem(
                'Month: $monthNum\nIncome: ${_formatMoneyDouble(point.income)}\nExpense: ${_formatMoneyDouble(point.expense)}',
                const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        barGroups: List.generate(points.length, (i) {
          final p = points[i];
          if (isStacked) {
            final isGroupTouched = i == _touchedMonthlyGroupIndex;
            final isRodTouched0 = isGroupTouched && _touchedMonthlyRodIndex == 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: p.income,
                  width: 12,
                  color: isRodTouched0 ? const Color(0xFF00E5FF) : const Color(0xFF0066FF),
                  rodStackItems: [
                    BarChartRodStackItem(0, p.expense, const Color(0xFFFF3B30)),
                    BarChartRodStackItem(p.expense, p.income, const Color(0xFF0066FF)),
                  ],
                ),
              ],
            );
          } else {
            final isGroupTouched = i == _touchedMonthlyGroupIndex;
            final incomeColor = isGroupTouched && _touchedMonthlyRodIndex == 0
                ? const Color(0xFF00E5FF)
                : (isGroupTouched ? const Color(0xFF0066FF).withOpacity(0.5) : const Color(0xFF0066FF));
            final expenseColor = isGroupTouched && _touchedMonthlyRodIndex == 1
                ? const Color(0xFF00E5FF)
                : (isGroupTouched ? const Color(0xFFFF3B30).withOpacity(0.5) : const Color(0xFFFF3B30));

            return BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: p.income,
                  color: incomeColor,
                  width: 6,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
                BarChartRodData(
                  toY: p.expense,
                  color: expenseColor,
                  width: 6,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  // --- HELPER GRAPH METHODS ---

  Widget _buildChartTypeSelector({
    required String currentType,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentType,
          dropdownColor: const Color(0xFF0A1120),
          style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 9, fontWeight: FontWeight.bold),
          items: options.map((opt) {
            return DropdownMenuItem(value: opt, child: Text(opt));
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildLegend(List<_LegendItem> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Icon(Icons.lens, color: item.color, size: 8),
              const SizedBox(width: 4),
              Text(item.name, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }


  List<List<DateTime?>> _generateHeatmapWeeks(DateTimeRange range) {
    final List<List<DateTime?>> weeks = [];
    final start = DateTime(range.start.year, range.start.month, range.start.day);

    // Shift to start on Monday
    final startOffset = start.weekday - 1;
    final firstMon = start.subtract(Duration(days: startOffset));

    DateTime current = firstMon;
    final targetEnd = DateTime(range.end.year, range.end.month, range.end.day);

    List<DateTime?> currentWeek = List.filled(7, null);
    while (!current.isAfter(targetEnd)) {
      final weekdayIndex = current.weekday - 1;
      if (current.isAfter(start.subtract(const Duration(seconds: 1)))) {
        currentWeek[weekdayIndex] = current;
      }

      if (current.weekday == 7 || current.isAtSameMomentAs(targetEnd)) {
        weeks.add(currentWeek);
        currentWeek = List.filled(7, null);
      }
      current = current.add(const Duration(days: 1));
    }
    if (currentWeek.any((d) => d != null)) {
      weeks.add(currentWeek);
    }
    return weeks;
  }

  LineChartBarData _lineBarData(List<double> values, Color color, bool isArea, bool isSpline) {
    return LineChartBarData(
      spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
      isCurved: isSpline,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: isArea,
        color: color.withOpacity(0.08),
      ),
    );
  }

  List<MonthlyCompPoint> _generateMonthlyCompPoints(List<Transaction> txs, DateTimeRange range) {
    final year = range.start.year;
    final List<MonthlyCompPoint> points = [];
    final labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (int month = 1; month <= 12; month++) {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));

      double inc = 0;
      double exp = 0;
      for (var tx in txs) {
        if (tx.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
            tx.date.isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
          if (FinancialCalculationService.isIncome(tx)) {
            inc += tx.amount / 100.0;
          } else if (FinancialCalculationService.isExpense(tx)) {
            exp += tx.amount / 100.0;
          }
        }
      }
      points.add(MonthlyCompPoint(
        label: labels[month - 1],
        income: inc,
        expense: exp,
        savings: inc - exp,
        netCashFlow: inc - exp,
      ));
    }
    return points;
  }
}

// --- CORE STRUCTS ---

class CashFlowPoint {
  final String label;
  final double income;
  final double expense;
  final double savings;
  final double netCashFlow;

  CashFlowPoint({
    required this.label,
    required this.income,
    required this.expense,
    required this.savings,
    required this.netCashFlow,
  });
}

class MonthlyCompPoint {
  final String label;
  final double income;
  final double expense;
  final double savings;
  final double netCashFlow;

  MonthlyCompPoint({
    required this.label,
    required this.income,
    required this.expense,
    required this.savings,
    required this.netCashFlow,
  });
}

class _LegendItem {
  final String name;
  final Color color;
  _LegendItem(this.name, this.color);
}

class GaugePainter extends CustomPainter {
  final double score;
  final Color color;

  GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    final paintBg = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final paintFg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      pi,
      pi,
      false,
      paintBg,
    );

    final sweepAngle = (score / 100.0) * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      pi,
      sweepAngle,
      false,
      paintFg,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- SANKEY CHART MODELS & PAINTER ---

class SankeyNode {
  final String id;
  final String label;
  final String type;
  final Color color;
  final double totalValue;
  Rect? rect;

  SankeyNode({
    required this.id,
    required this.label,
    required this.type,
    required this.color,
    required this.totalValue,
  });
}

class SankeyLink {
  final String fromId;
  final String toId;
  final double amount;
  final Color color;

  SankeyLink({
    required this.fromId,
    required this.toId,
    required this.amount,
    required this.color,
  });
}

class SankeyPainter extends CustomPainter {
  final List<SankeyNode> leftNodes;
  final List<SankeyNode> centerNodes;
  final List<SankeyNode> rightNodes;
  final List<SankeyLink> links;
  final String? selectedNodeId;

  SankeyPainter({
    required this.leftNodes,
    required this.centerNodes,
    required this.rightNodes,
    required this.links,
    required this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double colLeftX = 0.18 * size.width;
    final double colCenterX = 0.5 * size.width;
    final double colRightX = 0.82 * size.width;

    final double nodeWidth = 8.0;
    final double nodeHeight = 32.0;

    final Map<String, Offset> nodePositions = {};

    if (leftNodes.isNotEmpty) {
      final double spacing = size.height / (leftNodes.length + 1);
      for (int i = 0; i < leftNodes.length; i++) {
        final node = leftNodes[i];
        final double y = (i + 1) * spacing;
        final rect = Rect.fromLTWH(colLeftX - nodeWidth / 2, y - nodeHeight / 2, nodeWidth, nodeHeight);
        node.rect = rect;
        nodePositions[node.id] = Offset(colLeftX, y);

        final isSelected = selectedNodeId == null || selectedNodeId == node.id;
        final paintColor = isSelected ? node.color : node.color.withOpacity(0.3);
        final paint = Paint()
          ..color = paintColor
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);

        final labelText = node.label.length > 5 ? '${node.label.substring(0, 5)}.' : node.label;
        final textPainter = TextPainter(
          text: TextSpan(
            text: labelText,
            style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 8, fontWeight: FontWeight.bold),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(rect.left - textPainter.width - 6, y - textPainter.height / 2));
      }
    }

    if (centerNodes.isNotEmpty) {
      final double spacing = size.height / (centerNodes.length + 1);
      for (int i = 0; i < centerNodes.length; i++) {
        final node = centerNodes[i];
        final double y = (i + 1) * spacing;
        final rect = Rect.fromLTWH(colCenterX - nodeWidth / 2, y - nodeHeight / 2, nodeWidth, nodeHeight);
        node.rect = rect;
        nodePositions[node.id] = Offset(colCenterX, y);

        bool isSelected = selectedNodeId == null || selectedNodeId == node.id;
        if (selectedNodeId != null && selectedNodeId != node.id) {
          final hasIncoming = links.any((l) => l.fromId == selectedNodeId && l.toId == node.id);
          final hasOutgoing = links.any((l) => l.fromId == node.id && l.toId == selectedNodeId);
          isSelected = hasIncoming || hasOutgoing;
        }

        final paintColor = isSelected ? node.color : node.color.withOpacity(0.3);
        final paint = Paint()
          ..color = paintColor
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);

        final labelText = node.label.length > 5 ? '${node.label.substring(0, 5)}.' : node.label;
        final textPainter = TextPainter(
          text: TextSpan(
            text: labelText,
            style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 8, fontWeight: FontWeight.bold),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(rect.right + 6, y - textPainter.height / 2));
      }
    }

    if (rightNodes.isNotEmpty) {
      final double spacing = size.height / (rightNodes.length + 1);
      for (int i = 0; i < rightNodes.length; i++) {
        final node = rightNodes[i];
        final double y = (i + 1) * spacing;
        final rect = Rect.fromLTWH(colRightX - nodeWidth / 2, y - nodeHeight / 2, nodeWidth, nodeHeight);
        node.rect = rect;
        nodePositions[node.id] = Offset(colRightX, y);

        bool isSelected = selectedNodeId == null || selectedNodeId == node.id;
        if (selectedNodeId != null && selectedNodeId != node.id) {
          final hasLink = links.any((l) => l.fromId == selectedNodeId && l.toId == node.id) ||
                         links.any((l) {
                           if (l.toId == node.id) {
                             return links.any((l2) => l2.fromId == selectedNodeId && l2.toId == l.fromId);
                           }
                           return false;
                         });
          isSelected = hasLink;
        }

        final paintColor = isSelected ? node.color : node.color.withOpacity(0.3);
        final paint = Paint()
          ..color = paintColor
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);

        final labelText = node.label.length > 5 ? '${node.label.substring(0, 5)}.' : node.label;
        final textPainter = TextPainter(
          text: TextSpan(
            text: labelText,
            style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 8, fontWeight: FontWeight.bold),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(rect.left - textPainter.width - 6, y - textPainter.height / 2));
      }
    }

    double maxLinkValue = 1.0;
    for (var l in links) {
      if (l.amount > maxLinkValue) maxLinkValue = l.amount;
    }

    for (var link in links) {
      final pFrom = nodePositions[link.fromId];
      final pTo = nodePositions[link.toId];
      if (pFrom == null || pTo == null) continue;

      bool isHighlighted = selectedNodeId == null ||
          selectedNodeId == link.fromId ||
          selectedNodeId == link.toId ||
          links.any((l) => l.fromId == selectedNodeId && l.toId == link.fromId && link.toId == l.toId);

      if (selectedNodeId != null && !isHighlighted) {
        final leftToCenter = links.any((l) => l.fromId == selectedNodeId && l.toId == link.fromId);
        if (leftToCenter) {
          isHighlighted = true;
        }
      }

      final double thickness = (link.amount / maxLinkValue * 8.0).clamp(1.5, 8.0);
      final double dx = pTo.dx - pFrom.dx;

      final path = Path()
        ..moveTo(pFrom.dx + nodeWidth / 2, pFrom.dy)
        ..cubicTo(
          pFrom.dx + nodeWidth / 2 + dx / 2, pFrom.dy,
          pTo.dx - nodeWidth / 2 - dx / 2, pTo.dy,
          pTo.dx - nodeWidth / 2, pTo.dy,
        );

      final paint = Paint()
        ..color = isHighlighted ? link.color : link.color.withOpacity(0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SankeyPainter oldDelegate) {
    return oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.leftNodes.length != leftNodes.length ||
        oldDelegate.centerNodes.length != centerNodes.length ||
        oldDelegate.rightNodes.length != rightNodes.length ||
        oldDelegate.links.length != links.length;
  }
}
