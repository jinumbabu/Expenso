import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/sms_agent.dart';
import 'package:app/core/services/ledger_agent.dart';
import 'package:app/core/services/sms_account_matcher.dart';

void main() {
  late AppDatabase database;
  late SmsAgent smsAgent;
  late LedgerAgent ledgerAgent;
  final testDate = DateTime(2026, 7, 21);
  const userId = 'test_user_review_999';

  setUp(() async {
    database = AppDatabase.connect(NativeDatabase.memory());
    smsAgent = SmsAgent(database);
    ledgerAgent = LedgerAgent(database);

    // Seed Categories
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

    // Seed Payment Methods
    await database.paymentMethodDao.insertPaymentMethod(
      PaymentMethod(
        id: 'pm_upi',
        userId: 'system',
        name: 'UPI',
        type: 'upi',
        usageCount: 0,
        createdAt: DateTime.now(),
      ),
    );
    await database.paymentMethodDao.insertPaymentMethod(
      PaymentMethod(
        id: 'pm_cc',
        userId: 'system',
        name: 'Credit Card',
        type: 'card',
        usageCount: 0,
        createdAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('SMS Account Logic Engine Review Tests', () {
    test('1 & 5. Transaction from HDFC 3726 maps ONLY to HDFC 3726 and never SBI 1946', () async {
      // 1. Seed two accounts: SBI 1946 and HDFC 3726
      final sbiAcc = Account(
        id: 'acc_sbi_1946',
        userId: userId,
        name: 'SBI 1946',
        type: 'savings',
        balance: 1000000,
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bankName: 'State Bank of India',
        last4Digits: '1946',
        isEstimated: false,
      );
      final hdfcAcc = Account(
        id: 'acc_hdfc_3726',
        userId: userId,
        name: 'HDFC 3726',
        type: 'savings',
        balance: 500000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bankName: 'HDFC Bank',
        last4Digits: '3726',
        isEstimated: false,
      );
      await database.into(database.accounts).insert(sbiAcc);
      await database.into(database.accounts).insert(hdfcAcc);

      // 2. Parse SMS for HDFC 3726
      const sms = 'Rs 49.00 debited from HDFC Savings Account ****3726 on 21-Jul-26 by UPI Ref 123456. Info: Tea Stall.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);

      expect(result, isNotNull);

      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_upi',
        type: result!.transactionType,
        amount: (result.amount * 100).round(),
        currency: 'INR',
        description: 'SMS Alert: HDFC Savings Account ****3726',
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

      final res = await ledgerAgent.reconcileTransaction(tx, confidence: result.confidence);
      expect(res.status, equals(ReconciliationStatus.inserted));

      // 3. Verify Saved Transaction.accountId is HDFC 3726
      final allTxs = await database.transactionDao.getTransactionsForUser(userId);
      expect(allTxs, hasLength(1));
      final savedTx = allTxs.first;

      expect(savedTx.accountId, equals('acc_hdfc_3726'));
      expect(savedTx.description, contains('HDFC Savings Account ****3726'));

      // 4. Verify Ledger Isolation
      final sbiLedger = allTxs.where((t) => t.accountId == 'acc_sbi_1946').toList();
      final hdfcLedger = allTxs.where((t) => t.accountId == 'acc_hdfc_3726').toList();

      expect(sbiLedger, isEmpty);
      expect(hdfcLedger, hasLength(1));
      expect(hdfcLedger.first.amount, equals(4900));
    });

    test('HDFC UPI XXXX3726 debited ₹11735 matches existing HDFC 3726 account and NEVER Cash', () async {
      final hdfcAcc = Account(
        id: 'acc_hdfc_3726_exist',
        userId: userId,
        name: 'HDFC 3726',
        type: 'savings',
        balance: 5000000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bankName: 'HDFC Bank',
        last4Digits: '3726',
        isEstimated: false,
      );
      await database.into(database.accounts).insert(hdfcAcc);

      const smsText = 'HDFC UPI XXXX3726 debited ₹11,735.00 for Reliance Digital';
      final existing = await (database.select(database.accounts)..where((a) => a.userId.equals(userId))).get();
      final matchResult = SmsAccountMatcher.matchAccount(
        smsText: smsText,
        existingAccounts: existing,
        cardOrAccount: '1234567890', // UTR number
      );

      expect(matchResult.matchedAccount, isNotNull);
      expect(matchResult.matchedAccount!.id, equals('acc_hdfc_3726_exist'));
      expect(matchResult.paymentMethod, equals('UPI'));
      expect(matchResult.isNewAccountNeeded, isFalse);

      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 1173500, // ₹11,735
        currency: 'INR',
        description: smsText,
        merchant: 'Reliance Digital',
        referenceNumber: '1234567890',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ledgerAgent.reconcileTransaction(tx);

      final allTxs = await database.transactionDao.getTransactionsForUser(userId);
      final txSaved = allTxs.firstWhere((t) => t.amount == 1173500);

      expect(txSaved.accountId, equals('acc_hdfc_3726_exist'));
      expect(txSaved.accountId, isNot(equals('cash')));
    });

    test('2. Multiple SMS account references are NOT mixed or appended', () async {
      // Seed accounts
      final sbiAcc = Account(
        id: 'acc_sbi_9462',
        userId: userId,
        name: 'SBI 9462',
        type: 'savings',
        balance: 1000000,
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bankName: 'State Bank of India',
        last4Digits: '9462',
        isEstimated: false,
      );
      final hdfcAcc = Account(
        id: 'acc_hdfc_3726',
        userId: userId,
        name: 'HDFC 3726',
        type: 'savings',
        balance: 500000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bankName: 'HDFC Bank',
        last4Digits: '3726',
        isEstimated: false,
      );
      await database.into(database.accounts).insert(sbiAcc);
      await database.into(database.accounts).insert(hdfcAcc);

      // Reconcile SBI SMS
      final txSbi = Transaction(
        id: 'tx_sbi',
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 25000, // ₹250
        currency: 'INR',
        description: 'SMS Alert: SBI Savings Account ****9462',
        merchant: 'Coffee Shop',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ledgerAgent.reconcileTransaction(txSbi);

      // Reconcile HDFC SMS on same day with same amount
      final txHdfc = Transaction(
        id: 'tx_hdfc',
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 25000, // ₹250
        currency: 'INR',
        description: 'SMS Alert: HDFC Savings Account ****3726',
        merchant: 'Coffee Shop',
        date: testDate.add(const Duration(minutes: 5)),
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ledgerAgent.reconcileTransaction(txHdfc);

      // Both transactions must remain distinct in their respective ledgers
      final allTxs = await database.transactionDao.getTransactionsForUser(userId);
      expect(allTxs, hasLength(2));

      final savedSbi = allTxs.firstWhere((t) => t.accountId == 'acc_sbi_9462');
      final savedHdfc = allTxs.firstWhere((t) => t.accountId == 'acc_hdfc_3726');

      expect(savedSbi.description, contains('SBI Savings Account ****9462'));
      expect(savedSbi.description, isNot(contains('HDFC')));

      expect(savedHdfc.description, contains('HDFC Savings Account ****3726'));
      expect(savedHdfc.description, isNot(contains('SBI')));
    });

    test('3. Credit Card SMS (Axis 6935) maps strictly to Credit Card account', () async {
      final ccAcc = Account(
        id: 'acc_axis_6935',
        userId: userId,
        name: 'Axis 6935',
        type: 'credit_card',
        balance: 0,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bankName: 'Axis Bank',
        last4Digits: '6935',
        outstandingBalance: 0,
        creditLimit: 10000000,
        availableCredit: 10000000,
        isEstimated: false,
      );
      await database.into(database.accounts).insert(ccAcc);

      const sms = 'Spent Rs 1500.00 on Axis Credit Card ****6935 at Amazon India on 21-Jul-26.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);

      expect(result, isNotNull);
      expect(result!.accountType, equals('Credit Card'));

      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: null,
        categoryId: 'cat_shopping',
        paymentMethodId: 'pm_cc',
        type: result.transactionType,
        amount: (result.amount * 100).round(),
        currency: 'INR',
        description: 'SMS Alert: Axis Credit Card ****6935',
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

      final allTxs = await database.transactionDao.getTransactionsForUser(userId);
      expect(allTxs, hasLength(1));
      expect(allTxs.first.accountId, equals('acc_axis_6935'));

      final updatedCC = await database.accountDao.getAccountById('acc_axis_6935');
      expect(updatedCC!.outstandingBalance, equals(150000)); // ₹1,500
      expect(updatedCC.balance, equals(-150000));
    });
  });
}
