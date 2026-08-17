import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:app/features/expenses/presentation/screens/bills_management_screen.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/accounts/presentation/screens/credit_card_detail_screen.dart';
import 'package:app/shared/widgets/reusable_net_worth_ring.dart';
import 'package:app/features/expenses/domain/usecases/get_transactions_usecase.dart';
import 'package:app/features/expenses/domain/usecases/create_transaction_usecase.dart';
import 'package:app/features/expenses/domain/usecases/update_transaction_usecase.dart';
import 'package:app/features/expenses/domain/usecases/delete_transaction_usecase.dart';

class FakeGetTransactionsUseCase extends Fake implements GetTransactionsUseCase {}
class FakeCreateTransactionUseCase extends Fake implements CreateTransactionUseCase {}
class FakeUpdateTransactionUseCase extends Fake implements UpdateTransactionUseCase {}
class FakeDeleteTransactionUseCase extends Fake implements DeleteTransactionUseCase {}
class FakeRef extends Fake implements Ref {}

class FakeDatabase extends Fake implements AppDatabase {}

class MockAccountsNotifier extends AccountsNotifier {
  MockAccountsNotifier(List<Account> initialData)
      : super(
          db: FakeDatabase(),
          userId: null,
        ) {
    state = AsyncValue.data(initialData);
  }
}

class MockExpenseListNotifier extends ExpenseListNotifier {
  MockExpenseListNotifier(List<Transaction> initialData)
      : super(
          getTransactions: FakeGetTransactionsUseCase(),
          createTransaction: FakeCreateTransactionUseCase(),
          updateTransaction: FakeUpdateTransactionUseCase(),
          deleteTransaction: FakeDeleteTransactionUseCase(),
          userId: 'user1',
          ref: FakeRef(),
        ) {
    state = AsyncValue.data(initialData);
  }

  @override
  Future<void> loadTransactions() async {}
}

