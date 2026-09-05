import 'dart:developer';

class ParsedSmsResult {
  final double amount;
  final String type; // 'expense', 'income', or 'transfer'
  final String? merchant;
  final DateTime date;
  final String? cardOrAccount;
  final String? referenceId;

  ParsedSmsResult({
    required this.amount,
    required this.type,
    this.merchant,
    required this.date,
    this.cardOrAccount,
    this.referenceId,
  });

  @override
  String toString() {
    return 'ParsedSmsResult(amount: $amount, type: $type, merchant: $merchant, date: $date, cardOrAccount: $cardOrAccount, ref: $referenceId)';
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



  static bool _isValidMerchant(String name, {String? sender}) {
    final clean = name.trim().replaceAll(' ', '');
    if (clean.isEmpty) return false;
    
    final digitsOnly = clean.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 8) {
      return false; // Looks like a phone number or customer care number
    }
    
    if (sender != null && sender.isNotEmpty) {
      final cleanSender = sender.toLowerCase().trim();
      final lowerName = name.toLowerCase().trim();
      if (lowerName == cleanSender || cleanSender.contains(lowerName) || lowerName.contains(cleanSender)) {
        return false;
      }
    }

    // Reject dates
    if (RegExp(r'\b\d{1,2}[-\/\.\s](?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|[a-zA-Z0-9]+)[-\/\.\s]\d{2,4}\b', caseSensitive: false).hasMatch(name) ||
        RegExp(r'\b\d{1,2}[-\/\.]\d{1,2}[-\/\.]\d{2,4}\b').hasMatch(name)) {
      return false;
    }

    final lower = name.toLowerCase();
    if (lower.contains('customer care') || 
        lower.contains('helpline') || 
        lower.contains('call') || 
        lower.contains('contact') ||
        lower.contains('support') ||
        lower.contains('card ending') ||
        lower.contains('a/c') ||
        lower.contains('account')) {
      return false;
    }
    
    if (RegExp(r'^\d+$').hasMatch(clean)) {
      return false;
    }

    return true;
  }

  /// Parses an SMS body and returns a [ParsedSmsResult], or null if not a transaction
  static ParsedSmsResult? parseSms(String body, DateTime smsDateTime, {String? sender}) {
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

    final isDebit = type == 'expense';

    // 3. Extract Card / Account Number
    String? cardOrAccount;
    final accountMatch = _accountRegExp.firstMatch(cleanBody);
    if (accountMatch != null) {
      cardOrAccount = accountMatch.group(1);
    }

    // 4. Extract Merchant
    String? merchant;
    final patterns = isDebit 
        ? [
            RegExp(r'\b(?:info|info:|towards)\s*[:\s]\s*([^,.]+?)(?:[\.,\s]+(?:on|ref|vpa|at|from|using|not\s+you|if\s+not|call|avl|limit|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\bTo\s+([^,.]+?)(?:[\.,\s]+(?:on|ref|vpa|at|from|using|not\s+you|if\s+not|call|avl|limit|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\bon\s+\d{1,2}[-\/\.\s](?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|[a-zA-Z0-9]+)[-\/\.\s]\d{2,4}\s+on\s+([^,.]+?)(?:[\.,\s]+(?:avl\s+limit|available\s+limit|if\s+not|call|not\s+you|ref|vpa|using|rs\.?|inr|₹|usd|upi|on)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\bspent\s+.*?\s+on\s+([^,.]+?)(?:[\.,\s]+(?:avl\s+limit|available\s+limit|if\s+not|call|not\s+you|ref|vpa|using|rs\.?|inr|₹|usd|upi|on)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\bspent\s+at\s+([^,.]+?)(?:[\.,\s]+(?:on|ref|vpa|using|if\s+not|call|avl|limit|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\bpaid\s+to\s+([^,.]+?)(?:[\.,\s]+(?:on|ref|vpa|at|from|using|not\s+you|if\s+not|call|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\bsent\s+to\s+([^,.]+?)(?:[\.,\s]+(?:on|ref|vpa|at|from|using|not\s+you|if\s+not|call|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\bpurchase\s+at\s+([^,.]+?)(?:[\.,\s]+(?:on|ref|vpa|using|if\s+not|call|avl|limit|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\bat\s+([^,.]+?)(?:[\.,\s]+(?:on|ref|vpa|using|if\s+not|call|avl|limit|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
          ]
        : [
            RegExp(r'\b(?:info|info:|towards)\s*[:\s]\s*([^,.]+?)(?:[\.,\s]+(?:on|ref|vpa|at|from|using|not\s+you|if\s+not|call|avl|limit|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\btransfer\s+from\s+([^,.]+?)(?:[\.,\s]+(?:ref|no|on|to|using|if\s+not|call|avl|limit|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\breceived\s+from\s+([^,.]+?)(?:[\.,\s]+(?:ref|no|on|to|using|if\s+not|call|avl|limit|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\bcredited\s+.*?\s+from\s+([^,.]+?)(?:[\.,\s]+(?:ref|no|on|to|using|if\s+not|call|avl|limit|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\bpayment\s+from\s+([^,.]+?)(?:[\.,\s]+(?:ref|no|on|to|using|if\s+not|call|avl|limit|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
            RegExp(r'\bfrom\s+([^,.]+?)(?:[\.,\s]+(?:ref|no|on|to|using|if\s+not|call|avl|limit|rs\.?|inr|₹|usd|upi)\b|[\.,\s]*$)', caseSensitive: false),
          ];

    for (final reg in patterns) {
      final match = reg.firstMatch(cleanBody);
      if (match != null) {
        final candidate = match.group(1)!.trim();
        final cleaned = _cleanMerchantName(candidate);
        if (_isValidMerchant(cleaned, sender: sender)) {
          merchant = cleaned;
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
      if (word.toUpperCase() == 'ATM') return 'ATM';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ');
  }
}
