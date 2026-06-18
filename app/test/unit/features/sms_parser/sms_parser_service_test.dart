import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/sms_parser/domain/services/sms_parser_service.dart';

void main() {
  group('SmsParserService Tests', () {
    final testDate = DateTime(2026, 6, 17);

    test('Parses HDFC Bank Debit Alert via UPI', () {
      const sms = 'Dear Customer, Rs 150.00 debited from A/c XX1234 on 17-Jun-26 by UPI Ref 1234567. Info: TEA STALL.';
      final result = SmsParserService.parseSms(sms, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(150.0));
      expect(result.type, equals('expense'));
      expect(result.cardOrAccount, equals('1234'));
      expect(result.merchant, equals('Tea Stall'));
    });

    test('Parses ICICI Credit Card Spend Alert', () {
      const sms = 'INR 2,500.00 spent on Credit Card ending 5678 at AMAZON INDIA on 17-Jun-26.';
      final result = SmsParserService.parseSms(sms, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(2500.0));
      expect(result.type, equals('expense'));
      expect(result.cardOrAccount, equals('5678'));
      expect(result.merchant, equals('Amazon India'));
    });

    test('Parses SBI Account Credit Alert', () {
      const sms = 'Dear Customer, Rs 50,000.00 credited to A/c XX8901 on 17-Jun-26.';
      final result = SmsParserService.parseSms(sms, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(50000.0));
      expect(result.type, equals('income'));
      expect(result.cardOrAccount, equals('8901'));
      expect(result.merchant, equals('Income Deposit'));
    });

    test('Parses ATM Withdrawal Alert', () {
      const sms = 'Your A/c ending in 4321 has been debited for Rs 1000.00 on 17-Jun-26 towards ATM withdrawal.';
      final result = SmsParserService.parseSms(sms, testDate);

      expect(result, isNotNull);
      expect(result!.amount, equals(1000.0));
      expect(result.type, equals('expense'));
      expect(result.cardOrAccount, equals('4321'));
      expect(result.merchant, equals('ATM Withdrawal'));
    });

    test('Ignores non-financial transaction messages', () {
      const sms = 'Your OTP for logging into bank app is 123456. Valid for 5 minutes.';
      final result = SmsParserService.parseSms(sms, testDate);

      expect(result, isNull);
    });

    test('Cleans up merchant name formatting correctly', () {
      const sms1 = 'Spent Rs. 450 at STARBUCKS-COFFEE UPI Ref 890123.';
      final result1 = SmsParserService.parseSms(sms1, testDate);
      expect(result1!.merchant, equals('Starbucks-coffee'));

      const sms2 = 'Paid to worldwidecoin@okaxis Rs. 300 for food.';
      final result2 = SmsParserService.parseSms(sms2, testDate);
      expect(result2!.merchant, equals('Worldwidecoin@okaxis'));
    });
  });
}