void main() {
  group('CreditCardDetailScreen Redesign & 3-Page Flow Tests', () {
    late List<Transaction> mockTxs;
    late List<Category> mockCats;
    late List<Account> mockAccounts;
    late List<Bill> mockBills;
    final now = DateTime.now();

    setUp(() {
      mockCats = [
        Category(
          id: 'cat_shopping',
          userId: 'user1',
          name: 'Shopping',
          type: 'expense',
          icon: 'shopping_bag',
          usageCount: 5,
          isSystemDefault: true,
          createdAt: now,
        ),
      ];

      mockAccounts = [
        Account(
          id: 'card_icici',
          userId: 'user1',
          name: 'ICICI Credit Card',
          type: 'credit_card',
          balance: -1922234, // -₹19,222.34
          isDefault: true,
          createdAt: now,
          updatedAt: now,
          currency: 'INR',
          colorTheme: '0xFFFF3B30',
          icon: 'credit_card',
          isActive: true,
          creditLimit: 5000000, // ₹50,000 credit limit
          outstandingBalance: 1922234, // ₹19,222.34 outstanding
          availableCredit: 3077766, // ₹30,777.66 available
          statementDate: 15,
          paymentDueDate: 5,
          isEstimated: false,
        ),
        Account(
          id: 'card_hdfc',
          userId: 'user1',
          name: 'HDFC Card',
          type: 'credit_card',
          balance: -452034, // -₹4,520.34
          isDefault: false,
          createdAt: now,
          updatedAt: now,
          currency: 'INR',
          colorTheme: '0xFFFF9500',
          icon: 'credit_card',
          isActive: true,
          creditLimit: 4000000, // ₹40,000 limit
          outstandingBalance: 452034, // ₹4,520.34 outstanding
          availableCredit: 3547966, // ₹35,479.66 available
          statementDate: 20,
          paymentDueDate: 10,
          isEstimated: false,
        ),
      ];

      mockBills = [
        Bill(
          id: 'bill1',
          userId: 'user1',
          accountId: 'card_icici',
          title: 'ICICI Statement Bill',
          amount: 1922234, // ₹19,222.34
          dueDate: now.add(const Duration(days: 12)),
          statementDate: now.subtract(const Duration(days: 15)),
          status: 'pending',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      mockTxs = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          accountId: 'card_icici',
          type: 'expense',
          amount: 137000, // ₹1,370
          currency: 'INR',
          merchant: 'Zara',
          description: 'Shopping',
          categoryId: 'cat_shopping',
          date: now.subtract(const Duration(days: 1)),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    testWidgets('Renders Page 1: Dashboard with selector, overview, visual donut, metrics, and accounts', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeNotifier = MockExpenseListNotifier(mockTxs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseListNotifierProvider.overrideWith((ref) => fakeNotifier),
            categoriesProvider.overrideWith((ref) => mockCats),
            accountsProvider.overrideWith((ref) => MockAccountsNotifier(mockAccounts)),
            recalculatedAccountsProvider.overrideWithValue(AsyncValue.data(mockAccounts)),
            billsStreamProvider.overrideWith((ref) => Stream.value(mockBills)),
          ],
          child: const MaterialApp(
            home: CreditCardDetailScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Page Header
      expect(find.text('Credit Card'), findsOneWidget);

      // 2. Verify dynamic tabs exist
      expect(find.text('All Cards'), findsOneWidget);
      expect(find.text('ICICI Credit Card'), findsWidgets); // Tab + account list item
      expect(find.text('HDFC Card'), findsWidgets); // Tab + account list item

      // 3. Verify Credit Card Overview exists
      expect(find.text('CREDIT CARD OVERVIEW'), findsOneWidget);
      expect(find.text('Credit Limit'), findsWidgets);
      expect(find.text('Available Limit'), findsOneWidget);
      expect(find.text('Total Amount Due'), findsOneWidget);
      expect(find.text('Total Outstanding'), findsOneWidget);

      // 4. Verify visual donut ring exists
      expect(find.byType(ReusableNetWorthRing), findsOneWidget);

      // 5. Verify deprecated cards are removed
      expect(find.text('CREDIT UTILISATION VISUAL'), findsNothing);
      expect(find.text('TOTAL AMOUNT DUE'), findsNothing);
      expect(find.text('CURRENT BILL'), findsNothing);
      expect(find.text('LAST BILL'), findsNothing);

      // 6. Verify Bill and Liabilities categories
      expect(find.text('ACCOUNT-WISE LIABILITIES'), findsOneWidget);
      expect(find.text('CREDIT CARDS'), findsOneWidget);

      // 7. Recent transactions list
      expect(find.text('RECENT TRANSACTIONS'), findsOneWidget);
      expect(find.text('Zara'), findsOneWidget);
    });

    testWidgets('Tapping dynamic card tab switches card and navigates directly to Page 2: Analytics', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeNotifier = MockExpenseListNotifier(mockTxs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseListNotifierProvider.overrideWith((ref) => fakeNotifier),
            categoriesProvider.overrideWith((ref) => mockCats),
            accountsProvider.overrideWith((ref) => MockAccountsNotifier(mockAccounts)),
            recalculatedAccountsProvider.overrideWithValue(AsyncValue.data(mockAccounts)),
            billsStreamProvider.overrideWith((ref) => Stream.value(mockBills)),
          ],
          child: const MaterialApp(
            home: CreditCardDetailScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on ICICI Credit Card tab selector (keeps on Page 1)
      final iciciTabFinder = find.text('ICICI Credit Card').first;
      await tester.tap(iciciTabFinder);
      await tester.pumpAndSettle();

      // We should still be on Page 1 Dashboard, but with ICICI selected.
      // Tap Overview Card to enter Page 2 (Analytics)
      await tester.tap(find.text('CREDIT CARD OVERVIEW'));
      await tester.pumpAndSettle();

      // We should now be on Page 2 (ICICI Credit Card Analytics header)
      expect(find.text('ICICI Credit Card'), findsOneWidget);
      // Tabs should be gone
      expect(find.text('All Cards'), findsNothing);

      // Verify period selector and date chevrons exist
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('TOTAL SPENDING'), findsOneWidget);

      // Tapping back button in header goes back to Page 1
      final backButton = find.byKey(const Key('header_back_button'));
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Back on Page 1 Dashboard
      expect(find.text('Credit Card'), findsOneWidget);
      expect(find.text('All Cards'), findsOneWidget);
    });

    testWidgets('Tapping a card in account-wise liabilities navigates directly to Page 2: Analytics and selects the card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final hdfcTx = Transaction(
        id: 'tx2',
        userId: 'user1',
        accountId: 'card_hdfc',
        type: 'expense',
        amount: 50000,
        currency: 'INR',
        merchant: 'Starbucks',
        categoryId: 'cat_shopping',
        date: now.subtract(const Duration(days: 1)),
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );
      final fakeNotifier = MockExpenseListNotifier([...mockTxs, hdfcTx]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseListNotifierProvider.overrideWith((ref) => fakeNotifier),
            categoriesProvider.overrideWith((ref) => mockCats),
            accountsProvider.overrideWith((ref) => MockAccountsNotifier(mockAccounts)),
            recalculatedAccountsProvider.overrideWithValue(AsyncValue.data(mockAccounts)),
            billsStreamProvider.overrideWith((ref) => Stream.value(mockBills)),
          ],
          child: const MaterialApp(
            home: CreditCardDetailScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we are on Page 1
      expect(find.text('Credit Card'), findsOneWidget);

      // Find HDFC Card in the Account-Wise Liabilities list and tap it
      final hdfcCardFinder = find.byKey(const Key('liability_card_card_hdfc'));
      expect(hdfcCardFinder, findsOneWidget);

      await tester.tap(hdfcCardFinder);
      await tester.pumpAndSettle();

      // We should now be on Page 2 Analytics for HDFC Card
      expect(find.text('HDFC Card'), findsOneWidget);
      expect(find.text('All Cards'), findsNothing);
      expect(find.text('TOTAL SPENDING'), findsOneWidget);
    });

    testWidgets('Tapping category card on Page 2 navigates to Page 3: Sub-Expenses', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeNotifier = MockExpenseListNotifier(mockTxs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseListNotifierProvider.overrideWith((ref) => fakeNotifier),
            categoriesProvider.overrideWith((ref) => mockCats),
            accountsProvider.overrideWith((ref) => MockAccountsNotifier(mockAccounts)),
            recalculatedAccountsProvider.overrideWithValue(AsyncValue.data(mockAccounts)),
            billsStreamProvider.overrideWith((ref) => Stream.value(mockBills)),
          ],
          child: const MaterialApp(
            home: CreditCardDetailScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Overview Card on Page 1 to enter Page 2
      await tester.tap(find.text('CREDIT CARD OVERVIEW'));
      await tester.pumpAndSettle();

      // Now on Page 2. Tapping Category dropdown item
      expect(find.text('Shopping'), findsOneWidget);

      // Tap Category card "Shopping" once (selects category)
      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();

      // We should NOT be on Page 3 yet
      expect(find.text('SUB-EXPENSES'), findsNothing);

      // Tap Category card "Shopping" again (second tap)
      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();

      // We should be on Page 3 (Category Detail - "Shopping")
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('SUB-EXPENSES'), findsOneWidget);
      expect(find.text('Zara'), findsOneWidget);

      // Tap close button in header to return to Page 2
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Back on Page 2 Analytics
      expect(find.text('Today'), findsOneWidget);
    });
  });
}
