import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;
import '../database/app_database.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class SmsAgentResult {
  final double amount;
  final String merchant;
  final String transactionType; // 'expense' or 'income'
  final DateTime date;
  final String account; // e.g. "SBI A/c 1234"
  final String? bank;
  final String? accountNumber;
  final double? balance;
  final String? referenceId;
  final String? upiId;
  final String? paymentMode;
  final double confidence;

  SmsAgentResult({
    required this.amount,
    required this.merchant,
    required this.transactionType,
    required this.date,
    required this.account,
    this.bank,
    this.accountNumber,
    this.balance,
    this.referenceId,
    this.upiId,
    this.paymentMode,
    required this.confidence,
  });

  @override
  String toString() {
    return 'SmsAgentResult(amount: $amount, merchant: $merchant, type: $transactionType, account: $account, bank: $bank, acctNo: $accountNumber, bal: $balance, ref: $referenceId, upi: $upiId, mode: $paymentMode, confidence: $confidence)';
  }
}

class BankTemplate {
  final String bankName;
  final List<RegExp> debitPatterns;
  final List<RegExp> creditPatterns;

  BankTemplate({
    required this.bankName,
    required this.debitPatterns,
    required this.creditPatterns,
  });
}

class SmsAgent {
  final AppDatabase _db;

  SmsAgent(this._db);

