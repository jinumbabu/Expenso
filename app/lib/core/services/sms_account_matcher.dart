import '../../core/database/app_database.dart';
import '../../features/accounts/presentation/providers/account_formatters.dart';

class SmsAccountMatchResult {
  final Account? matchedAccount;
  final String bankName;
  final String? last4;
  final String displayTitle;
  final String accountType; // 'savings', 'current', 'credit_card', 'wallet', 'cash'
  final String paymentMethod; // 'UPI', 'Credit Card', 'Debit Card', 'Net Banking', 'Wallet', 'Cash'
  final bool isNewAccountNeeded;

  SmsAccountMatchResult({
    required this.matchedAccount,
    required this.bankName,
    required this.last4,
    required this.displayTitle,
    required this.accountType,
    required this.paymentMethod,
    required this.isNewAccountNeeded,
  });
}

class SmsAccountMatcher {
  /// Comprehensive mapping of Indian Banks and financial institutions
  static final Map<String, String> bankKeyToName = {
    'sbi': 'SBI',
    'state bank': 'SBI',
    'hdfc': 'HDFC',
    'icici': 'ICICI',
    'axis': 'Axis Bank',
    'federal': 'Federal Bank',
    'canara': 'Canara Bank',
    'indian bank': 'Indian Bank',
    'indbank': 'Indian Bank',
    'pnb': 'Punjab National Bank',
    'punjab national': 'Punjab National Bank',
    'baroda': 'Bank of Baroda',
    'bob': 'Bank of Baroda',
    'idfc': 'IDFC FIRST Bank',
    'idfc first': 'IDFC FIRST Bank',
    'kotak': 'Kotak Mahindra Bank',
    'yes bank': 'Yes Bank',
    'union bank': 'Union Bank of India',
    'ubi': 'Union Bank of India',
    'south indian': 'South Indian Bank',
    'sib': 'South Indian Bank',
    'indusind': 'IndusInd Bank',
    'au small': 'AU Small Finance Bank',
    'au bank': 'AU Small Finance Bank',
    'uco': 'UCO Bank',
    'central bank': 'Central Bank of India',
    'karnataka bank': 'Karnataka Bank',
    'bandhan': 'Bandhan Bank',
    'rbl': 'RBL Bank',
    'hsbc': 'HSBC',
    'stanchart': 'Standard Chartered',
    'standard chartered': 'Standard Chartered',
    'citi': 'Citibank',
    'citibank': 'Citibank',
    'paytm payments bank': 'Paytm Payments Bank',
    'airtel payments bank': 'Airtel Payments Bank',
    'jio payments bank': 'Jio Payments Bank',
  };

  /// Normalizes a bank name to a canonical string key for comparison
  static String normalizeBankKey(String rawName) {
    final lower = rawName.toLowerCase();
    for (final entry in bankKeyToName.entries) {
      if (lower.contains(entry.key)) {
        return entry.key;
      }
    }
    return lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Extracts standard bank name from SMS text, sender, or raw string
  static String extractBankName(String text, {String? sender, String? fallback}) {
    final combined = '${sender ?? ''} $text'.toLowerCase();
    for (final entry in bankKeyToName.entries) {
      if (combined.contains(entry.key)) {
        return entry.value;
      }
    }
    if (fallback != null && fallback.isNotEmpty && fallback.toLowerCase() != 'generic' && fallback.toLowerCase() != 'bank') {
      return fallback;
    }
    return 'Bank';
  }

  /// Extracts last 4 digits from SMS or card/account string
  static String? extractLast4(String? cardOrAcc, String smsText) {
    // 1. Primary priority: Extract 4 digits following account/card keywords in SMS text
    final regExps = [
      RegExp(r'\b(?:a/c|acct|account|card|ending|xx|x|no\.?|upi)\s*(?:no\.?|ending)?\s*(?:\*+|x+|[a-z]*)\s*(\d{3,4})\b', caseSensitive: false),
      RegExp(r'\b(?:xx|x|\*+)(\d{4})\b', caseSensitive: false),
      RegExp(r'xxxx(\d{4})', caseSensitive: false),
      RegExp(r'\b(?:a/c|acct|account|card|ending)\s+(\d{4})\b', caseSensitive: false),
    ];

    for (final reg in regExps) {
      final match = reg.firstMatch(smsText);
      if (match != null) {
        final val = (match.groupCount >= 1 ? match.group(1) : match.group(0));
        if (val != null && val.length == 4) {
          return val;
        }
      }
    }

    // 2. Secondary fallback: Check cardOrAcc if it's strictly 3 or 4 digits (not long UTR IDs)
    if (cardOrAcc != null && cardOrAcc.isNotEmpty && cardOrAcc.toUpperCase() != 'XXXX') {
      final digits = cardOrAcc.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 4) {
        return digits;
      }
    }

    // 3. Fallback: Standalone 4-digit number in smsText
    final standaloneMatch = RegExp(r'\b\d{4}\b').firstMatch(smsText);
    if (standaloneMatch != null) {
      final val = standaloneMatch.group(0);
      if (val != null && val.length == 4) {
        return val;
      }
    }

    return null;
  }

