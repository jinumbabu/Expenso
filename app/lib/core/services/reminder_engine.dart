import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../../features/expenses/presentation/providers/expense_provider.dart';
import '../../features/goals/presentation/providers/goals_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'notification_service.dart';

class CalendarReminder {
  final String id;
  final String title;
  final String type; // 'income', 'expense', 'transfer', 'goal', 'upcoming_bill', 'emi', 'loan_payment', 'credit_card_due', 'salary', 'general_reminder', 'subscription'
  final DateTime dueDate;
  final int amount; // in cents
  final bool isPaid;
  final bool isSystemGenerated;
  final String? notes;
  final bool reminderEnabled;

  CalendarReminder({
    required this.id,
    required this.title,
    required this.type,
    required this.dueDate,
    required this.amount,
    this.isPaid = false,
    this.isSystemGenerated = true,
    this.notes,
    this.reminderEnabled = true,
  });

  String get status {
    if (isPaid) return 'Paid';
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (normalizedDue.isBefore(normalizedNow)) {
      return 'Overdue';
    } else if (normalizedDue.difference(normalizedNow).inDays <= 3) {
      return 'Due Soon';
    } else {
      return 'Upcoming';
    }
  }

  String get daysRemainingText {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = normalizedDue.difference(normalizedNow).inDays;
    if (diff == 0) {
      return 'Due Today';
    } else if (diff == 1) {
      return 'Due Tomorrow';
    } else if (diff > 1) {
      return 'Due in $diff Days';
    } else {
      final absDiff = diff.abs();
      return 'Due $absDiff Days Ago';
    }
  }

  CalendarReminder copyWith({
    String? id,
    String? title,
    String? type,
    DateTime? dueDate,
    int? amount,
    bool? isPaid,
    bool? isSystemGenerated,
    String? notes,
    bool? reminderEnabled,
  }) {
    return CalendarReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      isSystemGenerated: isSystemGenerated ?? this.isSystemGenerated,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}

// Subscriptions Stream Provider
final subscriptionsStreamProvider = StreamProvider.autoDispose<List<Subscription>>((ref) {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return const Stream.empty();
  return db.subscriptionDao.watchSubscriptionsForUser(userId);
});

// Detected Recurring Pattern class
class DetectedRecurringPattern {
  final String title;
  final String category;
  final int averageAmount; // in cents
  final int frequencyDays; // e.g. 30 for monthly
  final List<Transaction> occurrences;

  DetectedRecurringPattern({
    required this.title,
    required this.category,
    required this.averageAmount,
    required this.frequencyDays,
    required this.occurrences,
  });
}

// Smart Reminder & Recurring Engine
class SmartReminderEngine {
  final Ref _ref;

  SmartReminderEngine(this._ref);

  // Automatically detect recurring transactions
  List<DetectedRecurringPattern> detectRecurringTransactions(List<Transaction> txs) {
    final Map<String, List<Transaction>> grouped = {};
    for (var tx in txs) {
      if (tx.type == 'expense' || tx.type == 'income') {
        final key = (tx.merchant ?? tx.description ?? 'transaction').toLowerCase().trim();
        grouped.putIfAbsent(key, () => []).add(tx);
      }
    }

    final List<DetectedRecurringPattern> patterns = [];
    grouped.forEach((key, occurrences) {
      if (occurrences.length < 2) return;
      
      // Sort occurrences chronologically
      occurrences.sort((a, b) => a.date.compareTo(b.date));
      
      // Calculate intervals
      final List<int> intervals = [];
      for (int i = 0; i < occurrences.length - 1; i++) {
        intervals.add(occurrences[i + 1].date.difference(occurrences[i].date).inDays);
      }
      
      // Check if intervals are consistently monthly (25-35 days) or weekly (6-8 days)
      final bool isMonthly = intervals.every((days) => days >= 25 && days <= 35);
      final bool isWeekly = intervals.every((days) => days >= 6 && days <= 8);

      if (isMonthly || isWeekly) {
        final totalAmount = occurrences.fold(0, (sum, tx) => sum + tx.amount);
        final averageAmount = (totalAmount / occurrences.length).round();
        final frequency = isMonthly ? 30 : 7;
        
        final cleanTitle = occurrences.first.merchant ?? occurrences.first.description ?? 'Recurring payment';
        
        patterns.add(DetectedRecurringPattern(
          title: cleanTitle,
          category: occurrences.first.categoryId ?? 'Uncategorized',
          averageAmount: averageAmount,
          frequencyDays: frequency,
          occurrences: occurrences,
        ));
      }
    });

    return patterns;
  }

