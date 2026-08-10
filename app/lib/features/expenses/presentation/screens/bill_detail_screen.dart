import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/account_formatters.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../providers/expense_provider.dart';

class BillDetailScreen extends ConsumerStatefulWidget {
  final String billId;

  const BillDetailScreen({super.key, required this.billId});

  @override
  ConsumerState<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends ConsumerState<BillDetailScreen> {
  bool _isProcessing = false;

  Future<void> _showMarkAsPaidWorkflow(BuildContext context, Transaction bill) async {
    final accounts = ref.read(accountsProvider).value ?? [];
    final pms = ref.read(paymentMethodsProvider).value ?? [];

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a financial account first.')),
      );
      return;
    }

    String selectedAccountId = accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first).id;
    String selectedPmId = pms.isNotEmpty ? pms.first.id : '';
    DateTime selectedDate = DateTime.now();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF0C0C0C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text(
                        'Confirm Payment Details',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Account Dropdown
                    const Text('Select Account', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAccountId,
                          dropdownColor: const Color(0xFF0C0C0C),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: accounts.map((acc) {
                            return DropdownMenuItem(
                              value: acc.id,
                              child: Text('${acc.displayTitle} (₹${(acc.balance / 100.0).toStringAsFixed(0)})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedAccountId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Dropdown
                    const Text('Payment Method', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPmId,
                          dropdownColor: const Color(0xFF0C0C0C),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: pms.map((pm) {
                            return DropdownMenuItem(
                              value: pm.id,
                              child: Text(pm.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedPmId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Date', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF00E5FF)),
                          label: Text(
                            DateFormat('dd MMM yyyy').format(selectedDate),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context, {
                          'accountId': selectedAccountId,
                          'paymentMethodId': selectedPmId,
                          'paymentDate': selectedDate,
                        });
                      },
                      child: const Text('Mark as Paid', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _isProcessing = true);
      try {
        await ref.read(expenseListNotifierProvider.notifier).markBillAsPaid(
          bill: bill,
          accountId: result['accountId'],
          paymentMethodId: result['paymentMethodId'],
          paymentDate: result['paymentDate'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bill marked as paid successfully!'), backgroundColor: Color(0xFF00FF88)),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pay bill: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(expenseListNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final categories = categoriesAsync.value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        title: const Text('Bill Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
      ),
      body: transactionsAsync.when(
        data: (txs) {
          final billList = txs.where((t) => t.id == widget.billId).toList();
          if (billList.isEmpty) {
            return const Center(child: Text('Bill not found.', style: TextStyle(color: Colors.white30)));
          }
          final bill = billList.first;
          final cat = categories.firstWhere((c) => c.id == bill.categoryId, 
              orElse: () => Category(id: '', userId: '', name: 'Miscellaneous', type: 'expense', icon: 'category', isSystemDefault: false, usageCount: 0, createdAt: DateTime.now()));
          final catColor = IconMapper.getColor(cat.icon);

          final due = bill.dueDate ?? bill.date;
          final formattedDue = DateFormat('dd MMM yyyy').format(due);
          final isPaid = bill.billStatus == 'paid';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.015),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: catColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        bill.merchant ?? bill.description ?? 'Bill',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${(bill.amount / 100.0).toStringAsFixed(2)}',
                        style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isPaid ? const Color(0xFF00FF88) : const Color(0xFFFF9500)).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isPaid ? 'PAID' : 'UNPAID',
                          style: TextStyle(
                            color: isPaid ? const Color(0xFF00FF88) : const Color(0xFFFF9500),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Details list
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.015),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Due Date', formattedDue),
                      const Divider(color: Colors.white10),
                      _buildDetailRow('Category', cat.name),
                      const Divider(color: Colors.white10),
                      _buildDetailRow('Type', bill.type.toUpperCase().replaceAll('_', ' ')),
                      if (bill.billLink != null && bill.billLink!.isNotEmpty) ...[
                        const Divider(color: Colors.white10),
                        _buildDetailRow('Bill Link / PDF', bill.billLink!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons
                if (!isPaid)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isProcessing ? null : () => _showMarkAsPaidWorkflow(context, bill),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