  /// Evaluates Payment Method for SMS (UPI, Credit Card, Debit Card, Net Banking, Wallet, Cash)
  static String detectPaymentMethod({
    required String smsText,
    required String accountType,
    String? explicitMode,
  }) {
    final lower = smsText.toLowerCase();

    if (accountType == 'cash' || lower.contains('atm withdrawal') || lower.contains('cash dispensed')) {
      return 'Cash';
    }
    if (accountType == 'credit_card' || lower.contains('credit card') || lower.contains('cc ending') || lower.contains('card ending')) {
      return 'Credit Card';
    }
    if (accountType == 'wallet') {
      return 'Wallet';
    }

    if (explicitMode != null && explicitMode.isNotEmpty && explicitMode != 'Other') {
      if (explicitMode == 'IMPS' || explicitMode == 'NEFT' || explicitMode == 'RTGS') {
        return 'Net Banking';
      }
      if (explicitMode == 'ATM') return 'Debit Card';
      return explicitMode;
    }

    if (lower.contains('upi') ||
        lower.contains('gpay') ||
        lower.contains('google pay') ||
        lower.contains('phonepe') ||
        lower.contains('paytm upi') ||
        lower.contains('bhim') ||
        lower.contains('vpa') ||
        lower.contains('cred') ||
        lower.contains('amazon pay upi') ||
        lower.contains('mobikwik upi')) {
      return 'UPI';
    }

    if (lower.contains('debit card') || lower.contains('atm') || lower.contains('pos purchase')) {
      return 'Debit Card';
    }

    if (lower.contains('net banking') || lower.contains('netbanking') || lower.contains('neft') || lower.contains('imps') || lower.contains('rtgs')) {
      return 'Net Banking';
    }

    return 'UPI'; // Default for mobile banking SMS alerts
  }

