import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/app_database.dart';
import 'sms_account_matcher.dart';
import 'ledger_agent.dart';

// Extracted transaction record representation
class ExtractedTransaction {
  final double amount;
  final String? bankName;
  final String? accountNumber;
  final String? referenceId;
  final bool isDebit;
  final DateTime date;
  final String merchant;
  final double confidence;

  ExtractedTransaction({
    required this.amount,
    this.bankName,
    this.accountNumber,
    this.referenceId,
    required this.isDebit,
    required this.date,
    required this.merchant,
    this.confidence = 1.0,
  });

  int get amountInCents => (amount * 100).round();
}

class ValidationResult {
  final bool isValid;
  final List<String> failures;
  final double confidence;

  ValidationResult({
    required this.isValid,
    required this.failures,
    required this.confidence,
  });
}

class TransactionEngineResult {
  final String normalizedBody;
  final String category;
  final ExtractedTransaction extracted;
  final SmsAccountMatchResult accountMatch;
  final bool isDuplicate;
  final String? duplicateTxId;
  final ValidationResult validation;

  TransactionEngineResult({
    required this.normalizedBody,
    required this.category,
    required this.extracted,
    required this.accountMatch,
    required this.isDuplicate,
    this.duplicateTxId,
    required this.validation,
  });
}

