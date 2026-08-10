import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/expenses/presentation/providers/expense_provider.dart';
import '../../features/accounts/presentation/providers/accounts_provider.dart';
import 'ledger_agent.dart';

class ParsedLine {
  final String rawText;
  double? amount; // amount in rupees
  String? category;
  String? subcategory;
  String? merchant;
  String type; // 'expense', 'income', 'transfer', 'credit_card_payment', 'upcoming_bill'
  String? accountName;
  String? accountType; // 'cash', 'bank', 'credit_card'
  DateTime? dueDate;
  String? error;
  String? warning;
  String? suggestion;
  bool isDuplicate;
  String duplicateAction; // 'skip', 'replace', 'keep'
  String? existingTxId; // For replacement
  String? paymentMethod;
  double confidence;

  ParsedLine({
    required this.rawText,
    this.amount,
    this.category,
    this.subcategory,
    this.merchant,
    required this.type,
    this.accountName,
    this.accountType,
    this.dueDate,
    this.error,
    this.warning,
    this.suggestion,
    this.isDuplicate = false,
    this.duplicateAction = 'keep',
    this.existingTxId,
    this.paymentMethod,
    this.confidence = 1.0,
  });

  ParsedLine copyWith({
    String? rawText,
    double? amount,
    String? category,
    String? subcategory,
    String? merchant,
    String? type,
    String? accountName,
    String? accountType,
    DateTime? dueDate,
    String? error,
    String? warning,
    String? suggestion,
    bool? isDuplicate,
    String? duplicateAction,
    String? existingTxId,
    String? paymentMethod,
    double? confidence,
  }) {
    return ParsedLine(
      rawText: rawText ?? this.rawText,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      merchant: merchant ?? this.merchant,
      type: type ?? this.type,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      dueDate: dueDate ?? this.dueDate,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      suggestion: suggestion ?? this.suggestion,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      duplicateAction: duplicateAction ?? this.duplicateAction,
      existingTxId: existingTxId ?? this.existingTxId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      confidence: confidence ?? this.confidence,
    );
  }
}

class QuickAddNotepadService {
  final Ref _ref;
  final AppDatabase _db;

  QuickAddNotepadService(this._ref) : _db = _ref.read(databaseProvider);

