import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'dart:developer' as dev;
import 'package:crypto/crypto.dart';
import '../database/app_database.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'ai_provider_orchestrator.dart';
import 'sms_account_matcher.dart';

class SmsAgentResult {
  final double amount;
  final String merchant;
  final String transactionType; // 'expense', 'income', 'transfer', 'upcoming_bill', etc.
  final DateTime date;
  final String account; // e.g. "SBI A/c 1234"
  final String? bank;
  final String? accountNumber;
  final double? balance;
  final String? referenceId;
  final String? upiId;
  final String? paymentMode;
  final double confidence;
  final String category; // SMS Category e.g. OTP, Income, Expense, Internal Transfer
  final String? accountType; // Savings Account, Current Account, UPI, Wallet, Credit Card, Loan, Investment
  final String? billStatus; // pending, paid
  final DateTime? dueDate;
  final String? categoryOverrideId; // categoryId override from manual edit learning
  final double bankConfidence;
  final double amountConfidence;
  final double accountConfidence;
  final double categoryConfidence;
  final double merchantConfidence;

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
    required this.category,
    this.accountType,
    this.billStatus,
    this.dueDate,
    this.categoryOverrideId,
    this.bankConfidence = 1.0,
    this.amountConfidence = 1.0,
    this.accountConfidence = 1.0,
    this.categoryConfidence = 1.0,
    this.merchantConfidence = 1.0,
  });

  @override
  String toString() {
    return 'SmsAgentResult(amount: $amount, merchant: $merchant, type: $transactionType, account: $account, bank: $bank, acctNo: $accountNumber, bal: $balance, ref: $referenceId, upi: $upiId, mode: $paymentMode, confidence: $confidence, category: $category, accountType: $accountType, billStatus: $billStatus, dueDate: $dueDate, bankConf: $bankConfidence, amtConf: $amountConfidence, acctConf: $accountConfidence, catConf: $categoryConfidence, merConf: $merchantConfidence)';
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
  final Ref? _ref;

  SmsAgent(this._db, [this._ref]);

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
  static final RegExp _fallbackAmountRegExp = RegExp(r'\b(?:debited|credited|spent|withdrawn|charged|payment\s+of|sent|transferred|for|of)\s*(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)\b', caseSensitive: false);
  static final RegExp _genericAccountRegExp = RegExp(r'\b(?:a/c|card|ending|xx|x|no\.?)\s*(?:no\.?|ending)?\s*(?:\*+|x+|[a-z]*)\s*(\d{3,4})\b', caseSensitive: false);
  static final RegExp _genericUpiRefRegExp = RegExp(r'\b(?:upi\s*ref|ref\s*no|txn|vpa|ref|rrn|transaction\s*id|txid|neft\s*ref|imps\s*ref|neft|imps)\s*(?:no\.?)?\s*:?\s*([a-z0-9]+)\b', caseSensitive: false);
  static final RegExp _genericUpiIdRegExp = RegExp(r'\b([a-zA-Z0-9\.\-_]+@[a-zA-Z]{3,})\b');
  static final RegExp _balanceRegExp = RegExp(r'\b(?:bal|balance|avail\s*bal|avbl\s*bal|limit|avail\s*limit)\s*(?:is)?\s*(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)', caseSensitive: false);

  /// Classify SMS into one of the specific categories
  String classifySms(String body, [String? userName]) {
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

    // Cashback
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

    // Internal Transfer / Transfer to self
    // Handled at top priority

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

    // Cashback
    if (lowerBody.contains('reward credit') || lowerBody.contains('cashback earned') || lowerBody.contains('credit card cashback') || lowerBody.contains('cashback credited') || lowerBody.contains('received cashback') || lowerBody.contains('points redeemed') || lowerBody.contains('cashback of')) {
      return 'Cashback';
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

    if (lowerBody.contains('debited') || lowerBody.contains('spent') || lowerBody.contains('paid to') || lowerBody.contains('sent') || lowerBody.contains('transferred') || lowerBody.contains('transaction of') || lowerBody.contains('made using') || lowerBody.contains('purchase')) {
      return 'Shopping'; // Default expense fallback
    }

    return 'Unknown';
  }

  /// Detect account type dynamically (NEVER returns 'UPI' or 'upi')
  String detectAccountType(String body, String category) {
    final lowerBody = body.toLowerCase();
    if (category == 'Credit Card Purchase' ||
        category == 'Credit Card Bill Reminder' ||
        category == 'Credit Card Payment' ||
        lowerBody.contains('credit card') ||
        lowerBody.contains('creditcard') ||
        lowerBody.contains('card ending') ||
        lowerBody.contains('cc ending') ||
        lowerBody.contains('card xx') ||
        lowerBody.contains('outstanding') ||
        lowerBody.contains('available credit') ||
        lowerBody.contains('pixel go') ||
        lowerBody.contains('simplyclick') ||
        lowerBody.contains('simply click') ||
        lowerBody.contains('coral') ||
        lowerBody.contains('amazon pay icici')) {
      return 'Credit Card';
    }
    final isExplicitWallet = lowerBody.contains('wallet top-up') ||
        lowerBody.contains('topup') ||
        lowerBody.contains('wallet credit') ||
        lowerBody.contains('added to wallet') ||
        lowerBody.contains('wallet balance');

    if (isExplicitWallet) {
      return 'Wallet';
    }
    if (category == 'Investment' || lowerBody.contains('mutual fund') || lowerBody.contains('sip') || lowerBody.contains('fd') || lowerBody.contains('ppf') || lowerBody.contains('stocks')) {
      return 'Investment';
    }
    if (category == 'Loan EMI' || category == 'Loan Disbursement' || lowerBody.contains('loan') || lowerBody.contains('emi')) {
      return 'Loan';
    }
    return 'Savings Account';
  }

  /// Parse due date dynamically from SMS text
  DateTime? _parseDueDate(String body, DateTime smsDateTime) {
    final dateReg1 = RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4}|\d{2})\b');
    final match1 = dateReg1.firstMatch(body);
    if (match1 != null) {
      final day = int.tryParse(match1.group(1)!) ?? 1;
      final month = int.tryParse(match1.group(2)!) ?? 1;
      var year = int.tryParse(match1.group(3)!) ?? smsDateTime.year;
      if (year < 100) year += 2000;
      return DateTime(year, month, day);
    }
    
    final dateReg2 = RegExp(
      r'\b(\d{1,2})(?:\s+|-)(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*(?:\s+|-)?(\d{4}|\d{2})?\b', 
      caseSensitive: false
    );
    final match2 = dateReg2.firstMatch(body);
    if (match2 != null) {
      final day = int.tryParse(match2.group(1)!) ?? 1;
      final monthStr = match2.group(2)!.toLowerCase();
      final monthsMap = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
      };
      final month = monthsMap[monthStr] ?? 1;
      var year = smsDateTime.year;
      if (match2.group(3) != null) {
        year = int.tryParse(match2.group(3)!) ?? smsDateTime.year;
        if (year < 100) year += 2000;
      }
      return DateTime(year, month, day);
    }
    
    return smsDateTime.add(const Duration(days: 15));
  }

  DateTime _parseTransactionDate(String body, DateTime defaultDate) {
    // Matches dd/mm/yyyy or dd/mm/yy or dd-mm-yyyy or dd-mm-yy
    final dateReg = RegExp(
      r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4}|\d{2})\b'
    );
    final match = dateReg.firstMatch(body);
    if (match != null) {
      final day = int.tryParse(match.group(1)!) ?? defaultDate.day;
      final month = int.tryParse(match.group(2)!) ?? defaultDate.month;
      var year = int.tryParse(match.group(3)!) ?? defaultDate.year;
      if (year < 100) {
        year += 2000;
      }
      try {
        return DateTime(year, month, day, defaultDate.hour, defaultDate.minute, defaultDate.second);
      } catch (_) {}
    }
    return defaultDate;
  }

  Future<void> _logRejection(String body, String reason, String? sender) async {
    final cleanBody = body.replaceAll('\n', ' ').trim();
    dev.log('[Rejection] SMS was not imported. Reason: $reason. Message: "$cleanBody"');
    try {
      await _db.agentLogDao.insertLog(
        AgentLog(
          id: const Uuid().v4(),
          agentName: 'SMS Transaction Agent',
          actionType: 'SMS_REJECTED',
          decisionDescription: "Rejected SMS. Reason: $reason. Sender: ${sender ?? 'Unknown'}. Body: \"$cleanBody\"",
          confidenceScore: 0.0,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      dev.log('SmsAgent: Failed to save agent rejection log: $e');
    }
  }

  Future<SmsAgentResult?> processSms(String body, DateTime smsDateTime, {String? userId, String? sender}) async {
    final cleanBody = body.replaceAll('\n', ' ').trim();
    dev.log('[SMS Read] Received: "$cleanBody" (Sender: "${sender ?? 'Unknown'}", Date: "$smsDateTime")');
    
    // 1. Save to RawSms Database table
    final rawId = const Uuid().v4();
    await _db.into(_db.rawSms).insert(
      RawSmsCompanion.insert(
        id: rawId,
        body: body,
        sender: sender ?? 'Unknown',
        receivedAt: smsDateTime,
        createdAt: DateTime.now(),
      ),
    );

    // 2. Classify SMS
    String? userName;
    if (userId != null) {
      try {
        final user = await (_db.select(_db.users)..where((u) => u.id.equals(userId))).getSingleOrNull();
        userName = user?.displayName;
      } catch (e) {
        dev.log('SmsAgent: Failed to fetch user info: $e');
      }
    }
    final category = classifySms(body, userName);
    dev.log('[Classification] Category: $category');
    final resolvedDate = _parseTransactionDate(body, smsDateTime);

    // 3. Extract Fields
    double? amount;
    if (category == 'Credit Card Bill Generated' || category == 'Credit Card Bill Reminder') {
      final totalDueRegExp = RegExp(r'(?:total\s+due|total\s+amt\s+due|total\s+amount\s+due|due\s+amount|due\s+amt)\s*(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)', caseSensitive: false);
      final totalDueMatch = totalDueRegExp.firstMatch(body);
      if (totalDueMatch != null) {
        amount = double.tryParse(totalDueMatch.group(1)!.replaceAll(',', ''));
      }
    }
    if (amount == null) {
      final amtMatch = _genericAmountRegExp.firstMatch(body) ?? _fallbackAmountRegExp.firstMatch(body);
      if (amtMatch != null) {
        amount = double.tryParse(amtMatch.group(1)!.replaceAll(',', ''));
      }
    }

    final acctMatch = _genericAccountRegExp.firstMatch(body);
    final accountNum = acctMatch?.group(1);

    String? referenceId;
    final refMatch = _genericUpiRefRegExp.firstMatch(body);
    if (refMatch != null) {
      referenceId = refMatch.group(1);
    }

    String? upiId;
    final upiMatch = _genericUpiIdRegExp.firstMatch(body);
    if (upiMatch != null) {
      upiId = upiMatch.group(1);
    }

    double? balance;
    final balMatch = _balanceRegExp.firstMatch(body);
    if (balMatch != null) {
      balance = double.tryParse(balMatch.group(1)!.replaceAll(',', ''));
    }

    final lowerBody = body.toLowerCase();
    String? matchedBank = SmsAccountMatcher.extractBankName(body, sender: sender);

    String? cardName;
    if (lowerBody.contains('pixel go')) {
      cardName = 'Pixel Go';
    } else if (lowerBody.contains('simplyclick') || lowerBody.contains('simply click')) {
      cardName = 'SimplyCLICK';
    } else if (lowerBody.contains('coral')) {
      cardName = 'Coral';
    } else if (lowerBody.contains('amazon pay icici')) {
      cardName = 'Amazon Pay ICICI';
    }

    final accountType = detectAccountType(body, category);

    bool isDebit = true;
    if (lowerBody.contains('credited') || lowerBody.contains('received') || lowerBody.contains('deposited') || category == 'Salary' || category == 'Refund' || category == 'Cashback') {
      isDebit = false;
    }

    String? paymentMode = SmsAccountMatcher.detectPaymentMethod(
      smsText: body,
      accountType: accountType == 'Credit Card' ? 'credit_card' : (accountType == 'Wallet' ? 'wallet' : 'savings'),
    );

    String merchant = _extractMerchant(cleanBody, isDebit ? 'expense' : 'income', category);
    if (merchant.isEmpty || merchant == 'General Merchant') {
      if (lowerBody.contains('atm') || lowerBody.contains('cash withdrawal')) {
        merchant = 'ATM Cash Withdrawal';
      } else {
        merchant = isDebit ? 'Local Purchase' : 'Cash/Bank Deposit';
      }
    }

    DateTime? dueDate = _parseDueDate(body, smsDateTime);
    int? billAmt;
    int? minDueAmt;
    if (category == 'Credit Card Bill Generated' || category == 'Credit Card Bill Reminder') {
      billAmt = amount != null ? (amount * 100).round() : null;
      final minDueReg = RegExp(
        r'(?:minimum\s+due|min\s+due|minimum\s+amount\s+due|min\s+amt\s+due)\s*(?:is)?\s*(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)', 
        caseSensitive: false
      );
      final minDueMatch = minDueReg.firstMatch(body);
      if (minDueMatch != null) {
        final val = double.tryParse(minDueMatch.group(1)!.replaceAll(',', ''));
        if (val != null) minDueAmt = (val * 100).round();
      }
    }

    String transactionType = isDebit ? 'expense' : 'income';
    if (category == 'Credit Card Bill Generated' || category == 'Credit Card Bill Reminder' || category == 'EMI Reminder') {
      transactionType = 'upcoming_bill';
    } else if (category == 'Credit Card Payment') {
      transactionType = 'credit_card_payment';
    } else if (category == 'Internal Transfer' || category == 'ATM Withdrawal') {
      transactionType = 'transfer';
    } else if (category == 'Refund') {
      transactionType = 'refund';
    } else if (category == 'Cashback') {
      transactionType = 'cashback';
    } else if (category == 'Loan Disbursement') {
      transactionType = 'loan';
    } else if (category == 'Investment') {
      transactionType = 'investment';
    }

    // 4. Evaluate Ignore Rules (Requirement 12)
    final ignoreCategories = [
      'OTP', 'Security Alert', 'Promotional', 'Balance Alert',
      'Reward Points / Cashback Notification', 'General Bill/EMI Reminder', 'Unknown', 'Spam', 'Failed Transaction', 'Account Alert'
    ];
    if (ignoreCategories.contains(category)) {
      await _logRejection(body, 'Ignored Category: $category', sender);
      return null;
    }

    if (amount == null || amount <= 0) {
      await _logRejection(body, 'No valid transaction amount found', sender);
      return null;
    }

    // Generate duplicate fingerprint hash
    final String cleanBankForHash = matchedBank ?? '';
    final String cleanAccForHash = accountNum ?? '';
    final int cleanAmtForHash = (amount * 100).round();
    final String cleanMerchantForHash = merchant;
    final String keyForHash = "${referenceId ?? ''}_${cleanBankForHash}_${cleanAccForHash}_${cleanAmtForHash}_${cleanMerchantForHash}_${isDebit}_${resolvedDate.millisecondsSinceEpoch}_$transactionType";
    final String duplicateHash = md5.convert(utf8.encode(keyForHash)).toString();

    // Confidence scores
    double resolvedConfidence = 0.95;
    if (category == 'Unknown' || merchant == 'General Merchant' || merchant == 'Local Purchase') {
      resolvedConfidence = 0.85;
    } else if (matchedBank == 'Generic' || accountNum == null) {
      resolvedConfidence = 0.88;
    } else if (category == 'Shopping' || category == 'Bills') {
      resolvedConfidence = 0.89;
    }

    if (transactionType == 'transfer') {
      bool destFound = false;
      if (userId != null && merchant.isNotEmpty) {
        try {
          final existingAccounts = await (_db.select(_db.accounts)..where((a) => a.userId.equals(userId))).get();
          for (var acc in existingAccounts) {
            final cleanBank = (acc.bankName ?? '').toLowerCase();
            final cleanName = acc.name.toLowerCase();
            final mLower = merchant.toLowerCase();
            if (cleanBank.isNotEmpty && (mLower.contains(cleanBank) || cleanBank.contains(mLower))) {
              destFound = true;
              break;
            }
            if (cleanName.contains(mLower) || mLower.contains(cleanName)) {
              destFound = true;
              break;
            }
          }
        } catch (_) {}
      }
      if (!destFound) {
        resolvedConfidence = 0.85;
      }
    }

    // Save to ParsedSms Database table
    final parsedId = const Uuid().v4();
    await _db.into(_db.parsedSms).insert(
      ParsedSmsCompanion.insert(
        id: parsedId,
        smsId: Value(rawId),
        sender: Value(sender ?? 'Unknown'),
        receivedAt: Value(resolvedDate),
        bankName: Value(matchedBank),
        accountType: Value(accountType),
        accountLast4: Value(accountNum),
        cardType: Value(cardName),
        merchant: Value(merchant),
        amount: Value((amount * 100).round()),
        isDebit: Value(isDebit),
        availableBalance: Value(balance != null ? (balance * 100).round() : null),
        referenceNumber: Value(referenceId),
        upiId: Value(upiId),
        paymentMethod: Value(paymentMode),
        purpose: const Value(null),
        billAmount: Value(billAmt),
        minDue: Value(minDueAmt),
        outstandingAmount: const Value(null),
        dueDate: Value(dueDate),
        statementDate: const Value(null),
        paymentDate: const Value(null),
        category: Value(category),
        subcategory: const Value(null),
        transactionType: Value(transactionType),
        confidenceScore: Value(resolvedConfidence),
        duplicateHash: Value(duplicateHash),
        createdAt: DateTime.now(),
      ),
    );

    // Unique Account name format: [Bank Name] [Account Type] ****[Last Four Digits]
    final String cleanBank = matchedBank ?? "Bank";
    final String cleanType = accountType;
    final String cleanLast4 = accountNum != null ? "****$accountNum" : "****XXXX";
    String accountName = "$cleanBank $cleanType $cleanLast4";
    if (lowerBody.contains('pixel go')) {
      accountName = "HDFC Pixel Go ${accountNum ?? '1234'}";
    }

    final result = SmsAgentResult(
      amount: amount,
      merchant: merchant,
      transactionType: transactionType,
      date: resolvedDate,
      account: accountName,
      bank: matchedBank,
      accountNumber: accountNum,
      balance: balance,
      referenceId: referenceId,
      upiId: upiId,
      paymentMode: paymentMode,
      confidence: resolvedConfidence,
      category: category,
      accountType: accountType,
      billStatus: category == 'Credit Card Payment' ? 'paid' : (category.endsWith('Reminder') || category.contains('Generated') ? 'pending' : null),
      dueDate: dueDate,
    );

    // Log the Decision
    try {
      await _db.agentLogDao.insertLog(
        AgentLog(
          id: const Uuid().v4(),
          agentName: 'SMS Transaction Agent',
          actionType: 'SMS_PARSED',
          decisionDescription: 'Parsed SMS successfully. Category: $category, Bank: $matchedBank, Amount: ₹$amount, Type: $transactionType, Account: $accountName',
          confidenceScore: resolvedConfidence,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      dev.log('SmsAgent: Failed to save agent log: $e');
    }

    dev.log('[SMS Parsed] Amount: $amount, Type: $transactionType, Account: $accountNum, Merchant: $merchant, Date: $resolvedDate, Ref: $referenceId');

    // AI Validation Gate (Requirement 9)
    final isValid = await validateSmsWithAI(body, result);
    if (!isValid) {
      await _logRejection(body, 'AI Validation failed or returned low confidence', sender);
      return null;
    }

    return result;
  }

  Future<bool> _runLocalAiValidation(String body, String category, double amount, String type, DateTime date) async {
    final lowerBody = body.toLowerCase();
    
    if (category.endsWith('Reminder') || category.contains('Generated')) {
      return true; // Valid bill reminder
    }

    final completedKeywords = [
      'debited', 'spent', 'paid', 'purchase', 'withdrawal', 'cash withdrawal', 
      'pos purchase', 'upi success', 'imps success', 'neft success', 'rtgs success', 
      'atm withdrawal', 'credited', 'deposited', 'received', 'refund', 'payment towards', 
      'thank you for payment', 'transaction', 'renewed', 'subscription', 'renewal', 'billed',
      'payment', 'disbursed', 'disbursement', 'reward', 'reward credit', 'transfer', 'sip',
      'sent', 'transferred'
    ];

    bool hasCompletedKeyword = completedKeywords.any((kw) => lowerBody.contains(kw));
    if (!hasCompletedKeyword) {
      return false;
    }

    return true;
  }

  Future<bool> validateSmsWithAI(String body, SmsAgentResult parsed) async {
    final localVal = await _runLocalAiValidation(body, parsed.category, parsed.amount, parsed.transactionType, parsed.date);
    if (!localVal) return false;

    if (_ref != null) {
      try {
        final config = _ref!.read(aiProviderOrchestratorProvider);
        if (config.aiMode == 'online') {
          final orchestrator = _ref!.read(aiProviderOrchestratorProvider.notifier);
          
          final prompt = """
You are a banking SMS validator. Analyze the message and reply in EXACT JSON format.
SMS: "$body"

JSON Schema:
{
  "is_real_completed_transaction": boolean, // true if debited, spent, paid, credited, deposited, received, or cc payment made
  "is_bill_reminder": boolean, // true if statement generated, payment due, minimum due, EMI due reminder
  "confidence": number // 0.0 to 1.0
}
""";

          final response = await orchestrator.getChatResponse(prompt, 'system');
          final responseText = response.reply;
          
          final startJson = responseText.indexOf('{');
          final endJson = responseText.lastIndexOf('}');
          if (startJson != -1 && endJson != -1) {
            final jsonStr = responseText.substring(startJson, endJson + 1);
            final Map<String, dynamic> data = jsonDecode(jsonStr);
            final isReal = data['is_real_completed_transaction'] as bool? ?? false;
            final isReminder = data['is_bill_reminder'] as bool? ?? false;
            final confidence = (data['confidence'] as num? ?? 0.0).toDouble();
            
            if (confidence >= 0.70) {
              if (parsed.transactionType == 'upcoming_bill') {
                return isReminder;
              }
              return isReal;
            }
          }
        }
      } catch (e) {
        dev.log('SmsAgent AI validation online error: $e. Falling back to local validation success.');
      }
    }

    return true; // fallback to local validation success
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

  String _extractMerchant(String body, String type, String category) {
    final lowerBody = body.toLowerCase();
    
    // For transfer, the destination bank is usually after "to" or "->" or "transfer to"
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
    
    // Find keywords based on transaction direction
    final keywords = (type == 'income' || category == 'Refund' || category == 'Cashback')
        ? ['transfer from', 'received from', 'refund from', 'cashback from', 'by', 'from']
        : ['paid to', 'spent at', 'towards', 'merchant', 'at', 'to'];
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
    
    return '';
  }
}

final Provider<SmsAgent> smsAgentProvider = Provider<SmsAgent>((ref) {
  final db = ref.watch(databaseProvider);
  return SmsAgent(db, ref);
});