// 1. SmsNormalizer
class SmsNormalizer {
  String normalize(String body) {
    return body.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

// 2. FinancialSmsClassifier
class FinancialSmsClassifier {
  String classify(String body, [String? userName]) {
    final lowerBody = body.toLowerCase();

    // 0. Self Transfer (Highest priority)
    bool isSelf = false;
    if (lowerBody.contains('transfer to self') ||
        lowerBody.contains('self transfer') ||
        lowerBody.contains('transfer to own') ||
        lowerBody.contains('own account transfer') ||
        lowerBody.contains('transferred to own account') ||
        lowerBody.contains('transfer to my account') ||
        (lowerBody.contains('transfer') && lowerBody.contains('own a/c'))) {
      isSelf = true;
    } else if (userName != null && userName.isNotEmpty && lowerBody.contains(userName.toLowerCase())) {
      if (lowerBody.contains('sent') || 
          lowerBody.contains('transfer') || 
          lowerBody.contains('credited') || 
          lowerBody.contains('debited') ||
          lowerBody.contains('paid') ||
          lowerBody.contains('received') ||
          lowerBody.contains('to') ||
          lowerBody.contains('from')) {
        isSelf = true;
      }
    } else {
      final banksPattern = r'(?:sbi|state bank|hdfc|icici|axis|kotak|pnb|punjab national|canara|union|federal|idfc|yes bank|rbl|hsbc|citi|paytm|airtel)';
      final bankToBankRegex = RegExp(
        '\\b$banksPattern\\s+(?:to|->|transfer to|sent to)\\s+$banksPattern\\b',
        caseSensitive: false,
      );

      if (bankToBankRegex.hasMatch(body)) {
        isSelf = true;
      }
    }

    if (isSelf) {
      return 'Internal Transfer';
    }
    
    // 1. OTP Check
    if (lowerBody.contains('otp') ||
        lowerBody.contains('verification code') ||
        lowerBody.contains('login code') ||
        lowerBody.contains('auth code') ||
        (lowerBody.contains('code is') && !lowerBody.contains('credited') && !lowerBody.contains('debited'))) {
      return 'OTP';
    }

    // 2. Security Alert
    if (lowerBody.contains('login attempt') ||
        lowerBody.contains('password reset') ||
        lowerBody.contains('card blocked') ||
        lowerBody.contains('security alert') ||
        lowerBody.contains('kyc alert') ||
        lowerBody.contains('kyc update') ||
        lowerBody.contains('verify your account')) {
      return 'Security Alert';
    }

    // 3. Promotional
    if (lowerBody.contains('loan offer') ||
        lowerBody.contains('credit card offer') ||
        lowerBody.contains('cashback offer') ||
        lowerBody.contains('discounts') ||
        lowerBody.contains('promo') ||
        lowerBody.contains('offering') ||
        lowerBody.contains('pre-approved') ||
        lowerBody.contains('apply now')) {
      return 'Promotional';
    }

    // 4. Balance Alerts (Ignore)
    if ((lowerBody.contains('bal') || lowerBody.contains('balance') || lowerBody.contains('available limit') || lowerBody.contains('credit limit')) &&
        !lowerBody.contains('debited') &&
        !lowerBody.contains('spent') &&
        !lowerBody.contains('paid') &&
        !lowerBody.contains('purchase') &&
        !lowerBody.contains('withdrawal') &&
        !lowerBody.contains('credited') &&
        !lowerBody.contains('received') &&
        !lowerBody.contains('deposited')) {
      return 'Balance Alert';
    }

    // Cashback Check (before reward points/notifications)
    if (lowerBody.contains('reward credit') || 
        (lowerBody.contains('cashback earned') && (lowerBody.contains('credit') || lowerBody.contains('rs') || lowerBody.contains('₹') || lowerBody.contains('inr'))) || 
        lowerBody.contains('credit card cashback') || 
        lowerBody.contains('cashback credited') || 
        lowerBody.contains('received cashback') || 
        lowerBody.contains('points redeemed') || 
        lowerBody.contains('cashback of')) {
      return 'Cashback';
    }

    // 5. Reward Points / Cashback Notifications (Ignore)
    if (lowerBody.contains('reward points') ||
        lowerBody.contains('points earned') ||
        (lowerBody.contains('cashback earned') && !lowerBody.contains('credit') && !lowerBody.contains('rs') && !lowerBody.contains('₹') && !lowerBody.contains('inr')) ||
        lowerBody.contains('won cashback') ||
        (lowerBody.contains('cashback') && !lowerBody.contains('credited') && !lowerBody.contains('received') && !lowerBody.contains('deposited'))) {
      return 'Reward Points / Cashback Notification';
    }

    // 6. Credit Card Bill Reminder / Bill Alerts (checked early to avoid expense misclassification)
    if (lowerBody.contains('total due') ||
        lowerBody.contains('total amount due') ||
        lowerBody.contains('total amt due') ||
        lowerBody.contains('tot due') ||
        lowerBody.contains('statement generated') ||
        lowerBody.contains('statement cycle') ||
        lowerBody.contains('minimum due') ||
        lowerBody.contains('min due') ||
        lowerBody.contains('minimum amount due') ||
        lowerBody.contains('min amt due') ||
        lowerBody.contains('payment due') ||
        lowerBody.contains('payment due reminder') ||
        lowerBody.contains('emi due') ||
        lowerBody.contains('emi due reminder') ||
        lowerBody.contains('due reminder') ||
        (lowerBody.contains('due') && lowerBody.contains('date')) ||
        (lowerBody.contains('bill') && lowerBody.contains('due'))) {
      return 'Credit Card Bill Reminder';
    }

    // 7. General Bill/EMI reminders (non-CC) - (Ignore)
    if ((lowerBody.contains('bill due') || lowerBody.contains('payment due') || lowerBody.contains('emi due') || lowerBody.contains('due date') || lowerBody.contains('bill reminder')) &&
        !lowerBody.contains('credit card') &&
        !lowerBody.contains('card ending') &&
        !lowerBody.contains('simplyclick') &&
        !lowerBody.contains('pixel go') &&
        !lowerBody.contains('spent') &&
        !lowerBody.contains('debited') &&
        !lowerBody.contains('paid')) {
      return 'General Bill/EMI Reminder';
    }

    // Salary (Income)
    if (lowerBody.contains('salary credited') ||
        lowerBody.contains('salary of') ||
        lowerBody.contains('salary for')) {
      return 'Salary';
    }

    // ATM Withdrawal
    if (lowerBody.contains('atm') || lowerBody.contains('cash withdrawal') || lowerBody.contains('cash dispensed') || lowerBody.contains('dispensed') || lowerBody.contains('withdrawn from atm') || lowerBody.contains('withdrew')) {
      return 'ATM Withdrawal';
    }

    // Hospital / Healthcare
    if (lowerBody.contains('hospital') || lowerBody.contains('clinic') || lowerBody.contains('apollo') || lowerBody.contains('doctor') || lowerBody.contains('dentist') || lowerBody.contains('healthcare')) {
      return 'Hospital';
    }

    // Medical / Pharmacy
    if (lowerBody.contains('pharmacy') || lowerBody.contains('medical') || lowerBody.contains('medicine') || lowerBody.contains('pharma') || lowerBody.contains('apothecary')) {
      return 'Medical';
    }

    // Fuel
    if (lowerBody.contains('fuel') || lowerBody.contains('petrol') || lowerBody.contains('diesel') || lowerBody.contains('shell') || lowerBody.contains('hpcl') || lowerBody.contains('bpcl') || lowerBody.contains('iocl') || lowerBody.contains('gas station')) {
      return 'Fuel';
    }

    // Restaurant / Food delivery
    if (lowerBody.contains('swiggy') || lowerBody.contains('zomato') || lowerBody.contains('starbucks') || lowerBody.contains('mcdonald') || lowerBody.contains('kfc') || lowerBody.contains('burger') || lowerBody.contains('cafe') || lowerBody.contains('restaurant') || lowerBody.contains('hotel') || lowerBody.contains('pizza')) {
      return 'Restaurant';
    }

    // Groceries
    if (lowerBody.contains('grocery') || lowerBody.contains('groceries') || lowerBody.contains('dmart') || lowerBody.contains('blinkit') || lowerBody.contains('zepto') || lowerBody.contains('bigbasket') || lowerBody.contains('instamart') || lowerBody.contains('supermarket')) {
      return 'Groceries';
    }

    // Subscription
    if (lowerBody.contains('netflix') || lowerBody.contains('spotify') || lowerBody.contains('prime membership') || lowerBody.contains('youtube premium') || lowerBody.contains('subscription renewal') || lowerBody.contains('auto-renewal') || lowerBody.contains('subscription of') || lowerBody.contains('renewed subscription')) {
      return 'Subscription';
    }

    // Entertainment
    if (lowerBody.contains('movie') || lowerBody.contains('pvr') || lowerBody.contains('cinema') || lowerBody.contains('playstation') || lowerBody.contains('xbox') || lowerBody.contains('gaming') || lowerBody.contains('ticket') || lowerBody.contains('entertainment') || lowerBody.contains('show')) {
      return 'Entertainment';
    }

    // Recharge
    if (lowerBody.contains('recharge') || lowerBody.contains('mobile recharge') || lowerBody.contains('topup') || lowerBody.contains('talktime')) {
      return 'Recharge';
    }

    // Bills (Electricity, Water, Gas, Broadband, etc.)
    if (lowerBody.contains('bill') || lowerBody.contains('utility') || lowerBody.contains('electricity') || lowerBody.contains('water') || lowerBody.contains('gas') || lowerBody.contains('broadband') || lowerBody.contains('wifi') || lowerBody.contains('internet') || lowerBody.contains('invoice')) {
      return 'Bills';
    }

    // Travel (Cab, Taxi, Flight, Train, Metro, Bus, etc.)
    if (lowerBody.contains('uber') || lowerBody.contains('ola') || lowerBody.contains('cab') || lowerBody.contains('taxi') || lowerBody.contains('metro') || lowerBody.contains('irctc') || lowerBody.contains('flight') || lowerBody.contains('train') || lowerBody.contains('makemytrip') || lowerBody.contains('airbnb') || lowerBody.contains('indigo') || lowerBody.contains('travel')) {
      return 'Travel';
    }

    // Education
    if (lowerBody.contains('school') || lowerBody.contains('college') || lowerBody.contains('tuition') || lowerBody.contains('fees') || lowerBody.contains('course') || lowerBody.contains('udemy') || lowerBody.contains('coursera') || lowerBody.contains('book')) {
      return 'Education';
    }

    // Investment
    if (lowerBody.contains('zerodha') || lowerBody.contains('groww') || lowerBody.contains('mutual fund') || lowerBody.contains('stocks') || lowerBody.contains('etf') || lowerBody.contains('sip debited') || lowerBody.contains('investment of') || lowerBody.contains('invested in') || lowerBody.contains('fixed deposit') || lowerBody.contains('fd created')) {
      return 'Investment';
    }

    // Loan / EMI
    if (lowerBody.contains('loan disbursed') ||
        lowerBody.contains('disbursement of loan') ||
        lowerBody.contains('loan disbursement') ||
        (lowerBody.contains('loan') && lowerBody.contains('disbursed')) ||
        lowerBody.contains('disbursed to a/c')) {
      return 'Loan Disbursement';
    }
    if (lowerBody.contains('loan emi') ||
        lowerBody.contains('emi debited') ||
        lowerBody.contains('emi payment') ||
        lowerBody.contains('monthly installment') ||
        lowerBody.contains('emi of') ||
        (lowerBody.contains('emi') && lowerBody.contains('debited'))) {
      return 'Loan EMI';
    }
    if (lowerBody.contains('loan') || lowerBody.contains('emi') || lowerBody.contains('installment') || lowerBody.contains('mortgage')) {
      return 'Loan';
    }

    // Shopping (Amazon, Flipkart, etc. if not matched by groceries)
    if (lowerBody.contains('amazon') || lowerBody.contains('flipkart') || lowerBody.contains('myntra') || lowerBody.contains('zara') || lowerBody.contains('shopping') || lowerBody.contains('store') || lowerBody.contains('mart') || lowerBody.contains('mall') || lowerBody.contains('pos purchase') || lowerBody.contains('spent at')) {
      return 'Shopping';
    }

    // Refund
    if (lowerBody.contains('refund credited') || lowerBody.contains('refund received') || lowerBody.contains('reversal') || lowerBody.contains('cashback reversal') || lowerBody.contains('refund of') || lowerBody.contains('refund from')) {
      return 'Refund';
    }

    // Credit Card Payment
    if (lowerBody.contains('outstanding reduced') ||
        lowerBody.contains('card payment successful') ||
        lowerBody.contains('payment towards credit card') ||
        lowerBody.contains('received towards credit card') ||
        lowerBody.contains('payment towards card') ||
        lowerBody.contains('payment towards') ||
        lowerBody.contains('thank you for payment') ||
        (lowerBody.contains('payment') && lowerBody.contains('towards') && (lowerBody.contains('card') || lowerBody.contains('credit card'))) ||
        (lowerBody.contains('payment received') && (lowerBody.contains('card') || lowerBody.contains('credit card')))) {
      return 'Credit Card Payment';
    }

    // General fallback matches
    if (lowerBody.contains('credited') || lowerBody.contains('received') || lowerBody.contains('deposited')) {
      return 'Salary'; // Default income fallback
    }

    if (lowerBody.contains('debited') || lowerBody.contains('spent') || lowerBody.contains('paid') || lowerBody.contains('sent') || lowerBody.contains('transferred') || lowerBody.contains('transaction of') || lowerBody.contains('made using') || lowerBody.contains('purchase') || lowerBody.contains('payment')) {
      return 'Shopping'; // Default expense fallback
    }

    return 'Unknown';
  }
}

// 3. RuleBasedTransactionParser
class RuleBasedTransactionParser {
  ExtractedTransaction parse(String body, DateTime date, String? sender, String category) {
    double? amount;
    if (category == 'Credit Card Bill Generated' || category == 'Credit Card Bill Reminder') {
      final totalDueRegExp = RegExp(r'(?:total\s+due|total\s+amt\s+due|total\s+amount\s+due|due\s+amount|due\s+amt)\s*(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)', caseSensitive: false);
      final totalDueMatch = totalDueRegExp.firstMatch(body);
      if (totalDueMatch != null) {
        amount = double.tryParse(totalDueMatch.group(1)!.replaceAll(',', ''));
      }
    }
    if (amount == null) {
      final amtMatch = RegExp(r'(?:rs\.?|inr|₹|\$|usd)\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body) ??
                       RegExp(r'\b(?:debited|credited|spent|withdrawn|charged|payment\s+of|sent|transferred|for|of)\s*(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)\b', caseSensitive: false).firstMatch(body);
      if (amtMatch != null) {
        amount = double.tryParse(amtMatch.group(1)!.replaceAll(',', ''));
      }
    }

    String? accountNum;
    final acctMatch = RegExp(r'\b(?:a/c|card|ending|xx|x|no\.?)\s*(?:no\.?|ending)?\s*(?:\*+|x+|[a-z]*)\s*(\d{3,4})\b', caseSensitive: false).firstMatch(body);
    if (acctMatch != null) {
      accountNum = acctMatch.group(1);
    }

    String? referenceId;
    final refMatch = RegExp(r'\b(?:upi\s*ref|ref\s*no|txn|vpa|ref|rrn|transaction\s*id|txid|neft\s*ref|imps\s*ref|neft|imps)\s*(?:no\.?)?\s*:?\s*([a-z0-9]+)\b', caseSensitive: false).firstMatch(body);
    if (refMatch != null) {
      referenceId = refMatch.group(1);
    }

    final bankName = SmsAccountMatcher.extractBankName(body, sender: sender);

    final lower = body.toLowerCase();
    bool isDebit = true;
    if (lower.contains('credited') || 
        lower.contains('received') || 
        lower.contains('deposited') || 
        category == 'Salary' || 
        category == 'Refund' || 
        category == 'Cashback') {
      isDebit = false;
    }

    return ExtractedTransaction(
      amount: amount ?? 0.0,
      bankName: bankName,
      accountNumber: accountNum,
      referenceId: referenceId,
      isDebit: isDebit,
      date: _parseTransactionDate(body, date),
      merchant: _extractMerchant(body, isDebit, category),
      confidence: 1.0,
    );
  }

  DateTime _parseTransactionDate(String body, DateTime defaultDate) {
    final dateReg3Part = RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4}|\d{2})\b');
    var match = dateReg3Part.firstMatch(body);
    if (match != null) {
      final day = int.tryParse(match.group(1)!) ?? defaultDate.day;
      final month = int.tryParse(match.group(2)!) ?? defaultDate.month;
      var year = int.tryParse(match.group(3)!) ?? defaultDate.year;
      if (year < 100) year += 2000;
      try {
        return DateTime(year, month, day, defaultDate.hour, defaultDate.minute, defaultDate.second);
      } catch (_) {}
    }

    final dateReg2Part = RegExp(r'\b(\d{1,2})[\/\-](\d{1,2})\b');
    match = dateReg2Part.firstMatch(body);
    if (match != null) {
      final day = int.tryParse(match.group(1)!) ?? defaultDate.day;
      final month = int.tryParse(match.group(2)!) ?? defaultDate.month;
      try {
        return DateTime(defaultDate.year, month, day, defaultDate.hour, defaultDate.minute, defaultDate.second);
      } catch (_) {}
    }

    return defaultDate;
  }

  String _extractMerchant(String body, bool isDebit, String category) {
    final lower = body.toLowerCase();

    if (category == 'Internal Transfer') {
      final transferReg = RegExp(r'\b(?:transfer\s+to|to|->)\s+([a-z0-9\s]+?)\b', caseSensitive: false);
      final match = transferReg.firstMatch(body);
      if (match != null) {
        final dest = match.group(1)!.trim();
        if (dest.isNotEmpty && dest.length < 30) {
          return _cleanMerchantName(dest);
        }
      }
    }

    final keywords = isDebit 
        ? ['paid to', 'spent at', 'towards', 'merchant', 'at', 'to']
        : ['received from', 'refund from', 'by', 'from'];
    for (var kw in keywords) {
      final reg = RegExp('\\b${RegExp.escape(kw)}\\b', caseSensitive: false);
      final match = reg.firstMatch(body);
      if (match != null) {
        final index = match.start;
        var start = index + kw.length;
        // Skip spaces
        while (start < body.length && (body[start] == ' ' || body[start] == ':')) {
          start++;
        }
        
        // Match until a boundary word or character
        var end = start;
        while (end < body.length) {
          final char = body[end];
          final substring = body.substring(end).toLowerCase();
          if (substring.startsWith(' on ') ||
              substring.startsWith(' by ') ||
              substring.startsWith(' using ') ||
              substring.startsWith(' ref ') ||
              substring.startsWith(' vpa ') ||
              substring.startsWith(' rs') ||
              substring.startsWith(' inr') ||
              substring.startsWith(' ₹') ||
              substring.startsWith(' txn') ||
              char == '.' ||
              char == ',' ||
              char == ';') {
            break;
          }
          end++;
        }
        
        final candidate = body.substring(start, end).trim();
        if (candidate.isNotEmpty && candidate.length < 40 && !candidate.toLowerCase().contains('account') && !candidate.toLowerCase().contains('credit card') && !candidate.toLowerCase().contains('card ending')) {
          return _cleanMerchantName(candidate);
        }
      }
    }

    return isDebit ? 'Local Purchase' : 'Deposit';
  }

  String _cleanMerchantName(String raw) {
    var cleaned = raw.replaceAll(RegExp(r'\s+'), ' ');
    final indexRef = cleaned.toLowerCase().indexOf(RegExp(r'\b(?:ref|ref\s+no|upi|vpa|txn|rrn)\b'));
    if (indexRef != -1) {
      cleaned = cleaned.substring(0, indexRef).trim();
    }
    cleaned = cleaned.replaceAll(RegExp(r'[\.\-,\s/]+$'), '').trim();
    if (cleaned.isEmpty) return 'General Merchant';
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ');
  }
}

// 4. OfflineAiTransactionParser (Optional Model abstraction)
abstract class OfflineTransactionModel {
  ExtractedTransaction? analyze(String text);
}

class RuleBasedTransactionModel implements OfflineTransactionModel {
  @override
  ExtractedTransaction? analyze(String text) {
    return null; 
  }
}

class LocalClassifierModel implements OfflineTransactionModel {
  @override
  ExtractedTransaction? analyze(String text) => null;
}

class LocalLLMTransactionModel implements OfflineTransactionModel {
  @override
  ExtractedTransaction? analyze(String text) => null;
}

class OfflineAiTransactionParser {
  final OfflineTransactionModel model;