  /// Main entry point to parse a full block of multiline text offline.
  List<ParsedLine> parseDocument(String documentText) {
    final lines = documentText.split('\n');
    final List<ParsedLine> results = [];

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      results.add(parseLine(line));
    }
    return results;
  }

  DateTime parseRelativeDate(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();
    
    if (lower.contains('today')) {
      return now;
    }
    if (lower.contains('yesterday')) {
      return now.subtract(const Duration(days: 1));
    }
    if (lower.contains('tomorrow')) {
      return now.add(const Duration(days: 1));
    }
    
    final daysAgoRegex = RegExp(r'(\d+)\s+days?\s+ago');
    final daysAgoMatch = daysAgoRegex.firstMatch(lower);
    if (daysAgoMatch != null) {
      final days = int.tryParse(daysAgoMatch.group(1) ?? '') ?? 0;
      return now.subtract(Duration(days: days));
    }

    final weeksAgoRegex = RegExp(r'(\d+)\s+weeks?\s+ago');
    final weeksAgoMatch = weeksAgoRegex.firstMatch(lower);
    if (weeksAgoMatch != null) {
      final weeks = int.tryParse(weeksAgoMatch.group(1) ?? '') ?? 0;
      return now.subtract(Duration(days: weeks * 7));
    }

    if (lower.contains('last month')) {
      return DateTime(now.year, now.month - 1, now.day);
    }

    final weekdays = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };
    
    for (var entry in weekdays.entries) {
      if (lower.contains('last ${entry.key}')) {
        int diff = now.weekday - entry.value;
        if (diff <= 0) diff += 7;
        return now.subtract(Duration(days: diff));
      }
      if (lower.contains('next ${entry.key}')) {
        int diff = entry.value - now.weekday;
        if (diff <= 0) diff += 7;
        return now.add(Duration(days: diff));
      }
    }

    final months = {
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'september': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
    };

    final dayMonthRegex = RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)?\s+([a-z]{3,})\b');
    final dmMatch = dayMonthRegex.firstMatch(lower);
    if (dmMatch != null) {
      final day = int.tryParse(dmMatch.group(1) ?? '') ?? 1;
      final mStr = dmMatch.group(2) ?? '';
      final month = months[mStr] ?? months[mStr.substring(0, 3.clamp(0, mStr.length))] ?? now.month;
      return DateTime(now.year, month, day, now.hour, now.minute);
    }

    final monthDayRegex = RegExp(r'\b([a-z]{3,})\s+(\d{1,2})(?:st|nd|rd|th)?\b');
    final mdMatch = monthDayRegex.firstMatch(lower);
    if (mdMatch != null) {
      final mStr = mdMatch.group(1) ?? '';
      final day = int.tryParse(mdMatch.group(2) ?? '') ?? 1;
      final month = months[mStr] ?? months[mStr.substring(0, 3.clamp(0, mStr.length))] ?? now.month;
      return DateTime(now.year, month, day, now.hour, now.minute);
    }

    return now;
  }

  /// Parses a single transaction line using regular expressions and rule-based NLP.
  ParsedLine parseLine(String line) {
    final clean = line.trim();
    if (clean.isEmpty) {
      return ParsedLine(rawText: line, type: 'expense', error: 'Empty line', confidence: 0.0);
    }

    String lower = clean.toLowerCase();

    // 1. Extract amount using regex.
    final amountRegex = RegExp(r'(?:rs\.?|₹|inr|\$)?\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);
    final matches = amountRegex.allMatches(clean);

    if (matches.isEmpty) {
      return ParsedLine(rawText: clean, type: 'expense', error: 'Invalid amount', confidence: 0.0);
    }

    double? amount;
    int amountMatchIndex = -1;

    for (int i = 0; i < matches.length; i++) {
      final m = matches.elementAt(i);
      final fullMatch = m.group(0)!.toLowerCase();
      if (fullMatch.contains('rs') || fullMatch.contains('₹') || fullMatch.contains('inr') || fullMatch.contains('\$')) {
        amount = double.tryParse(m.group(1) ?? '');
        amountMatchIndex = i;
        break;
      }
    }

    if (amount == null) {
      final m = matches.last;
      amount = double.tryParse(m.group(1) ?? '');
      amountMatchIndex = matches.length - 1;
    }

    if (amount == null || amount <= 0) {
      return ParsedLine(rawText: clean, type: 'expense', error: 'Invalid amount', confidence: 0.0);
    }

    final matchTextToRemove = matches.elementAt(amountMatchIndex).group(0)!;
    String textWithoutAmount = clean.replaceAll(matchTextToRemove, '');
    lower = textWithoutAmount.toLowerCase();

    double confidenceScore = 0.50; // Base confidence
    confidenceScore += 0.15; // Amount matched

    // 2. Date parsing
    DateTime transactionDate = DateTime.now();
    String? dateTokenFound;
    final dateKeywords = [
      'last monday', 'last tuesday', 'last wednesday', 'last thursday', 'last friday', 'last saturday', 'last sunday',
      'next monday', 'next tuesday', 'next wednesday', 'next thursday', 'next friday', 'next saturday', 'next sunday',
      '2 days ago', '3 days ago', '4 days ago', '5 days ago', '6 days ago', '7 days ago',
      'last month', 'yesterday', 'tomorrow', 'today'
    ];

    for (var kw in dateKeywords) {
      if (lower.contains(kw)) {
        dateTokenFound = kw;
        transactionDate = parseRelativeDate(kw);
        confidenceScore += 0.10;
        break;
      }
    }

    if (dateTokenFound == null) {
      const monthPattern = r'(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)';
      final dayMonthRegex = RegExp('\\b(\\d{1,2})(?:st|nd|rd|th)?\\s+$monthPattern\\b', caseSensitive: false);
      final dmMatch = dayMonthRegex.firstMatch(lower);
      if (dmMatch != null) {
        dateTokenFound = dmMatch.group(0)!;
        transactionDate = parseRelativeDate(dateTokenFound);
        confidenceScore += 0.10;
      } else {
        final monthDayRegex = RegExp('\\b$monthPattern\\s+(\\d{1,2})(?:st|nd|rd|th)?\\b', caseSensitive: false);
        final mdMatch = monthDayRegex.firstMatch(lower);
        if (mdMatch != null) {
          dateTokenFound = mdMatch.group(0)!;
          transactionDate = parseRelativeDate(dateTokenFound);
          confidenceScore += 0.10;
        }
      }
    }

    if (dateTokenFound != null) {
      textWithoutAmount = textWithoutAmount.replaceAll(RegExp('\\b$dateTokenFound\\b', caseSensitive: false), '');
      lower = textWithoutAmount.toLowerCase();
    }

    // 3. Check for credit card statement (ICICI Statement Rs 1707 Due 08-Jul)
    if (lower.contains('statement') && lower.contains('due')) {
      final dueIdx = lower.indexOf('due');
      final textAfterDue = lower.substring(dueIdx);
      final dateRegex = RegExp(
          r'(\d{1,2})[-/\s]?(jul|aug|sep|oct|nov|dec|jan|feb|mar|apr|may|jun|july|august|september|october|november|december|\d{1,2})',
          caseSensitive: false);
      final dateMatch = dateRegex.firstMatch(textAfterDue);
      DateTime dueDate = DateTime.now().add(const Duration(days: 15));
      if (dateMatch != null) {
        final day = int.tryParse(dateMatch.group(1) ?? '') ?? 15;
        final monthStr = dateMatch.group(2)!.toLowerCase();
        int month = DateTime.now().month;
        final monthsList = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
        final matchedIndex = monthsList.indexWhere((m) => monthStr.startsWith(m));
        if (matchedIndex != -1) {
          month = matchedIndex + 1;
        } else {
          month = int.tryParse(monthStr) ?? month;
        }
        dueDate = DateTime(DateTime.now().year, month, day);
        if (dueDate.isBefore(DateTime.now().subtract(const Duration(days: 30)))) {
          dueDate = DateTime(DateTime.now().year + 1, month, day);
        }
      }

      String ccName = 'Credit Card';
      final statementIdx = lower.indexOf('statement');
      if (statementIdx > 0) {
        ccName = clean.substring(0, statementIdx).trim();
      }

      return ParsedLine(
        rawText: clean,
        amount: amount,
        type: 'upcoming_bill',
        merchant: '$ccName Statement',
        category: 'Utilities',
        dueDate: dueDate,
        accountName: '$ccName Credit Card',
        accountType: 'credit_card',
        paymentMethod: 'Credit Card',
        confidence: 0.95,
        suggestion: 'Credit Card Statement: Will create upcoming bill due ${dueDate.toIso8601String().substring(0, 10)}.',
      );
    }

    // 4. Check for credit card payment (Credit Card Payment 5000)
    if (lower.contains('credit card payment') || lower.contains('cc payment')) {
      String ccName = 'Credit Card';
      final payIdx = lower.indexOf('credit card payment');
      if (payIdx > 0) {
        ccName = clean.substring(0, payIdx).trim();
      }
      return ParsedLine(
        rawText: clean,
        amount: amount,
        type: 'credit_card_payment',
        merchant: '$ccName Payment',
        category: 'Transfer',
        accountName: '$ccName Credit Card',
        accountType: 'credit_card',
        paymentMethod: 'Credit Card',
        dueDate: transactionDate,
        confidence: 0.95,
        suggestion: 'Credit Card Payment: Will reduce bank balance and CC outstanding.',
      );
    }

    // 5. Check for internal transfers
    final isTransferType = lower.contains('transfer') ||
        lower.contains('sent to') ||
        lower.contains('send to') ||
        lower.contains('atm withdrawal') ||
        lower.contains('cash deposit');

    if (isTransferType) {
      String fromAcc = 'Bank Account';
      String toAcc = 'Transfer Account';
      String? suggestionText;
      
      final accountKeywords = {
        'hdfc': 'HDFC Bank',
        'sbi': 'SBI',
        'axis': 'Axis Bank',
        'icici': 'ICICI Bank',
        'cash': 'Cash Wallet',
        'wallet': 'Wallet',
        'amazon pay': 'Amazon Pay',
        'phonepe': 'PhonePe Wallet',
        'gpay': 'Google Pay',
        'google pay': 'Google Pay',
        'paytm': 'Paytm Wallet',
        'savings': 'Savings Account'
      };

      String? matchedAcc;
      accountKeywords.forEach((key, val) {
        if (lower.contains(key)) {
          matchedAcc = val;
        }
      });

      if (lower.contains('atm withdrawal')) {
        fromAcc = matchedAcc ?? 'SBI';
        toAcc = 'Cash Wallet';
        suggestionText = 'ATM Withdrawal: Moves ₹${amount.toStringAsFixed(2)} from $fromAcc to Cash Wallet.';
      } else if (lower.contains('cash deposit')) {
        fromAcc = 'Cash Wallet';
        toAcc = matchedAcc ?? 'SBI';
        suggestionText = 'Cash Deposit: Moves ₹${amount.toStringAsFixed(2)} from Cash Wallet to $toAcc.';
      } else if (lower.contains('transfer to') || lower.contains('sent to') || lower.contains('send to')) {
        final transferToIdx = lower.contains('transfer to') 
            ? lower.indexOf('transfer to') 
            : lower.indexOf('to');
        final textBeforeTo = lower.substring(0, transferToIdx);
        String? srcAcc;
        accountKeywords.forEach((key, val) {
          if (textBeforeTo.contains(key)) {
            srcAcc = val;
          }
        });

        final idx = lower.contains('transfer to') 
            ? lower.indexOf('transfer to') + 'transfer to'.length 
            : lower.indexOf('to') + 'to'.length;
        String remainingText = clean.substring(idx.clamp(0, clean.length)).replaceAll(RegExp(r'\d+'), '').replaceAll(RegExp(r'(?:rs\.?|₹|inr|\$)', caseSensitive: false), '').trim();
        String destAcc = 'Savings Account';
        accountKeywords.forEach((key, val) {
          if (remainingText.toLowerCase().contains(key)) {
            destAcc = val;
          }
        });
        toAcc = destAcc;
        fromAcc = srcAcc ?? 'Bank Account';
      } else if (lower.contains('transfer from')) {
        toAcc = matchedAcc ?? 'SBI';
        final idx = lower.indexOf('transfer from') + 'transfer from'.length;
        String remainingText = clean.substring(idx.clamp(0, clean.length)).replaceAll(RegExp(r'\d+'), '').replaceAll(RegExp(r'(?:rs\.?|₹|inr|\$)', caseSensitive: false), '').trim();
        String srcAcc = 'Savings Account';
        accountKeywords.forEach((key, val) {
          if (remainingText.toLowerCase().contains(key)) {
            srcAcc = val;
          }
        });
        fromAcc = srcAcc;
      } else if (lower.contains('transfer')) {
        fromAcc = 'HDFC Bank';
        toAcc = matchedAcc ?? 'Savings Account';
      }

      return ParsedLine(
        rawText: clean,
        amount: amount,
        type: 'transfer',
        merchant: toAcc,
        accountName: fromAcc,
        accountType: fromAcc.toLowerCase().contains('cash') ? 'cash' : 'bank',
        paymentMethod: fromAcc.toLowerCase().contains('cash') ? 'Cash' : 'Debit Card',
        category: 'Transfer',
        dueDate: transactionDate,
        confidence: 0.90,
        suggestion: suggestionText ?? 'Internal Transfer: Moves ₹${amount.toStringAsFixed(2)} from $fromAcc to $toAcc.',
      );
    }

    // 6. Account Parsing
    String accountName = 'Cash Wallet';
    String accountType = 'cash';
    String? matchedAccountToken;

    final accountMap = {
      'hdfc credit card': {'name': 'HDFC Credit Card', 'type': 'credit_card'},
      'sbi credit card': {'name': 'SBI Credit Card', 'type': 'credit_card'},
      'axis credit card': {'name': 'Axis Credit Card', 'type': 'credit_card'},
      'icici credit card': {'name': 'ICICI Credit Card', 'type': 'credit_card'},
      'hdfc cc': {'name': 'HDFC Credit Card', 'type': 'credit_card'},
      'sbi cc': {'name': 'SBI Credit Card', 'type': 'credit_card'},
      'axis cc': {'name': 'Axis Credit Card', 'type': 'credit_card'},
      'icici cc': {'name': 'ICICI Credit Card', 'type': 'credit_card'},
      'hdfc': {'name': 'HDFC Bank', 'type': 'bank'},
      'sbi': {'name': 'SBI', 'type': 'bank'},
      'axis': {'name': 'Axis Bank', 'type': 'bank'},
      'icici': {'name': 'ICICI Bank', 'type': 'bank'},
      'cash': {'name': 'Cash Wallet', 'type': 'cash'},
      'wallet': {'name': 'Wallet', 'type': 'cash'},
      'amazon pay': {'name': 'Amazon Pay', 'type': 'wallet'},
      'phonepe': {'name': 'PhonePe Wallet', 'type': 'wallet'},
      'gpay': {'name': 'Google Pay', 'type': 'wallet'},
      'google pay': {'name': 'Google Pay', 'type': 'wallet'},
      'paytm': {'name': 'Paytm Wallet', 'type': 'wallet'},
    };

    for (var entry in accountMap.entries) {
      if (lower.contains(entry.key)) {
        accountName = entry.value['name']!;
        accountType = entry.value['type']!;
        matchedAccountToken = entry.key;
        confidenceScore += 0.15;
        break;
      }
    }

    if (matchedAccountToken != null) {
      textWithoutAmount = textWithoutAmount.replaceAll(RegExp('\\b$matchedAccountToken\\b', caseSensitive: false), '');
      lower = textWithoutAmount.toLowerCase();
    }

    // 7. Payment Method Parsing
    String? paymentMethod;
    String? matchedPaymentToken;
    final paymentMethodsMap = {
      'debit': 'Debit Card',
      'credit card': 'Credit Card',
      'credit': 'Credit Card',
      'cc': 'Credit Card',
      'card': 'Credit Card',
      'upi': 'UPI',
      'gpay': 'UPI',
      'phonepe': 'UPI',
      'paytm': 'UPI',
      'cash': 'Cash',
      'net banking': 'Net Banking',
      'netbanking': 'Net Banking'
    };

    for (var entry in paymentMethodsMap.entries) {
      if (lower.contains(entry.key)) {
        paymentMethod = entry.value;
        matchedPaymentToken = entry.key;
        confidenceScore += 0.10;
        break;
      }
    }

    if (matchedPaymentToken != null) {
      textWithoutAmount = textWithoutAmount.replaceAll(RegExp('\\b$matchedPaymentToken\\b', caseSensitive: false), '');
      lower = textWithoutAmount.toLowerCase();
    }

    if (paymentMethod == null) {
      if (accountName == 'Cash Wallet' || accountName == 'Wallet') {
        paymentMethod = 'Cash';
      } else if (accountType == 'credit_card') {
        paymentMethod = 'Credit Card';
      } else if (accountType == 'wallet') {
        paymentMethod = 'UPI';
      } else {
        paymentMethod = 'Debit Card';
      }
    }

    // 8. Determine Transaction Type
    String type = 'expense';
    final incomeKeywords = [
      "salary",
      "freelance",
      "received",
      "earned",
      "refund",
      "deposit",
      "bonus",
      "income",
      "stipend",
      "interest",
      "cashback",
      "got cashback",
      "credited"
    ];
    for (var kw in incomeKeywords) {
      if (lower.contains(kw)) {
        type = 'income';
        break;
      }
    }

    // 9. Determine Category & Subcategory
    String category = 'Miscellaneous';
    String? subcategory;

    if (lower.contains('eb bill') || lower.contains('electricity')) {
      category = 'Utilities';
      subcategory = 'Electricity Bill';
    } else if (lower.contains('recharge') || lower.contains('jio') || lower.contains('airtel')) {
      category = 'Utilities';
      subcategory = 'Mobile Recharge';
    } else if (lower.contains('pizza') || lower.contains('swiggy') || lower.contains('zomato') || lower.contains('restaurant') || lower.contains('cafe')) {
      category = 'Food';
      if (lower.contains('cafe') || lower.contains('coffee')) {
        subcategory = 'Cafe';
      } else {
        subcategory = 'Restaurant';
      }
    } else if (lower.contains('amazon') || lower.contains('flipkart')) {
      category = 'Shopping';
      if (lower.contains('amazon')) {
        subcategory = 'Amazon';
      } else {
        subcategory = 'Flipkart';
      }
    } else if (lower.contains('grocery') || lower.contains('supermarket')) {
      category = 'Shopping';
      subcategory = 'Grocery';
    } else if (lower.contains('fuel') || lower.contains('petrol') || lower.contains('diesel') || lower.contains('gas')) {
      category = 'Travel';
      subcategory = 'Fuel';
    } else {
      final categoryKeywords = {
        "Food": ["tea", "coffee", "restaurant", "food", "snacks", "lunch", "dinner", "starbucks", "mcdonald", "cafe", "hotel", "swiggy", "zomato", "burger", "pizza", "eat", "bakery", "dining"],
        "Travel": ["fuel", "petrol", "diesel", "gas", "cng", "shell", "refuel", "bus", "travel", "cab", "taxi", "hotel", "flight", "taxi"],
        "Shopping": ["amazon", "flipkart", "shopping", "order", "myntra", "clothing", "clothes", "shoes", "fashion", "mall", "grocery", "groceries", "mart", "supermarket", "bigbasket", "blinkit", "milk", "vegetables", "fruits", "provision"],
        "Utilities": ["electricity", "water", "internet", "wifi", "bill", "power", "dth", "broadband", "rent", "gas bill", "mobile", "recharge", "jio", "airtel", "phone", "talktime"],
        "Entertainment": ["movie", "cinema", "netflix", "spotify", "game", "gaming", "ticket", "show", "pub", "club", "concert", "prime"],
        "Salary": ["salary", "paycheck", "allowance", "stipend"],
        "Freelance": ["freelance", "gig", "contract", "upwork", "fiverr", "invoice"],
        "Investment": ["investment", "stock", "stocks", "mutual fund", "crypto", "gold", "share", "shares"]
      };

      int maxMatches = 0;
      categoryKeywords.forEach((cat, keywords) {
        int matches = 0;
        for (var kw in keywords) {
          if (lower.contains(kw)) {
            matches++;
          }
        }
        if (matches > maxMatches) {
          maxMatches = matches;
          category = cat;
        }
      });
    }

    int maxMatches = category == 'Miscellaneous' ? 0 : 1;
    if (maxMatches > 0) {
      confidenceScore += 0.10;
    }

    if (type == 'income' && category != 'Salary' && category != 'Freelance') {
      category = 'Salary';
    }

    // 10. Clean Description/Merchant
    String cleanText = textWithoutAmount;
    final wordsToRemove = [
      "spent", "paid", "received", "earned", "on", "for", "from", "to", "my", "a",
      "using", "credit card", "card", "today", "got", "upi payment", "google pay", "phonepe", "gpay", "payment"
    ];
    for (var word in wordsToRemove) {
      cleanText = cleanText.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
    }
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();

    String merchant = cleanText.isNotEmpty
        ? cleanText.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ')
        : (subcategory ?? category);

    if (merchant.toLowerCase().contains('credit card') || merchant.toLowerCase().contains('cc')) {
      merchant = type == 'income' ? 'Cashback' : 'Purchase';
    }

    if (confidenceScore > 1.0) {
      confidenceScore = 1.0;
    }

    String suggestion = 'Detected $merchant. Category: $category' + (subcategory != null ? ' -> $subcategory' : '') + '. Account: $accountName. Payment: $paymentMethod. Confidence: ${(confidenceScore * 100).toStringAsFixed(0)}%';

    return ParsedLine(
      rawText: clean,
      amount: amount,
      category: category,
      subcategory: subcategory,
      merchant: merchant,
      type: type,
      accountName: accountName,
      accountType: accountType,
      paymentMethod: paymentMethod,
      dueDate: transactionDate,
      confidence: confidenceScore,
      suggestion: suggestion,
    );
  }

  /// Compares parsed transactions with SQLite to detect duplicates within the current day.
  Future<List<ParsedLine>> detectDuplicates(List<ParsedLine> lines, String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get today's active transactions
    final todayTxs = await (_db.select(_db.transactions)
          ..where((t) => t.userId.equals(userId) & t.date.isBiggerOrEqualValue(startOfDay) & t.date.isSmallerOrEqualValue(endOfDay) & t.deletedAt.isNull()))
        .get();

    final List<ParsedLine> reconciledLines = [];

    for (var line in lines) {
      if (line.error != null) {
        reconciledLines.add(line);
        continue;
      }

      Transaction? duplicateTx;
      final intAmount = ((line.amount ?? 0) * 100).round();

      for (var tx in todayTxs) {
        if (tx.amount == intAmount && tx.type == line.type) {
          final txMerchant = (tx.merchant ?? '').toLowerCase();
          final lineMerchant = (line.merchant ?? '').toLowerCase();

          if (txMerchant.contains(lineMerchant) ||
              lineMerchant.contains(txMerchant) ||
              (tx.description ?? '').toLowerCase().contains(lineMerchant)) {
            duplicateTx = tx;
            break;
          }
        }
      }

      if (duplicateTx != null) {
        reconciledLines.add(line.copyWith(
          isDuplicate: true,
          warning: 'Duplicate transaction detected in database (ID: ${duplicateTx.merchant}, ₹${(duplicateTx.amount / 100).toStringAsFixed(2)}).',
          duplicateAction: 'skip', // default behavior when duplicate is detected
          existingTxId: duplicateTx.id,
        ));
      } else {
        reconciledLines.add(line);
      }
    }
    return reconciledLines;
  }

  /// Bulk saves all valid transactions in the list, performing double-entry updates via LedgerAgent.
  Future<Map<String, int>> saveAll(List<ParsedLine> lines, String userId) async {
    int saved = 0;
    int failed = 0;
    int skipped = 0;

    final ledger = _ref.read(ledgerAgentProvider);

    // Fetch categories and payment methods to map ids
    final allCats = await _db.categoryDao.getCategoriesForUser(userId);
    final allPms = await _db.paymentMethodDao.getPaymentMethodsForUser(userId);

    for (var line in lines) {
      if (line.error != null) {
        failed++;
        continue;
      }

      if (line.isDuplicate && line.duplicateAction == 'skip') {
        skipped++;
        continue;
      }

      try {
        final intAmount = ((line.amount ?? 0) * 100).round();

        // 1. Resolve Category & Subcategory ID
        String? catId;
        String? subCatId;
        final matchedCat = allCats.firstWhere(
          (c) => c.name.toLowerCase() == (line.category ?? '').toLowerCase() && c.parentId == null,
          orElse: () => allCats.firstWhere(
            (c) => c.parentId == null && (c.name.toLowerCase() == 'shopping' || c.name.toLowerCase() == 'food'),
            orElse: () => allCats.firstWhere((c) => c.parentId == null),
          ),
        );
        catId = matchedCat.id;

        if (line.subcategory != null) {
          final parentSubcategories = allCats.where((c) => c.parentId == catId).toList();
          if (parentSubcategories.isNotEmpty) {
            final matchedSub = parentSubcategories.firstWhere(
              (c) => c.name.toLowerCase() == line.subcategory!.toLowerCase(),
              orElse: () => parentSubcategories.firstWhere(
                (c) => c.name.toLowerCase().contains(line.subcategory!.toLowerCase()),
                orElse: () => parentSubcategories.first,
              ),
            );
            subCatId = matchedSub.id;
          }
        }

        // 2. Resolve Payment Method ID
        String? pmId;
        final pmName = line.paymentMethod ?? 'Cash';
        final matchedPm = allPms.firstWhere(
          (pm) => pm.name.toLowerCase().contains(pmName.toLowerCase()) || pmName.toLowerCase().contains(pm.name.toLowerCase()),
          orElse: () => allPms.firstWhere(
            (pm) => pm.name.toLowerCase() == 'cash',
            orElse: () => allPms.first,
          ),
        );
        pmId = matchedPm.id;

        // If duplicate action is 'replace', delete the old transaction first
        if (line.isDuplicate && line.duplicateAction == 'replace' && line.existingTxId != null) {
          // Re-balance: reverse account deduction
          final oldTx = await _db.transactionDao.getTransactionById(line.existingTxId!);
          if (oldTx != null) {
            // Revert balance adjustment (reverse of debit/credit)
            final account = await (_db.select(_db.accounts)..where((t) => t.id.equals(oldTx.accountId ?? ''))).getSingleOrNull();
            if (account != null) {
              int reversedBalance = account.balance;
              final isCredit = oldTx.type == 'income' || oldTx.type == 'cashback' || oldTx.type == 'refund';
              final isDebit = oldTx.type == 'expense' || oldTx.type == 'credit_card_purchase';
              if (isDebit) {
                reversedBalance += oldTx.amount;
              } else if (isCredit) {
                reversedBalance -= oldTx.amount;
              }
              await _db.update(_db.accounts).replace(account.copyWith(balance: reversedBalance, updatedAt: DateTime.now()));
            }
            await _db.transactionDao.hardDeleteTransaction(line.existingTxId!);
          }
        }

        // 3. Construct transaction companion
        final transaction = Transaction(
          id: const Uuid().v4(),
          userId: userId,
          categoryId: catId,
          subcategoryId: subCatId,
          paymentMethodId: pmId,
          type: line.type,
          amount: intAmount,
          currency: 'INR',
          merchant: line.merchant,
          description: line.rawText,
          date: line.dueDate ?? DateTime.now(),
          source: 'quick_add_notepad',
          isRecurring: false,
          syncStatus: 'pending',
          referenceNumber: line.accountName ?? 'Cash Wallet', // Stored custom account name
          accountType: line.accountType ?? 'cash', // Stored custom account type
          billStatus: line.type == 'upcoming_bill' ? 'pending' : null,
          dueDate: line.dueDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 4. Reconcile and save transaction
        await ledger.reconcileTransaction(transaction);
        saved++;
      } catch (e) {
        debugPrint('QuickAddNotepadService: Failed to save line "${line.rawText}": $e');
        failed++;
      }
    }

    // Invalidate expense notifier provider to trigger dynamic UI updates
    _ref.invalidate(expenseListNotifierProvider);
    _ref.invalidate(accountsProvider);
    _ref.invalidate(categoriesProvider);

    return {
      'parsed': lines.length,
      'saved': saved,
      'failed': failed,
      'skipped': skipped,
    };
  }
}

final Provider<QuickAddNotepadService> quickAddNotepadServiceProvider = Provider<QuickAddNotepadService>((ref) {
  return QuickAddNotepadService(ref);
});