  /// Core Account Matching Engine: Resolves an SMS alert against existing user accounts.
  /// NEVER defaults to Cash unless explicit ATM cash withdrawal.
  static SmsAccountMatchResult matchAccount({
    required String smsText,
    required List<Account> existingAccounts,
    String? cardOrAccount,
    String? rawBankName,
    String? rawAccountType,
    String? sender,
    String? explicitPaymentMode,
  }) {
    final lowerSms = smsText.toLowerCase();
    final isAtmWithdrawal = lowerSms.contains('atm') || lowerSms.contains('cash withdrawal') || lowerSms.contains('cash dispensed');

    // 1. ATM Cash Withdrawal Special Handling
    if (isAtmWithdrawal) {
      final cashAccount = existingAccounts.firstWhere(
        (a) => a.type == 'cash',
        orElse: () => existingAccounts.firstWhere((a) => a.isDefault, orElse: () => existingAccounts.first),
      );
      return SmsAccountMatchResult(
        matchedAccount: cashAccount,
        bankName: 'Cash',
        last4: null,
        displayTitle: 'Cash',
        accountType: 'cash',
        paymentMethod: 'Cash',
        isNewAccountNeeded: false,
      );
    }

    // 2. Extract Last 4 Digits & Bank Name
    final last4 = extractLast4(cardOrAccount, smsText);
    final bankName = extractBankName(smsText, sender: sender, fallback: rawBankName);
    final bankKey = normalizeBankKey(bankName);

    // 3. Determine actual Account Type (NEVER 'UPI' or 'upi')
    final isCreditCard = lowerSms.contains('credit card') ||
        lowerSms.contains('cc ending') ||
        lowerSms.contains('card ending') ||
        lowerSms.contains('total due') ||
        lowerSms.contains('statement generated') ||
        (rawAccountType != null && rawAccountType.toLowerCase().contains('credit'));

    final isExplicitWallet = lowerSms.contains('wallet top-up') ||
        lowerSms.contains('topup') ||
        lowerSms.contains('wallet credit') ||
        lowerSms.contains('added to wallet') ||
        lowerSms.contains('wallet balance');

    String accountType = isCreditCard ? 'credit_card' : (isExplicitWallet ? 'wallet' : 'savings');

    // 4. Match against existing accounts (Priority Order)
    Account? matchedAccount;

    // Priority 1: Exact Match by Last 4 Digits + Bank Name
    if (last4 != null && bankKey.isNotEmpty) {
      for (final acc in existingAccounts) {
        final accLast4 = acc.last4Digits ?? extractLast4(null, acc.name);
        final accBankKey = normalizeBankKey(acc.bankName ?? acc.name);
        final isTypeMatch = isCreditCard ? acc.type == 'credit_card' : acc.type != 'credit_card';

        if (accLast4 == last4 && (accBankKey == bankKey || accBankKey.contains(bankKey) || bankKey.contains(accBankKey)) && isTypeMatch) {
          matchedAccount = acc;
          break;
        }
      }
    }

    // Priority 2: Match by Last 4 Digits alone (if unique or type matches)
    if (matchedAccount == null && last4 != null) {
      for (final acc in existingAccounts) {
        final accLast4 = acc.last4Digits ?? extractLast4(null, acc.name);
        final isTypeMatch = isCreditCard ? acc.type == 'credit_card' : acc.type != 'credit_card';
        if (accLast4 == last4 && isTypeMatch) {
          matchedAccount = acc;
          break;
        }
      }
    }

    // Priority 3: Match by Bank Name alone (if no last4 in SMS)
    if (matchedAccount == null && bankKey.isNotEmpty) {
      for (final acc in existingAccounts) {
        final accBankKey = normalizeBankKey(acc.bankName ?? acc.name);
        final isTypeMatch = isCreditCard ? acc.type == 'credit_card' : acc.type != 'credit_card';
        if ((accBankKey == bankKey || accBankKey.contains(bankKey) || bankKey.contains(accBankKey)) && isTypeMatch) {
          matchedAccount = acc;
          break;
        }
      }
    }

    // Priority 4: Explicit Wallet Match
    if (matchedAccount == null && isExplicitWallet) {
      for (final acc in existingAccounts) {
        if (acc.type == 'wallet') {
          matchedAccount = acc;
          break;
        }
      }
    }

    // 5. Fallback Account Selection:
    // Only fall back to default bank account if neither bank name nor last4 could be extracted (completely generic SMS).
    // If bank name or last4 IS identified (e.g. "HDFC" or "3726"), keep matchedAccount = null so a dedicated account is created.
    if (matchedAccount == null) {
      final isGenericNoInfo = (bankName == 'Bank' || bankName.toLowerCase() == 'generic') && last4 == null;
      if (isGenericNoInfo) {
        final nonCashAccounts = existingAccounts.where((a) => a.type != 'cash').toList();
        if (nonCashAccounts.isNotEmpty) {
          matchedAccount = nonCashAccounts.firstWhere((a) => a.isDefault, orElse: () => nonCashAccounts.first);
        } else if (existingAccounts.isNotEmpty) {
          matchedAccount = existingAccounts.first;
        }
      }
    }

    // 6. Compute Display Title (clean, no "UPI" suffix in title)
    String displayTitle;
    if (matchedAccount != null) {
      displayTitle = formatAccountTitle(matchedAccount);
    } else {
      final cleanBank = sanitizeAccountName(bankName);
      displayTitle = last4 != null ? '$cleanBank $last4' : cleanBank;
    }

    final paymentMethod = detectPaymentMethod(
      smsText: smsText,
      accountType: matchedAccount?.type ?? accountType,
      explicitMode: explicitPaymentMode,
    );

    return SmsAccountMatchResult(
      matchedAccount: matchedAccount,
      bankName: bankName,
      last4: last4,
      displayTitle: displayTitle,
      accountType: matchedAccount?.type ?? accountType,
      paymentMethod: paymentMethod,
      isNewAccountNeeded: matchedAccount == null,
    );
  }
}
