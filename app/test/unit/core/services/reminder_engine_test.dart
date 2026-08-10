import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/reminder_engine.dart';

void main() {
  group('SmartReminderEngine Tests', () {
    late SmartReminderEngine engine;
    final now = DateTime.now();

    setUp(() {
      final container = ProviderContainer();
      engine = container.read(smartReminderEngineProvider);
    });

    test('getReminders merges goals, subscriptions, and transactions with due dates', () {
      final transactions = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'expense',
          amount: 5000,
          currency: 'INR',
          date: now,
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          dueDate: now.add(const Duration(days: 2)),
          billStatus: 'pending',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final goals = [
        Goal(
          id: 'goal1',
          userId: 'user1',
          title: 'New Laptop',
          targetAmount: 8000000, // ₹80,000
          currentAmount: 2000000, // ₹20,000
          targetDate: now.add(const Duration(days: 30)),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final subscriptions = [
        Subscription(
          id: 'sub1',
          userId: 'user1',
          title: 'Netflix Premium',
          monthlyCost: 64900,
          annualCost: 0,
          billingCycle: 'monthly',
          renewalDate: now.add(const Duration(days: 10)),
          providerName: 'Netflix',
          confidence: 1.0,
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final reminders = engine.getReminders(
        transactions: transactions,
        goals: goals,
        subscriptions: subscriptions,
      );

      // Verify consolidation count (1 subscription, 1 goal, 1 transaction = 3 reminders)
      expect(reminders.length, equals(3));

      // Verify Netlfix subscription reminder
      final subReminder = reminders.firstWhere((r) => r.type == 'subscription');
      expect(subReminder.title, equals('Netflix Premium'));
      expect(subReminder.amount, equals(64900));

      // Verify Goal reminder amount (target - current = 60,000)
      final goalReminder = reminders.firstWhere((r) => r.type == 'goal');
      expect(goalReminder.amount, equals(6000000));
    });

    test('detectRecurringTransactions finds monthly recurring expenses', () {
      final txs = [
        Transaction(
          id: 'tx-oct',
          userId: 'user1',
          type: 'expense',
          amount: 19900,
          currency: 'INR',
          merchant: 'Spotify',
          date: DateTime(2026, 1, 1),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 'tx-nov',
          userId: 'user1',
          type: 'expense',
          amount: 19900,
          currency: 'INR',
          merchant: 'Spotify',
          date: DateTime(2026, 2, 1),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final patterns = engine.detectRecurringTransactions(txs);

      // Should detect Spotify monthly subscription
      expect(patterns.length, equals(1));
      expect(patterns.first.title, equals('Spotify'));
      expect(patterns.first.frequencyDays, equals(30));
    });
  });
}
