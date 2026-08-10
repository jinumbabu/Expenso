import 'dart:convert';
import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../security/secure_storage_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/advisor/presentation/providers/advisor_provider.dart';
import 'ai_models.dart';
import 'ai_provider.dart';
import 'concrete_ai_providers.dart';
import 'financial_calculation_service.dart';

class AiProviderConfig {
  final String aiMode; // 'offline' or 'online'
  final String aiProvider; // 'offline', 'gemini', 'openai', 'claude', 'groq', 'openrouter', 'deepseek', 'together', 'mistral'
  final Map<String, String> selectedModels;
  final Map<String, bool> apiValid;
  final Map<String, int> apiLatency;
  final Map<String, String> apiError;
  final String? fallbackMessage;
  final List<SavedApiKey> savedKeys;
  final Map<String, String> activeKeyIds; // active key ID per provider
  final Map<String, ApiKeyStats> keyStats; // key stats per key ID

  const AiProviderConfig({
    required this.aiMode,
    required this.aiProvider,
    required this.selectedModels,
    required this.apiValid,
    required this.apiLatency,
    required this.apiError,
    this.fallbackMessage,
    this.savedKeys = const [],
    this.activeKeyIds = const {},
    this.keyStats = const {},
  });

  AiProviderConfig copyWith({
    String? aiMode,
    String? aiProvider,
    Map<String, String>? selectedModels,
    Map<String, bool>? apiValid,
    Map<String, int>? apiLatency,
    Map<String, String>? apiError,
    String? fallbackMessage,
    List<SavedApiKey>? savedKeys,
    Map<String, String>? activeKeyIds,
    Map<String, ApiKeyStats>? keyStats,
    bool clearFallback = false,
  }) {
    return AiProviderConfig(
      aiMode: aiMode ?? this.aiMode,
      aiProvider: aiProvider ?? this.aiProvider,
      selectedModels: selectedModels ?? this.selectedModels,
      apiValid: apiValid ?? this.apiValid,
      apiLatency: apiLatency ?? this.apiLatency,
      apiError: apiError ?? this.apiError,
      fallbackMessage: clearFallback ? null : (fallbackMessage ?? this.fallbackMessage),
      savedKeys: savedKeys ?? this.savedKeys,
      activeKeyIds: activeKeyIds ?? this.activeKeyIds,
      keyStats: keyStats ?? this.keyStats,
    );
  }
}

class AiProviderOrchestrator extends StateNotifier<AiProviderConfig> {
  final SecureStorageService _secureStorage;
  final Ref _ref;
  final Dio _dio = Dio();

  static const Map<String, String> _providerDisplayNames = {
    'offline': 'Offline AI',
    'gemini': 'Google Gemini',
    'openai': 'OpenAI',
    'claude': 'Claude',
    'groq': 'Groq',
    'openrouter': 'OpenRouter',
    'deepseek': 'DeepSeek',
    'together': 'Together AI',
    'mistral': 'Mistral',
  };

  AiProviderOrchestrator(this._secureStorage, this._ref)
      : super(const AiProviderConfig(
          aiMode: 'offline',
          aiProvider: 'offline',
          selectedModels: {},
          apiValid: {},
          apiLatency: {},
          apiError: {},
        )) {
    _loadSettings();
  }

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mode = await _secureStorage.getAiMode() ?? 'offline';
    final provider = await _secureStorage.getAiProvider() ?? 'offline';

    final models = <String, String>{};
    final valid = <String, bool>{};
    final latencies = <String, int>{};
    final errors = <String, String>{};
    final savedKeys = <SavedApiKey>[];
    final activeKeyIds = <String, String>{};
    final keyStats = <String, ApiKeyStats>{};

    final providersList = ['gemini', 'openai', 'claude', 'groq', 'openrouter', 'deepseek', 'together', 'mistral'];
    for (var p in providersList) {
      models[p] = await _secureStorage.getAiModel(p) ?? _getDefaultModel(p);
      
      // Load saved keys
      final keysJson = await _secureStorage.getSavedApiKeysJson(p);
      if (keysJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(keysJson);
          final parsed = decoded.map((k) => SavedApiKey.fromJson(k as Map<String, dynamic>)).toList();
          savedKeys.addAll(parsed);
        } catch (e) {
          debugPrint('Error decoding saved keys for $p: $e');
        }
      }

