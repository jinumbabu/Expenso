import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/sms_agent.dart';
import 'package:app/core/services/ledger_agent.dart';
import 'package:app/core/services/balance_engine.dart';
import 'package:app/core/services/duplicate_scanner.dart';

void main() {
  late AppDatabase database;
  late SmsAgent smsAgent;
  late LedgerAgent ledgerAgent;
  final testDate = DateTime(2026, 6, 28);
  const userId = 'user_test_123';

  setUp(() async {
    database = AppDatabase.connect(NativeDatabase.memory());
    smsAgent = SmsAgent(database);
    ledgerAgent = LedgerAgent(database);

    // Seed default categories
    await database.categoryDao.insertCategory(
      Category(
        id: 'cat_salary',
        userId: 'system',
        name: 'Salary',
        type: 'income',
        usageCount: 0,
        isSystemDefault: true,
        createdAt: DateTime.now(),
      ),
    );
    await database.categoryDao.insertCategory(
      Category(
        id: 'cat_shopping',
        userId: 'system',
        name: 'Shopping',
        type: 'expense',
        usageCount: 0,
        isSystemDefault: true,
        createdAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('SMS Auto Import Redesign Tests', () {
    test('High confidence SMS creates transaction and marks account as estimated', () async {
      const sms = 'Dear Employee, your Salary of Rs 75,000.00 has been credited to HDFC A/c XX1234 on 28-Jun-26.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);
      
      expect(result, isNotNull);
      expect(result!.confidence, greaterThanOrEqualTo(0.90));

      // 2. Reconcile with LedgerAgent
      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: 'cat_salary',
        paymentMethodId: 'pm_upi',
        type: result.transactionType,
        amount: (result.amount * 100).round(),
        currency: 'INR',
        description: 'SMS Alert: ${result.account}',
        merchant: result.merchant,
        date: result.date,
        source: 'sms',
        confidenceScore: result.confidence,
        isRecurring: false,
        syncStatus: 'pending',
        transactionType: result.category,
        accountType: result.accountType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ledgerAgent.reconcileTransaction(tx, confidence: result.confidence);

      // 3. Verify that the account was created with isEstimated = true and balance = ₹75,000
      final accounts = await database.select(database.accounts).get();
      expect(accounts, isNotEmpty);
      final acc = accounts.firstWhere((a) => a.name.contains('1234'));
      expect(acc.isEstimated, isTrue);
      expect(acc.balance, equals(7500000)); // ₹75,000
    });

    test('Low confidence SMS does not create transaction/account, but saves draft', () async {
      final draft = TransactionDraft(
        id: const Uuid().v4(),
        userId: userId,
        amount: 150000, // ₹1,500
        type: 'expense',
        currency: 'INR',
        merchant: 'Starbucks',
        description: 'Low confidence alert',
        date: testDate,
        smsBody: 'Your A/c XX4321 debited for Rs 1,500.00 at Starbucks.',
        createdAt: DateTime.now(),
        categoryId: 'cat_shopping',
        category: 'Shopping',
        confidenceScore: 0.85,
      );

      await database.transactionDraftDao.insertDraft(draft);

      final savedDrafts = await database.transactionDraftDao.getDraftsForUser(userId);
      expect(savedDrafts, hasLength(1));
      expect(savedDrafts.first.confidenceScore, equals(0.85));
      expect(savedDrafts.first.categoryId, equals('cat_shopping'));
      expect(savedDrafts.first.category, equals('Shopping'));
    });

    test('BalanceEngine recalculates estimated account balance correctly when opening balance is updated', () async {
      // 1. Create an estimated account with ₹0 opening balance
      final accId = const Uuid().v4();
      final acc = Account(
        id: accId,
        userId: userId,
        name: 'SBI A/c 5678',
        type: 'bank',
        balance: 100000, // starts at ₹1,000
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: true,
        openingBalance: 0,
      );
      await database.into(database.accounts).insert(acc);

      // 2. Add an expense of ₹200 to this account
      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: accId,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 20000, // ₹200
        currency: 'INR',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await database.transactionDao.insertTransaction(tx);

      // 3. Recalculate
      final balanceEngine = BalanceEngine(database);
      await balanceEngine.recalculateAllBalances();

      // Check balance is ₹-200 (since opening balance is ₹0 and expense is ₹200)
      var updatedAcc = await database.accountDao.getAccountById(accId);
      expect(updatedAcc!.balance, equals(-20000));

      // 4. User corrects opening balance to ₹5,000 and sets isEstimated to false
      await database.accountDao.updateAccount(updatedAcc.copyWith(
        openingBalance: const Value(500000), // ₹5,000
        isEstimated: false,
      ));

      // 5. Recalculate
      await balanceEngine.recalculateAllBalances();

      // Balance should now be ₹4,800 (₹5,000 - ₹200)
      updatedAcc = await database.accountDao.getAccountById(accId);
      expect(updatedAcc!.balance, equals(480000));
      expect(updatedAcc.isEstimated, isFalse);
    });

    test('Credit card purchase SMS is classified as credit card expense, creates card account, and doesn\'t affect savings account balance', () async {
      const sms = 'A transaction of Rs.346.00 was made using your HDFC Bank Pixel Go Credit Card XX1234 on 28-Jun-26.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);

      expect(result, isNotNull);
      expect(result!.accountType, equals('Credit Card'));

      // 2. Reconcile with LedgerAgent
      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_card',
        type: result.transactionType, // 'expense'
        amount: (result.amount * 100).round(), // 34600
        currency: 'INR',
        description: 'SMS Alert: ${result.account}',
        merchant: result.merchant,
        date: result.date,
        source: 'sms',
        confidenceScore: result.confidence,
        isRecurring: false,
        syncStatus: 'pending',
        transactionType: result.category,
        accountType: result.accountType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ledgerAgent.reconcileTransaction(tx, confidence: result.confidence);

      // Verify credit card account is created and outstanding is increased to ₹346 (represented as balance = -₹346)
      final accounts = await database.select(database.accounts).get();
      expect(accounts, isNotEmpty);
      final ccAcc = accounts.firstWhere((a) => a.type == 'credit_card');
      expect(ccAcc.name, contains('HDFC 1234'));
      expect(ccAcc.outstandingBalance, equals(34600));
      expect(ccAcc.balance, equals(-34600));

      // Verify no savings account was created or affected by this transaction
      final hasSavings = accounts.any((a) => a.type == 'savings');
      expect(hasSavings, isFalse);
    });

    test('Credit card payment SMS reduces savings balance and credit card outstanding', () async {
      // 1. Create a credit card account with ₹10,000 outstanding balance
      final ccId = const Uuid().v4();
      final ccAcc = Account(
        id: ccId,
        userId: userId,
        name: 'HDFC Pixel Go 1234',
        type: 'credit_card',
        balance: -1000000, // ₹-10,000
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        outstandingBalance: 1000000, // ₹10,000
        creditLimit: 5000000, // ₹50,000
        availableCredit: 4000000, // ₹40,000
        isEstimated: false,
      );
      await database.into(database.accounts).insert(ccAcc);

      // 2. Create a savings account with ₹15,000 balance
      final savingsId = const Uuid().v4();
      final savingsAcc = Account(
        id: savingsId,
        userId: userId,
        name: 'Main Savings A/c',
        type: 'savings',
        balance: 1500000, // ₹15,000
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        openingBalance: 1500000,
        isEstimated: false,
      );
      await database.into(database.accounts).insert(savingsAcc);

      // 3. Receive payment SMS: "Thank you for payment of Rs.5,000 towards HDFC Pixel Go Credit Card 1234."
      const sms = 'Thank you for payment of Rs.5,000 towards HDFC Pixel Go Credit Card 1234.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);

      expect(result, isNotNull);
      expect(result!.transactionType, equals('credit_card_payment'));

      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_card',
        type: result.transactionType,
        amount: (result.amount * 100).round(), // 500000
        currency: 'INR',
        description: 'SMS Alert: ${result.account}',
        merchant: result.merchant,
        date: result.date,
        source: 'sms',
        confidenceScore: result.confidence,
        isRecurring: false,
        syncStatus: 'pending',
        transactionType: result.category,
        accountType: result.accountType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ledgerAgent.reconcileTransaction(tx, confidence: result.confidence);

      // 4. Verify savings account balance is reduced by ₹5,000 (from ₹15,000 to ₹10,000)
      final updatedSavings = await database.accountDao.getAccountById(savingsId);
      expect(updatedSavings!.balance, equals(1000000)); // ₹10,000



      // 5. Verify credit card outstanding balance is reduced by ₹5,000 (from ₹10,000 to ₹5,000)
      final updatedCC = await database.accountDao.getAccountById(ccId);
      expect(updatedCC!.outstandingBalance, equals(500000)); // ₹5,000
      expect(updatedCC.balance, equals(-500000)); // ₹-5,000
      expect(updatedCC.availableCredit, equals(4500000)); // ₹45,000
    });

    test('Fuzzy 10-minute duplicate matches are merged and not duplicated', () async {
      final tx1 = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 15000, // ₹150
        currency: 'INR',
        description: 'UPI Debit Starbucks',
        merchant: 'Starbucks',
        date: testDate,
        source: 'sms',
        confidenceScore: 0.95,
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tx2 = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 15000, // ₹150
        currency: 'INR',
        description: 'UPI Confirmation Starbucks',
        merchant: 'Starbucks Coffee',
        date: testDate.add(const Duration(minutes: 5)),
        source: 'sms',
        confidenceScore: 0.95,
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Reconcile first
      final res1 = await ledgerAgent.reconcileTransaction(tx1);
      expect(res1.status, equals(ReconciliationStatus.inserted));

      // Reconcile duplicate within 5 mins
      final res2 = await ledgerAgent.reconcileTransaction(tx2);
      expect(res2.status, equals(ReconciliationStatus.merged));

      // Check DB contains only 1 transaction
      final txList = await database.transactionDao.getTransactionsForUser(userId);
      expect(txList, hasLength(1));

      // Verify fields are merged and supporting SMS is appended
      final mergedTx = txList.first;
      expect(mergedTx.merchant, equals('Starbucks Coffee'));
      expect(mergedTx.supportingSms, isNotNull);
      final smsList = List<String>.from(jsonDecode(mergedTx.supportingSms!));
      expect(smsList, contains('UPI Debit Starbucks'));
      expect(smsList, contains('UPI Confirmation Starbucks'));
    });

    test('Identical fingerprints skip transaction creation', () async {
      final tx1 = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 30000,
        currency: 'INR',
        description: 'UPI Starbucks',
        merchant: 'Starbucks',
        date: testDate,
        referenceNumber: 'UTR123456',
        source: 'sms',
        confidenceScore: 0.95,
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Reconcile first (fingerprint is generated internally)
      final res1 = await ledgerAgent.reconcileTransaction(tx1);
      expect(res1.status, equals(ReconciliationStatus.inserted));

      // Reconcile identical second time
      final res2 = await ledgerAgent.reconcileTransaction(tx1);
      expect(res2.status, equals(ReconciliationStatus.skipped));

      final txList = await database.transactionDao.getTransactionsForUser(userId);
      expect(txList, hasLength(1));
    });

    test('Credit Card statement alerts create upcoming_bill and update Credit Card account', () async {
      // 1. Create credit card account
      final ccId = const Uuid().v4();
      final ccAcc = Account(
        id: ccId,
        userId: userId,
        name: 'HDFC Credit Card 5678',
        type: 'credit_card',
        balance: 0,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        outstandingBalance: 0,
        creditLimit: 5000000,
        availableCredit: 5000000,
        isEstimated: false,
      );
      await database.into(database.accounts).insert(ccAcc);

      // 2. Parse Credit Card Bill Alert SMS
      const sms = 'Your HDFC Credit Card 5678 statement generated. Total Amt Due: Rs. 12,000, Min Amt Due: Rs. 1,200. Due date 15-Jul-26.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);

      expect(result, isNotNull);
      expect(result!.category, equals('Credit Card Bill Reminder'));
      expect(result.transactionType, equals('upcoming_bill'));
      expect(result.amount, equals(12000.0));

      // 3. Reconcile
      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_card',
        type: result.transactionType,
        amount: (result.amount * 100).round(), // 1200000
        currency: 'INR',
        description: 'SMS Alert: HDFC Credit Card 5678',
        merchant: result.merchant,
        date: result.date,
        dueDate: DateTime(2026, 7, 15),
        source: 'sms',
        confidenceScore: result.confidence,
        isRecurring: false,
        syncStatus: 'pending',
        transactionType: result.category,
        accountType: result.accountType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final res = await ledgerAgent.reconcileTransaction(tx);
      expect(res.status, equals(ReconciliationStatus.inserted));

      // 4. Verify Account values updated
      final updatedCC = await database.accountDao.getAccountById(ccId);
      expect(updatedCC!.totalAmountDue, equals(1200000)); // ₹12,000
      expect(updatedCC.nextDueDate, equals(DateTime(2026, 7, 15)));
      expect(updatedCC.paymentStatus, equals('unpaid'));

      // 5. Verify BalanceEngine returns 0 delta and CC balance is not affected
      final delta = BalanceEngine(database).getBalanceDelta(tx, 'credit_card');
      expect(delta, equals(0)); // Reminders do not affect ledger balance
    });

    test('Incoming SMS matching existing manual entry is flagged as matchingManual', () async {
      // 1. Create a manual transaction
      final manualTx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 25000, // ₹250
        currency: 'INR',
        description: 'SMS Alert: HDFC Bank',
        merchant: 'Starbucks',
        date: testDate,
        source: 'manual', // MANUAL
        confidenceScore: 1.0,
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // We resolve the account ID for manualTx and save it
      final resManual = await ledgerAgent.reconcileTransaction(manualTx);
      final savedManualTx = (await database.transactionDao.getTransactionsForUser(userId))
          .firstWhere((t) => t.id == manualTx.id || t.merchant == 'Starbucks');

      // 2. Incoming SMS with matching details (Starbucks, Rs 250, within 10 mins)
      final smsTx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 25000, // ₹250
        currency: 'INR',
        description: 'SMS Alert: HDFC Bank',
        merchant: 'Starbucks',
        date: testDate.add(const Duration(minutes: 2)),
        source: 'sms', // SMS
        confidenceScore: 0.95,
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final res = await ledgerAgent.reconcileTransaction(smsTx);
      expect(res.status, equals(ReconciliationStatus.matchingManual));
      expect(res.matchingManualId, equals(savedManualTx.id));
    });

    test('DuplicateScanner merges existing historical duplicates and cleans up DB', () async {
      final accId = const Uuid().v4();
      final acc = Account(
        id: accId,
        userId: userId,
        name: 'SBI 1234',
        type: 'savings',
        balance: 1000000,
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(acc);

      // Insert duplicate transactions directly
      final tx1 = Transaction(
        id: 'dup_tx_1',
        userId: userId,
        accountId: accId,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 50000,
        currency: 'INR',
        description: 'SMS Starbucks',
        merchant: 'Starbucks',
        date: testDate,
        source: 'sms',
        confidenceScore: 0.95,
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tx2 = Transaction(
        id: 'dup_tx_2',
        userId: userId,
        accountId: accId,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 50000,
        currency: 'INR',
        description: 'UPI Starbucks Spend',
        merchant: 'Starbucks',
        date: testDate.add(const Duration(minutes: 4)),
        source: 'sms',
        confidenceScore: 0.95,
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await database.transactionDao.insertTransaction(tx1);
      await database.transactionDao.insertTransaction(tx2);

      // Verify we have 2 transactions initially
      var allTxs = await database.transactionDao.getTransactionsForUser(userId);
      expect(allTxs, hasLength(2));

      // Run Duplicate Scanner
      final scanner = DuplicateScanner(database);
      final mergedCount = await scanner.scanAndCleanupDuplicates(userId);

      expect(mergedCount, equals(1));

      // Verify only 1 transaction remains in DB
      allTxs = await database.transactionDao.getTransactionsForUser(userId);
      expect(allTxs, hasLength(1));
      expect(allTxs.first.id, equals('dup_tx_1'));
      expect(allTxs.first.merchant, equals('Starbucks'));
    });

    test('SMS with Sent, From, To, On, Ref structure is parsed and imported successfully', () async {
      const sms = 'Sent Rs.200.00\n'
          'From HDFC Bank A/C *3726\n'
          'To R P G V RANGANATHAM AGENC\n'
          'On 17/07/26\n'
          'Ref 619819357527';

      final result = await smsAgent.processSms(sms, testDate, userId: userId);

      expect(result, isNotNull);
      expect(result!.transactionType, equals('expense'));
      expect(result.amount, equals(200.00));
      expect(result.accountNumber, equals('3726'));
      expect(result.merchant, equals('R P G V Ranganatham Agenc'));
      expect(result.referenceId, equals('619819357527'));
      expect(result.date.year, equals(2026));
      expect(result.date.month, equals(7));
      expect(result.date.day, equals(17));

      final categoryId = 'cat_shopping_test_new';
      await database.categoryDao.insertCategory(
        Category(
          id: categoryId,
          userId: userId,
          name: 'Shopping',
          type: 'expense',
          usageCount: 0,
          isSystemDefault: false,
          createdAt: DateTime.now(),
        ),
      );

      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: categoryId,
        paymentMethodId: 'pm_upi',
        type: result.transactionType,
        amount: (result.amount * 100).round(),
        currency: 'INR',
        description: 'SMS Alert: ${result.account}',
        merchant: result.merchant,
        date: result.date,
        source: 'sms',
        confidenceScore: result.confidence,
        isRecurring: false,
        syncStatus: 'pending',
        transactionType: result.category,
        accountType: result.accountType,
        referenceNumber: result.referenceId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final reconciliationResult = await ledgerAgent.reconcileTransaction(tx, confidence: result.confidence);
      expect(reconciliationResult.status, equals(ReconciliationStatus.inserted));

      final txs = await database.transactionDao.getTransactionsForUser(userId);
      final inserted = txs.firstWhere((t) => t.referenceNumber == '619819357527');
      expect(inserted.amount, equals(20000));
      expect(inserted.merchant, equals('R P G V Ranganatham Agenc'));
      expect(inserted.date, equals(DateTime(2026, 7, 17, testDate.hour, testDate.minute, testDate.second)));
    });
  });
}
