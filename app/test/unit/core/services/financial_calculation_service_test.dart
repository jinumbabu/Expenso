import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/financial_calculation_service.dart';

void main() {
  group('FinancialCalculationService Centralized Tests', () {
    final now = DateTime(2026, 8, 19);

    test('TEST 1: Income = 38203, Expenses = 69400.60 -> Net Cash Flow = -31197.60', () {
      final transactions = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'income',
          amount: 3820300, // ₹38,203 in cents
          currency: 'INR',
          date: DateTime(2026, 8, 10),
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
          amount: 6940060, // ₹69,400.60 in cents
          currency: 'INR',
          date: DateTime(2026, 8, 12),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: transactions,
        accounts: [],
        selectedMonth: now,
      );

      expect(snapshot.income, equals(38203.00));
      expect(snapshot.expenses, equals(69400.60));
      expect(snapshot.netCashFlow, equals(-31197.60));
      expect(snapshot.savings, equals(-31197.60));
    });

    test('TEST 2: Income = 50000, Expenses = 30000 -> Net Cash Flow = 20000', () {
      final transactions = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'income',
          amount: 5000000, // ₹50,000 in cents
          currency: 'INR',
          date: DateTime(2026, 8, 10),
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
          amount: 3000000, // ₹30,000 in cents
          currency: 'INR',
          date: DateTime(2026, 8, 12),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: transactions,
        accounts: [],
        selectedMonth: now,
      );

      expect(snapshot.income, equals(50000.0));
      expect(snapshot.expenses, equals(30000.0));
      expect(snapshot.netCashFlow, equals(20000.0));
      expect(snapshot.savings, equals(20000.0));
    });

    test('TEST 3: HDFC to SBI transfer is excluded from Income/Expense', () {
      final transactions = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'transfer',
          amount: 1000000, // ₹10,000 in cents
          currency: 'INR',
          date: DateTime(2026, 8, 10),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: transactions,
        accounts: [],
        selectedMonth: now,
      );

      expect(snapshot.income, equals(0.0));
      expect(snapshot.expenses, equals(0.0));
    });

    test('TEST 4: Credit card purchase is counted as expense', () {
      final transactions = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'credit_card_purchase',
          amount: 500000, // ₹5,000 in cents
          currency: 'INR',
          date: DateTime(2026, 8, 10),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: transactions,
        accounts: [],
        selectedMonth: now,
      );

      expect(snapshot.expenses, equals(5000.0));
      expect(snapshot.income, equals(0.0));
    });

    test('TEST 5: Credit card bill payment is excluded from expense', () {
      final transactions = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'credit_card_payment',
          amount: 500000, // ₹5,000 in cents
          currency: 'INR',
          date: DateTime(2026, 8, 10),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: transactions,
        accounts: [],
        selectedMonth: now,
      );

      expect(snapshot.expenses, equals(0.0));
      expect(snapshot.income, equals(0.0));
    });

    test('TEST 6: Dashboard and AI Chat receive identical values', () {
      final transactions = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'income',
          amount: 3820300,
          currency: 'INR',
          date: DateTime(2026, 8, 10),
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
          amount: 6940060,
          currency: 'INR',
          date: DateTime(2026, 8, 12),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: transactions,
        accounts: [],
        selectedMonth: now,
      );

      expect(snapshot.income, equals(38203.00));
      expect(snapshot.expenses, equals(69400.60));
      expect(snapshot.netCashFlow, equals(-31197.60));
      expect(snapshot.savings, equals(-31197.60));
    });

    test('TEST 7 & 8: Add / Delete transaction updates values consistently', () {
      final transactions = [
        Transaction(
          id: 'tx1',
          userId: 'user1',
          type: 'income',
          amount: 5000000,
          currency: 'INR',
          date: DateTime(2026, 8, 10),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      var snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: transactions,
        accounts: [],
        selectedMonth: now,
      );

      expect(snapshot.income, equals(50000.0));
      expect(snapshot.expenses, equals(0.0));

      transactions.add(
        Transaction(
          id: 'tx2',
          userId: 'user1',
          type: 'expense',
          amount: 2000000,
          currency: 'INR',
          date: DateTime(2026, 8, 12),
          source: 'manual',
          isRecurring: false,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: transactions,
        accounts: [],
        selectedMonth: now,
      );

      expect(snapshot.income, equals(50000.0));
      expect(snapshot.expenses, equals(20000.0));
      expect(snapshot.netCashFlow, equals(30000.0));

      transactions.removeLast();

      snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: transactions,
        accounts: [],
        selectedMonth: now,
      );

      expect(snapshot.income, equals(50000.0));
      expect(snapshot.expenses, equals(0.0));
      expect(snapshot.netCashFlow, equals(50000.0));
    });
  });
}
