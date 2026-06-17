import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/expenses/domain/repositories/expense_repository.dart';
import 'package:app/features/expenses/domain/usecases/create_transaction_usecase.dart';
import 'package:app/features/expenses/domain/usecases/delete_transaction_usecase.dart';
import 'package:app/features/expenses/domain/usecases/update_transaction_usecase.dart';
import 'package:app/features/expenses/domain/usecases/get_transactions_usecase.dart';
import 'package:app/features/expenses/domain/usecases/get_categories_usecase.dart';
import 'package:app/features/expenses/domain/usecases/get_payment_methods_usecase.dart';

class MockExpenseRepository extends Fake implements ExpenseRepository {
  final List<Transaction> transactions = [];
  bool getCategoriesCalled = false;
  bool getPaymentMethodsCalled = false;

  @override
  Future<void> createTransaction(Transaction transaction) async {
    transactions.add(transaction);
  }

  @override
  Future<void> softDeleteTransaction(String id) async {
    transactions.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
    }
  }

  @override
  Future<List<Transaction>> getTransactionsForUser(String userId) async {
    return transactions.where((t) => t.userId == userId).toList();
  }

  @override
  Future<List<Category>> getCategoriesForUser(String userId) async {
    getCategoriesCalled = true;
    return [];
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethodsForUser(String userId) async {
    getPaymentMethodsCalled = true;
    return [];
  }
}

void main() {
  group('Expense Use Cases Tests', () {
    late MockExpenseRepository repository;

    setUp(() {
      repository = MockExpenseRepository();
    });

    test('CreateTransactionUseCase adds transaction to repo', () async {
      final useCase = CreateTransactionUseCase(repository);
      final tx = Transaction(
        id: 'tx-1',
        userId: 'user-123',
        type: 'expense',
        amount: 25000,
        currency: 'INR',
        date: DateTime.now(),
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await useCase.execute(tx);
      expect(repository.transactions.length, equals(1));
      expect(repository.transactions.first.id, equals('tx-1'));
    });

    test('DeleteTransactionUseCase removes transaction from repo', () async {
      final createUseCase = CreateTransactionUseCase(repository);
      final deleteUseCase = DeleteTransactionUseCase(repository);
      final tx = Transaction(
        id: 'tx-1',
        userId: 'user-123',
        type: 'expense',
        amount: 25000,
        currency: 'INR',
        date: DateTime.now(),
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await createUseCase.execute(tx);
      expect(repository.transactions.length, equals(1));

      await deleteUseCase.execute('tx-1');
      expect(repository.transactions, isEmpty);
    });

    test('UpdateTransactionUseCase modifies transaction in repo', () async {
      final createUseCase = CreateTransactionUseCase(repository);
      final updateUseCase = UpdateTransactionUseCase(repository);
      
      final tx = Transaction(
        id: 'tx-1',
        userId: 'user-123',
        type: 'expense',
        amount: 25000,
        currency: 'INR',
        date: DateTime.now(),
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await createUseCase.execute(tx);
      
      final updatedTx = tx.copyWith(amount: 50000);
      await updateUseCase.execute(updatedTx);

      expect(repository.transactions.first.amount, equals(50000));
    });

    test('GetTransactionsUseCase fetches transactions by user', () async {
      final useCase = GetTransactionsUseCase(repository);
      
      repository.transactions.add(Transaction(
        id: 'tx-1',
        userId: 'user-123',
        type: 'expense',
        amount: 25000,
        currency: 'INR',
        date: DateTime.now(),
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      repository.transactions.add(Transaction(
        id: 'tx-2',
        userId: 'other-user',
        type: 'expense',
        amount: 35000,
        currency: 'INR',
        date: DateTime.now(),
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final list = await useCase.execute('user-123');
      expect(list.length, equals(1));
      expect(list.first.id, equals('tx-1'));
    });

    test('GetCategoriesUseCase calls getCategories in repo', () async {
      final useCase = GetCategoriesUseCase(repository);
      await useCase.execute('user-123');
      expect(repository.getCategoriesCalled, isTrue);
    });

    test('GetPaymentMethodsUseCase calls getPaymentMethods in repo', () async {
      final useCase = GetPaymentMethodsUseCase(repository);
      await useCase.execute('user-123');
      expect(repository.getPaymentMethodsCalled, isTrue);
    });
  });
}
