import '../../../../core/database/app_database.dart';

abstract class ChatRepository {
  Future<List<ChatHistoryItem>> getChatHistory(String userId);
  Future<void> saveMessage({
    required String userId,
    required String role,
    required String message,
    required String aiMode,
  });
  Future<String> sendMessageToAssistant(String message, String? context);
  Future<void> clearHistory(String userId);
  Future<List<AiMemoryItem>> getMemories(String userId);
  Future<void> deleteMemory(String id);
}
