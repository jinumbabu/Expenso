import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/accounts_provider.dart';

class AccountFormSheet extends ConsumerStatefulWidget {
  final Account? existing;

  const AccountFormSheet({super.key, this.existing});

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _notesController = TextEditingController();
  
  // CC fields
  final _creditLimitController = TextEditingController();
  final _statementDateController = TextEditingController();
  final _paymentDueDateController = TextEditingController();
  final _minAmountDueController = TextEditingController();
  final _totalAmountDueController = TextEditingController();
  final _last4DigitsController = TextEditingController();
  final _statementCycleController = TextEditingController();

  String _selectedType = 'savings';
  String _selectedColor = '0xFF0066FF'; // Default blue
  String _selectedIcon = 'account_balance';
  bool _isActive = true;
  bool _autoPay = false;
  bool _enableBillReminder = true;
  bool _enableSmsTracking = true;
  bool _isSaving = false;

  final List<Map<String, String>> _accountTypes = [
    {'value': 'cash', 'label': 'Cash', 'icon': 'account_balance_wallet'},
    {'value': 'savings', 'label': 'Savings Account', 'icon': 'account_balance'},
    {'value': 'current', 'label': 'Current Account', 'icon': 'business'},
    {'value': 'salary', 'label': 'Salary Account', 'icon': 'account_balance'},
    {'value': 'credit_card', 'label': 'Credit Card', 'icon': 'credit_card'},
    {'value': 'debit_card', 'label': 'Debit Card', 'icon': 'credit_card'},
    {'value': 'wallet', 'label': 'UPI / Digital Wallet', 'icon': 'account_balance_wallet'},
    {'value': 'investment', 'label': 'Investment Account', 'icon': 'trending_up'},
    {'value': 'fixed_deposit', 'label': 'Fixed Deposit', 'icon': 'lock'},
    {'value': 'loan', 'label': 'Loan Account', 'icon': 'monetization_on'},
    {'value': 'gold', 'label': 'Gold Account', 'icon': 'brightness_high'},
    {'value': 'crypto', 'label': 'Cryptocurrency Wallet', 'icon': 'currency_bitcoin'},
    {'value': 'custom', 'label': 'Other (Custom)', 'icon': 'star'},
  ];

  final List<String> _colors = [
    '0xFF0066FF', // Electric Blue
    '0xFF00E5FF', // Neon Cyan
    '0xFFFF3B30', // Red
    '0xFFFFB703', // Orange/Gold
    '0xFFB5179E', // Magenta
    '0xFF7209B7', // Purple
    '0xFF4CC9F0', // Sky Blue
    '0xFF00FF88', // Green
  ];

