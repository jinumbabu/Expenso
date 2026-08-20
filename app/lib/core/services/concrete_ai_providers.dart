import 'dart:convert';
import 'package:dio/dio.dart';
import 'ai_models.dart';
import 'ai_provider.dart';

const String _systemInstruction = 
  'You are Expenso AI, a secure and private financial assistant. '
  'You help users understand their spending, budgets, income, savings, and financial health. '
  'You only have access to the de-identified, summarized context provided by the app. '
  'Do not ask for or assume any personally identifiable details, account numbers, or card numbers. '
  'Always keep your answers concise, structured, and helpful. Use INR (₹) as the primary currency. '
  'CRITICAL: You must NEVER invent or recalculate financial values. All financial totals (income, expenses, net cash flow, savings, credit card outstanding, carry forward, and category spending) MUST be read exactly as provided in the de-identified structured context. Do NOT try to sum or calculate them yourself unless requested for a specific analytical question that requires mathematical operations not present in the context. If you are asked about these metrics, directly explain or state the values from the context.\n'
  'CRITICAL: Do NOT automatically include a full financial summary (balance, income, expenses, savings, health score) in your response unless the user explicitly asks for a "financial summary", "monthly summary", "report", or similar. For normal questions regarding bills, transactions, budgets, analytics, or spending, respond directly and concisely to the query without listing the entire financial summary context.\n'
  'When organizing financial breakdowns or reporting metrics, structure your response logically using headings, sections, and bullets. '
  'Always use the following visual formatting and icons to highlight key financial metrics/areas:\n'
  '- 💰 Income (Green)\n'
  '- 💸 Expenses (Red)\n'
  '- 🏦 Balance (Blue)\n'
  '- 📊 Budget (Purple)\n'
  '- 📅 Bills (Orange)\n'
  '- 🎯 Goals (Cyan)\n'
  '- ⭐ Health Score (Yellow)\n'
  'Avoid large text paragraphs; present insights in a premium, organized form with lists, cards (markdown style), or tables where applicable.';

// Helper to extract error message from DioException
String _parseDioError(DioException e) {
  if (e.response != null) {
    try {
      final data = e.response!.data;
      if (data is Map) {
        if (data['error'] != null) {
          final err = data['error'];
          if (err is Map && err['message'] != null) {
            return err['message'].toString();
          }
          if (err is String) return err;
          return jsonEncode(err);
        }
      }
    } catch (_) {}
    return 'HTTP Error ${e.response!.statusCode}: ${e.response!.statusMessage}';
  }
  return e.message ?? e.toString();
}

class OfflineAIProvider implements AIProvider {
  @override
  Future<AIResponse> chat(String message, FinancialContext context) async {
    // A helpful rule-based offline parsing fallback response
    final lower = message.toLowerCase();
    String reply = '';
    if (lower.contains('balance') || lower.contains('savings') || lower.contains('income') || lower.contains('spend')) {
      reply = 'Expenso Offline AI Summary:\n\n'
          '- **Current Balance**: ₹${context.currentBalance.toStringAsFixed(2)}\n'
          '- **Monthly Income**: ₹${context.monthlyIncome.toStringAsFixed(2)}\n'
          '- **Monthly Expenses**: ₹${context.monthlyExpenses.toStringAsFixed(2)}\n'
          '- **Savings**: ₹${context.savings.toStringAsFixed(2)}\n'
          '- **Financial Health Score**: ${context.healthScore}/100\n\n'
          'To query detailed insights, please enable an Online AI Provider in AI Settings.';
    } else {
      reply = 'I am operating in Offline AI Mode to protect your privacy. '
          'Under offline mode, I can access your local database summaries, budget thresholds, and trends. '
          'To get deeper conversational analysis or ask open-ended questions, please enable Google Gemini, OpenAI, Claude, or another provider in AI Settings and add your API key.';
    }

    return AIResponse(
      reply: reply,
      providerName: 'Offline AI',
      badgeText: 'Offline',
    );
  }

  @override
  Future<bool> validateApiKey() async => true;

  @override
  Future<List<AIModel>> getAvailableModels() async {
    return [
      const AIModel(id: 'offline-ai', name: 'Offline AI'),
    ];
  }
}

class GeminiAIProvider implements AIProvider {
  final Dio _dio;
  final String apiKey;
  final String model;

  GeminiAIProvider({required Dio dio, required this.apiKey, required this.model}) : _dio = dio;

