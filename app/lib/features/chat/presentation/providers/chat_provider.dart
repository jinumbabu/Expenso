import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/analysis_agent.dart';
import '../../../../core/services/forecasting_agent.dart';
import '../../../../core/services/subscription_agent.dart';
import '../../../../core/services/report_agent.dart';
import '../../../../core/services/ai_provider_orchestrator.dart';
import 'package:drift/drift.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/account_formatters.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';

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
final chatHistoryProvider =
    FutureProvider.autoDispose.family<List<ChatHistoryItem>, String>((ref, userId) async {
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

      final currentConfig = _ref.read(aiProviderOrchestratorProvider);
      final activeModelId = currentConfig.aiProvider == 'offline'
          ? 'Offline AI'
          : (currentConfig.selectedModels[currentConfig.aiProvider] ?? 'Online AI');

      // 1. Save user's message locally first
      await _repository.saveMessage(
        userId: userId,
        role: 'user',
        message: messageText,
        aiMode: activeModelId,
      );
      
      // Force refreshing the chat list provider so UI shows the user's message immediately
      _ref.invalidate(chatHistoryProvider(userId));
      String? reply;
      final lowerText = messageText.toLowerCase();

      // Financial Copilot Query Handling
      if (lowerText.startsWith('confirm payment')) {
        final accounts = _ref.read(accountsProvider).value ?? [];
        final pms = _ref.read(paymentMethodsProvider).value ?? [];

        // Extract account name if provided (e.g. "Confirm Payment using SBI Credit Card")
        String? targetAccountName;
        final usingMatch = RegExp(r'using\s+(.+)$', caseSensitive: false).firstMatch(messageText);
        if (usingMatch != null) {
          targetAccountName = usingMatch.group(1)!.trim();
        }

        Account? account;
        if (targetAccountName != null) {
          account = accounts.firstWhere(
            (a) => a.name.toLowerCase() == targetAccountName!.toLowerCase() ||
                   a.name.toLowerCase().contains(targetAccountName.toLowerCase()),
            orElse: () => accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first),
          );
        } else {
          account = accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
        }

        final history = await _repository.getChatHistory(userId);
        final lastConfirmMsg = history.lastWhere(
          (m) => m.role == 'model' && m.message.startsWith('[PAY_CONFIRM:'),
          orElse: () => ChatHistoryItem(id: '', userId: userId, role: 'model', message: '', aiMode: '', createdAt: DateTime.now()),
        );

        if (lastConfirmMsg.message.isNotEmpty) {
          final match = RegExp(r'^\[PAY_CONFIRM:(.*?)\]').firstMatch(lastConfirmMsg.message);
          final idsStr = match?.group(1) ?? '';
          final billIds = idsStr.split(',').where((id) => id.isNotEmpty).toList();

          final db = _ref.read(databaseProvider);
          final notifier = _ref.read(expenseListNotifierProvider.notifier);

          List<String> paidSummary = [];
          for (var id in billIds) {
            final bill = await db.transactionDao.getTransactionById(id);
            if (bill != null && bill.billStatus != 'paid') {
              // Resolve payment method based on account type
              final pm = pms.firstWhere(
                (p) => p.name.toLowerCase() == (account!.type == 'cash' ? 'cash' : 'debit card'),
                orElse: () => pms.first,
              );

              await notifier.markBillAsPaid(
                bill: bill,
                accountId: account!.id,
                paymentMethodId: pm.id,
                paymentDate: DateTime.now(),
              );
              paidSummary.add('✓ ${bill.merchant ?? bill.description ?? "Bill"} (₹${(bill.amount / 100.0).toStringAsFixed(2)})');
            }
          }

          if (paidSummary.isNotEmpty) {
            reply = 'I have marked the following bills as paid using **${account!.displayTitle}**:\n\n${paidSummary.join("\n")}\n\nAll financial charts, reports, and ledger balances have been updated instantly.';
          } else {
            reply = 'No pending bills were found or they have already been marked as paid.';
          }
        } else {
          reply = 'No pending payments to confirm.';
        }
      } 
      else if (lowerText == 'cancel payment') {
        reply = 'Payment cancelled.';
      }
      else if (lowerText.contains('pay') || lowerText.contains('paid') || lowerText.contains('clear')) {
        final db = _ref.read(databaseProvider);
        final pendingBills = await (db.select(db.transactions)
          ..where((t) => t.userId.equals(userId) & 
                         (t.type.equals('upcoming_bill') | t.type.equals('credit_card_bill') | t.type.equals('credit_card_bill_reminder')) & 
                         (t.billStatus.equals('pending') | t.billStatus.isNull()))
        ).get();

        if (pendingBills.isEmpty) {
          reply = 'You have no pending bills at the moment.';
        } else {
          List<Transaction> matches = [];
          
          if (lowerText.contains('electricity')) {
            matches = pendingBills.where((t) => (t.merchant ?? t.description ?? '').toLowerCase().contains('electricity')).toList();
          } else if (lowerText.contains('internet')) {
            matches = pendingBills.where((t) => (t.merchant ?? t.description ?? '').toLowerCase().contains('internet')).toList();
          } else if (lowerText.contains('talabat')) {
            matches = pendingBills.where((t) => (t.merchant ?? t.description ?? '').toLowerCase().contains('talabat')).toList();
          } else if (lowerText.contains('credit card') || lowerText.contains('creditcard')) {
            matches = pendingBills.where((t) => t.type == 'credit_card_bill' || t.type == 'credit_card_bill_reminder' || (t.merchant ?? t.description ?? '').toLowerCase().contains('credit card')).toList();
          } else {
            matches = List.from(pendingBills);
          }

          if (matches.isEmpty) {
            reply = 'I could not find any pending bills matching your description.';
          } else {
            final ids = matches.map((m) => m.id).join(',');
            final buffer = StringBuffer('[PAY_CONFIRM:$ids]I found ${matches.length} unpaid bill${matches.length > 1 ? "s" : ""}:\n\n');
            for (var m in matches) {
              buffer.writeln('✓ ${m.merchant ?? m.description ?? "Bill"}: ₹${(m.amount / 100.0).toStringAsFixed(2)}');
            }
            buffer.writeln('\nProceed to mark them as paid?');
            reply = buffer.toString();
          }
        }
      }
      else if (lowerText.contains('spend on food') || lowerText.contains('food spending') || lowerText.contains('spent on food')) {
        final analysisAgent = _ref.read(analysisAgentProvider);
        final analysis = await analysisAgent.analyzeFinances(userId);
        final categorySpending = Map<String, int>.from(analysis['categorySpendingThisMonth'] ?? {});
        final foodSpent = categorySpending['Food'] ?? 0;
        final double foodSpentVal = foodSpent / 100.0;
        final double totalExpenseVal = (analysis['thisMonthExpense'] ?? 0) / 100.0;
        final double pct = totalExpenseVal > 0 ? (foodSpentVal / totalExpenseVal) * 100 : 0.0;
        reply = 'You have spent ₹${foodSpentVal.toStringAsFixed(2)} on Food this month. This accounts for ${pct.toStringAsFixed(1)}% of your total monthly expenses (₹${totalExpenseVal.toStringAsFixed(2)}).';
      } 
      else if (lowerText.contains('cancel') && (lowerText.contains('subscription') || lowerText.contains('subscriptions'))) {
        final subAgent = _ref.read(subscriptionAgentProvider);
        final subs = await subAgent.scanAndDetectSubscriptions(userId);
        if (subs.isEmpty) {
          reply = 'Expenso did not detect any recurring subscription charges in your recent transactions.';
        } else {
          final buffer = StringBuffer('Here are the active subscriptions Expenso detected:\n\n');
          for (var s in subs) {
            buffer.writeln('- **${s.title}**: ₹${(s.monthlyCost / 100.0).toStringAsFixed(2)}/mo (₹${(s.annualCost / 100.0).toStringAsFixed(2)} annually)');
          }
          final totalMonthly = subs.map((s) => s.monthlyCost).reduce((a, b) => a + b);
          buffer.writeln('\nYou could save up to ₹${(totalMonthly / 100.0).toStringAsFixed(2)} monthly by canceling subscriptions you no longer use.');
          reply = buffer.toString();
        }
      } 
      else if (lowerText.contains('savings') && (lowerText.contains('decreasing') || lowerText.contains('decrease') || lowerText.contains('drop'))) {
        final analysisAgent = _ref.read(analysisAgentProvider);
        final analysis = await analysisAgent.analyzeFinances(userId);
        final savingsRate = (analysis['savingsRate'] as double) * 100;
        final double thisMonthExpense = (analysis['thisMonthExpense'] as int) / 100.0;
        final double lastMonthExpense = (analysis['lastMonthExpense'] as int) / 100.0;
        
        if (thisMonthExpense > lastMonthExpense) {
          final diff = thisMonthExpense - lastMonthExpense;
          reply = 'Your savings are decreasing primarily because your expenses increased by ₹${diff.toStringAsFixed(2)} compared to last month. Your current savings rate is ${savingsRate.toStringAsFixed(1)}%.';
        } else {
          reply = 'Your savings rate is currently ${savingsRate.toStringAsFixed(1)}%. Expenso recommends maintaining a savings rate of at least 20%. Try setting a monthly budget or reducing discretionary items like dining out.';
        }
      } 
      else if (lowerText.contains('predict') || lowerText.contains('forecast') || (lowerText.contains('balance') && lowerText.contains('next month'))) {
        final forecastingAgent = _ref.read(forecastingAgentProvider);
        final prediction = await forecastingAgent.generateProjections(userId);
        final bal = prediction.predictedBalance / 100.0;
        final exp = prediction.predictedExpenses / 100.0;
        reply = 'Predicted Month-End Balance:\n\n**₹${bal.toStringAsFixed(2)}**\n\nConfidence: **${(prediction.confidence * 100).toStringAsFixed(0)}%**\nProjected Expenses: ₹${exp.toStringAsFixed(2)}';
      } 
      else if (lowerText.contains('generate') && lowerText.contains('report')) {
        final reportAgent = _ref.read(reportAgentProvider);
        final report = await reportAgent.generateReport(userId, 'monthly');
        reply = 'I have generated your executive Monthly Report. You can view the summary below:\n\n${report.summaryText}\n\n*CSV exported to: ${report.exportedFilePath}*';
      }

      String activeModelName = 'Offline AI';
      if (reply == null) {
        // 2. Call the modular AI orchestrator
        final orchestrator = _ref.read(aiProviderOrchestratorProvider.notifier);
        final response = await orchestrator.getChatResponse(messageText, userId);
        reply = response.reply;
        activeModelName = response.providerName;
      } else {
        // Parsed by local hardcoded rules
        activeModelName = 'Offline AI';
      }

      // 4. Save model's reply locally
      await _repository.saveMessage(
        userId: userId,
        role: 'model',
        message: reply,
        aiMode: activeModelName,
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
}

final StateNotifierProvider<ChatNotifier, AsyncValue<void>> chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repository, ref);
});
