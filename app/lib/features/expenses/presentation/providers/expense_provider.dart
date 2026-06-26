import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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

// Repository Provider
final Provider<ExpenseRepository> expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseRepositoryImpl(
    db.accountDao,
    db.categoryDao,
    db.paymentMethodDao,
    db.transactionDao,
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
  return await ref.watch(getPaymentMethodsUseCaseProvider).execute(userId);
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
      await loadTransactions();
      if (_userId != null) {
        _checkBudgetAlerts(_userId);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editTransaction(Transaction tx) async {
    try {
      state = const AsyncValue.loading();
      await _updateTransaction.execute(tx);
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
      await _deleteTransaction.execute(id);
      await loadTransactions();
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

// Search & Filter State Providers
final StateProvider<String> searchQueryProvider = StateProvider<String>((ref) => '');
final StateProvider<String?> filterCategoryProvider = StateProvider<String?>((ref) => null);
final StateProvider<String?> filterTypeProvider = StateProvider<String?>((ref) => null);
final StateProvider<String?> filterPaymentMethodProvider = StateProvider<String?>((ref) => null);
final StateProvider<DateTimeRange?> filterDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// Filtered Transactions Provider
final Provider<List<Transaction>> filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final txsAsync = ref.watch(expenseListNotifierProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final categoryId = ref.watch(filterCategoryProvider);
  final type = ref.watch(filterTypeProvider);
  final pmId = ref.watch(filterPaymentMethodProvider);
  final dateRange = ref.watch(filterDateRangeProvider);

  // Watch categories to search by category name
  final categoriesAsync = ref.watch(categoriesProvider);
  final categoriesMap = categoriesAsync.maybeWhen(
    data: (cats) => {for (var c in cats) c.id: c.name.toLowerCase()},
    orElse: () => <String, String>{},
  );

  return txsAsync.maybeWhen(
    data: (txs) {
      return txs.where((tx) {
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
    },
    orElse: () => [],
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

  NlpParsedResult({
    required this.amount,
    required this.category,
    this.merchant,
    required this.type,
    required this.date,
    required this.confidence,
  });

  factory NlpParsedResult.fromJson(Map<String, dynamic> json) {
    return NlpParsedResult(
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      merchant: json['merchant'] as String?,
      type: json['type'] as String? ?? 'expense',
      date: json['date'] as String? ?? 'today',
      confidence: (json['confidence'] as num).toDouble(),
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
    
    // 1. Extract amount using regex
    final amountRegex = RegExp(r'(?:rs\.?|₹|inr|\$)?\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);
    final match = amountRegex.firstMatch(normalized);
    double amount = 0.0;
    if (match != null) {
      amount = double.tryParse(match.group(1) ?? '') ?? 0.0;
    }

    // 2. Determine type
    String type = 'expense';
    final incomeKeywords = ["salary", "freelance", "received", "earned", "refund", "deposit", "bonus", "income", "stipend", "interest"];
    for (var kw in incomeKeywords) {
      if (normalized.contains(kw)) {
        type = 'income';
        break;
      }
    }

    // 3. Determine Category
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
      "Investment": ["investment", "stock", "stocks", "mutual fund", "crypto", "gold", "share", "shares"],
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
    }

    // 4. Determine Merchant
    String cleanText = normalized;
    cleanText = cleanText.replaceAll(RegExp(r'(?:rs\.?|₹|inr|\$)?\s*\d+(?:\.\d{1,2})?', caseSensitive: false), '');
    final wordsToRemove = ["spent", "paid", "received", "earned", "on", "for", "from", "to", "my", "a"];
    for (var word in wordsToRemove) {
      cleanText = cleanText.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
    }
    
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    String merchant = cleanText.isNotEmpty
        ? cleanText.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ')
        : category;

    return NlpParsedResult(
      amount: amount,
      category: category,
      merchant: merchant,
      type: type,
      date: 'today',
      confidence: confidence,
    );
  }
}

final Provider<NlpService> nlpServiceProvider = Provider<NlpService>((ref) {
  return NlpService(ref);
});

