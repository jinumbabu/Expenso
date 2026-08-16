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
  group('MonthlyIncomeScreen Redesign & Interaction Tests', () {
    late List<Transaction> mockTxs;
    late List<Category> mockCats;
    late List<Account> mockAccounts;
    final now = DateTime.now();

    setUp(() {
      mockCats = [
        Category(
          id: 'cat_salary',
          userId: 'user1',
          name: 'Salary',
          type: 'income',
          icon: 'payments',
          usageCount: 10,
          isSystemDefault: true,
          createdAt: now,
        ),
        Category(
          id: 'cat_freelance',
          userId: 'user1',
          name: 'Freelance',
          type: 'income',
          icon: 'work',
          usageCount: 3,
          isSystemDefault: true,
          createdAt: now,
        ),
      ];

      mockAccounts = [
        Account(
          id: 'acc_hdfc',
          userId: 'user1',
          name: 'HDFC Bank',
          type: 'savings',
          balance: 1000000,
          currency: 'INR',
          colorTheme: '0xFF0066FF',
          icon: 'account_balance',
          isDefault: false,
          isEstimated: false,
          openingBalance: 1000000,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      mockTxs = [
        Transaction(
          id: 'tx_salary',
          userId: 'user1',
          type: 'income',
          amount: 5000000, // ₹50,000
          currency: 'INR',
          merchant: 'Ansel Salary Corp',
          description: 'Monthly Pay',
          categoryId: 'cat_salary',
          accountId: 'acc_hdfc',
          date: DateTime(now.year, now.month, now.day), // Today to fit within current day filter
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 'tx_freelance',
          userId: 'user1',
          type: 'income',
          amount: 1500000, // ₹15,000
          currency: 'INR',
          merchant: 'Client Freelance',
          description: 'Website Design',
          categoryId: 'cat_freelance',
          accountId: 'acc_hdfc',
          date: DateTime(now.year, now.month, now.day), // Today
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    testWidgets('Renders redesigned Monthly Income screen with periods, donut, details and recent records', (tester) async {
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
            home: MonthlyTransactionDetailScreen(type: 'income'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify header renders initial state (MONTHLY INCOME, back only)
      expect(find.text('MONTHLY INCOME'), findsOneWidget);
      expect(find.byKey(const Key('header_back_button')), findsOneWidget);
      expect(find.byKey(const Key('header_chevron_left')), findsNothing);
      expect(find.byKey(const Key('header_chevron_right')), findsNothing);

      // 2. Tap Month in period selector
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      final expectedMonthLabel = DateFormat('MMMM yyyy').format(now).toUpperCase();
      expect(find.text(expectedMonthLabel), findsOneWidget);
      expect(find.byKey(const Key('header_back_button')), findsNothing);
      expect(find.byKey(const Key('header_chevron_left')), findsOneWidget);
      expect(find.byKey(const Key('header_chevron_right')), findsOneWidget);

      // 3. Verify period filter selector items render
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Last Month'), findsOneWidget);
      expect(find.text('3M'), findsOneWidget);
      expect(find.text('6M'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // 4. Verify donut chart and breakdown sections exist
      expect(find.byType(ReusableDonutChart), findsOneWidget);
      expect(find.text('INCOME BY CATEGORY'), findsOneWidget);

      // 5. Verify breakdown group cards are visible
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Freelance'), findsOneWidget);
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
            home: MonthlyTransactionDetailScreen(type: 'income'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Month in period selector
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      // For Month, right button should be disabled since we cannot navigate to next month (future)
      final forwardButtonFinder = find.byKey(const Key('header_chevron_right'));
      expect(forwardButtonFinder, findsOneWidget);
      
      final forwardButton = tester.widget<IconButton>(forwardButtonFinder);
      expect(forwardButton.onPressed, isNull); // Disabled

      // Tap backward (chevron_left)
      final backwardButtonFinder = find.byKey(const Key('header_chevron_left'));
      expect(backwardButtonFinder, findsOneWidget);

      await tester.tap(backwardButtonFinder);
      await tester.pumpAndSettle();

      // Now forward button should be enabled because we are in the past (last month)
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
            home: MonthlyTransactionDetailScreen(type: 'income'),
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

      // 4. Select 3M
      await tester.tap(find.text('3M'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('header_chevron_left')), findsNothing);
      expect(find.byKey(const Key('header_chevron_right')), findsNothing);

      // 5. Select 6M
      await tester.tap(find.text('6M'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('header_chevron_left')), findsNothing);
      expect(find.byKey(const Key('header_chevron_right')), findsNothing);

      // 6. Select 1Y
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
            home: MonthlyTransactionDetailScreen(type: 'income'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open breakdown switcher popup menu
      await tester.tap(find.text('INCOME BY CATEGORY'));
      await tester.pumpAndSettle();

      // Tap 'INCOME BY ACCOUNT' menu option
      await tester.tap(find.text('INCOME BY ACCOUNT').last);
      await tester.pumpAndSettle();

      // Verify layout displays accounts in the breakdown list
      expect(find.text('INCOME BY ACCOUNT'), findsOneWidget);
      expect(find.text('HDFC Bank'), findsOneWidget);
      expect(find.text('Salary'), findsNothing); // Salary is a category, not an account
    });

    group('Bidirectional Interaction Tests', () {
      testWidgets('Tapping a category card updates selectedId in ReusableDonutChart', (tester) async {
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
              home: MonthlyTransactionDetailScreen(type: 'income'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap the 'Salary' card in the breakdown list
        final salaryCard = find.ancestor(
          of: find.text('Salary'),
          matching: find.byType(GestureDetector),
        ).first;
        await tester.ensureVisible(salaryCard);
        await tester.tap(salaryCard);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Verify the ReusableDonutChart is updated with the selectedId 'cat_salary'
        final donutFinder = find.byType(ReusableDonutChart);
        final ReusableDonutChart donut = tester.widget<ReusableDonutChart>(donutFinder);
        expect(donut.selectedId, 'cat_salary');
      });
    });
  });
}