  OfflineAiTransactionParser(this.model);

  ExtractedTransaction? parse(String text) {
    return model.analyze(text);
  }
}

// 5. TransactionResultFusion
class TransactionResultFusion {
  ExtractedTransaction fuse(ExtractedTransaction ruleResult, ExtractedTransaction? aiResult) {
    if (aiResult == null) return ruleResult;

    bool hasConflict = false;
    double fusedConfidence = ruleResult.confidence;

    if ((ruleResult.amount - aiResult.amount).abs() > 0.01) {
      hasConflict = true;
    }
    if (ruleResult.isDebit != aiResult.isDebit) {
      hasConflict = true;
    }

    if (hasConflict) {
      fusedConfidence = 0.75;
    }

    return ExtractedTransaction(
      amount: ruleResult.amount > 0 ? ruleResult.amount : aiResult.amount,
      bankName: ruleResult.bankName ?? aiResult.bankName,
      accountNumber: ruleResult.accountNumber ?? aiResult.accountNumber,
      referenceId: ruleResult.referenceId ?? aiResult.referenceId,
      isDebit: ruleResult.isDebit,
      date: ruleResult.date,
      merchant: ruleResult.merchant != 'Local Purchase' && ruleResult.merchant != 'Deposit' ? ruleResult.merchant : aiResult.merchant,
      confidence: fusedConfidence,
    );
  }
}

// 6. EvidenceValidator
class EvidenceValidator {
  bool validateEvidence(String rawSms, ExtractedTransaction extracted) {
    final body = rawSms.toLowerCase().replaceAll(',', '');

    // Check amount evidence
    if (extracted.amount > 0) {
      final amountStr = extracted.amount.toStringAsFixed(2);
      final amountShort = extracted.amount.toStringAsFixed(0);
      final hasAmount = body.contains(amountShort) || body.contains(amountStr) || body.contains(extracted.amount.toString());
      if (!hasAmount) return false;
    }

    // Check reference ID evidence
    if (extracted.referenceId != null && extracted.referenceId!.isNotEmpty) {
      if (!body.contains(extracted.referenceId!.toLowerCase())) return false;
    }

    // Check account number evidence
    if (extracted.accountNumber != null && extracted.accountNumber!.isNotEmpty) {
      if (!body.contains(extracted.accountNumber!.toLowerCase())) return false;
    }

    return true;
  }
}

// 7. AccountResolver
class AccountResolver {
  SmsAccountMatchResult resolve(String smsText, List<Account> existingAccounts, ExtractedTransaction extracted, String? sender) {
    return SmsAccountMatcher.matchAccount(
      smsText: smsText,
      existingAccounts: existingAccounts,
      cardOrAccount: extracted.accountNumber,
      sender: sender,
      rawBankName: extracted.bankName,
    );
  }
}

// 8. DuplicateDetector
class DuplicateDetector {
  final AppDatabase _db;

