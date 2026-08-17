import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/quick_add_notepad_service.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';

class FakeDatabase extends Fake implements AppDatabase {}

void main() {
  group('Quick Add Notepad Transfer and Validation Tests', () {
    late ProviderContainer container;
    late QuickAddNotepadService service;
    late List<Account> mockAccounts;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(FakeDatabase()),
        ],
      );
      service = container.read(quickAddNotepadServiceProvider);

      final now = DateTime.now();
      mockAccounts = [
        Account(
          id: 'cash-wallet-123',
          userId: 'user-123',
          name: 'Cash',
          type: 'cash',
          balance: 1000000, // ₹10,000 in cents
          isDefault: true,
          createdAt: now,
          updatedAt: now,
          isEstimated: false,
        ),
        Account(
          id: 'sbi-savings-123',
          userId: 'user-123',
          name: 'SBI',
          type: 'savings',
          balance: 300000, // ₹3,000 in cents
          isDefault: false,
          createdAt: now,
          updatedAt: now,
          isEstimated: false,
        ),
        Account(
          id: 'hdfc-savings-123',
          userId: 'user-123',
          name: 'HDFC',
          type: 'savings',
          balance: 800000, // ₹8,000 in cents
          isDefault: false,
          createdAt: now,
          updatedAt: now,
          isEstimated: false,
        ),
        Account(
          id: 'sbi-cc-123',
          userId: 'user-123',
          name: 'SBI Credit Card',
          type: 'credit_card',
          balance: 0,
          isDefault: false,
          createdAt: now,
          updatedAt: now,
          creditLimit: 5000000, // ₹50,000 in cents
          outstandingBalance: 1000000, // ₹10,000 outstanding (available: ₹40,000)
          isEstimated: false,
        ),
      ];
    });

    tearDown(() {
      container.dispose();
    });

    test('Parses valid transfer from HDFC to SBI: 4 July 5000 transfer HDFC to SBI', () {
      final result = service.parseLine('4 July 5000 transfer HDFC to SBI', mockAccounts);
      expect(result.error, isNull);
      expect(result.amount, equals(5000.0));
      expect(result.type, equals('transfer'));
      expect(result.accountName, equals('HDFC'));
      expect(result.merchant, equals('SBI'));
      expect(result.category, equals('Transfer'));
    });

    test('Parses valid transfer with different order: 4 July transfer 2000 SBI to Cash', () {
      final result = service.parseLine('4 July transfer 2000 SBI to Cash', mockAccounts);
      expect(result.error, isNull);
      expect(result.amount, equals(2000.0));
      expect(result.type, equals('transfer'));
      expect(result.accountName, equals('SBI'));
      expect(result.merchant, equals('Cash'));
      expect(result.category, equals('Transfer'));
    });

    test('Rejects transfer with insufficient balance: 4 July transfer 5000 SBI to Cash', () {
      // SBI balance is ₹3,000, trying to transfer ₹5,000
      final result = service.parseLine('4 July transfer 5000 SBI to Cash', mockAccounts);
      expect(result.error, isNotNull);
      expect(result.error, contains('Insufficient Balance'));
      expect(result.error, contains('SBI available balance:\n₹3,000'));
      expect(result.error, contains('Transfer amount:\n₹5,000'));
      expect(result.error, contains('Required:\n₹2,000 more'));
    });

    test('Ensures credit card purchases are NOT classified as transfers: 7 Aug Fuel 1000 SBI Credit Card', () {
      final result = service.parseLine('7 Aug Fuel 1000 SBI Credit Card', mockAccounts);
      expect(result.type, equals('expense'));
      expect(result.accountName, equals('SBI Credit Card'));
      expect(result.merchant, equals('Fuel'));
    });
  });
}
