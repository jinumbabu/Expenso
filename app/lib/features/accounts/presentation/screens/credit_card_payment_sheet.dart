import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../../../core/database/app_database.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/accounts_provider.dart';
import '../providers/account_formatters.dart';

class CreditCardPaymentSheet extends ConsumerStatefulWidget {
  const CreditCardPaymentSheet({super.key});

  @override
  ConsumerState<CreditCardPaymentSheet> createState() => _CreditCardPaymentSheetState();
}

class _TransferType {
  final String label;
  final String key;
  _TransferType(this.label, this.key);
}

class _CreditCardPaymentSheetState extends ConsumerState<CreditCardPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _targetCardId;
  String? _sourceAccountId;
  String _selectedOption = 'outstanding'; // outstanding, min_due, total_due, custom
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCardChanged(String? val, List<Account> accounts) {
    if (val == null) return;
    setState(() {
      _targetCardId = val;
      final card = accounts.firstWhere((a) => a.id == val);
      
      // Auto fill amount based on selected option
      _updateAmount(card);
    });
  }

  void _updateAmount(Account card) {
    if (_selectedOption == 'outstanding') {
      final outstanding = card.outstandingBalance ?? 0;
      _amountController.text = (outstanding / 100.0).toStringAsFixed(2);
    } else if (_selectedOption == 'min_due') {
      final minDue = card.minAmountDue ?? 0;
      _amountController.text = (minDue / 100.0).toStringAsFixed(2);
    } else if (_selectedOption == 'total_due') {
      final totalDue = card.totalAmountDue ?? 0;
      _amountController.text = (totalDue / 100.0).toStringAsFixed(2);
    } else {
      // Keep custom input or clear
      if (_amountController.text.isEmpty || _amountController.text == '0.00' || _amountController.text == '0') {
        _amountController.text = '';
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_targetCardId == null || _sourceAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select credit card and payment source')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final doubleAmount = double.parse(_amountController.text);
      final intAmount = (doubleAmount * 100).round();

      final notifier = ref.read(expenseListNotifierProvider.notifier);
      final accounts = ref.read(recalculatedAccountsProvider).value ?? [];
      
      final ccCard = accounts.firstWhere((a) => a.id == _targetCardId);
      final sourceAccount = accounts.firstWhere((a) => a.id == _sourceAccountId);
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Find Category ID for Transfer/Credit Card Payment
      final categoriesList = ref.read(categoriesProvider).value ?? [];
      final transferCat = categoriesList.firstWhere(
        (c) => c.name.toLowerCase().contains('transfer') || c.name.toLowerCase().contains('bills'),
        orElse: () => categoriesList.isNotEmpty ? categoriesList.first : null as dynamic,
      );
      final String? catId = transferCat?.id;

      final sourceId = const Uuid().v4();
      final now = DateTime.now();

      // 1. Create debit transaction on source account (debit bank balance)
      final sourceTx = Transaction(
        id: sourceId,
        userId: userId,
        accountId: _sourceAccountId,
        categoryId: catId,
        type: 'credit_card_payment_debit',
        amount: intAmount,
        currency: 'INR',
        description: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : 'Paid ${ccCard.displayTitle}',
        merchant: 'Pay CC: ${ccCard.displayTitle}',
        date: _selectedDate,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      // 2. Create credit transaction on CC account (decrease outstanding balance)
      final destTx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: _targetCardId,
        categoryId: catId,
        type: 'credit_card_payment_credit',
        amount: intAmount,
        currency: 'INR',
        description: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : 'Payment received',
        merchant: 'Payment fr: ${sourceAccount.displayTitle}',
        date: _selectedDate,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        referenceNumber: sourceId, // Linked
        createdAt: now,
        updatedAt: now,
      );

      // Save transactions
      await notifier.addTransaction(sourceTx);
      await notifier.addTransaction(destTx);

      // Reset totalAmountDue / minAmountDue if we paid full
      if (_selectedOption == 'total_due' || _selectedOption == 'outstanding' || intAmount >= (ccCard.outstandingBalance ?? 0)) {
        final updatedCC = ccCard.copyWith(
          totalAmountDue: const Value(0),
          minAmountDue: const Value(0),
          paymentStatus: const Value('paid'),
          updatedAt: DateTime.now(),
        );
        await ref.read(accountsProvider.notifier).editAccount(updatedCC);
      } else {
        // Just reload accounts
        await ref.read(accountsProvider.notifier).loadAccounts();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credit Card payment recorded successfully!'),
            backgroundColor: Color(0xFFFF3B30),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record payment: $e'), backgroundColor: const Color(0xFFFF3B30)),
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
              primary: Color(0xFFFF3B30),
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
    
    // Filter Target Credit Cards
    final creditCards = accounts.where((a) => a.isActive == true && a.type == 'credit_card').toList();
    // Filter Source Bank/Cash accounts
    final sourceAccounts = accounts.where((a) => a.isActive == true && a.type != 'credit_card').toList();

    Account? selectedCard;
    if (_targetCardId != null) {
      selectedCard = creditCards.firstWhere((a) => a.id == _targetCardId);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.12), width: 1.2),
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
                    'Record Card Payment',
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

              // Select Credit Card
              const Text('SELECT CREDIT CARD', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _targetCardId,
                dropdownColor: const Color(0xFF050505),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _buildInputDecoration(icon: Icons.credit_card_outlined),
                items: creditCards.map((c) {
                  final outstanding = (c.outstandingBalance ?? 0) / 100.0;
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text('${c.displayTitle} (Out: ₹${outstanding.toStringAsFixed(0)})'),
                  );
                }).toList(),
                onChanged: (val) => _onCardChanged(val, accounts),
                validator: (val) => val == null ? 'Credit card is required' : null,
              ),
              const SizedBox(height: 16),

              // Payment Source
              const Text('PAY FROM ACCOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sourceAccountId,
                dropdownColor: const Color(0xFF050505),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _buildInputDecoration(icon: Icons.account_balance_outlined),
                items: sourceAccounts.map((a) {
                  return DropdownMenuItem<String>(
                    value: a.id,
                    child: Text('${a.displayTitle} (₹${(a.balance / 100.0).toStringAsFixed(0)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _sourceAccountId = val),
                validator: (val) => val == null ? 'Source account is required' : null,
              ),
              const SizedBox(height: 20),

              // Quick Amount Options
              if (selectedCard != null) ...[
                const Text('PAYMENT OPTION', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildOptionChip(
                      label: 'Total Outstanding',
                      value: 'outstanding',
                      amountStr: '₹${((selectedCard.outstandingBalance ?? 0) / 100.0).toStringAsFixed(0)}',
                      card: selectedCard,
                    ),
                    _buildOptionChip(
                      label: 'Min Amount Due',
                      value: 'min_due',
                      amountStr: '₹${((selectedCard.minAmountDue ?? 0) / 100.0).toStringAsFixed(0)}',
                      card: selectedCard,
                    ),
                    _buildOptionChip(
                      label: 'Total Statement Due',
                      value: 'total_due',
                      amountStr: '₹${((selectedCard.totalAmountDue ?? 0) / 100.0).toStringAsFixed(0)}',
                      card: selectedCard,
                    ),
                    _buildOptionChip(
                      label: 'Custom / Partial',
                      value: 'custom',
                      amountStr: 'Any amount',
                      card: selectedCard,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Amount
              const Text('PAYMENT AMOUNT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                enabled: _selectedOption == 'custom' || selectedCard == null,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _buildInputDecoration(hintText: '0.00', icon: Icons.payments_outlined),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Amount is required';
                  final doubleVal = double.tryParse(val);
                  if (doubleVal == null || doubleVal <= 0) return 'Enter a valid amount';
                  return null;
                },
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
                          const Icon(Icons.calendar_today, color: Color(0xFFFF3B30), size: 18),
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
              const SizedBox(height: 16),

              // Notes
              const Text('NOTES / REMARKS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(hintText: 'e.g. Card payment, Partial payoff', icon: Icons.notes_outlined),
              ),
              const SizedBox(height: 28),

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('RECORD CC PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required String value,
    required String amountStr,
    required Account card,
  }) {
    final isSelected = _selectedOption == value;
    return ChoiceChip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(amountStr, style: TextStyle(color: isSelected ? Colors.white70 : Colors.white38, fontSize: 9)),
        ],
      ),
      selected: isSelected,
      backgroundColor: Colors.white.withOpacity(0.02),
      selectedColor: const Color(0xFFFF3B30).withOpacity(0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? const Color(0xFFFF3B30) : Colors.white12),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedOption = value;
            _updateAmount(card);
          });
        }
      },
    );
  }

  InputDecoration _buildInputDecoration({String? hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13.5),
      prefixIcon: Icon(icon, color: const Color(0xFFFF3B30), size: 18),
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF3B30)),
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