  DuplicateDetector(this._db);

  Future<Transaction?> detect(String userId, ExtractedTransaction result, String? accountId) async {
    if (result.referenceId != null && result.referenceId!.isNotEmpty) {
      final duplicateByRef = await (_db.select(_db.transactions)
        ..where((t) => t.userId.equals(userId) & 
                       t.referenceNumber.equals(result.referenceId!) & 
                       t.deletedAt.isNull())
        ..limit(1)
      ).getSingleOrNull();
      if (duplicateByRef != null) {
        return duplicateByRef;
      }
    }

    final startOfDay = DateTime(result.date.year, result.date.month, result.date.day);
    final endOfDay = startOfDay.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    
    final existingTxs = await (_db.select(_db.transactions)
      ..where((t) => t.userId.equals(userId) & 
                     t.amount.equals(result.amountInCents) &
                     t.date.isBetweenValues(startOfDay, endOfDay) &
                     t.deletedAt.isNull())
    ).get();

    for (var ext in existingTxs) {
      if (ext.accountId != null && accountId != null && ext.accountId != accountId) {
        continue;
      }
      final bool isExtDateOnly = ext.date.hour == 0 && ext.date.minute == 0 && ext.date.second == 0;
      final bool isNewDateOnly = result.date.hour == 0 && result.date.minute == 0 && result.date.second == 0;
      final bool timeWindowMatches = (isExtDateOnly || isNewDateOnly)
          ? true
          : ext.date.difference(result.date).inMinutes.abs() <= 35;
      if (!timeWindowMatches) continue;

      final extMerchant = (ext.merchant ?? '').toLowerCase().trim();
      final newMerchant = result.merchant.toLowerCase().trim();
      if (extMerchant == newMerchant || extMerchant.contains(newMerchant) || newMerchant.contains(extMerchant)) {
        return ext;
      }
    }

    return null;
  }
}

// 9. TransactionSafetyValidator
class TransactionSafetyValidator {
  final AppDatabase _db;

