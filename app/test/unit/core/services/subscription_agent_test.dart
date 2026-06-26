import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/subscription_agent.dart';

void main() {
  late AppDatabase database;
  late SubscriptionAgent subscriptionAgent;

  setUp(() {
    database = AppDatabase.connect(NativeDatabase.memory());
    subscriptionAgent = SubscriptionAgent(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('SubscriptionAgent Scanning & Detection Tests', () {
    final testDate = DateTime(2026, 6, 21);

    test('detects a known subscription from a single transaction', () async {
      // Netflix is in the known list
      final tx = Transaction(
        id: const Uuid().v4(),
        userId: 'user-1',
        type: 'expense',
        amount: 64900, // ₹649
        currency: 'INR',
        merchant: 'Netflix',
        date: testDate,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await database.transactionDao.insertTransaction(tx);

      final subs = await subscriptionAgent.scanAndDetectSubscriptions('user-1');
      expect(subs.length, equals(1));
      expect(subs.first.title, equals('Netflix'));
      expect(subs.first.monthlyCost, equals(64900));
      expect(subs.first.annualCost, equals(64900 * 12));
      expect(subs.first.billingCycle, equals('monthly'));

      // Check database
      final dbSubs = await database.subscriptionDao.getSubscriptionsForUser('user-1');
      expect(dbSubs.length, equals(1));
      expect(dbSubs.first.title, equals('Netflix'));
    });

    test('detects monthly subscription from recurring intervals', () async {
      // 3 transactions separated by exactly 30 days
      final tx1 = Transaction(
        id: const Uuid().v4(),
        userId: 'user-1',
        type: 'expense',
        amount: 19900, // ₹199
        currency: 'INR',
        merchant: 'Gym Membership',
        date: testDate,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final tx2 = tx1.copyWith(
        id: const Uuid().v4(),
        date: testDate.subtract(const Duration(days: 30)),
      );
      final tx3 = tx1.copyWith(
        id: const Uuid().v4(),
        date: testDate.subtract(const Duration(days: 60)),
      );

      await database.transactionDao.insertTransaction(tx1);
      await database.transactionDao.insertTransaction(tx2);
      await database.transactionDao.insertTransaction(tx3);

      final subs = await subscriptionAgent.scanAndDetectSubscriptions('user-1');
      expect(subs.length, equals(1));
      expect(subs.first.title, equals('Gym Membership'));
      expect(subs.first.billingCycle, equals('monthly'));
      expect(subs.first.confidence, equals(1.0));
    });
  });
}
