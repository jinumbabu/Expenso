import 'ai_models.dart';

abstract class AIProvider {
  Future<AIResponse> chat(
    String message,
    FinancialContext context,
  );

  Future<bool> validateApiKey();

  Future<List<AIModel>> getAvailableModels();
}