      // Check for active key ID
      final activeId = await _secureStorage.getActiveKeyId(p);
      if (activeId != null) {
        activeKeyIds[p] = activeId;
      } else {
        // Fallback: if there are saved keys, make the first one active
        final pKeys = savedKeys.where((k) => k.provider == p).toList();
        if (pKeys.isNotEmpty) {
          activeKeyIds[p] = pKeys.first.id;
          await _secureStorage.saveActiveKeyId(p, pKeys.first.id);
        }
      }

      // Legacy key import
      final legacyKey = await _secureStorage.getApiKey(p);
      final pKeys = savedKeys.where((k) => k.provider == p).toList();
      if (legacyKey != null && legacyKey.isNotEmpty && pKeys.isEmpty) {
        final newKey = SavedApiKey(
          id: 'legacy-$p',
          provider: p,
          nickname: 'Imported Key',
          key: legacyKey,
          selectedModel: models[p] ?? _getDefaultModel(p),
          createdAt: DateTime.now(),
          validationStatus: 'valid',
          latencyMs: 0,
        );
        savedKeys.add(newKey);
        activeKeyIds[p] = newKey.id;
        await _secureStorage.saveActiveKeyId(p, newKey.id);
        await _secureStorage.saveSavedApiKeysJson(p, jsonEncode([newKey.toJson()]));
      }
    }

    // Load Stats for each key
    for (var k in savedKeys) {
      final statsJson = await _secureStorage.getSavedApiKeysJson('stats_${k.id}');
      if (statsJson != null) {
        try {
          keyStats[k.id] = ApiKeyStats.fromJson(jsonDecode(statsJson));
        } catch (_) {}
      } else {
        keyStats[k.id] = ApiKeyStats(requestsToday: 0, totalResponseTimeMs: 0, estimatedTokens: 0, dateStr: '');
      }
    }

    // Populate validation status maps
    for (var p in providersList) {
      final activeKey = getActiveKeyForProvider(p, savedKeys, activeKeyIds);
      if (activeKey != null) {
        valid[p] = activeKey.validationStatus == 'valid';
        latencies[p] = activeKey.latencyMs;
      } else {
        valid[p] = false;
        latencies[p] = 0;
      }
    }

    state = AiProviderConfig(
      aiMode: mode,
      aiProvider: provider,
      selectedModels: models,
      apiValid: valid,
      apiLatency: latencies,
      apiError: errors,
      savedKeys: savedKeys,
      activeKeyIds: activeKeyIds,
      keyStats: keyStats,
    );
  }

  String _getDefaultModel(String provider) {
    switch (provider) {
      case 'gemini':
        return 'gemini-2.5-flash';
      case 'openai':
        return 'gpt-5-mini';
      case 'claude':
        return 'claude-4-sonnet';
      case 'groq':
        return 'llama-4';
      case 'openrouter':
        return 'google/gemini-2.5-pro';
      case 'deepseek':
        return 'deepseek-chat';
      case 'together':
        return 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo';
      case 'mistral':
        return 'mistral-large-latest';
      default:
        return 'offline-ai';
    }
  }

  SavedApiKey? getActiveKeyForProvider(String provider, [List<SavedApiKey>? keys, Map<String, String>? activeIds]) {
    final list = keys ?? state.savedKeys;
    final idsMap = activeIds ?? state.activeKeyIds;
    final activeId = idsMap[provider];
    if (activeId == null) {
      return null;
    }
    final matched = list.where((k) => k.id == activeId).toList();
    if (matched.isNotEmpty) {
      return matched.first;
    }
    return null;
  }

  String? getFallbackProviderWithValidKey() {
    final onlineProviders = ['gemini', 'openai', 'claude', 'groq', 'openrouter', 'deepseek', 'together', 'mistral'];
    for (var fallbackProv in onlineProviders) {
      final fbKey = getActiveKeyForProvider(fallbackProv);
      if (fbKey != null && fbKey.validationStatus == 'valid' && fbKey.key.trim().isNotEmpty) {
        return fallbackProv;
      }
    }
    return null;
  }

  Future<void> addSavedApiKey(SavedApiKey newKey) async {
    final provider = newKey.provider;
    final newSavedKeys = List<SavedApiKey>.from(state.savedKeys)..add(newKey);
    final providerKeys = newSavedKeys.where((k) => k.provider == provider).toList();

    await _secureStorage.saveSavedApiKeysJson(provider, jsonEncode(providerKeys.map((k) => k.toJson()).toList()));

    // Make active if it is the first key or explicitly default
    final activeKeyId = state.activeKeyIds[provider];
    final updatedActiveIds = Map<String, String>.from(state.activeKeyIds);
    if (activeKeyId == null || providerKeys.length == 1) {
      updatedActiveIds[provider] = newKey.id;
      await _secureStorage.saveActiveKeyId(provider, newKey.id);
    }

    state = state.copyWith(
      savedKeys: newSavedKeys,
      activeKeyIds: updatedActiveIds,
    );
    await _loadSettings();
  }

  Future<void> editSavedApiKey(String keyId, String nickname, String model) async {
    final keyIndex = state.savedKeys.indexWhere((k) => k.id == keyId);
    if (keyIndex == -1) return;

    final key = state.savedKeys[keyIndex];
    final updatedKey = key.copyWith(nickname: nickname, selectedModel: model);

    final newSavedKeys = List<SavedApiKey>.from(state.savedKeys)..[keyIndex] = updatedKey;
    final providerKeys = newSavedKeys.where((k) => k.provider == key.provider).toList();

    await _secureStorage.saveSavedApiKeysJson(key.provider, jsonEncode(providerKeys.map((k) => k.toJson()).toList()));

    state = state.copyWith(savedKeys: newSavedKeys);
    await _loadSettings();
  }

  Future<void> deleteSavedApiKey(String keyId) async {
    final keyIndex = state.savedKeys.indexWhere((k) => k.id == keyId);
    if (keyIndex == -1) return;

    final key = state.savedKeys[keyIndex];
    final newSavedKeys = List<SavedApiKey>.from(state.savedKeys)..removeAt(keyIndex);
    final providerKeys = newSavedKeys.where((k) => k.provider == key.provider).toList();

    await _secureStorage.saveSavedApiKeysJson(key.provider, jsonEncode(providerKeys.map((k) => k.toJson()).toList()));

    final updatedActiveIds = Map<String, String>.from(state.activeKeyIds);
    if (state.activeKeyIds[key.provider] == keyId) {
      if (providerKeys.isNotEmpty) {
        updatedActiveIds[key.provider] = providerKeys.first.id;
        await _secureStorage.saveActiveKeyId(key.provider, providerKeys.first.id);
      } else {
        updatedActiveIds.remove(key.provider);
        await _secureStorage.deleteActiveKeyId(key.provider);
      }
    }

    state = state.copyWith(
      savedKeys: newSavedKeys,
      activeKeyIds: updatedActiveIds,
    );
    await _loadSettings();
  }

  Future<void> duplicateSavedApiKey(String keyId) async {
    final keyIndex = state.savedKeys.indexWhere((k) => k.id == keyId);
    if (keyIndex == -1) return;

    final key = state.savedKeys[keyIndex];
    final duplicated = SavedApiKey(
      id: 'copy-${DateTime.now().millisecondsSinceEpoch}',
      provider: key.provider,
      nickname: '${key.nickname} Copy',
      key: key.key,
      selectedModel: key.selectedModel,
      createdAt: DateTime.now(),
      validationStatus: key.validationStatus,
      latencyMs: key.latencyMs,
    );

    await addSavedApiKey(duplicated);
  }

  Future<void> setActiveKey(String provider, String keyId) async {
    await _secureStorage.saveActiveKeyId(provider, keyId);
    final updatedActiveIds = Map<String, String>.from(state.activeKeyIds)..[provider] = keyId;

    state = state.copyWith(activeKeyIds: updatedActiveIds);
    await _loadSettings();
  }

  Future<bool> validateKey(String keyId) async {
    final keyIndex = state.savedKeys.indexWhere((k) => k.id == keyId);
    if (keyIndex == -1) return false;
    final savedKey = state.savedKeys[keyIndex];
    final provider = savedKey.provider;
    
    final stopwatch = Stopwatch()..start();
    bool isSuccess = false;
    String errText = '';
    
    try {
      final modelToUse = savedKey.selectedModel.isNotEmpty ? savedKey.selectedModel : _getDefaultModel(provider);
      final AIProvider providerInstance = _createProviderInstance(provider, savedKey.key, modelToUse);
      isSuccess = await providerInstance.validateApiKey();
      stopwatch.stop();
    } catch (e) {
      stopwatch.stop();
      isSuccess = false;
      errText = e.toString().replaceAll('Exception:', '').trim();
    }
    
    final updatedKey = savedKey.copyWith(
      validationStatus: isSuccess ? 'valid' : 'invalid',
      latencyMs: isSuccess ? stopwatch.elapsedMilliseconds : 0,
      lastValidatedAt: DateTime.now(),
    );
    
    final newSavedKeys = List<SavedApiKey>.from(state.savedKeys)..[keyIndex] = updatedKey;
    final providerKeys = newSavedKeys.where((k) => k.provider == provider).toList();
    await _secureStorage.saveSavedApiKeysJson(provider, jsonEncode(providerKeys.map((k) => k.toJson()).toList()));
    
    // Update stats if validation runs
    await _updateUsageStats(keyId, isSuccess ? stopwatch.elapsedMilliseconds : 0, 0);

    state = state.copyWith(savedKeys: newSavedKeys);
    await _loadSettings();
    return isSuccess;
  }

  String exportKeys() {
    final exportData = state.savedKeys.map((k) => k.toJson()).toList();
    return jsonEncode(exportData);
  }

  Future<void> importKeys(String exportJson) async {
    try {
      final List<dynamic> decoded = jsonDecode(exportJson);
      final imported = decoded.map((k) => SavedApiKey.fromJson(k as Map<String, dynamic>)).toList();
      
      final providers = <String>{};
      for (var key in imported) {
        providers.add(key.provider);
        final existingIdx = state.savedKeys.indexWhere((k) => k.key == key.key && k.provider == key.provider);
        if (existingIdx != -1) {
          state.savedKeys[existingIdx] = key;
        } else {
          state.savedKeys.add(key);
        }
      }

      for (var p in providers) {
        final pKeys = state.savedKeys.where((k) => k.provider == p).toList();
        await _secureStorage.saveSavedApiKeysJson(p, jsonEncode(pKeys.map((k) => k.toJson()).toList()));
      }
      
      await _loadSettings();
    } catch (e) {
      throw Exception('Import failed: invalid key payload.');
    }
  }

  Future<void> setAiMode(String mode) async {
    await _secureStorage.saveAiMode(mode);
    state = state.copyWith(aiMode: mode);
  }

  Future<void> setAiProvider(String provider) async {
    await _secureStorage.saveAiProvider(provider);
    state = state.copyWith(aiProvider: provider);
  }

  Future<void> setAiModel(String provider, String model) async {
    await _secureStorage.saveAiModel(provider, model);
    final updatedModels = Map<String, String>.from(state.selectedModels)..[provider] = model;
    
    // Also update selected model in active key
    final activeKey = getActiveKeyForProvider(provider);
    if (activeKey != null) {
      await editSavedApiKey(activeKey.id, activeKey.nickname, model);
    }

    state = state.copyWith(selectedModels: updatedModels);
  }

  Future<void> clearFallbackMessage() async {
    state = state.copyWith(clearFallback: true);
  }

  AIProvider _createProviderInstance(String provider, String apiKey, String model) {
    switch (provider) {
      case 'gemini':
        return GeminiAIProvider(dio: _dio, apiKey: apiKey, model: model);
      case 'openai':
        return OpenAIProvider(dio: _dio, apiKey: apiKey, model: model);
      case 'claude':
        return ClaudeProvider(dio: _dio, apiKey: apiKey, model: model);
      case 'groq':
        return GroqProvider(dio: _dio, apiKey: apiKey, model: model);
      case 'openrouter':
        return OpenRouterProvider(dio: _dio, apiKey: apiKey, model: model);
      case 'deepseek':
        return DeepSeekProvider(dio: _dio, apiKey: apiKey, model: model);
      case 'together':
        return TogetherAIProvider(dio: _dio, apiKey: apiKey, model: model);
      case 'mistral':
        return MistralProvider(dio: _dio, apiKey: apiKey, model: model);
      default:
        return OfflineAIProvider();
    }
  }

  int _estimateTokens(String text) {
    return (text.length / 4).round();
  }

  Future<void> _updateUsageStats(String keyId, int responseTimeMs, int estimatedTokens) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month}-${now.day}';
    
    ApiKeyStats stats;
    final statsJson = await _secureStorage.getSavedApiKeysJson('stats_$keyId');
    if (statsJson != null) {
      try {
        final parsed = ApiKeyStats.fromJson(jsonDecode(statsJson));
        if (parsed.dateStr == dateStr) {
          stats = ApiKeyStats(
            requestsToday: parsed.requestsToday + 1,
            totalResponseTimeMs: parsed.totalResponseTimeMs + responseTimeMs,
            lastUsedAt: now,
            estimatedTokens: parsed.estimatedTokens + estimatedTokens,
            dateStr: dateStr,
          );
        } else {
          stats = ApiKeyStats(
            requestsToday: 1,
            totalResponseTimeMs: responseTimeMs,
            lastUsedAt: now,
            estimatedTokens: estimatedTokens,
            dateStr: dateStr,
          );
        }
      } catch (_) {
        stats = ApiKeyStats(
          requestsToday: 1,
          totalResponseTimeMs: responseTimeMs,
          lastUsedAt: now,
          estimatedTokens: estimatedTokens,
          dateStr: dateStr,
        );
      }
    } else {
      stats = ApiKeyStats(
        requestsToday: 1,
        totalResponseTimeMs: responseTimeMs,
        lastUsedAt: now,
        estimatedTokens: estimatedTokens,
        dateStr: dateStr,
      );
    }
    
    await _secureStorage.saveSavedApiKeysJson('stats_$keyId', jsonEncode(stats.toJson()));
    
    final newStatsMap = Map<String, ApiKeyStats>.from(state.keyStats)..[keyId] = stats;
    state = state.copyWith(keyStats: newStatsMap);
  }

  Future<AIResponse> getChatResponse(String message, String userId) async {
    final context = await compileFinancialContext(userId);
    final offlineProvider = OfflineAIProvider();

    // 1. Offline Mode explicitly selected
    if (state.aiMode == 'offline' || state.aiProvider == 'offline') {
      return await offlineProvider.chat(message, context);
    }

    // 2. Check Internet connectivity
    bool isConnected = true;
    try {
      final lookupResult = await InternetAddress.lookup('google.com');
      if (lookupResult.isEmpty || lookupResult[0].rawAddress.isEmpty) {
        isConnected = false;
      }
    } catch (_) {
      isConnected = false;
    }

    if (!isConnected) {
      dev.log('AiProviderOrchestrator: No internet connection. Falling back to Offline AI.');
      final offlineRes = await offlineProvider.chat(message, context);
      return AIResponse(
        reply: offlineRes.reply,
        providerName: 'Offline AI (Offline Fallback)',
        badgeText: 'Offline Fallback',
        error: 'No internet connection. Operating offline.',
      );
    }

    final activeProvider = state.aiProvider;
    final activeModel = state.selectedModels[activeProvider] ?? _getDefaultModel(activeProvider);
    final activeKey = getActiveKeyForProvider(activeProvider);

    // 3. API Key not present
    if (activeKey == null || activeKey.key.trim().isEmpty) {
      dev.log('AiProviderOrchestrator: Missing API Key for $activeProvider. Trying fallback chain.');
      return await _executeFallbackChain(message, context, userId, activeProvider);
    }

    // 4. Try execution of selected Online AI Provider
    try {
      final stopwatch = Stopwatch()..start();
      final clientProvider = _createProviderInstance(activeProvider, activeKey.key, activeModel);
      final response = await clientProvider.chat(message, context);
      stopwatch.stop();

      final totalTokens = _estimateTokens(message) + _estimateTokens(response.reply);
      await _updateUsageStats(activeKey.id, stopwatch.elapsedMilliseconds, totalTokens);

      return response;
    } catch (e) {
      dev.log('AiProviderOrchestrator: Call to $activeProvider failed: $e. Entering fallback chain.');
      return await _executeFallbackChain(message, context, userId, activeProvider);
    }
  }

  Future<AIResponse> _executeFallbackChain(
    String message,
    FinancialContext context,
    String userId,
    String failedProvider,
  ) async {
    final onlineProviders = ['gemini', 'openai', 'claude', 'groq', 'openrouter', 'deepseek', 'together', 'mistral'];
    final offlineProvider = OfflineAIProvider();

    for (var fallbackProv in onlineProviders) {
      if (fallbackProv == failedProvider) continue;

      final fbKey = getActiveKeyForProvider(fallbackProv);
      if (fbKey != null && fbKey.validationStatus == 'valid' && fbKey.key.trim().isNotEmpty) {
        try {
          dev.log('AiProviderOrchestrator: Auto-fallback: Trying $fallbackProv...');
          final fbModel = state.selectedModels[fallbackProv] ?? _getDefaultModel(fallbackProv);
          final stopwatch = Stopwatch()..start();
          final clientProvider = _createProviderInstance(fallbackProv, fbKey.key, fbModel);
          final response = await clientProvider.chat(message, context);
          stopwatch.stop();

          final totalTokens = _estimateTokens(message) + _estimateTokens(response.reply);
          await _updateUsageStats(fbKey.id, stopwatch.elapsedMilliseconds, totalTokens);

          // Switch active provider
          await setAiProvider(fallbackProv);

          // Set fallback message for UI display
          state = state.copyWith(
            fallbackMessage: '${_providerDisplayNames[failedProvider] ?? failedProvider} is currently unavailable. Switched to ${_providerDisplayNames[fallbackProv] ?? fallbackProv} automatically.',
          );

          return response;
        } catch (e) {
          dev.log('AiProviderOrchestrator: Fallback to $fallbackProv failed: $e');
        }
      }
    }

    // All failed: fall back to Offline AI
    dev.log('AiProviderOrchestrator: All fallbacks failed. Falling back to Offline AI.');
    final offlineRes = await offlineProvider.chat(message, context);
    await setAiMode('offline');
    await setAiProvider('offline');

    state = state.copyWith(
      fallbackMessage: '${_providerDisplayNames[failedProvider] ?? failedProvider} is currently unavailable. Switched to Offline AI automatically.',
    );

    return AIResponse(
      reply: offlineRes.reply,
      providerName: 'Offline AI (Offline Fallback)',
      badgeText: 'Offline Fallback',
      error: 'All Online API providers failed.',
    );
  }

  Future<FinancialContext> compileFinancialContext(String userId) async {
    final db = _ref.read(databaseProvider);
    final advisorState = _ref.read(advisorProvider);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final transactions = await db.transactionDao.getTransactionsForUser(userId);
    final currentMonthTxs = transactions.where((tx) => tx.date.isAfter(startOfMonth) || tx.date.isAtSameMomentAs(startOfMonth)).toList();

    final categories = await db.categoryDao.getCategoriesForUser(userId);
    final categoriesMap = {for (var c in categories) c.id: c};
    final budgets = await db.budgetDao.getBudgetsForUser(userId);

    final financialData = FinancialCalculationService.calculate(
      transactions: transactions,
      selectedMonth: now,
    );
    int totalIncome = financialData.monthlyIncome;
    int totalExpense = financialData.monthlyExpenses;
    final categorySpending = <String, int>{};

    for (var tx in currentMonthTxs) {
      if (FinancialCalculationService.isExpense(tx)) {
        final catName = categoriesMap[tx.categoryId]?.name ?? 'Uncategorized';
        categorySpending[catName] = (categorySpending[catName] ?? 0) + tx.amount;
      }
    }

    final double incomeVal = totalIncome / 100.0;
    final double expenseVal = totalExpense / 100.0;
    final double netVal = incomeVal - expenseVal;

    final budgetBuffer = StringBuffer();
    if (budgets.isEmpty) {
      budgetBuffer.write('No active budgets configured.');
    } else {
      for (var budget in budgets) {
        final catName = categoriesMap[budget.categoryId]?.name ?? 'Total';
        final limit = budget.amount / 100.0;
        int spent = 0;
        for (var tx in currentMonthTxs) {
          if (tx.categoryId == budget.categoryId && tx.type == 'expense') {
            spent += tx.amount;
          }
        }
        final spentVal = spent / 100.0;
        final remaining = limit - spentVal;
        budgetBuffer.write('$catName Category: (Limit ₹$limit, Spent ₹$spentVal, Remaining ₹$remaining); ');
      }
    }

    final upcomingBills = await (db.select(db.transactions)
      ..where((t) => t.userId.equals(userId) & 
                     (t.type.equals('upcoming_bill') | t.type.equals('credit_card_bill') | t.type.equals('credit_card_bill_reminder')) & 
                     t.billStatus.equals('pending'))
    ).get();

    final billBuffer = StringBuffer();
    if (upcomingBills.isEmpty) {
      billBuffer.write('No pending upcoming bills detected.');
    } else {
      for (var bill in upcomingBills) {
        final amt = bill.amount / 100.0;
        final merchant = bill.merchant ?? bill.description ?? 'Bill';
        billBuffer.write('$merchant: ₹$amt due ${bill.dueDate?.toIso8601String().substring(0, 10) ?? "soon"}; ');
      }
    }

    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(3).map((e) => '${e.key}: ₹${(e.value / 100.0).toStringAsFixed(2)}').toList();

    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = startOfMonth.subtract(const Duration(milliseconds: 1));
    final lastMonthTxs = transactions.where((tx) => tx.date.isAfter(lastMonthStart) && tx.date.isBefore(lastMonthEnd)).toList();
    int lastMonthExpense = 0;
    for (var tx in lastMonthTxs) {
      if (tx.type == 'expense') {
        lastMonthExpense += tx.amount;
      }
    }
    final double lastMonthExpenseVal = lastMonthExpense / 100.0;

    final trends = <String>[];
    if (expenseVal > lastMonthExpenseVal && lastMonthExpenseVal > 0) {
      final diff = expenseVal - lastMonthExpenseVal;
      trends.add('Monthly expenses increased by ₹${diff.toStringAsFixed(2)} compared to last month.');
    } else if (expenseVal < lastMonthExpenseVal && lastMonthExpenseVal > 0) {
      final diff = lastMonthExpenseVal - expenseVal;
      trends.add('Frugal behavior: Monthly expenses decreased by ₹${diff.toStringAsFixed(2)} compared to last month.');
    }
    if (incomeVal > 0 && expenseVal / incomeVal > 0.8) {
      trends.add('Caution: Spending accounts for over 80% of your active income this month.');
    }

    return FinancialContext(
      currentBalance: netVal,
      monthlyIncome: incomeVal,
      monthlyExpenses: expenseVal,
      savings: netVal,
      budgetStatus: budgetBuffer.toString(),
      upcomingBills: billBuffer.toString(),
      healthScore: advisorState.healthScore,
      topSpendingCategories: topCategories,
      recentFinancialTrends: trends,
    );
  }
}

final StateNotifierProvider<AiProviderOrchestrator, AiProviderConfig> aiProviderOrchestratorProvider =
    StateNotifierProvider<AiProviderOrchestrator, AiProviderConfig>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AiProviderOrchestrator(secureStorage, ref);
});
