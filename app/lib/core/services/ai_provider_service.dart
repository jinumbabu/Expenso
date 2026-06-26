import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/privacy_settings_screen.dart';
import 'dart:developer' as dev;

abstract class AiProviderService {
  Future<String> generateText(String prompt, {String? systemInstruction});
}

class GeminiProviderService implements AiProviderService {
  final Dio _dio;
  GeminiProviderService(this._dio);

  @override
  Future<String> generateText(String prompt, {String? systemInstruction}) async {
    try {
      final response = await _dio.post(
        '/ai/chat',
        data: {
          'message': prompt,
          'context': systemInstruction,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['reply'] as String;
      }
    } catch (e) {
      dev.log('GeminiProviderService: Error calling backend AI endpoint: $e');
    }
    return '';
  }
}

class OpenAIProviderService implements AiProviderService {
  // ignore: unused_field
  final Dio _dio;
  OpenAIProviderService(this._dio);

  @override
  Future<String> generateText(String prompt, {String? systemInstruction}) async {
    // Simulated/Mock implementation of OpenAI GPT call
    dev.log('OpenAIProviderService: Generating text for prompt');
    return 'OpenAI GPT response: Simulated analysis for: $prompt';
  }
}

class ClaudeProviderService implements AiProviderService {
  // ignore: unused_field
  final Dio _dio;
  ClaudeProviderService(this._dio);

  @override
  Future<String> generateText(String prompt, {String? systemInstruction}) async {
    // Simulated/Mock implementation of Claude call
    dev.log('ClaudeProviderService: Generating text for prompt');
    return 'Claude response: Simulated analysis for: $prompt';
  }
}

class AiProviderManager {
  final Ref _ref;

  AiProviderManager(this._ref);

  Future<String> analyzeWithActiveProvider(String prompt, {String? systemInstruction, String provider = 'gemini'}) async {
    final privacyMode = _ref.read(privacyModeProvider);
    if (privacyMode == 'local') {
      return 'LOCAL_MODE';
    }

    try {
      final client = _ref.read(dioClientProvider);
      AiProviderService activeService;
      switch (provider.toLowerCase()) {
        case 'openai':
          activeService = OpenAIProviderService(client.dio);
          break;
        case 'claude':
          activeService = ClaudeProviderService(client.dio);
          break;
        case 'gemini':
        default:
          activeService = GeminiProviderService(client.dio);
          break;
      }

      final response = await activeService.generateText(prompt, systemInstruction: systemInstruction);
      if (response.isEmpty) {
        return 'LOCAL_MODE'; // fallback to local analysis if error or network down
      }
      return response;
    } catch (e) {
      dev.log('AiProviderManager: Exception calling provider: $e');
      return 'LOCAL_MODE';
    }
  }
}

final Provider<AiProviderManager> aiProviderManagerProvider = Provider<AiProviderManager>((ref) {
  return AiProviderManager(ref);
});
