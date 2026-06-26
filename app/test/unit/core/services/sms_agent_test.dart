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
      expect(result.confidence, equals(1.0));
      
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
      expect(result.confidence, equals(0.75));
    });

    test('Ignores non-financial SMS', () async {
      const body = 'Hi there, your OTP is 987654. Do not share.';
      final result = await smsAgent.processSms(body, testDate);
      expect(result, isNull);
    });
  });
}
