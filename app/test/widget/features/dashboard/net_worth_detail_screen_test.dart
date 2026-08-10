import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/financial_calculation_service.dart' hide AccountSummary;
import 'package:app/features/dashboard/presentation/screens/net_worth_detail_screen.dart';
import 'package:app/features/dashboard/presentation/screens/dashboard_summary_screen.dart';
import 'package:app/shared/widgets/blue_donut_chart.dart';
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
  group('NetWorthDetailScreen Redesign Widget Tests', () {
    late List<Transaction> mockTxs;
    late List<Category> mockCats;
    late List<Account> mockAccounts;
    late AccountSummary mockSummary;
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
      ];

      mockAccounts = [
        Account(
          id: 'acc_sbi',
          userId: 'user1',
          name: 'SBI Savings',
          type: 'savings',
          balance: 500000, // ₹5,000
          isDefault: true,
          createdAt: now,
          updatedAt: now,
          currency: 'INR',
          colorTheme: '0xFF0066FF',
          icon: 'account_balance',
          isActive: true,
          isEstimated: false,
        ),
        Account(
          id: 'acc_cc',
          userId: 'user1',
          name: 'HDFC Credit Card',
          type: 'credit_card',
          balance: -50000, // -₹500
          isDefault: false,
          createdAt: now,
          updatedAt: now,
          currency: 'INR',
          colorTheme: '0xFFFF3B30',
          icon: 'credit_card',
          isActive: true,
          outstandingBalance: 50000, // ₹500 outstanding
          isEstimated: false,
        ),
      ];

      mockSummary = AccountSummary(
        totalAssets: 500000, // ₹5,000
        totalLiabilities: 50000, // ₹500
        netAssets: 450000, // ₹4,500
        cashBalance: 0,
        bankBalance: 500000,
        walletBalance: 0,
        ccOutstanding: 50000,
        investmentBalance: 0,
        loanOutstanding: 0,
      );

      mockTxs = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'income',
          amount: 500000, // ₹5,000
          currency: 'INR',
          merchant: 'Salary Corp',
          description: 'Monthly salary',
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
          amount: 100000, // ₹1,000
          currency: 'INR',
          merchant: 'Uber',
          description: 'Ride to office',
          categoryId: 'cat_food',
          date: DateTime(now.year, now.month, 12),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    testWidgets('Renders redesigned Net Worth Details screen with integrated small donut ring and grouped accounts', (tester) async {
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
            recalculatedAccountsProvider.overrideWithValue(AsyncValue.data(mockAccounts)),
            accountSummaryProvider.overrideWithValue(AsyncValue.data(mockSummary)),
            dashboardFinancialDataProvider.overrideWithValue(
              const FinancialData(
                openingBalance: 100000,
                monthlyIncome: 400000,
                monthlyExpenses: 100000,
                netWorth: 450000,
              ),
            ),
          ],
          child: const MaterialApp(
            home: NetWorthDetailScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify screen title
      expect(find.text('Net Worth Details'), findsOneWidget);

      // 2. Verify CURRENT NET WORTH summary card
      expect(find.text('CURRENT\nNET WORTH'), findsOneWidget);
      expect(find.text('TOTAL ASSETS'), findsOneWidget);
      expect(find.text('TOTAL LIABILITIES'), findsOneWidget);

      // 3. Verify small integrated donut chart (BlueDonutChart) and legend labels are present
      expect(find.byType(BlueDonutChart), findsOneWidget);
      expect(find.text('Total Assets'), findsOneWidget);
      expect(find.text('Total Liabilities'), findsOneWidget);

      // 4. Verify standalone large breakdown donut card is NOT present
      expect(find.text('NET WORTH BREAKDOWN'), findsNothing);

      // 5. Verify ACCOUNT-WISE BALANCES section
      expect(find.text('ACCOUNT-WISE BALANCES'), findsOneWidget);
      expect(find.text('ASSETS'), findsOneWidget);
      expect(find.text('LIABILITIES'), findsOneWidget);

      // Verify specific grouped accounts are rendered
      expect(find.text('SBI'), findsOneWidget);
      expect(find.text('HDFC'), findsOneWidget);
      expect(find.text('Available Balance'), findsOneWidget);
      expect(find.text('Outstanding Balance'), findsOneWidget);

      // 6. Verify TOP SPENDING CATEGORIES section
      expect(find.text('TOP SPENDING CATEGORIES'), findsOneWidget);

      // 7. Verify RECENT NET WORTH TRANSACTIONS section
      expect(find.text('RECENT NET WORTH TRANSACTIONS'), findsOneWidget);
      expect(find.text('Salary Corp'), findsOneWidget);
      expect(find.text('Uber'), findsOneWidget);
    });
  });
}
