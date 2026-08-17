import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:app/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/accounts/presentation/screens/account_ledger_credit_card_detail_screen.dart';

class FakeAppDatabase extends Fake implements AppDatabase {}

class MockAccountsNotifier extends AccountsNotifier {
  bool adjustBalanceManuallyCalled = false;

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
  Future<void> adjustBalanceManually(String accountId, int amountInCents, bool createEntry, String userId) async {
    adjustBalanceManuallyCalled = true;
  }
}

void main() {
  group('AccountLedgerCreditCardDetailScreen Widget Tests', () {
    late Account mockCcAccount;
    late List<Transaction> mockTxs;
    final now = DateTime.now();

    setUp(() {
      mockCcAccount = Account(
        id: 'acc_cc1',
        userId: 'user1',
        name: 'HDFC Credit Card',
        type: 'credit_card',
        balance: -452034, // -₹4,520.34
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        currency: 'INR',
        colorTheme: '0xFFFF3B30',
        icon: 'credit_card',
        isActive: true,
        isEstimated: false,
        outstandingBalance: 452034, // ₹4,520.34 outstanding
        creditLimit: 10000000,       // ₹100,000.00
        availableCredit: 9547966,   // ₹95,479.66
        statementDate: 15,
        paymentDueDate: 7,
        minAmountDue: 0,
        totalAmountDue: 0,
        hasMismatch: false,
        balanceDiscrepancyDismissed: false,
      );

      mockTxs = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          accountId: 'acc_cc1',
          type: 'expense',
          amount: 452034, // ₹4,520.34
          currency: 'INR',
          merchant: 'Sarath',
          description: 'Weekly purchase',
          date: now,
          source: 'sms',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 'tx2',
          userId: 'user1',
          accountId: 'acc_cc1',
          type: 'credit_card_payment_credit',
          amount: 100000, // ₹1,000.00
          currency: 'INR',
          merchant: 'Payment received',
          description: 'Payment description',
          date: now,
          source: 'sms',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    testWidgets('Renders credit card ledger screen with correct header and outstanding balance card in red', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockNotifier = MockAccountsNotifier([mockCcAccount]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) => mockNotifier),
            recalculatedAccountsProvider.overrideWith((ref) {
              final accounts = ref.watch(accountsProvider).value ?? [];
              return AsyncValue.data(accounts);
            }),
            accountTransactionsProvider('acc_cc1').overrideWithValue(AsyncValue.data(mockTxs)),
          ],
          child: const MaterialApp(
            home: AccountLedgerCreditCardDetailScreen(accountId: 'acc_cc1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify screen title and subtitle
      expect(find.text('HDFC Credit Card'), findsOneWidget);
      expect(find.text('Credit Card'), findsOneWidget);

      // 2. Verify outstanding balance section
      expect(find.text('TOTAL OUTSTANDING'), findsOneWidget);
      
      // Verify outstanding balance value is formatted correctly and colored RED
      final balanceFinder = find.text('-₹4,520.34');
      expect(balanceFinder, findsOneWidget);
      final Text balanceText = tester.widget<Text>(balanceFinder);
      expect(balanceText.style?.color, equals(const Color(0xFFFF3B30)));

      // 3. Verify credit limits and utilization percent
      expect(find.text('Credit Utilization'), findsOneWidget);
      expect(find.text('4.5%'), findsOneWidget);
      expect(find.text('Credit Limit'), findsOneWidget);
      expect(find.text('₹100,000.00'), findsOneWidget);
      expect(find.text('Available Limit'), findsOneWidget);
      expect(find.text('₹95,479.66'), findsOneWidget);
    });

    testWidgets('Renders balance trend line and displays empty trend state if data is insufficient', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockNotifier = MockAccountsNotifier([mockCcAccount]);

      // Sub-test A: Insufficient data (< 2 transactions)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) => mockNotifier),
            recalculatedAccountsProvider.overrideWith((ref) {
              final accounts = ref.watch(accountsProvider).value ?? [];
              return AsyncValue.data(accounts);
            }),
            accountTransactionsProvider('acc_cc1').overrideWithValue(AsyncValue.data([])),
          ],
          child: const MaterialApp(
            home: AccountLedgerCreditCardDetailScreen(accountId: 'acc_cc1'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('BALANCE TREND'), findsOneWidget);
      expect(find.text('No trend data available yet'), findsOneWidget);

      // Sub-test B: Sufficient data (>= 2 transactions)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) => mockNotifier),
            recalculatedAccountsProvider.overrideWith((ref) {
              final accounts = ref.watch(accountsProvider).value ?? [];
              return AsyncValue.data(accounts);
            }),
            accountTransactionsProvider('acc_cc1').overrideWithValue(AsyncValue.data(mockTxs)),
          ],
          child: const MaterialApp(
            home: AccountLedgerCreditCardDetailScreen(accountId: 'acc_cc1'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('BALANCE TREND'), findsOneWidget);
      expect(find.text('No trend data available yet'), findsNothing);
    });

    testWidgets('Renders transaction history filtered for selected card and supports period options', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockNotifier = MockAccountsNotifier([mockCcAccount]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) => mockNotifier),
            recalculatedAccountsProvider.overrideWith((ref) {
              final accounts = ref.watch(accountsProvider).value ?? [];
              return AsyncValue.data(accounts);
            }),
            accountTransactionsProvider('acc_cc1').overrideWithValue(AsyncValue.data(mockTxs)),
          ],
          child: const MaterialApp(
            home: AccountLedgerCreditCardDetailScreen(accountId: 'acc_cc1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify list items
      expect(find.text('Sarath'), findsOneWidget);
      expect(find.text('Payment received'), findsOneWidget);
      
      // Verify drop down button exists with active filter
      expect(find.text('This Month'), findsOneWidget);
    });
  });
}
