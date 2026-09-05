import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/sms_agent.dart';

void main() {
  late AppDatabase database;
  late SmsAgent smsAgent;

  setUp(() {
    database = AppDatabase.connect(NativeDatabase.memory());
    smsAgent = SmsAgent(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('SmsAgent Template Extraction Tests', () {
    final testDate = DateTime(2026, 6, 21);

    test('Parses SBI Debit SMS correctly', () async {
      // Wait, SBI Debit Pattern 1 is: (?:debited|spent|withdrawn).*?rs\.?\s*([\d,]+\.?\d*).*?a/c\s*(?:xx|x|no)?(\d{4})
      // So 'debited Rs 1500.00 A/c XX1234' matches this!
      const matchingBody = 'SBI: Account has been debited for Rs 1500.00. A/c XX1234.';
      final result = await smsAgent.processSms(matchingBody, testDate);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(1500.0));
      expect(result.transactionType, equals('expense'));
      expect(result.account, contains('SBI'));
      expect(result.account, contains('1234'));
      expect(result.confidence, equals(0.85));
      
      // Verify AgentLog was written
      final logs = await database.agentLogDao.getLogs(10);
      expect(logs.isNotEmpty, isTrue);
      expect(logs.first.agentName, equals('SMS Transaction Agent'));
      expect(logs.first.actionType, equals('SMS_PARSED'));
    });

    test('Parses HDFC Credit SMS correctly', () async {
      const body = 'HDFC Bank: Rs 45,000.00 credited to A/c XX5678 on 21-Jun-26. Salary deposit.';
      final result = await smsAgent.processSms(body, testDate);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(45000.0));
      expect(result.transactionType, equals('income'));
      expect(result.account, contains('HDFC'));
      expect(result.account, contains('5678'));
    });

    test('Parses ICICI Credit Card expense correctly', () async {
      const body = 'ICICI Bank: INR 500.00 spent on card 9876.';
      final result = await smsAgent.processSms(body, testDate);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(500.0));
      expect(result.transactionType, equals('expense'));
      expect(result.account, contains('ICICI'));
      expect(result.account, contains('9876'));
    });

    test('Parses Axis Debit SMS correctly', () async {
      const body = 'Axis A/c xx4321 debited Rs. 2400.00 on 21-Jun-26.';
      final result = await smsAgent.processSms(body, testDate);
      
      expect(result, isNotNull);
      expect(result!.amount, equals(2400.0));
      expect(result.account, contains('Axis'));
      expect(result.account, contains('4321'));
    });

    test('Parses Federal Bank Debit SMS correctly', () async {
      const body = 'Federal Bank A/c xx7788 debited Rs 100.00.';
      final result = await smsAgent.processSms(body, testDate);
      expect(result, isNotNull);
      expect(result!.amount, equals(100.0));
      expect(result.account, contains('Federal Bank'));
    });

    test('Parses Kotak Debit SMS correctly', () async {
      const body = 'Kotak A/c xx3344 debited Rs 999.00.';
      final result = await smsAgent.processSms(body, testDate);
      expect(result, isNotNull);
      expect(result!.amount, equals(999.0));
    });

    test('Parses Generic SMS using fallbacks', () async {
      const body = 'ALERT: INR 350.00 paid for grocery ending A/c 2211.';
      final result = await smsAgent.processSms(body, testDate);
      expect(result, isNotNull);
      expect(result!.amount, equals(350.0));
      expect(result.confidence, equals(0.85));
    });

    test('Ignores non-financial SMS', () async {
      const body = 'Hi there, your OTP is 987654. Do not share.';
      final result = await smsAgent.processSms(body, testDate);
      expect(result, isNull);
    });

    test('Parses self-transfer when username matches', () async {
      const userId = 'user_123';
      await database.into(database.users).insert(
        User(
          id: userId,
          email: 'jinu@example.com',
          googleId: 'google_id_123',
          currency: 'INR',
          displayName: 'JINU M BABU',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      const body = 'Sent Rs.100.00 From HDFC Bank A/C *3726 To JINU M BABU On 17/08/26 Ref 622962983009';
      final result = await smsAgent.processSms(body, testDate, userId: userId);

      expect(result, isNotNull);
      expect(result!.amount, equals(100.0));
      expect(result.transactionType, equals('transfer'));
      expect(result.category, equals('Internal Transfer'));
      expect(result.referenceId, equals('622962983009'));
    });

    test('Parses self-transfer when bank-to-bank keywords are used', () async {
      const body = 'Transferred Rs.500 from HDFC to SBI A/c XX1122 Ref 72384910';
      final result = await smsAgent.processSms(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(500.0));
      expect(result.transactionType, equals('transfer'));
      expect(result.category, equals('Internal Transfer'));
    });

    test('Parses ICICI Card Expense (Peevi Enterpris) correctly', () async {
      const body = 'Dear Customer, your ICICI Bank Credit Card xx1122 has been spent Rs. 550.00 on Peevi Enterpris on 21-Jun-26. Avl Limit: INR 45,000.00.';
      final result = await smsAgent.processSms(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(550.0));
      expect(result.transactionType, equals('expense'));
      expect(result.account, contains('ICICI'));
      expect(result.account, contains('1122'));
      expect(result.merchant, equals('Peevi Enterpris'));
    });

    test('Parses ICICI Card Expense (Kerala State Be) correctly', () async {
      const body = 'Dear Customer, your ICICI Bank Credit Card xx9999 has been spent Rs. 1,200.00 on Kerala State Be on 21-Jun-26. Avl Limit: INR 12,000.00.';
      final result = await smsAgent.processSms(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(1200.0));
      expect(result.transactionType, equals('expense'));
      expect(result.account, contains('ICICI'));
      expect(result.account, contains('9999'));
      expect(result.merchant, equals('Kerala State Be'));
    });

    test('Parses HDFC UPI Expense (Jms Karummbu Paal) correctly', () async {
      const body = 'Paid Rs 40.00 from HDFC Bank A/c XX3726 To Jms Karummbu Paal on 21-Jun-26. UPI Ref: 622962983010.';
      final result = await smsAgent.processSms(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(40.0));
      expect(result.transactionType, equals('expense'));
      expect(result.merchant, equals('Jms Karummbu Paal'));
      expect(result.referenceId, equals('622962983010'));
    });

    test('Parses SBI Income (Jinu M Babu) correctly', () async {
      const body = 'SBI: Account XX1234 credited Rs 5,000.00 on 21-Jun-26 by transfer from Jinu M Babu. UPI Ref: 123456789012.';
      final result = await smsAgent.processSms(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(5000.0));
      expect(result.transactionType, equals('income'));
      expect(result.merchant, equals('Jinu M Babu'));
      expect(result.referenceId, equals('123456789012'));
    });

    test('Parses SBI Income with different reference and card details (Jinu M Babu) correctly', () async {
      const body = 'SBI: Account XX5678 credited Rs 12,500.00 on 21-Jun-26 by transfer from Jinu M Babu. UPI Ref: 987654321098.';
      final result = await smsAgent.processSms(body, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(12500.0));
      expect(result.transactionType, equals('income'));
      expect(result.merchant, equals('Jinu M Babu'));
      expect(result.referenceId, equals('987654321098'));
    });
  });
}
