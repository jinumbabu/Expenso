import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/analytics/presentation/screens/analytics_screen.dart';
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
  group('AnalyticsScreen Widget Tests', () {
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
          createdAt: DateTime.now(),
        ),
        Category(
          id: 'cat_fuel',
          userId: 'user1',
          name: 'Fuel',
          type: 'expense',
          icon: 'local_gas_station',
          usageCount: 2,
          isSystemDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      mockTxs = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'expense',
          amount: 150000, // ₹1,500
          currency: 'INR',
          merchant: 'Swiggy',
          description: 'Lunch spend',
          categoryId: 'cat_food',
          date: DateTime(now.year, now.month, 10),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 'tx2',
          userId: 'user1',
          type: 'expense',
          amount: 80000, // ₹800
          currency: 'INR',
          merchant: 'Shell Petrol',
          description: 'Gas tank refill',
          categoryId: 'cat_fuel',
          date: DateTime(now.year, now.month, 12),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 'tx3',
          userId: 'user1',
          type: 'income',
          amount: 3000000, // ₹30,000
          currency: 'INR',
          merchant: 'Salary Corp',
          description: 'Salary credit',
          date: DateTime(now.year, now.month, 1),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    testWidgets('Renders Area line chart, pie chart, and categories legend list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      final fakeNotifier = MockExpenseListNotifier(mockTxs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseListNotifierProvider.overrideWith((ref) => fakeNotifier),
            categoriesProvider.overrideWith((ref) => mockCats),
          ],
          child: const MaterialApp(
            home: AnalyticsScreen(),
          ),
        ),
      );

      // Verify page titles and chart sections
      expect(find.text('Analytics Dashboard'), findsOneWidget);
      expect(find.text('INCOME VS EXPENSES'), findsOneWidget);
      expect(find.text('CATEGORY SHARE'), findsOneWidget);

      await tester.pump();

      // Verify category list items are loaded and show totals
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Fuel'), findsOneWidget);
      
      // Verify formatted spends are rendered
      expect(find.text('₹1,500'), findsOneWidget);
      expect(find.text('₹800'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
