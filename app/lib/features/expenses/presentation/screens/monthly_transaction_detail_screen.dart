import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/widgets/privacy_text.dart';

class MonthlyTransactionDetailScreen extends ConsumerStatefulWidget {
  final String type; // 'income' or 'expense'

  const MonthlyTransactionDetailScreen({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<MonthlyTransactionDetailScreen> createState() => _MonthlyTransactionDetailScreenState();
}

class _MonthlyTransactionDetailScreenState extends ConsumerState<MonthlyTransactionDetailScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    // Default to the current month
    _selectedMonth = DateTime.now();
  }

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 2).format(amount);
  }

  void _showMonthYearPicker(BuildContext context) {
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
                            _selectedMonth = DateTime(_selectedMonth.year - 1, _selectedMonth.month, 1);
                          });
                        },
                      ),
                      Text(
                        '${_selectedMonth.year}',
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
                            _selectedMonth = DateTime(_selectedMonth.year + 1, _selectedMonth.month, 1);
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
                      final isSelected = _selectedMonth.month == index + 1;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMonth = DateTime(_selectedMonth.year, index + 1, 1);
                          });
                          Navigator.pop(context);
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

  void _showQuickActionsSheet(BuildContext context, WidgetRef ref, Transaction tx) {
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
                leading: const Icon(Icons.copy_rounded, color: Color(0xFF00E5FF)),
                title: const Text('Duplicate Transaction', style: TextStyle(color: Color(0xFF00E5FF))),
                onTap: () async {
                  Navigator.pop(context);
                  await _duplicateTransactionDirectly(ref, tx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
                title: const Text('Delete Transaction', style: TextStyle(color: Color(0xFFFF3B30))),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteDirectly(context, ref, tx.id);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _duplicateTransactionDirectly(WidgetRef ref, Transaction tx) async {
    try {
      final now = DateTime.now();
      final duplicatedTx = Transaction(
        id: const Uuid().v4(),
        userId: tx.userId,
        accountId: tx.accountId,
        categoryId: tx.categoryId,
        paymentMethodId: tx.paymentMethodId,
        type: tx.type,
        amount: tx.amount,
        currency: tx.currency,
        description: tx.description != null ? '${tx.description} (Copy)' : 'Copy',
        merchant: tx.merchant,
        date: now,
        source: 'manual',
        syncStatus: 'pending',
        createdAt: now,
        updatedAt: now,
        receiptUrl: tx.receiptUrl,
        billLink: tx.billLink,
        tags: tx.tags,
        isRecurring: tx.isRecurring,
      );

      await ref.read(expenseListNotifierProvider.notifier).addTransaction(duplicatedTx);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction duplicated!'),
            backgroundColor: Color(0xFF00E5FF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to duplicate: $e')),
        );
      }
    }
  }

  void _confirmDeleteDirectly(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        title: const Text('Delete Transaction', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this transaction?', style: TextStyle(color: Colors.white70)),
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

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(expenseListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final isIncome = widget.type == 'income';
    final primaryColor = isIncome ? const Color(0xFF00E5FF) : const Color(0xFFFF3B30);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/expenses/add?type=${widget.type}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050E1A), Color(0xFF050505)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isIncome ? 'Monthly Income' : 'Monthly Expenses',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              Expanded(
                child: txsAsync.when(
                  data: (txs) {
                    // Filter transactions to selected type and month
                    final filteredTxs = txs.where((t) {
                      final matchesType = isIncome 
                          ? FinancialCalculationService.isIncome(t) 
                          : FinancialCalculationService.isExpense(t);
                      final matchesMonth = t.date.year == _selectedMonth.year && t.date.month == _selectedMonth.month;
                      return matchesType && matchesMonth;
                    }).toList();

                    // Sort by date descending
                    filteredTxs.sort((a, b) => b.date.compareTo(a.date));

                    // Group by date
                    final groupedTxs = <String, List<Transaction>>{};
                    for (var tx in filteredTxs) {
                      final dateStr = DateFormat('yyyy-MM-dd').format(tx.date);
                      groupedTxs.putIfAbsent(dateStr, () => []).add(tx);
                    }

                    // Calculate total
                    final totalAmount = filteredTxs.fold<int>(0, (sum, tx) => sum + tx.amount.toInt());

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      children: [
                        // TOTAL VALUE GLASS CARD
                        GlassCard(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isIncome ? 'TOTAL INCOME' : 'TOTAL EXPENSES',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                PrivacyText(
                                  rawValue: '${isIncome ? "+" : "-"}${_formatMoney(totalAmount)}',
                                  isTransactionAmount: true,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // MONTH NAVIGATOR ROW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.white70),
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showMonthYearPicker(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today, color: primaryColor, size: 14),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMMM yyyy').format(_selectedMonth).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: Colors.white70),
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // TRANSACTION LOGS LIST
                        if (filteredTxs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white24),
                                const SizedBox(height: 12),
                                Text(
                                  'No transactions for this month',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        else
                          categoriesAsync.when(
                            data: (cats) {
                              final categoriesMap = {for (var c in cats) c.id: c};

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: groupedTxs.keys.length,
                                itemBuilder: (context, groupIdx) {
                                  final dateStr = groupedTxs.keys.elementAt(groupIdx);
                                  final txList = groupedTxs[dateStr]!;
                                  final parsedDate = DateTime.parse(dateStr);
                                  
                                  // Formatting the date header
                                  final now = DateTime.now();
                                  String dayHeader = '';
                                  if (parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day) {
                                    dayHeader = 'TODAY';
                                  } else if (parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day - 1) {
                                    dayHeader = 'YESTERDAY';
                                  } else {
                                    dayHeader = DateFormat('EEEE, MMMM d').format(parsedDate).toUpperCase();
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
                                        child: Text(
                                          dayHeader,
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                      ...txList.map((tx) {
                                        final cat = categoriesMap[tx.categoryId];
                                        final icon = IconMapper.getIcon(cat?.icon);
                                        final iconColor = IconMapper.getColor(cat?.icon);
                                        
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0A1121).withOpacity(0.4),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.white.withOpacity(0.03)),
                                            ),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(16),
                                              onTap: () => context.push('/expenses/edit/${tx.id}'),
                                              onLongPress: () => _showQuickActionsSheet(context, ref, tx),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                child: Row(
                                                  children: [
                                                    // CATEGORY ICON
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: iconColor.withOpacity(0.12),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(icon, color: iconColor, size: 18),
                                                    ),
                                                    const SizedBox(width: 14),

                                                    // DESCRIPTION & SUBTITLE
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            tx.description ?? tx.merchant ?? 'Untitled',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 13.5,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 3),
                                                          Row(
                                                            children: [
                                                              Text(
                                                                cat?.name ?? 'General',
                                                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                              ),
                                                              if (tx.referenceNumber != null) ...[
                                                                const SizedBox(width: 6),
                                                                const Text('•', style: TextStyle(color: Colors.white24, fontSize: 10)),
                                                                const SizedBox(width: 6),
                                                                Text(
                                                                  tx.referenceNumber!,
                                                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    // AMOUNT
                                                    PrivacyText(
                                                      rawValue: '${isIncome ? "+" : "-"}${_formatMoney(tx.amount.toInt())}',
                                                      isTransactionAmount: true,
                                                      style: TextStyle(
                                                        color: primaryColor,
                                                        fontSize: 13.5,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                      }),
                                    ],
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, s) => const SizedBox.shrink(),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                  error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
