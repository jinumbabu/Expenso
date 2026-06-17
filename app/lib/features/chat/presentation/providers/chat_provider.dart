import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/database/app_database.dart';

final Provider<ChatRepository> chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final client = ref.watch(dioClientProvider);
  return ChatRepositoryImpl(
    db.chatHistoryDao,
    db.aiMemoryDao,
    client.dio,
  );
});

// Chat History Future Provider (refreshed when messages are sent/cleared)
final FutureProviderFamily<List<ChatHistoryItem>, String> chatHistoryProvider =
    FutureProvider.family<List<ChatHistoryItem>, String>((ref, userId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return await repo.getChatHistory(userId);
});

// State of the chat screen: holds sending status or error
class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  final ChatRepository _repository;
  final Ref _ref;

  ChatNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> sendMessage(String userId, String messageText) async {
    try {
      state = const AsyncValue.loading();

      // 1. Save user's message locally first
      await _repository.saveMessage(
        userId: userId,
        role: 'user',
        message: messageText,
        aiMode: 'cloud',
      );
      
      // Force refreshing the chat list provider so UI shows the user's message immediately
      _ref.invalidate(chatHistoryProvider(userId));

      // 2. Compile client-side data minimization context
      final contextText = await _compileFinancialSummary(userId);

      // 3. Send message to backend
      final reply = await _repository.sendMessageToAssistant(messageText, contextText);

      // 4. Save model's reply locally
      await _repository.saveMessage(
        userId: userId,
        role: 'model',
        message: reply,
        aiMode: 'cloud',
      );

      // 5. Refresh the list so the model reply appears in the UI
      _ref.invalidate(chatHistoryProvider(userId));
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> clearChat(String userId) async {
    try {
      state = const AsyncValue.loading();
      await _repository.clearHistory(userId);
      _ref.invalidate(chatHistoryProvider(userId));
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String> _compileFinancialSummary(String userId) async {
    final db = _ref.read(databaseProvider);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    // Fetch transactions
    final transactions = await db.transactionDao.getTransactionsForUser(userId);
    final currentMonthTxs = transactions.where((tx) => tx.date.isAfter(startOfMonth) || tx.date.isAtSameMomentAs(startOfMonth)).toList();
    
    // Fetch budgets
    final budgets = await db.budgetDao.getBudgetsForUser(userId);
    
    // Fetch categories
    final categories = await db.categoryDao.getCategoriesForUser(userId);
    final categoriesMap = {for (var c in categories) c.id: c};
    
    int totalIncome = 0;
    int totalExpense = 0;
    final categorySpending = <String, int>{};
    
    for (var tx in currentMonthTxs) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        totalExpense += tx.amount;
        final catName = categoriesMap[tx.categoryId]?.name ?? 'Uncategorized';
        categorySpending[catName] = (categorySpending[catName] ?? 0) + tx.amount;
      }
    }
    
    final double totalIncomeVal = totalIncome / 100.0;
    final double totalExpenseVal = totalExpense / 100.0;
    final double netVal = totalIncomeVal - totalExpenseVal;
    
    final buffer = StringBuffer();
    buffer.writeln('User Current Month Financial Context (since ${startOfMonth.toIso8601String().substring(0, 10)}):');
    buffer.writeln('- Total Income: INR ${totalIncomeVal.toStringAsFixed(2)}');
    buffer.writeln('- Total Expenses: INR ${totalExpenseVal.toStringAsFixed(2)}');
    buffer.writeln('- Net Balance: INR ${netVal.toStringAsFixed(2)}');
    
    buffer.writeln('\nCategory Spending (This Month):');
    if (categorySpending.isEmpty) {
      buffer.writeln('No expenses recorded this month.');
    } else {
      categorySpending.forEach((cat, amount) {
        buffer.writeln('- $cat: INR ${(amount / 100.0).toStringAsFixed(2)}');
      });
    }
    
    buffer.writeln('\nActive Budgets:');
    if (budgets.isEmpty) {
      buffer.writeln('No budgets configured.');
    } else {
      for (var budget in budgets) {
        final catName = categoriesMap[budget.categoryId]?.name ?? 'Total';
        final limit = budget.amount / 100.0;
        int spent = 0;
        for (var tx in currentMonthTxs) {
          if (tx.categoryId == budget.categoryId && tx.type == 'expense') {
            spent += tx.amount;
          }
        }
        final spentVal = spent / 100.0;
        final remainingVal = limit - spentVal;
        buffer.writeln('- $catName Category Budget: Limit INR ${limit.toStringAsFixed(2)}, Spent INR ${spentVal.toStringAsFixed(2)}, Remaining INR ${remainingVal.toStringAsFixed(2)}');
      }
    }
    
    buffer.writeln('\n5 Most Recent Transactions:');
    final sortedTxs = List<Transaction>.from(transactions)..sort((a, b) => b.date.compareTo(a.date));
    final recentTxs = sortedTxs.take(5).toList();
    if (recentTxs.isEmpty) {
      buffer.writeln('No transactions recorded yet.');
    } else {
      for (var tx in recentTxs) {
        final catName = categoriesMap[tx.categoryId]?.name ?? 'Uncategorized';
        final amountVal = tx.amount / 100.0;
        final dateStr = tx.date.toIso8601String().substring(0, 10);
        buffer.writeln('- $dateStr: ${tx.type == 'income' ? '+' : '-'}INR ${amountVal.toStringAsFixed(2)} | Description: ${tx.description ?? tx.merchant ?? catName}');
      }
    }
    
    return buffer.toString();
  }
}

final StateNotifierProvider<ChatNotifier, AsyncValue<void>> chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repository, ref);
});
