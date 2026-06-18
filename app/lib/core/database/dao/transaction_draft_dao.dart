import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transaction_drafts.dart';

part 'transaction_draft_dao.g.dart';

@DriftAccessor(tables: [TransactionDrafts])
class TransactionDraftDao extends DatabaseAccessor<AppDatabase> with _$TransactionDraftDaoMixin {
  TransactionDraftDao(super.db);

  Stream<List<TransactionDraft>> watchDraftsForUser(String userId) =>
      (select(transactionDrafts)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
      .watch();

  Future<List<TransactionDraft>> getDraftsForUser(String userId) =>
      (select(transactionDrafts)..where((t) => t.userId.equals(userId))).get();

  Future<TransactionDraft?> getDraftById(String id) =>
      (select(transactionDrafts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<bool> hasSmsBeenProcessed(String originalSmsId) async {
    if (originalSmsId.isEmpty) return false;
    final query = select(transactionDrafts)..where((t) => t.originalSmsId.equals(originalSmsId));
    final results = await query.get();
    return results.isNotEmpty;
  }

  Future<void> insertDraft(TransactionDraft draft) => into(transactionDrafts).insert(draft, mode: InsertMode.insertOrIgnore);
  Future<void> deleteDraft(String id) => (delete(transactionDrafts)..where((t) => t.id.equals(id))).go();
  Future<void> clearAllDraftsForUser(String userId) => (delete(transactionDrafts)..where((t) => t.userId.equals(userId))).go();
}
