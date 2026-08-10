import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/calendar/presentation/screens/calendar_screen.dart';
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
  group('CalendarScreen Widget Tests', () {
    late List<Transaction> mockTxs;
    final now = DateTime.now();

    setUp(() {
      mockTxs = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'expense',
          amount: 50000, // ₹500
          currency: 'INR',
          merchant: 'Starbucks',
          description: null,
          date: DateTime(now.year, now.month, 15, 10, 30),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 'tx2',
          userId: 'user1',
          type: 'income',
          amount: 2500000, // ₹25,000
          currency: 'INR',
          merchant: 'Google Inc',
          description: null,
          date: DateTime(now.year, now.month, 15, 14, 0),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    testWidgets('Renders calendar heatmap grid and daily timeline correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeNotifier = MockExpenseListNotifier(mockTxs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseListNotifierProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      // Verify page title
      expect(find.text('Calendar Intelligence'), findsOneWidget);

      // Pump to let the state process
      await tester.pump();

      // Tap on day 15 (mock transactions are on day 15)
      final dayFinder = find.text('15');
      expect(dayFinder, findsWidgets);
      
      // Tap the day element
      await tester.tap(dayFinder.first);
      await tester.pumpAndSettle();

      // Verify daily transactions list headers or transaction names
      expect(find.text('Starbucks'), findsOneWidget);
      expect(find.text('Google Inc'), findsOneWidget);

      // Verify amounts (income has + prefix, expense has - prefix)
      expect(find.text('-₹500.00'), findsWidgets);
      expect(find.text('+₹25,000.00'), findsWidgets);
    });

    testWidgets('Displays empty state when a day without transactions is clicked', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeNotifier = MockExpenseListNotifier(mockTxs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseListNotifierProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pump();

      // Tap on day 20 (no transactions on this day)
      final dayFinder = find.text('20');
      expect(dayFinder, findsWidgets);
      await tester.tap(dayFinder.first);
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('No transactions found.'), findsOneWidget);
    });
  });
}
