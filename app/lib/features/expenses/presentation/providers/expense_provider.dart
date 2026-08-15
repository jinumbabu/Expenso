import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/create_transaction_usecase.dart';
import '../../domain/usecases/delete_transaction_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_payment_methods_usecase.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/update_transaction_usecase.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/ocr_service.dart';

// Repository Provider
final Provider<ExpenseRepository> expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseRepositoryImpl(
    db.accountDao,
    db.categoryDao,
    db.paymentMethodDao,
    db.transactionDao,
    db,
  );
});

// Use Case Providers
final Provider<GetTransactionsUseCase> getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return GetTransactionsUseCase(repo);
});

final Provider<CreateTransactionUseCase> createTransactionUseCaseProvider = Provider<CreateTransactionUseCase>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return CreateTransactionUseCase(repo);
});

final Provider<UpdateTransactionUseCase> updateTransactionUseCaseProvider = Provider<UpdateTransactionUseCase>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return UpdateTransactionUseCase(repo);
});

final Provider<DeleteTransactionUseCase> deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return DeleteTransactionUseCase(repo);
});

final Provider<GetCategoriesUseCase> getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return GetCategoriesUseCase(repo);
});

final Provider<GetPaymentMethodsUseCase> getPaymentMethodsUseCaseProvider = Provider<GetPaymentMethodsUseCase>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return GetPaymentMethodsUseCase(repo);
});

// Category and Payment Method Future Providers (Ranked/Seeded)
final FutureProvider<List<Category>> categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return [];
  return await ref.watch(getCategoriesUseCaseProvider).execute(userId);
});

final FutureProvider<List<PaymentMethod>> paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return [];

  final db = ref.watch(databaseProvider);
  final existing = await ref.watch(getPaymentMethodsUseCaseProvider).execute(userId);

  final requiredPms = [
    {'name': 'Cash', 'type': 'cash'},
    {'name': 'UPI', 'type': 'upi'},
    {'name': 'Credit Card', 'type': 'card'},
    {'name': 'Debit Card', 'type': 'card'},
    {'name': 'Net Banking', 'type': 'bank'},
    {'name': 'Wallet Balance', 'type': 'wallet'},
    {'name': 'Loan Disbursement', 'type': 'loan'},
    {'name': 'EMI Payment', 'type': 'loan'},
    {'name': 'Buy', 'type': 'investment'},
    {'name': 'Sell', 'type': 'investment'},
    {'name': 'Transfer', 'type': 'investment'},
  ];

  bool addedAny = false;
  final now = DateTime.now();
  for (var req in requiredPms) {
    final name = req['name']!;
    final type = req['type']!;
    final exists = existing.any((pm) => pm.name.toLowerCase() == name.toLowerCase());
    if (!exists) {
      await db.paymentMethodDao.insertPaymentMethod(
        PaymentMethod(
          id: const Uuid().v4(),
          userId: userId,
          name: name,
          type: type,
          createdAt: now,
          usageCount: 0,
        ),
      );
      addedAny = true;
    }
  }

  if (addedAny) {
    return await ref.watch(getPaymentMethodsUseCaseProvider).execute(userId);
  }
  return existing;
});