  @override
  Future<AIResponse> chat(String message, FinancialContext context) async {
    try {
      final prompt = '${context.toPromptString()}\n\nUser Question: $message';
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'systemInstruction': {
            'parts': [
              {'text': _systemInstruction}
            ]
          }
        },
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          if (content != null) {
            final parts = content['parts'] as List;
            if (parts.isNotEmpty) {
              return AIResponse(
                reply: parts[0]['text'] as String,
                providerName: 'Google Gemini ($model)',
                badgeText: model.contains('pro') ? 'Premium Model' : 'Connected',
              );
            }
          }
        }
      }
      throw Exception('Empty or malformed response from Gemini API.');
    } on DioException catch (e) {
      throw Exception('Gemini API Error: ${_parseDioError(e)}');
    }
  }

  @override
  Future<bool> validateApiKey() async {
    try {
      final response = await _dio.get(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Validation failed: ${_parseDioError(e)}');
    }
  }

  @override
  Future<List<AIModel>> getAvailableModels() async {
    return [
      const AIModel(id: 'gemini-2.5-flash', name: 'Gemini 2.5 Flash'),
      const AIModel(id: 'gemini-2.5-pro', name: 'Gemini 2.5 Pro', isPremium: true),
      const AIModel(id: 'gemini-2.0-flash', name: 'Gemini 2.0 Flash'),
      const AIModel(id: 'gemini-2.0-flash-lite', name: 'Gemini 2.0 Flash Lite'),
    ];
  }
}

class OpenAIProvider implements AIProvider {
  final Dio _dio;
  final String apiKey;
  final String model;

  OpenAIProvider({required Dio dio, required this.apiKey, required this.model}) : _dio = dio;

  @override
  Future<AIResponse> chat(String message, FinancialContext context) async {
    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': _systemInstruction},
            {'role': 'user', 'content': '${context.toPromptString()}\n\nUser Question: $message'},
          ],
        },
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List;
        if (choices.isNotEmpty) {
          final reply = choices[0]['message']['content'] as String;
          return AIResponse(
            reply: reply,
            providerName: 'OpenAI ($model)',
            badgeText: (model.contains('gpt-5') && !model.contains('mini') && !model.contains('nano')) || model == 'gpt-4.1'
                ? 'Premium Model'
                : 'Connected',
          );
        }
      }
      throw Exception('Empty or malformed response from OpenAI API.');
    } on DioException catch (e) {
      throw Exception('OpenAI API Error: ${_parseDioError(e)}');
    }
  }

  @override
  Future<bool> validateApiKey() async {
    try {
      final response = await _dio.get(
        'https://api.openai.com/v1/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Validation failed: ${_parseDioError(e)}');
    }
  }

  @override
  Future<List<AIModel>> getAvailableModels() async {
    return [
      const AIModel(id: 'gpt-5', name: 'GPT-5', isPremium: true),
      const AIModel(id: 'gpt-5-mini', name: 'GPT-5 Mini'),
      const AIModel(id: 'gpt-5-nano', name: 'GPT-5 Nano'),
      const AIModel(id: 'gpt-4.1', name: 'GPT-4.1', isPremium: true),
      const AIModel(id: 'gpt-4.1-mini', name: 'GPT-4.1 Mini'),
    ];
  }
}

class ClaudeProvider implements AIProvider {
  final Dio _dio;
  final String apiKey;
  final String model;

  ClaudeProvider({required Dio dio, required this.apiKey, required this.model}) : _dio = dio;

  @override
  Future<AIResponse> chat(String message, FinancialContext context) async {
    try {
      final response = await _dio.post(
        'https://api.anthropic.com/v1/messages',
        options: Options(headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        }),
        data: {
          'model': model,
          'system': _systemInstruction,
          'messages': [
            {'role': 'user', 'content': '${context.toPromptString()}\n\nUser Question: $message'},
          ],
          'max_tokens': 1024,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['content'] as List;
        if (content.isNotEmpty) {
          final reply = content[0]['text'] as String;
          return AIResponse(
            reply: reply,
            providerName: 'Claude ($model)',
            badgeText: model.contains('opus') ? 'Premium Model' : 'Connected',
          );
        }
      }
      throw Exception('Empty or malformed response from Claude API.');
    } on DioException catch (e) {
      throw Exception('Claude API Error: ${_parseDioError(e)}');
    }
  }

