import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../providers/budget_provider.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  String _formatMoney(int amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR').format(amount);
  }

  Color _getProgressColor(double percent) {
    if (percent < 0.70) {
      return Colors.tealAccent.shade400;
    } else if (percent <= 1.0) {
      return Colors.amberAccent.shade400;
    } else {
      return Colors.redAccent.shade400;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetStatusAsync = ref.watch(budgetStatusProviderList);

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
              // Screen Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Budgets',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.tealAccent),
                      onPressed: () => _showBudgetForm(context, ref),
                    ),
                  ],
                ),
              ),

              // Budgets List / Content
              Expanded(
                child: budgetStatusAsync.when(
                  data: (budgetStatuses) {
                    if (budgetStatuses.isEmpty) {
                      return _buildEmptyState(context, ref);
                    }

                    // Separate Overall Budget from Category Budgets
                    final overallBudgets = budgetStatuses.where((b) => b.budget.categoryId == null).toList();
                    final categoryBudgets = budgetStatuses.where((b) => b.budget.categoryId != null).toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Overall Budget Section (if exists)
                        if (overallBudgets.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0, bottom: 12.0),
                            child: Text(
                              'OVERALL LIMIT',
                              style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ),
                          ...overallBudgets.map((b) => _buildOverallBudgetCard(context, ref, b)),
                          const SizedBox(height: 20),
                        ],

                        // Category Budgets Section
                        if (categoryBudgets.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              'CATEGORY LIMITS',
                              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ),
                          ...categoryBudgets.map((b) => _buildCategoryBudgetCard(context, ref, b)),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.teal)),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBudgetForm(context, ref),
        backgroundColor: Colors.tealAccent.shade400,
        foregroundColor: const Color(0xFF00241F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.teal.withOpacity(0.15)),
              ),
              child: Icon(
                Icons.pie_chart,
                size: 64,
                color: Colors.teal.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No active budgets',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Setting a monthly or category budget helps keep your spending on track. Setup your first budget below.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade400,
                foregroundColor: const Color(0xFF00241F),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _showBudgetForm(context, ref),
              child: const Text('CREATE A BUDGET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallBudgetCard(BuildContext context, WidgetRef ref, BudgetStatus status) {
    final progress = status.percent;
    final progressColor = _getProgressColor(progress);

    return GestureDetector(
      onTap: () => _showBudgetActions(context, ref, status),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade900.withOpacity(0.6), const Color(0xFF00241F).withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.teal.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.tealAccent.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.wallet, color: Colors.tealAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Total Monthly Limit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress > 1.0 ? 1.0 : progress,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: progressColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${_formatMoney(status.spentAmount)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                Text(
                  status.isOverBudget
                      ? 'Over limit: ${_formatMoney(-status.remainingAmount)}'
                      : 'Remaining: ${_formatMoney(status.remainingAmount)}',
                  style: TextStyle(
                    color: status.isOverBudget ? Colors.redAccent : Colors.tealAccent.shade200,
                    fontSize: 13,
                    fontWeight: status.isOverBudget ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetCard(BuildContext context, WidgetRef ref, BudgetStatus status) {
    final catColor = IconMapper.getColor(status.category?.icon);
    final catIcon = IconMapper.getIcon(status.category?.icon);
    final progress = status.percent;
    final progressColor = _getProgressColor(progress);

    return GestureDetector(
      onTap: () => _showBudgetActions(context, ref, status),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: catColor.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(catIcon, color: catColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            status.category?.name ?? 'Category Limit',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                          Text(
                            _formatMoney(status.budget.amount),
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Spent ${_formatMoney(status.spentAmount)}',
                            style: const TextStyle(color: Colors.white30, fontSize: 12),
                          ),
                          Text(
                            status.isOverBudget
                                ? 'Over: ${_formatMoney(-status.remainingAmount)}'
                                : 'Left: ${_formatMoney(status.remainingAmount)}',
                            style: TextStyle(
                              color: status.isOverBudget ? Colors.redAccent.shade100 : Colors.white60,
                              fontSize: 12,
                              fontWeight: status.isOverBudget ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress > 1.0 ? 1.0 : progress,
                backgroundColor: Colors.white.withOpacity(0.03),
                color: progressColor,
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetActions(BuildContext context, WidgetRef ref, BudgetStatus status) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                title: const Text('Edit Budget Limit', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showBudgetForm(context, ref, status);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete Budget Limit', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, status.budget.id);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String budgetId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Budget', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this budget limit? This action is local and irreversible.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.teal)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(budgetListNotifierProvider.notifier).removeBudget(budgetId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBudgetForm(BuildContext context, WidgetRef ref, [BudgetStatus? existing]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _BudgetFormSheet(existing: existing);
      },
    );
  }
}

// Combined categories loading and status calculation
final budgetStatusProviderList = Provider<AsyncValue<List<BudgetStatus>>>((ref) {
  return ref.watch(budgetStatusListProvider);
});

class _BudgetFormSheet extends ConsumerStatefulWidget {
  final BudgetStatus? existing;

  const _BudgetFormSheet({this.existing});

  @override
  ConsumerState<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _amountController.text = (widget.existing!.budget.amount / 100.0).toStringAsFixed(2);
      _selectedCategoryId = widget.existing!.budget.categoryId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final doubleVal = double.parse(_amountController.text);
      final centsVal = (doubleVal * 100).round();

      final notifier = ref.read(budgetListNotifierProvider.notifier);

      if (widget.existing != null) {
        final updatedBudget = widget.existing!.budget.copyWith(
          amount: centsVal,
          categoryId: Value<String?>(_selectedCategoryId),
        );
        await notifier.editBudget(updatedBudget);
      } else {
        await notifier.addBudget(centsVal, _selectedCategoryId);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Text(widget.existing != null ? 'Budget updated successfully!' : 'Budget created successfully!'),
              ],
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.maybeWhen(
      data: (cats) => cats.where((c) => c.type == 'expense').toList(),
      orElse: () => <Category>[],
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existing != null ? 'Edit Budget Limit' : 'Set Budget Limit',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),

            // Amount Input
            const Text('MONTHLY LIMIT AMOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.payments, color: Colors.tealAccent),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.tealAccent)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter an amount';
                final numVal = double.tryParse(val);
                if (numVal == null || numVal <= 0) return 'Please enter a valid amount greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category Selection (Optional, null is overall)
            const Text('BUDGET SCOPE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _selectedCategoryId,
              dropdownColor: const Color(0xFF0F0F0F),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.tealAccent)),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.wallet, color: Colors.tealAccent, size: 18),
                      SizedBox(width: 10),
                      Text('Overall Monthly Budget (All Expenses)'),
                    ],
                  ),
                ),
                ...categories.map((c) {
                  final catIcon = IconMapper.getIcon(c.icon);
                  final catColor = IconMapper.getColor(c.icon);
                  return DropdownMenuItem<String?>(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(catIcon, color: catColor, size: 18),
                        const SizedBox(width: 10),
                        Text('${c.name} Limit'),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: widget.existing != null
                  ? null // Disable editing category on existing budget to keep it clean (delete and recreate if needed)
                  : (val) => setState(() => _selectedCategoryId = val),
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade400,
                foregroundColor: const Color(0xFF00241F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2))
                  : Text(
                      widget.existing != null ? 'UPDATE BUDGET LIMIT' : 'CREATE BUDGET LIMIT',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
