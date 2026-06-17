import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../../core/database/app_database.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final txsAsync = ref.watch(expenseListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    // Watch filter states
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(filterCategoryProvider);
    final selectedType = ref.watch(filterTypeProvider);
    final selectedPaymentMethod = ref.watch(filterPaymentMethodProvider);
    final selectedDateRange = ref.watch(filterDateRangeProvider);

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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF002D27), Colors.black],
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transactions',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.tealAccent),
                      onPressed: () => _showFiltersBottomSheet(context, ref),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: TextField(
                    onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                    controller: TextEditingController(text: searchQuery)..selection = TextSelection.fromPosition(TextPosition(offset: searchQuery.length)),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search description, merchant...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(Icons.search, color: Colors.white60),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white60),
                              onPressed: () {
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Active Chips Row
              if (selectedCategory != null || selectedType != null || selectedPaymentMethod != null || selectedDateRange != null)
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
                        categoriesAsync.maybeWhen(
                          data: (cats) {
                            final cat = cats.firstWhere((c) => c.id == selectedCategory);
                            return _buildFilterChip(
                              label: cat.name,
                              onClear: () => ref.read(filterCategoryProvider.notifier).state = null,
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                      if (selectedPaymentMethod != null)
                        paymentMethodsAsync.maybeWhen(
                          data: (pms) {
                            final pm = pms.firstWhere((p) => p.id == selectedPaymentMethod);
                            return _buildFilterChip(
                              label: pm.name,
                              onClear: () => ref.read(filterPaymentMethodProvider.notifier).state = null,
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                      if (selectedDateRange != null)
                        _buildFilterChip(
                          label: '${DateFormat('MM/dd').format(selectedDateRange.start)} - ${DateFormat('MM/dd').format(selectedDateRange.end)}',
                          onClear: () => ref.read(filterDateRangeProvider.notifier).state = null,
                        ),
                    ],
                  ),
                ),

              // Summary Info Card
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00241F).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total In: ${_formatMoney(totalIncomeShown)}',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total Out: ${_formatMoney(totalExpenseShown)}',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
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
                                Icon(Icons.receipt_long, size: 64, color: Colors.teal.withOpacity(0.3)),
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

                    return Consumer(
                      builder: (context, ref, child) {
                        final categories = categoriesAsync.maybeWhen(
                          data: (c) => c,
                          orElse: () => <Category>[],
                        );
                        final pms = paymentMethodsAsync.maybeWhen(
                          data: (p) => p,
                          orElse: () => <PaymentMethod>[],
                        );

                        final categoriesMap = {for (var c in categories) c.id: c};
                        final pmsMap = {for (var p in pms) p.id: p};

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
                                    style: TextStyle(color: Colors.teal.shade200, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                  ),
                                ),
                                ...dayTxs.map((tx) {
                                  final cat = tx.categoryId != null ? categoriesMap[tx.categoryId] : null;
                                  final pm = tx.paymentMethodId != null ? pmsMap[tx.paymentMethodId] : null;
                                  final isIncome = tx.type == 'income';
                                  final catColor = IconMapper.getColor(cat?.icon);
                                  final catIcon = IconMapper.getIcon(cat?.icon);

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
                                          color: catColor.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(catIcon, color: catColor, size: 20),
                                      ),
                                      title: Text(
                                        tx.description ?? tx.merchant ?? cat?.name ?? 'Uncategorized',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${DateFormat('hh:mm a').format(tx.date)}${pm != null ? " • via ${pm.name}" : ""}',
                                        style: const TextStyle(color: Colors.white30, fontSize: 12),
                                      ),
                                      trailing: Text(
                                        (isIncome ? '+' : '-') + _formatMoney(tx.amount),
                                        style: TextStyle(
                                          color: isIncome ? Colors.greenAccent : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      onTap: () => _showTransactionActions(context, ref, tx),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.teal)),
                  error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/expenses/add'),
        backgroundColor: Colors.tealAccent.shade400,
        foregroundColor: const Color(0xFF00241F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onClear}) {
    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      child: InputChip(
        label: Text(label, style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
        backgroundColor: const Color(0xFF00241F).withOpacity(0.4),
        side: const BorderSide(color: Colors.tealAccent, width: 0.8),
        deleteIcon: const Icon(Icons.close, size: 14, color: Colors.tealAccent),
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

  void _showTransactionActions(BuildContext context, WidgetRef ref, Transaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
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
                leading: const Icon(Icons.edit, color: Colors.white70),
                title: const Text('Edit Transaction', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/expenses/edit/${tx.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete Transaction', style: TextStyle(color: Colors.redAccent)),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Delete Transaction', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this transaction? This action is reversible under soft-delete.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.teal)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  void _showFiltersBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final categoriesAsync = ref.watch(categoriesProvider);
            final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

            final currentType = ref.watch(filterTypeProvider);
            final currentCategory = ref.watch(filterCategoryProvider);
            final currentPM = ref.watch(filterPaymentMethodProvider);

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.85,
              minChildSize: 0.4,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filter Transactions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            ref.read(filterTypeProvider.notifier).state = null;
                            ref.read(filterCategoryProvider.notifier).state = null;
                            ref.read(filterPaymentMethodProvider.notifier).state = null;
                            ref.read(filterDateRangeProvider.notifier).state = null;
                            Navigator.pop(context);
                          },
                          child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),

                    // Filter by Type
                    const Text('Transaction Type', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFilterChoiceChip(
                          label: 'Expense',
                          selected: currentType == 'expense',
                          onSelected: (selected) {
                            ref.read(filterTypeProvider.notifier).state = selected ? 'expense' : null;
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChoiceChip(
                          label: 'Income',
                          selected: currentType == 'income',
                          onSelected: (selected) {
                            ref.read(filterTypeProvider.notifier).state = selected ? 'income' : null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Filter by Date Range
                    const Text('Date Range', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: Colors.tealAccent),
                      title: const Text('Select custom date range', style: TextStyle(color: Colors.white70)),
                      subtitle: Consumer(
                        builder: (context, ref, child) {
                          final range = ref.watch(filterDateRangeProvider);
                          if (range == null) return const Text('All Time', style: TextStyle(color: Colors.white30));
                          return Text('${DateFormat('MM/dd/yyyy').format(range.start)} - ${DateFormat('MM/dd/yyyy').format(range.end)}', style: const TextStyle(color: Colors.tealAccent));
                        },
                      ),
                      onTap: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: Colors.teal,
                                  onPrimary: Colors.white,
                                  surface: Colors.grey.shade900,
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (range != null) {
                          ref.read(filterDateRangeProvider.notifier).state = range;
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Filter by Category
                    const Text('Category', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    categoriesAsync.when(
                      data: (cats) {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: cats.map((cat) {
                            final isSelected = cat.id == currentCategory;
                            return ChoiceChip(
                              label: Text(cat.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                ref.read(filterCategoryProvider.notifier).state = selected ? cat.id : null;
                              },
                              selectedColor: Colors.teal.shade800,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => const Text('Error loading categories', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(height: 20),

                    // Filter by Payment Method
                    const Text('Payment Method', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    paymentMethodsAsync.when(
                      data: (methods) {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: methods.map((pm) {
                            final isSelected = pm.id == currentPM;
                            return ChoiceChip(
                              label: Text(pm.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                ref.read(filterPaymentMethodProvider.notifier).state = selected ? pm.id : null;
                              },
                              selectedColor: Colors.teal.shade800,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => const Text('Error loading payment methods', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChoiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.teal.shade800,
      backgroundColor: Colors.white.withOpacity(0.05),
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