  @override
  Future<bool> validateApiKey() async {
    try {
      // Validate by doing a 1-token message generation request
      final response = await _dio.post(
        'https://api.anthropic.com/v1/messages',
        options: Options(headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        }),
        data: {
          'model': 'claude-3-5-sonnet-20241022',
          'messages': [
            {'role': 'user', 'content': 'test'}
          ],
          'max_tokens': 1,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Validation failed: ${_parseDioError(e)}');
    }
  }

  @override
  Future<List<AIModel>> getAvailableModels() async {
    return [
      const AIModel(id: 'claude-4-sonnet', name: 'Claude Sonnet 4'),
      const AIModel(id: 'claude-4-opus', name: 'Claude Opus 4', isPremium: true),
    ];
  }
}

class GroqProvider implements AIProvider {
  final Dio _dio;
  final String apiKey;
  final String model;

  GroqProvider({required Dio dio, required this.apiKey, required this.model}) : _dio = dio;

  @override
  Future<AIResponse> chat(String message, FinancialContext context) async {
    try {
      final response = await _dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': _systemInstruction},
            {'role': 'user', 'content': '${context.toPromptString()}\n\nUser Question: $message'},
          ],
        },
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List;
        if (choices.isNotEmpty) {
          final reply = choices[0]['message']['content'] as String;
          return AIResponse(
            reply: reply,
            providerName: 'Groq ($model)',
            badgeText: model.contains('llama-4') ? 'Premium Model' : 'Connected',
          );
        }
      }
      throw Exception('Empty or malformed response from Groq API.');
    } on DioException catch (e) {
      throw Exception('Groq API Error: ${_parseDioError(e)}');
    }
  }

  @override
  Future<bool> validateApiKey() async {
    try {
      final response = await _dio.get(
        'https://api.groq.com/openai/v1/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Validation failed: ${_parseDioError(e)}');
    }
  }

  @override
  Future<List<AIModel>> getAvailableModels() async {
    return [
      const AIModel(id: 'llama-4', name: 'Llama 4', isPremium: true),
      const AIModel(id: 'llama-3.3-70b-specdec', name: 'Llama 3.3 70B'),
      const AIModel(id: 'deepseek-r1-distill-llama-70b', name: 'DeepSeek R1'),
      const AIModel(id: 'qwen-2.5-coder-32b', name: 'Qwen'),
    ];
  }
}

class OpenRouterProvider implements AIProvider {
  final Dio _dio;
  final String apiKey;
  final String model;

  OpenRouterProvider({required Dio dio, required this.apiKey, required this.model}) : _dio = dio;

  @override
  Future<AIResponse> chat(String message, FinancialContext context) async {
    try {
      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://expenso.app',
          'X-Title': 'Expenso App',
        }),
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': _systemInstruction},
            {'role': 'user', 'content': '${context.toPromptString()}\n\nUser Question: $message'},
          ],
        },
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List;
        if (choices.isNotEmpty) {
          final reply = choices[0]['message']['content'] as String;
          return AIResponse(
            reply: reply,
            providerName: 'OpenRouter ($model)',
            badgeText: model.contains('pro') || model.contains('opus') || model.contains('gpt-4')
                ? 'Premium Model'
                : 'Connected',
          );
        }
      }
      throw Exception('Empty or malformed response from OpenRouter API.');
    } on DioException catch (e) {
      throw Exception('OpenRouter API Error: ${_parseDioError(e)}');
    }
  }

  @override
  Future<bool> validateApiKey() async {
    try {
      final response = await _dio.get(
        'https://openrouter.ai/api/v1/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Validation failed: ${_parseDioError(e)}');
    }
  }

  @override
  Future<List<AIModel>> getAvailableModels() async {
    return [
      const AIModel(id: 'google/gemini-2.5-pro', name: 'Gemini', isPremium: true),
      const AIModel(id: 'openai/gpt-4o', name: 'GPT'),
      const AIModel(id: 'anthropic/claude-3-5-sonnet', name: 'Claude'),
      const AIModel(id: 'deepseek/deepseek-chat', name: 'DeepSeek'),
      const AIModel(id: 'meta-llama/llama-3.1-70b-instruct', name: 'Llama'),
      const AIModel(id: 'mistralai/mistral-large', name: 'Mistral'),
      const AIModel(id: 'qwen/qwen-2.5-72b-instruct', name: 'Qwen'),
    ];
  }
}

class DeepSeekProvider implements AIProvider {
  final Dio _dio;
  final String apiKey;
  final String model;

  DeepSeekProvider({required Dio dio, required this.apiKey, required this.model}) : _dio = dio;

