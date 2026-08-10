import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/app_database.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/accounts_provider.dart';
import '../providers/account_formatters.dart';
import '../../../dashboard/presentation/providers/hide_balance_provider.dart';
import '../../../../shared/widgets/privacy_text.dart';
import 'account_form_sheet.dart';
import 'transfer_form_sheet.dart';
import 'credit_card_payment_sheet.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, bank, card, wallet, hidden

  String formatCreditCardAmount(String text) {
    final clean = text.replaceAll('-', '').replaceAll('–', '').replaceAll('—', '').replaceAll('−', '').trim();
    if (clean.isEmpty || clean == '₹0.00' || clean == '0' || clean == '0.00') {
      return '₹0.00';
    }
    return '-$clean';
  }

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }

  int _getAccountTypeRank(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return 1;
      case 'wallet':
      case 'upi_wallet':
      case 'digital_wallet':
        return 2;
      case 'savings':
      case 'current':
      case 'salary':
      case 'debit_card':
        return 3;
      case 'credit_card':
        return 4;
      case 'investment':
      case 'fixed_deposit':
      case 'gold':
      case 'crypto':
        return 5;
      case 'loan':
        return 6;
      default:
        return 7;
    }
  }

  Color _getColor(String? colorStr, String type) {
    if (colorStr != null && colorStr.isNotEmpty) {
      try {
        return Color(int.parse(colorStr));
      } catch (_) {}
    }
    switch (type.toLowerCase()) {
      case 'credit_card':
      case 'loan':
        return const Color(0xFFFF3B30); // Red
      case 'cash':
        return const Color(0xFF00E5FF); // Cyan
      case 'wallet':
      case 'upi_wallet':
        return const Color(0xFFFFB703); // Yellow/Gold
      default:
        return const Color(0xFF0066FF); // Blue
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortBy = ref.watch(accountSortProvider);
    final summaryAsync = ref.watch(accountSummaryProvider);
    final accountsAsync = ref.watch(recalculatedAccountsProvider);

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Accounts Ledger',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Consumer(
                      builder: (context, ref, child) {
                        final hideState = ref.watch(hideBalanceProvider);
                        return IconButton(
                          icon: Icon(
                            hideState.hideAccountBalances ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            ref.read(hideBalanceProvider.notifier).toggleHideAccountBalances();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(accountsProvider.notifier).loadAccounts();
                  },
                  color: const Color(0xFF0066FF),
                  backgroundColor: const Color(0xFF0A0A0A),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Net Assets card
                      summaryAsync.when(
                        data: (summary) => _buildNetAssetsCard(context, summary),
                        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                      ),
                      const SizedBox(height: 16),

                      // Credit Card Info Banner
                      Builder(
                        builder: (context) {
                          final hasCC = accountsAsync.maybeWhen(
                            data: (list) => list.any((a) => a.type == 'credit_card' && (a.outstandingBalance == null || a.outstandingBalance == 0)),
                            orElse: () => false,
                          );
                          if (!hasCC) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066FF).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.2)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: Color(0xFF00E5FF), size: 18),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No credit card outstanding balance detected. Expenso will automatically calculate it from future SMS statements and transactions.',
                                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Search and Controls
                      _buildSearchAndControls(sortBy),
                      const SizedBox(height: 20),

                      // Accounts List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'MY ACCOUNTS',
                            style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          if (sortBy == 'manual')
                            const Text(
                              'Hold & Drag to Reorder',
                              style: TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      accountsAsync.when(
                        data: (accounts) {
                          if (accounts.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No accounts found. Tap + to add one.', style: TextStyle(color: Colors.white38)),
                              ),
                            );
                          }

                          // Filter and sort accounts
                          final filtered = accounts.where((acc) {
                            final nameMatches = acc.name.toLowerCase().contains(_searchQuery.toLowerCase());
                            final bankMatches = (acc.bankName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
                            final typeMatches = acc.type.toLowerCase().contains(_searchQuery.toLowerCase());
                            final digitsMatches = (acc.last4Digits ?? '').contains(_searchQuery);
                            final matchesSearch = nameMatches || bankMatches || typeMatches || digitsMatches;

                            if (_selectedFilter == 'hidden') {
                              return matchesSearch && (acc.isActive == false);
                            }
                            
                            if (acc.isActive == false) return false;

                            switch (_selectedFilter) {
                              case 'bank':
                                return matchesSearch && (acc.type == 'savings' || acc.type == 'current' || acc.type == 'salary' || acc.type == 'debit_card');
                              case 'card':
                                return matchesSearch && acc.type == 'credit_card';
                              case 'wallet':
                                return matchesSearch && (acc.type == 'wallet' || acc.type == 'upi_wallet' || acc.type == 'digital_wallet' || acc.type == 'cash');
                              default:
                                return matchesSearch;
                            }
                          }).toList();

                           if (sortBy == 'name') {
                            filtered.sort((a, b) => sanitizeAccountName(a.name).toLowerCase().compareTo(sanitizeAccountName(b.name).toLowerCase()));
                          } else if (sortBy == 'balance_high') {
                            filtered.sort((a, b) {
                              final balA = a.type == 'credit_card' ? -(a.outstandingBalance ?? 0) : a.balance;
                              final balB = b.type == 'credit_card' ? -(b.outstandingBalance ?? 0) : b.balance;
                              return balB.compareTo(balA);
                            });
                          } else if (sortBy == 'balance_low') {
                            filtered.sort((a, b) {
                              final balA = a.type == 'credit_card' ? -(a.outstandingBalance ?? 0) : a.balance;
                              final balB = b.type == 'credit_card' ? -(b.outstandingBalance ?? 0) : b.balance;
                              return balA.compareTo(balB);
                            });
                          } else if (sortBy == 'updated') {
                            filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                          } else if (sortBy == 'manual') {
                            filtered.sort((a, b) {
                              final orderA = a.sortOrder ?? 0;
                              final orderB = b.sortOrder ?? 0;
                              if (orderA != orderB) {
                                return orderA.compareTo(orderB);
                              }
                              final rankA = _getAccountTypeRank(a.type);
                              final rankB = _getAccountTypeRank(b.type);
                              if (rankA != rankB) return rankA.compareTo(rankB);
                              return sanitizeAccountName(a.name).toLowerCase().compareTo(sanitizeAccountName(b.name).toLowerCase());
                            });
                          }

                          if (filtered.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No accounts match the filters.', style: TextStyle(color: Colors.white38)),
                              ),
                            );
                          }

                          if (sortBy == 'manual') {
                            // Show drag & drop reorderable list
                            return ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              buildDefaultDragHandles: false,
                              itemCount: filtered.length,
                              onReorder: (oldIndex, newIndex) async {
                                if (newIndex > oldIndex) {
                                  newIndex -= 1;
                                }
                                final item = filtered.removeAt(oldIndex);
                                filtered.insert(newIndex, item);
                                await ref.read(accountsProvider.notifier).updateAccountSortOrder(filtered);
                              },
                              itemBuilder: (context, idx) {
                                final acc = filtered[idx];
                                return ReorderableDragStartListener(
                                  index: idx,
                                  key: ValueKey(acc.id),
                                  child: _buildDismissibleAccountItem(context, acc),
                                );
                              },
                            );
                          }

                          // Otherwise group by type if "All" filter is chosen, or just show flat sorted list
                          if (_selectedFilter == 'all') {
                            final cash = filtered.where((a) => a.type == 'cash').toList();
                            final wallets = filtered.where((a) => a.type == 'wallet' || a.type == 'upi_wallet' || a.type == 'digital_wallet').toList();
                            final banks = filtered.where((a) => a.type == 'savings' || a.type == 'current' || a.type == 'salary' || a.type == 'debit_card').toList();
                            final creditCards = filtered.where((a) => a.type == 'credit_card').toList();
                            final investments = filtered.where((a) => a.type == 'investment' || a.type == 'fixed_deposit' || a.type == 'gold' || a.type == 'crypto').toList();
                            final loans = filtered.where((a) => a.type == 'loan').toList();
                            final others = filtered.where((a) => 
                              !cash.contains(a) && 
                              !wallets.contains(a) && 
                              !banks.contains(a) && 
                              !creditCards.contains(a) && 
                              !investments.contains(a) && 
                              !loans.contains(a)
                            ).toList();

                            final listToProcess = [cash, wallets, banks, creditCards, investments, loans, others];
                            for (var subList in listToProcess) {
                              if (sortBy == 'name') {
                                subList.sort((a, b) => sanitizeAccountName(a.name).toLowerCase().compareTo(sanitizeAccountName(b.name).toLowerCase()));
                              } else if (sortBy == 'balance_high') {
                                subList.sort((a, b) {
                                  final balA = a.type == 'credit_card' ? -(a.outstandingBalance ?? 0) : a.balance;
                                  final balB = b.type == 'credit_card' ? -(b.outstandingBalance ?? 0) : b.balance;
                                  return balB.compareTo(balA);
                                });
                              } else if (sortBy == 'balance_low') {
                                subList.sort((a, b) {
                                  final balA = a.type == 'credit_card' ? -(a.outstandingBalance ?? 0) : a.balance;
                                  final balB = b.type == 'credit_card' ? -(b.outstandingBalance ?? 0) : b.balance;
                                  return balA.compareTo(balB);
                                });
                              } else if (sortBy == 'updated') {
                                subList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                              } else if (sortBy == 'manual') {
                                subList.sort((a, b) {
                                  final orderA = a.sortOrder ?? 0;
                                  final orderB = b.sortOrder ?? 0;
                                  if (orderA != orderB) {
                                    return orderA.compareTo(orderB);
                                  }
                                  return sanitizeAccountName(a.name).toLowerCase().compareTo(sanitizeAccountName(b.name).toLowerCase());
                                });
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (cash.isNotEmpty) ...[
                                  _buildGroupHeader('Cash'),
                                  ...cash.map((acc) => _buildDismissibleAccountItem(context, acc)),
                                  const SizedBox(height: 12),
                                ],
                                if (wallets.isNotEmpty) ...[
                                  _buildGroupHeader('Wallets'),
                                  ...wallets.map((acc) => _buildDismissibleAccountItem(context, acc)),
                                  const SizedBox(height: 12),
                                ],
                                if (banks.isNotEmpty) ...[
                                  _buildGroupHeader('Bank Accounts'),
                                  ...banks.map((acc) => _buildDismissibleAccountItem(context, acc)),
                                  const SizedBox(height: 12),
                                ],
                                if (creditCards.isNotEmpty) ...[
                                  _buildGroupHeader('Credit Cards'),
                                  ...creditCards.map((acc) => _buildDismissibleAccountItem(context, acc)),
                                  const SizedBox(height: 12),
                                ],
                                if (investments.isNotEmpty) ...[
                                  _buildGroupHeader('Investments'),
                                  ...investments.map((acc) => _buildDismissibleAccountItem(context, acc)),
                                  const SizedBox(height: 12),
                                ],
                                if (loans.isNotEmpty) ...[
                                  _buildGroupHeader('Loans'),
                                  ...loans.map((acc) => _buildDismissibleAccountItem(context, acc)),
                                  const SizedBox(height: 12),
                                ],
                                if (others.isNotEmpty) ...[
                                  _buildGroupHeader('Other Accounts'),
                                  ...others.map((acc) => _buildDismissibleAccountItem(context, acc)),
                                ],
                              ],
                            );
                          }

                          // If filtered to a specific type, show flat sorted list
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (context, idx) => _buildDismissibleAccountItem(context, filtered[idx]),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildNetAssetsCard(BuildContext context, AccountSummary summary) {
    return GlassCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'NET WORTH / ASSETS',
            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 6),
          PrivacyText(
            rawValue: _formatMoney(summary.netAssets),
            isNetWorth: true,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Assets', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 2),
                    PrivacyText(
                      rawValue: _formatMoney(summary.totalAssets),
                      isNetWorth: true,
                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Liabilities', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 2),
                    PrivacyText(
                      rawValue: _formatMoney(summary.totalLiabilities),
                      isNetWorth: true,
                      style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add_rounded,
                  label: 'Add Account',
                  color: const Color(0xFF00E5FF),
                  onTap: () => _showAccountForm(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Transfer',
                  color: const Color(0xFF0066FF),
                  onTap: () => _showTransferForm(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.payment_rounded,
                  label: 'Pay Card',
                  color: const Color(0xFFFF3B30),
                  onTap: () => _showCreditCardPaymentForm(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndControls(String sortBy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Input & Sort dropdown
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search account name, bank...',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 12.5),
                    prefixIcon: const Icon(Icons.search, color: Colors.white30, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortBy,
                  dropdownColor: const Color(0xFF0F1A1C),
                  icon: const Icon(Icons.sort_rounded, color: Colors.white70, size: 18),
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 'manual', child: Text('Manual')),
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'balance_high', child: Text('Highest Bal')),
                    DropdownMenuItem(value: 'balance_low', child: Text('Lowest Bal')),
                    DropdownMenuItem(value: 'updated', child: Text('Recent')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(accountSortProvider.notifier).setSortBy(val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Filter Chips (horizontal scroll)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('all', '🏷️ All'),
              const SizedBox(width: 8),
              _buildFilterChip('bank', '🏦 Banks'),
              const SizedBox(width: 8),
              _buildFilterChip('card', '💳 Cards'),
              const SizedBox(width: 8),
              _buildFilterChip('wallet', '👛 Wallets'),
              const SizedBox(width: 8),
              _buildFilterChip('hidden', '👁️ Hidden'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0066FF).withOpacity(0.15) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0066FF).withOpacity(0.5) : Colors.white12,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleAccountItem(BuildContext context, Account acc) {
    return Dismissible(
      key: Key('dismiss_${acc.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF00E5FF).withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: const [
            Icon(Icons.list_alt_rounded, color: Color(0xFF00E5FF)),
            SizedBox(width: 8),
            Text('Transactions', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      secondaryBackground: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB703).withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text('Quick Settings', style: TextStyle(color: Color(0xFFFFB703), fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(width: 8),
            Icon(Icons.settings, color: Color(0xFFFFB703)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right: open details screen directly
          context.push('/accounts/${acc.id}');
        } else {
          // Swipe Left: show quick actions sheet
          _showAccountActionsSheet(context, acc);
        }
        return false; // do not remove the widget from the tree
      },
      child: GestureDetector(
        onLongPress: () => _showAccountActionsSheet(context, acc),
        child: _buildCompactAccountCard(context, acc),
      ),
    );
  }

  Widget _buildCompactAccountCard(BuildContext context, Account acc) {
    final color = _getColor(acc.colorTheme, acc.type);
    final isCC = acc.type == 'credit_card';
    final hasMismatch = acc.hasMismatch == true;

    final String cardTitle = acc.displayTitleWithEmoji(includeEmoji: true);

    // Format balances
    final balanceVal = isCC ? (acc.outstandingBalance ?? 0) : acc.balance;
    final balanceText = _formatMoney(balanceVal);
    final outstandingText = _formatMoney(acc.outstandingBalance ?? 0);
    final lastBillText = _formatMoney(acc.totalAmountDue ?? 0);

    return InkWell(
      onTap: () => context.push('/accounts/${acc.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.015),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        clipBehavior: ui.Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Accent Colored Line on the left
              Container(
                width: 4.5,
                color: color,
              ),
              // 2. Main content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Title and Chevron
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cardTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasMismatch) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFFF3B30),
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white24,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Row 2: Account type and Balance
                      if (!isCC) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              acc.displaySubtitle,
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            PrivacyText(
                              rawValue: balanceText,
                              isAccountBalance: true,
                              style: TextStyle(
                                color: balanceVal >= 0 ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30),
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Credit Card details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              acc.displaySubtitle,
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            PrivacyText(
                              rawValue: formatCreditCardAmount(outstandingText),
                              isAccountBalance: true,
                              style: const TextStyle(
                                color: Color(0xFFFF3B30),
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Last Bill Due',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            PrivacyText(
                              rawValue: formatCreditCardAmount(lastBillText),
                              isAccountBalance: true,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.0,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountActionsSheet(BuildContext context, Account acc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050E1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      acc.displayTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getColor(acc.colorTheme, acc.type).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        acc.type.toUpperCase(),
                        style: TextStyle(color: _getColor(acc.colorTheme, acc.type), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.white70),
                title: const Text('Edit / Rename', style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  _showAccountForm(context, existing: acc);
                },
              ),
              ListTile(
                leading: const Icon(Icons.scale_rounded, color: Colors.white70),
                title: const Text('Adjust Balance Manually', style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  _showAdjustBalanceSheet(context, acc);
                },
              ),
              ListTile(
                leading: Icon(
                  acc.isActive == false ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: Colors.white70,
                ),
                title: Text(
                  acc.isActive == false ? 'Show / Activate Account' : 'Hide / Deactivate Account',
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final updated = acc.copyWith(
                    isActive: Value(acc.isActive == false),
                    updatedAt: DateTime.now(),
                  );
                  await ref.read(accountsProvider.notifier).editAccount(updated);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFFF3B30)),
                title: const Text('Delete Account', style: TextStyle(color: Color(0xFFFF3B30))),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, acc);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdjustBalanceSheet(BuildContext context, Account acc) {
    final isCC = acc.type == 'credit_card';
    final currentValInCents = isCC ? (acc.outstandingBalance ?? 0) : acc.balance;
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
                    'Adjust balance for ${acc.displayTitle}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: Color(0xFF00E5FF), fontSize: 24, fontWeight: FontWeight.bold),
                      labelText: isCC ? 'Current Outstanding Balance' : 'Current Available Balance',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0066FF))),
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

  void _confirmDelete(BuildContext context, Account acc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF3B30), width: 1),
        ),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${acc.displayTitle}"? This will delete the account local configuration. Transactions belonging to this account will remain, but their account reference will be removed.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF0066FF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(accountsProvider.notifier).removeAccount(acc.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAccountForm(BuildContext context, {Account? existing}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AccountFormSheet(existing: existing),
    );
  }

  void _showTransferForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const TransferFormSheet(),
    );
  }

  void _showCreditCardPaymentForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CreditCardPaymentSheet(),
    );
  }
}
