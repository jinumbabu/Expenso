import 'dart:convert';

class AIModel {
  final String id;
  final String name;
  final bool isPremium;

  const AIModel({
    required this.id,
    required this.name,
    this.isPremium = false,
  });
}

class SavedApiKey {
  final String id;
  final String provider; // 'gemini', 'openai', 'claude', 'groq', 'openrouter', 'deepseek', 'together', 'mistral'
  final String nickname;
  final String key;
  final String selectedModel;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final DateTime? lastValidatedAt;
  final String validationStatus; // 'valid', 'invalid', 'not_tested'
  final int latencyMs;

  SavedApiKey({
    required this.id,
    required this.provider,
    required this.nickname,
    required this.key,
    required this.selectedModel,
    required this.createdAt,
    this.lastUsedAt,
    this.lastValidatedAt,
    required this.validationStatus,
    required this.latencyMs,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider,
    'nickname': nickname,
    'key': key,
    'selectedModel': selectedModel,
    'createdAt': createdAt.toIso8601String(),
    'lastUsedAt': lastUsedAt?.toIso8601String(),
    'lastValidatedAt': lastValidatedAt?.toIso8601String(),
    'validationStatus': validationStatus,
    'latencyMs': latencyMs,
  };

  factory SavedApiKey.fromJson(Map<String, dynamic> json) => SavedApiKey(
    id: json['id'] as String,
    provider: json['provider'] as String,
    nickname: json['nickname'] as String,
    key: json['key'] as String,
    selectedModel: json['selectedModel'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastUsedAt: json['lastUsedAt'] != null ? DateTime.parse(json['lastUsedAt'] as String) : null,
    lastValidatedAt: json['lastValidatedAt'] != null ? DateTime.parse(json['lastValidatedAt'] as String) : null,
    validationStatus: json['validationStatus'] as String? ?? 'not_tested',
    latencyMs: json['latencyMs'] as int? ?? 0,
  );

  SavedApiKey copyWith({
    String? nickname,
    String? key,
    String? selectedModel,
    DateTime? lastUsedAt,
    DateTime? lastValidatedAt,
    String? validationStatus,
    int? latencyMs,
  }) {
    return SavedApiKey(
      id: id,
      provider: provider,
      nickname: nickname ?? this.nickname,
      key: key ?? this.key,
      selectedModel: selectedModel ?? this.selectedModel,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      lastValidatedAt: lastValidatedAt ?? this.lastValidatedAt,
      validationStatus: validationStatus ?? this.validationStatus,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }
}

class ApiKeyStats {
  final int requestsToday;
  final int totalResponseTimeMs;
  final DateTime? lastUsedAt;
  final int estimatedTokens;
  final String dateStr; // track requests per day

  ApiKeyStats({
    required this.requestsToday,
    required this.totalResponseTimeMs,
    this.lastUsedAt,
    required this.estimatedTokens,
    required this.dateStr,
  });

  Map<String, dynamic> toJson() => {
    'requestsToday': requestsToday,
    'totalResponseTimeMs': totalResponseTimeMs,
    'lastUsedAt': lastUsedAt?.toIso8601String(),
    'estimatedTokens': estimatedTokens,
    'dateStr': dateStr,
  };

  factory ApiKeyStats.fromJson(Map<String, dynamic> json) => ApiKeyStats(
    requestsToday: json['requestsToday'] as int? ?? 0,
    totalResponseTimeMs: json['totalResponseTimeMs'] as int? ?? 0,
    lastUsedAt: json['lastUsedAt'] != null ? DateTime.parse(json['lastUsedAt'] as String) : null,
    estimatedTokens: json['estimatedTokens'] as int? ?? 0,
    dateStr: json['dateStr'] as String? ?? '',
  );

  double get averageResponseSec => requestsToday > 0 ? (totalResponseTimeMs / requestsToday) / 1000.0 : 0.0;

  String get connectionQuality {
    if (requestsToday == 0) return 'Not Tested';
    final avg = totalResponseTimeMs / requestsToday;
    if (avg < 250) return 'Excellent';
    if (avg < 500) return 'Good';
    if (avg < 1000) return 'Fair';
    return 'Poor';
  }
}

class AIResponse {
  final String reply;
  final String providerName;
  final String badgeText; // e.g. "Offline", "Connected", "API Valid", "Premium Model"
  final String? error;

  const AIResponse({
    required this.reply,
    required this.providerName,
    required this.badgeText,
    this.error,
  });
}

class FinancialContext {
  final double currentBalance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double savings;
  final String budgetStatus;
  final String upcomingBills;
  final int healthScore;
  final List<String> topSpendingCategories;
  final List<String> recentFinancialTrends;
  final String accountSummary;
  final double creditCardOutstanding;
  final double carryForward;
  final String period;

  const FinancialContext({
    required this.currentBalance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.savings,
    required this.budgetStatus,
    required this.upcomingBills,
    required this.healthScore,
    required this.topSpendingCategories,
    required this.recentFinancialTrends,
    required this.accountSummary,
    required this.creditCardOutstanding,
    required this.carryForward,
    required this.period,
  });

  String toPromptString() {
    final buffer = StringBuffer();
    buffer.writeln('=== FINANCIAL SUMMARY CONTEXT (DE-IDENTIFIED) ===');
    buffer.writeln('Period: $period');
    buffer.writeln('Current Balance (Net Cash Flow): INR ${currentBalance.toStringAsFixed(2)}');
    buffer.writeln('Monthly Income: INR ${monthlyIncome.toStringAsFixed(2)}');
    buffer.writeln('Monthly Expenses: INR ${monthlyExpenses.toStringAsFixed(2)}');
    buffer.writeln('Savings: INR ${savings.toStringAsFixed(2)}');
    buffer.writeln('Carry Forward: INR ${carryForward.toStringAsFixed(2)}');
    buffer.writeln('Credit Card Outstanding: INR ${creditCardOutstanding.toStringAsFixed(2)}');
    buffer.writeln('Health Score (0-100): $healthScore');
    buffer.writeln('Budget Status: $budgetStatus');
    buffer.writeln('Upcoming Bills: $upcomingBills');
    buffer.writeln('Account Balances:\n$accountSummary');

    // Structured JSON block for the AI to parse/reference
    final Map<String, dynamic> structuredData = {
      "period": period,
      "income": double.parse(monthlyIncome.toStringAsFixed(2)),
      "expenses": double.parse(monthlyExpenses.toStringAsFixed(2)),
      "netCashFlow": double.parse(currentBalance.toStringAsFixed(2)),
      "savings": double.parse(savings.toStringAsFixed(2)),
      "creditCardOutstanding": double.parse(creditCardOutstanding.toStringAsFixed(2)),
      "carryForward": double.parse(carryForward.toStringAsFixed(2)),
    };
    buffer.writeln('STRUCTURED_DATA_JSON: ${jsonEncode(structuredData)}');
    
    buffer.writeln('Top Spending Categories:');
    if (topSpendingCategories.isEmpty) {
      buffer.writeln('- None recorded');
    } else {
      for (var category in topSpendingCategories) {
        buffer.writeln('- $category');
      }
    }

    buffer.writeln('Recent Financial Trends & Observations:');
    if (recentFinancialTrends.isEmpty) {
      buffer.writeln('- Stable spending patterns');
    } else {
      for (var trend in recentFinancialTrends) {
        buffer.writeln('- $trend');
      }
    }
    buffer.writeln('==================================================');
    return buffer.toString();
  }
}
