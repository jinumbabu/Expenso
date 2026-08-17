import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:app/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/accounts/presentation/screens/account_detail_screen.dart';

class MockAccountsNotifier extends AccountsNotifier {
  bool acceptImportedBalanceCalled = false;
  bool dismissDiscrepancyCalled = false;

  MockAccountsNotifier(List<Account> initialAccounts)
      : super(
          db: AppDatabase.connect(NativeDatabase.memory()),
          userId: null,
        ) {
    state = AsyncValue.data(initialAccounts);
  }

  @override
  Future<void> loadAccounts() async {}

  @override
  Future<void> acceptImportedBalance(String accountId) async {
    acceptImportedBalanceCalled = true;
    state = AsyncValue.data(
      state.value!.map((a) => a.id == accountId ? a.copyWith(hasMismatch: const Value(false)) : a).toList(),
    );
  }

  @override
  Future<void> dismissDiscrepancy(String accountId) async {
    dismissDiscrepancyCalled = true;
    state = AsyncValue.data(
      state.value!.map((a) => a.id == accountId ? a.copyWith(hasMismatch: const Value(false), balanceDiscrepancyDismissed: const Value(true)) : a).toList(),
    );
  }
}

void main() {
  group('AccountDetailScreen Discrepancy Redesign Widget Tests', () {
    late Account mockAccountWithMismatch;
    late Account mockAccountNoMismatch;
    late List<Transaction> mockTxs;
    final now = DateTime.now();

    setUp(() {
      mockAccountWithMismatch = Account(
        id: 'acc_hdfc',
        userId: 'user1',
        name: 'HDFC Savings',
        type: 'savings',
        balance: 4000, // ₹40.00
        isDefault: true,
        createdAt: now,
        updatedAt: now,
        currency: 'INR',
        colorTheme: '0xFF0066FF',
        icon: 'account_balance',
        isActive: true,
        isEstimated: false,
        hasMismatch: true,
        mismatchExpected: 4000,   // ₹40.00
        mismatchImported: -2000,  // -₹20.00
        balanceDiscrepancyDismissed: false,
      );

      mockAccountNoMismatch = Account(
        id: 'acc_sbi',
        userId: 'user1',
        name: 'SBI Savings',
        type: 'savings',
        balance: 100000, // ₹1,000.00
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        currency: 'INR',
        colorTheme: '0xFF00E5FF',
        icon: 'account_balance',
        isActive: true,
        isEstimated: false,
        hasMismatch: false,
        balanceDiscrepancyDismissed: false,
      );

      mockTxs = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          accountId: 'acc_hdfc',
          type: 'expense',
          amount: 6000, // ₹60.00
          currency: 'INR',
          merchant: 'Zara',
          date: now,
          source: 'sms',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    testWidgets('Renders discrepancy card with only Accept SMS Balance and Cancel buttons', (tester) async {
      final mockNotifier = MockAccountsNotifier([mockAccountWithMismatch]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) => mockNotifier),
            recalculatedAccountsProvider.overrideWith((ref) {
              final accounts = ref.watch(accountsProvider).value ?? [];
              return AsyncValue.data(accounts);
            }),
            accountTransactionsProvider('acc_hdfc').overrideWithValue(AsyncValue.data(mockTxs)),
          ],
          child: const MaterialApp(
            home: AccountDetailScreen(accountId: 'acc_hdfc'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify warning title is rendered
      expect(find.text('Balance Discrepancy Detected'), findsOneWidget);

      // 2. Verify calculations are correctly rendered (in monospace text styles)
      expect(find.text('Expected (Calculated):'), findsOneWidget);
      expect(find.text('Imported (SMS):'), findsOneWidget);
      expect(find.text('Difference:'), findsOneWidget);

      // 3. Verify Accept SMS Balance and Cancel are present
      expect(find.text('Accept SMS Balance'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // 4. Verify old buttons are completely absent
      expect(find.text('Keep Verified'), findsNothing);
      expect(find.text('Create Adjustment'), findsNothing);
    });

    testWidgets('Tapping Accept SMS Balance triggers action and shows SnackBar', (tester) async {
      final mockNotifier = MockAccountsNotifier([mockAccountWithMismatch]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) => mockNotifier),
            recalculatedAccountsProvider.overrideWith((ref) {
              final accounts = ref.watch(accountsProvider).value ?? [];
              return AsyncValue.data(accounts);
            }),
            accountTransactionsProvider('acc_hdfc').overrideWithValue(AsyncValue.data(mockTxs)),
          ],
          child: const MaterialApp(
            home: AccountDetailScreen(accountId: 'acc_hdfc'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Accept SMS Balance
      await tester.tap(find.text('Accept SMS Balance'));
      await tester.pump(); // Start SnackBar animation
      await tester.pumpAndSettle();

      expect(mockNotifier.acceptImportedBalanceCalled, isTrue);
      expect(find.text('SMS balance accepted'), findsOneWidget);
      
      // Clean up SnackBar timers
      ScaffoldMessenger.of(tester.element(find.byType(AccountDetailScreen))).clearSnackBars();
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping Cancel triggers dismissal, shows SnackBar, and hides card', (tester) async {
      final mockNotifier = MockAccountsNotifier([mockAccountWithMismatch]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) => mockNotifier),
            recalculatedAccountsProvider.overrideWith((ref) {
              final accounts = ref.watch(accountsProvider).value ?? [];
              return AsyncValue.data(accounts);
            }),
            accountTransactionsProvider('acc_hdfc').overrideWithValue(AsyncValue.data(mockTxs)),
          ],
          child: const MaterialApp(
            home: AccountDetailScreen(accountId: 'acc_hdfc'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify card is visible initially
      expect(find.text('Balance Discrepancy Detected'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pump(); // Start SnackBar animation
      await tester.pumpAndSettle();

      expect(mockNotifier.dismissDiscrepancyCalled, isTrue);
      expect(find.text('Balance discrepancy dismissed'), findsOneWidget);

      // Clean up SnackBar timers
      ScaffoldMessenger.of(tester.element(find.byType(AccountDetailScreen))).clearSnackBars();
      await tester.pumpAndSettle();

      // Verify card disappears from UI
      expect(find.text('Balance Discrepancy Detected'), findsNothing);
    });

    testWidgets('Discrepancy card does not render when hasMismatch is false', (tester) async {
      final mockNotifier = MockAccountsNotifier([mockAccountNoMismatch]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) => mockNotifier),
            recalculatedAccountsProvider.overrideWith((ref) {
              final accounts = ref.watch(accountsProvider).value ?? [];
              return AsyncValue.data(accounts);
            }),
            accountTransactionsProvider('acc_sbi').overrideWithValue(AsyncValue.data([])),
          ],
          child: const MaterialApp(
            home: AccountDetailScreen(accountId: 'acc_sbi'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Balance Discrepancy Detected'), findsNothing);
    });
  });
}
