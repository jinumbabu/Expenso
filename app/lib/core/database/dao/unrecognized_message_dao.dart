import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/unrecognized_messages.dart';

part 'unrecognized_message_dao.g.dart';

@DriftAccessor(tables: [UnrecognizedMessages])
class UnrecognizedMessageDao extends DatabaseAccessor<AppDatabase> with _$UnrecognizedMessageDaoMixin {
  UnrecognizedMessageDao(super.db);

  Future<List<UnrecognizedMessage>> getUnrecognizedMessagesForUser(String userId) =>
      (select(unrecognizedMessages)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Stream<List<UnrecognizedMessage>> watchUnrecognizedMessagesForUser(String userId) =>
      (select(unrecognizedMessages)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Future<void> insertUnrecognizedMessage(UnrecognizedMessage message) =>
      into(unrecognizedMessages).insert(message);

  Future<int> deleteUnrecognizedMessage(String id) =>
      (delete(unrecognizedMessages)..where((t) => t.id.equals(id))).go();

  Future<void> clearUnrecognizedMessages(String userId) =>
      (delete(unrecognizedMessages)..where((t) => t.userId.equals(userId))).go();
}
