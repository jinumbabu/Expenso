import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/ai_memories.dart';

part 'ai_memory_dao.g.dart';

@DriftAccessor(tables: [AiMemories])
class AiMemoryDao extends DatabaseAccessor<AppDatabase> with _$AiMemoryDaoMixin {
  AiMemoryDao(super.db);

  Future<List<AiMemoryItem>> getMemories(String userId) =>
      (select(aiMemories)..where((t) => t.userId.equals(userId))).get();

  Future<List<AiMemoryItem>> getMemoriesByType(String userId, String type) =>
      (select(aiMemories)
        ..where((t) => t.userId.equals(userId) & t.memoryType.equals(type)))
      .get();

  Future<void> insertMemory(AiMemoryItem item) => into(aiMemories).insert(item);

  Future<bool> updateMemory(AiMemoryItem item) => update(aiMemories).replace(item);

  Future<int> deleteMemory(String id) =>
      (delete(aiMemories)..where((t) => t.id.equals(id))).go();

  Future<int> clearMemories(String userId) =>
      (delete(aiMemories)..where((t) => t.userId.equals(userId))).go();
}
