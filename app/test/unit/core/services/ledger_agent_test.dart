import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/ledger_agent.dart';

void main() {
  late AppDatabase database;
  late LedgerAgent ledgerAgent;

  setUp(() {
    database = AppDatabase.connect(NativeDatabase.memory());
    ledgerAgent = LedgerAgent(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('LedgerAgent Reconcile & Deduplication Tests', () {
    final testDate = DateTime(2026, 6, 21, 10, 0);

    test('reconcileTransaction inserts transaction and reconciles account balance when no duplicate exists', () async {
      final tx = Transaction(
        id: const Uuid().v4(),
        userId: 'user-1',
        type: 'expense',
        amount: 15000, // ₹150 (cents)
        currency: 'INR',
        merchant: 'Uber',
        date: testDate,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ledgerAgent.reconcileTransaction(tx);

      // Verify transaction inserted
      final txs = await database.transactionDao.getTransactionsForUser('user-1');
      expect(txs.length, equals(1));
      expect(txs.first.merchant, equals('Uber'));

      // Verify account and balance created/updated (Cash Wallet for manual source)
      final accounts = await (database.select(database.accounts)).get();
      expect(accounts.length, equals(1));
      expect(accounts.first.name, equals('Cash Wallet'));
      // Seed balance is 1000000 (₹10,000) - 15000 = 985000 (₹9,850)
      expect(accounts.first.balance, equals(985000));
    });

    test('reconcileTransaction merges description and merchant when a duplicate exists within the same day', () async {
      final txId1 = const Uuid().v4();
      final tx1 = Transaction(
        id: txId1,
        userId: 'user-1',
        type: 'expense',
        amount: 50000, // ₹500
        currency: 'INR',
        merchant: 'Netflix',
        description: 'Monthly Fee',
        date: testDate,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insert first
      await database.transactionDao.insertTransaction(tx1);

      // Attempt to insert duplicate from SMS
      final tx2 = Transaction(
        id: const Uuid().v4(),
        userId: 'user-1',
        type: 'expense',
        amount: 50000, // Same amount
        currency: 'INR',
        merchant: 'Netflix Premium',
        description: 'Netflix alert notification',
        date: testDate.add(const Duration(minutes: 30)), // within same day
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ledgerAgent.reconcileTransaction(tx2);

      // Check transactions - should STILL be 1 transaction due to merge
      final txs = await database.transactionDao.getTransactionsForUser('user-1');
      expect(txs.length, equals(1));
      expect(txs.first.id, equals(txId1));
      expect(txs.first.merchant, equals('Netflix Premium'));
      expect(txs.first.description, contains('Monthly Fee'));
      expect(txs.first.description, contains('Netflix alert notification'));

      // Verify AgentLog recorded a merge
      final logs = await database.agentLogDao.getLogs(10);
      expect(logs.any((l) => l.actionType == 'TRANSACTION_MERGED'), isTrue);
    });
  });
}
