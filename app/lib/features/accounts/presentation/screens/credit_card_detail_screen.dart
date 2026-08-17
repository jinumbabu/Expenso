import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/privacy_text.dart';
import '../../../../shared/widgets/reusable_donut_chart.dart';
import '../../../../shared/widgets/reusable_net_worth_ring.dart';
import '../../../../shared/utils/analytics_formatter.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../expenses/presentation/screens/bills_management_screen.dart'; // for billsStreamProvider
import '../providers/accounts_provider.dart';
import '../../../dashboard/presentation/providers/privacy_provider.dart';
import '../../../analytics/presentation/models/analytics_chart_data.dart';

class CreditCardDetailScreen extends ConsumerStatefulWidget {
  final String? initialCardId;

  const CreditCardDetailScreen({super.key, this.initialCardId});

  @override
  ConsumerState<CreditCardDetailScreen> createState() => _CreditCardDetailScreenState();
}

class _CreditCardDetailScreenState extends ConsumerState<CreditCardDetailScreen> {
  // Navigation level: 1 = Dashboard, 2 = Analytics, 3 = Category Detail
  int _navigationLevel = 1;

  // Selected card filter ('all' or specific card account id)
  String _selectedCardId = 'all';

  // State for Page 2 (Analytics)
  String _selectedPeriod = 'Month';
  DateTimeRange? _customDateRange;
  String _breakdownMode = 'Category'; // Category, Account, Payment Type
  String _selectedCategoryId = '';
  String _selectedSubExpenseId = '';
  
  // Anchors for period navigation on Page 2
  late DateTime _anchorToday;
  late DateTime _anchorWeek;
  late DateTime _anchorMonth;
  late DateTime _anchorLastMonth;
  late DateTime _anchor3M;
  late DateTime _anchor6M;
  late DateTime _anchor1Y;
  
  late ScrollController _categoryScrollController;
  late ScrollController _subExpenseScrollController;
  final Map<String, GlobalKey> _categoryKeys = {};
  final Map<String, GlobalKey> _subExpenseKeys = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchorToday = DateTime(now.year, now.month, now.day);
    _anchorWeek = _anchorToday.subtract(Duration(days: _anchorToday.weekday - 1));
    _anchorMonth = DateTime(now.year, now.month, 1);
    _anchorLastMonth = DateTime(now.year, now.month - 1, 1);
    _anchor3M = _anchorToday;
    _anchor6M = _anchorToday;
    _anchor1Y = _anchorToday;
    
    _categoryScrollController = ScrollController();
    _subExpenseScrollController = ScrollController();

