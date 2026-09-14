import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/privacy_text.dart';
import '../../../../shared/utils/analytics_formatter.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../dashboard/presentation/providers/privacy_provider.dart';

class MerchantTransactionsDetailScreen extends ConsumerWidget {
  final String merchantName;
  final String? initialPeriod;
  final DateTimeRange? initialCustomRange;

  const MerchantTransactionsDetailScreen({
    super.key,
    required this.merchantName,
    this.initialPeriod,
    this.initialCustomRange,
  });

  DateTimeRange _getRangeForFilter(String filter, DateTimeRange? customRange) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (filter) {
      case 'Today':
        return DateTimeRange(start: todayStart, end: todayEnd);
      case 'Week':
      case 'this_week':
        final startOfWeek = todayStart.subtract(Duration(days: todayStart.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: startOfWeek, end: endOfWeek);
      case 'Month':
      case 'this_month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
      case 'Last Month':
      case 'last_month':
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final lastYear = now.month == 1 ? now.year - 1 : now.year;
        final startOfLastMonth = DateTime(lastYear, lastMonth, 1);
        final endOfLastMonth = DateTime(lastYear, lastMonth + 1, 1).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: startOfLastMonth, end: endOfLastMonth);
      case '3M':
      case 'last_3_months':
        final start = todayStart.subtract(const Duration(days: 90));
        return DateTimeRange(start: start, end: todayEnd);
      case '6M':
      case 'last_6_months':
        final start = todayStart.subtract(const Duration(days: 180));
        return DateTimeRange(start: start, end: todayEnd);
      case 'Year':
      case '1Y':
      case 'this_year':
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        return DateTimeRange(start: startOfYear, end: endOfYear);
      case 'Custom':
      case 'custom':
        if (customRange != null) return customRange;
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: todayEnd);
      default:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: todayEnd);
    }
  }

  String _getPeriodSubtitle(String filter) {
    switch (filter) {
      case 'Today':
        return 'Today';
      case 'Week':
        return 'This Week';
      case 'Month':
        return 'This Month';
      case 'Last Month':
        return 'Last Month';
      case '3M':
        return 'Last 3 Months';
      case '6M':
        return 'Last 6 Months';
      case 'Year':
      case '1Y':
        return 'This Year';
      case 'Custom':
        return 'Custom Date Range';
      default:
        return 'Selected Period';
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);

    if (check == today) {
      return 'TODAY';
    } else if (check == yesterday) {
      return 'YESTERDAY';
    } else {
      return DateFormat('EEEE, MMMM dd, yyyy').format(date).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodStr = initialPeriod ?? 'Month';
    final activeRange = _getRangeForFilter(periodStr, initialCustomRange);

    final txsAsync = ref.watch(expenseListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final accountsAsync = ref.watch(recalculatedAccountsProvider);
    final isPrivate = ref.watch(privacyModeProvider);

    final cats = categoriesAsync.maybeWhen(data: (c) => c, orElse: () => <Category>[]);
    final pms = paymentMethodsAsync.maybeWhen(data: (p) => p, orElse: () => <PaymentMethod>[]);
    final accs = accountsAsync.maybeWhen(data: (a) => a, orElse: () => <Account>[]);

    final categoriesMap = {for (var c in cats) c.id: c};
    final pmsMap = {for (var p in pms) p.id: p.name};
    final accsMap = {for (var a in accs) a.id: a.name};

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
          child: Column(
            children: [
              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/analytics');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchantName,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getPeriodSubtitle(periodStr),
                            style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Content Body
              Expanded(
                child: txsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                  data: (allTxs) {
                    // Filter matching merchant & period transactions
                    final merchantTxs = allTxs.where((tx) {
                      final inRange = tx.date.isAfter(activeRange.start.subtract(const Duration(seconds: 1))) &&
                          tx.date.isBefore(activeRange.end.add(const Duration(seconds: 1)));
                      if (!inRange || !FinancialCalculationService.isExpense(tx)) return false;

                      final m = tx.merchant ?? tx.description ?? 'General';
                      return m == merchantName;
                    }).toList();

                    merchantTxs.sort((a, b) => b.date.compareTo(a.date));

                    double totalSpent = 0;
                    for (var tx in merchantTxs) {
                      totalSpent += tx.amount / 100.0;
                    }

                    if (merchantTxs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white24),
                              const SizedBox(height: 16),
                              const Text(
                                'No Transactions Found',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No transactions recorded for $merchantName in the selected period.',
                                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Group by date
                    final Map<DateTime, List<Transaction>> grouped = {};
                    for (var tx in merchantTxs) {
                      final dayKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
                      grouped.putIfAbsent(dayKey, () => []).add(tx);
                    }

                    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                    return ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        // Merchant Summary Header Card
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TOTAL MERCHANT SPEND',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  PrivacyText(
                                    rawValue: AnalyticsFormatter.formatCurrency(totalSpent),
                                    style: const TextStyle(
                                      color: Color(0xFFFF3B30),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Text(
                                  '${merchantTxs.length} ${merchantTxs.length == 1 ? "Tx" : "Txs"}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Date Grouped Transactions
                        for (var date in sortedDates) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 4.0),
                            child: Text(
                              _formatDateHeader(date),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          ...grouped[date]!.map((tx) {
                            final cat = categoriesMap[tx.categoryId];
                            final pmName = pmsMap[tx.paymentMethodId];
                            final accName = accsMap[tx.accountId];

                            final iconData = IconMapper.getIcon(cat?.icon ?? 'shopping_bag');
                            final timeStr = DateFormat('hh:mm a').format(tx.date);

                            final List<String> details = [timeStr];
                            if (pmName != null && pmName.isNotEmpty) details.add('via $pmName');
                            if (accName != null && accName.isNotEmpty) details.add(accName);
                            final subtitleStr = details.join(' • ');

                            final String titleStr = tx.merchant ?? tx.description ?? cat?.name ?? 'Expense';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: GlassCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF3B30).withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(iconData, color: const Color(0xFFFF3B30), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            titleStr,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            subtitleStr,
                                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PrivacyText(
                                      rawValue: '-${AnalyticsFormatter.formatCurrency(tx.amount / 100.0)}',
                                      style: const TextStyle(
                                        color: Color(0xFFFF3B30),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