// Transaction List State Notifier
class ExpenseListNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final GetTransactionsUseCase _getTransactions;
  final CreateTransactionUseCase _createTransaction;
  final UpdateTransactionUseCase _updateTransaction;
  final DeleteTransactionUseCase _deleteTransaction;
  final String? _userId;
  final Ref _ref;

  ExpenseListNotifier({
    required GetTransactionsUseCase getTransactions,
    required CreateTransactionUseCase createTransaction,
    required UpdateTransactionUseCase updateTransaction,
    required DeleteTransactionUseCase deleteTransaction,
    required String? userId,
    required Ref ref,
  }) : _getTransactions = getTransactions,
       _createTransaction = createTransaction,
       _updateTransaction = updateTransaction,
       _deleteTransaction = deleteTransaction,
       _userId = userId,
       _ref = ref,
       super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final txs = await _getTransactions.execute(_userId);
      state = AsyncValue.data(txs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTransaction(Transaction tx) async {
    try {
      state = const AsyncValue.loading();
      await _createTransaction.execute(tx);
      // Refresh categories list to update usage ranking
      _ref.invalidate(categoriesProvider);
      _ref.invalidate(accountsProvider);
      await loadTransactions();
      if (_userId != null) {
        _checkBudgetAlerts(_userId);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Transaction?> getOtherSideOfTransfer(Transaction tx) async {
    final repo = _ref.read(expenseRepositoryProvider);
    final db = _ref.read(databaseProvider);
    if (tx.type == 'transfer_debit') {
      final list = await (db.select(db.transactions)
        ..where((t) => t.referenceNumber.equals(tx.id) & t.type.equals('transfer_credit'))
      ).get();
      return list.isNotEmpty ? list.first : null;
    } else if (tx.type == 'transfer_credit' && tx.referenceNumber != null) {
      return repo.getTransactionById(tx.referenceNumber!);
    }
    return null;
  }

  Future<void> editTransaction(Transaction tx) async {
    try {
      state = const AsyncValue.loading();
      
      final repo = _ref.read(expenseRepositoryProvider);
      if (tx.type == 'transfer_debit' || tx.type == 'transfer_credit') {
        final otherSide = await getOtherSideOfTransfer(tx);
        if (otherSide != null) {
          final debitTx = tx.type == 'transfer_debit' ? tx : otherSide;
          final creditTx = tx.type == 'transfer_credit' ? tx : otherSide;

          final accounts = _ref.read(accountsProvider).value ?? [];
          final fromAcc = accounts.firstWhere((a) => a.id == debitTx.accountId, orElse: () => accounts.first);
          final toAcc = accounts.firstWhere((a) => a.id == creditTx.accountId, orElse: () => accounts.first);

          final updatedDebit = debitTx.copyWith(
            amount: tx.amount,
            date: tx.date,
            description: tx.description != null ? Value(tx.description) : const Value(null),
            merchant: Value('To ${toAcc.name}'),
            updatedAt: DateTime.now(),
          );

          final updatedCredit = creditTx.copyWith(
            amount: tx.amount,
            date: tx.date,
            description: tx.description != null ? Value(tx.description) : const Value(null),
            merchant: Value('From ${fromAcc.name}'),
            updatedAt: DateTime.now(),
          );

          await repo.updateTransaction(updatedDebit);
          await repo.updateTransaction(updatedCredit);
        } else {
          await _updateTransaction.execute(tx);
        }
      } else {
        await _updateTransaction.execute(tx);
      }
      
      _ref.invalidate(accountsProvider);
      await loadTransactions();
      if (_userId != null) {
        _checkBudgetAlerts(_userId);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeTransaction(String id) async {
    try {
      state = const AsyncValue.loading();
      
      final repo = _ref.read(expenseRepositoryProvider);
      final tx = await repo.getTransactionById(id);
      if (tx != null && (tx.type == 'transfer_debit' || tx.type == 'transfer_credit')) {
        final otherSide = await getOtherSideOfTransfer(tx);
        await _deleteTransaction.execute(tx.id);
        if (otherSide != null) {
          await _deleteTransaction.execute(otherSide.id);
        }
      } else {
        await _deleteTransaction.execute(id);
      }

      
      _ref.invalidate(accountsProvider);
      await loadTransactions();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }


  Future<void> markBillAsPaid({
    required Transaction bill,
    required String accountId,
    required String paymentMethodId,
    required DateTime paymentDate,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      // 1. Update the bill transaction itself
      final updatedBill = bill.copyWith(
        billStatus: const Value('paid'),
        accountId: Value(accountId),
        paymentMethodId: Value(paymentMethodId),
        updatedAt: DateTime.now(),
      );
      await _updateTransaction.execute(updatedBill);

      // 2. Create the corresponding expense transaction automatically
      final expenseTx = Transaction(
        id: const Uuid().v4(),
        userId: bill.userId,
        accountId: accountId,
        categoryId: bill.categoryId,
        paymentMethodId: paymentMethodId,
        type: 'expense',
        amount: bill.amount,
        currency: bill.currency,
        description: 'Payment for ${bill.merchant ?? bill.description ?? 'Bill'}',
        merchant: bill.merchant,
        date: paymentDate,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _createTransaction.execute(expenseTx);

      // 3. Invalidate relevant providers to force rebuilds
      _ref.invalidate(accountsProvider);
      _ref.invalidate(categoriesProvider);
      
      await loadTransactions();
      
      if (_userId != null) {
        _checkBudgetAlerts(_userId);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _checkBudgetAlerts(String userId) async {
    try {
      final budgetRepo = _ref.read(budgetRepositoryProvider);
      final budgets = await budgetRepo.getBudgetsForUser(userId);
      if (budgets.isEmpty) return;

      final db = _ref.read(databaseProvider);
      final txs = await db.transactionDao.getTransactionsForUser(userId);
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final currentMonthExpenses = txs.where((tx) =>
        tx.type == 'expense' &&
        (tx.date.isAfter(startOfMonth) || tx.date.isAtSameMomentAs(startOfMonth))
      ).toList();

      for (var budget in budgets) {
        int spent = 0;
        if (budget.categoryId == null) {
          spent = currentMonthExpenses.fold(0, (sum, tx) => sum + tx.amount);
        } else {
          spent = currentMonthExpenses
              .where((tx) => tx.categoryId == budget.categoryId)
              .fold(0, (sum, tx) => sum + tx.amount);
        }

        final double percent = budget.amount == 0 ? 0.0 : spent / budget.amount;
        final notificationService = _ref.read(notificationServiceProvider);

        if (spent > budget.amount) {
          final categoryName = budget.categoryId != null 
              ? (await db.categoryDao.getCategoryById(budget.categoryId!))?.name ?? 'Category'
              : 'Overall';
          
          await notificationService.sendProactiveAlert(
            userId,
            title: 'Budget Exceeded! ⚠️',
            body: 'You have spent ₹${(spent / 100.0).toStringAsFixed(2)} exceeding your $categoryName budget of ₹${(budget.amount / 100.0).toStringAsFixed(2)}.',
            priority: 'critical',
          );
        } else if (percent >= 0.80) {
          final categoryName = budget.categoryId != null 
              ? (await db.categoryDao.getCategoryById(budget.categoryId!))?.name ?? 'Category'
              : 'Overall';

          await notificationService.sendProactiveAlert(
            userId,
            title: 'Budget Alert ⚠️',
            body: 'You have used ${(percent * 100).toStringAsFixed(0)}% of your $categoryName budget (₹${(spent / 100.0).toStringAsFixed(2)} / ₹${(budget.amount / 100.0).toStringAsFixed(2)}).',
            priority: 'high',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking budget alerts: $e');
    }
  }
}

// Transaction List Provider
final StateNotifierProvider<ExpenseListNotifier, AsyncValue<List<Transaction>>> expenseListNotifierProvider =
    StateNotifierProvider<ExpenseListNotifier, AsyncValue<List<Transaction>>>((ref) {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  return ExpenseListNotifier(
    getTransactions: ref.watch(getTransactionsUseCaseProvider),
    createTransaction: ref.watch(createTransactionUseCaseProvider),
    updateTransaction: ref.watch(updateTransactionUseCaseProvider),
    deleteTransaction: ref.watch(deleteTransactionUseCaseProvider),
    userId: userId,
    ref: ref,
  );
});

DateTimeRange? getDateRangeFromPreset(String preset) {
  final now = DateTime.now();
  switch (preset) {
    case 'today':
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      return DateTimeRange(start: start, end: end);
    case 'yesterday':
      final yest = now.subtract(const Duration(days: 1));
      final start = DateTime(yest.year, yest.month, yest.day);
      final end = start.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      return DateTimeRange(start: start, end: end);
    case 'this_week':
      final start = now.subtract(Duration(days: now.weekday - 1));
      final startOnly = DateTime(start.year, start.month, start.day);
      final end = startOnly.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
      return DateTimeRange(start: startOnly, end: end);
    case 'this_month':
      final start = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      final end = DateTime(now.year, now.month, lastDay, 23, 59, 59);
      return DateTimeRange(start: start, end: end);
    case 'last_month':
      final lastM = now.month == 1 ? 12 : now.month - 1;
      final year = now.month == 1 ? now.year - 1 : now.year;
      final start = DateTime(year, lastM, 1);
      final lastDay = DateTime(year, lastM + 1, 0).day;
      final end = DateTime(year, lastM, lastDay, 23, 59, 59);
      return DateTimeRange(start: start, end: end);
    case 'last_3_months':
      final start = now.subtract(const Duration(days: 90));
      final startOnly = DateTime(start.year, start.month, start.day);
      final endOnly = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return DateTimeRange(start: startOnly, end: endOnly);
    case 'last_6_months':
      final start = now.subtract(const Duration(days: 180));
      final startOnly = DateTime(start.year, start.month, start.day);
      final endOnly = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return DateTimeRange(start: startOnly, end: endOnly);
    case 'this_year':
      final start = now.subtract(const Duration(days: 365));
      final startOnly = DateTime(start.year, start.month, start.day);
      final endOnly = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return DateTimeRange(start: startOnly, end: endOnly);
    case 'all_time':
    default:
      return null;
  }
}

// Search & Filter State Providers
final StateProvider<String> searchQueryProvider = StateProvider<String>((ref) => '');
final StateProvider<String?> filterCategoryProvider = StateProvider<String?>((ref) => null);
final StateProvider<String?> filterTypeProvider = StateProvider<String?>((ref) => null);
final StateProvider<String?> filterPaymentMethodProvider = StateProvider<String?>((ref) => null);
final StateProvider<DateTimeRange?> filterDateRangeProvider = StateProvider<DateTimeRange?>((ref) => getDateRangeFromPreset('this_month'));
final StateProvider<String?> filterAccountProvider = StateProvider<String?>((ref) => null);
final StateProvider<double?> filterMinAmountProvider = StateProvider<double?>((ref) => null);
final StateProvider<double?> filterMaxAmountProvider = StateProvider<double?>((ref) => null);
final StateProvider<String> filterSortByProvider = StateProvider<String>((ref) => 'newest');
final StateProvider<String?> activeDatePresetProvider = StateProvider<String?>((ref) => 'this_month');

class SavedFilterPreset {
  final String name;
  final String? type;
  final String? categoryId;
  final String? paymentMethodId;
  final String? accountId;
  final DateTimeRange? dateRange;
  final String? datePreset;
  final double? minAmount;
  final double? maxAmount;
  final String sortBy;

  SavedFilterPreset({
    required this.name,
    this.type,
    this.categoryId,
    this.paymentMethodId,
    this.accountId,
    this.dateRange,
    this.datePreset,
    this.minAmount,
    this.maxAmount,
    this.sortBy = 'newest',
  });
}

class SavedFiltersNotifier extends StateNotifier<List<SavedFilterPreset>> {
  SavedFiltersNotifier() : super([
    SavedFilterPreset(name: 'Monthly Expenses', type: 'expense', datePreset: 'this_month'),
    SavedFilterPreset(name: 'Salary Transactions', type: 'income', datePreset: 'all_time'),
    SavedFilterPreset(name: 'Cash Transactions', paymentMethodId: 'cash', datePreset: 'all_time'),
    SavedFilterPreset(name: 'Credit Card Payments', paymentMethodId: 'credit card', datePreset: 'all_time'),
    SavedFilterPreset(name: 'Investment History', categoryId: 'investment', datePreset: 'all_time'),
    SavedFilterPreset(name: 'Bills', categoryId: 'utilities', datePreset: 'all_time'),
    SavedFilterPreset(name: 'Recent Expenses', type: 'expense', sortBy: 'newest'),
  ]);

  void addPreset(SavedFilterPreset preset) {
    state = [...state, preset];
  }

  void removePreset(String name) {
    state = state.where((p) => p.name != name).toList();
  }
}

final StateNotifierProvider<SavedFiltersNotifier, List<SavedFilterPreset>> savedFiltersProvider =
    StateNotifierProvider<SavedFiltersNotifier, List<SavedFilterPreset>>((ref) {
  return SavedFiltersNotifier();
});

// Filtered Transactions Provider
final Provider<List<Transaction>> filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final txsAsync = ref.watch(expenseListNotifierProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final categoryId = ref.watch(filterCategoryProvider);
  final type = ref.watch(filterTypeProvider);
  final pmId = ref.watch(filterPaymentMethodProvider);
  final dateRange = ref.watch(filterDateRangeProvider);
  final accountId = ref.watch(filterAccountProvider);
  final minAmount = ref.watch(filterMinAmountProvider);
  final maxAmount = ref.watch(filterMaxAmountProvider);
  final sortBy = ref.watch(filterSortByProvider);

  // Watch categories to search by category name
  final categoriesAsync = ref.watch(categoriesProvider);
  final categoriesMap = categoriesAsync.maybeWhen(
    data: (cats) => {for (var c in cats) c.id: c.name.toLowerCase()},
    orElse: () => <String, String>{},
  );

  return txsAsync.maybeWhen(
    data: (txs) {
      var filtered = txs.where((tx) {
        // Search Query (Description, Merchant, Category Name)
        if (query.isNotEmpty) {
          final descMatch = tx.description?.toLowerCase().contains(query) ?? false;
          final merchantMatch = tx.merchant?.toLowerCase().contains(query) ?? false;
          final catName = tx.categoryId != null ? categoriesMap[tx.categoryId] : null;
          final catMatch = catName?.contains(query) ?? false;

          if (!descMatch && !merchantMatch && !catMatch) return false;
        }

        // Category Filter
        if (categoryId != null && tx.categoryId != categoryId) return false;

        // Type Filter
        if (type != null && tx.type != type) return false;

        // Payment Method Filter
        if (pmId != null && tx.paymentMethodId != pmId) return false;

        // Account Filter
        if (accountId != null && tx.accountId != accountId) return false;

        // Amount range Filter
        if (minAmount != null && (tx.amount / 100.0) < minAmount) return false;
        if (maxAmount != null && (tx.amount / 100.0) > maxAmount) return false;

        // Date Range Filter
        if (dateRange != null) {
          // Normalize to compare only dates
          final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
          final startDate = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
          final endDate = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);

          if (txDate.isBefore(startDate) || txDate.isAfter(endDate)) {
            return false;
          }
        }

        return true;
      }).toList();

      // Sorting
      if (sortBy == 'oldest') {
        filtered.sort((a, b) => a.date.compareTo(b.date));
      } else if (sortBy == 'highest') {
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
      } else if (sortBy == 'lowest') {
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
      } else {
        // default: newest
        filtered.sort((a, b) => b.date.compareTo(a.date));
      }

      return filtered;
    },
    orElse: () => <Transaction>[],
  );
});

// NLP Parsing Classes and Providers
class NlpParsedResult {
  final double amount;
  final String category;
  final String? merchant;
  final String type;
  final String date;
  final double confidence;
  final String? accountName;
  final String? paymentMethodName;
  final String? notes;
  final String? transferToAccountName;
  
  // Rich receipt fields
  final String? merchantAddress;
  final String? time;
  final double? tax;
  final String? currency;
  final String? cardType;
  final String? last4Digits;
  final String? receiptNumber;
  final String? invoiceNumber;
  final double? discount;
  final double? tips;
  final List<OcrItem>? items;

  NlpParsedResult({
    required this.amount,
    required this.category,
    this.merchant,
    required this.type,
    required this.date,
    required this.confidence,
    this.accountName,
    this.paymentMethodName,
    this.notes,
    this.transferToAccountName,
    this.merchantAddress,
    this.time,
    this.tax,
    this.currency,
    this.cardType,
    this.last4Digits,
    this.receiptNumber,
    this.invoiceNumber,
    this.discount,
    this.tips,
    this.items,
  });

  factory NlpParsedResult.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List?;
    List<OcrItem> parsedItems = [];
    if (rawItems != null) {
      parsedItems = rawItems.map((i) => OcrItem.fromJson(i as Map<String, dynamic>)).toList();
    }

    return NlpParsedResult(
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      merchant: json['merchant'] as String?,
      type: json['type'] as String? ?? 'expense',
      date: json['date'] as String? ?? 'today',
      confidence: (json['confidence'] as num).toDouble(),
      accountName: json['accountName'] as String?,
      paymentMethodName: json['paymentMethodName'] as String?,
      notes: json['notes'] as String?,
      transferToAccountName: json['transferToAccountName'] as String?,
      merchantAddress: json['merchantAddress'] as String?,
      time: json['time'] as String?,
      tax: (json['tax'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      cardType: json['cardType'] as String?,
      last4Digits: json['last4Digits']?.toString(),
      receiptNumber: json['receiptNumber']?.toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
      discount: (json['discount'] as num?)?.toDouble(),
      tips: (json['tips'] as num?)?.toDouble(),
      items: parsedItems,
    );
  }
}

class NlpService {
  final Ref _ref;

  NlpService(this._ref);

  Future<NlpParsedResult?> parseExpense(String text) async {
    try {
      final dio = _ref.read(dioClientProvider).dio;
      final response = await dio.post('/ai/parse-expense', data: {'text': text});
      if (response.statusCode == 200 && response.data != null) {
        return NlpParsedResult.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('NLP parsing error: $e. Using local rule-based parser.');
    }
    
    // Local fallback parsing
    try {
      return _parseExpenseLocally(text);
    } catch (e) {
      debugPrint('Local NLP parsing fallback failed: $e');
    }
    return null;
  }

  NlpParsedResult _parseExpenseLocally(String text) {
    final normalized = text.toLowerCase().trim();

    // Local parser for text representation of numbers
    double parseTextualAmount(String norm) {
      final clean = norm.replaceAll(RegExp(r'[₹\$rs\.inr]'), ' ');
      final numberWords = {
        'zero': 0.0, 'one': 1.0, 'two': 2.0, 'three': 3.0, 'four': 4.0,
        'five': 5.0, 'six': 6.0, 'seven': 7.0, 'eight': 8.0, 'nine': 9.0,
        'ten': 10.0, 'eleven': 11.0, 'twelve': 12.0, 'thirteen': 13.0,
        'fourteen': 14.0, 'fifteen': 15.0, 'sixteen': 16.0, 'seventeen': 17.0,
        'eighteen': 18.0, 'nineteen': 19.0, 'twenty': 20.0, 'thirty': 30.0,
        'forty': 40.0, 'fifty': 50.0, 'sixty': 60.0, 'seventy': 70.0,
        'eighty': 80.0, 'ninety': 90.0,
      };

      final scaleWords = {
        'hundred': 100.0,
        'thousand': 1000.0,
        'lakh': 100000.0,
        'lakhs': 100000.0,
      };

      final tokens = clean.split(RegExp(r'[\s\-]+'));
      double total = 0.0;
      double current = 0.0;
      bool foundNumber = false;

      for (var token in tokens) {
        final word = token.toLowerCase().trim();
        if (numberWords.containsKey(word)) {
          current += numberWords[word]!;
          foundNumber = true;
        } else if (scaleWords.containsKey(word)) {
          current = (current == 0.0 ? 1.0 : current) * scaleWords[word]!;
          total += current;
          current = 0.0;
          foundNumber = true;
        }
      }
      total += current;
      return foundNumber ? total : 0.0;
    }

    // 1. Extract amount using regex
    double amount = 0.0;
    final amountRegex = RegExp(r'(?:rs\.?|₹|inr|rupees|\$)?\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);
    final match = amountRegex.firstMatch(normalized);
    if (match != null) {
      amount = double.tryParse(match.group(1) ?? '') ?? 0.0;
    }
    if (amount == 0.0) {
      amount = parseTextualAmount(normalized);
    }

    // 2. Determine type
    String type = 'expense';
    if (normalized.contains('transfer') || normalized.contains('transferred')) {
      type = 'transfer';
    } else {
      final incomeKeywords = ["salary", "freelance", "received", "earned", "refund", "deposit", "bonus", "income", "stipend", "interest", "cashback"];
      for (var kw in incomeKeywords) {
        if (normalized.contains(kw)) {
          type = 'income';
          break;
        }
      }
    }

    // 3. Determine Account Names
    String? accountName;
    String? transferToAccountName;

    final accountKeywords = {
      'SBI Savings': ['sbi', 'state bank', 'savings'],
      'Cash Wallet': ['cash wallet', 'cash'],
      'Google Pay Wallet': ['gpay', 'google pay', 'g-pay', 'digital wallet'],
      'HDFC Credit Card': ['hdfc', 'credit card', 'creditcard'],
    };

    String? firstMatch;
    String? secondMatch;

    accountKeywords.forEach((name, keywords) {
      for (var kw in keywords) {
        final regex = RegExp('\\b$kw\\b', caseSensitive: false);
        if (regex.hasMatch(normalized)) {
          if (firstMatch == null) {
            firstMatch = name;
          } else if (secondMatch == null && firstMatch != name) {
            secondMatch = name;
          }
          break;
        }
      }
    });

    if (type == 'transfer') {
      final fromIndex = normalized.indexOf('from');
      final toIndex = normalized.indexOf('to');
      if (fromIndex != -1 && toIndex != -1 && fromIndex < toIndex) {
        accountName = firstMatch;
        transferToAccountName = secondMatch;
      } else {
        accountName = firstMatch;
        transferToAccountName = secondMatch;
      }
    } else {
      accountName = firstMatch;
    }

    // 4. Determine Payment Method
    String? paymentMethodName;
    final pmKeywords = {
      'UPI': ['upi', 'gpay', 'google pay', 'phonepe', 'paytm'],
      'Cash': ['cash'],
      'Credit Card': ['credit card', 'creditcard', 'cc'],
      'Debit Card': ['debit card', 'debitcard', 'dc'],
      'Net Banking': ['net banking', 'netbanking', 'bank transfer', 'bank'],
    };

    pmKeywords.forEach((name, keywords) {
      for (var kw in keywords) {
        final regex = RegExp('\\b$kw\\b', caseSensitive: false);
        if (regex.hasMatch(normalized)) {
          paymentMethodName = name;
          break;
        }
      }
    });

    // 5. Determine Category
    String category = 'Food'; // default
    final categoryKeywords = {
      "Food": ["tea", "coffee", "restaurant", "food", "snacks", "lunch", "dinner", "grocery", "groceries", "starbucks", "mcdonald", "cafe", "hotel", "swiggy", "zomato", "burger", "pizza", "eat", "bakery"],
      "Fuel": ["fuel", "petrol", "diesel", "gas", "cng", "shell", "refuel"],
      "Grocery": ["grocery", "groceries", "mart", "supermarket", "bigbasket", "blinkit", "milk", "vegetables", "fruits", "provision"],
      "Utilities": ["electricity", "water", "internet", "wifi", "bill", "mobile", "recharge", "power", "dth", "broadband", "postpaid"],
      "Shopping": ["amazon", "flipkart", "shopping", "order", "myntra", "clothing", "clothes", "shoes", "fashion", "mall"],
      "Entertainment": ["movie", "cinema", "netflix", "spotify", "game", "gaming", "ticket", "show", "pub", "club", "concert"],
      "Salary": ["salary", "paycheck", "allowance", "stipend"],
      "Freelance": ["freelance", "gig", "contract", "upwork", "fiverr", "invoice"],
      "Investment": ["investment", "stock", "stocks", "mutual fund", "mutual funds", "crypto", "gold", "share", "shares"],
      "Transfer": ["transfer", "sent", "send", "received from"]
    };

    int maxMatches = 0;
    double confidence = 0.50;
    categoryKeywords.forEach((cat, keywords) {
      int matches = 0;
      for (var kw in keywords) {
        if (normalized.contains(kw)) {
          matches++;
        }
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        category = cat;
        confidence = matches > 1 ? 0.90 : 0.80;
      }
    });

    if (type == 'income' && category != 'Salary' && category != 'Freelance' && category != 'Transfer') {
      category = 'Salary';
      confidence = 0.75;
    } else if (type == 'transfer') {
      category = 'Transfer';
      confidence = 0.90;
    }

    // 6. Determine Date
    String date = 'today';
    if (normalized.contains('yesterday')) {
      date = 'yesterday';
    } else if (normalized.contains('tomorrow')) {
      date = 'tomorrow';
    }

    // 7. Determine Merchant & Notes
    String cleanText = normalized;
    cleanText = cleanText.replaceAll(RegExp(r'(?:rs\.?|₹|inr|rupees|\$)?\s*\d+(?:\.\d{1,2})?', caseSensitive: false), '');
    final textNumbers = ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'thousand', 'hundred', 'lakh', 'lakhs'];
    for (var tn in textNumbers) {
      cleanText = cleanText.replaceAll(RegExp('\\b$tn\\b', caseSensitive: false), '');
    }
    final wordsToRemove = [
      "spent", "paid", "received", "earned", "on", "for", "from", "to", "my", "a",
      "sbi", "hdfc", "gpay", "google pay", "cash wallet", "upi", "yesterday", "today",
      "tomorrow", "transfer", "transferred", "mutual funds", "mutual fund"
    ];
    for (var word in wordsToRemove) {
      cleanText = cleanText.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
    }
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();

    String merchant = cleanText.isNotEmpty
        ? cleanText.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ')
        : 'Store';

    if (type == 'transfer') {
      merchant = 'Transfer';
    }

    final String notes = text;

    return NlpParsedResult(
      amount: amount,
      category: category,
      merchant: merchant,
      type: type,
      date: date,
      confidence: confidence,
      accountName: accountName,
      paymentMethodName: paymentMethodName,
      notes: notes,
      transferToAccountName: transferToAccountName,
    );
  }
}

final Provider<NlpService> nlpServiceProvider = Provider<NlpService>((ref) {
  return NlpService(ref);
});

int getAccountTypePriority(String type) {
  switch (type.toLowerCase()) {
    case 'cash':
      return 1;
    case 'savings':
    case 'current':
    case 'salary':
    case 'debit_card':
    case 'bank':
      return 2;
    case 'credit_card':
      return 3;
    case 'wallet':
    case 'upi_wallet':
    case 'digital_wallet':
      return 4;
    default:
      return 5;
  }
}

final Provider<AsyncValue<List<Account>>> sortedAccountsProvider = Provider<AsyncValue<List<Account>>>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final txsAsync = ref.watch(expenseListNotifierProvider);

  return accountsAsync.when(
    data: (accounts) {
      return txsAsync.maybeWhen(
        data: (txs) {
          final counts = <String, int>{};
          for (var tx in txs) {
            final accId = tx.accountId;
            if (accId != null) {
              counts[accId] = (counts[accId] ?? 0) + 1;
            }
          }

          final sortedList = List<Account>.from(accounts);
          final originalIndices = {for (int i = 0; i < accounts.length; i++) accounts[i].id: i};

          sortedList.sort((a, b) {
            final aPriority = getAccountTypePriority(a.type);
            final bPriority = getAccountTypePriority(b.type);
            if (aPriority != bPriority) {
              return aPriority.compareTo(bPriority);
            }

            final aCount = counts[a.id] ?? 0;
            final bCount = counts[b.id] ?? 0;
            if (aCount != bCount) {
              return bCount.compareTo(aCount); // DESC
            }

            return originalIndices[a.id]!.compareTo(originalIndices[b.id]!); // stable sort
          });

          return AsyncValue.data(sortedList);
        },
        orElse: () {
          final sortedList = List<Account>.from(accounts);
          final originalIndices = {for (int i = 0; i < accounts.length; i++) accounts[i].id: i};
          sortedList.sort((a, b) {
            final aPriority = getAccountTypePriority(a.type);
            final bPriority = getAccountTypePriority(b.type);
            if (aPriority != bPriority) {
              return aPriority.compareTo(bPriority);
            }
            return originalIndices[a.id]!.compareTo(originalIndices[b.id]!);
          });
          return AsyncValue.data(sortedList);
        },
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

class MerchantResolver {
  static String resolve({
    required String? enteredMerchant,
    required String? subcategoryName,
    required String? categoryName,
  }) {
    final cleanMerchant = enteredMerchant?.trim() ?? '';
    if (cleanMerchant.isNotEmpty) {
      return cleanMerchant;
    }
    final cleanSub = subcategoryName?.trim() ?? '';
    if (cleanSub.isNotEmpty) {
      return cleanSub;
    }
    final cleanCat = categoryName?.trim() ?? '';
    if (cleanCat.isNotEmpty) {
      return cleanCat;
    }
    return 'Other';
  }
}



