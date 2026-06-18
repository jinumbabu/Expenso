import 'dart:developer';

class ParsedSmsResult {
  final double amount;
  final String type; // 'expense', 'income', or 'transfer'
  final String? merchant;
  final DateTime date;
  final String? cardOrAccount;

  ParsedSmsResult({
    required this.amount,
    required this.type,
    this.merchant,
    required this.date,
    this.cardOrAccount,
  });

  @override
  String toString() {
    return 'ParsedSmsResult(amount: $amount, type: $type, merchant: $merchant, date: $date, cardOrAccount: $cardOrAccount)';
  }
}

class SmsParserService {
  // Common keywords to detect if an SMS is transaction related
  static final List<String> _transactionKeywords = [
    'debited', 'credited', 'spent', 'charged', 'withdrawn', 'received', 'deposited', 'transferred', 'txn', 'payment', 'paid'
  ];

  // Regex to match amount, matching prefixes like Rs., INR, ₹, $, USD, and decimals
  static final RegExp _amountRegExp = RegExp(
    r'(?:rs\.?|inr|₹|\$|usd)\s*([\d,]+(?:\.\d{2})?)',
    caseSensitive: false,
  );

  // Fallback RegExp if no currency symbol prefix is present but it matches "debited/credited [amount]"
  static final RegExp _fallbackAmountRegExp = RegExp(
    r'\b(?:debited|credited|spent|withdrawn|for|of)\s+([\d,]+(?:\.\d{2})?)\b',
    caseSensitive: false,
  );

  // Regex to extract card or account ending digits (usually last 4 digits)
  static final RegExp _accountRegExp = RegExp(
    r'\b(?:a/c|acct|account|card|card\s+ending|a/c\s+no\.?)\s*(?:no\.?|ending)?\s*(?:\*+|x+|[a-z]*)\s*(\d{4})\b',
    caseSensitive: false,
  );

  // Regex to extract merchant name
  static final List<RegExp> _merchantRegExps = [
    // Matches "at [Merchant] on" or "at [Merchant] by"
    RegExp(r'\bat\s+([a-z0-9\s\.\-_&@]+?)\s+(?:on|by|using|ref|rs\.?|inr|₹|\$|usd|\.|\bfor\b)', caseSensitive: false),
    // Matches "transferred to [Merchant] on" or "sent to [Merchant]"
    RegExp(r'\b(?:transferred|sent|paid)\s+to\s+([a-z0-9\s\.\-_&@]+?)\s+(?:on|by|using|ref|rs\.?|inr|₹|\$|usd|\.|\bfor\b)', caseSensitive: false),
    // Matches "info: [Merchant]"
    RegExp(r'\b(?:info|info:|towards)\s*:\s*([a-z0-9\s\.\-_&@]+?)(?:\s+on|\s+by|rs\.?|inr|₹|\$|usd|\.|\s*$)', caseSensitive: false),
  ];

  // Helper to check if string contains banking transaction markers
  static bool isTransactionSms(String body) {
    final lowerBody = body.toLowerCase();
    return _transactionKeywords.any((kw) => lowerBody.contains(kw));
  }

  /// Parses an SMS body and returns a [ParsedSmsResult], or null if not a transaction
  static ParsedSmsResult? parseSms(String body, DateTime smsDateTime) {
    if (!isTransactionSms(body)) {
      return null;
    }

    final cleanBody = body.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    final lowerBody = cleanBody.toLowerCase();

    // 1. Extract Amount
    double? amount;
    var amountMatch = _amountRegExp.firstMatch(cleanBody);
    if (amountMatch != null) {
      final amtStr = amountMatch.group(1)!.replaceAll(',', '');
      amount = double.tryParse(amtStr);
    } else {
      // Try fallback amount RegExp
      amountMatch = _fallbackAmountRegExp.firstMatch(cleanBody);
      if (amountMatch != null) {
        final amtStr = amountMatch.group(1)!.replaceAll(',', '');
        amount = double.tryParse(amtStr);
      }
    }

    if (amount == null || amount <= 0) {
      log('SmsParserService: Found transaction keywords but no valid amount.');
      return null;
    }

    // 2. Determine Transaction Type
    String type = 'expense'; // Default fallback
    if (lowerBody.contains('credited') ||
        lowerBody.contains('deposited') ||
        lowerBody.contains('received') ||
        lowerBody.contains('refund') ||
        lowerBody.contains('salary')) {
      type = 'income';
    } else if (lowerBody.contains('debited') ||
               lowerBody.contains('spent') ||
               lowerBody.contains('charged') ||
               lowerBody.contains('withdrawn') ||
               lowerBody.contains('paid')) {
      type = 'expense';
    }

    // 3. Extract Card / Account Number
    String? cardOrAccount;
    final accountMatch = _accountRegExp.firstMatch(cleanBody);
    if (accountMatch != null) {
      cardOrAccount = accountMatch.group(1);
    }

    // 4. Extract Merchant
    String? merchant;
    for (final regex in _merchantRegExps) {
      final match = regex.firstMatch(cleanBody);
      if (match != null) {
        final rawMerchant = match.group(1)!.trim();
        // Clean up merchant if it has trailing codes or garbage (like transaction IDs)
        if (rawMerchant.isNotEmpty && rawMerchant.length < 50) {
          merchant = _cleanMerchantName(rawMerchant);
          break;
        }
      }
    }

    // If no merchant was extracted, default to a generic name
    if (merchant == null || merchant.isEmpty) {
      if (lowerBody.contains('atm')) {
        merchant = 'ATM Withdrawal';
      } else {
        merchant = type == 'income' ? 'Income Deposit' : 'General Expense';
      }
    }

    return ParsedSmsResult(
      amount: amount,
      type: type,
      merchant: merchant,
      date: smsDateTime,
      cardOrAccount: cardOrAccount,
    );
  }

  static String _cleanMerchantName(String raw) {
    var cleaned = raw;
    // Strip common words and extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    // If it has UPI reference or payment codes like "ref no", "vpa", "upi ref"
    final indexRef = cleaned.toLowerCase().indexOf(RegExp(r'\b(?:ref|ref\s+no|upi|vpa)\b'));
    if (indexRef != -1) {
      cleaned = cleaned.substring(0, indexRef).trim();
    }
    // Clean trailing special characters/punctuations
    cleaned = cleaned.replaceAll(RegExp(r'[\.\-,\s/]+$'), '').trim();
    // Convert to Title Case
    if (cleaned.isEmpty) return 'General';
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ');
  }
}
