import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;
import '../database/app_database.dart';
import '../../features/expenses/presentation/providers/expense_provider.dart';
import '../../features/dashboard/presentation/screens/privacy_settings_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class ParserAgentResult {
  final double amount;
  final String merchant;
  final String currency;
  final DateTime date;
  final String category;
  final String paymentMethod;
  final String type; // 'expense' or 'income'
  final double confidence;

  ParserAgentResult({
    required this.amount,
    required this.merchant,
    required this.currency,
    required this.date,
    required this.category,
    required this.paymentMethod,
    required this.type,
    required this.confidence,
  });

  @override
  String toString() {
    return 'ParserAgentResult(amount: $amount, merchant: $merchant, currency: $currency, date: $date, category: $category, paymentMethod: $paymentMethod, type: $type, confidence: $confidence)';
  }
}

class ParserAgent {
  final Ref _ref;
  final AppDatabase _db;

  ParserAgent(this._ref, this._db);

  static const Map<String, String> keywordToCategory = {
    'starbucks': 'Food', 'mcdonald': 'Food', 'swiggy': 'Food', 'zomato': 'Food', 'hotel': 'Food', 'cafe': 'Food', 'restaurant': 'Food', 'kfc': 'Food', 'burger': 'Food',
    'uber': 'Transport', 'ola': 'Transport', 'metro': 'Transport', 'auto': 'Transport', 'cab': 'Transport', 'fuel': 'Transport', 'petrol': 'Transport', 'shell': 'Transport',
    'amazon': 'Shopping', 'flipkart': 'Shopping', 'zara': 'Shopping', 'myntra': 'Shopping', 'shopping': 'Shopping', 'store': 'Shopping', 'mart': 'Shopping', 'mall': 'Shopping',
    'hospital': 'Healthcare', 'pharmacy': 'Healthcare', 'apollo': 'Healthcare', 'clinic': 'Healthcare', 'medical': 'Healthcare', 'doctor': 'Healthcare', 'dentist': 'Healthcare',
    'netflix': 'Entertainment', 'spotify': 'Entertainment', 'prime': 'Entertainment', 'hotstar': 'Entertainment', 'movie': 'Entertainment', 'pvr': 'Entertainment', 'cinema': 'Entertainment',
    'electricity': 'Utilities', 'water': 'Utilities', 'gas': 'Utilities', 'power': 'Utilities', 'internet': 'Utilities', 'wifi': 'Utilities',
    'school': 'Education', 'college': 'Education', 'tuition': 'Education', 'course': 'Education', 'udemy': 'Education', 'book': 'Education', 'library': 'Education',
    'makemytrip': 'Travel', 'irctc': 'Travel', 'flight': 'Travel', 'train': 'Travel', 'hotel stay': 'Travel', 'indigo': 'Travel', 'airbnb': 'Travel',
    'zerodha': 'Investments', 'groww': 'Investments', 'mutual fund': 'Investments', 'stocks': 'Investments', 'etf': 'Investments',
    'lic': 'Insurance', 'hdfc ergo': 'Insurance', 'insurance': 'Insurance', 'medical insurance': 'Insurance',
    'bill': 'Bills', 'recharge': 'Bills', 'postpaid': 'Bills', 'mobile bill': 'Bills',
    'salary': 'Salary', 'dividend': 'Salary', 'refund': 'Salary', 'freelance': 'Salary',
  };

