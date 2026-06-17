import '../../domain/repositories/expense_repository.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/dao/account_dao.dart';
import '../../../../core/database/dao/category_dao.dart';
import '../../../../core/database/dao/payment_method_dao.dart';
import '../../../../core/database/dao/transaction_dao.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final AccountDao _accountDao;
  final CategoryDao _categoryDao;
  final PaymentMethodDao _paymentMethodDao;
  final TransactionDao _transactionDao;

  ExpenseRepositoryImpl(
    this._accountDao,
    this._categoryDao,
    this._paymentMethodDao,
    this._transactionDao,
  );

  // Accounts
  @override
  Future<List<Account>> getAccountsForUser(String userId) => _accountDao.getAccountsForUser(userId);

  @override
  Future<Account?> getAccountById(String id) => _accountDao.getAccountById(id);

  @override
  Future<Account?> getDefaultAccount(String userId) => _accountDao.getDefaultAccount(userId);

  @override
  Future<void> createAccount(Account account) => _accountDao.insertAccount(account);

  @override
  Future<void> updateAccount(Account account) => _accountDao.updateAccount(account);

  @override
  Future<void> deleteAccount(String id) => _accountDao.deleteAccount(id);

  // Categories
  @override
  Future<List<Category>> getCategoriesForUser(String userId) => _categoryDao.getCategoriesForUser(userId);

  @override
  Future<Category?> getCategoryById(String id) => _categoryDao.getCategoryById(id);

  @override
  Future<void> createCategory(Category category) => _categoryDao.insertCategory(category);

  @override
  Future<void> updateCategory(Category category) => _categoryDao.updateCategory(category);

  @override
  Future<void> deleteCategory(String id) => _categoryDao.deleteCategory(id);

  @override
  Future<void> incrementCategoryUsage(String categoryId) => _categoryDao.incrementCategoryUsage(categoryId);

  // Payment Methods
  @override
  Future<List<PaymentMethod>> getPaymentMethodsForUser(String userId) => _paymentMethodDao.getPaymentMethodsForUser(userId);

  @override
  Future<PaymentMethod?> getPaymentMethodById(String id) => _paymentMethodDao.getPaymentMethodById(id);

  @override
  Future<void> createPaymentMethod(PaymentMethod paymentMethod) => _paymentMethodDao.insertPaymentMethod(paymentMethod);

  @override
  Future<void> updatePaymentMethod(PaymentMethod paymentMethod) => _paymentMethodDao.updatePaymentMethod(paymentMethod);

  @override
  Future<void> deletePaymentMethod(String id) => _paymentMethodDao.deletePaymentMethod(id);

  // Transactions
  @override
  Future<List<Transaction>> getTransactionsForUser(String userId) => _transactionDao.getTransactionsForUser(userId);

  @override
  Future<Transaction?> getTransactionById(String id) => _transactionDao.getTransactionById(id);

  @override
  Future<List<Transaction>> getPendingSyncTransactions() => _transactionDao.getPendingSyncTransactions();

  @override
  Future<void> createTransaction(Transaction transaction) => _transactionDao.insertTransaction(transaction);

  @override
  Future<void> updateTransaction(Transaction transaction) => _transactionDao.updateTransaction(transaction);

  @override
  Future<void> softDeleteTransaction(String id) => _transactionDao.softDeleteTransaction(id);

  @override
  Future<void> hardDeleteTransaction(String id) => _transactionDao.hardDeleteTransaction(id);
}
