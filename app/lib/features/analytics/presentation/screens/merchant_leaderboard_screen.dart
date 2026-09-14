import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/utils/analytics_formatter.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';

class MerchantLeaderboardScreen extends ConsumerWidget {
  final String? initialPeriod;
  final DateTimeRange? initialCustomRange;

  const MerchantLeaderboardScreen({
    super.key,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodStr = initialPeriod ?? 'Month';
    final activeRange = _getRangeForFilter(periodStr, initialCustomRange);
    final txsAsync = ref.watch(expenseListNotifierProvider);

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
              // Top Bar
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
                          const Text(
                            'Merchant Leaderboard',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                    final periodTxs = allTxs.where((tx) {
                      final inRange = tx.date.isAfter(activeRange.start.subtract(const Duration(seconds: 1))) &&
                          tx.date.isBefore(activeRange.end.add(const Duration(seconds: 1)));
                      return inRange && FinancialCalculationService.isExpense(tx);
                    }).toList();

                    final Map<String, double> merchantSpend = {};
                    for (var tx in periodTxs) {
                      final m = tx.merchant ?? tx.description ?? 'General';
                      merchantSpend[m] = (merchantSpend[m] ?? 0) + tx.amount / 100.0;
                    }

                    final sortedMerchants = merchantSpend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                    final double maxVal = sortedMerchants.isNotEmpty ? sortedMerchants.first.value : 1.0;

                    if (sortedMerchants.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.storefront_outlined, size: 64, color: Colors.white24),
                              const SizedBox(height: 16),
                              const Text(
                                'No Merchant Spending Found',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'There are no expense transactions recorded for the selected period.',
                                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: sortedMerchants.length,
                      itemBuilder: (context, index) {
                        final entry = sortedMerchants[index];
                        final merchantName = entry.key;
                        final amount = entry.value;
                        final pct = maxVal > 0 ? (amount / maxVal) : 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: () {
                              final encodedMerchant = Uri.encodeComponent(merchantName);
                              if (periodStr == 'Custom' && initialCustomRange != null) {
                                final start = initialCustomRange!.start.toIso8601String();
                                final end = initialCustomRange!.end.toIso8601String();
                                context.push('/merchant-transactions?merchant=$encodedMerchant&period=Custom&start=$start&end=$end');
                              } else {
                                context.push('/merchant-transactions?merchant=$encodedMerchant&period=$periodStr');
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: index < 3 ? const Color(0xFF0066FF).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${index + 1}',
                                                  style: TextStyle(
                                                    color: index < 3 ? const Color(0xFF00E5FF) : Colors.white54,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                merchantName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            AnalyticsFormatter.formatCurrency(amount),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.chevron_right, color: Colors.white38, size: 16),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Stack(
                                    children: [
                                      Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.04),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Container(
                                            height: 6,
                                            width: max(0.0, constraints.maxWidth * pct),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF0066FF), Color(0xFF00E5FF)],
                                              ),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          );
                                        },
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
