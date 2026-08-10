import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/accounts_provider.dart';
import '../providers/account_formatters.dart';

class TransferFormSheet extends ConsumerStatefulWidget {
  const TransferFormSheet({super.key});

  @override
  ConsumerState<TransferFormSheet> createState() => _TransferFormSheetState();
}

class _TransferFormSheetState extends ConsumerState<TransferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _sourceAccountId;
  String? _destAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sourceAccountId == null || _destAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both source and destination accounts')),
      );
      return;
    }

    if (_sourceAccountId == _destAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and destination accounts must be different')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final doubleAmount = double.parse(_amountController.text);
      final intAmount = (doubleAmount * 100).round();

      final notifier = ref.read(expenseListNotifierProvider.notifier);
      final accounts = ref.read(recalculatedAccountsProvider).value ?? [];
      
      final sourceAccount = accounts.firstWhere((a) => a.id == _sourceAccountId);
      final destAccount = accounts.firstWhere((a) => a.id == _destAccountId);
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Find Transfer category
      final categoriesList = ref.read(categoriesProvider).value ?? [];
      final transferCat = categoriesList.firstWhere(
        (c) => c.name.toLowerCase().contains('transfer'),
        orElse: () => categoriesList.isNotEmpty ? categoriesList.first : null as dynamic,
      );
      final String? catId = transferCat?.id;

      final sourceId = const Uuid().v4();
      final now = DateTime.now();

      // 1. Create source transaction (Debit)
      final sourceTx = Transaction(
        id: sourceId,
        userId: userId,
        accountId: _sourceAccountId,
        categoryId: catId,
        type: 'transfer_debit',
        amount: intAmount,
        currency: 'INR',
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        merchant: 'To ${destAccount.displayTitle}',
        date: _selectedDate,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      // 2. Create destination transaction (Credit)
      final destTx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: _destAccountId,
        categoryId: catId,
        type: 'transfer_credit',
        amount: intAmount,
        currency: 'INR',
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        merchant: 'From ${sourceAccount.displayTitle}',
        date: _selectedDate,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        referenceNumber: sourceId, // Linked
        createdAt: now,
        updatedAt: now,
      );

      // Insert both
      await notifier.addTransaction(sourceTx);
      await notifier.addTransaction(destTx);

      // Reload accounts list
      await ref.read(accountsProvider.notifier).loadAccounts();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer recorded successfully!'),
            backgroundColor: Color(0xFF0066FF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to perform transfer: $e'), backgroundColor: const Color(0xFFFF3B30)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0066FF),
              onPrimary: Colors.white,
              surface: Color(0xFF0F1A1C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(recalculatedAccountsProvider);
    final accounts = accountsAsync.value ?? [];
    
    // Filter source accounts (cannot be credit cards for standard transfer out)
    final sourceAccounts = accounts.where((a) => a.isActive == true && a.type != 'credit_card').toList();
    // Destination accounts (can be any active account)
    final destAccounts = accounts.where((a) => a.isActive == true).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.12), width: 1.2),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transfer Money',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // Source Account
              const Text('FROM ACCOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sourceAccountId,
                dropdownColor: const Color(0xFF050505),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _buildInputDecoration(icon: Icons.unfold_less_rounded),
                items: sourceAccounts.map((a) {
                  return DropdownMenuItem<String>(
                    value: a.id,
                    child: Text('${a.displayTitle} (₹${(a.balance / 100.0).toStringAsFixed(0)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _sourceAccountId = val),
                validator: (val) => val == null ? 'Source account is required' : null,
              ),
              const SizedBox(height: 16),

              // Destination Account
              const Text('TO ACCOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _destAccountId,
                dropdownColor: const Color(0xFF050505),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _buildInputDecoration(icon: Icons.unfold_more_rounded),
                items: destAccounts.map((a) {
                  final isCC = a.type == 'credit_card';
                  final balStr = isCC 
                      ? 'Out: ₹${((a.outstandingBalance ?? 0) / 100.0).toStringAsFixed(0)}'
                      : 'Bal: ₹${(a.balance / 100.0).toStringAsFixed(0)}';
                  return DropdownMenuItem<String>(
                    value: a.id,
                    child: Text('${a.displayTitle} ($balStr)'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _destAccountId = val),
                validator: (val) => val == null ? 'Destination account is required' : null,
              ),
              const SizedBox(height: 16),

              // Amount
              const Text('TRANSFER AMOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _buildInputDecoration(hintText: '0.00', icon: Icons.payments_outlined),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Amount is required';
                  final doubleVal = double.tryParse(val);
                  if (doubleVal == null || doubleVal <= 0) return 'Enter a valid amount > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              const Text('DESCRIPTION', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(hintText: 'e.g. Card payment, Pocket money', icon: Icons.notes_outlined),
              ),
              const SizedBox(height: 16),

              // Date
              const Text('DATE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF0066FF), size: 18),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white30, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('CONFIRM TRANSFER', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13.5),
      prefixIcon: Icon(icon, color: const Color(0xFF0066FF), size: 18),
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0066FF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF3B30)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF3B30)),
      ),
    );
  }
}
