import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/chat_history.dart';

part 'chat_history_dao.g.dart';

@DriftAccessor(tables: [ChatHistory])
class ChatHistoryDao extends DatabaseAccessor<AppDatabase> with _$ChatHistoryDaoMixin {
  ChatHistoryDao(super.db);

  Future<List<ChatHistoryItem>> getChatHistory(String userId) =>
      (select(chatHistory)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
      .get();

  Future<void> insertChatItem(ChatHistoryItem item) => into(chatHistory).insert(item);
  
  Future<int> clearChatHistory(String userId) =>
      (delete(chatHistory)..where((t) => t.userId.equals(userId))).go();
}
