import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/ai_models.dart';
import 'package:app/core/services/concrete_ai_providers.dart';
import 'package:app/core/security/secure_storage_service.dart';
import 'package:app/core/services/ai_provider_orchestrator.dart';

class FakeRef extends Fake implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSecureStorageService implements SecureStorageService {
  final Map<String, String> _storage = {};

  @override
  Future<void> saveAiMode(String mode) async {
    _storage['ai_mode'] = mode;
  }

  @override
  Future<String?> getAiMode() async {
    return _storage['ai_mode'];
  }

  @override
  Future<void> saveAiProvider(String provider) async {
    _storage['ai_provider'] = provider;
  }

  @override
  Future<String?> getAiProvider() async {
    return _storage['ai_provider'];
  }

  @override
  Future<void> saveAiModel(String provider, String model) async {
    _storage['ai_model_$provider'] = model;
  }

  @override
  Future<String?> getAiModel(String provider) async {
    return _storage['ai_model_$provider'];
  }

  @override
  Future<void> saveApiKey(String provider, String key) async {
    _storage['api_key_$provider'] = key;
  }

  @override
  Future<String?> getApiKey(String provider) async {
    return _storage['api_key_$provider'];
  }

  @override
  Future<void> deleteApiKey(String provider) async {
    _storage.remove('api_key_$provider');
  }

  @override
  Future<void> deleteAiModel(String provider) async {
    _storage.remove('ai_model_$provider');
  }

  @override
  Future<void> saveSavedApiKeysJson(String provider, String jsonStr) async {
    _storage['api_keys_list_$provider'] = jsonStr;
  }

  @override
  Future<String?> getSavedApiKeysJson(String provider) async {
    return _storage['api_keys_list_$provider'];
  }

  @override
  Future<void> deleteSavedApiKeysJson(String provider) async {
    _storage.remove('api_keys_list_$provider');
  }

  @override
  Future<void> saveActiveKeyId(String provider, String keyId) async {
    _storage['active_key_id_$provider'] = keyId;
  }

  @override
  Future<String?> getActiveKeyId(String provider) async {
    return _storage['active_key_id_$provider'];
  }

  @override
  Future<void> deleteActiveKeyId(String provider) async {
    _storage.remove('active_key_id_$provider');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AI Provider Architecture Tests', () {
    test('OfflineAIProvider returns offline text and offline status details', () async {
      final provider = OfflineAIProvider();
      const context = FinancialContext(
        currentBalance: 5000.0,
        monthlyIncome: 10000.0,
        monthlyExpenses: 5000.0,
        savings: 5000.0,
        budgetStatus: 'Healthy',
        upcomingBills: 'None',
        healthScore: 85,
        topSpendingCategories: [],
        recentFinancialTrends: [],
        accountSummary: 'SBI Savings: ₹5,000.00\nHDFC Credit Card: -₹500.00',
      );

      final response = await provider.chat('What is my balance?', context);
      expect(response.providerName, equals('Offline AI'));
      expect(response.badgeText, equals('Offline'));
      expect(response.reply, contains('Expenso Offline AI Summary'));
      expect(response.reply, contains('₹5000.00'));
    });

    test('FinancialContext format is structured correctly', () {
      const context = FinancialContext(
        currentBalance: 5000.0,
        monthlyIncome: 10000.0,
        monthlyExpenses: 5000.0,
        savings: 5000.0,
        budgetStatus: 'Healthy',
        upcomingBills: 'None',
        healthScore: 85,
        topSpendingCategories: ['Food: ₹120.00'],
        recentFinancialTrends: ['Spending increased'],
        accountSummary: 'SBI Savings: ₹5,000.00\nHDFC Credit Card: -₹500.00',
      );

      final prompt = context.toPromptString();
      expect(prompt, contains('Current Balance: INR 5000.00'));
      expect(prompt, contains('Health Score (0-100): 85'));
      expect(prompt, contains('Food: ₹120.00'));
      expect(prompt, contains('Spending increased'));
    });

    test('Saved API Keys lifecycle', () async {
      final secureStorage = FakeSecureStorageService();
      final orchestrator = AiProviderOrchestrator(secureStorage, FakeRef());
      await orchestrator.initialize();

      expect(orchestrator.state.savedKeys, isEmpty);

      final key1 = SavedApiKey(
        id: 'gemini-1',
        provider: 'gemini',
        nickname: 'My Gemini Key',
        key: 'AIzaSyKey1',
        selectedModel: 'gemini-2.5-flash',
        createdAt: DateTime.now(),
        validationStatus: 'not_tested',
        latencyMs: 0,
      );

      await orchestrator.addSavedApiKey(key1);
      expect(orchestrator.state.savedKeys.length, equals(1));
      expect(orchestrator.state.savedKeys.first.nickname, equals('My Gemini Key'));
      expect(orchestrator.state.activeKeyIds['gemini'], equals('gemini-1'));

      await orchestrator.editSavedApiKey('gemini-1', 'My Updated Gemini Key', 'gemini-2.5-pro');
      expect(orchestrator.state.savedKeys.first.nickname, equals('My Updated Gemini Key'));
      expect(orchestrator.state.savedKeys.first.selectedModel, equals('gemini-2.5-pro'));

      await orchestrator.deleteSavedApiKey('gemini-1');
      expect(orchestrator.state.savedKeys, isEmpty);
      expect(orchestrator.state.activeKeyIds['gemini'], isNull);
    });

    test('Auto-fallback cascade selection logic', () async {
      final secureStorage = FakeSecureStorageService();
      final orchestrator = AiProviderOrchestrator(secureStorage, FakeRef());
      await orchestrator.initialize();

      final geminiKey = SavedApiKey(
        id: 'gemini-1',
        provider: 'gemini',
        nickname: 'Gemini Key',
        key: 'AIzaSyInvalid',
        selectedModel: 'gemini-2.5-flash',
        createdAt: DateTime.now(),
        validationStatus: 'invalid',
        latencyMs: 0,
      );
      final groqKey = SavedApiKey(
        id: 'groq-1',
        provider: 'groq',
        nickname: 'Groq Key',
        key: 'gsk_Valid',
        selectedModel: 'llama-4',
        createdAt: DateTime.now(),
        validationStatus: 'valid',
        latencyMs: 120,
      );

      await orchestrator.addSavedApiKey(geminiKey);
      await orchestrator.addSavedApiKey(groqKey);

      await orchestrator.setAiMode('online');
      await orchestrator.setAiProvider('gemini');

      final key = orchestrator.getActiveKeyForProvider('gemini');
      expect(key, isNotNull);
      expect(key!.id, equals('gemini-1'));

      final fallback = orchestrator.getFallbackProviderWithValidKey();
      expect(fallback, equals('groq'));
    });
  });
}
