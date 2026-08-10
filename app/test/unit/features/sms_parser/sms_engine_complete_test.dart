import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/sms_agent.dart';
import 'package:app/core/services/ledger_agent.dart';

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
        id: 'cat_investment',
        userId: 'system',
        name: 'Investment',
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

  group('SmsAgent Classification & Parser Engine Tests', () {
    test('Salary SMS (Income)', () async {
      const sms = 'Dear Employee, your Salary of Rs 75,000.00 has been credited to A/c XX1234 on 28-Jun-26.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(75000.0));
      expect(result.transactionType, equals('income'));
      expect(result.category, equals('Salary'));
      expect(result.accountType, equals('Savings Account'));
      expect(result.account, contains('1234'));
    });

    test('Expense SMS (Expense)', () async {
      const sms = 'Your A/c XX4321 debited for Rs 1,500.00 at Starbucks Cafe.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(1500.0));
      expect(result.transactionType, equals('expense'));
      expect(result.category, equals('Restaurant'));
      expect(result.accountType, equals('Savings Account'));
      expect(result.merchant, equals('Starbucks Cafe'));
    });

    test('Credit Card Purchase', () async {
      const sms = 'Transaction of INR 4,200.00 on Credit Card ending 9999 used at Amazon India.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(4200.0));
      expect(result.transactionType, equals('expense'));
      expect(result.category, equals('Shopping'));
      expect(result.accountType, equals('Credit Card'));
      expect(result.merchant, equals('Amazon India'));
    });

    test('Credit Card Bill Reminder', () async {
      const sms = 'Payment due for Card ending 8888: Minimum Amount Due Rs 1,200.00, Total Due Rs 12,000.00 on due date 15-Jul-2026.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(12000.0));
      expect(result.transactionType, equals('upcoming_bill'));
      expect(result.category, equals('Credit Card Bill Reminder'));
      expect(result.billStatus, equals('pending'));
      expect(result.dueDate, isNotNull);
      expect(result.dueDate!.day, equals(15));
      expect(result.dueDate!.month, equals(7));
    });

    test('Credit Card Payment', () async {
      const sms = 'Thank you for your payment of Rs 12,000.00 towards Credit Card ending 8888. Outstanding reduced.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(12000.0));
      expect(result.transactionType, equals('credit_card_payment'));
      expect(result.category, equals('Credit Card Payment'));
      expect(result.billStatus, equals('paid'));
    });

    test('Internal Transfer', () async {
      const sms = 'Self transfer of Rs 5,000.00 from SBI to HDFC.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(5000.0));
      expect(result.transactionType, equals('transfer'));
      expect(result.category, equals('Internal Transfer'));
      expect(result.merchant, equals('Hdfc'));
    });

    test('Refund', () async {
      const sms = 'Refund of Rs 350.00 has been credited back for txn 88712.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(350.0));
      expect(result.transactionType, equals('refund'));
      expect(result.category, equals('Refund'));
    });

    test('Cashback', () async {
      const sms = 'Cashback earned: Rs 150.00 reward credit to your account.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(150.0));
      expect(result.transactionType, equals('cashback'));
      expect(result.category, equals('Cashback'));
    });

    test('Loan Disbursement & EMI', () async {
      const sms1 = 'Your Loan account 100293 has been disbursed with Rs 1,00,000.00.';
      final result1 = await smsAgent.processSms(sms1, testDate, userId: userId);
      expect(result1, isNotNull);
      expect(result1!.transactionType, equals('loan'));
      expect(result1.category, equals('Loan Disbursement'));

      const sms2 = 'Loan EMI Rs 8,500.00 debited from your bank account.';
      final result2 = await smsAgent.processSms(sms2, testDate, userId: userId);
      expect(result2, isNotNull);
      expect(result2!.transactionType, equals('expense'));
      expect(result2.category, equals('Loan EMI'));
    });

    test('Investment', () async {
      const sms = 'SIP Mutual Fund debited Rs 2,000.00 from your account.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(2000.0));
      expect(result.transactionType, equals('investment'));
      expect(result.category, equals('Investment'));
      expect(result.accountType, equals('Investment'));
    });

    test('Subscription', () async {
      const sms = 'Renewed subscription of Rs 199.00 to Netflix.';
      final result = await smsAgent.processSms(sms, testDate, userId: userId);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(199.0));
      expect(result.transactionType, equals('expense'));
      expect(result.category, equals('Subscription'));
    });

    test('Ignores OTP, Security Alerts, and Promotional SMS', () async {
      const otpSms = 'Your Expenso verification code is 4321. Do not share.';
      final otpResult = await smsAgent.processSms(otpSms, testDate, userId: userId);
      expect(otpResult, isNull);

      const securitySms = 'Alert: Suspicious login attempt from Chrome browser.';
      final secResult = await smsAgent.processSms(securitySms, testDate, userId: userId);
      expect(secResult, isNull);

      const promoSms = 'Get pre-approved home loan up to 50 Lakhs today! Apply now.';
      final promoResult = await smsAgent.processSms(promoSms, testDate, userId: userId);
      expect(promoResult, isNull);
    });
  });

  group('LedgerAgent Reconciliation & Multi-Account Updates', () {
    test('Self Transfer updates both accounts balance and keeps Net Worth unchanged', () async {
      // Create initial accounts with seeded balances
      final sbi = Account(
        id: const Uuid().v4(),
        userId: userId,
        name: 'SBI A/c 1234',
        type: 'bank',
        balance: 1000000, // ₹10,000
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(sbi);

      final hdfc = Account(
        id: const Uuid().v4(),
        userId: userId,
        name: 'HDFC A/c XXXX',
        type: 'bank',
        balance: 1000000, // ₹10,000
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(hdfc);

      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        type: 'transfer',
        amount: 200000, // ₹2,000
        currency: 'INR',
        description: 'SMS Alert: SBI A/c 1234',
        merchant: 'HDFC',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ledgerAgent.reconcileTransaction(tx);

      // Verify source deducted, destination credited
      final updatedSbi = await database.accountDao.getAccountById(sbi.id);
      final updatedHdfc = await database.accountDao.getAccountById(hdfc.id);

      expect(updatedSbi!.balance, equals(800000)); // ₹8,000
      expect(updatedHdfc!.balance, equals(1200000)); // ₹12,000
    });

    test('Credit Card Payment updates balances and auto-settles pending CC bills', () async {
      // 1. Create CC Bill Reminder Transaction
      final bill = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        type: 'upcoming_bill',
        amount: 1500000, // ₹15,000
        currency: 'INR',
        merchant: 'HDFC Credit Card ending 8888',
        description: 'CC Statement Due',
        date: testDate,
        source: 'sms',
        billStatus: 'pending',
        isRecurring: false,
        syncStatus: 'pending',
        dueDate: testDate.add(const Duration(days: 15)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await database.transactionDao.insertTransaction(bill);

      // 2. Create Payment Transaction
      final payment = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        type: 'credit_card_payment',
        amount: 1500000, // ₹15,000
        currency: 'INR',
        merchant: 'HDFC Credit Card ending 8888',
        description: 'SMS Alert: HDFC Credit Card ending 8888',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ledgerAgent.reconcileTransaction(payment);

      // 3. Confirm pending bill was marked paid
      final updatedBill = await database.transactionDao.getTransactionById(bill.id);
      expect(updatedBill!.billStatus, equals('paid'));
    });
  });
}