  // Define templates for the banks
  static final List<BankTemplate> _bankTemplates = [
    BankTemplate(
      bankName: 'SBI',
      debitPatterns: [
        RegExp(r'(?:debited|spent|withdrawn).*?rs\.?\s*([\d,]+\.?\d*).*?a/c\s*(?:xx|x|no)?(\d{4})', caseSensitive: false),
        RegExp(r'a/c\s*(?:xx|x|no)?(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
      creditPatterns: [
        RegExp(r'(?:credited|received|deposited).*?rs\.?\s*([\d,]+\.?\d*).*?a/c\s*(?:xx|x|no)?(\d{4})', caseSensitive: false),
        RegExp(r'a/c\s*(?:xx|x|no)?(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
    ),
    BankTemplate(
      bankName: 'ICICI',
      debitPatterns: [
        RegExp(r'inr\s*([\d,]+\.?\d*).*?(?:spent|debited).*?(?:card|a/c\s+ending)\s*(\d{4})', caseSensitive: false),
        RegExp(r'spent\s*on\s*(?:credit\s*card|card)\s*(?:ending)?\s*(\d{4})\s*at\s*(.+?)\s*on', caseSensitive: false),
        RegExp(r'spent.*?card\s*ending\s*(\d{4})', caseSensitive: false),
      ],
      creditPatterns: [
        RegExp(r'a/c\s*(\d{4}).*?(?:credited|deposited).*?inr\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'inr\s*([\d,]+\.?\d*).*?credited.*?a/c\s*ending\s*(\d{4})', caseSensitive: false),
      ],
    ),
    BankTemplate(
      bankName: 'HDFC',
      debitPatterns: [
        RegExp(r'rs\s*([\d,]+\.?\d*).*?debited.*?a/c\s*(?:xx)?(\d{4})', caseSensitive: false),
        RegExp(r'spent.*?rs\s*([\d,]+\.?\d*).*?card.*?ending\s*(\d{4})', caseSensitive: false),
      ],
      creditPatterns: [
        RegExp(r'rs\s*([\d,]+\.?\d*).*?credited.*?a/c\s*(?:xx)?(\d{4})', caseSensitive: false),
      ],
    ),
    BankTemplate(
      bankName: 'Axis',
      debitPatterns: [
        RegExp(r'axis.*?card\s*xx(\d{4}).*?spent\s*rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
      creditPatterns: [
        RegExp(r'a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
    ),
    BankTemplate(
      bankName: 'Federal Bank',
      debitPatterns: [
        RegExp(r'federal.*?a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
      creditPatterns: [
        RegExp(r'federal.*?a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
    ),
    BankTemplate(
      bankName: 'Kotak',
      debitPatterns: [
        RegExp(r'kotak.*?a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
      creditPatterns: [
        RegExp(r'kotak.*?a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
    ),
    BankTemplate(
      bankName: 'Canara',
      debitPatterns: [
        RegExp(r'canara.*?a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
      creditPatterns: [
        RegExp(r'canara.*?a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
    ),
    BankTemplate(
      bankName: 'Union Bank',
      debitPatterns: [
        RegExp(r'union.*?a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
      creditPatterns: [
        RegExp(r'union.*?a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
    ),
    BankTemplate(
      bankName: 'Indian Bank',
      debitPatterns: [
        RegExp(r'indian.*?a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
      creditPatterns: [
        RegExp(r'indian.*?a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
    ),
    BankTemplate(
      bankName: 'Bank of Baroda',
      debitPatterns: [
        RegExp(r'baroda.*?a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'debited.*?rs\.?\s*([\d,]+\.?\d*).*?baroda.*?a/c\s*xx(\d{4})', caseSensitive: false),
      ],
      creditPatterns: [
        RegExp(r'baroda.*?a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
    ),
    BankTemplate(
      bankName: 'PNB',
      debitPatterns: [
        RegExp(r'pnb.*?a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
      creditPatterns: [
        RegExp(r'pnb.*?a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
    ),
    BankTemplate(
      bankName: 'IDFC',
      debitPatterns: [
        RegExp(r'idfc.*?a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?debited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
      creditPatterns: [
        RegExp(r'idfc.*?a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'a/c\s*xx(\d{4}).*?credited.*?rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      ],
    ),
  ];

  // Generic patterns for fallback
  static final RegExp _genericAmountRegExp = RegExp(r'(?:rs\.?|inr|₹|\$|usd)\s*([\d,]+\.?\d*)', caseSensitive: false);
  static final RegExp _fallbackAmountRegExp = RegExp(r'\b(?:debited|credited|spent|withdrawn|charged|payment\s+of|for|of)\s*(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)\b', caseSensitive: false);
  static final RegExp _genericAccountRegExp = RegExp(r'\b(?:a/c|card|ending|xx|x|no\.?)\s*(?:no\.?|ending)?\s*(?:\*+|x+|[a-z]*)\s*(\d{3,4})\b', caseSensitive: false);
  static final RegExp _genericUpiRefRegExp = RegExp(r'\b(?:upi\s*ref|ref\s*no|txn|vpa|ref|rrn|transaction\s*id|txid)\s*(?:no\.?)?\s*:?\s*([a-z0-9]+)\b', caseSensitive: false);
  static final RegExp _genericUpiIdRegExp = RegExp(r'\b([a-zA-Z0-9\.\-_]+@[a-zA-Z]{3,})\b');
  static final RegExp _balanceRegExp = RegExp(r'\b(?:bal|balance|avail\s*bal|avbl\s*bal|limit|avail\s*limit)\s*(?:is)?\s*(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)', caseSensitive: false);

  static final RegExp _merchantRegExp = RegExp(
    r'\b(?:at|to|paid\s+to|spent\s+at|towards)\s+([a-z0-9\s\.\-_&@]+?)\s+(?:on|by|using|ref|vpa|rs\.?|inr|₹|\.|\bfor\b|\bwith\b|$)', 
    caseSensitive: false
  );

  Future<SmsAgentResult?> processSms(String body, DateTime smsDateTime) async {
    final lowerBody = body.toLowerCase();
    
    // Check if it contains transactional indicators
    final hasKeywords = lowerBody.contains('debited') ||
        lowerBody.contains('credited') ||
        lowerBody.contains('spent') ||
        lowerBody.contains('charged') ||
        lowerBody.contains('withdrawn') ||
        lowerBody.contains('payment') ||
        lowerBody.contains('received') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('pay') ||
        lowerBody.contains('deposited') ||
        lowerBody.contains('refund') ||
        lowerBody.contains('cashback') ||
        lowerBody.contains('salary') ||
        lowerBody.contains('interest') ||
        lowerBody.contains('emi');

    if (!hasKeywords) {
      return null;
    }

    double? amount;
    String? accountNum;
    String type = 'expense';
    String? matchedBank;
    double confidence = 0.0;

    // 1. Try to match specific Bank Templates
    for (final template in _bankTemplates) {
      if (lowerBody.contains(template.bankName.toLowerCase())) {
        matchedBank = template.bankName;
        
        // Try Debit Patterns
        for (final pattern in template.debitPatterns) {
          final match = pattern.firstMatch(body);
          if (match != null) {
            type = 'expense';
            // Extract values based on group order in patterns
            if (pattern.pattern.indexOf('rs') < pattern.pattern.indexOf('a/c')) {
              amount = double.tryParse(match.group(1)!.replaceAll(',', ''));
              accountNum = match.group(2);
            } else {
              accountNum = match.group(1);
              amount = double.tryParse(match.group(2)!.replaceAll(',', ''));
            }
            confidence = 1.0;
            break;
          }
        }

        // Try Credit Patterns (if debit didn't match)
        if (amount == null) {
          for (final pattern in template.creditPatterns) {
            final match = pattern.firstMatch(body);
            if (match != null) {
              type = 'income';
              if (pattern.pattern.indexOf('rs') < pattern.pattern.indexOf('a/c')) {
                amount = double.tryParse(match.group(1)!.replaceAll(',', ''));
                accountNum = match.group(2);
              } else {
                accountNum = match.group(1);
                amount = double.tryParse(match.group(2)!.replaceAll(',', ''));
              }
              confidence = 1.0;
              break;
            }
          }
        }
        
        if (amount != null) break;
      }
    }

    // 2. Generic Fallback if bank templates did not match
    if (amount == null) {
      final amtMatch = _genericAmountRegExp.firstMatch(body) ?? _fallbackAmountRegExp.firstMatch(body);
      if (amtMatch != null) {
        amount = double.tryParse(amtMatch.group(1)!.replaceAll(',', ''));
        
        final acctMatch = _genericAccountRegExp.firstMatch(body);
        accountNum = acctMatch?.group(1);
        
        if (lowerBody.contains('credited') || lowerBody.contains('received') || lowerBody.contains('deposited') || lowerBody.contains('salary') || lowerBody.contains('refund') || lowerBody.contains('cashback') || lowerBody.contains('interest')) {
          type = 'income';
        } else {
          type = 'expense';
        }

        // Attempt to extract bank name dynamically
        if (lowerBody.contains('sbi') || lowerBody.contains('state bank')) {
          matchedBank = 'SBI';
        } else if (lowerBody.contains('hdfc')) {
          matchedBank = 'HDFC';
        } else if (lowerBody.contains('icici')) {
          matchedBank = 'ICICI';
        } else if (lowerBody.contains('axis')) {
          matchedBank = 'Axis';
        } else if (lowerBody.contains('federal bank')) {
          matchedBank = 'Federal Bank';
        } else if (lowerBody.contains('kotak')) {
          matchedBank = 'Kotak';
        } else if (lowerBody.contains('canara')) {
          matchedBank = 'Canara';
        } else if (lowerBody.contains('union bank')) {
          matchedBank = 'Union Bank';
        } else if (lowerBody.contains('pnb') || lowerBody.contains('punjab national')) {
          matchedBank = 'PNB';
        } else if (lowerBody.contains('baroda') || lowerBody.contains('bob')) {
          matchedBank = 'Bank of Baroda';
        } else if (lowerBody.contains('idfc')) {
          matchedBank = 'IDFC';
        } else if (lowerBody.contains('indian bank')) {
          matchedBank = 'Indian Bank';
        } else if (lowerBody.contains('paytm')) {
          matchedBank = 'Paytm';
        } else if (lowerBody.contains('phonepe')) {
          matchedBank = 'PhonePe';
        } else if (lowerBody.contains('gpay') || lowerBody.contains('google pay')) {
          matchedBank = 'Google Pay';
        } else {
          matchedBank = 'Generic Banking';
        }
        
        confidence = 0.75;
      }
    }

    if (amount == null || amount <= 0) {
      dev.log('SmsAgent: Failed to parse valid transaction amount from SMS.');
      return null;
    }

    // 3. Extract Merchant
    String merchant = 'General Merchant';
    final merchantMatch = _merchantRegExp.firstMatch(body);
    if (merchantMatch != null) {
      final rawMerchant = merchantMatch.group(1)!.trim();
      if (rawMerchant.isNotEmpty && rawMerchant.length < 40) {
        merchant = _cleanMerchantName(rawMerchant);
      }
    }

    if (merchant == 'General Merchant' || merchant.isEmpty) {
      if (lowerBody.contains('atm') || lowerBody.contains('cash withdrawal')) {
        merchant = 'ATM Cash Withdrawal';
      } else {
        merchant = type == 'income' ? 'Cash/Bank Deposit' : 'Local Purchase';
      }
    }

    // 4. Extract UPI Reference ID
    String? referenceId;
    final refMatch = _genericUpiRefRegExp.firstMatch(body);
    if (refMatch != null) {
      referenceId = refMatch.group(1);
    }

    // 5. Extract UPI ID
    String? upiId;
    final upiMatch = _genericUpiIdRegExp.firstMatch(body);
    if (upiMatch != null) {
      upiId = upiMatch.group(1);
    }

    // 6. Extract Balance
    double? balance;
    final balMatch = _balanceRegExp.firstMatch(body);
    if (balMatch != null) {
      balance = double.tryParse(balMatch.group(1)!.replaceAll(',', ''));
    }

    // 7. Extract Payment Mode
    String? paymentMode = 'Other';
    if (lowerBody.contains('upi') || lowerBody.contains('phonepe') || lowerBody.contains('gpay') || lowerBody.contains('paytm') || lowerBody.contains('bhim') || upiId != null) {
      paymentMode = 'UPI';
    } else if (lowerBody.contains('atm') || lowerBody.contains('cash withdraw')) {
      paymentMode = 'ATM';
    } else if (lowerBody.contains('credit card') || lowerBody.contains(' spent on card ending')) {
      paymentMode = 'Credit Card';
    } else if (lowerBody.contains('debit card')) {
      paymentMode = 'Debit Card';
    } else if (lowerBody.contains('imps') || lowerBody.contains('neft') || lowerBody.contains('rtgs') || lowerBody.contains('net banking') || lowerBody.contains('netbanking')) {
      paymentMode = 'Net Banking';
    } else if (lowerBody.contains('pos') || lowerBody.contains('swipe')) {
      paymentMode = 'POS';
    } else if (lowerBody.contains('emi')) {
      paymentMode = 'EMI';
    } else if (lowerBody.contains('salary')) {
      paymentMode = 'Salary';
    } else if (lowerBody.contains('cashback') || lowerBody.contains('refund')) {
      paymentMode = 'Refund';
    } else if (lowerBody.contains('interest')) {
      paymentMode = 'Interest';
    }

    final accountName = '${matchedBank ?? "Bank"} A/c ${accountNum ?? "XXXX"}';

    final result = SmsAgentResult(
      amount: amount,
      merchant: merchant,
      transactionType: type,
      date: smsDateTime,
      account: accountName,
      bank: matchedBank,
      accountNumber: accountNum,
      balance: balance,
      referenceId: referenceId,
      upiId: upiId,
      paymentMode: paymentMode,
      confidence: confidence,
    );

    // 8. Log the Decision in the Database AgentLogs table
    try {
      await _db.agentLogDao.insertLog(
        AgentLog(
          id: const Uuid().v4(),
          agentName: 'SMS Transaction Agent',
          actionType: 'SMS_PARSED',
          decisionDescription: 'Parsed SMS successfully. Bank: $matchedBank, Amount: ₹$amount, Type: $type, Account: $accountName, Mode: $paymentMode',
          confidenceScore: confidence,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      dev.log('SmsAgent: Failed to save agent log: $e');
    }

    return result;
  }

  String _cleanMerchantName(String raw) {
    var cleaned = raw.replaceAll(RegExp(r'\s+'), ' ');
    // Strip trailing codes or "VPA"
    final indexRef = cleaned.toLowerCase().indexOf(RegExp(r'\b(?:ref|ref\s+no|upi|vpa|txn|rrn)\b'));
    if (indexRef != -1) {
      cleaned = cleaned.substring(0, indexRef).trim();
    }
    cleaned = cleaned.replaceAll(RegExp(r'[\.\-,\s/]+$'), '').trim();
    if (cleaned.isEmpty) return 'General Merchant';
    // Title Case
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ');
  }
}

final Provider<SmsAgent> smsAgentProvider = Provider<SmsAgent>((ref) {
  final db = ref.watch(databaseProvider);
  return SmsAgent(db);
});