  TransactionSafetyValidator(this._db);

  Future<ValidationResult> validate({
    required ExtractedTransaction result,
    required SmsAccountMatchResult accountMatch,
    required bool isDuplicate,
    required String category,
    required String? sender,
    required bool evidenceValid,
  }) async {
    final List<String> failures = [];

    // Amount Checks
    if (result.amount <= 0) {
      failures.add('INVALID_AMOUNT');
    }

    // Ignore Non-Financial
    final ignoreCategories = [
      'OTP', 'Security Alert', 'Promotional', 'Balance Alert',
      'Reward Points / Cashback Notification', 'General Bill/EMI Reminder', 'Unknown', 'Spam', 'Failed Transaction', 'Account Alert'
    ];
    if (ignoreCategories.contains(category)) {
      failures.add('NON_FINANCIAL_CATEGORY');
    }

    // Evidence checks
    if (!evidenceValid) {
      failures.add('FAILED_EVIDENCE_VALIDATION');
    }

    // Account resolved check
    if (accountMatch.matchedAccount == null) {
      failures.add('ACCOUNT_NOT_RESOLVED');
    }

    // Duplicate transaction check
    if (isDuplicate) {
      failures.add('DUPLICATE_TRANSACTION');
    }

    // Ambiguity / Direction Check
    final isPossiblePromo = (sender ?? '').toUpperCase().length < 5 || 
                            (! (sender ?? '').contains('-') && ! (sender ?? '').toUpperCase().contains('BK') && ! (sender ?? '').toUpperCase().contains('BANK'));
    if (isPossiblePromo && category != 'TRANSACTION' && category != 'Credit Card Bill Reminder') {
      failures.add('SUSPICIOUS_SENDER');
    }

    // Compute parse confidence matching original SmsAgent logic
    double confidence = 0.95;
    if (category == 'Unknown' || result.merchant == 'General Merchant' || result.merchant == 'Local Purchase') {
      confidence = 0.85;
    } else if (result.bankName == 'Generic' || result.accountNumber == null) {
      confidence = 0.88;
    } else if (category == 'Shopping' || category == 'Bills') {
      confidence = 0.89;
    }

    if (result.referenceId != null && result.referenceId!.isNotEmpty) {
      confidence = 0.95;
    }

    if (isDuplicate) {
      confidence = 0.50;
    }

    return ValidationResult(
      isValid: failures.isEmpty,
      failures: failures,
      confidence: confidence,
    );
  }
}

// 10. TransactionSaver & ExpensoTransactionIntelligenceEngine Orchestrator
class TransactionSaver {
  final AppDatabase _db;