  // Get active reminder list combining all data sources
  List<CalendarReminder> getReminders({
    required List<Transaction> transactions,
    required List<Goal> goals,
    required List<Subscription> subscriptions,
  }) {
    final List<CalendarReminder> reminders = [];

    // 1. Add Subscriptions as reminders
    for (var sub in subscriptions) {
      reminders.add(CalendarReminder(
        id: 'sub-${sub.id}',
        title: sub.title,
        type: 'subscription',
        dueDate: sub.renewalDate,
        amount: sub.monthlyCost,
        isPaid: sub.status == 'paid',
        isSystemGenerated: true,
        notes: 'Provider: ${sub.providerName}',
      ));
    }

    // 2. Add Goals as reminders on their target dates
    for (var goal in goals) {
      final savedAmount = goal.currentAmount;
      final targetAmount = goal.targetAmount;
      reminders.add(CalendarReminder(
        id: 'goal-${goal.id}',
        title: 'Target: ${goal.title}',
        type: 'goal',
        dueDate: goal.targetDate,
        amount: targetAmount - savedAmount,
        isPaid: savedAmount >= targetAmount,
        isSystemGenerated: true,
        notes: 'Target Date for goal achievement.',
      ));
    }

    // 3. Add pending transactions with a due date
    for (var tx in transactions) {
      if (tx.dueDate != null) {
        String type = 'upcoming_bill';
        if (tx.type == 'credit_card_bill' || tx.type == 'credit_card_bill_reminder') {
          type = 'credit_card_due';
        } else if (tx.type == 'emi') {
          type = 'emi';
        } else if (tx.type == 'loan_payment') {
          type = 'loan_payment';
        } else if (tx.description?.toLowerCase().contains('salary') ?? false) {
          type = 'salary';
        } else if (tx.type == 'income') {
          type = 'income';
        }

        reminders.add(CalendarReminder(
          id: 'tx-reminder-${tx.id}',
          title: tx.description ?? tx.merchant ?? 'Bill Payment',
          type: type,
          dueDate: tx.dueDate!,
          amount: tx.amount,
          isPaid: tx.billStatus == 'paid',
          isSystemGenerated: false,
          notes: tx.merchant != null ? 'Merchant: ${tx.merchant}' : null,
        ));
      }
    }

    // Sort chronologically
    reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return reminders;
  }

  // Toggle paid status for a reminder in the database/settings
  Future<void> toggleReminderPaidStatus(CalendarReminder reminder) async {
    final db = _ref.read(databaseProvider);
    final isPaidNew = !reminder.isPaid;

    if (reminder.id.startsWith('tx-reminder-')) {
      final txId = reminder.id.replaceFirst('tx-reminder-', '');
      final tx = await db.transactionDao.getTransactionById(txId);
      if (tx != null) {
        final updatedTx = tx.copyWith(
          billStatus: Value(isPaidNew ? 'paid' : 'pending'),
          updatedAt: DateTime.now(),
        );
        await db.transactionDao.updateTransaction(updatedTx);
        _ref.invalidate(expenseListNotifierProvider);
      }
    } else if (reminder.id.startsWith('sub-')) {
      final subId = reminder.id.replaceFirst('sub-', '');
      final sub = await db.subscriptionDao.getSubscriptionById(subId);
      if (sub != null) {
        final updatedSub = sub.copyWith(
          status: isPaidNew ? 'paid' : 'active',
          updatedAt: DateTime.now(),
        );
        await db.subscriptionDao.updateSubscription(updatedSub);
        _ref.invalidate(subscriptionsStreamProvider);
      }
    }
  }
}

final smartReminderEngineProvider = Provider<SmartReminderEngine>((ref) {
  return SmartReminderEngine(ref);
});

// Reminders List Provider
final remindersListProvider = Provider<List<CalendarReminder>>((ref) {
  final txsAsync = ref.watch(expenseListNotifierProvider);
  final goals = ref.watch(goalsListNotifierProvider);
  final subsAsync = ref.watch(subscriptionsStreamProvider);

  final List<Transaction> txs = txsAsync.maybeWhen(
    data: (list) => list,
    orElse: () => [],
  );

  final List<Subscription> subs = subsAsync.maybeWhen(
    data: (list) => list,
    orElse: () => [],
  );

  return ref.read(smartReminderEngineProvider).getReminders(
    transactions: txs,
    goals: goals,
    subscriptions: subs,
  );
});

// Detected Recurring Transactions List Provider
final detectedRecurringProvider = Provider<List<DetectedRecurringPattern>>((ref) {
  final txsAsync = ref.watch(expenseListNotifierProvider);
  final List<Transaction> txs = txsAsync.maybeWhen(
    data: (list) => list,
    orElse: () => [],
  );
  return ref.read(smartReminderEngineProvider).detectRecurringTransactions(txs);
});
