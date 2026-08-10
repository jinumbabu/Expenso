import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'dart:developer' as dev;
import 'package:crypto/crypto.dart';
import '../database/app_database.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/accounts/presentation/providers/account_formatters.dart';
import 'balance_engine.dart';
import 'notification_service.dart';
import 'sms_account_matcher.dart';

enum ReconciliationStatus { inserted, updated, merged, skipped, matchingManual }

class ReconciliationResult {
  final ReconciliationStatus status;
  final String? transactionId;
  final String? matchingManualId;

  ReconciliationResult({
    required this.status,
    this.transactionId,
    this.matchingManualId,
  });
}

class LedgerAgent {
  final AppDatabase _db;

  LedgerAgent(this._db);

  /// Reconciles a new transaction: checks for duplicates, merges if found,
  /// otherwise inserts and updates the associated account ledger balances.
  /// Generates a unique fingerprint for a transaction to prevent duplicates.
  String generateFingerprint({
    required String? accountId,
    required int amount,
    required String? merchant,
    required DateTime date,
    required String? referenceNumber,
  }) {
    final normAccount = (accountId ?? '').trim();
    final normAmount = amount.toString();
    final normMerchant = (merchant ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final normDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    final normRef = (referenceNumber ?? '').toLowerCase().trim();
    return "${normAccount}_${normAmount}_${normMerchant}_${normDate}_$normRef";
  }

  /// Reconciles a new transaction: checks for duplicates, merges if found,
  /// otherwise inserts and updates the associated account ledger balances.
  Future<ReconciliationResult> reconcileTransaction(Transaction newTx, {double confidence = 1.0, int? importedBalance}) async {
    dev.log('LedgerAgent DEBUG: Reconciling transaction. Merchant: ${newTx.merchant}, Amount: ${newTx.amount}, Type: ${newTx.type}');
    
    // 1. Reconcile Account Balance and get the account ID
    final balanceResult = await _reconcileAccountBalance(newTx, confidence);
    final accountId = balanceResult['accountId'] as String;
    final finalType = balanceResult['type'] as String;
    final referenceNumber = balanceResult['referenceNumber'] as String?;
    
    var txWithAccount = newTx.copyWith(
      accountId: Value(accountId),
      type: finalType,
      referenceNumber: Value(referenceNumber ?? newTx.referenceNumber),
    );

    // Fetch the account to get the type and name
    final account = await (_db.select(_db.accounts)..where((a) => a.id.equals(accountId))).getSingleOrNull();

    final parsedBank = SmsAccountMatcher.extractBankName('${newTx.description ?? ''} ${newTx.merchant ?? ''}', fallback: newTx.accountType);
    final parsedLast4 = SmsAccountMatcher.extractLast4(newTx.referenceNumber, '${newTx.description ?? ''} ${newTx.merchant ?? ''}');
    final paymentMethod = SmsAccountMatcher.detectPaymentMethod(smsText: newTx.description ?? '', accountType: account?.type ?? newTx.accountType ?? 'savings');

    dev.log('''
==================================================
=== SMS ACCOUNT RESOLUTION PIPELINE LOG ===
Detected Bank: $parsedBank
Detected Last Four Digits: ${parsedLast4 ?? 'None'}
Matched Existing Account: ${account?.displayTitle ?? account?.name ?? 'None'}
Matched Account ID: ${account?.id ?? 'None'}
Created New Account: ${newTx.accountId == null ? 'Yes' : 'No'}
Reason: Matched/Resolved account for SMS transaction
Assigned Transaction Account: ${account?.displayTitle ?? account?.name ?? 'Unknown'} ($accountId)
Payment Method: $paymentMethod
==================================================''');

    // 2. Duplicate detection using the centralized DuplicateHashes database (Requirement 5, 16)
    final String cleanBank = (account?.bankName ?? '').toLowerCase();
    final String cleanAcc = (account?.last4Digits ?? '').toLowerCase();
    final int cleanAmt = txWithAccount.amount.toInt();
    final String cleanMerchant = (txWithAccount.merchant ?? '').toLowerCase();
    final bool isDebit = finalType == 'expense' || finalType == 'transfer' || finalType == 'credit_card_payment';
    final int timestamp = txWithAccount.date.millisecondsSinceEpoch;
    
    final hashKey = "${txWithAccount.referenceNumber ?? ''}_${cleanBank}_${cleanAcc}_${cleanAmt}_${cleanMerchant}_${isDebit}_${timestamp}_$finalType";
    final hash = md5.convert(utf8.encode(hashKey)).toString();

    final duplicateHashEntry = await (_db.select(_db.duplicateHashes)
      ..where((t) => t.hash.equals(hash))
      ..limit(1)
    ).getSingleOrNull();

    if (duplicateHashEntry != null) {
      dev.log('LedgerAgent DEBUG: Duplicate detected via duplicate hashes table. Skipping reconciliation.');
      return ReconciliationResult(status: ReconciliationStatus.skipped, transactionId: duplicateHashEntry.transactionId);
    }

    // Generate and assign unique fingerprint (backwards compatibility)
    final fingerprint = generateFingerprint(
      accountId: accountId,
      amount: txWithAccount.amount.toInt(),
      merchant: txWithAccount.merchant,
      date: txWithAccount.date,
      referenceNumber: txWithAccount.referenceNumber,
    );
    txWithAccount = txWithAccount.copyWith(fingerprint: Value(fingerprint));

    // 3. Bill Lifecycle logic (Requirement 6): Bypasses normal Transactions table
    if (finalType == 'upcoming_bill') {
      dev.log('LedgerAgent DEBUG: Processing bill reminder/generated event. Creating/updating Bill object.');
      final billingCycle = "${txWithAccount.date.year}-${txWithAccount.date.month.toString().padLeft(2, '0')}";
      
      int? minDueCents;
      if (account != null && account.type == 'credit_card') {
        final minDueReg = RegExp(
          r'(?:minimum\s+due|min\s+due|minimum\s+amount\s+due|min\s+amt\s+due)\s*(?:is)?\s*(?:rs\.?|inr|₹|\$)?\s*([\d,]+\.?\d*)', 
          caseSensitive: false
        );
        final minDueMatch = minDueReg.firstMatch(txWithAccount.description ?? '');
        if (minDueMatch != null) {
          final val = double.tryParse(minDueMatch.group(1)!.replaceAll(',', ''));
          if (val != null) minDueCents = (val * 100).round();
        }
      }

      final existingBill = await (_db.select(_db.bills)
        ..where((b) => b.accountId.equals(accountId) & b.billingCycle.equals(billingCycle))
        ..limit(1)
      ).getSingleOrNull();

      if (existingBill != null) {
        final updatedBill = existingBill.copyWith(
          amount: txWithAccount.amount.toInt(),
          minDue: Value(minDueCents ?? existingBill.minDue),
          dueDate: Value(txWithAccount.dueDate ?? txWithAccount.date),
          status: 'pending',
          updatedAt: DateTime.now(),
        );
        await _db.update(_db.bills).replace(updatedBill);

        // Update Credit Card account due details if Credit Card
        if (account != null && account.type == 'credit_card') {
          final updatedCC = account.copyWith(
            totalAmountDue: Value(txWithAccount.amount.toInt()),
            minAmountDue: Value(minDueCents ?? (txWithAccount.amount.toInt() ~/ 20)),
            nextDueDate: Value(txWithAccount.dueDate ?? txWithAccount.date),
            paymentStatus: const Value('unpaid'),
            updatedAt: DateTime.now(),
          );
          await _db.accountDao.updateAccount(updatedCC);
        }

        // Record duplicate hash
        await _db.into(_db.duplicateHashes).insert(
          DuplicateHashesCompanion.insert(
            id: const Uuid().v4(),
            hash: hash,
            billId: Value(existingBill.id),
            createdAt: DateTime.now(),
          ),
        );
        
        return ReconciliationResult(status: ReconciliationStatus.updated, transactionId: existingBill.id);
      } else {
        final billId = const Uuid().v4();
        final bill = Bill(
          id: billId,
          userId: txWithAccount.userId,
          accountId: accountId,
          title: txWithAccount.merchant ?? txWithAccount.description ?? 'Bill',
          amount: txWithAccount.amount.toInt(),
          minDue: minDueCents ?? (txWithAccount.amount.toInt() ~/ 20), // default 5% min due
          dueDate: txWithAccount.dueDate ?? txWithAccount.date,
          status: 'pending',
          billingCycle: billingCycle,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _db.into(_db.bills).insert(bill);

        // Record duplicate hash
        await _db.into(_db.duplicateHashes).insert(
          DuplicateHashesCompanion.insert(
            id: const Uuid().v4(),
            hash: hash,
            billId: Value(billId),
            createdAt: DateTime.now(),
          ),
        );

        // Update Credit Card account due details if Credit Card
        if (account != null && account.type == 'credit_card') {
          final updatedCC = account.copyWith(
            totalAmountDue: Value(txWithAccount.amount.toInt()),
            minAmountDue: Value(minDueCents ?? (txWithAccount.amount.toInt() ~/ 20)),
            nextDueDate: Value(txWithAccount.dueDate ?? txWithAccount.date),
            paymentStatus: const Value('unpaid'),
            updatedAt: DateTime.now(),
          );
          await _db.accountDao.updateAccount(updatedCC);
        }

        return ReconciliationResult(status: ReconciliationStatus.inserted, transactionId: billId);
      }
    }

    // 4. Traditional Duplicate Transaction detection (for non-bill transactions, backwards compatibility)
    // Global reference number check (Requirement 11)
    if (txWithAccount.referenceNumber != null && txWithAccount.referenceNumber!.isNotEmpty) {
      final duplicateByRef = await (_db.select(_db.transactions)
        ..where((t) => t.userId.equals(txWithAccount.userId) & 
                       t.referenceNumber.equals(txWithAccount.referenceNumber!) & 
                       t.deletedAt.isNull())
        ..limit(1)
      ).getSingleOrNull();

      if (duplicateByRef != null) {
        dev.log('[Duplicate Check] Duplicate detected globally by reference number: ${txWithAccount.referenceNumber}');
        return ReconciliationResult(status: ReconciliationStatus.merged, transactionId: duplicateByRef.id);
      }
    }

    final existingWithFingerprint = await (_db.select(_db.transactions)
      ..where((t) => t.userId.equals(txWithAccount.userId) & t.fingerprint.equals(fingerprint) & t.deletedAt.isNull())
      ..limit(1)
    ).getSingleOrNull();

    if (existingWithFingerprint != null) {
      dev.log('[Duplicate Check] Duplicate Status: Duplicate detected by fingerprint. Merging with existing transaction: ${existingWithFingerprint.id}');
      return ReconciliationResult(status: ReconciliationStatus.merged, transactionId: existingWithFingerprint.id);
    }

    Transaction? duplicateTx;
    final startOfDay = DateTime(txWithAccount.date.year, txWithAccount.date.month, txWithAccount.date.day);
    final endOfDay = startOfDay.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    
    final existingTxs = await (_db.select(_db.transactions)
      ..where((t) => t.userId.equals(txWithAccount.userId) & 
                     t.amount.equals(txWithAccount.amount.toInt()) &
                     t.date.isBetweenValues(startOfDay, endOfDay) &
                     t.deletedAt.isNull())
    ).get();

    for (var ext in existingTxs) {
      // REQUIREMENT: Transactions from different accounts MUST NEVER be treated as duplicates!
      if (ext.accountId != null && txWithAccount.accountId != null && ext.accountId != txWithAccount.accountId) {
        continue;
      }

      final bool isExtDateOnly = ext.date.hour == 0 && ext.date.minute == 0 && ext.date.second == 0;
      final bool isNewDateOnly = txWithAccount.date.hour == 0 && txWithAccount.date.minute == 0 && txWithAccount.date.second == 0;
      
      final bool timeWindowMatches = (isExtDateOnly || isNewDateOnly || ext.source == 'manual' || txWithAccount.source == 'manual')
          ? true // same day match
          : ext.date.difference(txWithAccount.date).inMinutes.abs() <= 35;
          
      if (!timeWindowMatches) continue;

      final extMerchant = (ext.merchant ?? '').toLowerCase().trim();
      final newMerchant = (txWithAccount.merchant ?? '').toLowerCase().trim();
      final merchantMatches = extMerchant == newMerchant ||
                              extMerchant.contains(newMerchant) ||
                              newMerchant.contains(extMerchant) ||
                              (extMerchant.isEmpty && newMerchant.isEmpty);
      if (!merchantMatches) continue;

      final extRef = (ext.referenceNumber ?? '').trim().toLowerCase();
      final newRef = (txWithAccount.referenceNumber ?? '').trim().toLowerCase();
      final refMatches = extRef == newRef || extRef.isEmpty || newRef.isEmpty;
      if (!refMatches) continue;

      duplicateTx = ext;
      break;
    }

    if (duplicateTx != null) {
      if (txWithAccount.source == 'sms' && duplicateTx.source == 'manual') {
        dev.log('[Duplicate Check] Duplicate Status: Incoming SMS matches manual entry ${duplicateTx.id}. Merging manual entry with SMS details.');
      }

      dev.log('[Duplicate Check] Duplicate Status: Duplicate detected by field matches. Merging with existing transaction: ${duplicateTx.id}');
      
      final mergedDesc = _mergeStrings(duplicateTx.description, txWithAccount.description);
      final mergedMerchant = _mergeStrings(duplicateTx.merchant, txWithAccount.merchant) ?? 'Merged Merchant';

      // Merge supporting SMS lists
      List<String> smsList = [];
      if (duplicateTx.supportingSms != null && duplicateTx.supportingSms!.isNotEmpty) {
        try {
          smsList = List<String>.from(jsonDecode(duplicateTx.supportingSms!));
        } catch (_) {}
      }
      if (duplicateTx.description != null && !smsList.contains(duplicateTx.description)) {
        smsList.add(duplicateTx.description!);
      }
      final newSmsText = txWithAccount.description ?? txWithAccount.merchant ?? 'SMS Alert';
      if (!smsList.contains(newSmsText)) {
        smsList.add(newSmsText);
      }

      final mergedRef = (duplicateTx.referenceNumber == null || duplicateTx.referenceNumber!.isEmpty)
          ? txWithAccount.referenceNumber
          : duplicateTx.referenceNumber;

      final newFingerprint = generateFingerprint(
        accountId: duplicateTx.accountId,
        amount: duplicateTx.amount,
        merchant: mergedMerchant,
        date: duplicateTx.date,
        referenceNumber: mergedRef,
      );

      final mergedTx = duplicateTx.copyWith(
        description: Value(mergedDesc),
        merchant: Value(mergedMerchant),
        categoryId: Value(duplicateTx.categoryId ?? txWithAccount.categoryId),
        paymentMethodId: Value(duplicateTx.paymentMethodId ?? txWithAccount.paymentMethodId),
        referenceNumber: Value(mergedRef),
        fingerprint: Value(newFingerprint),
        supportingSms: Value(jsonEncode(smsList)),
        syncStatus: 'pending',
        updatedAt: DateTime.now(),
      );

      await _db.transactionDao.updateTransaction(mergedTx);

      await _db.agentLogDao.insertLog(
        AgentLog(
          id: const Uuid().v4(),
          agentName: 'Ledger Intelligence Agent',
          actionType: 'TRANSACTION_MERGED',
          decisionDescription: 'Auto-merged transaction ${txWithAccount.id} into existing ${duplicateTx.id}. Amount: ₹${txWithAccount.amount / 100.0}',
          confidenceScore: 0.95,
          timestamp: DateTime.now(),
        ),
      );
      
      final isMatchingManual = txWithAccount.source == 'sms' && duplicateTx.source == 'manual';
      final status = isMatchingManual ? ReconciliationStatus.matchingManual : ReconciliationStatus.merged;

      await _checkBalanceMismatch(accountId, importedBalance, txWithAccount.date);

      return ReconciliationResult(
        status: status,
        transactionId: isMatchingManual ? null : duplicateTx.id,
        matchingManualId: isMatchingManual ? duplicateTx.id : null,
      );
    }

    dev.log('[Duplicate Check] Duplicate Status: Not a duplicate (No matching transaction found within time window)');

    // 5. Insert new Transaction (Requirement 1)
    try {
      dev.log('[Database Insert] Attempting to insert transaction: ${txWithAccount.id} with account: $accountId');
      await _db.transactionDao.insertTransaction(txWithAccount);
      dev.log('[Database Insert] Status: Success (ID: ${txWithAccount.id})');
    } catch (e) {
      dev.log('[Database Insert] Status: Failure (Reason: $e)');
      rethrow;
    }
    await BalanceEngine(_db).reconcileOnAdd(txWithAccount);

    // Record duplicate hash
    await _db.into(_db.duplicateHashes).insert(
      DuplicateHashesCompanion.insert(
        id: const Uuid().v4(),
        hash: hash,
        transactionId: Value(txWithAccount.id),
        createdAt: DateTime.now(),
      ),
    );

    // 6. Reconcile CC payments (Requirement 7)
    if (finalType == 'credit_card_payment' || finalType == 'expense') {
      await _reconcileCreditCardPayment(txWithAccount);
    }

    await _checkBalanceMismatch(accountId, importedBalance, txWithAccount.date);

    return ReconciliationResult(status: ReconciliationStatus.inserted, transactionId: txWithAccount.id);
  }

  Future<void> _reconcileCreditCardPayment(Transaction paymentTx) async {
    dev.log('LedgerAgent DEBUG: Reconciling Credit Card Payment transaction: ${paymentTx.id}');
    final ccAccounts = await (_db.select(_db.accounts)
      ..where((a) => a.userId.equals(paymentTx.userId) & a.type.equals('credit_card'))
    ).get();

    for (var ccAcc in ccAccounts) {
      final unpaidBills = await (_db.select(_db.bills)
        ..where((b) => b.accountId.equals(ccAcc.id) & b.status.equals('paid').not())
        ..orderBy([(t) => OrderingTerm.asc(t.dueDate)])
      ).get();

      for (var bill in unpaidBills) {
        final dueDate = bill.dueDate ?? bill.createdAt;
        final inDuePeriod = paymentTx.date.isBefore(dueDate.add(const Duration(days: 5))) && 
                            paymentTx.date.isAfter(dueDate.subtract(const Duration(days: 32)));

        if (inDuePeriod) {
          dev.log('LedgerAgent DEBUG: Matched payment of ${paymentTx.amount} to bill ${bill.id}.');
          
          final currentCCDue = ccAcc.totalAmountDue ?? 0;
          final newCCDue = (currentCCDue - paymentTx.amount.toInt()).clamp(0, currentCCDue);
          final bool isFullyPaid = newCCDue <= 0;
          
          final updatedBill = bill.copyWith(
            status: isFullyPaid ? 'paid' : 'partially_paid',
            paymentTransactionId: Value(paymentTx.id),
            paymentSourceAccountId: Value(paymentTx.accountId),
            updatedAt: DateTime.now(),
          );
          await _db.update(_db.bills).replace(updatedBill);

          final currentOutstanding = ccAcc.outstandingBalance ?? 0;
          final newOutstanding = (currentOutstanding - paymentTx.amount.toInt()).clamp(0, currentOutstanding);
          final limit = ccAcc.creditLimit ?? 0;
          final newAvail = limit > 0 ? (limit - newOutstanding).clamp(0, limit) : null;

          final updatedCC = ccAcc.copyWith(
            outstandingBalance: Value(newOutstanding),
            availableCredit: Value(newAvail),
            totalAmountDue: Value(newCCDue),
            minAmountDue: Value(isFullyPaid ? 0 : ((ccAcc.minAmountDue ?? 0) - (paymentTx.amount.toInt() ~/ 20)).clamp(0, ccAcc.minAmountDue ?? 0)),
            paymentStatus: Value(isFullyPaid ? 'paid' : 'partially_paid'),
            updatedAt: DateTime.now(),
          );
          await _db.accountDao.updateAccount(updatedCC);

          // Soft-delete upcoming_bill reminders for this credit card
          final upcomingReminders = await (_db.select(_db.transactions)
            ..where((t) => t.accountId.equals(ccAcc.id) & 
                           (t.type.equals('upcoming_bill') | t.type.equals('credit_card_bill') | t.type.equals('credit_card_bill_reminder')) & 
                           t.deletedAt.isNull())
          ).get();
          for (var reminder in upcomingReminders) {
            final reminderCycle = "${reminder.date.year}-${reminder.date.month.toString().padLeft(2, '0')}";
            if (reminderCycle == bill.billingCycle || isFullyPaid) {
              final updatedReminder = reminder.copyWith(
                deletedAt: Value(DateTime.now()),
                billStatus: Value(isFullyPaid ? 'paid' : 'partially_paid'),
                updatedAt: DateTime.now(),
              );
              await _db.transactionDao.updateTransaction(updatedReminder);
            }
          }
          break;
        }
      }
    }

    // Legacy/backwards compatibility check for pending bills in Transactions table (to pass legacy tests)
    final legacyBills = await (_db.select(_db.transactions)
      ..where((t) => t.userId.equals(paymentTx.userId) & 
                     (paymentTx.accountId != null ? (t.accountId.equals(paymentTx.accountId!) | t.accountId.isNull()) : t.accountId.isNull()) &
                     (t.type.equals('upcoming_bill') | t.type.equals('credit_card_bill') | t.type.equals('credit_card_bill_reminder')) & 
                     (t.billStatus.equals('pending') | t.billStatus.isNull()) &
                     t.deletedAt.isNull())
    ).get();
    
    bool matchedBill = false;
    for (var bill in legacyBills) {
      final amountMatches = (bill.amount - paymentTx.amount).abs() < 1000; // within 10 rupees
      final due = bill.dueDate ?? bill.date;
      final inDuePeriod = paymentTx.date.isBefore(due.add(const Duration(days: 5))) && 
                          paymentTx.date.isAfter(due.subtract(const Duration(days: 30)));
      
      if (amountMatches && inDuePeriod) {
        dev.log('LedgerAgent DEBUG: Legacy Match found! Marking pending bill ${bill.id} as paid.');
        final updatedBill = bill.copyWith(
          billStatus: const Value('paid'),
          accountId: Value(paymentTx.accountId),
          paymentMethodId: Value(paymentTx.paymentMethodId),
          updatedAt: DateTime.now(),
        );
        await _db.transactionDao.updateTransaction(updatedBill);
        matchedBill = true;
        break;
      }
    }
  }

  Map<String, String> _detectAccountDetails(Transaction tx) {
    if (tx.description != null && (tx.description!.startsWith('SMS Alert: ') || tx.description!.startsWith('Mock SMS Alert: '))) {
      final nameRaw = tx.description!.startsWith('SMS Alert: ') 
          ? tx.description!.replaceFirst('SMS Alert: ', '') 
          : tx.description!.replaceFirst('Mock SMS Alert: ', '');
      
      String type = 'savings';
      if (tx.accountType != null) {
        final norm = tx.accountType!.toLowerCase().replaceAll(' ', '_');
        if (norm == 'credit_card' || norm == 'creditcard') {
          type = 'credit_card';
        } else if (norm == 'savings_account' || norm == 'savings') {
          type = 'savings';
        } else if (norm == 'wallet') {
          type = 'wallet';
        } else if (norm == 'investment') {
          type = 'investment';
        } else if (norm == 'loan') {
          type = 'loan';
        } else {
          type = 'savings';
        }
      } else {
        type = nameRaw.toLowerCase().contains('card') ? 'credit_card' : 'savings';
      }

      final bank = SmsAccountMatcher.extractBankName(nameRaw);
      final last4 = SmsAccountMatcher.extractLast4(tx.referenceNumber, nameRaw);
      final name = sanitizeAccountName(last4 != null ? '$bank $last4' : bank);

      final isCC = type == 'credit_card';
      return {
        'name': name,
        'type': type,
        'bank': bank,
        'color': isCC ? '0xFFFF3B30' : '0xFF0066FF',
        'icon': isCC ? 'credit_card' : 'account_balance',
      };
    }

    final searchSource = '${tx.description ?? ''} ${tx.merchant ?? ''} ${tx.referenceNumber ?? ''}';
    final bank = SmsAccountMatcher.extractBankName(searchSource);
    final last4 = SmsAccountMatcher.extractLast4(null, searchSource);

    final isCC = searchSource.toLowerCase().contains('credit') || searchSource.toLowerCase().contains('cc') || searchSource.toLowerCase().contains('card');
    final isExplicitWallet = (searchSource.toLowerCase().contains('wallet top') || searchSource.toLowerCase().contains('topup')) && searchSource.toLowerCase().contains('wallet');

    if (tx.source != 'sms' && bank == 'Bank' && last4 == null && !isCC && !isExplicitWallet) {
      return {
        'name': 'Cash Wallet',
        'type': 'cash',
        'bank': 'Cash',
        'color': '0xFF00E5FF',
        'icon': 'account_balance_wallet',
      };
    }

    final name = sanitizeAccountName(last4 != null ? '$bank $last4' : bank);
    final type = isCC ? 'credit_card' : (isExplicitWallet ? 'wallet' : 'savings');

    return {
      'name': name,
      'type': type,
      'bank': bank,
      'color': isCC ? '0xFFFF3B30' : (isExplicitWallet ? '0xFFFFB703' : '0xFF0066FF'),
      'icon': isCC ? 'credit_card' : (isExplicitWallet ? 'account_balance_wallet' : 'account_balance'),
    };
  }

  Future<Account> _getOrCreateAccount(
    String userId,
    String name,
    String type, {
    String? bankName,
    String? colorTheme,
    String? icon,
    bool isEstimated = false,
    int? openingBalance,
    int? initialBalance,
  }) async {
    final cleanName = sanitizeAccountName(name);
    var account = await (_db.select(_db.accounts)
      ..where((t) => t.name.equals(cleanName))
      ..limit(1)
    ).getSingleOrNull();

    if (account == null) {
      final now = DateTime.now();
      final isCC = type == 'credit_card';

      final int? opBal = isEstimated ? null : (openingBalance ?? (isCC ? 0 : 1000000));
      final int initBal = initialBalance ?? (isCC ? 0 : (isEstimated ? 0 : 1000000));

      final last4Match = RegExp(r'\b\d{4}\b').firstMatch(cleanName);
      final last4 = last4Match?.group(0);

      account = Account(
        id: const Uuid().v4(),
        userId: userId,
        name: cleanName,
        type: type,
        balance: initBal,
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        bankName: bankName ?? 'Bank',
        openingBalance: opBal,
        currency: 'INR',
        colorTheme: colorTheme ?? (isCC ? '0xFFFF3B30' : '0xFF0066FF'),
        icon: icon ?? (isCC ? 'credit_card' : 'account_balance'),
        isActive: true,
        creditLimit: isCC ? 10000000 : null, // ₹100,000 limit
        availableCredit: isCC ? 10000000 : null,
        outstandingBalance: isCC ? 0 : null,
        statementDate: isCC ? 15 : null,
        paymentDueDate: isCC ? 5 : null,
        paymentStatus: isCC ? 'paid' : null,
        autoPay: false,
        isEstimated: isEstimated,
        last4Digits: last4,
      );
      await _db.into(_db.accounts).insert(account);

      if (isCC) {
        try {
          await NotificationService().sendProactiveAlert(
            userId,
            title: 'New Credit Card Detected 💳',
            body: 'New Credit Card Detected. Complete setup.',
            priority: 'high',
          );
        } catch (e) {
          dev.log('LedgerAgent: Failed to trigger notification: $e');
        }
      }
    }
    return account;
  }

  Future<Account?> _findExistingAccount({
    required String userId,
    required String type,
    required String bankName,
    required String last4,
  }) async {
    final existingAccounts = await (_db.select(_db.accounts)
      ..where((a) => a.userId.equals(userId))
    ).get();

    final matchResult = SmsAccountMatcher.matchAccount(
      smsText: '$bankName $last4',
      existingAccounts: existingAccounts,
      cardOrAccount: last4,
      rawBankName: bankName,
      rawAccountType: type,
    );

    return matchResult.matchedAccount;
  }

  Future<Map<String, dynamic>> _reconcileAccountBalance(Transaction tx, double confidence) async {
    try {
      // 1. Handle Internal Transfer at top level
      if (tx.type == 'transfer') {
        Account? sourceAccount;
        if (tx.accountId != null && tx.accountId!.isNotEmpty) {
          sourceAccount = await (_db.select(_db.accounts)
            ..where((a) => a.id.equals(tx.accountId!))
            ..limit(1)
          ).getSingleOrNull();
        }
        if (sourceAccount == null) {
          final detected = _detectAccountDetails(tx);
          final accountName = detected['name']!;
          final accountType = detected['type']!;
          final bankName = detected['bank']!;
          final color = detected['color']!;
          final icon = detected['icon']!;

          final last4Match = RegExp(r'\b\d{3,4}\b').firstMatch(accountName);
          final last4 = last4Match?.group(0);

          if (last4 != null) {
            sourceAccount = await _findExistingAccount(
              userId: tx.userId,
              type: accountType,
              bankName: bankName,
              last4: last4,
            );
          }

          if (sourceAccount == null) {
            sourceAccount = await _getOrCreateAccount(
              tx.userId,
              accountName,
              accountType,
              bankName: bankName,
              colorTheme: color,
              icon: icon,
              isEstimated: tx.source == 'sms',
              openingBalance: tx.source == 'sms' ? null : tx.amount.toInt(),
              initialBalance: 0,
            );
          }
        }

        // Now handle destination account
        Account? destAccount;
        String destAccountName = 'Transfer Account';

        final isAtm = tx.merchant?.toLowerCase().contains('atm') == true ||
                      tx.merchant?.toLowerCase().contains('withdrawal') == true ||
                      tx.description?.toLowerCase().contains('atm') == true ||
                      tx.description?.toLowerCase().contains('withdrawal') == true ||
                      tx.accountType?.toLowerCase().contains('atm') == true;

        if (isAtm) {
          destAccount = await (_db.select(_db.accounts)
            ..where((a) => a.userId.equals(tx.userId) & a.type.equals('cash'))
            ..limit(1)
          ).getSingleOrNull();

          if (destAccount == null) {
            destAccount = await _getOrCreateAccount(
              tx.userId,
              'Cash Wallet',
              'cash',
              bankName: 'Cash',
              colorTheme: '0xFF00E5FF',
              icon: 'account_balance_wallet',
              isEstimated: false,
              openingBalance: 0,
              initialBalance: tx.amount.toInt(),
            );
          }
        } else if (tx.merchant != null && tx.merchant!.isNotEmpty && 
            tx.merchant != 'General Merchant' && tx.merchant != 'Cash/Bank Deposit' && tx.merchant != 'Local Purchase') {
          destAccountName = '${tx.merchant} A/c XXXX';
          
          final last4Match = RegExp(r'\b\d{3,4}\b').firstMatch(destAccountName);
          final last4 = last4Match?.group(0);

          destAccount = await _findExistingAccount(
            userId: tx.userId,
            type: 'savings',
            bankName: tx.merchant!,
            last4: last4 ?? 'XXXX',
          );

          if (destAccount == null) {
            final existingAccounts = await (_db.select(_db.accounts)
              ..where((a) => a.userId.equals(tx.userId))
            ).get();
            
            for (var existing in existingAccounts) {
              final destNameLower = tx.merchant!.toLowerCase();
              final existingNameLower = existing.name.toLowerCase();
              final existingBankLower = (existing.bankName ?? '').toLowerCase();
              if (existingNameLower.contains(destNameLower) || 
                  (existingNameLower.isNotEmpty && destNameLower.contains(existingNameLower)) || 
                  (existingBankLower.isNotEmpty && existingBankLower.contains(destNameLower)) || 
                  (existingBankLower.isNotEmpty && destNameLower.contains(existingBankLower))) {
                destAccount = existing;
                break;
              }
            }
          }
        }
        
        if (destAccount == null) {
          destAccount = await _getOrCreateAccount(
            tx.userId,
            destAccountName,
            'savings',
            bankName: tx.merchant ?? 'Transfer Destination',
            colorTheme: '0xFF0066FF',
            icon: 'account_balance',
            isEstimated: tx.source == 'sms',
            openingBalance: 0,
            initialBalance: tx.amount.toInt(),
          );
        }

        return {
          'accountId': sourceAccount.id,
          'type': 'transfer',
          'referenceNumber': destAccount.id,
        };
      }

      // 2. Handle Credit Card Payment at top level
      if (tx.type == 'credit_card_payment') {
        Account? ccAccount;
        if (tx.accountId != null && tx.accountId!.isNotEmpty) {
          ccAccount = await (_db.select(_db.accounts)
            ..where((a) => a.id.equals(tx.accountId!))
            ..limit(1)
          ).getSingleOrNull();
        }
        if (ccAccount == null) {
          final detected = _detectAccountDetails(tx);
          final accountName = detected['name']!;
          final bankName = detected['bank']!;
          final color = detected['color']!;
          final icon = detected['icon']!;

          final last4Match = RegExp(r'\b\d{3,4}\b').firstMatch(accountName);
          final last4 = last4Match?.group(0);

          if (last4 != null) {
            ccAccount = await _findExistingAccount(
              userId: tx.userId,
              type: 'credit_card',
              bankName: bankName,
              last4: last4,
            );
          }

          if (ccAccount == null) {
            ccAccount = await _getOrCreateAccount(
              tx.userId,
              accountName,
              'credit_card',
              bankName: bankName,
              colorTheme: color,
              icon: icon,
              isEstimated: tx.source == 'sms',
            );
          }
        }

        final savingsAccounts = await (_db.select(_db.accounts)
          ..where((a) => a.userId.equals(tx.userId) & a.type.equals('savings'))
        ).get();
        Account sourceAccount;
        if (savingsAccounts.isNotEmpty) {
          sourceAccount = savingsAccounts.first;
        } else {
          sourceAccount = await _getOrCreateAccount(
            tx.userId,
            'Main Savings A/c',
            'savings',
            bankName: 'Savings',
            colorTheme: '0xFF0066FF',
            icon: 'account_balance',
            isEstimated: tx.source == 'sms',
            openingBalance: tx.amount.toInt(),
            initialBalance: 0,
          );
        }

        await _reconcileCreditCardPayment(tx);

        return {
          'accountId': sourceAccount.id,
          'type': 'credit_card_payment',
          'referenceNumber': ccAccount.id,
        };
      }

      // 3. Normal transaction account matching/creation
      Account? account;
      if (tx.accountId != null && tx.accountId!.isNotEmpty) {
        account = await (_db.select(_db.accounts)
          ..where((a) => a.id.equals(tx.accountId!))
          ..limit(1)
        ).getSingleOrNull();
      }
      if (account == null && tx.referenceNumber != null && tx.referenceNumber!.isNotEmpty) {
        account = await (_db.select(_db.accounts)
          ..where((a) => a.userId.equals(tx.userId) & a.name.equals(tx.referenceNumber!))
          ..limit(1)
        ).getSingleOrNull();
      }

      if (account == null) {
        final detected = _detectAccountDetails(tx);
        final accountName = detected['name']!;
        final accountType = detected['type']!;
        final bankName = detected['bank']!;
        final color = detected['color']!;
        final icon = detected['icon']!;

        bool routedToSavings = false;
        if (accountType == 'wallet' && (accountName.contains('Google Pay') || accountName.contains('PhonePe') || accountName.contains('Paytm') || accountName.contains('Amazon Pay'))) {
          final bodyLower = (tx.description ?? '').toLowerCase();
          final isExplicitWalletActivity = bodyLower.contains('top-up') ||
                                           bodyLower.contains('topup') ||
                                           bodyLower.contains('cashback') ||
                                           bodyLower.contains('refund') ||
                                           bodyLower.contains('reward') ||
                                           bodyLower.contains('loaded') ||
                                           bodyLower.contains('added to wallet') ||
                                           bodyLower.contains('wallet balance');

          if (!isExplicitWalletActivity) {
            final savings = await (_db.select(_db.accounts)
              ..where((a) => a.userId.equals(tx.userId) & a.type.equals('savings'))
            ).get();
            if (savings.isNotEmpty) {
              account = savings.first;
            } else {
              account = await _getOrCreateAccount(
                tx.userId,
                'SBI Savings',
                'savings',
                bankName: 'State Bank of India',
                colorTheme: '0xFF0066FF',
                icon: 'account_balance',
                isEstimated: tx.source == 'sms',
                openingBalance: 0,
                initialBalance: 0,
              );
            }
            routedToSavings = true;
          }
        }

        if (!routedToSavings) {
          final existingAccounts = await (_db.select(_db.accounts)
            ..where((a) => a.userId.equals(tx.userId))
          ).get();

          final matchResult = SmsAccountMatcher.matchAccount(
            smsText: '${tx.description ?? ''} ${tx.merchant ?? ''}',
            existingAccounts: existingAccounts,
            cardOrAccount: tx.referenceNumber,
            rawBankName: bankName,
            rawAccountType: accountType,
          );

          if (matchResult.matchedAccount != null) {
            account = matchResult.matchedAccount;
            if (account!.last4Digits == null && matchResult.last4 != null) {
              final updatedAccount = account.copyWith(
                last4Digits: Value(matchResult.last4),
                updatedAt: DateTime.now(),
              );
              await _db.accountDao.updateAccount(updatedAccount);
              account = updatedAccount;
            }
          } else {
            account = await _getOrCreateAccount(
              tx.userId,
              matchResult.displayTitle,
              matchResult.accountType,
              bankName: matchResult.bankName,
              colorTheme: color,
              icon: icon,
              isEstimated: tx.source == 'sms',
              openingBalance: tx.source == 'sms' ? null : null,
              initialBalance: tx.source == 'sms' ? 0 : null,
            );
          }

          await _checkAndMergeDuplicates(tx.userId, account!, bankName);
        }
      }

      return {
        'accountId': account?.id ?? '',
        'type': tx.type,
      };
    } catch (e) {
      dev.log('LedgerAgent: Failed to reconcile: $e');
      final userAccounts = await (_db.select(_db.accounts)
        ..where((a) => a.userId.equals(tx.userId))
      ).get();

      Account fallbackAccount;
      if (tx.source == 'sms') {
        final nonCash = userAccounts.where((a) => a.type != 'cash').toList();
        fallbackAccount = nonCash.isNotEmpty
            ? nonCash.firstWhere((a) => a.isDefault, orElse: () => nonCash.first)
            : (userAccounts.isNotEmpty ? userAccounts.first : await _getOrCreateAccount(
                tx.userId,
                'Primary Account',
                'savings',
                bankName: 'Bank',
              ));
      } else {
        fallbackAccount = await _getOrCreateAccount(
          tx.userId,
          'Cash Wallet',
          'cash',
          bankName: 'Cash',
          colorTheme: '0xFF00E5FF',
          icon: 'account_balance_wallet',
        );
      }
      return {
        'accountId': fallbackAccount.id,
        'type': tx.type,
      };
    }
  }

  Future<void> _checkAndMergeDuplicates(String userId, Account account, String bankName) async {
    final resolvedLast4 = account.last4Digits ?? (account.name.contains(RegExp(r'\b\d{4}\b')) ? RegExp(r'\b\d{4}\b').firstMatch(account.name)?.group(0) : null);
    if (resolvedLast4 == null) return;

    final otherAccounts = await (_db.select(_db.accounts)
      ..where((a) => a.userId.equals(userId) & a.id.equals(account.id).not())
    ).get();

    Account? genericDuplicate;
    for (var other in otherAccounts) {
      if (other.type != account.type) continue;

      final otherLast4 = other.last4Digits ?? (other.name.contains(RegExp(r'\b\d{4}\b')) ? RegExp(r'\b\d{4}\b').firstMatch(other.name)?.group(0) : null);
      if (otherLast4 != null) continue; // specific account, don't merge

      // Check if bank name matches
      final otherBankNormalized = (other.bankName ?? other.name).toLowerCase();
      final bankMatches = otherBankNormalized.contains(bankName.toLowerCase()) || 
                          bankName.toLowerCase().contains(otherBankNormalized) ||
                          other.name.toLowerCase().contains(bankName.toLowerCase());

      if (bankMatches) {
        genericDuplicate = other;
        break;
      }
    }

    if (genericDuplicate != null) {
      await _mergeAccounts(genericDuplicate, account);
    }
  }

  Future<void> _mergeAccounts(Account source, Account destination) async {
    dev.log('LedgerAgent: Merging account ${source.id} (${source.name}) into ${destination.id} (${destination.name})');

    // 1. Move all transactions from source to destination
    await (_db.update(_db.transactions)
      ..where((t) => t.accountId.equals(source.id))
    ).write(TransactionsCompanion(accountId: Value(destination.id)));

    // 2. Move any transactions where source is the reference (transfers, bills, etc.)
    await (_db.update(_db.transactions)
      ..where((t) => t.referenceNumber.equals(source.id))
    ).write(TransactionsCompanion(referenceNumber: Value(destination.id)));

    // 3. Move payment methods
    await (_db.update(_db.paymentMethods)
      ..where((t) => t.accountId.equals(source.id))
    ).write(PaymentMethodsCompanion(accountId: Value(destination.id)));

    // 4. Update the destination account's opening balance if destination opening balance is null and source has one
    if (destination.openingBalance == null && source.openingBalance != null) {
      await _db.accountDao.updateAccount(destination.copyWith(
        openingBalance: Value(source.openingBalance),
      ));
    }

    // 5. Delete the source account
    await (_db.delete(_db.accounts)..where((a) => a.id.equals(source.id))).go();

    // 6. Recalculate balances
    await BalanceEngine(_db).recalculateAllBalances();
  }



  String? _mergeStrings(String? a, String? b) {
    if (a == null || a.isEmpty) return b;
    if (b == null || b.isEmpty) return a;
    if (a.toLowerCase() == b.toLowerCase()) return a;
    if (a.toLowerCase().contains(b.toLowerCase())) return a;
    if (b.toLowerCase().contains(a.toLowerCase())) return b;
    if (a.startsWith('SMS Alert:') && b.startsWith('SMS Alert:')) return a;
    return '$a / $b';
  }

  /// Checks if the calculated balance matches the imported balance, and auto-reconciles or flags mismatch.
  Future<void> _checkBalanceMismatch(String accountId, int? importedBalance, DateTime txDate) async {
    if (importedBalance == null) return;

    final updatedAccount = await (_db.select(_db.accounts)..where((a) => a.id.equals(accountId))).getSingleOrNull();
    if (updatedAccount != null) {
      final expected = updatedAccount.type == 'credit_card'
          ? (updatedAccount.outstandingBalance ?? 0)
          : updatedAccount.balance;
      final diff = (expected - importedBalance).abs();

      if (diff > 0) {
        if (diff <= 50000) {
          // Auto-reconcile: update verifiedBalance to importedBalance
          final toUpdate = updatedAccount.copyWith(
            verifiedBalance: Value(importedBalance),
            verifiedAt: Value(txDate),
            importedBalance: Value(importedBalance),
            hasMismatch: const Value(false),
            mismatchExpected: const Value(null),
            mismatchImported: const Value(null),
            updatedAt: DateTime.now(),
          );
          await _db.accountDao.updateAccount(toUpdate);
          await BalanceEngine(_db).recalculateAllBalances(accountId: accountId);

          await _db.agentLogDao.insertLog(
            AgentLog(
              id: const Uuid().v4(),
              agentName: 'Ledger Intelligence Agent',
              actionType: 'AUTO_RECONCILE_BALANCE',
              decisionDescription: 'Auto-reconciled account ${updatedAccount.name}. Expected: ${expected / 100.0}, Imported: ${importedBalance / 100.0}, Difference: ${diff / 100.0}. Updated verified balance.',
              confidenceScore: 0.95,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          // Flag mismatch
          final toUpdate = updatedAccount.copyWith(
            importedBalance: Value(importedBalance),
            hasMismatch: const Value(true),
            mismatchExpected: Value(expected),
            mismatchImported: Value(importedBalance),
            updatedAt: DateTime.now(),
          );
          await _db.accountDao.updateAccount(toUpdate);

          await _db.agentLogDao.insertLog(
            AgentLog(
              id: const Uuid().v4(),
              agentName: 'Ledger Intelligence Agent',
              actionType: 'BALANCE_MISMATCH_DETECTED',
              decisionDescription: 'Large balance discrepancy detected on ${updatedAccount.name}. Expected: ${expected / 100.0}, Imported: ${importedBalance / 100.0}, Difference: ${diff / 100.0}. Flagged mismatch.',
              confidenceScore: 0.99,
              timestamp: DateTime.now(),
            ),
          );
        }
      } else {
        // No mismatch, just save imported balance
        final toUpdate = updatedAccount.copyWith(
          importedBalance: Value(importedBalance),
          hasMismatch: const Value(false),
          mismatchExpected: const Value(null),
          mismatchImported: const Value(null),
          updatedAt: DateTime.now(),
        );
        await _db.accountDao.updateAccount(toUpdate);
      }
    }
  }

  /// Accepts the imported balance from the SMS and sets it as the verified balance.
  Future<void> acceptImportedBalance(String accountId) async {
    final account = await (_db.select(_db.accounts)..where((a) => a.id.equals(accountId))).getSingleOrNull();
    if (account == null || account.mismatchImported == null) return;

    final updated = account.copyWith(
      verifiedBalance: Value(account.mismatchImported),
      verifiedAt: Value(DateTime.now()),
      hasMismatch: const Value(false),
      mismatchExpected: const Value(null),
      mismatchImported: const Value(null),
      updatedAt: DateTime.now(),
    );
    await _db.accountDao.updateAccount(updated);
    await BalanceEngine(_db).recalculateAllBalances(accountId: accountId);
    await BalanceEngine(_db).validateAndSelfHeal();
  }

  /// Keeps the currently verified balance baseline, clearing the mismatch.
  Future<void> keepVerifiedBalance(String accountId) async {
    final account = await (_db.select(_db.accounts)..where((a) => a.id.equals(accountId))).getSingleOrNull();
    if (account == null) return;

    final updated = account.copyWith(
      hasMismatch: const Value(false),
      mismatchExpected: const Value(null),
      mismatchImported: const Value(null),
      updatedAt: DateTime.now(),
    );
    await _db.accountDao.updateAccount(updated);
    await BalanceEngine(_db).validateAndSelfHeal();
  }

  /// Creates a manual adjustment entry transaction to resolve the mismatch.
  Future<void> createAdjustmentEntry(String accountId, String userId, int amountInCents) async {
    final account = await (_db.select(_db.accounts)..where((a) => a.id.equals(accountId))).getSingleOrNull();
    if (account == null) return;

    final category = await (_db.select(_db.categories)
      ..where((c) => c.name.equals('Adjustment'))
      ..limit(1)
    ).getSingleOrNull();

    final categoryId = category?.id ?? const Uuid().v4();
    if (category == null) {
      await _db.into(_db.categories).insert(
        CategoriesCompanion.insert(
          id: categoryId,
          userId: userId,
          name: 'Adjustment',
          type: amountInCents < 0 ? 'expense' : 'income',
          createdAt: DateTime.now(),
        ),
      );
    }

    final adjustmentTx = Transaction(
      id: const Uuid().v4(),
      userId: userId,
      accountId: accountId,
      categoryId: categoryId,
      type: amountInCents < 0 ? 'expense' : 'income',
      amount: amountInCents.abs(),
      currency: 'INR',
      description: 'Balance Adjustment',
      merchant: 'Adjustment',
      date: DateTime.now(),
      source: 'manual',
      isRecurring: false,
      syncStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.transactionDao.insertTransaction(adjustmentTx);

    final updated = account.copyWith(
      hasMismatch: const Value(false),
      mismatchExpected: const Value(null),
      mismatchImported: const Value(null),
      updatedAt: DateTime.now(),
    );
    await _db.accountDao.updateAccount(updated);

    await BalanceEngine(_db).reconcileOnAdd(adjustmentTx);
  }
}

final Provider<LedgerAgent> ledgerAgentProvider = Provider<LedgerAgent>((ref) {
  final db = ref.watch(databaseProvider);
  return LedgerAgent(db);
});