  TransactionSaver(this._db);

  Future<ReconciliationResult> save({
    required Transaction transaction,
    required LedgerAgent ledgerAgent,
    required int? balance,
  }) async {
    // Run everything in an atomic database transaction
    return await _db.transaction(() async {
      final res = await ledgerAgent.reconcileTransaction(
        transaction,
        confidence: transaction.confidenceScore ?? 1.0,
        importedBalance: balance,
      );
      return res;
    });
  }
}

class ExpensoTransactionIntelligenceEngine {
  final AppDatabase _db;
  final SmsNormalizer _normalizer;
  final FinancialSmsClassifier _classifier;
  final RuleBasedTransactionParser _ruleParser;
  final OfflineAiTransactionParser _aiParser;
  final TransactionResultFusion _fusion;
  final EvidenceValidator _evidenceValidator;
  final AccountResolver _accountResolver;
  final DuplicateDetector _duplicateDetector;
  final TransactionSafetyValidator _safetyValidator;
  final TransactionSaver _saver;

  ExpensoTransactionIntelligenceEngine(this._db)
      : _normalizer = SmsNormalizer(),
        _classifier = FinancialSmsClassifier(),
        _ruleParser = RuleBasedTransactionParser(),
        _aiParser = OfflineAiTransactionParser(RuleBasedTransactionModel()),
        _fusion = TransactionResultFusion(),
        _evidenceValidator = EvidenceValidator(),
        _accountResolver = AccountResolver(),
        _duplicateDetector = DuplicateDetector(_db),
        _safetyValidator = TransactionSafetyValidator(_db),
        _saver = TransactionSaver(_db);

