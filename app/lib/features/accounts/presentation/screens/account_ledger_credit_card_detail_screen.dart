import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../providers/accounts_provider.dart';
import '../providers/account_formatters.dart';
import 'account_form_sheet.dart';

class AccountLedgerCreditCardDetailScreen extends ConsumerStatefulWidget {
  final String accountId;

  const AccountLedgerCreditCardDetailScreen({super.key, required this.accountId});

  @override
  ConsumerState<AccountLedgerCreditCardDetailScreen> createState() => _AccountLedgerCreditCardDetailScreenState();
}

class _AccountLedgerCreditCardDetailScreenState extends ConsumerState<AccountLedgerCreditCardDetailScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _dateFilter = 'This Month'; // Today, This Week, This Month, Last Month, Last 3 Months, Last 6 Months, This Year, Custom
  DateTimeRange? _customDateRange;
  int _activeTab = 0; // 0 = Ledger, 1 = SMS Log, 2 = Settings

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }

  String _formatOutstanding(int amountInCents) {
    final text = _formatMoney(amountInCents);
    final clean = text.replaceAll('-', '').replaceAll('–', '').replaceAll('—', '').replaceAll('−', '').trim();
    if (clean.isEmpty || clean == '₹0.00' || clean == '0' || clean == '0.00') {
      return '₹0.00';
    }
    return '-$clean';
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
      case 'Last Month':
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
        final startOfLastMonth = DateTime(lastMonthYear, lastMonth, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
        return txDate.isAfter(startOfLastMonth.subtract(const Duration(seconds: 1))) &&
               txDate.isBefore(endOfLastMonth.add(const Duration(days: 1)));
      case 'Last 3 Months':
        final startOfPeriod = DateTime(now.year, now.month - 3, now.day);
        return txDate.isAfter(startOfPeriod.subtract(const Duration(seconds: 1)));
      case 'Last 6 Months':
        final startOfPeriod = DateTime(now.year, now.month - 6, now.day);
        return txDate.isAfter(startOfPeriod.subtract(const Duration(seconds: 1)));
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(recalculatedAccountsProvider);
    
    return accountsAsync.when(
      data: (accounts) {
        final account = accounts.firstWhere(
          (a) => a.id == widget.accountId,
          orElse: () => null as dynamic,
        );

        if (account == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Account not found', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
                ],
              ),
            ),
          );
        }

        final txsAsync = ref.watch(accountTransactionsProvider(widget.accountId));

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
                  _buildHeader(context, ref, account),
                  
                  Expanded(
                    child: txsAsync.when(
                      data: (txs) {
                        // Filter transactions
                        final filteredTxs = txs.where((tx) {
                          final matchesSearch = tx.merchant?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
                                                tx.description?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
                                                tx.type.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
                          final matchesDate = _filterByDate(tx.date);
                          return matchesSearch && matchesDate;
                        }).toList();

                        // Sort by date descending
                        filteredTxs.sort((a, b) => b.date.compareTo(a.date));

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // 1. Balance discrepancy alert (Mismatch Banner)
                            _buildMismatchBanner(context, ref, account),

                            // 2. Credit Card Summary Card
                            _buildCreditCardOverviewCard(account),
                            const SizedBox(height: 20),

                            // 3. Tab Selector
                            _buildTabs(),
                            const SizedBox(height: 20),

                            // 4. Render Active Tab Content
                            if (_activeTab == 0) ...[
                              // Trend Line Chart
                              const Text(
                                'BALANCE TREND',
                                style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 12),
                              if (txs.length >= 2)
                                _buildTrendChart(account, txs)
                              else
                                _buildEmptyTrendState(),
                              const SizedBox(height: 24),

                              // Search & Filter
                              _buildSearchAndFilters(),
                              const SizedBox(height: 20),

                              // Transactions List
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'RECENT TRANSACTIONS',
                                    style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  ),
                                  Text(
                                    '${filteredTxs.length} items',
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              if (filteredTxs.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(40),
                                  alignment: Alignment.center,
                                  child: const Text('No transactions match filters.', style: TextStyle(color: Colors.white24, fontSize: 13)),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredTxs.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, idx) => _buildTransactionItem(filteredTxs[idx], account),
                                ),
                            ] else if (_activeTab == 1) ...[
                              // SMS Parse Logs list
                              _buildSmsHistoryTab(account),
                            ] else ...[
                              // Settings Tab
                              _buildSettingsTab(account),
                            ],
                            
                            const SizedBox(height: 100),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)))),
      error: (err, _) => Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Account account) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Credit Card',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white60),
                onPressed: () => _editAccount(context, account),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
                onPressed: () => _confirmDelete(context, ref, account),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.015),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          _buildTabItem(0, '📝 Ledger'),
          _buildTabItem(1, '📨 SMS Log'),
          _buildTabItem(2, '⚙️ Settings'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0066FF).withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF0066FF).withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMismatchBanner(BuildContext context, WidgetRef ref, Account account) {
    if (account.hasMismatch != true || account.balanceDiscrepancyDismissed == true) {
      return const SizedBox.shrink();
    }

    final expectedVal = account.mismatchExpected ?? 0;
    final importedVal = account.mismatchImported ?? 0;
    final diffVal = (expectedVal - importedVal).abs();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30), size: 20),
              SizedBox(width: 8),
              Text(
                'Balance Discrepancy Detected',
                style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Expected (Calculated):', style: TextStyle(color: Colors.white60, fontSize: 12.5)),
              Text(_formatMoney(expectedVal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Imported (SMS):', style: TextStyle(color: Colors.white60, fontSize: 12.5)),
              Text(_formatMoney(importedVal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Difference:', style: TextStyle(color: Colors.white60, fontSize: 12.5)),
              Text(_formatMoney(diffVal), style: const TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold, fontSize: 12.5, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final useVertical = constraints.maxWidth < 300;
              final buttons = [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () async {
                    try {
                      await ref.read(accountsProvider.notifier).acceptImportedBalance(account.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('SMS balance accepted')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: const Text('Accept SMS Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                if (!useVertical) const SizedBox(width: 8) else const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () async {
                    try {
                      await ref.read(accountsProvider.notifier).dismissDiscrepancy(account.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Balance discrepancy dismissed')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error dismissing discrepancy: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ];

              if (useVertical) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: buttons,
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: buttons,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardOverviewCard(Account account) {
    final themeColor = const Color(0xFFFF3B30); // Use RED for credit-card liabilities/accents
    
    final double utilizationPercent = (account.creditLimit != null && account.creditLimit! > 0)
        ? ((account.outstandingBalance ?? 0) / account.creditLimit! * 100).clamp(0, 100)
        : 0.0;

    int? daysRemaining;
    if (account.paymentDueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      var dueDate = DateTime(now.year, now.month, account.paymentDueDate!);
      if (dueDate.isBefore(today)) {
        var nextMonth = now.month + 1;
        var nextYear = now.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        dueDate = DateTime(nextYear, nextMonth, account.paymentDueDate!);
      }
      daysRemaining = dueDate.difference(today).inDays;
    }

    return GlassCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Row: Icon + Title on Left, [Adjust] button on Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: themeColor.withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(Icons.credit_card_rounded, color: themeColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'TOTAL OUTSTANDING',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showAdjustBalanceSheet(context, account),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.edit_road_rounded, color: Color(0xFF00E5FF), size: 14),
                      SizedBox(width: 6),
                      Text('Adjust', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Balance Amount (colored RED)
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              _formatOutstanding(account.outstandingBalance ?? 0),
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                color: Color(0xFFFF3B30), // Colored RED for outstanding liability
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          
          if (account.verifiedBalance != null) ...[
            const SizedBox(height: 8),
            Text(
              'Verified Baseline: ${_formatMoney(account.verifiedBalance!)} (${DateFormat('MMM dd').format(account.verifiedAt ?? DateTime.now())})',
              style: const TextStyle(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 16),

          // 3. Credit Utilization Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Credit Utilization', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text('${utilizationPercent.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: utilizationPercent / 100.0,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    utilizationPercent > 80 ? const Color(0xFFFF3B30) : const Color(0xFFFF3B30), // Show utilization bar in red
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Credit Limit', style: TextStyle(color: Colors.white38, fontSize: 10.5)),
                    const SizedBox(height: 2),
                    Text(_formatMoney(account.creditLimit ?? 0), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Limit', style: TextStyle(color: Colors.white38, fontSize: 10.5)),
                    const SizedBox(height: 2),
                    Text(_formatMoney(account.availableCredit ?? 0), style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Statement Date', style: TextStyle(color: Colors.white38, fontSize: 10.5)),
                    const SizedBox(height: 2),
                    Text(account.statementDate != null ? 'Day ${account.statementDate}' : 'N/A', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Due Date', style: TextStyle(color: Colors.white38, fontSize: 10.5)),
                    const SizedBox(height: 2),
                    Text(account.paymentDueDate != null ? 'Day ${account.paymentDueDate}' : 'N/A', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Minimum Due', style: TextStyle(color: Colors.white38, fontSize: 10.5)),
                    const SizedBox(height: 2),
                    Text(account.minAmountDue != null ? _formatMoney(account.minAmountDue!) : 'N/A', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Statement Amount', style: TextStyle(color: Colors.white38, fontSize: 10.5)),
                    const SizedBox(height: 2),
                    Text(account.totalAmountDue != null ? _formatOutstanding(account.totalAmountDue!) : 'N/A', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (daysRemaining != null) ...[
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Days Remaining until Due Date', style: TextStyle(color: Colors.white38, fontSize: 11)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: daysRemaining <= 3 ? const Color(0xFFFF3B30).withOpacity(0.12) : const Color(0xFF00E5FF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$daysRemaining day${daysRemaining > 1 ? "s" : ""}',
                    style: TextStyle(
                      color: daysRemaining <= 3 ? const Color(0xFFFF3B30) : const Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendChart(Account account, List<Transaction> txs) {
    final sortedTxs = List<Transaction>.from(txs)..sort((a, b) => a.date.compareTo(b.date));
    
    int running = account.outstandingBalance ?? 0;

    final List<FlSpot> spots = [];
    final limit = sortedTxs.length > 8 ? 8 : sortedTxs.length;

    final activeTxs = sortedTxs.reversed.take(limit).toList().reversed.toList();
    
    int tempBalance = running;
    final List<int> historyBalances = [tempBalance];

    for (int i = activeTxs.length - 1; i >= 1; i--) {
      final tx = activeTxs[i];
      final isCredit = tx.type == 'income' || tx.type == 'refund' || tx.type == 'cashback' || tx.type == 'reward' || tx.type == 'salary' || tx.type == 'transfer_credit' || tx.type == 'credit_card_payment_credit';
      final isDebit = tx.type == 'expense' || tx.type == 'credit_card_purchase' || tx.type == 'loan_emi' || tx.type == 'subscription' || tx.type == 'investment' || tx.type == 'cash_withdrawal' || tx.type == 'transfer_debit' || tx.type == 'credit_card_payment_debit';

      if (isCredit) {
        tempBalance += tx.amount.toInt();
      } else if (isDebit) {
        tempBalance -= tx.amount.toInt();
      }
      historyBalances.insert(0, tempBalance);
    }

    for (int i = 0; i < activeTxs.length; i++) {
      spots.add(FlSpot(i.toDouble(), historyBalances[i] / 100.0));
    }

    const chartColor = Color(0xFFFF3B30); // RED line for credit cards

    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
              isCurved: true,
              color: chartColor,
              barWidth: 3.0,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: chartColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTrendState() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.show_chart_rounded, color: Colors.white24, size: 32),
            SizedBox(height: 8),
            Text(
              'No trend data available yet',
              style: TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search merchant, note...',
                hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                prefixIcon: Icon(Icons.search, color: Colors.white30, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
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
              items: [
                'Today',
                'This Week',
                'This Month',
                'Last Month',
                'Last 3 Months',
                'Last 6 Months',
                'This Year',
                'Custom'
              ].map((String val) {
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
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF0066FF),
                            onPrimary: Colors.white,
                            surface: Color(0xFF050E1A),
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
      ],
    );
  }

  Widget _buildTransactionItem(Transaction tx, Account account) {
    final isCredit = tx.type == 'income' || tx.type == 'refund' || tx.type == 'cashback' || tx.type == 'reward' || tx.type == 'salary' || tx.type == 'transfer_credit' || tx.type == 'credit_card_payment_credit';
    final amountColor = isCredit ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30);
    
    return InkWell(
      onTap: () => _showTransactionActionsSheet(context, ref, tx),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.01),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: amountColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.merchant ?? tx.description ?? 'General Transaction',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('MMM dd, yyyy').format(tx.date)} • ${tx.type.toUpperCase().replaceAll('_', ' ')}',
                    style: const TextStyle(color: Colors.white30, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            Text(
              (isCredit ? '+ ' : '- ') + _formatMoney(tx.amount),
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showViewTransactionDetailsDialog(BuildContext context, Transaction tx) {
    showDialog(
      context: context,
      builder: (context) {
        final isCredit = tx.type == 'income' || tx.type == 'refund' || tx.type == 'cashback' || tx.type == 'reward' || tx.type == 'salary';
        final amountColor = isCredit ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30);
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1A1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white12)),
          title: Text(tx.merchant ?? tx.description ?? 'Transaction Details', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text((isCredit ? '+ ' : '- ') + _formatMoney(tx.amount.toInt()), style: TextStyle(color: amountColor, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildDetailRow('Date', DateFormat('yyyy-MM-dd hh:mm a').format(tx.date)),
                _buildDetailRow('Type', tx.type.toUpperCase().replaceAll('_', ' ')),
                if (tx.merchant != null) _buildDetailRow('Merchant', tx.merchant!),
                if (tx.referenceNumber != null && tx.referenceNumber!.isNotEmpty) _buildDetailRow('Ref / UPI ID', tx.referenceNumber!),
                if (tx.description != null && tx.description!.isNotEmpty) _buildDetailRow('Notes', tx.description!),
                if (tx.source != null) _buildDetailRow('Source', tx.source!.toUpperCase()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF00E5FF))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(width: 8),
          Flexible(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  void _showTransactionActionsSheet(BuildContext context, WidgetRef ref, Transaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1A1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.visibility_outlined, color: Color(0xFF00E5FF)),
                title: const Text('View Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('View full transaction metadata', style: TextStyle(color: Colors.white38, fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _showViewTransactionDetailsDialog(context, tx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded, color: Colors.white70),
                title: const Text('Edit Transaction', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Open full edit screen', style: TextStyle(color: Colors.white38, fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/expenses/edit/${tx.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined, color: Color(0xFFFFB703)),
                title: const Text('Change Category', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showChangeCategorySheet(context, ref, tx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF0066FF)),
                title: const Text('Change Account', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showChangeAccountSheet(context, ref, tx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money_rounded, color: Colors.greenAccent),
                title: const Text('Change Amount', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showChangeAmountDialog(context, ref, tx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.store_outlined, color: Colors.purpleAccent),
                title: const Text('Change Merchant & Notes', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showChangeMerchantNotesDialog(context, ref, tx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.call_split_rounded, color: Colors.orangeAccent),
                title: const Text('Split Transaction', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showSplitTransactionSheet(context, ref, tx);
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
                title: const Text('Delete Transaction', style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteTransaction(context, ref, tx);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showChangeCategorySheet(BuildContext context, WidgetRef ref, Transaction tx) {
    final categoriesAsync = ref.read(categoriesProvider);
    categoriesAsync.whenData((categories) {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF050E1A),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Select New Category', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, idx) {
                      final cat = categories[idx];
                      return ListTile(
                        leading: const Icon(Icons.category, color: Color(0xFF00E5FF)),
                        title: Text(cat.name, style: const TextStyle(color: Colors.white)),
                        onTap: () async {
                          Navigator.pop(context);
                          final updated = tx.copyWith(categoryId: Value(cat.id), updatedAt: DateTime.now());
                          await ref.read(expenseListNotifierProvider.notifier).editTransaction(updated);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  void _showChangeAccountSheet(BuildContext context, WidgetRef ref, Transaction tx) {
    final accountsAsync = ref.read(accountsProvider);
    accountsAsync.whenData((accounts) {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF050E1A),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Select New Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, idx) {
                      final acc = accounts[idx];
                      return ListTile(
                        leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF0066FF)),
                        title: Text(acc.displayTitle, style: const TextStyle(color: Colors.white)),
                        onTap: () async {
                          Navigator.pop(context);
                          final updated = tx.copyWith(accountId: Value(acc.id), updatedAt: DateTime.now());
                          await ref.read(expenseListNotifierProvider.notifier).editTransaction(updated);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  void _showChangeAmountDialog(BuildContext context, WidgetRef ref, Transaction tx) {
    final controller = TextEditingController(text: (tx.amount / 100.0).toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        title: const Text('Change Amount', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(prefixText: '₹ ', enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF)),
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(context);
                final updated = tx.copyWith(amount: (val * 100).round(), updatedAt: DateTime.now());
                await ref.read(expenseListNotifierProvider.notifier).editTransaction(updated);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangeMerchantNotesDialog(BuildContext context, WidgetRef ref, Transaction tx) {
    final merchantController = TextEditingController(text: tx.merchant);
    final notesController = TextEditingController(text: tx.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        title: const Text('Edit Details', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: merchantController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Merchant', labelStyle: TextStyle(color: Colors.white54))),
            TextField(controller: notesController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Notes', labelStyle: TextStyle(color: Colors.white54))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF)),
            onPressed: () async {
              Navigator.pop(context);
              final updated = tx.copyWith(merchant: Value(merchantController.text.trim()), description: Value(notesController.text.trim()), updatedAt: DateTime.now());
              await ref.read(expenseListNotifierProvider.notifier).editTransaction(updated);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSplitTransactionSheet(BuildContext context, WidgetRef ref, Transaction tx) {
    final controller1 = TextEditingController(text: (tx.amount / 200.0).toStringAsFixed(2));
    final controller2 = TextEditingController(text: (tx.amount / 200.0).toStringAsFixed(2));
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050E1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Split Transaction', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: controller1, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'First Amount', labelStyle: TextStyle(color: Colors.white54))),
            TextField(controller: controller2, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Second Amount', labelStyle: TextStyle(color: Colors.white54))),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF), padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                final val1 = double.tryParse(controller1.text);
                final val2 = double.tryParse(controller2.text);
                if (val1 != null && val2 != null && val1 > 0 && val2 > 0) {
                  Navigator.pop(context);
                  final amt1 = (val1 * 100).round();
                  final amt2 = (val2 * 100).round();
                  
                  final t1 = tx.copyWith(amount: amt1, description: Value('${tx.description ?? ""} [Split 1]'), updatedAt: DateTime.now());
                  final t2 = tx.copyWith(id: const Uuid().v4(), amount: amt2, description: Value('${tx.description ?? ""} [Split 2]'), createdAt: DateTime.now(), updatedAt: DateTime.now());
                  
                  await ref.read(expenseListNotifierProvider.notifier).editTransaction(t1);
                  await ref.read(expenseListNotifierProvider.notifier).addTransaction(t2);
                }
              },
              child: const Text('Split Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTransaction(BuildContext context, WidgetRef ref, Transaction tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFFF3B30), width: 1)),
        title: const Text('Delete Transaction', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${tx.merchant ?? tx.description ?? "this transaction"}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF0066FF)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(expenseListNotifierProvider.notifier).removeTransaction(tx.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSmsHistoryTab(Account account) {
    final parsedSmsAsync = ref.watch(accountParsedSmsProvider(account.id));

    return parsedSmsAsync.when(
      data: (smsList) {
        if (smsList.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            child: const Text(
              'No SMS logs found for this account.',
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AUTO IMPORTED SMS ALERTS',
                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Text(
                  '${smsList.length} logs',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: smsList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final sms = smsList[idx];
                final isDebit = sms.isDebit == true;
                final amtColor = isDebit ? const Color(0xFFFF3B30) : const Color(0xFF00E5FF);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.015),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.03)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sms.sender ?? 'SMS Alert',
                              style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            sms.receivedAt != null 
                                ? DateFormat('MMM dd, hh:mm a').format(sms.receivedAt!)
                                : '',
                            style: const TextStyle(color: Colors.white24, fontSize: 10.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Merchant: ${sms.merchant ?? "Unknown"}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            isDebit ? 'Debited: ' : 'Credited: ',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          Text(
                            _formatMoney(sms.amount ?? 0),
                            style: TextStyle(color: amtColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (sms.availableBalance != null) ...[
                            const Text(
                              'Bal: ',
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                            Text(
                              _formatMoney(sms.availableBalance!),
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildSettingsTab(Account account) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ACCOUNT PREFERENCES',
          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.015),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                value: account.enableSmsTracking ?? true,
                activeColor: const Color(0xFF0066FF),
                title: const Text('SMS Auto-Import Tracking', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Intelligently parse incoming transaction alerts', style: TextStyle(color: Colors.white38, fontSize: 11.5)),
                onChanged: (val) async {
                  final updated = account.copyWith(
                    enableSmsTracking: Value(val),
                    updatedAt: DateTime.now(),
                  );
                  await ref.read(accountsProvider.notifier).editAccount(updated);
                },
              ),
              const Divider(color: Colors.white10),
              SwitchListTile(
                value: account.enableBillReminder ?? true,
                activeColor: const Color(0xFF0066FF),
                title: const Text('Bill Payment Reminders', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Generate auto reminders for statement dues', style: TextStyle(color: Colors.white38, fontSize: 11.5)),
                onChanged: (val) async {
                  final updated = account.copyWith(
                    enableBillReminder: Value(val),
                    updatedAt: DateTime.now(),
                  );
                  await ref.read(accountsProvider.notifier).editAccount(updated);
                },
              ),
              const Divider(color: Colors.white10),
              SwitchListTile(
                value: account.isActive ?? true,
                activeColor: const Color(0xFF0066FF),
                title: const Text('Active Account', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Toggle visibility of this account in main dashboards', style: TextStyle(color: Colors.white38, fontSize: 11.5)),
                onChanged: (val) async {
                  final updated = account.copyWith(
                    isActive: Value(val),
                    updatedAt: DateTime.now(),
                  );
                  await ref.read(accountsProvider.notifier).editAccount(updated);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF3B30).withOpacity(0.1),
            side: const BorderSide(color: Color(0xFFFF3B30), width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => _confirmDelete(context, ref, account),
          icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFFF3B30)),
          label: const Text('Permanently Delete Account', style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showAdjustBalanceSheet(BuildContext context, Account acc) {
    final currentValInCents = acc.outstandingBalance ?? 0;
    final controller = TextEditingController(text: (currentValInCents / 100.0).toStringAsFixed(2));
    bool createEntry = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050E1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Manual Balance Correction',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Adjust balance baseline for ${acc.displayTitle}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(color: Color(0xFF00E5FF), fontSize: 24, fontWeight: FontWeight.bold),
                      labelText: 'Current Outstanding Balance',
                      labelStyle: TextStyle(color: Colors.white54, fontSize: 14),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0066FF))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: createEntry,
                    title: const Text(
                      'Create Adjustment Entry',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Generates an income/expense entry to account for the difference',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        setStateSheet(() => createEntry = val);
                      }
                    },
                    activeColor: const Color(0xFF0066FF),
                    checkColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final double? parsedVal = double.tryParse(controller.text);
                      if (parsedVal != null) {
                        final valInCents = (parsedVal * 100).round();
                        final auth = ref.read(authProvider);
                        final userId = auth.user?.id ?? 'system';
                        
                        Navigator.pop(context);
                        await ref.read(accountsProvider.notifier).adjustBalanceManually(
                          acc.id,
                          valInCents,
                          createEntry,
                          userId,
                        );
                      }
                    },
                    child: const Text('Save Correction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editAccount(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AccountFormSheet(existing: account),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF3B30), width: 1),
        ),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${account.displayTitle}"? This will delete the account local configuration. Transactions belonging to this account will remain, but their account reference will be removed.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF0066FF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
            onPressed: () async {
              Navigator.pop(context); // close dialog
              context.pop(); // go back from details screen
              await ref.read(accountsProvider.notifier).removeAccount(account.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
