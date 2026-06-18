import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../../core/database/app_database.dart';
import '../../../sms_parser/presentation/providers/sms_parser_provider.dart';

class DashboardSummaryScreen extends ConsumerWidget {
  const DashboardSummaryScreen({super.key});

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount); // Defaulting to INR format for aesthetic. We can dynamically resolve symbol if needed.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final txsAsync = ref.watch(expenseListNotifierProvider);

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
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(expenseListNotifierProvider.notifier).loadTransactions();
            },
            color: Colors.teal,
            backgroundColor: Colors.grey.shade900,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              children: [
                // Welcome Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(color: Colors.teal.shade200, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.user?.displayName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        // Show Profile & Settings options dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF0F1A1C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(color: Colors.teal.withOpacity(0.2)),
                            ),
                            title: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.teal,
                                  child: Text(
                                    (auth.user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        auth.user?.displayName ?? 'User',
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        auth.user?.email ?? '',
                                        style: TextStyle(color: Colors.teal.shade200, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Divider(color: Colors.white10, height: 16),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.cloud_upload_outlined, color: Colors.tealAccent),
                                  title: const Text('Sync & Backup', style: TextStyle(color: Colors.white, fontSize: 14)),
                                  subtitle: const Text('Encrypt and save database', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.push('/backup');
                                  },
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                                  title: const Text('Logout Session', style: TextStyle(color: Colors.white, fontSize: 14)),
                                  subtitle: const Text('Sign out of your account', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ref.read(authProvider.notifier).logout();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.teal,
                        child: Text(
                          (auth.user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pending SMS drafts banner
                ref.watch(transactionDraftsStreamProvider).maybeWhen(
                  data: (drafts) {
                    if (drafts.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade900.withOpacity(0.4), Colors.teal.shade800.withOpacity(0.2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.textsms_outlined, color: Colors.tealAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You have ${drafts.length} pending SMS transaction draft${drafts.length > 1 ? "s" : ""}.',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/sms-drafts'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.tealAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),

                // Balance summary widget
                txsAsync.when(
                  data: (txs) {
                    int totalIncome = 0;
                    int totalExpense = 0;

                    for (var tx in txs) {
                      if (tx.type == 'income') {
                        totalIncome += tx.amount.toInt();
                      } else if (tx.type == 'expense') {
                        totalExpense += tx.amount.toInt();
                      }
                    }

                    final netBalance = totalIncome - totalExpense;

                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade900.withOpacity(0.8), const Color(0xFF00241F).withOpacity(0.5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NET BALANCE',
                            style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatMoney(netBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
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
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_downward, color: Colors.green, size: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Income', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatMoney(totalIncome),
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.teal.withOpacity(0.3),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.arrow_upward, color: Colors.red, size: 14),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Expenses', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatMoney(totalExpense),
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Container(
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(child: CircularProgressIndicator(color: Colors.teal)),
                  ),
                  error: (e, _) => Container(
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(child: Text('Error loading balances: $e', style: const TextStyle(color: Colors.red))),
                  ),
                ),
                const SizedBox(height: 24),
                const _AiQuickAddWidget(),
                const SizedBox(height: 32),

                // Quick Actions Title
                const Text(
                  'QUICK ACTIONS',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.add,
                        label: 'Add Expense',
                        color: Colors.teal,
                        onTap: () => context.push('/expenses/add'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.chat_bubble,
                        label: 'Ask AI',
                        color: Colors.purple,
                        onTap: () => StatefulNavigationShell.of(context).goBranch(3), // Navigate to AI Chat tab
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Recent Transactions Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RECENT TRANSACTIONS',
                      style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    TextButton(
                      onPressed: () {
                        StatefulNavigationShell.of(context).goBranch(1); // Switch to Expenses Tab
                      },
                      child: const Text('See All', style: TextStyle(color: Colors.tealAccent, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Recent transaction list
                txsAsync.when(
                  data: (txs) {
                    if (txs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Center(
                          child: Text(
                            'No transactions yet. Add your first expense!',
                            style: TextStyle(color: Colors.white60, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    final recentTxs = txs.take(3).toList();

                    return Consumer(
                      builder: (context, ref, child) {
                        final categoriesAsync = ref.watch(categoriesProvider);
                        final categoriesMap = categoriesAsync.maybeWhen(
                          data: (cats) => {for (var c in cats) c.id: c},
                          orElse: () => <String, Category>{},
                        );

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentTxs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tx = recentTxs[index];
                            final cat = tx.categoryId != null ? categoriesMap[tx.categoryId] : null;
                            final isIncome = tx.type == 'income';
                            final categoryName = cat?.name ?? 'Uncategorized';
                            final color = IconMapper.getColor(cat?.icon);
                            final icon = IconMapper.getIcon(cat?.icon);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: color, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.description ?? tx.merchant ?? categoryName,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(tx.date),
                                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    (isIncome ? '+' : '-') + _formatMoney(tx.amount),
                                    style: TextStyle(
                                      color: isIncome ? Colors.greenAccent : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.teal)),
                  error: (e, _) => Center(child: Text('Error loading transactions: $e', style: const TextStyle(color: Colors.red))),
                ),
                const SizedBox(height: 100), // Spacing for bottom navbar overlay
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// AI Quick Add Entry Widget
class _AiQuickAddWidget extends ConsumerStatefulWidget {
  const _AiQuickAddWidget();

  @override
  ConsumerState<_AiQuickAddWidget> createState() => _AiQuickAddWidgetState();
}

class _AiQuickAddWidgetState extends ConsumerState<_AiQuickAddWidget> {
  final _controller = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isProcessing = true);
    
    try {
      final nlpService = ref.read(nlpServiceProvider);
      final result = await nlpService.parseExpense(text);
      if (result != null && mounted) {
        _controller.clear();
        _showConfirmationSheet(context, result);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to parse text. Try: "Spent 250 on tea"'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showConfirmationSheet(BuildContext context, NlpParsedResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _AiConfirmSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade900.withOpacity(0.35),
            Colors.teal.shade900.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.purpleAccent, Colors.tealAccent],
                ).createShader(bounds),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI QUICK ADD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Type your transaction in plain English and let AI do the rest.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Spent 250 on tea or Salary 50000',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _submitText(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purpleAccent, Colors.tealAccent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _isProcessing ? null : _submitText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// AI Confirmation Dialog Bottom Sheet
class _AiConfirmSheet extends ConsumerStatefulWidget {
  final NlpParsedResult result;

  const _AiConfirmSheet({required this.result});

  @override
  ConsumerState<_AiConfirmSheet> createState() => _AiConfirmSheetState();
}

class _AiConfirmSheetState extends ConsumerState<_AiConfirmSheet> {
  late String _type;
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late TextEditingController _descriptionController;
  String? _selectedCategoryId;
  String? _selectedPaymentMethodId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.result.type;
    _amountController = TextEditingController(text: widget.result.amount.toStringAsFixed(2));
    _merchantController = TextEditingController(text: widget.result.merchant ?? '');
    _descriptionController = TextEditingController(
      text: widget.result.merchant != null ? 'Bought ${widget.result.merchant}' : 'AI transaction entry',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) throw Exception("User not authenticated");

      final doubleAmount = double.parse(_amountController.text);
      final intAmount = (doubleAmount * 100).round();

      final transaction = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        categoryId: _selectedCategoryId,
        paymentMethodId: _selectedPaymentMethodId,
        type: _type,
        amount: intAmount,
        currency: auth.user?.currency ?? 'INR',
        merchant: _merchantController.text.trim().isNotEmpty ? _merchantController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        date: DateTime.now(),
        source: 'ai_nlp',
        isRecurring: false,
        confidenceScore: widget.result.confidence,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(expenseListNotifierProvider.notifier).addTransaction(transaction);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent),
                SizedBox(width: 8),
                Text('AI transaction saved!'),
              ],
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    final categories = categoriesAsync.maybeWhen(data: (c) => c, orElse: () => <Category>[]);
    final paymentMethods = paymentMethodsAsync.maybeWhen(data: (p) => p, orElse: () => <PaymentMethod>[]);

    // Auto-select category if not selected yet
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      final match = categories.firstWhere(
        (c) => c.name.toLowerCase() == widget.result.category.toLowerCase(),
        orElse: () => categories.first,
      );
      _selectedCategoryId = match.id;
    }

    // Auto-select payment method if not selected yet
    if (_selectedPaymentMethodId == null && paymentMethods.isNotEmpty) {
      _selectedPaymentMethodId = paymentMethods.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AI Extracted Details',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          // Segmented Selector for type
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Expense')),
                  selected: _type == 'expense',
                  onSelected: (val) => setState(() => _type = 'expense'),
                  selectedColor: Colors.redAccent.withOpacity(0.25),
                  backgroundColor: Colors.white.withOpacity(0.04),
                  labelStyle: TextStyle(color: _type == 'expense' ? Colors.redAccent : Colors.white60),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Income')),
                  selected: _type == 'income',
                  onSelected: (val) => setState(() => _type = 'income'),
                  selectedColor: Colors.greenAccent.withOpacity(0.25),
                  backgroundColor: Colors.white.withOpacity(0.04),
                  labelStyle: TextStyle(color: _type == 'income' ? Colors.greenAccent : Colors.white60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount Field
          const Text('AMOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.payments, color: Colors.tealAccent),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // Merchant Field
          const Text('MERCHANT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _merchantController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.storefront, color: Colors.tealAccent),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          const Text('CATEGORY', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            dropdownColor: const Color(0xFF0F0F0F),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.folder, color: Colors.tealAccent),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            items: categories.map((c) {
              return DropdownMenuItem<String>(
                value: c.id,
                child: Text(c.name),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategoryId = val),
          ),
          const SizedBox(height: 16),

          // Payment Method Dropdown
          const Text('PAYMENT METHOD', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethodId,
            dropdownColor: const Color(0xFF0F0F0F),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.credit_card, color: Colors.tealAccent),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            items: paymentMethods.map((pm) {
              return DropdownMenuItem<String>(
                value: pm.id,
                child: Text(pm.name),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedPaymentMethodId = val),
          ),
          const SizedBox(height: 16),

          // Description Note
          const Text('NOTE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.note, color: Colors.tealAccent),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),

          // Confirm Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent.shade400,
              foregroundColor: const Color(0xFF00241F),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2))
                : const Text('CONFIRM & SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
