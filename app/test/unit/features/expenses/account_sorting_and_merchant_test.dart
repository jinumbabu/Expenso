import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/features/accounts/presentation/providers/accounts_provider.dart';

// Fake StateNotifier for Accounts
class FakeAccountsNotifier extends StateNotifier<AsyncValue<List<Account>>> {
  FakeAccountsNotifier(List<Account> accounts) : super(AsyncValue.data(accounts));
}

// Fake StateNotifier for Transactions
class FakeExpenseListNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  FakeExpenseListNotifier(List<Transaction> txs) : super(AsyncValue.data(txs));
}

void main() {
  group('getAccountTypePriority tests', () {
    test('Cash has highest priority 1', () {
      expect(getAccountTypePriority('cash'), equals(1));
      expect(getAccountTypePriority('CASH'), equals(1));
    });

    test('Savings/Current/Salary/Debit Card/Bank has priority 2', () {
      expect(getAccountTypePriority('savings'), equals(2));
      expect(getAccountTypePriority('current'), equals(2));
      expect(getAccountTypePriority('salary'), equals(2));
      expect(getAccountTypePriority('debit_card'), equals(2));
      expect(getAccountTypePriority('bank'), equals(2));
    });

    test('Credit Card has priority 3', () {
      expect(getAccountTypePriority('credit_card'), equals(3));
    });

    test('Wallets have priority 4', () {
      expect(getAccountTypePriority('wallet'), equals(4));
      expect(getAccountTypePriority('upi_wallet'), equals(4));
      expect(getAccountTypePriority('digital_wallet'), equals(4));
    });

    test('Other types have priority 5', () {
      expect(getAccountTypePriority('loan'), equals(5));
      expect(getAccountTypePriority('investment'), equals(5));
      expect(getAccountTypePriority('fixed_deposit'), equals(5));
    });
  });

  group('MerchantResolver tests', () {
    test('Preserve entered merchant when not empty', () {
      final result = MerchantResolver.resolve(
        enteredMerchant: 'Swiggy',
        subcategoryName: 'Food Delivery',
        categoryName: 'Food',
      );
      expect(result, equals('Swiggy'));
    });

    test('Fall back to subcategory name when entered merchant is empty/whitespace', () {
      final result1 = MerchantResolver.resolve(
        enteredMerchant: '',
        subcategoryName: 'Food Delivery',
        categoryName: 'Food',
      );
      expect(result1, equals('Food Delivery'));

      final result2 = MerchantResolver.resolve(
        enteredMerchant: '   ',
        subcategoryName: 'Food Delivery',
        categoryName: 'Food',
      );
      expect(result2, equals('Food Delivery'));
    });

    test('Fall back to category name when entered merchant and subcategory are empty/null', () {
      final result1 = MerchantResolver.resolve(
        enteredMerchant: '',
        subcategoryName: '',
        categoryName: 'House Rent',
      );
      expect(result1, equals('House Rent'));

      final result2 = MerchantResolver.resolve(
        enteredMerchant: null,
        subcategoryName: null,
        categoryName: 'House Rent',
      );
      expect(result2, equals('House Rent'));
    });

    test('Fall back to Other when all inputs are empty/null', () {
      final result = MerchantResolver.resolve(
        enteredMerchant: '   ',
        subcategoryName: '',
        categoryName: null,
      );
      expect(result, equals('Other'));
    });
  });

  group('sortedAccountsProvider tests', () {
    final List<Account> mockAccounts = [
      Account(
        id: 'cash-acc',
        userId: 'user-1',
        name: 'Cash Wallet',
        type: 'cash',
        balance: 1000,
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 'sbi-acc',
        userId: 'user-1',
        name: 'SBI Savings',
        type: 'savings',
        balance: 500,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 'hdfc-acc',
        userId: 'user-1',
        name: 'HDFC Savings',
        type: 'savings',
        balance: 1500,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 'hdfc-cc',
        userId: 'user-1',
        name: 'HDFC Credit Card',
        type: 'credit_card',
        balance: -200,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 'paytm-wallet',
        userId: 'user-1',
        name: 'Paytm Wallet',
        type: 'wallet',
        balance: 30,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('Default ordering when no usage history exists', () {
      final container = ProviderContainer(
        overrides: [
          accountsProvider.overrideWith((ref) => FakeAccountsNotifier(mockAccounts)),
          expenseListNotifierProvider.overrideWith((ref) => FakeExpenseListNotifier([])),
        ],
      );

      final state = container.read(sortedAccountsProvider);
      expect(state, isA<AsyncData>());
      
      final sortedList = state.value!;
      expect(sortedList[0].id, equals('cash-acc')); // Cash (Priority 1)
      expect(sortedList[1].id, equals('sbi-acc'));  // SBI (Priority 2, index 1)
      expect(sortedList[2].id, equals('hdfc-acc')); // HDFC (Priority 2, index 2)
      expect(sortedList[3].id, equals('hdfc-cc'));  // Credit Card (Priority 3)
      expect(sortedList[4].id, equals('paytm-wallet')); // Wallet (Priority 4)
    });

    test('Ordering within group based on selection frequency (HDFC Savings > SBI Savings)', () {
      final txs = [
        // HDFC selected 3 times
        Transaction(id: 'tx-1', userId: 'user-1', accountId: 'hdfc-acc', type: 'expense', amount: 100, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Transaction(id: 'tx-2', userId: 'user-1', accountId: 'hdfc-acc', type: 'expense', amount: 200, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Transaction(id: 'tx-3', userId: 'user-1', accountId: 'hdfc-acc', type: 'expense', amount: 300, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        // SBI selected 1 time
        Transaction(id: 'tx-4', userId: 'user-1', accountId: 'sbi-acc', type: 'expense', amount: 400, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final container = ProviderContainer(
        overrides: [
          accountsProvider.overrideWith((ref) => FakeAccountsNotifier(mockAccounts)),
          expenseListNotifierProvider.overrideWith((ref) => FakeExpenseListNotifier(txs)),
        ],
      );

      final state = container.read(sortedAccountsProvider);
      final sortedList = state.value!;

      expect(sortedList[0].id, equals('cash-acc')); // Cash is still first due to type priority
      expect(sortedList[1].id, equals('hdfc-acc')); // HDFC has 3 uses, so it goes above SBI which has 1 use
      expect(sortedList[2].id, equals('sbi-acc'));  // SBI is next
      expect(sortedList[3].id, equals('hdfc-cc'));  // Credit card is priority 3
      expect(sortedList[4].id, equals('paytm-wallet')); // Wallet is priority 4
    });

    test('Ordering changes when SBI Savings usage exceeds HDFC Savings', () {
      final txs = [
        // HDFC selected 2 times
        Transaction(id: 'tx-1', userId: 'user-1', accountId: 'hdfc-acc', type: 'expense', amount: 100, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Transaction(id: 'tx-2', userId: 'user-1', accountId: 'hdfc-acc', type: 'expense', amount: 200, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        // SBI selected 5 times
        Transaction(id: 'tx-3', userId: 'user-1', accountId: 'sbi-acc', type: 'expense', amount: 10, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Transaction(id: 'tx-4', userId: 'user-1', accountId: 'sbi-acc', type: 'expense', amount: 20, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Transaction(id: 'tx-5', userId: 'user-1', accountId: 'sbi-acc', type: 'expense', amount: 30, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Transaction(id: 'tx-6', userId: 'user-1', accountId: 'sbi-acc', type: 'expense', amount: 40, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Transaction(id: 'tx-7', userId: 'user-1', accountId: 'sbi-acc', type: 'expense', amount: 50, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final container = ProviderContainer(
        overrides: [
          accountsProvider.overrideWith((ref) => FakeAccountsNotifier(mockAccounts)),
          expenseListNotifierProvider.overrideWith((ref) => FakeExpenseListNotifier(txs)),
        ],
      );

      final state = container.read(sortedAccountsProvider);
      final sortedList = state.value!;

      expect(sortedList[0].id, equals('cash-acc')); // Cash is still first due to type priority
      expect(sortedList[1].id, equals('sbi-acc'));  // SBI has 5 uses, so it goes above HDFC which has 2 uses
      expect(sortedList[2].id, equals('hdfc-acc')); // HDFC is next
    });

    test('Credit Card / Wallet usage does not violate group boundaries', () {
      final txs = [
        // Credit card selected 50 times
        for (int i = 0; i < 50; i++)
          Transaction(id: 'tx-cc-$i', userId: 'user-1', accountId: 'hdfc-cc', type: 'expense', amount: 100, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        // Wallet selected 100 times
        for (int i = 0; i < 100; i++)
          Transaction(id: 'tx-w-$i', userId: 'user-1', accountId: 'paytm-wallet', type: 'expense', amount: 50, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final container = ProviderContainer(
        overrides: [
          accountsProvider.overrideWith((ref) => FakeAccountsNotifier(mockAccounts)),
          expenseListNotifierProvider.overrideWith((ref) => FakeExpenseListNotifier(txs)),
        ],
      );

      final state = container.read(sortedAccountsProvider);
      final sortedList = state.value!;

      expect(sortedList[0].id, equals('cash-acc'));     // Cash is still first (Priority 1)
      expect(sortedList[1].id, equals('sbi-acc'));      // SBI Savings (Priority 2)
      expect(sortedList[2].id, equals('hdfc-acc'));     // HDFC Savings (Priority 2)
      expect(sortedList[3].id, equals('hdfc-cc'));      // Credit Card is still third (Priority 3) despite 50 selections
      expect(sortedList[4].id, equals('paytm-wallet')); // Wallet is still last (Priority 4) despite 100 selections
    });

    test('Tied selection counts preserve original database order (stable sorting)', () {
      final txs = [
        // Both SBI and HDFC have 2 selections
        Transaction(id: 'tx-1', userId: 'user-1', accountId: 'hdfc-acc', type: 'expense', amount: 100, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Transaction(id: 'tx-2', userId: 'user-1', accountId: 'hdfc-acc', type: 'expense', amount: 200, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Transaction(id: 'tx-3', userId: 'user-1', accountId: 'sbi-acc', type: 'expense', amount: 10, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Transaction(id: 'tx-4', userId: 'user-1', accountId: 'sbi-acc', type: 'expense', amount: 20, date: DateTime.now(), source: 'manual', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final container = ProviderContainer(
        overrides: [
          // In the database list, sbi-acc comes BEFORE hdfc-acc
          accountsProvider.overrideWith((ref) => FakeAccountsNotifier(mockAccounts)),
          expenseListNotifierProvider.overrideWith((ref) => FakeExpenseListNotifier(txs)),
        ],
      );

      final state = container.read(sortedAccountsProvider);
      final sortedList = state.value!;

      expect(sortedList[1].id, equals('sbi-acc'));  // SBI comes first because it was before HDFC in database order
      expect(sortedList[2].id, equals('hdfc-acc')); // HDFC comes next
    });
  });
}