  Future<TransactionEngineResult> processSms({
    required String body,
    required DateTime receivedAt,
    required String? sender,
    required String userId,
    required List<Account> existingAccounts,
  }) async {
    // 1. Normalization
    final normalized = _normalizer.normalize(body);

    // 2. Classification
    String? userName;
    if (userId.isNotEmpty) {
      try {
        final user = await (_db.select(_db.users)..where((u) => u.id.equals(userId))).getSingleOrNull();
        userName = user?.displayName;
      } catch (_) {}
    }
    final category = _classifier.classify(normalized, userName);

    // 3. Rule parser
    final ruleResult = _ruleParser.parse(normalized, receivedAt, sender, category);

    // 4. AI parser (stubs/model abstraction)
    final aiResult = _aiParser.parse(normalized);

    // 5. Result fusion
    final fusedResult = _fusion.fuse(ruleResult, aiResult);

    // 6. Evidence validation
    final evidenceValid = _evidenceValidator.validateEvidence(body, fusedResult);

    // 7. Account resolution
    final accountMatch = _accountResolver.resolve(normalized, existingAccounts, fusedResult, sender);

    // 8. Duplicate detection
    final duplicateResult = await _duplicateDetector.detect(userId, fusedResult, accountMatch.matchedAccount?.id);

    // 9. Safety validation
    final validation = await _safetyValidator.validate(
      result: fusedResult,
      accountMatch: accountMatch,
      isDuplicate: duplicateResult != null,
      category: category,
      sender: sender,
      evidenceValid: evidenceValid,
    );

    // 10. Engine result ready for Saver
    return TransactionEngineResult(
      normalizedBody: normalized,
      category: category,
      extracted: fusedResult,
      accountMatch: accountMatch,
      isDuplicate: duplicateResult != null,
      duplicateTxId: duplicateResult?.id,
      validation: validation,
    );
  }

  Future<ReconciliationResult> saveTransaction({
    required Transaction transaction,
    required LedgerAgent ledgerAgent,
    required int? balance,
  }) async {
    return await _saver.save(
      transaction: transaction,
      ledgerAgent: ledgerAgent,
      balance: balance,
    );
  }
}
