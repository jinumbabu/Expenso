import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/core/security/audit_logger.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/features/expenses/domain/usecases/get_transactions_usecase.dart';
import 'package:app/features/expenses/domain/usecases/create_transaction_usecase.dart';
import 'package:app/features/expenses/domain/usecases/update_transaction_usecase.dart';
import 'package:app/features/expenses/domain/usecases/delete_transaction_usecase.dart';
import 'package:app/features/goals/presentation/providers/goals_provider.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/main.dart' show ExpensoApp;

class FakeAuthRepository extends Fake implements AuthRepository {}
class FakeAuditLogger extends Fake implements AuditLogger {}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier() : super(FakeAuthRepository(), FakeAuditLogger()) {
    state = AuthState.authenticated(
      User(
        id: 'user1',
        googleId: 'google-id',
        email: 'jinu@expenso.ai',
        displayName: 'Jinu',
        currency: 'INR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> checkSession() async {}
}

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

class MockGoalsListNotifier extends GoalsListNotifier {
  MockGoalsListNotifier(List<Goal> initialGoals) : super(FakeRef()) {
    state = initialGoals;
  }

  @override
  Future<void> loadGoals() async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E App User Flow Integration Tests', () {
    late List<Transaction> mockTxs;
    late List<Category> mockCats;
    late List<Goal> mockGoals;
    final now = DateTime.now();

    setUp(() {
      mockCats = [
        Category(
          id: 'cat1',
          userId: 'user1',
          name: 'Food',
          type: 'expense',
          icon: 'fastfood',
          usageCount: 1,
          isSystemDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      mockTxs = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'expense',
          amount: 45000, // ₹450
          currency: 'INR',
          merchant: 'Starbucks',
          description: 'Latte',
          categoryId: 'cat1',
          date: DateTime(now.year, now.month, 10, 9, 30),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      mockGoals = [
        Goal(
          id: 'goal1',
          userId: 'user1',
          title: 'Emergency Fund',
          targetAmount: 5000000, // ₹50,000
          currentAmount: 2000000,  // ₹20,000
          targetDate: DateTime.now().add(const Duration(days: 30)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    testWidgets('Complete app navigation flow with mock dependencies', (tester) async {
      final fakeAuth = FakeAuthNotifier();
      final fakeExpenses = MockExpenseListNotifier(mockTxs);
      final fakeGoals = MockGoalsListNotifier(mockGoals);

      Future<void> safePump() async {
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => fakeAuth),
            expenseListNotifierProvider.overrideWith((ref) => fakeExpenses),
            goalsListNotifierProvider.overrideWith((ref) => fakeGoals),
            categoriesProvider.overrideWith((ref) => mockCats),
            // Reset unlocked state to ensure the PIN screen shows up first
            isUnlockedProvider.overrideWith((ref) => false),
          ],
          child: const ExpensoApp(),
        ),
      );

      await safePump();

      // 1. We should start on the PIN Lock Screen overlay
      expect(find.text('SECURITY LOCK'), findsOneWidget);

      // 2. Tap PIN code '1', '2', '3', '4' to unlock the app
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await safePump();

      // 3. We should now be on the Dashboard
      expect(find.text('Welcome back,'), findsOneWidget);
      expect(find.text('Jinu'), findsOneWidget);
      expect(find.text('NET WORTH'), findsOneWidget);

      // 4. Tap the 'Calendar' card in the feature grid
      final calendarGridFinder = find.text('Calendar');
      await tester.ensureVisible(calendarGridFinder);
      await tester.pump();
      expect(calendarGridFinder, findsOneWidget);
      await tester.tap(calendarGridFinder);
      await safePump();

      // We should arrive on the Calendar Screen
      expect(find.text('Calendar Intelligence'), findsOneWidget);

      // Tap back button
      final backButtonFinder = find.byIcon(Icons.arrow_back_ios_new);
      expect(backButtonFinder, findsOneWidget);
      await tester.tap(backButtonFinder);
      await safePump();

      // 5. Back on Dashboard. Tap 'Reports' card
      final reportsGridFinder = find.text('Reports');
      await tester.ensureVisible(reportsGridFinder);
      await tester.pump();
      expect(reportsGridFinder, findsOneWidget);
      await tester.tap(reportsGridFinder);
      await safePump();

      // We should be on the Analytics Screen
      expect(find.text('Analytics Dashboard'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await safePump();

      // 6. Back on Dashboard. Tap 'Goals' card
      final goalsGridFinder = find.text('Goals');
      await tester.ensureVisible(goalsGridFinder);
      await tester.pump();
      expect(goalsGridFinder, findsOneWidget);
      await tester.tap(goalsGridFinder);
      await safePump();

      // We should be on the Goals Screen
      expect(find.text('Goals & Savings'), findsOneWidget);
    });
  });
}
