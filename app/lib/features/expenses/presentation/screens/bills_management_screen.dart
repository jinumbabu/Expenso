import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../providers/expense_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/account_formatters.dart';

final subscriptionsStreamProvider = StreamProvider.autoDispose<List<Subscription>>((ref) {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return const Stream.empty();
  return db.subscriptionDao.watchSubscriptionsForUser(userId);
});

final billsStreamProvider = StreamProvider.autoDispose<List<Bill>>((ref) {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return const Stream.empty();
  return (db.select(db.bills)
    ..where((b) => b.userId.equals(userId))
  ).watch();
});

class BillsManagementScreen extends ConsumerStatefulWidget {
  const BillsManagementScreen({super.key});

  @override
  ConsumerState<BillsManagementScreen> createState() => _BillsManagementScreenState();
}

class _BillsManagementScreenState extends ConsumerState<BillsManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortBy = 'due_date_asc'; // 'due_date_asc', 'due_date_desc', 'amount_asc', 'amount_desc', 'category'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Bill> _filterAndSortBills(List<Bill> bills, {required bool isPaid, bool? isOverdue}) {
    var filtered = bills.toList();

    // Filter by paid status
    if (isPaid) {
      filtered = filtered.where((tx) => tx.status == 'paid').toList();
    } else {
      filtered = filtered.where((tx) => tx.status != 'paid').toList();
      
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      if (isOverdue == true) {
        filtered = filtered.where((tx) {
          final due = tx.dueDate ?? tx.createdAt;
          final dueDate = DateTime(due.year, due.month, due.day);
          return dueDate.isBefore(todayDate);
        }).toList();
      } else if (isOverdue == false) {
        filtered = filtered.where((tx) {
          final due = tx.dueDate ?? tx.createdAt;
          final dueDate = DateTime(due.year, due.month, due.day);
          return !dueDate.isBefore(todayDate);
        }).toList();
      }
    }

    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tx) {
        final title = tx.title.toLowerCase();
        return title.contains(_searchQuery);
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      if (_sortBy == 'due_date_asc') {
        final da = a.dueDate ?? a.createdAt;
        final db = b.dueDate ?? b.createdAt;
        return da.compareTo(db);
      } else if (_sortBy == 'due_date_desc') {
        final da = a.dueDate ?? a.createdAt;
        final db = b.dueDate ?? b.createdAt;
        return db.compareTo(da);
      } else if (_sortBy == 'amount_asc') {
        return a.amount.compareTo(b.amount);
      } else if (_sortBy == 'amount_desc') {
        return b.amount.compareTo(a.amount);
      }
      return 0;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billsStreamProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final subscriptionsAsync = ref.watch(subscriptionsStreamProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final categories = categoriesAsync.value ?? [];
    final accounts = accountsAsync.value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        title: const Text('Bills Management', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0066FF),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Overdue'),
            Tab(text: 'Paid'),
            Tab(text: 'Recurring'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF080808),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search bills...',
                            hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                            prefixIcon: Icon(Icons.search, color: Colors.white30, size: 16),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Sort Dropdown
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          dropdownColor: const Color(0xFF0C0C0C),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                          items: const [
                            DropdownMenuItem(value: 'due_date_asc', child: Text('Due Date (Earliest)')),
                            DropdownMenuItem(value: 'due_date_desc', child: Text('Due Date (Latest)')),
                            DropdownMenuItem(value: 'amount_asc', child: Text('Amount (Low to High)')),
                            DropdownMenuItem(value: 'amount_desc', child: Text('Amount (High to Low)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _sortBy = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Category Dropdown
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedCategory,
                          dropdownColor: const Color(0xFF0C0C0C),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                          hint: const Text('All Categories', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Categories')),
                            ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Bills List tabs
          Expanded(
            child: billsAsync.when(
              data: (billsList) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Upcoming Tab
                    _buildBillList(_filterAndSortBills(billsList, isPaid: false, isOverdue: false), accounts),
                    // Overdue Tab
                    _buildBillList(_filterAndSortBills(billsList, isPaid: false, isOverdue: true), accounts, isOverdueMode: true),
                    // Paid Tab
                    _buildBillList(_filterAndSortBills(billsList, isPaid: true), accounts),
                    // Recurring Tab
                    subscriptionsAsync.when(
                      data: (subs) {
                        return _buildRecurringList(subs, [], categories);
                      },
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillList(List<Bill> bills, List<Account> accounts, {bool isOverdueMode = false}) {
    debugPrint('BillsManagementScreen DEBUG: Rendering bill list. Count: ${bills.length}, isOverdueMode: $isOverdueMode');

    if (bills.isEmpty) {
      String reason = 'No bills matching filter criteria.';
      if (isOverdueMode) {
        reason = 'No overdue bills found in the database.';
      } else {
        reason = 'No pending bills found in the database. Try scanning SMS alerts.';
      }
      debugPrint('BillsManagementScreen DEBUG: Bills list is empty. Reason: $reason');
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, color: Colors.white10, size: 48),
              const SizedBox(height: 12),
              Text(
                isOverdueMode ? 'No overdue bills!' : 'No matching bills found',
                style: const TextStyle(color: Colors.white30, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'Debug Info: $reason',
                style: const TextStyle(color: Colors.white12, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        final matchedAccs = accounts.where((a) => a.id == bill.accountId);
        final Account? acc = matchedAccs.isNotEmpty ? matchedAccs.first : null;
        
        var iconColor = const Color(0xFFFFB703);
        var iconData = Icons.receipt_long;
        var subText = 'Utility Bill';
        if (acc != null) {
          iconColor = Color(int.tryParse(acc.colorTheme ?? '0xFFFFB703') ?? 0xFFFFB703);
          iconData = IconMapper.getIcon(acc.icon ?? 'credit_card');
          subText = acc.displayTitle;
        }
        
        final due = bill.dueDate ?? bill.createdAt;
        final formattedDue = DateFormat('dd MMM yyyy').format(due);
        final daysLeft = due.difference(DateTime.now()).inDays;
        
        String dueSubtitle = 'Due in $daysLeft days';
        if (daysLeft == 0) dueSubtitle = 'Due Today';
        if (daysLeft < 0) dueSubtitle = 'Overdue by ${daysLeft.abs()} days';

        final isOverdue = daysLeft < 0 && bill.status != 'paid';
        final isPaid = bill.status == 'paid';
        final isSms = true;

        return GestureDetector(
          onTap: () => context.push('/bills/${bill.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.015),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bill.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSms) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SMS',
                                style: TextStyle(color: Colors.teal, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            isPaid ? 'Paid on $formattedDue' : dueSubtitle,
                            style: TextStyle(
                              color: isPaid 
                                  ? const Color(0xFF00FF88) 
                                  : (isOverdue ? const Color(0xFFFF3B30) : const Color(0xFF00E5FF)),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'OVERDUE',
                                style: TextStyle(color: Color(0xFFFF3B30), fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${(bill.amount / 100.0).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subText,
                      style: const TextStyle(color: Colors.white30, fontSize: 10),
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

  Widget _buildRecurringList(List<Subscription> subscriptions, List<Transaction> recurringTxs, List<Category> categories) {
    final totalCount = subscriptions.length + recurringTxs.length;
    if (totalCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.loop_outlined, color: Colors.white10, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No recurring bills or subscriptions',
              style: TextStyle(color: Colors.white30, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        final isSub = index < subscriptions.length;
        String title = '';
        double amount = 0.0;
        String cycleText = '';
        String logoChar = '';

        if (isSub) {
          final sub = subscriptions[index];
          title = sub.title;
          amount = sub.monthlyCost / 100.0;
          cycleText = 'Subscription • Renewal: ${DateFormat('dd MMM').format(sub.renewalDate)}';
          logoChar = title.isNotEmpty ? title[0].toUpperCase() : 'S';
        } else {
          final tx = recurringTxs[index - subscriptions.length];
          title = tx.merchant ?? tx.description ?? 'Recurring Bill';
          amount = tx.amount / 100.0;
          cycleText = 'Recurring Expense • Due: ${DateFormat('dd MMM').format(tx.dueDate ?? tx.date)}';
          logoChar = title.isNotEmpty ? title[0].toUpperCase() : 'R';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.015),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    logoChar,
                    style: const TextStyle(
                      color: Color(0xFF0066FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cycleText,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
