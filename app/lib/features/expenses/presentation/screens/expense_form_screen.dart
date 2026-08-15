import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/ledger_agent.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/category_picker.dart';
import '../widgets/payment_method_picker.dart';
import '../../../../core/database/app_database.dart';
import '../../../sms_parser/presentation/providers/sms_parser_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/account_formatters.dart';
import '../../../../shared/widgets/privacy_text.dart';
import '../../../dashboard/presentation/providers/privacy_provider.dart';
import '../../../../core/services/category_intelligence.dart';
import '../widgets/searchable_category_bottom_sheet.dart';
import '../../../../core/services/balance_engine.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  final String? draftId;
  final String? initialType;

  const ExpenseFormScreen({
    super.key,
    this.transactionId,
    this.draftId,
    this.initialType,
  });

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();
  final _receiptController = TextEditingController();
  final _billLinkController = TextEditingController();
  final _tagsController = TextEditingController();
  final _categoryController = TextEditingController();

  String _transactionType = 'expense';
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String? _selectedPaymentMethodId;
  String? _selectedAccountId;
  String? _sourceAccountId;
  String? _destAccountId;
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  bool _pendingSaveAfterCategorySelection = false;
  bool _isEditMode = false;
  bool _hasCustomTime = false;
  Transaction? _existingTransaction;
  double? _confidenceScore;
  String? _draftCategory;
  String? _matchingTransactionId;

  bool get _isTransfer => _transactionType == 'transfer_debit' || _transactionType == 'transfer_credit';

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.transactionId != null;
    if (_isEditMode) {
      _loadExistingTransaction();
    } else {
      if (widget.initialType != null) {
        _transactionType = widget.initialType!;
      }
      if (widget.draftId != null) {
        _loadDraftTransaction();
      } else {
        _setDefaultPaymentMethod();
      }
    }
    
    _merchantController.addListener(() {
      final text = _merchantController.text.trim();
      if (text.isNotEmpty && _selectedCategoryId == null) {
        _suggestCategoryForMerchant(text);
      }
    });
  }

  Future<void> _suggestCategoryForMerchant(String merchant) async {
    final lower = merchant.trim().toLowerCase();
    if (lower.isEmpty) return;

    final auth = ref.read(authProvider);
    final userId = auth.user?.id;
    if (userId == null) return;

    String? parentName;
    String? subName;

    if (lower.contains('swiggy') || lower.contains('zomato') || lower.contains('ubereats')) {
      parentName = 'Food';
      subName = 'Restaurant';
    } else if (lower.contains('amazon') || lower.contains('flipkart') || lower.contains('myntra')) {
      parentName = 'Shopping';
    } else if (lower.contains('indian oil') || lower.contains('hpcl') || lower.contains('shell') || lower.contains('bpcl') || lower.contains('petrol') || lower.contains('fuel')) {
      parentName = 'Travel';
      subName = 'Fuel';
    } else if (lower.contains('netflix') || lower.contains('spotify') || lower.contains('prime video') || lower.contains('hotstar') || lower.contains('youtube premium')) {
      parentName = 'Entertainment';
      subName = 'Subscription';
    } else if (lower.contains('salary') || lower.contains('paycheck')) {
      parentName = 'Salary';
    }

    if (parentName != null) {
      final db = ref.read(databaseProvider);
      final existingCategories = await db.categoryDao.getCategoriesForUser(userId);

      // Find or create parent
      var parent = existingCategories.firstWhere(
        (c) => c.name.toLowerCase() == parentName!.toLowerCase() && c.parentId == null,
        orElse: () => null as dynamic,
      );
      if (parent == null) {
        final newId = const Uuid().v4();
        parent = Category(
          id: newId,
          userId: userId,
          name: parentName,
          type: _transactionType,
          icon: CategoryIntelligence.getIconKeyForName(parentName),
          color: CategoryIntelligence.getColorHexForName(parentName),
          isSystemDefault: false,
          createdAt: DateTime.now(),
          usageCount: 0,
        );
        await db.categoryDao.insertCategory(parent);
        ref.invalidate(categoriesProvider);
      }

      Category? sub;
      if (subName != null) {
        // Find or create subcategory
        sub = existingCategories.firstWhere(
          (c) => c.name.toLowerCase() == subName!.toLowerCase() && c.parentId == parent!.id,
          orElse: () => null as dynamic,
        );
        if (sub == null) {
          final newId = const Uuid().v4();
          sub = Category(
            id: newId,
            userId: userId,
            name: subName,
            type: _transactionType,
            parentId: parent.id,
            icon: CategoryIntelligence.getIconKeyForName(subName),
            color: CategoryIntelligence.getColorHexForName(subName),
            isSystemDefault: false,
            createdAt: DateTime.now(),
            usageCount: 0,
          );
          await db.categoryDao.insertCategory(sub);
          ref.invalidate(categoriesProvider);
        }
      }

      setState(() {
        _selectedCategoryId = parent.id;
        _selectedSubcategoryId = sub?.id;
        _confidenceScore = 0.95;
        if (sub != null) {
          _categoryController.text = '${parent.name} > ${sub.name}';
        } else {
          _categoryController.text = parent.name;
        }
      });
    }
  }

  Future<void> _loadDraftTransaction() async {
    setState(() => _isLoading = true);
    try {
      final dao = ref.read(transactionDraftDaoProvider);
      final draft = await dao.getDraftById(widget.draftId!);
      if (draft != null && mounted) {
        String categoryText = draft.category ?? '';
        if (draft.categoryId != null) {
          final db = ref.read(databaseProvider);
          final cat = await db.categoryDao.getCategoryById(draft.categoryId!);
          if (cat != null) {
            categoryText = cat.name;
          }
        }
        setState(() {
          _amountController.text = (draft.amount / 100.0).toStringAsFixed(2);
          _descriptionController.text = draft.description ?? '';
          _merchantController.text = draft.merchant ?? '';
          _transactionType = draft.type;
          _selectedDate = draft.date;
          _hasCustomTime = true;
          _selectedCategoryId = draft.categoryId;
          _categoryController.text = categoryText;
          _confidenceScore = draft.confidenceScore;
          _draftCategory = draft.category;
          _matchingTransactionId = draft.matchingTransactionId;
        });
        await _autoDetectAccountAndPaymentMethod(draft);
      }
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

  Future<void> _autoDetectAccountAndPaymentMethod(TransactionDraft draft) async {
    final accounts = ref.read(sortedAccountsProvider).value ?? [];
    final pms = await ref.read(paymentMethodsProvider.future);
    if (accounts.isEmpty || pms.isEmpty) return;

    final smsText = (draft.smsBody ?? draft.description ?? '').toLowerCase();
    final cardOrAccNum = draft.cardOrAccount?.trim();

    Account? matchedAccount;

    // Helper: get last 4
    String getLast4(Account acc) {
      final regExp = RegExp(r'\d{3,4}$');
      final match = regExp.firstMatch(acc.name);
      return match != null ? match.group(0)! : '';
    }

    // 1. Last 4 digits match
    if (cardOrAccNum != null && cardOrAccNum.isNotEmpty) {
      for (final acc in accounts) {
        if (acc.type == 'credit_card' && getLast4(acc) == cardOrAccNum) {
          matchedAccount = acc;
          break;
        }
      }
      if (matchedAccount == null) {
        for (final acc in accounts) {
          if (acc.type == 'savings' && getLast4(acc) == cardOrAccNum) {
            matchedAccount = acc;
            break;
          }
        }
      }
    }

    // 2. Bank keyword match
    if (matchedAccount == null) {
      final bankKeywords = ['hdfc', 'icici', 'sbi', 'axis', 'federal', 'kotak', 'canara', 'union', 'pnb', 'baroda', 'idfc', 'indian'];
      String? foundBankKey;
      for (final kw in bankKeywords) {
        if (smsText.contains(kw)) {
          foundBankKey = kw;
          break;
        }
      }

      if (foundBankKey != null) {
        final isCreditCardSms = smsText.contains('credit card') || smsText.contains('card ending') || smsText.contains('cc');
        if (isCreditCardSms) {
          for (final acc in accounts) {
            if (acc.type == 'credit_card' && acc.name.toLowerCase().contains(foundBankKey)) {
              matchedAccount = acc;
              break;
            }
          }
        }
        if (matchedAccount == null) {
          for (final acc in accounts) {
            if (acc.type == 'savings' && acc.name.toLowerCase().contains(foundBankKey)) {
              matchedAccount = acc;
              break;
            }
          }
        }
      }
    }

    // 3. Wallet match
    if (matchedAccount == null) {
      final walletKeywords = ['wallet', 'paytm', 'phonepe', 'gpay', 'amazon pay'];
      bool isWalletSms = false;
      for (final kw in walletKeywords) {
        if (smsText.contains(kw)) {
          isWalletSms = true;
          break;
        }
      }
      if (isWalletSms) {
        for (final acc in accounts) {
          if (acc.type == 'wallet') {
            matchedAccount = acc;
            break;
          }
        }
      }
    }

    // 4. Cash
    if (matchedAccount == null && (smsText.contains('cash') || smsText.isEmpty)) {
      for (final acc in accounts) {
        if (acc.type == 'cash') {
          matchedAccount = acc;
          break;
        }
      }
    }

    // Fallback default
    if (matchedAccount == null) {
      final defaultAcc = accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.firstWhere((a) => a.type == 'savings', orElse: () => accounts.first));
      matchedAccount = defaultAcc;
    }

    String pmName = 'UPI';
    if (matchedAccount.type == 'credit_card') {
      pmName = 'Credit Card';
    } else if (matchedAccount.type == 'wallet') {
      pmName = 'Wallet';
    } else if (matchedAccount.type == 'cash') {
      pmName = 'Cash';
    } else {
      if (smsText.contains('atm') || smsText.contains('withdrawn')) {
        pmName = 'Debit Card';
      } else if (smsText.contains('card')) {
        pmName = 'Debit Card';
      } else if (smsText.contains('net banking') || smsText.contains('neft') || smsText.contains('imps')) {
        pmName = 'Net Banking';
      } else {
        pmName = 'UPI';
      }
    }

    final matchedPm = pms.firstWhere(
      (pm) => pm.name.toLowerCase() == pmName.toLowerCase() || pm.name.toLowerCase().contains(pmName.toLowerCase()),
      orElse: () => pms.firstWhere((pm) => pm.name.toLowerCase() == 'upi', orElse: () => pms.first),
    );

    if (mounted) {
      setState(() {
        _selectedAccountId = matchedAccount!.id;
        _selectedPaymentMethodId = matchedPm.id;
      });
    }
  }

  Future<void> _setDefaultPaymentMethod() async {
    final pms = await ref.read(paymentMethodsProvider.future);
    final accounts = ref.read(sortedAccountsProvider).value ?? [];
    if (accounts.isNotEmpty && pms.isNotEmpty && mounted) {
      if (_selectedAccountId == null) {
        final defaultAcc = accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
        _selectedAccountId = defaultAcc.id;
      }
      final activeAcc = accounts.firstWhere((a) => a.id == _selectedAccountId, orElse: () => accounts.first);
      final validPms = _getAvailablePaymentMethodsForType(activeAcc.type, pms);
      setState(() {
        if (validPms.isNotEmpty) {
          _selectedPaymentMethodId = validPms.first.id;
        } else {
          _selectedPaymentMethodId = pms.first.id;
        }
      });
    }
  }

  Future<void> _loadExistingTransaction() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final tx = await repo.getTransactionById(widget.transactionId!);
      if (tx != null && mounted) {
        final diff = tx.date.difference(tx.createdAt).abs();

        Transaction? otherSide;
        if (tx.type == 'transfer_debit' || tx.type == 'transfer_credit') {
          final db = ref.read(databaseProvider);
          if (tx.type == 'transfer_debit') {
            final list = await (db.select(db.transactions)
              ..where((t) => t.referenceNumber.equals(tx.id) & t.type.equals('transfer_credit'))
            ).get();
            if (list.isNotEmpty) otherSide = list.first;
          } else if (tx.type == 'transfer_credit' && tx.referenceNumber != null) {
            otherSide = await repo.getTransactionById(tx.referenceNumber!);
          }
        }

        _selectedCategoryId = tx.categoryId;
        _selectedSubcategoryId = tx.subcategoryId;

        String categoryText = '';
        if (_selectedCategoryId != null) {
          final db = ref.read(databaseProvider);
          final cat = await db.categoryDao.getCategoryById(_selectedCategoryId!);
          if (cat != null) {
            categoryText = cat.name;
            if (_selectedSubcategoryId != null) {
              final sub = await db.categoryDao.getCategoryById(_selectedSubcategoryId!);
              if (sub != null) {
                categoryText += ' > ${sub.name}';
              }
            }
          }
        }

        setState(() {
          _existingTransaction = tx;
          _amountController.text = (tx.amount / 100.0).toStringAsFixed(2);
          _descriptionController.text = tx.description ?? '';
          _merchantController.text = tx.merchant ?? '';
          _transactionType = tx.type;
          _selectedPaymentMethodId = tx.paymentMethodId;
          _selectedAccountId = tx.accountId;
          _selectedDate = tx.date;
          _hasCustomTime = diff.inSeconds > 10;
          _receiptController.text = tx.receiptUrl ?? '';
          _billLinkController.text = tx.billLink ?? '';
          _tagsController.text = tx.tags ?? '';
          _categoryController.text = categoryText;
          _confidenceScore = tx.confidenceScore;

          if (tx.type == 'transfer_debit' || tx.type == 'transfer_credit') {
            final debitTx = tx.type == 'transfer_debit' ? tx : otherSide;
            final creditTx = tx.type == 'transfer_credit' ? tx : otherSide;
            if (debitTx != null) _sourceAccountId = debitTx.accountId;
            if (creditTx != null) _destAccountId = creditTx.accountId;
          }
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
    _receiptController.dispose();
    _billLinkController.dispose();
    _tagsController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _openCategoryPickerSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchableCategoryBottomSheet(
        transactionType: _transactionType,
        selectedCategoryId: _selectedCategoryId,
        selectedSubcategoryId: _selectedSubcategoryId,
      ),
    );

    if (result != null) {
      final parent = result['category'] as Category;
      final sub = result['subcategory'] as Category?;

      setState(() {
        _selectedCategoryId = parent.id;
        _selectedSubcategoryId = sub?.id;
        if (sub != null) {
          _categoryController.text = '${parent.name} > ${sub.name}';
        } else {
          _categoryController.text = parent.name;
        }
      });

      if (_pendingSaveAfterCategorySelection) {
        _pendingSaveAfterCategorySelection = false;
        _saveTransaction();
      }
    } else {
      _pendingSaveAfterCategorySelection = false;
    }
  }


  Future<bool> _confirmAndCreateCategory(String name, String userId, {String? parentId}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D121B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF0066FF), width: 1.2),
        ),
        title: const Text('Create Category?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'The category "$name" does not exist. Would you like to create it?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YES'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final newId = const Uuid().v4();
        final db = ref.read(databaseProvider);
        final newCat = Category(
          id: newId,
          userId: userId,
          name: name,
          type: _transactionType,
          parentId: parentId,
          icon: CategoryIntelligence.getIconKeyForName(name),
          color: CategoryIntelligence.getColorHexForName(name),
          isSystemDefault: false,
          createdAt: DateTime.now(),
          usageCount: 1,
        );
        await db.categoryDao.insertCategory(newCat);
        ref.invalidate(categoriesProvider);
        setState(() {
          if (parentId == null) {
            _selectedCategoryId = newId;
            _selectedSubcategoryId = null;
          } else {
            _selectedCategoryId = parentId;
            _selectedSubcategoryId = newId;
          }
        });
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to auto-create category: $e')),
          );
        }
        return false;
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
    return false;
  }

  Future<String> _resolveMerchantName() async {
    String? subName;
    if (_selectedSubcategoryId != null) {
      final categories = ref.read(categoriesProvider).value ?? [];
      subName = categories.firstWhere((c) => c.id == _selectedSubcategoryId, orElse: () => null as dynamic)?.name;
      if (subName == null) {
        final db = ref.read(databaseProvider);
        final cat = await db.categoryDao.getCategoryById(_selectedSubcategoryId!);
        subName = cat?.name;
      }
    }

    String? catName;
    if (_selectedCategoryId != null) {
      final categories = ref.read(categoriesProvider).value ?? [];
      catName = categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => null as dynamic)?.name;
      if (catName == null) {
        final db = ref.read(databaseProvider);
        final cat = await db.categoryDao.getCategoryById(_selectedCategoryId!);
        catName = cat?.name;
      }
    }

    return MerchantResolver.resolve(
      enteredMerchant: _merchantController.text,
      subcategoryName: subName,
      categoryName: catName,
    );
  }

  Future<void> _saveTransaction() async {
    if (_isLoading) return;

    // STEP 1: Check amount
    if (!_formKey.currentState!.validate()) return;

    final isTransfer = _transactionType == 'transfer_debit' || _transactionType == 'transfer_credit';

    // STEP 2: Check financial account
    if (!isTransfer) {
      if (_selectedAccountId == null) {
        final accounts = ref.read(sortedAccountsProvider).value ?? [];
        final pms = await ref.read(paymentMethodsProvider.future);
        if (mounted) {
          _showAccountSelectionSheet(context, accounts, pms);
        }
        return;
      }
    } else {
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
    }

    // STEP 3: Check category
    if (!isTransfer) {
      if (_selectedCategoryId == null || _categoryController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        _pendingSaveAfterCategorySelection = true;
        _openCategoryPickerSheet();
        return;
      }
    }

    // Authenticated user check & category database insertion if missing
    final auth = ref.read(authProvider);
    final userId = auth.user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User is not authenticated')),
      );
      return;
    }

    if (!isTransfer) {
      final db = ref.read(databaseProvider);
      final existingCategories = await db.categoryDao.getCategoriesForUser(userId);

      var categoryText = _categoryController.text.trim();
      String parentName = categoryText;
      String? subName;
      if (categoryText.contains(' > ')) {
        final parts = categoryText.split(' > ');
        parentName = parts[0].trim();
        subName = parts[1].trim();
      }

      final matchedParent = existingCategories.firstWhere(
        (c) => c.name.toLowerCase() == parentName.toLowerCase() && c.parentId == null,
        orElse: () => null as dynamic,
      );

      if (matchedParent != null) {
        _selectedCategoryId = matchedParent.id;
        if (subName != null) {
          final matchedSub = existingCategories.firstWhere(
            (c) => c.name.toLowerCase() == subName!.toLowerCase() && c.parentId == matchedParent.id,
            orElse: () => null as dynamic,
          );
          if (matchedSub != null) {
            _selectedSubcategoryId = matchedSub.id;
          } else {
            final created = await _confirmAndCreateCategory(subName, userId, parentId: matchedParent.id);
            if (!created) return;
          }
        } else {
          _selectedSubcategoryId = null;
        }
      } else {
        final created = await _confirmAndCreateCategory(categoryText, userId);
        if (!created) return;
      }

      if (_selectedPaymentMethodId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a payment method')),
        );
        return;
      }
    }

    // STEP 4: Resolve merchant fallback
    final resolvedMerchant = await _resolveMerchantName();

    setState(() => _isLoading = true);

    try {
      final doubleAmount = double.parse(_amountController.text);
      final intAmount = (doubleAmount * 100).round();

      final now = DateTime.now();
      final txDate = _hasCustomTime
          ? _selectedDate
          : DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              now.hour,
              now.minute,
              now.second,
            );

      final notifier = ref.read(expenseListNotifierProvider.notifier);

      if (isTransfer) {
        if (_isEditMode && _existingTransaction != null) {
          final otherSide = await notifier.getOtherSideOfTransfer(_existingTransaction!);
          if (otherSide != null) {
            final debitTx = _existingTransaction!.type == 'transfer_debit' ? _existingTransaction! : otherSide;
            final creditTx = _existingTransaction!.type == 'transfer_credit' ? _existingTransaction! : otherSide;

            final accounts = ref.read(sortedAccountsProvider).value ?? [];
            final fromAcc = accounts.firstWhere((a) => a.id == _sourceAccountId, orElse: () => accounts.first);
            final toAcc = accounts.firstWhere((a) => a.id == _destAccountId, orElse: () => accounts.first);

            final updatedDebit = debitTx.copyWith(
              accountId: Value(_sourceAccountId),
              amount: intAmount,
              date: txDate,
              description: _descriptionController.text.isNotEmpty ? Value(_descriptionController.text) : const Value(null),
              merchant: Value('To ${toAcc.name}'),
              updatedAt: now,
            );

            final updatedCredit = creditTx.copyWith(
              accountId: Value(_destAccountId),
              amount: intAmount,
              date: txDate,
              description: _descriptionController.text.isNotEmpty ? Value(_descriptionController.text) : const Value(null),
              merchant: Value('From ${fromAcc.name}'),
              updatedAt: now,
            );

            await notifier.editTransaction(updatedDebit);
          }
        }
      } else {
        final transaction = Transaction(
          id: _isEditMode ? _existingTransaction!.id : const Uuid().v4(),
          userId: userId,
          accountId: _selectedAccountId,
          categoryId: _selectedCategoryId,
          subcategoryId: _selectedSubcategoryId,
          paymentMethodId: _selectedPaymentMethodId,
          type: _transactionType,
          amount: intAmount,
          currency: auth.user?.currency ?? 'INR',
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
          merchant: resolvedMerchant,
          date: txDate,
          source: _isEditMode ? _existingTransaction!.source : 'manual',
          confidenceScore: _isEditMode ? _existingTransaction!.confidenceScore : null,
          isRecurring: _isEditMode ? _existingTransaction!.isRecurring : false,
          syncStatus: 'pending',
          createdAt: _isEditMode ? _existingTransaction!.createdAt : now,
          updatedAt: now,
          receiptUrl: _receiptController.text.isNotEmpty ? _receiptController.text : null,
          billLink: _billLinkController.text.isNotEmpty ? _billLinkController.text : null,
          tags: _tagsController.text.isNotEmpty ? _tagsController.text : null,
        );

        // Smart Bill Detection (Requirement 5)
        Transaction? matchedPendingBill;
        if (!_isEditMode && _transactionType == 'expense') {
          final db = ref.read(databaseProvider);
          final pendingBills = await (db.select(db.transactions)
            ..where((t) => t.userId.equals(userId) & 
                           (t.type.equals('upcoming_bill') | t.type.equals('credit_card_bill') | t.type.equals('credit_card_bill_reminder')) & 
                           (t.billStatus.equals('pending') | t.billStatus.isNull()))
          ).get();

          for (var bill in pendingBills) {
            final amountMatches = (bill.amount - intAmount).abs() < 1000; // within 10 rupees
            final billName = (bill.merchant ?? bill.description ?? '').toLowerCase();
            final formName = _merchantController.text.toLowerCase().trim();
            
            if (amountMatches && formName.isNotEmpty && (billName.contains(formName) || formName.contains(billName))) {
              matchedPendingBill = bill;
              break;
            }
          }
        }

        if (matchedPendingBill != null && mounted) {
          final confirmPayBill = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0C0C0C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF0066FF), width: 1.2),
              ),
              title: const Text('Match Upcoming Bill', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              content: Text(
                'This expense matches your upcoming "${matchedPendingBill!.merchant ?? matchedPendingBill!.description ?? 'Bill'}" (₹${(matchedPendingBill!.amount / 100.0).toStringAsFixed(2)}). Would you like to mark that bill as paid?',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes, Mark Paid'),
                ),
              ],
            ),
          );

          if (confirmPayBill == true) {
            final db = ref.read(databaseProvider);
            final updatedBill = matchedPendingBill!.copyWith(
              billStatus: const Value('paid'),
              accountId: Value(_selectedAccountId),
              paymentMethodId: Value(_selectedPaymentMethodId),
              updatedAt: DateTime.now(),
            );
            await db.transactionDao.updateTransaction(updatedBill);
            ref.invalidate(accountsProvider);
          }
        }

        if (_matchingTransactionId != null) {
          final db = ref.read(databaseProvider);
          final manualTx = await (db.select(db.transactions)..where((t) => t.id.equals(_matchingTransactionId!))).getSingleOrNull();
          if (manualTx != null) {
            String mergeStrings(String? a, String? b) {
              if (a == null || a.isEmpty) return b ?? '';
              if (b == null || b.isEmpty) return a;
              if (a.toLowerCase().contains(b.toLowerCase())) return a;
              if (b.toLowerCase().contains(a.toLowerCase())) return b;
              return '$a / $b';
            }

            final mergedDesc = mergeStrings(manualTx.description, transaction.description);
            final mergedMerchant = mergeStrings(manualTx.merchant, transaction.merchant) ?? 'Merged Merchant';

            List<String> smsList = [];
            if (manualTx.supportingSms != null && manualTx.supportingSms!.isNotEmpty) {
              try {
                smsList = List<String>.from(jsonDecode(manualTx.supportingSms!));
              } catch (_) {}
            }
            if (manualTx.description != null && !smsList.contains(manualTx.description)) {
              smsList.add(manualTx.description!);
            }
            final newSmsText = transaction.description ?? transaction.merchant ?? 'SMS Alert';
            if (!smsList.contains(newSmsText)) {
              smsList.add(newSmsText);
            }

            final mergedRef = (manualTx.referenceNumber == null || manualTx.referenceNumber!.isEmpty)
                ? transaction.referenceNumber
                : manualTx.referenceNumber;

            final ledgerAgent = ref.read(ledgerAgentProvider);
            final fingerprint = ledgerAgent.generateFingerprint(
              accountId: manualTx.accountId,
              amount: manualTx.amount,
              merchant: mergedMerchant,
              date: manualTx.date,
              referenceNumber: mergedRef,
            );

            final mergedTx = manualTx.copyWith(
              description: Value(mergedDesc),
              merchant: Value(mergedMerchant),
              categoryId: Value(manualTx.categoryId ?? transaction.categoryId),
              subcategoryId: Value(manualTx.subcategoryId ?? transaction.subcategoryId),
              paymentMethodId: Value(manualTx.paymentMethodId ?? transaction.paymentMethodId),
              referenceNumber: Value(mergedRef),
              fingerprint: Value(fingerprint),
              supportingSms: Value(jsonEncode(smsList)),
              updatedAt: DateTime.now(),
            );
            await notifier.editTransaction(mergedTx);
          }
        } else {
          if (_isEditMode) {
            await notifier.editTransaction(transaction);
          } else {
            await notifier.addTransaction(transaction);
          }
        }
      }

      if (widget.draftId != null) {
        await ref.read(smsScannerProvider.notifier).dismissDraft(widget.draftId!);
        final db = ref.read(databaseProvider);
        await BalanceEngine(db).recalculateAllBalances();
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

  Widget _buildTransferAccountDropdown({
    required String label,
    required String? value,
    required List<Account> accounts,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: value,
              dropdownColor: const Color(0xFF0F1A1C),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              hint: const Text('Select Account', style: TextStyle(color: Colors.white24, fontSize: 14)),
              items: accounts.map((a) {
                return DropdownMenuItem<String>(
                  value: a.id,
                  child: Row(
                    children: [
                      Icon(_getAccountIcon(a.icon, a.type), color: const Color(0xFF00E5FF), size: 18),
                      const SizedBox(width: 12),
                      Text(a.displayTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getAccountIcon(String? iconName, String type) {
    if (iconName != null && iconName.isNotEmpty) {
      switch (iconName.toLowerCase()) {
        case 'cash':
        case 'account_balance_wallet':
          return Icons.account_balance_wallet_outlined;
        case 'savings':
        case 'bank':
        case 'account_balance':
          return Icons.account_balance_outlined;
        case 'current':
        case 'building':
        case 'business':
          return Icons.business_outlined;
        case 'wallet':
          return Icons.wallet_outlined;
        case 'credit_card':
          return Icons.credit_card_outlined;
        case 'investment':
          return Icons.trending_up_rounded;
      }
    }

    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.account_balance_wallet_outlined;
      case 'savings':
      case 'salary':
      case 'current':
        return Icons.account_balance_outlined;
      case 'wallet':
      case 'upi_wallet':
      case 'digital_wallet':
        return Icons.wallet_outlined;
      case 'credit_card':
        return Icons.credit_card_outlined;
      case 'investment':
      case 'gold':
      case 'cryptocurrency_wallet':
        return Icons.trending_up_rounded;
      case 'loan':
        return Icons.monetization_on_outlined;
      default:
        return Icons.account_balance_outlined;
    }
  }

  Color _getAccountColor(String? colorStr, String type) {
    if (colorStr != null && colorStr.isNotEmpty) {
      try {
        return Color(int.parse(colorStr));
      } catch (_) {}
    }
    switch (type.toLowerCase()) {
      case 'credit_card':
      case 'loan':
        return const Color(0xFFFF3B30);
      case 'cash':
        return const Color(0xFF00E5FF);
      case 'wallet':
      case 'upi_wallet':
        return const Color(0xFFFFB703);
      default:
        return const Color(0xFF0066FF);
    }
  }

  Widget _buildBankLogo(Account acc) {
    final name = (acc.bankName ?? acc.name).toLowerCase();
    Color logoBg = Colors.white24;
    String initial = '';

    if (name.contains('sbi') || name.contains('state bank')) {
      logoBg = const Color(0xFF0066FF);
      initial = 'S';
    } else if (name.contains('hdfc')) {
      logoBg = const Color(0xFF1C3F94);
      initial = 'H';
    } else if (name.contains('icici')) {
      logoBg = const Color(0xFFF28500);
      initial = 'I';
    } else if (name.contains('google') || name.contains('gpay')) {
      logoBg = const Color(0xFFEA4335);
      initial = 'G';
    } else if (name.contains('phonepe')) {
      logoBg = const Color(0xFF5F259F);
      initial = 'P';
    } else if (name.contains('paytm')) {
      logoBg = const Color(0xFF00B9F5);
      initial = 'P';
    } else if (name.contains('cash')) {
      logoBg = const Color(0xFF00E5FF);
      initial = 'C';
    } else {
      logoBg = Colors.white10;
      initial = acc.name.isNotEmpty ? acc.name[0].toUpperCase() : 'A';
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: logoBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  List<PaymentMethod> _getAvailablePaymentMethodsForType(String type, List<PaymentMethod> allMethods) {
    final t = type.toLowerCase();
    if (t == 'cash') {
      return allMethods.where((pm) => pm.name.toLowerCase() == 'cash').toList();
    } else if (t == 'savings' || t == 'current') {
      return allMethods.where((pm) {
        final name = pm.name.toLowerCase();
        return name == 'upi' || name == 'debit card' || name == 'debit_card' || name == 'net banking' || name == 'net_banking';
      }).toList();
    } else if (t == 'credit_card') {
      return allMethods.where((pm) {
        final name = pm.name.toLowerCase();
        return name == 'credit card' || name == 'credit_card' || name == 'upi' || name == 'net banking' || name == 'net_banking';
      }).toList();
    } else if (t == 'wallet') {
      return allMethods.where((pm) {
        final name = pm.name.toLowerCase();
        return name == 'wallet balance' || name == 'wallet_balance' || name == 'upi';
      }).toList();
    } else if (t == 'loan' || t == 'loan_account') {
      return allMethods.where((pm) {
        final name = pm.name.toLowerCase();
        return name == 'loan disbursement' || name == 'loan_disbursement' || name == 'emi payment' || name == 'emi_payment';
      }).toList();
    } else if (t == 'investment') {
      return allMethods.where((pm) {
        final name = pm.name.toLowerCase();
        return name == 'buy' || name == 'sell' || name == 'transfer';
      }).toList();
    }
    return allMethods;
  }

  void _onAccountChanged(Account acc, List<PaymentMethod> allMethods) {
    setState(() {
      _selectedAccountId = acc.id;
      final validMethods = _getAvailablePaymentMethodsForType(acc.type, allMethods);
      if (validMethods.isNotEmpty) {
        final isCurrentValid = validMethods.any((pm) => pm.id == _selectedPaymentMethodId);
        if (!isCurrentValid) {
          _selectedPaymentMethodId = validMethods.first.id;
        }
      } else {
        _selectedPaymentMethodId = null;
      }
    });
  }

  void _showAccountSelectionSheet(BuildContext context, List<Account> accounts, List<PaymentMethod> allMethods) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050505),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Financial Account',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final acc = accounts[index];
                      final isSelected = acc.id == _selectedAccountId;
                      final isCC = acc.type == 'credit_card';
                      final balance = isCC ? (acc.outstandingBalance ?? 0) : acc.balance;
                      final balanceVal = isCC ? ((acc.creditLimit ?? 0) - balance) : balance;

                      return GestureDetector(
                        onTap: () {
                          _onAccountChanged(acc, allMethods);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0066FF).withOpacity(0.08) : Colors.white.withOpacity(0.015),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0066FF).withOpacity(0.4) : Colors.white.withOpacity(0.04),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildBankLogo(acc),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      acc.displayTitle,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      acc.displaySubtitle,
                                      style: const TextStyle(color: Colors.white30, fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                              PrivacyText(
                                rawValue: NumberFormat.simpleCurrency(name: 'INR').format(balanceVal / 100.0),
                                isAccountBalance: true,
                                style: TextStyle(
                                  color: isCC ? const Color(0xFFFF3B30) : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumAccountCard(Account selectedAcc, List<Account> accounts, List<PaymentMethod> allMethods) {
    final isCC = selectedAcc.type == 'credit_card';
    final balance = isCC ? (selectedAcc.outstandingBalance ?? 0) : selectedAcc.balance;
    final balanceLabel = isCC ? 'Available Credit' : 'Available Balance';
    final balanceVal = isCC ? ((selectedAcc.creditLimit ?? 0) - balance) : selectedAcc.balance;

    return GestureDetector(
      onTap: () => _showAccountSelectionSheet(context, accounts, allMethods),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.15), width: 1.2),
        ),
        child: Row(
          children: [
            _buildBankLogo(selectedAcc),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedAcc.displayTitle,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  PrivacyText(
                    rawValue: '$balanceLabel: ${NumberFormat.simpleCurrency(name: 'INR').format(balanceVal / 100.0)}',
                    isAccountBalance: true,
                    style: TextStyle(
                      color: isCC ? const Color(0xFFFF3B30) : const Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final currencySymbol = auth.user?.currency == 'USD' ? '\$' : '₹';

    if (_isLoading && _existingTransaction == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
      );
    }

    return Scaffold(
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
              // Screen Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      _isEditMode ? (_isTransfer ? 'Edit Transfer' : 'Edit Transaction') : 'Add Transaction',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_rounded, color: Colors.white),
                      onPressed: _isLoading ? null : _saveTransaction,
                    ),
                  ],
                ),
              ),

              // Form content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (!_isTransfer) ...[
                        // Segmented Income/Expense Selector
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTypeButton(
                                  label: 'Expense',
                                  type: 'expense',
                                  activeColor: const Color(0xFFFF3B30),
                                ),
                              ),
                              Expanded(
                                child: _buildTypeButton(
                                  label: 'Income',
                                  type: 'income',
                                  activeColor: const Color(0xFF00E5FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Giant Amount Field
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'AMOUNT',
                              style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.01),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.02)),
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currencySymbol,
                                        style: const TextStyle(color: Colors.white70, fontSize: 44, fontWeight: FontWeight.bold),
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
                                            contentPadding: EdgeInsets.zero,
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
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      if (!_isTransfer) ...[
                        Row(
                          children: [
                            const Text(
                              'CATEGORY',
                              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                            if (_confidenceScore != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2), width: 0.8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 10),
                                    SizedBox(width: 4),
                                    Text(
                                      '✨ AI Suggested',
                                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _openCategoryPickerSheet,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                () {
                                  final text = _categoryController.text.trim();
                                  final name = text.contains(' > ') ? text.split(' > ').last : text;
                                  final color = text.isEmpty ? Colors.white24 : CategoryIntelligence.getColorForName(name);
                                  final icon = text.isEmpty ? Icons.folder_outlined : CategoryIntelligence.getIconForName(name);
                                  return Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: color, size: 20),
                                  );
                                }(),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _categoryController.text.trim().isNotEmpty
                                        ? _categoryController.text.trim()
                                        : 'Select Category (Defaults to Other)...',
                                    style: TextStyle(
                                      color: _categoryController.text.trim().isNotEmpty ? Colors.white : Colors.white24,
                                      fontSize: 14.5,
                                      fontWeight: _categoryController.text.trim().isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.white30, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (!_isTransfer && _confidenceScore != null && _confidenceScore! < 0.90) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9500).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFFF9500).withOpacity(0.2), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9500).withOpacity(0.02),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.report_gmailerrorred_rounded, color: Colors.orangeAccent.shade400, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "AI couldn't confidently identify the category.",
                                        style: TextStyle(
                                          color: Colors.orangeAccent.shade200,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Suggested Details Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'SUGGESTED CATEGORY',
                                          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _categoryController.text.isNotEmpty ? _categoryController.text : (_draftCategory ?? 'Shopping'),
                                          style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'CONFIDENCE',
                                          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(_confidenceScore! * 100).toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            color: Colors.orangeAccent.shade400,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Action Buttons wrap/row
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Accept Suggestion
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0066FF),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _confidenceScore = 1.0;
                                        });
                                      },
                                      icon: const Icon(Icons.done_rounded, size: 14),
                                      label: const Text('Accept Suggestion', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    ),
                                    // Choose Another Category
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white70,
                                        side: BorderSide(color: Colors.white.withOpacity(0.12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => _openCategoryPickerSheet(),
                                      icon: const Icon(Icons.category_outlined, size: 14),
                                      label: const Text('Choose Another', style: TextStyle(fontSize: 11.5)),
                                    ),
                                    // Always Learn This Merchant
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF00E5FF),
                                        side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () async {
                                        final cleanMerchant = _merchantController.text.toLowerCase().trim();
                                        if (cleanMerchant.isNotEmpty) {
                                          final db = ref.read(databaseProvider);
                                          final userId = ref.read(authProvider).user?.id;
                                          if (userId != null) {
                                            final catKey = 'merchant_category_override:$cleanMerchant';
                                            final typeKey = 'merchant_type_override:$cleanMerchant';

                                            await db.into(db.aiMemories).insertOnConflictUpdate(
                                              AiMemoriesCompanion.insert(
                                                id: const Uuid().v4(),
                                                userId: userId,
                                                memoryType: 'preference',
                                                memoryKey: catKey,
                                                memoryValue: _selectedCategoryId ?? '',
                                                createdAt: DateTime.now(),
                                              ),
                                            );
                                            await db.into(db.aiMemories).insertOnConflictUpdate(
                                              AiMemoriesCompanion.insert(
                                                id: const Uuid().v4(),
                                                userId: userId,
                                                memoryType: 'preference',
                                                memoryKey: typeKey,
                                                memoryValue: _transactionType,
                                                createdAt: DateTime.now(),
                                              ),
                                            );

                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Expenso will always categorize "$cleanMerchant" as "${_categoryController.text}"!'),
                                                  backgroundColor: const Color(0xFF0F1A1C),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.psychology_outlined, size: 14),
                                      label: const Text('Always Learn This', style: TextStyle(fontSize: 11.5)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Subcategory Selector (Optional)
                        if (_selectedCategoryId != null) ...[
                          ref.watch(categoriesProvider).when(
                            data: (categories) {
                              final subs = categories
                                  .where((c) => c.parentId == _selectedCategoryId)
                                  .toList();
                              if (subs.isEmpty) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SUBCATEGORY (OPTIONAL)',
                                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.02),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<String?>(
                                        value: _selectedSubcategoryId,
                                        dropdownColor: const Color(0xFF0F1A1C),
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        hint: const Text('None', style: TextStyle(color: Colors.white24, fontSize: 14)),
                                        items: [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('None', style: TextStyle(color: Colors.white54)),
                                          ),
                                          ...subs.map((s) => DropdownMenuItem<String?>(
                                                value: s.id,
                                                child: Text(s.name),
                                              )),
                                        ],
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedSubcategoryId = val;
                                            final parent = categories.firstWhere((c) => c.id == _selectedCategoryId);
                                            if (val != null) {
                                              final sub = categories.firstWhere((c) => c.id == val);
                                              _categoryController.text = '${parent.name} > ${sub.name}';
                                            } else {
                                              _categoryController.text = parent.name;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ],

                      if (_isTransfer) ...[
                        ref.watch(sortedAccountsProvider).when(
                          data: (accounts) {
                            if (accounts.isEmpty) return const SizedBox.shrink();
                            final activeAccs = accounts.where((a) => a.isActive == true).toList();
                            return _buildTransferAccountDropdown(
                              label: 'FROM ACCOUNT',
                              value: _sourceAccountId,
                              accounts: activeAccs,
                              onChanged: (val) => setState(() => _sourceAccountId = val),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                          error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(height: 24),

                        ref.watch(sortedAccountsProvider).when(
                          data: (accounts) {
                            if (accounts.isEmpty) return const SizedBox.shrink();
                            final activeAccs = accounts.where((a) => a.isActive == true && a.id != _sourceAccountId).toList();
                            return _buildTransferAccountDropdown(
                              label: 'TO ACCOUNT',
                              value: _destAccountId,
                              accounts: activeAccs,
                              onChanged: (val) => setState(() => _destAccountId = val),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                          error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        // Account Selection Section
                        const Text(
                          'FINANCIAL ACCOUNT',
                          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 12),
                        ref.watch(sortedAccountsProvider).when(
                          data: (accounts) {
                            if (accounts.isEmpty) return const SizedBox.shrink();

                            if (_selectedAccountId == null) {
                              final defaultAcc = accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
                              _selectedAccountId = defaultAcc.id;
                            }

                            final activeAcc = accounts.firstWhere((a) => a.id == _selectedAccountId, orElse: () => accounts.first);

                            return ref.watch(paymentMethodsProvider).when(
                              data: (allMethods) {
                                return _buildPremiumAccountCard(activeAcc, accounts, allMethods);
                              },
                              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                              error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                          error: (err, _) => Text('Error loading accounts: $err', style: const TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(height: 24),

                        // Payment Method Section
                        const Text(
                          'PAYMENT METHOD',
                          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 12),
                        ref.watch(sortedAccountsProvider).when(
                          data: (accounts) {
                            final activeAcc = accounts.firstWhere((a) => a.id == _selectedAccountId, orElse: () => accounts.first);
                            return PaymentMethodPicker(
                              selectedPaymentMethodId: _selectedPaymentMethodId,
                              accountType: activeAcc.type,
                              onPaymentMethodSelected: (pm) {
                                setState(() {
                                  _selectedPaymentMethodId = pm.id;
                                });
                              },
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Note & Merchant Fields
                      const Text(
                        'DETAILS',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _merchantController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _buildInputDecoration(
                          hintText: 'Merchant (e.g. Starbucks, Amazon)',
                          icon: Icons.storefront,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _buildInputDecoration(
                          hintText: 'Description / Notes',
                          icon: Icons.description,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Date & Time Picker
                      const Text(
                        'DATE & TIME',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDateOnly,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Color(0xFF0066FF), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
                                        style: const TextStyle(color: Colors.white, fontSize: 15),
                                      ),
                                      if (_hasCustomTime) ...[
                                        const SizedBox(width: 12),
                                        AnimatedOpacity(
                                          opacity: _hasCustomTime ? 1.0 : 0.0,
                                          duration: const Duration(milliseconds: 300),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.access_time, color: Color(0xFF00E5FF), size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat('hh:mm a').format(_selectedDate),
                                                style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.access_time_outlined, color: Colors.white70, size: 20),
                                onPressed: _pickTimeOnly,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Receipt Section
                      const Text(
                        'RECEIPT',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _receiptController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _buildInputDecoration(
                                hintText: 'Receipt (URL or Image Path)',
                                icon: Icons.receipt_long,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.camera_alt, color: Color(0xFF0066FF)),
                            onPressed: _pickReceiptImage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bill Link Section
                      const Text(
                        'BILL LINK',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _billLinkController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _buildInputDecoration(
                          hintText: 'Bill URL or PDF path',
                          icon: Icons.link,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tags Section
                      const Text(
                        'TAGS',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tagsController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _buildInputDecoration(
                          hintText: 'Tags (comma separated, e.g. food, trip)',
                          icon: Icons.local_offer,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Save, Duplicate, Delete, Cancel Action Buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                              shadowColor: const Color(0xFF0066FF).withOpacity(0.3),
                            ),
                            onPressed: _isLoading ? null : _saveTransaction,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    _isEditMode ? (_isTransfer ? 'UPDATE TRANSFER' : 'UPDATE TRANSACTION') : 'SAVE TRANSACTION',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          if (_isEditMode) ...[
                            if (_isTransfer) ...[
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF3B30),
                                  side: const BorderSide(color: Color(0xFFFF3B30)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _isLoading ? null : _deleteTransaction,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline, size: 16),
                                    SizedBox(width: 6),
                                    Text('DELETE TRANSFER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ] else ...[
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
                                      onPressed: _isLoading ? null : _duplicateTransaction,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.copy_rounded, size: 16),
                                          SizedBox(width: 6),
                                          Text('DUPLICATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFFF3B30),
                                        side: const BorderSide(color: Color(0xFFFF3B30)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      onPressed: _isLoading ? null : _deleteTransaction,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.delete_outline, size: 16),
                                          SizedBox(width: 6),
                                          Text('DELETE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white12),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => context.pop(),
                            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
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
  }) {
    final isSelected = _transactionType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = type;
          _selectedCategoryId = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor.withOpacity(0.4) : Colors.transparent,
            width: 1.2,
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
      prefixIcon: Icon(icon, color: const Color(0xFF0066FF), size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0066FF)),
      ),
    );
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final confirm = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF050505),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Colors.white70),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.white70),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (confirm != null) {
      try {
        final image = await picker.pickImage(source: confirm);
        if (image != null && mounted) {
          setState(() {
            _receiptController.text = image.path;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick image: $e')),
          );
        }
      }
    }
  }

  Future<void> _pickDateOnly() async {
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
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDate.hour,
          _selectedDate.minute,
          _selectedDate.second,
        );
      });
    }
  }

  Future<void> _pickTimeOnly() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
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

    if (pickedTime != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _hasCustomTime = true;
      });
    }
  }

  Future<void> _duplicateTransaction() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) throw Exception('User not authenticated');

      final doubleAmount = double.parse(_amountController.text);
      final intAmount = (doubleAmount * 100).round();

      final now = DateTime.now();
      final resolvedMerchant = await _resolveMerchantName();

      final duplicatedTx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: _selectedAccountId,
        categoryId: _selectedCategoryId,
        paymentMethodId: _selectedPaymentMethodId,
        type: _transactionType,
        amount: intAmount,
        currency: auth.user?.currency ?? 'INR',
        description: _descriptionController.text.isNotEmpty ? '${_descriptionController.text} (Copy)' : 'Copy',
        merchant: resolvedMerchant,
        date: now,
        source: 'manual',
        syncStatus: 'pending',
        createdAt: now,
        updatedAt: now,
        receiptUrl: _receiptController.text.isNotEmpty ? _receiptController.text : null,
        billLink: _billLinkController.text.isNotEmpty ? _billLinkController.text : null,
        tags: _tagsController.text.isNotEmpty ? _tagsController.text : null,
        isRecurring: _isEditMode ? _existingTransaction!.isRecurring : false,
      );

      await ref.read(expenseListNotifierProvider.notifier).addTransaction(duplicatedTx);
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction duplicated successfully!'),
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTransaction() async {
    if (_existingTransaction == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        title: const Text('Delete Transaction', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this transaction?', style: TextStyle(color: Colors.white70)),
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

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(expenseListNotifierProvider.notifier).removeTransaction(_existingTransaction!.id);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully!'),
            backgroundColor: Color(0xFFFF3B30),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