  static final RegExp _amountRegExp = RegExp(r'(?:rs\.?|inr|₹|\$|usd)\s*([\d,]+\.?\d*)', caseSensitive: false);
  static final RegExp _dateRegExp = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})');

  Future<ParserAgentResult?> parseText(String text, {String? defaultType}) async {
    final privacyMode = _ref.read(aiPrivacyModeProvider);
    dev.log('ParserAgent: Parsing using privacy mode: $privacyMode');

    // 1. Run Local Pre-checks or Local Rule Engine first
    final localResult = await _parseLocally(text, defaultType);

    // If local parsing resolves with high confidence or privacy is local-only, return it
    if (privacyMode == 'local' || (localResult != null && localResult.confidence >= 0.85)) {
      await _logDecision('LOCAL_RULE_ENGINE', localResult, text);
      return localResult;
    }

    // 2. Cloud NLP Fallback
    try {
      final nlpService = _ref.read(nlpServiceProvider);
      final cloudParsed = await nlpService.parseExpense(text);

      if (cloudParsed != null) {
        final result = ParserAgentResult(
          amount: cloudParsed.amount,
          merchant: cloudParsed.merchant ?? 'General Merchant',
          currency: 'INR',
          date: _parseDateTime(cloudParsed.date),
          category: _normalizeCategory(cloudParsed.category),
          paymentMethod: 'UPI', // Default fallback
          type: cloudParsed.type,
          confidence: cloudParsed.confidence,
        );
        await _logDecision('CLOUD_GEMINI_NLP', result, text);
        return result;
      }
    } catch (e) {
      dev.log('ParserAgent: Cloud NLP failed: $e. Falling back to local rules.');
    }

    // 3. Fallback to local parsing results if Cloud NLP failed/errored
    if (localResult != null) {
      await _logDecision('LOCAL_RULE_ENGINE_FALLBACK', localResult, text);
    }
    return localResult;
  }

  Future<ParserAgentResult?> _parseLocally(String text, String? defaultType) async {
    final lowerText = text.toLowerCase();
    
    // Amount extraction
    double? amount;
    final amtMatch = _amountRegExp.firstMatch(text);
    if (amtMatch != null) {
      amount = double.tryParse(amtMatch.group(1)!.replaceAll(',', ''));
    } else {
      // Look for plain numbers followed by spaces/words
      final plainAmtRegex = RegExp(r'\b([\d,]+\.\d{2})\b');
      final plainAmtMatch = plainAmtRegex.firstMatch(text);
      if (plainAmtMatch != null) {
        amount = double.tryParse(plainAmtMatch.group(1)!.replaceAll(',', ''));
      }
    }

    if (amount == null || amount <= 0) {
      return null;
    }

    // Category & Merchant classification
    String category = 'Shopping'; // Default fallback
    String merchant = 'General Merchant';
    double confidenceSum = 0.50;

    // Search keywords
    for (final entry in keywordToCategory.entries) {
      if (lowerText.contains(entry.key)) {
        category = entry.value;
        merchant = entry.key[0].toUpperCase() + entry.key.substring(1);
        confidenceSum += 0.35;
        break;
      }
    }

    // Payment Method extraction
    String paymentMethod = 'UPI'; // Default
    if (lowerText.contains('credit card') || lowerText.contains('card ending')) {
      paymentMethod = 'Credit Card';
    } else if (lowerText.contains('debit card') || lowerText.contains('atm')) {
      paymentMethod = 'Debit Card';
    } else if (lowerText.contains('cash')) {
      paymentMethod = 'Cash';
    } else if (lowerText.contains('net banking') || lowerText.contains('bank transfer')) {
      paymentMethod = 'Net Banking';
    }

    // Date extraction
    DateTime transactionDate = DateTime.now();
    final dateMatch = _dateRegExp.firstMatch(text);
    if (dateMatch != null) {
      try {
        final day = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        var year = int.parse(dateMatch.group(3)!);
        if (year < 100) {
          year += 2000;
        }
        transactionDate = DateTime(year, month, day);
      } catch (_) {}
    }

    // Transaction Type
    String type = defaultType ?? 'expense';
    if (lowerText.contains('credited') || lowerText.contains('received') || lowerText.contains('salary')) {
      type = 'income';
    }

    return ParserAgentResult(
      amount: amount,
      merchant: merchant,
      currency: lowerText.contains('\$') || lowerText.contains('usd') ? 'USD' : 'INR',
      date: transactionDate,
      category: category,
      paymentMethod: paymentMethod,
      type: type,
      confidence: confidenceSum.clamp(0.0, 1.0),
    );
  }

  DateTime _parseDateTime(String dateStr) {
    if (dateStr.toLowerCase() == 'today' || dateStr.toLowerCase() == 'now') {
      return DateTime.now();
    }
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        // Try dd/MM/yyyy
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }
    return DateTime.now();
  }

  String _normalizeCategory(String rawCat) {
    final lower = rawCat.toLowerCase();
    if (lower.contains('food') || lower.contains('restaurant') || lower.contains('eat')) return 'Food';
    if (lower.contains('transport') || lower.contains('cab') || lower.contains('fuel')) return 'Transport';
    if (lower.contains('shopping') || lower.contains('zara') || lower.contains('mart')) return 'Shopping';
    if (lower.contains('health') || lower.contains('medical') || lower.contains('hospital')) return 'Healthcare';
    if (lower.contains('entertainment') || lower.contains('movie') || lower.contains('netflix')) return 'Entertainment';
    if (lower.contains('utility') || lower.contains('electricity') || lower.contains('water')) return 'Utilities';
    if (lower.contains('education') || lower.contains('course') || lower.contains('book')) return 'Education';
    if (lower.contains('travel') || lower.contains('trip') || lower.contains('flight')) return 'Travel';
    if (lower.contains('invest')) return 'Investments';
    if (lower.contains('insurance')) return 'Insurance';
    if (lower.contains('bill')) return 'Bills';
    if (lower.contains('salary')) return 'Salary';
    if (lower.contains('transfer')) return 'Transfer';
    return 'Shopping';
  }

  Future<void> _logDecision(String modelType, ParserAgentResult? result, String text) async {
    try {
      await _db.agentLogDao.insertLog(
        AgentLog(
          id: const Uuid().v4(),
          agentName: 'Transaction Parser Agent',
          actionType: 'TEXT_PARSED',
          decisionDescription: 'Parsed text using $modelType. Success: ${result != null}. Details: $result. Source text preview: ${text.length > 60 ? "${text.substring(0, 60)}..." : text}',
          confidenceScore: result?.confidence ?? 0.0,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      dev.log('ParserAgent: Failed to insert agent log: $e');
    }
  }
}

final Provider<ParserAgent> parserAgentProvider = Provider<ParserAgent>((ref) {
  final db = ref.watch(databaseProvider);
  return ParserAgent(ref, db);
});
