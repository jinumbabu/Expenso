import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/expenses/presentation/screens/monthly_transaction_detail_screen.dart';
import 'package:app/shared/widgets/reusable_donut_chart.dart';
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
  group('MonthlyExpensesScreen Redesign & Interaction Tests', () {
    late List<Transaction> mockTxs;
    late List<Category> mockCats;
    late List<Account> mockAccounts;
    final now = DateTime.now();

    setUp(() {
      mockCats = [
        Category(
          id: 'cat_shopping',
          userId: 'user1',
          name: 'Shopping',
          type: 'expense',
          icon: 'shopping_bag',
          usageCount: 10,
          isSystemDefault: true,
          createdAt: now,
        ),
        Category(
          id: 'cat_food',
          userId: 'user1',
          name: 'Food',
          type: 'expense',
          icon: 'restaurant',
          usageCount: 5,
          isSystemDefault: true,
          createdAt: now,
        ),
      ];

      mockAccounts = [
        Account(
          id: 'acc_cash',
          userId: 'user1',
          name: 'Cash Wallet',
          type: 'cash',
          balance: 50000,
          currency: 'INR',
          colorTheme: '0xFF4CD964',
          icon: 'wallet',
          isDefault: true,
          isEstimated: false,
          openingBalance: 50000,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      mockTxs = [
        Transaction(
          id: 'tx_shopping',
          userId: 'user1',
          type: 'expense',
          amount: 1648500, // ₹16,485
          currency: 'INR',
          merchant: 'Zara Store',
          description: 'Clothes',
          categoryId: 'cat_shopping',
          accountId: 'acc_cash',
          date: DateTime(now.year, now.month, now.day),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 'tx_food',
          userId: 'user1',
          type: 'expense',
          amount: 120000, // ₹1,200
          currency: 'INR',
          merchant: 'Pizza Place',
          description: 'Dinner',
          categoryId: 'cat_food',
          accountId: 'acc_cash',
          date: DateTime(now.year, now.month, now.day),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    testWidgets('Renders redesigned Monthly Expenses screen with periods, donut, details and recent records', (tester) async {
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
          ],
          child: const MaterialApp(
            home: MonthlyTransactionDetailScreen(type: 'expense'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header initially displays MONTHLY EXPENSES (Back arrow button only, no navigation chevrons)
      expect(find.text('MONTHLY EXPENSES'), findsOneWidget);
      expect(find.byKey(const Key('header_back_button')), findsOneWidget);
      expect(find.byKey(const Key('header_chevron_left')), findsNothing);
      expect(find.byKey(const Key('header_chevron_right')), findsNothing);

      // Verify that "Month" is selected by default
      final monthTextFinder = find.text('Month');
      expect(monthTextFinder, findsOneWidget);

      // Tapping "Month" should switch the title to dates and enable navigation arrows
      await tester.tap(monthTextFinder);
      await tester.pumpAndSettle();

      final expectedMonthLabel = DateFormat('MMMM yyyy').format(now).toUpperCase();
      expect(find.text(expectedMonthLabel), findsOneWidget);
      expect(find.byKey(const Key('header_chevron_left')), findsOneWidget);
      expect(find.byKey(const Key('header_chevron_right')), findsOneWidget);

      // Verify donut chart is rendered
      expect(find.byType(ReusableDonutChart), findsOneWidget);

      // Total expense = ₹16,485 + ₹1,200 = ₹17,685
      expect(find.text('TOTAL EXPENSE'), findsOneWidget);

      // Verify spending categories are listed
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('Date navigation shifts timeframes and disables right button for future timeframes', (tester) async {
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
          ],
          child: const MaterialApp(
            home: MonthlyTransactionDetailScreen(type: 'expense'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Month to transition header to navigation state
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      final forwardButtonFinder = find.byKey(const Key('header_chevron_right'));
      expect(forwardButtonFinder, findsOneWidget);
      
      final forwardButton = tester.widget<IconButton>(forwardButtonFinder);
      expect(forwardButton.onPressed, isNull); // Disabled (current month)

      // Tap backward (chevron_left)
      final backwardButtonFinder = find.byKey(const Key('header_chevron_left'));
      expect(backwardButtonFinder, findsOneWidget);

      await tester.tap(backwardButtonFinder);
      await tester.pumpAndSettle();

      // Now forward button should be enabled because we are in the past
      final updatedForwardButton = tester.widget<IconButton>(forwardButtonFinder);
      expect(updatedForwardButton.onPressed, isNotNull); // Enabled
    });

    testWidgets('Header formats and navigation arrows exist/disappear correctly for other periods', (tester) async {
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
          ],
          child: const MaterialApp(
            home: MonthlyTransactionDetailScreen(type: 'expense'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Select Today
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      final expectedTodayLabel = DateFormat('d MMMM yyyy').format(now).toUpperCase();
      expect(find.text(expectedTodayLabel), findsOneWidget);
      expect(find.byKey(const Key('header_chevron_left')), findsOneWidget);
      expect(find.byKey(const Key('header_chevron_right')), findsOneWidget);
      final todayForwardButton = tester.widget<IconButton>(find.byKey(const Key('header_chevron_right')));
      expect(todayForwardButton.onPressed, isNull);

      // 2. Select Week
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
      final expectedWeekLabel = '${DateFormat('d MMM yyyy').format(currentWeekStart).toUpperCase()} – ${DateFormat('d MMM yyyy').format(currentWeekEnd).toUpperCase()}';
      expect(find.text(expectedWeekLabel), findsOneWidget);
      expect(find.byKey(const Key('header_chevron_left')), findsOneWidget);
      expect(find.byKey(const Key('header_chevron_right')), findsOneWidget);

      // 3. Select Last Month
      await tester.tap(find.text('Last Month'));
      await tester.pumpAndSettle();
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final expectedLastMonthLabel = DateFormat('MMMM yyyy').format(lastMonthStart).toUpperCase();
      expect(find.text(expectedLastMonthLabel), findsOneWidget);
      expect(find.byKey(const Key('header_chevron_left')), findsOneWidget);
      expect(find.byKey(const Key('header_chevron_right')), findsOneWidget);

      // 4. Select 3M (No arrows)
      await tester.tap(find.text('3M'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('header_chevron_left')), findsNothing);
      expect(find.byKey(const Key('header_chevron_right')), findsNothing);

      // 5. Select 6M (No arrows)
      await tester.tap(find.text('6M'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('header_chevron_left')), findsNothing);
      expect(find.byKey(const Key('header_chevron_right')), findsNothing);

      // 6. Select 1Y (Has arrows)
      await tester.tap(find.text('1Y'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('header_chevron_left')), findsOneWidget);
      expect(find.byKey(const Key('header_chevron_right')), findsOneWidget);
    });

    testWidgets('Tapping breakdown switcher menu updates mode and card lists', (tester) async {
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
          ],
          child: const MaterialApp(
            home: MonthlyTransactionDetailScreen(type: 'expense'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Month to load data
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      // Check current default switcher mode shows SPENDING BY CATEGORY
      expect(find.text('SPENDING BY CATEGORY'), findsOneWidget);

      // Open dropdown menu
      await tester.tap(find.text('SPENDING BY CATEGORY'));
      await tester.pumpAndSettle();

      // Select SPENDING BY ACCOUNT
      await tester.tap(find.text('SPENDING BY ACCOUNT').last);
      await tester.pumpAndSettle();

      // Verify lists show accounts
      expect(find.text('Cash Wallet'), findsOneWidget);
    });
  });
}
