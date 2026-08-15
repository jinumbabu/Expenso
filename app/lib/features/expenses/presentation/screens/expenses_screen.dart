import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/account_formatters.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/privacy_text.dart';
import '../../../../core/services/category_intelligence.dart';

final _categorySearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final _accountSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final _pmSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  bool _isSearchActive = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeDatePresetProvider.notifier).state = 'this_month';
      ref.read(filterDateRangeProvider.notifier).state = getDateRangeFromPreset('this_month');
      ref.read(searchQueryProvider.notifier).state = '';
      ref.read(filterCategoryProvider.notifier).state = null;
      ref.read(filterTypeProvider.notifier).state = null;
      ref.read(filterPaymentMethodProvider.notifier).state = null;
      ref.read(filterAccountProvider.notifier).state = null;
      ref.read(filterMinAmountProvider.notifier).state = null;
      ref.read(filterMaxAmountProvider.notifier).state = null;
      ref.read(filterSortByProvider.notifier).state = 'newest';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }

  void _showCategorySearchSheet(BuildContext context, WidgetRef ref, List<Category> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final searchQuery = ref.watch(_categorySearchQueryProvider);
            final filteredCats = categories.where((c) {
              return c.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Category', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: TextField(
                      onChanged: (val) => ref.read(_categorySearchQueryProvider.notifier).state = val,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search categories...',
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon: Icon(Icons.search, color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.all_inclusive, color: Color(0xFF00E5FF)),
                          title: const Text('All Categories', style: TextStyle(color: Colors.white, fontSize: 14)),
                          onTap: () {
                            ref.read(filterCategoryProvider.notifier).state = null;
                            Navigator.pop(context);
                          },
                        ),
                        ...filteredCats.map((cat) {
                          final isSelected = ref.watch(filterCategoryProvider) == cat.id;
                          final catColor = IconMapper.getColor(cat.icon);
                          final catIcon = IconMapper.getIcon(cat.icon);
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: catColor.withOpacity(0.12), shape: BoxShape.circle),
                              child: Icon(catIcon, color: catColor, size: 18),
                            ),
                            title: Text(cat.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF00E5FF), size: 20) : null,
                            onTap: () {
                              ref.read(filterCategoryProvider.notifier).state = cat.id;
                              Navigator.pop(context);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAccountSearchSheet(BuildContext context, WidgetRef ref, List<Account> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final searchQuery = ref.watch(_accountSearchQueryProvider);
            final filteredAccs = accounts.where((a) {
              return a.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Financial Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: TextField(
                      onChanged: (val) => ref.read(_accountSearchQueryProvider.notifier).state = val,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search accounts...',
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon: Icon(Icons.search, color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.all_inclusive, color: Color(0xFF00E5FF)),
                          title: const Text('All Accounts', style: TextStyle(color: Colors.white, fontSize: 14)),
                          onTap: () {
                            ref.read(filterAccountProvider.notifier).state = null;
                            Navigator.pop(context);
                          },
                        ),
                        ...filteredAccs.map((acc) {
                          final isSelected = ref.watch(filterAccountProvider) == acc.id;
                          return ListTile(
                            leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF0066FF)),
                            title: Text(acc.displayTitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            subtitle: Text(acc.displaySubtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF00E5FF), size: 20) : null,
                            onTap: () {
                              ref.read(filterAccountProvider.notifier).state = acc.id;
                              Navigator.pop(context);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPmSearchSheet(BuildContext context, WidgetRef ref, List<PaymentMethod> methods) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final searchQuery = ref.watch(_pmSearchQueryProvider);
            final filteredPms = methods.where((p) {
              return p.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Payment Method', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: TextField(
                      onChanged: (val) => ref.read(_pmSearchQueryProvider.notifier).state = val,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search payment methods...',
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon: Icon(Icons.search, color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.all_inclusive, color: Color(0xFF00E5FF)),
                          title: const Text('All Payment Methods', style: TextStyle(color: Colors.white, fontSize: 14)),
                          onTap: () {
                            ref.read(filterPaymentMethodProvider.notifier).state = null;
                            Navigator.pop(context);
                          },
                        ),
                        ...filteredPms.map((pm) {
                          final isSelected = ref.watch(filterPaymentMethodProvider) == pm.id;
                          return ListTile(
                            leading: const Icon(Icons.credit_card, color: Color(0xFFFFB703)),
                            title: Text(pm.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF00E5FF), size: 20) : null,
                            onTap: () {
                              ref.read(filterPaymentMethodProvider.notifier).state = pm.id;
                              Navigator.pop(context);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSavePresetDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Save Filter Preset', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            labelText: 'Preset Name',
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final currentType = ref.read(filterTypeProvider);
                final currentCat = ref.read(filterCategoryProvider);
                final currentPM = ref.read(filterPaymentMethodProvider);
                final currentAcc = ref.read(filterAccountProvider);
                final currentDatePreset = ref.read(activeDatePresetProvider);
                final currentDateRange = ref.read(filterDateRangeProvider);
                final currentMin = ref.read(filterMinAmountProvider);
                final currentMax = ref.read(filterMaxAmountProvider);
                final currentSort = ref.read(filterSortByProvider);

                ref.read(savedFiltersProvider.notifier).addPreset(
                  SavedFilterPreset(
                    name: name,
                    type: currentType,
                    categoryId: currentCat,
                    paymentMethodId: currentPM,
                    accountId: currentAcc,
                    datePreset: currentDatePreset,
                    dateRange: currentDateRange,
                    minAmount: currentMin,
                    maxAmount: currentMax,
                    sortBy: currentSort,
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final txsAsync = ref.watch(expenseListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    // Watch filter states
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(filterCategoryProvider);
    final selectedType = ref.watch(filterTypeProvider);
    final selectedPaymentMethod = ref.watch(filterPaymentMethodProvider);
    final selectedDateRange = ref.watch(filterDateRangeProvider);
    final selectedAccount = ref.watch(filterAccountProvider);
    final minAmount = ref.watch(filterMinAmountProvider);
    final maxAmount = ref.watch(filterMaxAmountProvider);
    final activeDatePreset = ref.watch(activeDatePresetProvider);

    ref.listen<String>(searchQueryProvider, (prev, next) {
      if (_searchController.text != next) {
        _searchController.text = next;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: next.length),
        );
      }
    });

    // Group transactions by date
    final groupedTxs = <DateTime, List<Transaction>>{};
    for (var tx in filteredTransactions) {
      final dateOnly = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (groupedTxs[dateOnly] == null) {
        groupedTxs[dateOnly] = [];
      }
      groupedTxs[dateOnly]!.add(tx);
    }
    final sortedDates = groupedTxs.keys.toList()..sort((a, b) => b.compareTo(a));

    // Calculate total expenses shown
    int totalExpenseShown = 0;
    int totalIncomeShown = 0;
    for (var tx in filteredTransactions) {
      if (tx.type == 'expense') {
        totalExpenseShown += tx.amount;
      } else if (tx.type == 'income') {
        totalIncomeShown += tx.amount;
      }
    }

    final categories = categoriesAsync.maybeWhen(data: (c) => c, orElse: () => <Category>[]);
    final paymentMethods = paymentMethodsAsync.maybeWhen(data: (p) => p, orElse: () => <PaymentMethod>[]);
    final accounts = accountsAsync.maybeWhen(data: (a) => a, orElse: () => <Account>[]);

    final categoriesMap = {for (var c in categories) c.id: c};
    final pmsMap = {for (var p in paymentMethods) p.id: p};
    final accountsMap = {for (var a in accounts) a.id: a};

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
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
              children: [
                // Screen Header & Filter summary card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () {
                          if (_isSearchActive) {
                            ref.read(searchQueryProvider.notifier).state = '';
                            setState(() {
                              _isSearchActive = false;
                            });
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isSearchActive
                            ? Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.12)),
                                ),
                                child: TextField(
                                  autofocus: true,
                                  onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                                  controller: _searchController,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Search description, merchant...',
                                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                                    suffixIcon: searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                                            onPressed: () {
                                              ref.read(searchQueryProvider.notifier).state = '';
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              )
                            : const Text(
                                'Transaction',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                      ),
                      if (!_isSearchActive) ...[
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white, size: 22),
                          onPressed: () {
                            setState(() {
                              _isSearchActive = true;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: Color(0xFF00E5FF), size: 22),
                          onPressed: () => _showFiltersBottomSheet(context, ref, categories, paymentMethods, accounts),
                        ),
                      ] else
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 22),
                          onPressed: () {
                            ref.read(searchQueryProvider.notifier).state = '';
                            setState(() {
                              _isSearchActive = false;
                            });
                          },
                        ),
                    ],
                  ),
                ),

                // Period Selector
                _buildPeriodSelector(ref),
                const SizedBox(height: 12),

                // Filter Active Chips Row
                if (selectedCategory != null || 
                    selectedType != null || 
                    selectedPaymentMethod != null || 
                    selectedDateRange != null || 
                    selectedAccount != null ||
                    minAmount != null ||
                    maxAmount != null)
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (selectedType != null)
                          _buildFilterChip(
                            label: selectedType.toUpperCase(),
                            onClear: () => ref.read(filterTypeProvider.notifier).state = null,
                          ),
                        if (selectedCategory != null)
                          _buildFilterChip(
                            label: categoriesMap[selectedCategory]?.name ?? 'Category',
                            onClear: () => ref.read(filterCategoryProvider.notifier).state = null,
                          ),
                        if (selectedAccount != null)
                          _buildFilterChip(
                            label: accountsMap[selectedAccount]?.name ?? 'Account',
                            onClear: () => ref.read(filterAccountProvider.notifier).state = null,
                          ),
                        if (selectedPaymentMethod != null)
                          _buildFilterChip(
                            label: pmsMap[selectedPaymentMethod]?.name ?? 'Payment',
                            onClear: () => ref.read(filterPaymentMethodProvider.notifier).state = null,
                          ),
                        if (selectedDateRange != null)
                          _buildFilterChip(
                            label: activeDatePreset != 'custom' && activeDatePreset != null
                                ? activeDatePreset.replaceAll('_', ' ').toUpperCase()
                                : '${DateFormat('MM/dd').format(selectedDateRange.start)} - ${DateFormat('MM/dd').format(selectedDateRange.end)}',
                            onClear: () {
                              ref.read(filterDateRangeProvider.notifier).state = null;
                              ref.read(activeDatePresetProvider.notifier).state = 'all_time';
                            },
                          ),
                        if (minAmount != null)
                          _buildFilterChip(
                            label: 'Min: ₹${minAmount.toStringAsFixed(0)}',
                            onClear: () => ref.read(filterMinAmountProvider.notifier).state = null,
                          ),
                        if (maxAmount != null)
                          _buildFilterChip(
                            label: 'Max: ₹${maxAmount.toStringAsFixed(0)}',
                            onClear: () => ref.read(filterMaxAmountProvider.notifier).state = null,
                          ),
                      ],
                    ),
                  ),



                // Transaction List
                Expanded(
                  child: txsAsync.when(
                    data: (_) {
                      if (filteredTransactions.isEmpty) {
                        return ListView(
                          children: [
                            const SizedBox(height: 100),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 64, color: const Color(0xFF0066FF).withOpacity(0.3)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No transactions found',
                                    style: TextStyle(color: Colors.white38, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, dateIndex) {
                          final date = sortedDates[dateIndex];
                          final dayTxs = groupedTxs[date]!;
                          final formattedDate = _formatHeaderDate(date);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                                child: Text(
                                  formattedDate,
                                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                ),
                              ),
                              ...dayTxs.map((tx) {
                                final cat = tx.categoryId != null ? categoriesMap[tx.categoryId] : null;
                                final subCat = tx.subcategoryId != null ? categoriesMap[tx.subcategoryId] : null;
                                final pm = tx.paymentMethodId != null ? pmsMap[tx.paymentMethodId] : null;
                                final acc = tx.accountId != null ? accountsMap[tx.accountId] : null;
                                final isIncome = tx.type == 'income';
                                final isTransfer = tx.type == 'transfer_debit' || tx.type == 'transfer_credit';

                                Color catColor = const Color(0xFF0066FF);
                                if (isTransfer) {
                                  catColor = const Color(0xFFFFB703);
                                } else if (cat != null) {
                                  if (cat.color != null && cat.color!.isNotEmpty) {
                                    try {
                                      catColor = Color(int.parse(cat.color!));
                                    } catch (_) {}
                                  } else {
                                    catColor = CategoryIntelligence.getColorForName(cat.name);
                                  }
                                }

                                IconData catIcon = Icons.category_outlined;
                                if (isTransfer) {
                                  catIcon = Icons.swap_horiz;
                                } else if (cat != null) {
                                  catIcon = CategoryIntelligence.getIconForName(cat.name);
                                }

                                // Build trailing text color
                                Color amountColor = const Color(0xFFFF3B30);
                                String sign = '-';
                                if (isIncome || tx.type == 'transfer_credit') {
                                  amountColor = const Color(0xFF00E5FF);
                                  sign = '+';
                                } else if (tx.type == 'transfer_debit') {
                                  amountColor = const Color(0xFFFFB703);
                                  sign = '-';
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: catColor.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(catIcon, color: catColor, size: 20),
                                    ),
                                    title: Text(
                                      tx.description ?? tx.merchant ?? subCat?.name ?? cat?.name ?? 'Uncategorized',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${DateFormat('hh:mm a').format(tx.date)}${pm != null ? " • via ${pm.name}" : ""}${acc != null ? " • ${acc.displayTitle}" : ""}',
                                      style: const TextStyle(color: Colors.white30, fontSize: 12),
                                    ),
                                    trailing: PrivacyText(
                                      rawValue: sign + _formatMoney(tx.amount),
                                      isTransactionAmount: true,
                                      style: TextStyle(
                                        color: amountColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    onTap: () {
                                      if (tx.type == 'transfer_debit' || tx.type == 'transfer_credit') {
                                        _showTransferDetailsSheet(context, ref, tx, accountsMap);
                                      } else {
                                        _showTransactionActions(context, ref, tx);
                                      }
                                    },
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                    error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/expenses/add'),
          backgroundColor: const Color(0xFF0066FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onClear}) {
    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      child: InputChip(
        label: Text(label, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
        backgroundColor: const Color(0xFF0066FF).withOpacity(0.12),
        side: const BorderSide(color: Color(0xFF0066FF), width: 0.8),
        deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF00E5FF)),
        onDeleted: onClear,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatHeaderDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'TODAY';
    if (date == yesterday) return 'YESTERDAY';
    return DateFormat('EEEE, MMMM dd, yyyy').format(date).toUpperCase();
  }

  void _showTransferDetailsSheet(BuildContext context, WidgetRef ref, Transaction tx, Map<String, Account> accountsMap) async {
    final notifier = ref.read(expenseListNotifierProvider.notifier);
    final otherSide = await notifier.getOtherSideOfTransfer(tx);

    final debitTx = tx.type == 'transfer_debit' ? tx : otherSide;
    final creditTx = tx.type == 'transfer_credit' ? tx : otherSide;

    final fromAccount = debitTx != null ? accountsMap[debitTx.accountId] : null;
    final toAccount = creditTx != null ? accountsMap[creditTx.accountId] : null;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050505),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Transfer Details',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Centered Amount
                Center(
                  child: PrivacyText(
                    rawValue: NumberFormat.simpleCurrency(name: 'INR').format(tx.amount / 100.0),
                    isTransactionAmount: true,
                    style: const TextStyle(color: Color(0xFFFFB703), fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),

                // From / To layout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('FROM', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(
                              fromAccount?.displayTitle ?? 'Unknown',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFB703), size: 20),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('TO', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(
                              toAccount?.displayTitle ?? 'Unknown',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Date', style: TextStyle(color: Colors.white38, fontSize: 13)),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(tx.date),
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description if any
                if (tx.description != null && tx.description!.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Description', style: TextStyle(color: Colors.white38, fontSize: 13)),
                      Expanded(
                        child: Text(
                          tx.description!,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  const SizedBox(height: 12),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00E5FF),
                          side: const BorderSide(color: Color(0xFF00E5FF)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/expenses/edit/${tx.id}');
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('EDIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3B30),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(context, ref, tx.id, isTransfer: true);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, size: 16),
                            SizedBox(width: 8),
                            Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransactionActions(BuildContext context, WidgetRef ref, Transaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050505),
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
                leading: const Icon(Icons.edit_outlined, color: Colors.white70),
                title: const Text('Edit Transaction', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/expenses/edit/${tx.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
                title: const Text('Delete Transaction', style: TextStyle(color: Color(0xFFFF3B30))),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, tx.id);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, {bool isTransfer = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF0066FF), width: 1)),
        title: Text(isTransfer ? 'Delete Transfer' : 'Delete Transaction', style: const TextStyle(color: Colors.white)),
        content: Text(
          isTransfer 
              ? 'Are you sure you want to delete this transfer? Both linked transactions will be deleted and balances restored.'
              : 'Are you sure you want to delete this transaction? This action is reversible under soft-delete.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF0066FF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
            onPressed: () {
              Navigator.pop(context);
              ref.read(expenseListNotifierProvider.notifier).removeTransaction(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
    List<PaymentMethod> methods,
    List<Account> accounts,
  ) {
    // Mini temporary controllers for ranges
    final minVal = ref.read(filterMinAmountProvider);
    final maxVal = ref.read(filterMaxAmountProvider);
    final minController = TextEditingController(text: minVal != null ? minVal.toStringAsFixed(0) : '');
    final maxController = TextEditingController(text: maxVal != null ? maxVal.toStringAsFixed(0) : '');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Consumer(
                  builder: (context, ref, child) {
                    final currentType = ref.watch(filterTypeProvider);
                    final currentCategory = ref.watch(filterCategoryProvider);
                    final currentPM = ref.watch(filterPaymentMethodProvider);
                    final currentAccount = ref.watch(filterAccountProvider);
                    final activePreset = ref.watch(activeDatePresetProvider);
                    final currentRange = ref.watch(filterDateRangeProvider);
                    final sortBy = ref.watch(filterSortByProvider);
                    final presets = ref.watch(savedFiltersProvider);

                    final selectedCat = currentCategory != null
                        ? categories.firstWhere((c) => c.id == currentCategory, orElse: () => categories.first)
                        : null;
                    final selectedPM = currentPM != null
                        ? methods.firstWhere((p) => p.id == currentPM, orElse: () => methods.first)
                        : null;
                    final selectedAcc = currentAccount != null
                        ? accounts.firstWhere((a) => a.id == currentAccount, orElse: () => accounts.first)
                        : null;

                    return Stack(
                      children: [
                        // Scrollable filter inputs
                        Positioned.fill(
                          bottom: 84,
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Filter Transactions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),

                              // Saved Presets Section
                              if (presets.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('SAVED PRESETS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                    IconButton(
                                      icon: const Icon(Icons.bookmark_add_outlined, color: Color(0xFF00E5FF), size: 18),
                                      onPressed: () => _showSavePresetDialog(context, ref),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 38,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: presets.length,
                                    itemBuilder: (context, index) {
                                      final p = presets[index];
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        child: InputChip(
                                          label: Text(p.name, style: const TextStyle(fontSize: 12)),
                                          backgroundColor: const Color(0xFF0066FF).withOpacity(0.12),
                                          side: const BorderSide(color: Color(0xFF0066FF), width: 0.8),
                                          onPressed: () {
                                            ref.read(filterTypeProvider.notifier).state = p.type;
                                            ref.read(filterCategoryProvider.notifier).state = p.categoryId;
                                            ref.read(filterPaymentMethodProvider.notifier).state = p.paymentMethodId;
                                            ref.read(filterAccountProvider.notifier).state = p.accountId;
                                            ref.read(activeDatePresetProvider.notifier).state = p.datePreset;
                                            if (p.datePreset != null) {
                                              ref.read(filterDateRangeProvider.notifier).state = getDateRangeFromPreset(p.datePreset!);
                                            } else {
                                              ref.read(filterDateRangeProvider.notifier).state = p.dateRange;
                                            }
                                            ref.read(filterMinAmountProvider.notifier).state = p.minAmount;
                                            ref.read(filterMaxAmountProvider.notifier).state = p.maxAmount;
                                            ref.read(filterSortByProvider.notifier).state = p.sortBy;

                                            minController.text = p.minAmount != null ? p.minAmount!.toStringAsFixed(0) : '';
                                            maxController.text = p.maxAmount != null ? p.maxAmount!.toStringAsFixed(0) : '';
                                          },
                                          onDeleted: () {
                                            ref.read(savedFiltersProvider.notifier).removePreset(p.name);
                                          },
                                          deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF00E5FF)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Type Choice Chips
                              const Text('TRANSACTION TYPE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(child: Text('All')),
                                      selected: currentType == null,
                                      onSelected: (val) => ref.read(filterTypeProvider.notifier).state = null,
                                      selectedColor: const Color(0xFF00E5FF).withOpacity(0.15),
                                      backgroundColor: Colors.white.withOpacity(0.02),
                                      labelStyle: TextStyle(color: currentType == null ? const Color(0xFF00E5FF) : Colors.white60),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(child: Text('Expense')),
                                      selected: currentType == 'expense',
                                      onSelected: (val) => ref.read(filterTypeProvider.notifier).state = val ? 'expense' : null,
                                      selectedColor: const Color(0xFFFF3B30).withOpacity(0.15),
                                      backgroundColor: Colors.white.withOpacity(0.02),
                                      labelStyle: TextStyle(color: currentType == 'expense' ? const Color(0xFFFF3B30) : Colors.white60),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(child: Text('Income')),
                                      selected: currentType == 'income',
                                      onSelected: (val) => ref.read(filterTypeProvider.notifier).state = val ? 'income' : null,
                                      selectedColor: const Color(0xFF0066FF).withOpacity(0.15),
                                      backgroundColor: Colors.white.withOpacity(0.02),
                                      labelStyle: TextStyle(color: currentType == 'income' ? const Color(0xFF0066FF) : Colors.white60),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Category searchable card picker
                              _buildDropdownCard(
                                label: 'CATEGORY',
                                valueText: selectedCat != null ? selectedCat.name : 'All Categories',
                                icon: Icons.folder_open,
                                onTap: () => _showCategorySearchSheet(context, ref, categories),
                              ),
                              const SizedBox(height: 16),

                              // Account searchable card picker
                              _buildDropdownCard(
                                label: 'FINANCIAL ACCOUNT',
                                valueText: selectedAcc != null ? selectedAcc.name : 'All Accounts',
                                icon: Icons.account_balance_wallet,
                                onTap: () => _showAccountSearchSheet(context, ref, accounts),
                              ),
                              const SizedBox(height: 16),

                              // Payment Method searchable card picker
                              _buildDropdownCard(
                                label: 'PAYMENT METHOD',
                                valueText: selectedPM != null ? selectedPM.name : 'All Payment Methods',
                                icon: Icons.credit_card,
                                onTap: () => _showPmSearchSheet(context, ref, methods),
                              ),
                              const SizedBox(height: 24),

                              // Date presets row
                              const Text('DATE FILTER', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 38,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: {
                                    'all_time': 'All Time',
                                    'today': 'Today',
                                    'yesterday': 'Yesterday',
                                    'this_week': 'This Week',
                                    'this_month': 'This Month',
                                    'last_month': 'Last Month',
                                    'last_3_months': '3 Months',
                                    'last_6_months': '6 Months',
                                    'this_year': 'This Year',
                                    'custom': 'Custom Range',
                                  }.entries.map((entry) {
                                    final isSelected = activePreset == entry.key;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: ChoiceChip(
                                        label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                                        selected: isSelected,
                                        onSelected: (selected) async {
                                          if (selected) {
                                            ref.read(activeDatePresetProvider.notifier).state = entry.key;
                                            if (entry.key == 'custom') {
                                              final range = await showDateRangePicker(
                                                context: context,
                                                firstDate: DateTime(2020),
                                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                                builder: (context, child) {
                                                  return Theme(
                                                    data: ThemeData.dark().copyWith(
                                                      colorScheme: const ColorScheme.dark(
                                                        primary: Color(0xFF0066FF),
                                                        onPrimary: Colors.white,
                                                        surface: Color(0xFF050505),
                                                        onSurface: Colors.white,
                                                      ),
                                                    ),
                                                    child: child!,
                                                  );
                                                },
                                              );
                                              if (range != null) {
                                                ref.read(filterDateRangeProvider.notifier).state = range;
                                              } else {
                                                ref.read(activeDatePresetProvider.notifier).state = 'all_time';
                                                ref.read(filterDateRangeProvider.notifier).state = null;
                                              }
                                            } else {
                                              ref.read(filterDateRangeProvider.notifier).state = getDateRangeFromPreset(entry.key);
                                            }
                                          }
                                        },
                                        selectedColor: const Color(0xFF00E5FF).withOpacity(0.15),
                                        backgroundColor: Colors.white.withOpacity(0.02),
                                        labelStyle: TextStyle(
                                          color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              if (activePreset == 'custom' && currentRange != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Selected: ${DateFormat('MM/dd/yyyy').format(currentRange.start)} - ${DateFormat('MM/dd/yyyy').format(currentRange.end)}',
                                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13),
                                ),
                              ],
                              const SizedBox(height: 24),

                              // Min/Max Amount Range Inputs
                              const Text('AMOUNT RANGE (₹)', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.02),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                                      ),
                                      child: TextField(
                                        controller: minController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                        onChanged: (val) {
                                          ref.read(filterMinAmountProvider.notifier).state = double.tryParse(val);
                                        },
                                        decoration: const InputDecoration(
                                          hintText: 'Minimum',
                                          hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.02),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                                      ),
                                      child: TextField(
                                        controller: maxController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                        onChanged: (val) {
                                          ref.read(filterMaxAmountProvider.notifier).state = double.tryParse(val);
                                        },
                                        decoration: const InputDecoration(
                                          hintText: 'Maximum',
                                          hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Sort options
                              const Text('SORT TRANSACTIONS BY', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: {
                                  'newest': 'Newest First',
                                  'oldest': 'Oldest First',
                                  'highest': 'Highest Amount',
                                  'lowest': 'Lowest Amount',
                                }.entries.map((entry) {
                                  final isSelected = sortBy == entry.key;
                                  return ChoiceChip(
                                    label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        ref.read(filterSortByProvider.notifier).state = entry.key;
                                      }
                                    },
                                    selectedColor: const Color(0xFF0066FF).withOpacity(0.3),
                                    backgroundColor: Colors.white.withOpacity(0.02),
                                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        // Sticky Action Bar
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F0F0F),
                              border: Border(top: BorderSide(color: Colors.white10)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFFF3B30),
                                      side: const BorderSide(color: Color(0xFFFF3B30)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    onPressed: () {
                                      ref.read(filterTypeProvider.notifier).state = null;
                                      ref.read(filterCategoryProvider.notifier).state = null;
                                      ref.read(filterPaymentMethodProvider.notifier).state = null;
                                      ref.read(filterAccountProvider.notifier).state = null;
                                      ref.read(filterDateRangeProvider.notifier).state = null;
                                      ref.read(filterMinAmountProvider.notifier).state = null;
                                      ref.read(filterMaxAmountProvider.notifier).state = null;
                                      ref.read(filterSortByProvider.notifier).state = 'newest';
                                      ref.read(activeDatePresetProvider.notifier).state = 'all_time';

                                      minController.clear();
                                      maxController.clear();
                                      setSheetState(() {});
                                    },
                                    child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0066FF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownCard({
    required String label,
    required String valueText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF00E5FF), size: 18),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 2),
                    Text(valueText, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(WidgetRef ref) {
    final periods = ['Today', 'Week', 'Month', 'Last Month', '3M', '6M', '1Y', 'Custom'];
    final activePreset = ref.watch(activeDatePresetProvider);

    String presetForPeriod(String period) {
      switch (period) {
        case 'Today': return 'today';
        case 'Week': return 'this_week';
        case 'Month': return 'this_month';
        case 'Last Month': return 'last_month';
        case '3M': return 'last_3_months';
        case '6M': return 'last_6_months';
        case '1Y': return 'this_year';
        case 'Custom': return 'custom';
        default: return 'all_time';
      }
    }

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
          final preset = presetForPeriod(p);
          final isSelected = activePreset == preset;
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
                    ref.read(activeDatePresetProvider.notifier).state = 'custom';
                    ref.read(filterDateRangeProvider.notifier).state = range;
                  }
                } else {
                  ref.read(activeDatePresetProvider.notifier).state = preset;
                  ref.read(filterDateRangeProvider.notifier).state = getDateRangeFromPreset(preset);
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
}