    if (widget.initialCardId != null) {
      _selectedCardId = widget.initialCardId!;
      _navigationLevel = 2;
    }
  }

  @override
  void didUpdateWidget(covariant CreditCardDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCardId != oldWidget.initialCardId && widget.initialCardId != null) {
      setState(() {
        _selectedCardId = widget.initialCardId!;
        _navigationLevel = 2;
        _selectedCategoryId = '';
      });
    }
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    _subExpenseScrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String categoryId, int index) {
    if (index < 0) return;
    final key = _categoryKeys[categoryId];
    if (key == null) return;

    const double estimatedHeight = 66.0; // 58.0 card height + 8.0 separator
    final double targetOffset = index * estimatedHeight;

    if (_categoryScrollController.hasClients) {
      _categoryScrollController.animateTo(
        targetOffset.clamp(0.0, _categoryScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ).then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              alignment: 0.0,
            );
          }
        });
      });
    }
  }

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }



  // Color mapping functions
  Color _getCategoryColor(String? icon) {
    if (icon != null && icon.isNotEmpty) {
      if (icon.contains('fastfood') || icon.contains('dining') || icon.contains('food')) return Colors.orange;
      if (icon.contains('shopping') || icon.contains('cart')) return Colors.purple;
      if (icon.contains('commute') || icon.contains('car') || icon.contains('cab')) return Colors.blue;
      if (icon.contains('movie') || icon.contains('tv') || icon.contains('game')) return Colors.pink;
      if (icon.contains('home') || icon.contains('rent')) return Colors.green;
      if (icon.contains('health') || icon.contains('med')) return Colors.red;
    }
    return const Color(0xFF0066FF);
  }

  Color _getPaymentMethodColor(String type) {
    switch (type.toLowerCase()) {
      case 'upi':
        return const Color(0xFF00E5FF);
      case 'net_banking':
      case 'net banking':
        return const Color(0xFF0066FF);
      default:
        return const Color(0xFFFFB703);
    }
  }

  Color _getCardColor(String? colorStr) {
    if (colorStr != null && colorStr.isNotEmpty) {
      try {
        return Color(int.parse(colorStr));
      } catch (_) {}
    }
    return const Color(0xFFFF3B30); // Default Credit Card Red
  }

  String _getUtilisationStatusText(double pct) {
    if (pct <= 30.0) return 'HEALTHY UTILISATION';
    if (pct <= 50.0) return 'MODERATE UTILISATION';
    if (pct <= 70.0) return 'HIGH UTILISATION';
    if (pct <= 90.0) return 'VERY HIGH UTILISATION';
    if (pct <= 100.0) return 'CRITICAL UTILISATION';
    return 'OVER LIMIT';
  }

  Color _getUtilisationStatusColor(double pct) {
    if (pct <= 30.0) return const Color(0xFF00FF88);
    if (pct <= 50.0) return const Color(0xFF00E5FF);
    if (pct <= 70.0) return const Color(0xFFFF9500);
    if (pct <= 90.0) return const Color(0xFFFF5E00);
    return const Color(0xFFFF3B30);
  }

  String _formatDueDays(DateTime dueDate, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;
    
    if (diff < 0) {
      return 'Overdue by ${diff.abs()} day${diff.abs() > 1 ? "s" : ""}';
    } else if (diff == 0) {
      return 'Due today';
    } else if (diff == 1) {
      return 'Due tomorrow';
    } else {
      return 'Dues in $diff days';
    }
  }

  Color _getDueDaysColor(DateTime dueDate, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;
    
    if (diff < 0) {
      return const Color(0xFFFF3B30);
    } else if (diff <= 3) {
      return const Color(0xFFFF9500);
    } else {
      return const Color(0xFF00E5FF);
    }
  }

  bool _canGoForward(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (period) {
      case 'Today':
        return _anchorToday.isBefore(today);
      case 'Week':
        final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
        return _anchorWeek.isBefore(currentWeekStart);
      case 'Month':
        final currentMonthStart = DateTime(today.year, today.month, 1);
        return _anchorMonth.isBefore(currentMonthStart);
      case 'Last Month':
        final currentMonthStart = DateTime(today.year, today.month, 1);
        return _anchorLastMonth.isBefore(currentMonthStart);
      case '1Y':
        final currentMonthStart = DateTime(today.year, today.month, 1);
        return _anchor1Y.isBefore(currentMonthStart);
      default:
        return false;
    }
  }

  void _goForward(String period) {
    setState(() {
      switch (period) {
        case 'Today':
          _anchorToday = _anchorToday.add(const Duration(days: 1));
          break;
        case 'Week':
          _anchorWeek = _anchorWeek.add(const Duration(days: 7));
          break;
        case 'Month':
          _anchorMonth = DateTime(_anchorMonth.year, _anchorMonth.month + 1, 1);
          break;
        case 'Last Month':
          _anchorLastMonth = DateTime(_anchorLastMonth.year, _anchorLastMonth.month + 1, 1);
          break;
        case '1Y':
          _anchor1Y = DateTime(_anchor1Y.year + 1, _anchor1Y.month, 1);
          break;
      }
    });
  }

  void _goBackward(String period) {
    setState(() {
      switch (period) {
        case 'Today':
          _anchorToday = _anchorToday.subtract(const Duration(days: 1));
          break;
        case 'Week':
          _anchorWeek = _anchorWeek.subtract(const Duration(days: 7));
          break;
        case 'Month':
          _anchorMonth = DateTime(_anchorMonth.year, _anchorMonth.month - 1, 1);
          break;
        case 'Last Month':
          _anchorLastMonth = DateTime(_anchorLastMonth.year, _anchorLastMonth.month - 1, 1);
          break;
        case '1Y':
          _anchor1Y = DateTime(_anchor1Y.year - 1, _anchor1Y.month, 1);
          break;
      }
    });
  }

  DateTimeRange _getActiveRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return DateTimeRange(
          start: DateTime(_anchorToday.year, _anchorToday.month, _anchorToday.day, 0, 0, 0),
          end: DateTime(_anchorToday.year, _anchorToday.month, _anchorToday.day, 23, 59, 59, 999),
        );
      case 'Week':
        return DateTimeRange(
          start: DateTime(_anchorWeek.year, _anchorWeek.month, _anchorWeek.day, 0, 0, 0),
          end: DateTime(_anchorWeek.year, _anchorWeek.month, _anchorWeek.day, 23, 59, 59, 999).add(const Duration(days: 6)),
        );
      case 'Month':
        final start = DateTime(_anchorMonth.year, _anchorMonth.month, 1, 0, 0, 0);
        final end = DateTime(_anchorMonth.year, _anchorMonth.month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case 'Last Month':
        final start = DateTime(_anchorLastMonth.year, _anchorLastMonth.month, 1, 0, 0, 0);
        final end = DateTime(_anchorLastMonth.year, _anchorLastMonth.month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case '3M':
        final start = DateTime(_anchor3M.year, _anchor3M.month - 2, 1, 0, 0, 0);
        final end = DateTime(_anchor3M.year, _anchor3M.month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case '6M':
        final start = DateTime(_anchor6M.year, _anchor6M.month - 5, 1, 0, 0, 0);
        final end = DateTime(_anchor6M.year, _anchor6M.month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case '1Y':
        final start = DateTime(_anchor1Y.year - 1, _anchor1Y.month + 1, 1, 0, 0, 0);
        final end = DateTime(_anchor1Y.year, _anchor1Y.month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case 'Custom':
        if (_customDateRange != null) return _customDateRange!;
        final todayStart = DateTime(now.year, now.month, 1, 0, 0, 0);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: todayStart, end: todayEnd);
      default:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
    }
  }

  void _scrollToSubExpense(String transactionId, int index) {
    if (index < 0) return;
    final key = _subExpenseKeys[transactionId];
    if (key == null) return;

    const double estimatedHeight = 66.0;
    final double targetOffset = index * estimatedHeight;

    if (_subExpenseScrollController.hasClients) {
      _subExpenseScrollController.animateTo(
        targetOffset.clamp(0.0, _subExpenseScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ).then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              alignment: 0.0,
            );
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(recalculatedAccountsProvider);
    final billsAsync = ref.watch(billsStreamProvider);
    final transactionsAsync = ref.watch(expenseListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final isPrivate = ref.watch(privacyModeProvider);
    final now = DateTime.now();

    return PopScope(
      canPop: _navigationLevel == 1,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_navigationLevel == 3) {
          setState(() {
            _navigationLevel = 2;
          });
        } else if (_navigationLevel == 2) {
          setState(() {
            _navigationLevel = 1;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
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
            child: accountsAsync.when(
              data: (accounts) {
                final creditCards = accounts.where((a) => a.isActive == true && a.type == 'credit_card').toList();

                if (creditCards.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context, "Credit Card"),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'No active credit cards found.',
                            style: TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Dynamic card tab sorting
                final allTxs = transactionsAsync.value ?? [];
                final Map<String, DateTime> latestTxDates = {};
                for (var tx in allTxs) {
                  if (tx.deletedAt != null) continue;
                  final id = tx.accountId;
                  if (id != null) {
                    final txDate = tx.date;
                    final currentLatest = latestTxDates[id];
                    if (currentLatest == null || txDate.isAfter(currentLatest)) {
                      latestTxDates[id] = txDate;
                    }
                  }
                }

                final List<Account> sortedCards = creditCards.toList();
                sortedCards.sort((a, b) {
                  final aDate = latestTxDates[a.id];
                  final bDate = latestTxDates[b.id];
                  
                  if (aDate != null && bDate != null) {
                    return bDate.compareTo(aDate);
                  } else if (aDate != null) {
                    return -1;
                  } else if (bDate != null) {
                    return 1;
                  } else {
                    final aOut = a.outstandingBalance ?? 0;
                    final bOut = b.outstandingBalance ?? 0;
                    return bOut.compareTo(aOut);
                  }
                });

                // Retrieve currently selected card
                final currentCard = _selectedCardId == 'all'
                    ? null
                    : creditCards.firstWhere((c) => c.id == _selectedCardId, orElse: () => creditCards.first);

                final List<String> activeCardIds = currentCard != null
                    ? [currentCard.id]
                    : creditCards.map((c) => c.id).toList();

                final bills = billsAsync.value ?? [];
                final activeBills = bills.where((b) => activeCardIds.contains(b.accountId)).toList()
                  ..sort((a, b) => (b.dueDate ?? b.createdAt).compareTo(a.dueDate ?? a.createdAt));

                final unpaidActiveBills = activeBills.where((b) => b.status != 'paid').toList()
                  ..sort((a, b) => (a.dueDate ?? a.createdAt).compareTo(b.dueDate ?? b.createdAt));

                final int totalLimit = currentCard != null
                    ? (currentCard.creditLimit ?? 0)
                    : creditCards.fold(0, (sum, c) => sum + (c.creditLimit ?? 0));

                final int totalOutstanding = currentCard != null
                    ? (currentCard.outstandingBalance ?? 0)
                    : creditCards.fold(0, (sum, c) => sum + (c.outstandingBalance ?? 0));

                final int totalAvailable = currentCard != null
                    ? (currentCard.availableCredit ?? 0)
                    : creditCards.fold(0, (sum, c) => sum + (c.availableCredit ?? 0));

                final double utilisationPct = totalLimit > 0
                    ? (totalOutstanding / totalLimit * 100).clamp(0.0, 1000.0)
                    : 0.0;

                if (_navigationLevel == 1) {
                  return _buildPage1Dashboard(
                    context,
                    sortedCards,
                    currentCard,
                    activeCardIds,
                    activeBills,
                    unpaidActiveBills,
                    totalLimit,
                    totalOutstanding,
                    totalAvailable,
                    utilisationPct,
                    allTxs,
                    isPrivate,
                    now,
                  );
                } else if (_navigationLevel == 2) {
                  return _buildPage2Analytics(
                    context,
                    currentCard,
                    activeCardIds,
                    allTxs,
                    categoriesAsync.value ?? [],
                    paymentMethodsAsync.value ?? [],
                    isPrivate,
                  );
                } else {
                  return _buildPage3SubExpenses(
                    context,
                    currentCard,
                    activeCardIds,
                    allTxs,
                    categoriesAsync.value ?? [],
                    isPrivate,
                  );
                }
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, {VoidCallback? onBack}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            key: const Key('header_back_button'),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
            onPressed: onBack ?? () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector(List<Account> creditCards) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: creditCards.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll ? _selectedCardId == 'all' : _selectedCardId == creditCards[index - 1].id;
          final label = isAll ? 'All Cards' : creditCards[index - 1].name;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _selectedCardId = isAll ? 'all' : creditCards[index - 1].id;
                  _selectedCategoryId = '';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0066FF).withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0066FF) : Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
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

  List<Widget> _buildAlertsSection(Account? account, List<Account> allCards, List<Bill> activeBills, DateTime now) {
    final List<Widget> banners = [];
    final today = DateTime(now.year, now.month, now.day);

    if (account != null) {
      final unpaid = activeBills.where((b) => b.status != 'paid').toList();
      if (unpaid.isNotEmpty) {
        final due = unpaid.first.dueDate ?? unpaid.first.createdAt;
        final dueDate = DateTime(due.year, due.month, due.day);
        final days = dueDate.difference(today).inDays;
        
        if (days < 0) {
          banners.add(_buildAlertBanner('OVERDUE', 'Your credit card payment is overdue by ${days.abs()} days.'));
        } else if (days <= 3) {
          banners.add(_buildAlertBanner('DUE SOON', 'Your credit card payment is due in $days days.'));
        }
      }

      final limit = account.creditLimit ?? 0;
      final outstanding = account.outstandingBalance ?? 0;
      if (limit > 0) {
        final util = (outstanding / limit) * 100;
        if (util >= 80.0) {
          banners.add(_buildAlertBanner('HIGH UTILISATION', 'Your card utilisation has reached ${util.toStringAsFixed(0)}%.'));
        }
      }
    } else {
      for (var card in allCards) {
        final cardBills = activeBills.where((b) => b.accountId == card.id).toList();
        final cardUnpaid = cardBills.where((b) => b.status != 'paid').toList();
        if (cardUnpaid.isNotEmpty) {
          final due = cardUnpaid.first.dueDate ?? cardUnpaid.first.createdAt;
          final dueDate = DateTime(due.year, due.month, due.day);
          final days = dueDate.difference(today).inDays;
          
          if (days < 0) {
            banners.add(_buildAlertBanner('OVERDUE', '${card.name} payment is overdue by ${days.abs()} days.'));
          } else if (days <= 3) {
            banners.add(_buildAlertBanner('DUE SOON', '${card.name} payment is due in $days days.'));
          }
        }

        final limit = card.creditLimit ?? 0;
        final outstanding = card.outstandingBalance ?? 0;
        if (limit > 0) {
          final util = (outstanding / limit) * 100;
          if (util >= 80.0) {
            banners.add(_buildAlertBanner('HIGH UTILISATION', '${card.name} utilisation has reached ${util.toStringAsFixed(0)}%.'));
          }
        }
      }
    }

    if (banners.isNotEmpty) {
      return [
        Column(children: banners),
        const SizedBox(height: 8),
      ];
    }
    return [];
  }

  Widget _buildAlertBanner(String type, String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(int limit, int outstanding, int available, int totalAmountDue, double utilisationPct, bool isPrivate) {
    final double creditLimitPct = limit > 0 ? (available / limit * 100) : 0.0;
    final double utilisationPctVal = limit > 0 ? (outstanding / limit * 100) : 0.0;

    final String creditLimitPctText = isPrivate ? '**%' : '${creditLimitPct.toStringAsFixed(2)}%';
    final String utilisationPctText = isPrivate ? '**%' : '${utilisationPctVal.toStringAsFixed(2)}%';

    return GlassCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'CREDIT CARD OVERVIEW',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Outstanding',
                      style: TextStyle(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    PrivacyText(
                      rawValue: _formatMoney(outstanding),
                      isAccountBalance: true,
                      style: const TextStyle(
                        color: Color(0xFFFF3B30),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Total Amount Due',
                      style: TextStyle(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    PrivacyText(
                      rawValue: _formatMoney(totalAmountDue),
                      isAccountBalance: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (limit > 0) ...[
                    ReusableNetWorthRing(
                      valueFraction: (available / limit).clamp(0.0, 1.0),
                      size: 50,
                      trackColor: const Color(0xFFFF3B30),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    creditLimitPctText,
                    style: const TextStyle(
                      color: Color(0xFF0066FF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0066FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Credit Limit',
                        style: TextStyle(color: Colors.white38, fontSize: 8.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    utilisationPctText,
                    style: const TextStyle(
                      color: Color(0xFFFF3B30),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Utilisation',
                        style: TextStyle(color: Colors.white38, fontSize: 8.5),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Credit Limit',
                      style: TextStyle(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    PrivacyText(
                      rawValue: limit > 0 ? _formatMoney(limit) : 'Not available',
                      isAccountBalance: true,
                      style: const TextStyle(
                        color: Color(0xFF0066FF),
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Limit',
                      style: TextStyle(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    PrivacyText(
                      rawValue: _formatMoney(available),
                      isAccountBalance: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
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



  Widget _buildAccountWiseLiabilities(List<Account> creditCards, List<Bill> bills, DateTime now) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ACCOUNT-WISE LIABILITIES',
          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 6),
        const Text(
          'CREDIT CARDS',
          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: creditCards.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final card = creditCards[index];
            final cardBills = bills.where((b) => b.accountId == card.id).toList()
              ..sort((a, b) => (b.dueDate ?? b.createdAt).compareTo(a.dueDate ?? a.createdAt));
            
            final unpaidBills = cardBills.where((b) => b.status != 'paid').toList();
            final latestBill = cardBills.isNotEmpty ? cardBills.first : null;
            final unpaidBill = unpaidBills.isNotEmpty ? unpaidBills.first : null;

            final int outstanding = card.outstandingBalance ?? 0;
            final int currentBillAmount = latestBill?.amount ?? 0;
            
            String dueText = '';
            Color dueColor = Colors.white38;
            if (latestBill?.statementDate == null) {
              dueText = '';
            } else if (unpaidBill != null && unpaidBill.dueDate != null) {
              dueText = _formatDueDays(unpaidBill.dueDate!, now);
              dueColor = _getDueDaysColor(unpaidBill.dueDate!, now);
            } else if (latestBill != null && latestBill.status == 'paid') {
              dueText = 'Paid';
              dueColor = const Color(0xFF00FF88);
            } else {
              dueText = 'Pending';
              dueColor = const Color(0xFFFF9500);
            }

            final String stmtDateStr = latestBill?.statementDate != null 
                ? DateFormat('dd MMM').format(latestBill!.statementDate!) 
                : 'Not generated';

            return GestureDetector(
              key: Key('liability_card_${card.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _selectedCardId = card.id;
                  _navigationLevel = 2; // Navigates to Level 2 (Analytics)
                  _selectedCategoryId = '';
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.015),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.credit_card_rounded, color: Color(0xFF0066FF), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                card.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Current Bill', style: TextStyle(color: Colors.white38, fontSize: 11)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: PrivacyText(
                                  rawValue: latestBill != null ? _formatMoney(currentBillAmount) : 'N/A',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Outstanding', style: TextStyle(color: Colors.white38, fontSize: 11)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: PrivacyText(
                                  rawValue: _formatMoney(outstanding),
                                  style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Statement date: $stmtDateStr', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                              Text(
                                dueText,
                                style: TextStyle(color: dueColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsCard(List<Transaction> txs, List<String> activeCardIds, List<Account> allCards) {
    final cardsMap = {for (var c in allCards) c.id: c};

    final ccTxs = txs.where((tx) {
      if (tx.deletedAt != null) return false;
      return activeCardIds.contains(tx.accountId) || 
             (tx.type == 'transfer' && activeCardIds.contains(tx.referenceNumber)) || 
             (tx.type == 'credit_card_payment' && activeCardIds.contains(tx.referenceNumber));
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final recentLimit = ccTxs.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'RECENT TRANSACTIONS',
          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        if (recentLimit.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.015),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            alignment: Alignment.center,
            child: const Text('No transactions recorded for this card.', style: TextStyle(color: Colors.white24, fontSize: 12)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentLimit.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = recentLimit[index];
              final isCredit = tx.type == 'credit_card_payment' || tx.type == 'transfer' || tx.type == 'income' || tx.type == 'refund' || tx.type == 'cashback';
              final color = isCredit ? const Color(0xFF00FF88) : const Color(0xFFFF3B30);
              final sign = isCredit ? '+' : '-';
              
              final account = cardsMap[tx.accountId];
              final cardName = account != null ? account.name : 'Credit Card';
              final displayType = tx.type == 'credit_card_payment' 
                  ? 'Payment' 
                  : (tx.type == 'transfer' ? 'Transfer' : (isCredit ? 'Credit' : 'Expense'));

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
                            tx.merchant ?? tx.description ?? 'General Merchant',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$cardName • $displayType',
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
                    GestureDetector(
                      onTap: () => context.push('/expenses/edit/${tx.id}'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PrivacyText(
                            rawValue: '$sign${_formatMoney(tx.amount.toInt().abs())}',
                            isTransactionAmount: true,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16),
                        ],
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

  Widget _buildPage1Dashboard(
    BuildContext context,
    List<Account> sortedCards,
    Account? currentCard,
    List<String> activeCardIds,
    List<Bill> activeBills,
    List<Bill> unpaidActiveBills,
    int totalLimit,
    int totalOutstanding,
    int available,
    double utilisationPct,
    List<Transaction> allTxs,
    bool isPrivate,
    DateTime now,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, "Credit Card"),

        _buildSelector(sortedCards),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(accountsProvider.notifier).loadAccounts();
            },
            color: const Color(0xFF0066FF),
            backgroundColor: const Color(0xFF0C0C0C),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              physics: const BouncingScrollPhysics(),
              children: [
                ..._buildAlertsSection(currentCard, sortedCards, activeBills, now),

                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _navigationLevel = 2;
                    });
                  },
                  child: _buildOverviewCard(totalLimit, totalOutstanding, available, unpaidActiveBills.fold(0, (s, b) => s + b.amount), utilisationPct, isPrivate),
                ),
                const SizedBox(height: 16),

                _buildAccountWiseLiabilities(
                  _selectedCardId == 'all' ? sortedCards : [currentCard!],
                  activeBills,
                  now,
                ),
                const SizedBox(height: 16),

                _buildRecentTransactionsCard(allTxs, activeCardIds, sortedCards),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage2Analytics(
    BuildContext context,
    Account? currentCard,
    List<String> activeCardIds,
    List<Transaction> allTxs,
    List<Category> categories,
    List<PaymentMethod> paymentMethods,
    bool isPrivate,
  ) {
    final title = currentCard != null ? currentCard.name : 'Credit Card';

    final activeRange = _getActiveRange();
    final filteredTxs = allTxs.where((tx) {
      if (tx.deletedAt != null) return false;
      
      final matchCard = activeCardIds.contains(tx.accountId) || 
                        (tx.type == 'transfer' && activeCardIds.contains(tx.referenceNumber)) || 
                        (tx.type == 'credit_card_payment' && activeCardIds.contains(tx.referenceNumber));
      if (!matchCard) return false;

      if (!FinancialCalculationService.isExpense(tx)) return false;

      final inRange = tx.date.isAfter(activeRange.start.subtract(const Duration(seconds: 1))) &&
                      tx.date.isBefore(activeRange.end.add(const Duration(seconds: 1)));
      return inRange;
    }).toList();

    filteredTxs.sort((a, b) => b.date.compareTo(a.date));

    final List<ChartDatum> chartData = [];
    int totalAmount = 0;

    final categoriesMap = {for (var c in categories) c.id: c};
    final pmsMap = {for (var pm in paymentMethods) pm.id: pm};

    if (_breakdownMode == 'Category') {
      final spends = <String, int>{};
      for (var tx in filteredTxs) {
        if (tx.categoryId != null) {
          spends[tx.categoryId!] = (spends[tx.categoryId!] ?? 0) + tx.amount.toInt();
          totalAmount += tx.amount.toInt();
        }
      }
      spends.forEach((catId, amt) {
        final cat = categoriesMap[catId];
        final pct = totalAmount == 0 ? 0.0 : (amt / totalAmount * 100);
        chartData.add(ChartDatum(
          id: catId,
          label: cat?.name ?? 'Other',
          value: amt.toDouble() / 100.0,
          percentage: pct,
          color: _getCategoryColor(cat?.icon),
          transactionCount: 1,
        ));
      });
    } else if (_breakdownMode == 'Account') {
      final spends = <String, int>{};
      for (var tx in filteredTxs) {
        final id = tx.accountId ?? 'unknown';
        spends[id] = (spends[id] ?? 0) + tx.amount.toInt();
        totalAmount += tx.amount.toInt();
      }
      final accountsAsync = ref.watch(accountsProvider);
      final accountsMap = {for (var a in accountsAsync.value ?? []) a.id: a};

      spends.forEach((accId, amt) {
        final acc = accountsMap[accId];
        final pct = totalAmount == 0 ? 0.0 : (amt / totalAmount * 100);
        chartData.add(ChartDatum(
          id: accId,
          label: acc?.name ?? accId,
          value: amt.toDouble() / 100.0,
          percentage: pct,
          color: _getCardColor(acc?.colorTheme),
          transactionCount: 1,
        ));
      });
    } else {
      final spends = <String, int>{};
      for (var tx in filteredTxs) {
        final id = tx.paymentMethodId ?? 'card';
        spends[id] = (spends[id] ?? 0) + tx.amount.toInt();
        totalAmount += tx.amount.toInt();
      }
      spends.forEach((pmId, amt) {
        final pm = pmsMap[pmId];
        final pct = totalAmount == 0 ? 0.0 : (amt / totalAmount * 100);
        chartData.add(ChartDatum(
          id: pmId,
          label: pm?.name ?? pmId,
          value: amt.toDouble() / 100.0,
          percentage: pct,
          color: _getPaymentMethodColor(pm?.type ?? 'card'),
          transactionCount: 1,
        ));
      });
    }

    chartData.sort((a, b) => b.value.compareTo(a.value));
    final dropdownTitle = 'SPENDING BY ${_breakdownMode.toUpperCase()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(
          context,
          title,
          onBack: () {
            setState(() {
              _navigationLevel = 1;
            });
          },
        ),

        _buildPeriodSelector(),

        _buildDateNavigationHeader(),

        // Fixed Donut Chart
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ReusableDonutChart(
            data: chartData,
            selectedId: _selectedCategoryId,
            onSelected: (id) {
              setState(() {
                _selectedCategoryId = id;
                final index = chartData.indexWhere((item) => item.id == id);
                if (index >= 0 && _categoryScrollController.hasClients) {
                  _scrollToCategory(id, index);
                }
              });
            },
            centerTitle: 'TOTAL SPENDING',
            centerValue: totalAmount.toDouble() / 100.0,
            isPrivate: isPrivate,
          ),
        ),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PopupMenuButton<String>(
                offset: const Offset(0, 30),
                color: const Color(0xFF0A0F1D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                onSelected: (val) {
                  setState(() {
                    _breakdownMode = val;
                    _selectedCategoryId = '';
                  });
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(value: 'Category', child: Text('SPENDING BY CATEGORY', style: TextStyle(color: _breakdownMode == 'Category' ? const Color(0xFF00E5FF) : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))),
                    PopupMenuItem(value: 'Account', child: Text('SPENDING BY ACCOUNT', style: TextStyle(color: _breakdownMode == 'Account' ? const Color(0xFF00E5FF) : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))),
                    PopupMenuItem(value: 'Payment Type', child: Text('SPENDING BY PAYMENT TYPE', style: TextStyle(color: _breakdownMode == 'Payment Type' ? const Color(0xFF00E5FF) : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))),
                  ];
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dropdownTitle,
                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00E5FF), size: 14),
                  ],
                ),
              ),
              PrivacyText(
                rawValue: AnalyticsFormatter.formatCurrency(totalAmount.toDouble() / 100.0),
                style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: chartData.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: const Text('No transactions recorded in this period.', style: TextStyle(color: Colors.white24, fontSize: 12)),
                )
              : ListView.separated(
                  controller: _categoryScrollController,
                  padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 80.0),
                  physics: const BouncingScrollPhysics(),
                  itemCount: chartData.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = chartData[index];
                    final isSelected = _selectedCategoryId == item.id;
                    final itemKey = _categoryKeys.putIfAbsent(item.id, () => GlobalKey());

                    return GestureDetector(
                      key: itemKey,
                      onTap: () {
                        if (_selectedCategoryId == item.id) {
                          setState(() {
                            _navigationLevel = 3;
                            _selectedSubExpenseId = '';
                          });
                        } else {
                          setState(() {
                            _selectedCategoryId = item.id;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF051833) : Colors.white.withOpacity(0.015),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.03),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 8,
                              width: 8,
                              decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.label,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPrivate ? '**%' : '${item.percentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: PrivacyText(
                                rawValue: AnalyticsFormatter.formatCurrency(item.value),
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPage3SubExpenses(
    BuildContext context,
    Account? currentCard,
    List<String> activeCardIds,
    List<Transaction> allTxs,
    List<Category> categories,
    bool isPrivate,
  ) {
    final activeRange = _getActiveRange();
    final categoriesMap = {for (var c in categories) c.id: c};

    final filteredTxs = allTxs.where((tx) {
      if (tx.deletedAt != null) return false;
      
      final matchCard = activeCardIds.contains(tx.accountId) || 
                        (tx.type == 'transfer' && activeCardIds.contains(tx.referenceNumber)) || 
                        (tx.type == 'credit_card_payment' && activeCardIds.contains(tx.referenceNumber));
      if (!matchCard) return false;

      if (!FinancialCalculationService.isExpense(tx)) return false;

      final inRange = tx.date.isAfter(activeRange.start.subtract(const Duration(seconds: 1))) &&
                      tx.date.isBefore(activeRange.end.add(const Duration(seconds: 1)));
      return inRange;
    }).toList();

    List<Transaction> subTxs = [];
    String subTitle = 'Details';

    if (_breakdownMode == 'Category') {
      subTxs = filteredTxs.where((tx) => tx.categoryId == _selectedCategoryId).toList();
      final cat = categoriesMap[_selectedCategoryId];
      subTitle = cat?.name ?? 'Category';
    } else if (_breakdownMode == 'Account') {
      subTxs = filteredTxs.where((tx) => tx.accountId == _selectedCategoryId).toList();
      final accountsAsync = ref.watch(accountsProvider);
      Account? acc;
      for (var a in (accountsAsync.value ?? [])) {
        if (a.id == _selectedCategoryId) {
          acc = a;
          break;
        }
      }
      subTitle = acc?.name ?? _selectedCategoryId;
    } else {
      subTxs = filteredTxs.where((tx) => tx.paymentMethodId == _selectedCategoryId).toList();
      final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
      PaymentMethod? pm;
      for (var p in (paymentMethodsAsync.value ?? [])) {
        if (p.id == _selectedCategoryId) {
          pm = p;
          break;
        }
      }
      subTitle = pm?.name ?? _selectedCategoryId;
    }

    subTxs.sort((a, b) => b.date.compareTo(a.date));
    final int subTotal = subTxs.fold(0, (sum, tx) => sum + tx.amount.toInt());

    final List<ChartDatum> chartData = [];
    final colors = [
      const Color(0xFF0066FF),
      const Color(0xFF00E5FF),
      const Color(0xFFFF3B30),
      const Color(0xFFFF9500),
      const Color(0xFF4CD964),
      const Color(0xFFAF52DE),
      const Color(0xFFFF2D55),
      const Color(0xFFE5FF00),
      const Color(0xFF00FFCC),
    ];

    for (int i = 0; i < subTxs.length; i++) {
      final tx = subTxs[i];
      final pct = subTotal == 0 ? 0.0 : (tx.amount.toDouble() / subTotal * 100);
      chartData.add(ChartDatum(
        id: tx.id,
        label: tx.merchant ?? tx.description ?? 'General',
        value: tx.amount.toDouble() / 100.0,
        percentage: pct,
        color: colors[i % colors.length],
        transactionCount: 1,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _navigationLevel = 2;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _navigationLevel = 2;
                  });
                },
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ReusableDonutChart(
            data: chartData,
            selectedId: _selectedSubExpenseId,
            onSelected: (id) {
              setState(() {
                _selectedSubExpenseId = id;
                final index = subTxs.indexWhere((tx) => tx.id == id);
                _scrollToSubExpense(id, index);
              });
            },
            centerTitle: 'SUB-EXPENSES',
            centerValue: subTotal.toDouble() / 100.0,
            isPrivate: isPrivate,
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: ListView.separated(
            controller: _subExpenseScrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: subTxs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = subTxs[index];
              final key = _subExpenseKeys.putIfAbsent(tx.id, () => GlobalKey());
              final isSelected = _selectedSubExpenseId == tx.id;
              final displayMerchant = tx.merchant ?? tx.description ?? 'General Merchant';

              return GestureDetector(
                key: key,
                onTap: () {
                  setState(() {
                    _selectedSubExpenseId = isSelected ? '' : tx.id;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF051833) : Colors.white.withOpacity(0.015),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.03),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Color(0xFFFF3B30),
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayMerchant,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM yyyy').format(tx.date),
                              style: const TextStyle(color: Colors.white24, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/expenses/edit/${tx.id}'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: PrivacyText(
                                rawValue: '-${_formatMoney(tx.amount.toInt().abs())}',
                                isTransactionAmount: true,
                                style: const TextStyle(
                                  color: Color(0xFFFF3B30),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'Week', 'Month', 'Last Month', '3M', '6M', '1Y', 'Custom'];
    return Container(
      height: 48,
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: periods.length,
        itemBuilder: (context, index) {
          final period = periods[index];
          final isSelected = _selectedPeriod == period;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                  _selectedCategoryId = '';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0066FF).withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0066FF) : Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    period,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
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

  Widget _buildDateNavigationHeader() {
    final showArrows = _selectedPeriod != '3M' && _selectedPeriod != '6M' && _selectedPeriod != 'Custom';
    final label = _getPeriodLabel();
    final enableForward = showArrows && _canGoForward(_selectedPeriod);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showArrows)
            IconButton(
              key: const Key('header_chevron_left'),
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              onPressed: () => _goBackward(_selectedPeriod),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (showArrows)
            IconButton(
              key: const Key('header_chevron_right'),
              icon: Icon(
                Icons.chevron_right,
                color: enableForward ? Colors.white70 : Colors.white10,
              ),
              onPressed: enableForward ? () => _goForward(_selectedPeriod) : null,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'Today':
        return DateFormat('d MMMM yyyy').format(_anchorToday).toUpperCase();
      case 'Week':
        final endOfWeek = _anchorWeek.add(const Duration(days: 6));
        return '${DateFormat('d MMM yyyy').format(_anchorWeek).toUpperCase()} – ${DateFormat('d MMM yyyy').format(endOfWeek).toUpperCase()}';
      case 'Month':
        return DateFormat('MMMM yyyy').format(_anchorMonth).toUpperCase();
      case 'Last Month':
        return DateFormat('MMMM yyyy').format(_anchorLastMonth).toUpperCase();
      case '3M':
        final start = _anchor3M.subtract(const Duration(days: 90));
        return '${DateFormat('MMM yyyy').format(start).toUpperCase()} – ${DateFormat('MMM yyyy').format(_anchor3M).toUpperCase()}';
      case '6M':
        final start = _anchor6M.subtract(const Duration(days: 180));
        return '${DateFormat('MMM yyyy').format(start).toUpperCase()} – ${DateFormat('MMM yyyy').format(_anchor6M).toUpperCase()}';
      case '1Y':
        return DateFormat('yyyy').format(_anchor1Y).toUpperCase();
      case 'Custom':
        if (_customDateRange != null) {
          return '${DateFormat('d MMM yyyy').format(_customDateRange!.start).toUpperCase()} – ${DateFormat('d MMM yyyy').format(_customDateRange!.end).toUpperCase()}';
        }
        return 'CUSTOM RANGE';
      default:
        return 'ALL TIME';
    }
  }
}