  final List<Map<String, dynamic>> _icons = [
    {'name': 'account_balance_wallet', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'account_balance', 'icon': Icons.account_balance_outlined},
    {'name': 'business', 'icon': Icons.business_outlined},
    {'name': 'wallet', 'icon': Icons.wallet_outlined},
    {'name': 'credit_card', 'icon': Icons.credit_card_outlined},
    {'name': 'trending_up', 'icon': Icons.trending_up_rounded},
    {'name': 'lock', 'icon': Icons.lock_outline_rounded},
    {'name': 'monetization_on', 'icon': Icons.monetization_on_outlined},
    {'name': 'brightness_high', 'icon': Icons.brightness_high_outlined},
    {'name': 'currency_bitcoin', 'icon': Icons.currency_bitcoin_outlined},
    {'name': 'star', 'icon': Icons.star_border_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final acc = widget.existing!;
      _nameController.text = acc.name;
      _bankNameController.text = acc.bankName ?? '';
      _openingBalanceController.text = ((acc.openingBalance ?? 0) / 100.0).toStringAsFixed(2);
      _notesController.text = acc.notes ?? '';
      _selectedType = acc.type;
      _selectedColor = acc.colorTheme ?? '0xFF0066FF';
      _selectedIcon = acc.icon ?? 'account_balance';
      _isActive = acc.isActive ?? true;

      if (acc.type == 'credit_card') {
        _creditLimitController.text = ((acc.creditLimit ?? 0) / 100.0).toStringAsFixed(2);
        _statementDateController.text = acc.statementDate?.toString() ?? '';
        _paymentDueDateController.text = acc.paymentDueDate?.toString() ?? '';
        _minAmountDueController.text = ((acc.minAmountDue ?? 0) / 100.0).toStringAsFixed(2);
        _totalAmountDueController.text = ((acc.totalAmountDue ?? 0) / 100.0).toStringAsFixed(2);
        _autoPay = acc.autoPay ?? false;
        _last4DigitsController.text = acc.last4Digits ?? '';
        _statementCycleController.text = acc.statementCycle ?? '';
        _enableBillReminder = acc.enableBillReminder ?? true;
        _enableSmsTracking = acc.enableSmsTracking ?? true;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _openingBalanceController.dispose();
    _notesController.dispose();
    _creditLimitController.dispose();
    _statementDateController.dispose();
    _paymentDueDateController.dispose();
    _minAmountDueController.dispose();
    _totalAmountDueController.dispose();
    _last4DigitsController.dispose();
    _statementCycleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(accountsProvider.notifier);

      final openBal = _openingBalanceController.text.isNotEmpty 
          ? (double.parse(_openingBalanceController.text) * 100).round()
          : 0;

      final limit = _creditLimitController.text.isNotEmpty
          ? (double.parse(_creditLimitController.text) * 100).round()
          : 0;

      final minDue = _minAmountDueController.text.isNotEmpty
          ? (double.parse(_minAmountDueController.text) * 100).round()
          : 0;

      final totalDue = _totalAmountDueController.text.isNotEmpty
          ? (double.parse(_totalAmountDueController.text) * 100).round()
          : 0;

      final stmtDate = int.tryParse(_statementDateController.text);
      final dueDate = int.tryParse(_paymentDueDateController.text);

      if (widget.existing != null) {
        // Edit mode
        final currentBal = _selectedType == 'credit_card' 
            ? widget.existing!.balance // Keep the existing CC balance
            : (widget.existing!.balance - (widget.existing!.openingBalance ?? 0) + openBal);

        final updated = widget.existing!.copyWith(
          name: _nameController.text.trim(),
          type: _selectedType,
          bankName: Value(_bankNameController.text.trim().isNotEmpty ? _bankNameController.text.trim() : null),
          openingBalance: Value(openBal),
          balance: currentBal,
          colorTheme: Value(_selectedColor),
          icon: Value(_selectedIcon),
          notes: Value(_notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null),
          isActive: Value(_isActive),
          creditLimit: _selectedType == 'credit_card' ? Value(limit) : const Value(null),
          availableCredit: _selectedType == 'credit_card' ? Value(limit - (widget.existing!.outstandingBalance ?? 0)) : const Value(null),
          statementDate: _selectedType == 'credit_card' ? Value(stmtDate) : const Value(null),
          paymentDueDate: _selectedType == 'credit_card' ? Value(dueDate) : const Value(null),
          minAmountDue: _selectedType == 'credit_card' ? Value(minDue) : const Value(null),
          totalAmountDue: _selectedType == 'credit_card' ? Value(totalDue) : const Value(null),
          autoPay: Value(_selectedType == 'credit_card' ? _autoPay : false),
          last4Digits: _selectedType == 'credit_card' ? Value(_last4DigitsController.text.trim().isNotEmpty ? _last4DigitsController.text.trim() : null) : const Value(null),
          statementCycle: _selectedType == 'credit_card' ? Value(_statementCycleController.text.trim().isNotEmpty ? _statementCycleController.text.trim() : null) : const Value(null),
          enableBillReminder: _selectedType == 'credit_card' ? Value(_enableBillReminder) : const Value(null),
          enableSmsTracking: _selectedType == 'credit_card' ? Value(_enableSmsTracking) : const Value(null),
        );
        await notifier.editAccount(updated);
      } else {
        // Add mode
        final id = const Uuid().v4();
        final now = DateTime.now();
        final userId = ref.read(authProvider).user?.id;
        if (userId == null) throw Exception("User ID is null");

        // Outstanding balance for new card is 0, so availableCredit = limit, balance = 0
        final initialBalance = _selectedType == 'credit_card' ? 0 : openBal;

        final companion = AccountsCompanion.insert(
          id: id,
          userId: userId,
          name: _nameController.text.trim(),
          type: _selectedType,
          balance: Value(initialBalance),
          isDefault: const Value(false),
          createdAt: now,
          updatedAt: now,
          bankName: Value(_bankNameController.text.trim().isNotEmpty ? _bankNameController.text.trim() : null),
          openingBalance: Value(openBal),
          currency: const Value('INR'),
          colorTheme: Value(_selectedColor),
          icon: Value(_selectedIcon),
          notes: Value(_notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null),
          isActive: Value(_isActive),
          creditLimit: _selectedType == 'credit_card' ? Value(limit) : const Value(null),
          availableCredit: _selectedType == 'credit_card' ? Value(limit) : const Value(null),
          outstandingBalance: _selectedType == 'credit_card' ? const Value(0) : const Value(null),
          statementDate: _selectedType == 'credit_card' ? Value(stmtDate) : const Value(null),
          paymentDueDate: _selectedType == 'credit_card' ? Value(dueDate) : const Value(null),
          minAmountDue: _selectedType == 'credit_card' ? Value(minDue) : const Value(null),
          totalAmountDue: _selectedType == 'credit_card' ? Value(totalDue) : const Value(null),
          autoPay: _selectedType == 'credit_card' ? Value(_autoPay) : const Value(false),
          paymentStatus: _selectedType == 'credit_card' ? const Value('paid') : const Value(null),
          last4Digits: _selectedType == 'credit_card' ? Value(_last4DigitsController.text.trim().isNotEmpty ? _last4DigitsController.text.trim() : null) : const Value(null),
          statementCycle: _selectedType == 'credit_card' ? Value(_statementCycleController.text.trim().isNotEmpty ? _statementCycleController.text.trim() : null) : const Value(null),
          enableBillReminder: _selectedType == 'credit_card' ? Value(_enableBillReminder) : const Value(null),
          enableSmsTracking: _selectedType == 'credit_card' ? Value(_enableSmsTracking) : const Value(null),
        );
        await notifier.addAccount(companion);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null ? 'Account updated successfully!' : 'Account created successfully!'),
            backgroundColor: const Color(0xFF0066FF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFFF3B30)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onTypeChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedType = val;
      // Auto-assign default icon and color for type
      final matchedType = _accountTypes.firstWhere((t) => t['value'] == val);
      _selectedIcon = matchedType['icon'] ?? 'star';
      if (val == 'credit_card') {
        _selectedColor = '0xFFFF3B30'; // red
      } else if (val == 'cash') {
        _selectedColor = '0xFF00E5FF'; // cyan
      } else if (val == 'wallet') {
        _selectedColor = '0xFFFFB703'; // gold
      } else {
        _selectedColor = '0xFF0066FF'; // blue
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCC = _selectedType == 'credit_card';

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
                  Text(
                    widget.existing != null ? 'Edit Account' : 'New Account',
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

              // Account Type
              const Text('ACCOUNT TYPE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: const Color(0xFF050505),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _buildInputDecoration(icon: Icons.category_outlined),
                items: _accountTypes.map((t) {
                  return DropdownMenuItem<String>(
                    value: t['value'],
                    child: Text(t['label']!),
                  );
                }).toList(),
                onChanged: widget.existing != null ? null : _onTypeChanged,
              ),
              const SizedBox(height: 16),

              // Account Name
              const Text('ACCOUNT NAME', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(hintText: 'e.g. SBI Savings, GPay, HDFC CC', icon: Icons.badge_outlined),
                validator: (val) => val == null || val.trim().isEmpty ? 'Account name is required' : null,
              ),
              const SizedBox(height: 16),

              // Bank Name
              const Text('BANK / PROVIDER NAME', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bankNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(hintText: 'e.g. State Bank of India, Paytm, Cash', icon: Icons.account_balance_outlined),
              ),
              const SizedBox(height: 16),

              // Opening Balance
              if (widget.existing == null && !isCC) ...[
                const Text('OPENING / INITIAL BALANCE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _openingBalanceController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _buildInputDecoration(hintText: '0.00', icon: Icons.payments_outlined),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    if (double.tryParse(val) == null) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Credit Card Fields
              if (isCC) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LAST 4 DIGITS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _last4DigitsController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration(hintText: 'e.g. 1234', icon: Icons.numbers_outlined),
                            validator: (val) {
                              if (!isCC) return null;
                              if (val != null && val.isNotEmpty && val.length != 4) return 'Must be 4 digits';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('STATEMENT CYCLE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _statementCycleController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration(hintText: 'e.g. Monthly', icon: Icons.replay_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('CREDIT LIMIT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _creditLimitController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _buildInputDecoration(hintText: 'e.g. 100000.00', icon: Icons.credit_score_outlined),
                  validator: (val) => isCC && (val == null || val.isEmpty || double.tryParse(val) == null) ? 'Credit limit is required' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BILL STATEMENT DATE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _statementDateController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration(hintText: 'e.g. 15', icon: Icons.calendar_today_outlined),
                            validator: (val) {
                              if (!isCC) return null;
                              final date = int.tryParse(val ?? '');
                              if (date == null || date < 1 || date > 31) return '1 to 31';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PAYMENT DUE DATE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _paymentDueDateController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration(hintText: 'e.g. 5', icon: Icons.event_available_outlined),
                            validator: (val) {
                              if (!isCC) return null;
                              final date = int.tryParse(val ?? '');
                              if (date == null || date < 1 || date > 31) return '1 to 31';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MIN AMOUNT DUE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _minAmountDueController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _buildInputDecoration(hintText: '0.00', icon: Icons.price_change_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL AMOUNT DUE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _totalAmountDueController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _buildInputDecoration(hintText: '0.00', icon: Icons.payments_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CC Auto Pay Toggle
                SwitchListTile(
                  title: const Text('Auto Pay enabled', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Automatically schedule credit card payments', style: TextStyle(color: Colors.white30, fontSize: 11)),
                  value: _autoPay,
                  activeColor: const Color(0xFF00E5FF),
                  activeTrackColor: const Color(0xFF0066FF).withOpacity(0.3),
                  onChanged: (val) => setState(() => _autoPay = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),

                // Bill Reminder Toggle
                SwitchListTile(
                  title: const Text('Enable Bill Reminder', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Get notified when your credit card payment is due', style: TextStyle(color: Colors.white30, fontSize: 11)),
                  value: _enableBillReminder,
                  activeColor: const Color(0xFF00E5FF),
                  activeTrackColor: const Color(0xFF0066FF).withOpacity(0.3),
                  onChanged: (val) => setState(() => _enableBillReminder = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),

                // SMS Tracking Toggle
                SwitchListTile(
                  title: const Text('Enable SMS Tracking', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Automatically import transactions from SMS alerts', style: TextStyle(color: Colors.white30, fontSize: 11)),
                  value: _enableSmsTracking,
                  activeColor: const Color(0xFF00E5FF),
                  activeTrackColor: const Color(0xFF0066FF).withOpacity(0.3),
                  onChanged: (val) => setState(() => _enableSmsTracking = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
              ],

              // Color Theme Selection
              const Text('THEME COLOR', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final colorHex = _colors[idx];
                    final color = Color(int.parse(colorHex));
                    final isSelected = _selectedColor == colorHex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected 
                              ? Border.all(color: Colors.white, width: 2)
                              : Border.all(color: Colors.white12, width: 1),
                        ),
                        child: isSelected 
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Icon Picker
              const Text('ACCOUNT ICON', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final item = _icons[idx];
                    final name = item['name'] as String;
                    final icon = item['icon'] as IconData;
                    final isSelected = _selectedIcon == name;
                    final themeColor = Color(int.parse(_selectedColor));

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = name),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? themeColor.withOpacity(0.2) : Colors.white.withOpacity(0.02),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? themeColor : Colors.white12,
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          icon, 
                          color: isSelected ? themeColor : Colors.white60, 
                          size: 18,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              const Text('NOTES / REMARKS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(hintText: 'Additional details...', icon: Icons.notes_outlined),
              ),
              const SizedBox(height: 20),

              // Active Toggle
              SwitchListTile(
                title: const Text('Active Account', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Show this account in dashboards and balance summaries', style: TextStyle(color: Colors.white30, fontSize: 11)),
                value: _isActive,
                activeColor: const Color(0xFF00E5FF),
                activeTrackColor: const Color(0xFF0066FF).withOpacity(0.3),
                onChanged: (val) => setState(() => _isActive = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(int.parse(_selectedColor)),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.existing != null ? 'SAVE CHANGES' : 'CREATE ACCOUNT', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText, required IconData icon}) {
    final themeColor = Color(int.parse(_selectedColor));
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13.5),
      prefixIcon: Icon(icon, color: themeColor.withOpacity(0.8), size: 18),
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: themeColor),
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
