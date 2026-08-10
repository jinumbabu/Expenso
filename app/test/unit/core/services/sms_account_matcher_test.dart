import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/sms_account_matcher.dart';

void main() {
  group('SmsAccountMatcher Unit Tests', () {
    final List<Account> mockAccounts = [
      Account(
        id: 'acc-1',
        userId: 'user-1',
        name: 'HDFC 3726',
        type: 'savings',
        balance: 500000,
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bankName: 'HDFC Bank',
        last4Digits: '3726',
        currency: 'INR',
        isActive: true,
        autoPay: false,
        isEstimated: false,
      ),
      Account(
        id: 'acc-2',
        userId: 'user-1',
        name: 'SBI 8589',
        type: 'savings',
        balance: 100000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bankName: 'State Bank of India',
        last4Digits: '8589',
        currency: 'INR',
        isActive: true,
        autoPay: false,
        isEstimated: false,
      ),
      Account(
        id: 'acc-3',
        userId: 'user-1',
        name: 'Cash Wallet',
        type: 'cash',
        balance: 20000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bankName: 'Cash',
        currency: 'INR',
        isActive: true,
        autoPay: false,
        isEstimated: false,
      ),
    ];

    test('HDFC UPI SMS matches existing HDFC 3726 account and UPI payment method', () {
      const smsText = 'HDFC UPI ****3726 debited for Rs 11,735.00 to HDFC Bank Digital Credit.';
      final result = SmsAccountMatcher.matchAccount(
        smsText: smsText,
        existingAccounts: mockAccounts,
        cardOrAccount: '3726',
      );

      expect(result.matchedAccount, isNotNull);
      expect(result.matchedAccount!.id, equals('acc-1'));
      expect(result.matchedAccount!.name, equals('HDFC 3726'));
      expect(result.accountType, equals('savings'));
      expect(result.paymentMethod, equals('UPI'));
      expect(result.matchedAccount!.type, isNot(equals('cash')));
    });

    test('SMS with bank name and last4 digits matches correct account', () {
      const smsText = 'Rs 5000.00 debited from A/c ending 8589 at SBI.';
      final result = SmsAccountMatcher.matchAccount(
        smsText: smsText,
        existingAccounts: mockAccounts,
        cardOrAccount: '8589',
      );

      expect(result.matchedAccount, isNotNull);
      expect(result.matchedAccount!.id, equals('acc-2'));
      expect(result.matchedAccount!.name, equals('SBI 8589'));
    });

    test('Unmatched bank SMS returns isNewAccountNeeded true so dedicated account is created', () {
      const smsText = 'Canara Bank A/c xx9999 debited for Rs 1200.00 via GPay.';
      final result = SmsAccountMatcher.matchAccount(
        smsText: smsText,
        existingAccounts: mockAccounts,
        cardOrAccount: '9999',
      );

      expect(result.matchedAccount, isNull);
      expect(result.isNewAccountNeeded, isTrue);
      expect(result.displayTitle, equals('Canara 9999'));
      expect(result.paymentMethod, equals('UPI'));
    });

    test('ATM cash withdrawal correctly matches cash account', () {
      const smsText = 'Your A/c ending in 3726 has been debited for Rs 2000.00 towards ATM withdrawal.';
      final result = SmsAccountMatcher.matchAccount(
        smsText: smsText,
        existingAccounts: mockAccounts,
        cardOrAccount: '3726',
      );

      expect(result.matchedAccount, isNotNull);
      expect(result.matchedAccount!.type, equals('cash'));
      expect(result.paymentMethod, equals('Cash'));
    });

    test('Extracts canonical Indian Bank names correctly', () {
      expect(SmsAccountMatcher.extractBankName('Transaction on Axis Bank card'), equals('Axis Bank'));
      expect(SmsAccountMatcher.extractBankName('Federal Bank alert A/c 1234'), equals('Federal Bank'));
      expect(SmsAccountMatcher.extractBankName('PNB debited Rs 500'), equals('Punjab National Bank'));
      expect(SmsAccountMatcher.extractBankName('BOB A/c 5544 credited'), equals('Bank of Baroda'));
      expect(SmsAccountMatcher.extractBankName('IDFC FIRST Bank alert'), equals('IDFC FIRST Bank'));
      expect(SmsAccountMatcher.extractBankName('Kotak Mahindra Bank alert'), equals('Kotak Mahindra Bank'));
    });
  });
}