  @override
  Future<AIResponse> chat(String message, FinancialContext context) async {
    try {
      final response = await _dio.post(
        'https://api.deepseek.com/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': _systemInstruction},
            {'role': 'user', 'content': '${context.toPromptString()}\n\nUser Question: $message'},
          ],
        },
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List;
        if (choices.isNotEmpty) {
          final reply = choices[0]['message']['content'] as String;
          return AIResponse(
            reply: reply,
            providerName: 'DeepSeek ($model)',
            badgeText: model.contains('reasoner') ? 'Premium Model' : 'Connected',
          );
        }
      }
      throw Exception('Empty or malformed response from DeepSeek API.');
    } on DioException catch (e) {
      throw Exception('DeepSeek API Error: ${_parseDioError(e)}');
    }
  }

  @override
  Future<bool> validateApiKey() async {
    try {
      final response = await _dio.get(
        'https://api.deepseek.com/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Validation failed: ${_parseDioError(e)}');
    }
  }

  @override
  Future<List<AIModel>> getAvailableModels() async {
    return [
      const AIModel(id: 'deepseek-chat', name: 'DeepSeek Chat'),
      const AIModel(id: 'deepseek-reasoner', name: 'DeepSeek Reasoner', isPremium: true),
    ];
  }
}

class TogetherAIProvider implements AIProvider {
  final Dio _dio;
  final String apiKey;
  final String model;

  TogetherAIProvider({required Dio dio, required this.apiKey, required this.model}) : _dio = dio;

  @override
  Future<AIResponse> chat(String message, FinancialContext context) async {
    try {
      final response = await _dio.post(
        'https://api.together.xyz/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': _systemInstruction},
            {'role': 'user', 'content': '${context.toPromptString()}\n\nUser Question: $message'},
          ],
        },
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List;
        if (choices.isNotEmpty) {
          final reply = choices[0]['message']['content'] as String;
          return AIResponse(
            reply: reply,
            providerName: 'Together AI ($model)',
            badgeText: model.contains('V3') ? 'Premium Model' : 'Connected',
          );
        }
      }
      throw Exception('Empty or malformed response from Together AI API.');
    } on DioException catch (e) {
      throw Exception('Together AI API Error: ${_parseDioError(e)}');
    }
  }

  @override
  Future<bool> validateApiKey() async {
    try {
      final response = await _dio.get(
        'https://api.together.xyz/v1/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Validation failed: ${_parseDioError(e)}');
    }
  }

  @override
  Future<List<AIModel>> getAvailableModels() async {
    return [
      const AIModel(id: 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo', name: 'Llama 3.1 70B'),
      const AIModel(id: 'meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo', name: 'Llama 3.1 8B'),
      const AIModel(id: 'deepseek-ai/DeepSeek-V3', name: 'DeepSeek V3', isPremium: true),
    ];
  }
}

class MistralProvider implements AIProvider {
  final Dio _dio;
  final String apiKey;
  final String model;

  MistralProvider({required Dio dio, required this.apiKey, required this.model}) : _dio = dio;

  @override
  Future<AIResponse> chat(String message, FinancialContext context) async {
    try {
      final response = await _dio.post(
        'https://api.mistral.ai/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': _systemInstruction},
            {'role': 'user', 'content': '${context.toPromptString()}\n\nUser Question: $message'},
          ],
        },
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List;
        if (choices.isNotEmpty) {
          final reply = choices[0]['message']['content'] as String;
          return AIResponse(
            reply: reply,
            providerName: 'Mistral ($model)',
            badgeText: model.contains('large') ? 'Premium Model' : 'Connected',
          );
        }
      }
      throw Exception('Empty or malformed response from Mistral API.');
    } on DioException catch (e) {
      throw Exception('Mistral API Error: ${_parseDioError(e)}');
    }
  }

  @override
  Future<bool> validateApiKey() async {
    try {
      final response = await _dio.get(
        'https://api.mistral.ai/v1/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Validation failed: ${_parseDioError(e)}');
    }
  }

  @override
  Future<List<AIModel>> getAvailableModels() async {
    return [
      const AIModel(id: 'mistral-large-latest', name: 'Mistral Large', isPremium: true),
      const AIModel(id: 'mistral-medium-latest', name: 'Mistral Medium'),
      const AIModel(id: 'mistral-small-latest', name: 'Mistral Small'),
      const AIModel(id: 'open-mixtral-8x22b', name: 'Mixtral 8x22B'),
    ];
  }
}
