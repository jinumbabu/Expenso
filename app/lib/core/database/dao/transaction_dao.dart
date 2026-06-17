import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<List<Transaction>> getTransactionsForUser(String userId) =>
      (select(transactions)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();

  Future<Transaction?> getTransactionById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Transaction>> getPendingSyncTransactions() =>
      (select(transactions)..where((t) => t.syncStatus.equals('pending') & t.deletedAt.isNull())).get();

  Future<void> insertTransaction(Transaction transaction) => into(transactions).insert(transaction);
  Future<bool> updateTransaction(Transaction transaction) => update(transactions).replace(transaction);
  
  Future<void> softDeleteTransaction(String id) async {
    final tx = await getTransactionById(id);
    if (tx != null) {
      final updated = tx.copyWith(
        deletedAt: Value(DateTime.now()),
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      );
      await updateTransaction(updated);
    }
  }

  Future<int> hardDeleteTransaction(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();
}
