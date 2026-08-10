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
      expect(accounts.first.name, equals('Cash'));
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

    test('reconcileTransaction creates SMS account with null opening balance', () async {
      final tx = Transaction(
        id: const Uuid().v4(),
        userId: 'user-1',
        type: 'expense',
        amount: 25000, // ₹250
        currency: 'INR',
        merchant: 'Uber',
        date: testDate,
        source: 'sms', // SMS source triggers null openingBalance
        isRecurring: false,
        syncStatus: 'pending',
        description: 'SMS Alert: HDFC A/c 3726',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ledgerAgent.reconcileTransaction(tx);

      // Verify account and balance created
      final accounts = await (database.select(database.accounts)).get();
      expect(accounts.length, equals(1));
      expect(accounts.first.name, equals('HDFC 3726'));
      expect(accounts.first.openingBalance, isNull);
      expect(accounts.first.last4Digits, equals('3726'));
    });

    test('reconcileTransaction merges generic duplicate account and migrates transactions', () async {
      // 1. Manually create generic account
      final genericAccount = Account(
        id: 'generic-hdfc',
        userId: 'user-1',
        name: 'HDFC Bank',
        type: 'savings',
        balance: 100000,
        openingBalance: 100000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bankName: 'HDFC',
        isEstimated: false,
      );
      await database.into(database.accounts).insert(genericAccount);

      // Add a transaction on the generic account
      final txOld = Transaction(
        id: 'tx-old-1',
        userId: 'user-1',
        accountId: 'generic-hdfc',
        type: 'expense',
        amount: 5000,
        currency: 'INR',
        date: testDate.subtract(const Duration(days: 1)),
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await database.transactionDao.insertTransaction(txOld);

      // 2. Incoming SMS with specific A/c 3726
      final txSms = Transaction(
        id: 'tx-sms-1',
        userId: 'user-1',
        type: 'expense',
        amount: 12000,
        currency: 'INR',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        description: 'SMS Alert: HDFC A/c 3726',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Reconcile SMS transaction - should detect generic account, rename it, and map txSms to it
      await ledgerAgent.reconcileTransaction(txSms);

      // Verify that there is only one HDFC account left and it is named specific
      final accounts = await (database.select(database.accounts)).get();
      final hdfcAccounts = accounts.where((a) => a.name.contains('HDFC')).toList();
      expect(hdfcAccounts.length, equals(1));
      expect(hdfcAccounts.first.name.contains('HDFC'), isTrue);
      expect(hdfcAccounts.first.last4Digits, equals('3726'));
      expect(hdfcAccounts.first.openingBalance, equals(100000)); // opening balance carried over!

      // Verify both transactions are associated with the merged HDFC A/c 3726
      final txs = await database.transactionDao.getTransactionsForUser('user-1');
      expect(txs.length, equals(2));
      for (var t in txs) {
        expect(t.accountId, equals(hdfcAccounts.first.id));
      }
    });
  });
}
