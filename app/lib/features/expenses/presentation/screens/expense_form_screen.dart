import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/category_picker.dart';
import '../widgets/payment_method_picker.dart';
import '../../../../core/database/app_database.dart';
import '../../../sms_parser/presentation/providers/sms_parser_provider.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  final String? draftId;

  const ExpenseFormScreen({
    super.key,
    this.transactionId,
    this.draftId,
  });

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();

  String _transactionType = 'expense';
  String? _selectedCategoryId;
  String? _selectedPaymentMethodId;
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  bool _isEditMode = false;
  Transaction? _existingTransaction;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.transactionId != null;
    if (_isEditMode) {
      _loadExistingTransaction();
    } else if (widget.draftId != null) {
      _loadDraftTransaction();
    } else {
      // Set default payment method if available
      _setDefaultPaymentMethod();
    }
  }

  Future<void> _loadDraftTransaction() async {
    setState(() => _isLoading = true);
    try {
      final dao = ref.read(transactionDraftDaoProvider);
      final draft = await dao.getDraftById(widget.draftId!);
      if (draft != null && mounted) {
        setState(() {
          _amountController.text = (draft.amount / 100.0).toStringAsFixed(2);
          _descriptionController.text = draft.description ?? '';
          _merchantController.text = draft.merchant ?? '';
          _transactionType = draft.type;
          _selectedDate = draft.date;
        });
      }
      await _setDefaultPaymentMethod();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load draft: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefaultPaymentMethod() async {
    // Wait for payment methods to load and pick the first one (e.g. Cash or UPI) as default
    final pms = await ref.read(paymentMethodsProvider.future);
    if (pms.isNotEmpty && mounted) {
      setState(() {
        _selectedPaymentMethodId = pms.first.id;
      });
    }
  }

  Future<void> _loadExistingTransaction() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final tx = await repo.getTransactionById(widget.transactionId!);
      if (tx != null && mounted) {
        setState(() {
          _existingTransaction = tx;
          _amountController.text = (tx.amount / 100.0).toStringAsFixed(2);
          _descriptionController.text = tx.description ?? '';
          _merchantController.text = tx.merchant ?? '';
          _transactionType = tx.type;
          _selectedCategoryId = tx.categoryId;
          _selectedPaymentMethodId = tx.paymentMethodId;
          _selectedDate = tx.date;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load transaction: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

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

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) {
        throw Exception('User is not authenticated');
      }

      // Convert amount string to cents/paise
      final doubleAmount = double.parse(_amountController.text);
      final intAmount = (doubleAmount * 100).round();

      final now = DateTime.now();

      final transaction = Transaction(
        id: _isEditMode ? _existingTransaction!.id : const Uuid().v4(),
        userId: userId,
        accountId: _isEditMode ? _existingTransaction!.accountId : null,
        categoryId: _selectedCategoryId,
        paymentMethodId: _selectedPaymentMethodId,
        type: _transactionType,
        amount: intAmount,
        currency: auth.user?.currency ?? 'INR',
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        merchant: _merchantController.text.isNotEmpty ? _merchantController.text : null,
        date: _selectedDate,
        source: _isEditMode ? _existingTransaction!.source : 'manual',
        confidenceScore: _isEditMode ? _existingTransaction!.confidenceScore : null,
        isRecurring: _isEditMode ? _existingTransaction!.isRecurring : false,
        syncStatus: 'pending',
        createdAt: _isEditMode ? _existingTransaction!.createdAt : now,
        updatedAt: now,
      );

      final notifier = ref.read(expenseListNotifierProvider.notifier);
      if (_isEditMode) {
        await notifier.editTransaction(transaction);
      } else {
        await notifier.addTransaction(transaction);
      }

      if (widget.draftId != null) {
        await ref.read(smsScannerProvider.notifier).dismissDraft(widget.draftId!);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transaction: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final currencySymbol = auth.user?.currency == 'USD' ? '\$' : '₹';

    if (_isLoading && _existingTransaction == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
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
          child: Column(
            children: [
              // Screen Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      _isEditMode ? 'Edit Transaction' : 'Add Transaction',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 48), // Equalizer space
                  ],
                ),
              ),

              // Form content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    children: [
                      // Segmented Income/Expense Selector
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTypeButton(
                                label: 'Expense',
                                type: 'expense',
                                activeColor: Colors.redAccent.withOpacity(0.2),
                                borderActiveColor: Colors.redAccent,
                              ),
                            ),
                            Expanded(
                              child: _buildTypeButton(
                                label: 'Income',
                                type: 'income',
                                activeColor: Colors.greenAccent.withOpacity(0.2),
                                borderActiveColor: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Giant Amount Field
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'AMOUNT',
                              style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  currencySymbol,
                                  style: const TextStyle(color: Colors.white70, fontSize: 36, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                IntrinsicWidth(
                                  child: TextFormField(
                                    controller: _amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: TextStyle(color: Colors.white10),
                                      border: InputBorder.none,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Category Section (Ranked)
                      const Text(
                        'SELECT CATEGORY',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      CategoryPicker(
                        selectedCategoryId: _selectedCategoryId,
                        transactionType: _transactionType,
                        onCategorySelected: (cat) {
                          setState(() {
                            _selectedCategoryId = cat.id;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Payment Method Section
                      const Text(
                        'PAYMENT METHOD',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      PaymentMethodPicker(
                        selectedPaymentMethodId: _selectedPaymentMethodId,
                        onPaymentMethodSelected: (pm) {
                          setState(() {
                            _selectedPaymentMethodId = pm.id;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Note & Merchant Fields
                      const Text(
                        'DETAILS',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _merchantController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          hintText: 'Merchant (e.g. Starbucks, Amazon)',
                          icon: Icons.storefront,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          hintText: 'Description / Notes',
                          icon: Icons.description,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Date Picker
                      const Text(
                        'DATE',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.tealAccent, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                  ),
                                ],
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white30),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Save Action Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent.shade400,
                          foregroundColor: const Color(0xFF00241F),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 8,
                          shadowColor: Colors.teal.withOpacity(0.4),
                        ),
                        onPressed: _isLoading ? null : _saveTransaction,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2.5),
                              )
                            : Text(
                                _isEditMode ? 'UPDATE TRANSACTION' : 'SAVE TRANSACTION',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required String type,
    required Color activeColor,
    required Color borderActiveColor,
  }) {
    final isSelected = _transactionType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = type;
          // Clear category selection since category lists differ between expense/income
          _selectedCategoryId = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? borderActiveColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.tealAccent.shade700, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.tealAccent),
      ),
    );
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

    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }
}
