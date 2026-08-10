import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../providers/calendar_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  int _slideDirection = 1; // 1 for next month, -1 for previous month

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }

  void _updateMonth(DateTime newMonth, CalendarNotifier notifier) {
    setState(() {
      _slideDirection = newMonth.isAfter(_currentMonth) ? 1 : -1;
      _currentMonth = newMonth;
    });

    // Auto-select a date in the new month
    final today = DateTime.now();
    DateTime newSelectedDate;
    if (newMonth.year == today.year && newMonth.month == today.month) {
      newSelectedDate = today;
    } else {
      newSelectedDate = DateTime(newMonth.year, newMonth.month, 1);
    }
    notifier.setSelectedDate(newSelectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarProvider);
    final calendarNotifier = ref.read(calendarProvider.notifier);
    
    final txsAsync = ref.watch(expenseListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final txs = txsAsync.maybeWhen(data: (list) => list, orElse: () => <Transaction>[]);
    final categories = categoriesAsync.maybeWhen(data: (list) => list, orElse: () => <Category>[]);
    final categoriesMap = {for (var c in categories) c.id: c};

    // Selected date details
    final selectedDate = calendarState.selectedDate;

    // Filter transactions to selected date
    final dayTxs = txs.where((t) =>
        t.date.day == selectedDate.day &&
        t.date.month == selectedDate.month &&
        t.date.year == selectedDate.year).toList();

    // Calculate daily income & expenses
    int totalIncome = 0;
    int totalExpense = 0;
    for (var tx in dayTxs) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        totalExpense += tx.amount;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF02070F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF030D1E), Color(0xFF010204)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              Expanded(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Income & Expense Summary Cards
                    _buildSummaryCards(totalIncome, totalExpense),
                    const SizedBox(height: 16),

                    // Calendar
                    _buildCalendarCard(
                      context,
                      calendarState,
                      calendarNotifier,
                      txs,
                    ),
                    const SizedBox(height: 24),

                    // Timeline Log
                    _buildTimelineLog(selectedDate, txs, categoriesMap),
                    const SizedBox(height: 24),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Text(
            'Calendar Intelligence',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(int totalIncome, int totalExpense) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Income',
            amount: totalIncome,
            isIncome: true,
            color: const Color(0xFF00E5FF),
            icon: Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Expenses',
            amount: totalExpense,
            isIncome: false,
            color: const Color(0xFFFF3B30),
            icon: Icons.arrow_upward,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int amount,
    required bool isIncome,
    required Color color,
    required IconData icon,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      borderRadius: 20,
      borderColor: color.withOpacity(0.15),
      gradientColors: [
        color.withOpacity(0.04),
        Colors.black.withOpacity(0.4),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (isIncome ? '+' : '-') + _formatMoney(amount),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(
    BuildContext context,
    CalendarState state,
    CalendarNotifier notifier,
    List<Transaction> txs,
  ) {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    
    final int daysInMonth = lastDayOfMonth.day;
    final int weekdayOfFirst = firstDayOfMonth.weekday % 7; // Sunday start: 0, Mon: 1...

    final totalGridCells = daysInMonth + weekdayOfFirst;
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return GlassCard(
      borderRadius: 24,
      borderColor: const Color(0xFF00E5FF).withOpacity(0.15),
      gradientColors: [
        const Color(0xFF0A1121).withOpacity(0.85),
        const Color(0xFF030814).withOpacity(0.95),
      ],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Month Header: ◀ JULY 2026 ▶
          _buildMonthHeader(context, notifier),
          const SizedBox(height: 12),
          // Weekdays row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((w) {
              return SizedBox(
                width: 32,
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Animated Grid
          ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(_slideDirection * 1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: GridView.builder(
                key: ValueKey<DateTime>(_currentMonth),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: totalGridCells,
                itemBuilder: (context, index) {
                  if (index < weekdayOfFirst) {
                    return const SizedBox.shrink();
                  }

                  final day = index - weekdayOfFirst + 1;
                  final dayDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                  final isSelected = state.selectedDate.day == day &&
                      state.selectedDate.month == _currentMonth.month &&
                      state.selectedDate.year == _currentMonth.year;
                  
                  final today = DateTime.now();
                  final isToday = dayDate.day == today.day &&
                      dayDate.month == today.month &&
                      dayDate.year == today.year;

                  // Find daily transactions for indicators
                  final dayTransactions = txs.where((tx) =>
                      tx.date.day == day &&
                      tx.date.month == _currentMonth.month &&
                      tx.date.year == _currentMonth.year).toList();

                  final hasIncome = dayTransactions.any((tx) => tx.type == 'income');
                  final hasExpense = dayTransactions.any((tx) => tx.type == 'expense');

                  Widget? indicator;
                  if (hasIncome && hasExpense) {
                    indicator = Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD500F9), // Purple dot
                        shape: BoxShape.circle,
                      ),
                    );
                  } else if (hasIncome) {
                    indicator = Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E5FF), // Cyan dot
                        shape: BoxShape.circle,
                      ),
                    );
                  } else if (hasExpense) {
                    indicator = Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30), // Red dot
                        shape: BoxShape.circle,
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      notifier.setSelectedDate(dayDate);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00E5FF)
                            : (isToday ? Colors.white.withOpacity(0.04) : Colors.transparent),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00E5FF)
                              : (isToday ? const Color(0xFF00E5FF).withOpacity(0.8) : Colors.transparent),
                          width: isSelected ? 2.0 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]
                            : (isToday
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withOpacity(0.2),
                                      blurRadius: 6,
                                      spreadRadius: 0.5,
                                    )
                                  ]
                                : null),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF02070F) : Colors.white,
                              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          indicator ?? const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, CalendarNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 24),
            onPressed: () {
              final newMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
              _updateMonth(newMonth, notifier);
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showMonthYearPicker(context, notifier),
            child: Text(
              DateFormat('MMMM yyyy').format(_currentMonth).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
            onPressed: () {
              final newMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
              _updateMonth(newMonth, notifier);
            },
          ),
        ],
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context, CalendarNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF030D1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final months = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white70),
                        onPressed: () {
                          setModalState(() {
                            _currentMonth = DateTime(_currentMonth.year - 1, _currentMonth.month, 1);
                          });
                        },
                      ),
                      Text(
                        '${_currentMonth.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white70),
                        onPressed: () {
                          setModalState(() {
                            _currentMonth = DateTime(_currentMonth.year + 1, _currentMonth.month, 1);
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthName = months[index];
                      final isSelected = _currentMonth.month == index + 1;
                      
                      return GestureDetector(
                        onTap: () {
                          final newMonth = DateTime(_currentMonth.year, index + 1, 1);
                          Navigator.pop(context);
                          _updateMonth(newMonth, notifier);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00E5FF).withOpacity(0.2)
                                : Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white.withOpacity(0.05),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              monthName.substring(0, 3).toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineLog(
    DateTime selectedDate,
    List<Transaction> txs,
    Map<String, Category> categoriesMap,
  ) {
    final dayTxs = txs.where((t) =>
        t.date.day == selectedDate.day &&
        t.date.month == selectedDate.month &&
        t.date.year == selectedDate.year).toList();

    dayTxs.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timeline Log',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('dd MMMM yyyy').format(selectedDate),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        if (dayTxs.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayTxs.length,
            itemBuilder: (context, index) {
              final tx = dayTxs[index];
              return _buildTransactionCard(tx, categoriesMap);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: Colors.white12,
            ),
            const SizedBox(height: 12),
            const Text(
              'No transactions found.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction tx, Map<String, Category> categoriesMap) {
    final isIncome = tx.type == 'income';
    final amtColor = isIncome ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30);
    final cat = tx.categoryId != null ? categoriesMap[tx.categoryId] : null;
    final catColor = IconMapper.getColor(cat?.icon);
    final catIcon = IconMapper.getIcon(cat?.icon);

    return GestureDetector(
      onTap: () => _showTransactionDetailsSheet(context, tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1121).withOpacity(0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.04),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                catIcon,
                color: catColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.merchant ?? tx.description ?? cat?.name ?? 'Transaction',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('hh:mm a').format(tx.date),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              (isIncome ? '+' : '-') + _formatMoney(tx.amount.toInt()),
              style: TextStyle(
                color: amtColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferDetailsSheet(BuildContext context, Transaction tx) async {
    final notifier = ref.read(expenseListNotifierProvider.notifier);
    final otherSide = await notifier.getOtherSideOfTransfer(tx);

    final debitTx = tx.type == 'transfer_debit' ? tx : otherSide;
    final creditTx = tx.type == 'transfer_credit' ? tx : otherSide;

    final accounts = ref.read(accountsProvider).value ?? [];
    final accountsMap = {for (var a in accounts) a.id: a};

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
                  child: Text(
                    _formatMoney(tx.amount.toInt()),
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
                              fromAccount?.name ?? 'Unknown',
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
                              toAccount?.name ?? 'Unknown',
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
                        onPressed: () async {
                          Navigator.pop(context);
                          final deleteConfirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF050505),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF0066FF), width: 1)),
                              title: const Text('Delete Transfer', style: TextStyle(color: Colors.white)),
                              content: const Text('Are you sure you want to delete this transfer? Both linked transactions will be deleted and balances restored.', style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF0066FF))),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (deleteConfirm == true) {
                            await ref.read(expenseListNotifierProvider.notifier).removeTransaction(tx.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer deleted.')));
                            }
                          }
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

  void _showTransactionDetailsSheet(BuildContext context, Transaction tx) {
    if (tx.type == 'transfer_debit' || tx.type == 'transfer_credit') {
      _showTransferDetailsSheet(context, tx);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF091224),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            final isIncome = tx.type == 'income';
            
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  tx.merchant ?? tx.description ?? 'Transaction Detail',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatMoney(tx.amount.toInt()),
                  style: TextStyle(color: isIncome ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30), fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildDetailRow(Icons.category, 'Category', tx.categoryId ?? 'Uncategorized'),
                _buildDetailRow(Icons.payment, 'Payment Method', tx.paymentMethodId ?? 'UPI'),
                _buildDetailRow(Icons.calendar_today, 'Date', DateFormat('dd MMMM yyyy, hh:mm a').format(tx.date)),
                if (tx.referenceNumber != null)
                  _buildDetailRow(Icons.tag, 'Reference No', tx.referenceNumber!),
                if (tx.aiClassification != null)
                  _buildDetailRow(Icons.psychology, 'AI Classification', tx.aiClassification!),
                
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(Icons.edit, 'Edit', () {
                      Navigator.pop(context);
                      context.push('/expenses/edit/${tx.id}');
                    }),
                    _buildActionButton(Icons.delete, 'Delete', () {
                      ref.read(expenseListNotifierProvider.notifier).removeTransaction(tx.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted.')));
                    }),
                    _buildActionButton(Icons.copy, 'Copy', () {
                      final details = 'Transaction: ${tx.merchant ?? tx.description} - Amount: ${_formatMoney(tx.amount.toInt())} on ${tx.date.toIso8601String()}';
                      Clipboard.setData(ClipboardData(text: details));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction details copied to clipboard.')));
                    }),
                  ],
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
