import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/privacy_text.dart';
import '../../../../shared/widgets/reusable_net_worth_ring.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/account_formatters.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../providers/privacy_provider.dart';
import '../screens/dashboard_summary_screen.dart';

class NetWorthDetailScreen extends ConsumerWidget {
  const NetWorthDetailScreen({super.key});

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountSummaryAsync = ref.watch(accountSummaryProvider);
    final accountsAsync = ref.watch(recalculatedAccountsProvider);
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

              Expanded(
                child: accountSummaryAsync.when(
                  data: (summary) {
                    return transactionsAsync.when(
                      data: (txs) {
                        return categoriesAsync.when(
                          data: (categories) {
                            final selectedMonth = ref.watch(dashboardMonthProvider);
                            final financialData = ref.watch(dashboardFinancialDataProvider);

                            final allAccounts = accountsAsync.maybeWhen(
                              data: (list) => list.where((a) => a.isActive == true).toList(),
                              orElse: () => <Account>[],
                            );

                            final assetAccounts = allAccounts
                                .where((a) => a.type != 'credit_card' && a.type != 'loan' && a.type != 'loan_account')
                                .toList()
                              ..sort((a, b) => b.balance.compareTo(a.balance));

                            final liabilityAccounts = allAccounts
                                .where((a) => a.type == 'credit_card' || a.type == 'loan' || a.type == 'loan_account')
                                .toList()
                              ..sort((a, b) {
                                final balA = a.type == 'credit_card' ? (a.outstandingBalance ?? 0) : (a.balance < 0 ? -a.balance : a.balance);
                                final balB = b.type == 'credit_card' ? (b.outstandingBalance ?? 0) : (b.balance < 0 ? -b.balance : b.balance);
                                return balB.compareTo(balA);
                              });

                            // Month boundaries
                            final startOfSelectedMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
                            final endOfSelectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1).subtract(const Duration(milliseconds: 1));

                            // Calculate Top Categories for Selected Month
                            final categoryExpenses = <String, int>{};
                            for (var tx in txs) {
                              if (tx.date.isAfter(startOfSelectedMonth.subtract(const Duration(seconds: 1))) && 
                                  tx.date.isBefore(endOfSelectedMonth) &&
                                  FinancialCalculationService.isExpense(tx) && 
                                  tx.categoryId != null) {
                                categoryExpenses[tx.categoryId!] = (categoryExpenses[tx.categoryId!] ?? 0) + tx.amount.toInt();
                              }
                            }

                            final categoriesMap = {for (var c in categories) c.id: c};
                            final sortedCategorySpends = categoryExpenses.entries.map((entry) {
                              final cat = categoriesMap[entry.key];
                              return _CategorySpend(
                                name: cat?.name ?? 'Other',
                                amount: entry.value,
                                color: _getCategoryColor(cat?.icon),
                              );
                            }).toList()
                              ..sort((a, b) => b.amount.compareTo(a.amount));

                            // Map accounts by ID to look up names
                            final accountsMap = {for (var a in allAccounts) a.id: a};

                            // Filter recent 5 transactions affecting Net Worth (Income, Expense, Transfers, CC Payments, not deleted)
                            final recentTxs = txs.where((tx) {
                              if (tx.deletedAt != null) return false;
                              final type = tx.type.toLowerCase();
                              return FinancialCalculationService.isIncome(tx) ||
                                     FinancialCalculationService.isExpense(tx) ||
                                     type.contains('transfer') ||
                                     type.contains('credit_card_payment');
                            }).toList()
                              ..sort((a, b) => b.date.compareTo(a.date));
                            final topRecent = recentTxs.take(5).toList();

                            // Calculated fields synchronized with Dashboard
                            final currentMonthExpense = financialData.monthlyExpenses;
                            final lastUpdated = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

                            final double totalForBreakdown = (summary.totalAssets + summary.totalLiabilities).toDouble();
                            final double assetsPct = totalForBreakdown > 0 ? (summary.totalAssets / totalForBreakdown * 100) : 0.0;
                            final double liabilitiesPct = totalForBreakdown > 0 ? (summary.totalLiabilities / totalForBreakdown * 100) : 0.0;
                            final double assetFraction = totalForBreakdown > 0 ? (summary.totalAssets / totalForBreakdown) : -1.0;

                            return ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                // 1. Large Net Worth Summary Card with integrated donut ring
                                _buildNetWorthHero(
                                  netWorth: summary.netAssets,
                                  assets: summary.totalAssets,
                                  liabilities: summary.totalLiabilities,
                                  assetsPct: assetsPct,
                                  liabilitiesPct: liabilitiesPct,
                                  assetFraction: assetFraction,
                                  isPrivate: isPrivate,
                                  selectedMonth: selectedMonth,
                                ),
                                const SizedBox(height: 20),

                                // 2. Account Balances Section (Assets & Liabilities grouped)
                                _buildAccountsSection(context, assetAccounts, liabilityAccounts),
                                const SizedBox(height: 20),

                                // 3. Top Spending Categories Section
                                if (sortedCategorySpends.isNotEmpty) ...[
                                  _buildTopCategoriesSection(sortedCategorySpends, currentMonthExpense),
                                  const SizedBox(height: 20),
                                ],

                                // 4. Recent Transactions Section
                                _buildRecentTransactionsSection(topRecent, accountsMap),

                                const SizedBox(height: 40),
                                Center(
                                  child: Text(
                                    'Last updated: $lastUpdated',
                                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                                  ),
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
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                  error: (err, _) => Center(child: Text('Error loading account summary: $err', style: const TextStyle(color: Colors.red))),
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
            'Net Worth Details',
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

  Widget _buildNetWorthHero({
    required int netWorth,
    required int assets,
    required int liabilities,
    required double assetsPct,
    required double liabilitiesPct,
    required double assetFraction,
    required bool isPrivate,
    required DateTime selectedMonth,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT\nNET WORTH',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: PrivacyText(
                        rawValue: _formatMoney(netWorth),
                        isNetWorth: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Asset vs Liability Donut Chart + Percentages
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (assetFraction >= 0) ...[
                    ReusableNetWorthRing(
                      key: ValueKey('net_worth_ring_details_${selectedMonth.toIso8601String()}'),
                      valueFraction: assetFraction,
                      size: 54,
                      trackColor: const Color(0xFFFF3B30),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          isPrivate ? '**%' : '${assetsPct.toStringAsFixed(1)}%',
                          key: ValueKey('assets_$isPrivate'),
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text('Asset Share', style: TextStyle(color: Colors.white30, fontSize: 8.5)),
                      const SizedBox(height: 3),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          isPrivate ? '**%' : '${liabilitiesPct.toStringAsFixed(1)}%',
                          key: ValueKey('liab_$isPrivate'),
                          style: const TextStyle(
                            color: Color(0xFFFF3B30),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text('Liability Share', style: TextStyle(color: Colors.white30, fontSize: 8.5)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0066FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('TOTAL ASSETS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    PrivacyText(
                      rawValue: _formatMoney(assets),
                      isAccountBalance: true,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white10),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('TOTAL LIABILITIES', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    PrivacyText(
                      rawValue: _formatMoney(liabilities),
                      isAccountBalance: true,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsSection(BuildContext context, List<Account> assets, List<Account> liabilities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ACCOUNT-WISE BALANCES',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        if (assets.isNotEmpty) ...[
          const Text(
            'ASSETS',
            style: TextStyle(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          ...assets.map((acc) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildAccountCard(acc, false),
          )),
        ],
        if (liabilities.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'LIABILITIES',
            style: TextStyle(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          ...liabilities.map((acc) {
            final card = _buildAccountCard(acc, true);
            if (acc.type == 'credit_card') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/credit-card-detail'),
                  child: card,
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: card,
            );
          }),
        ],
      ],
    );
  }

  Widget _buildAccountCard(Account acc, bool isLiability) {
    final color = _getAccountColor(acc.colorTheme);
    final balance = isLiability
        ? (acc.type == 'credit_card' ? (acc.outstandingBalance ?? 0) : (acc.balance < 0 ? -acc.balance : acc.balance))
        : acc.balance;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getAccountIcon(acc.icon),
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        acc.displayTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  acc.displaySubtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Text(
                  isLiability ? 'Outstanding Balance' : 'Available Balance',
                  style: const TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                PrivacyText(
                  rawValue: _formatMoney(balance),
                  isAccountBalance: true,
                  style: TextStyle(
                    color: isLiability
                        ? (balance > 0 ? const Color(0xFFFF3B30) : Colors.white)
                        : (balance >= 0 ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30)),
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesSection(List<_CategorySpend> categories, int totalExpenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'TOP SPENDING CATEGORIES',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: categories.take(4).map((cat) {
              final double percentage = totalExpenses == 0 ? 0.0 : (cat.amount / totalExpenses) * 100;
              final double ratio = totalExpenses == 0 ? 0.0 : cat.amount / totalExpenses;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        PrivacyText(
                          rawValue: '${_formatMoney(cat.amount)} (${percentage.toStringAsFixed(1)}%)',
                          isAnalyticsAmount: true,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: Colors.white.withOpacity(0.02),
                        color: cat.color,
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection(List<Transaction> transactions, Map<String, Account> accountsMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'RECENT NET WORTH TRANSACTIONS',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text('No transactions recorded.', style: TextStyle(color: Colors.white24, fontSize: 12)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isCredit = FinancialCalculationService.isIncome(tx);
              final color = isCredit ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30);
              final sign = isCredit ? '+' : '-';
              
              final accountName = accountsMap[tx.accountId]?.name ?? 'Unknown';
              final typeLower = tx.type.toLowerCase();
              String displayType = 'Transaction';
              if (FinancialCalculationService.isIncome(tx)) {
                displayType = 'Income';
              } else if (FinancialCalculationService.isExpense(tx)) {
                displayType = 'Expense';
              } else if (typeLower.contains('transfer') || typeLower.contains('credit_card_payment')) {
                displayType = 'Transfer/Payment';
              }

              return Container(
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
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: color,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.merchant ?? tx.description ?? 'General',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${accountName} • ${displayType}',
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy').format(tx.date),
                            style: const TextStyle(color: Colors.white24, fontSize: 8.5),
                          ),
                        ],
                      ),
                    ),
                    PrivacyText(
                      rawValue: '$sign${_formatMoney(tx.amount.toInt().abs())}',
                      isTransactionAmount: true,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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

  Color _getAccountColor(String? colorStr) {
    if (colorStr != null && colorStr.isNotEmpty) {
      try {
        return Color(int.parse(colorStr));
      } catch (_) {}
    }
    return const Color(0xFF0066FF);
  }

  IconData _getAccountIcon(String? iconName) {
    if (iconName != null && iconName.isNotEmpty) {
      switch (iconName.toLowerCase()) {
        case 'cash':
        case 'account_balance_wallet':
          return Icons.account_balance_wallet_outlined;
        case 'savings':
        case 'bank':
        case 'account_balance':
          return Icons.account_balance_outlined;
        case 'current':
        case 'building':
        case 'business':
          return Icons.business_outlined;
        case 'wallet':
          return Icons.wallet_outlined;
        case 'credit_card':
          return Icons.credit_card_outlined;
      }
    }
    return Icons.account_balance_outlined;
  }

  Color _getCategoryColor(String? icon) {
    if (icon != null && icon.isNotEmpty) {
      // Map basic icon terms to custom colors
      if (icon.contains('fastfood') || icon.contains('dining') || icon.contains('food')) return Colors.orange;
      if (icon.contains('shopping') || icon.contains('cart')) return Colors.purple;
      if (icon.contains('commute') || icon.contains('car') || icon.contains('cab')) return Colors.blue;
      if (icon.contains('movie') || icon.contains('tv') || icon.contains('game')) return Colors.pink;
      if (icon.contains('home') || icon.contains('rent')) return Colors.green;
      if (icon.contains('health') || icon.contains('med')) return Colors.red;
    }
    return const Color(0xFF0066FF);
  }
}

class _CategorySpend {
  final String name;
  final int amount;
  final Color color;

  _CategorySpend({required this.name, required this.amount, required this.color});
}


