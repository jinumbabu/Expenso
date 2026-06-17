import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/chat_repository.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/dao/chat_history_dao.dart';
import '../../../../core/database/dao/ai_memory_dao.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatHistoryDao _chatHistoryDao;
  final AiMemoryDao _aiMemoryDao;
  final Dio _dio;

  ChatRepositoryImpl(
    this._chatHistoryDao,
    this._aiMemoryDao,
    this._dio,
  );

  @override
  Future<List<ChatHistoryItem>> getChatHistory(String userId) =>
      _chatHistoryDao.getChatHistory(userId);

  @override
  Future<void> saveMessage({
    required String userId,
    required String role,
    required String message,
    required String aiMode,
  }) async {
    final chatItem = ChatHistoryItem(
      id: const Uuid().v4(),
      userId: userId,
      role: role,
      message: message,
      aiMode: aiMode,
      createdAt: DateTime.now(),
    );
    await _chatHistoryDao.insertChatItem(chatItem);
  }

  @override
  Future<String> sendMessageToAssistant(String message, String? context) async {
    try {
      final response = await _dio.post(
        '/ai/chat',
        data: {
          'message': message,
          'context': context,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['reply'] as String;
      }
      return 'Sorry, I encountered an issue. Please try again.';
    } catch (e) {
      return 'Network error: Please verify your connection to the Expenso backend server.';
    }
  }

  @override
  Future<void> clearHistory(String userId) => _chatHistoryDao.clearChatHistory(userId);

  @override
  Future<List<AiMemoryItem>> getMemories(String userId) => _aiMemoryDao.getMemories(userId);

  @override
  Future<void> deleteMemory(String id) => _aiMemoryDao.deleteMemory(id);
}
