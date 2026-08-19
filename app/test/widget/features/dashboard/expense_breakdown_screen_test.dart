import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/dashboard/presentation/screens/expense_breakdown_screen.dart';
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
  group('ExpenseBreakdownScreen Redesign & Interaction Tests', () {
    late List<Transaction> mockTxs;
    late List<Category> mockCats;
    final now = DateTime.now();

    setUp(() {
      mockCats = [
        Category(
          id: 'cat_food',
          userId: 'user1',
          name: 'Food',
          type: 'expense',
          icon: 'fastfood',
          usageCount: 5,
          isSystemDefault: true,
          createdAt: now,
        ),
        Category(
          id: 'cat_bills',
          userId: 'user1',
          name: 'Bills',
          type: 'expense',
          icon: 'shopping_bag',
          usageCount: 2,
          isSystemDefault: true,
          createdAt: now,
        ),
      ];

      mockTxs = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'expense',
          amount: 50000, // ₹500
          currency: 'INR',
          merchant: 'McDonalds',
          description: 'Lunch',
          categoryId: 'cat_food',
          date: DateTime(now.year, now.month, 10),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 'tx2',
          userId: 'user1',
          type: 'expense',
          amount: 150000, // ₹1500
          currency: 'INR',
          merchant: 'Electricity Corp',
          description: 'Power bill',
          categoryId: 'cat_bills',
          date: DateTime(now.year, now.month, 12),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    testWidgets('Renders Expense Breakdown screen with scrollable periods, parent donut and triggers detail flow', (tester) async {
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
          ],
          child: const MaterialApp(
            home: ExpenseBreakdownScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify period selector items are rendered
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Last Month'), findsOneWidget);
      expect(find.text('3M'), findsOneWidget);
      expect(find.text('6M'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // 2. Verify ReusableDonutChart is rendered
      expect(find.byType(ReusableDonutChart), findsOneWidget);

      // 3. Verify Categories in list
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Bills'), findsOneWidget);

      // Verify layout structure: outer column + expanded scrollable list
      expect(find.byType(Column), findsWidgets);
      final verticalListFinder = find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.vertical,
      );
      expect(verticalListFinder, findsOneWidget);

      // 4. First tap highlights category item (updating selection, but does NOT enter detail mode)
      final foodCard = find.ancestor(
        of: find.text('Food'),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(foodCard);
      await tester.pumpAndSettle();

      // ReusableDonutChart should still be the parent one, and _isDetailMode is false
      expect(find.text('SUB-EXPENSES'), findsNothing);

      // 5. Second tap on highlighted category enters detail mode
      await tester.tap(foodCard);
      await tester.pumpAndSettle();

      // Verify we entered detail mode: sub-expenses header is shown, McDonald's lunch transaction is shown
      expect(find.text('SUB-EXPENSES'), findsOneWidget);
      expect(find.text('McDonalds'), findsOneWidget);
      expect(find.text('Electricity Corp'), findsNothing); // Bills item should not be in Food detail view

      // 6. Close detail mode using back arrow or close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify we returned to parent breakdown screen
      expect(find.text('SUB-EXPENSES'), findsNothing);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Bills'), findsOneWidget);
    });

    testWidgets('Tapping a donut segment highlights segment, center, scrolls to category list item and highlights card', (tester) async {
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
          ],
          child: const MaterialApp(
            home: ExpenseBreakdownScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the ReusableDonutChart on the screen
      final donutFinder = find.byType(ReusableDonutChart);
      expect(donutFinder, findsOneWidget);

      final ReusableDonutChart donut = tester.widget<ReusableDonutChart>(donutFinder);

      // Simulate tapping the segment for 'Bills' (cat_bills)
      donut.onSelected('cat_bills');
      await tester.pumpAndSettle();

      // Verify selected category is highlighted with a cyan border (Color(0xFF00E5FF))
      final billsCardFinder = find.ancestor(
        of: find.text('Bills'),
        matching: find.byType(GestureDetector),
      );
      expect(billsCardFinder, findsOneWidget);

      final containerFinder = find.descendant(
        of: billsCardFinder,
        matching: find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration),
      );
      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.border!.isUniform, isTrue);
      expect(decoration.border!.top.color, const Color(0xFF00E5FF));
    });

    testWidgets('Tapping a category card highlights donut segment and updates center', (tester) async {
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
          ],
          child: const MaterialApp(
            home: ExpenseBreakdownScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the 'Bills' card
      final billsCard = find.ancestor(
        of: find.text('Bills'),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(billsCard);
      await tester.pump(const Duration(milliseconds: 400));

      // Verify donut selection is updated to 'cat_bills'
      final donutFinder = find.byType(ReusableDonutChart);
      final ReusableDonutChart donut = tester.widget<ReusableDonutChart>(donutFinder);
      expect(donut.selectedId, 'cat_bills');
    });

    testWidgets('Sub-expense screen renders with fixed chart and scrolling transaction list, and supports bidirectional selection', (tester) async {
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
          ],
          child: const MaterialApp(
            home: ExpenseBreakdownScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Double tap 'Food' to enter detail mode directly
      final foodCard = find.ancestor(
        of: find.text('Food'),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(foodCard);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(foodCard);
      await tester.pump(const Duration(milliseconds: 400));

      // 2. Verify fixed detail layout structure (Column with fixed chart + scrollable list)
      expect(find.text('SUB-EXPENSES'), findsOneWidget);
      expect(find.byType(ReusableDonutChart), findsOneWidget);
      
      final verticalListFinder = find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.vertical,
      );
      expect(verticalListFinder, findsOneWidget);

      // Verify the list scroll controller is attached
      final ListView listWidget = tester.widget<ListView>(verticalListFinder);
      expect(listWidget.controller, isNotNull);

      // 3. Verify sub-expense item is shown (McDonalds)
      expect(find.text('McDonalds'), findsOneWidget);

      // 4. Tap the McDonalds card and check donut center updates
      final mcDonaldsCard = find.ancestor(
        of: find.text('McDonalds'),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(mcDonaldsCard);
      await tester.pump(const Duration(milliseconds: 400));

      final donutFinder = find.byType(ReusableDonutChart);
      final ReusableDonutChart donut = tester.widget<ReusableDonutChart>(donutFinder);
      expect(donut.selectedId, 'tx1'); // Selected sub-expense is tx1
    });
  });
}
