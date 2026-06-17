import '../../../../core/database/app_database.dart';

abstract class ExpenseRepository {
  // Accounts
  Future<List<Account>> getAccountsForUser(String userId);
  Future<Account?> getAccountById(String id);
  Future<Account?> getDefaultAccount(String userId);
  Future<void> createAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(String id);

  // Categories
  Future<List<Category>> getCategoriesForUser(String userId);
  Future<Category?> getCategoryById(String id);
  Future<void> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<void> incrementCategoryUsage(String categoryId);

  // Payment Methods
  Future<List<PaymentMethod>> getPaymentMethodsForUser(String userId);
  Future<PaymentMethod?> getPaymentMethodById(String id);
  Future<void> createPaymentMethod(PaymentMethod paymentMethod);
  Future<void> updatePaymentMethod(PaymentMethod paymentMethod);
  Future<void> deletePaymentMethod(String id);

  // Transactions
  Future<List<Transaction>> getTransactionsForUser(String userId);
  Future<Transaction?> getTransactionById(String id);
  Future<List<Transaction>> getPendingSyncTransactions();
  Future<void> createTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> softDeleteTransaction(String id);
  Future<void> hardDeleteTransaction(String id);
}
