import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/sms_agent.dart';
import 'package:app/core/services/ledger_agent.dart';
import 'package:app/core/services/financial_calculation_service.dart';
import 'package:app/core/services/balance_engine.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;

void main() {
  late AppDatabase database;
  late SmsAgent smsAgent;
  late LedgerAgent ledgerAgent;
  final testDate = DateTime(2026, 8, 26);
  const userId = 'user_test_456';

  setUp(() async {
    database = AppDatabase.connect(NativeDatabase.memory());
    smsAgent = SmsAgent(database);
    ledgerAgent = LedgerAgent(database);

    // Seed default categories
    await database.categoryDao.insertCategory(
      Category(
        id: 'cat_transfer',
        userId: 'system',
        name: 'Transfer',
        type: 'transfer',
        usageCount: 0,
        isSystemDefault: true,
        createdAt: DateTime.now(),
      ),
    );
    await database.categoryDao.insertCategory(
      Category(
        id: 'cat_shopping',
        userId: 'system',
        name: 'Shopping',
        type: 'expense',
        usageCount: 0,
        isSystemDefault: true,
        createdAt: DateTime.now(),
      ),
    );
    await database.categoryDao.insertCategory(
      Category(
        id: 'cat_salary',
        userId: 'system',
        name: 'Salary',
        type: 'income',
        usageCount: 0,
        isSystemDefault: true,
        createdAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('SMS Agent Reference ID Extraction & Normalization', () {
    test('Scenario 1: Extract and normalize reference ID correctly across common patterns', () async {
      final sbiMsg = 'Dear SBI User, your A/c X3726-credited by Rs.100 on 26Aug26 transfer from JINU M BABU Ref No 623867227567 -SBI';
      final res1 = await smsAgent.processSms(sbiMsg, testDate, userId: userId);
      expect(res1, isNotNull);
      expect(res1!.referenceId, equals('623867227567'));

      final hdfcMsg = 'Credit Alert! Rs.100.00 credited to HDFC Bank A/c XX3726 on 26-08-26 from VPA jinumbabu92@oksbi (UPI 623867227567)';
      final res2 = await smsAgent.processSms(hdfcMsg, testDate, userId: userId);
      expect(res2, isNotNull);
      expect(res2!.referenceId, equals('623867227567'));
    });
  });

  group('SMS Agent Deduplication & Merging Tests', () {
    test('Scenario 2: Real-time merging debit and credit alerts with the same reference number', () async {
      // Create user bank accounts
      final sbi = Account(
        id: 'acc_sbi',
        userId: userId,
        name: 'SBI Bank',
        type: 'bank',
        bankName: 'SBI',
        last4Digits: '3726',
        balance: 100000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(sbi);

      final hdfc = Account(
        id: 'acc_hdfc',
        userId: userId,
        name: 'HDFC Bank',
        type: 'bank',
        bankName: 'HDFC',
        last4Digits: '3726',
        balance: 50000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(hdfc);

      // Insert first alert (credits HDFC XX3726)
      final tx1 = Transaction(
        id: 'tx_first',
        userId: userId,
        accountId: 'acc_hdfc',
        categoryId: 'cat_shopping',
        type: 'income',
        amount: 10000, // ₹100
        currency: 'INR',
        description: 'SMS Alert: HDFC XX3726',
        merchant: 'Jinu M Babu',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        referenceNumber: '623867227567',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final r1 = await ledgerAgent.reconcileTransaction(tx1);
      expect(r1.status, equals(ReconciliationStatus.inserted));

      // Reconcile second alert (transfer from SBI to HDFC, same ref)
      final tx2 = Transaction(
        id: 'tx_second',
        userId: userId,
        accountId: 'acc_sbi',
        categoryId: 'cat_transfer',
        type: 'transfer',
        amount: 10000,
        currency: 'INR',
        description: 'SMS Alert: SBI X3726',
        merchant: 'To HDFC',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        referenceNumber: '623867227567',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final r2 = await ledgerAgent.reconcileTransaction(tx2);
      expect(r2.status, equals(ReconciliationStatus.merged));

      // Verify transaction was merged to self-transfer and accounts adjusted
      final merged = await database.transactionDao.getTransactionById('tx_first');
      expect(merged, isNotNull);
      expect(merged!.type, equals('transfer'));
      expect(merged.transactionType, equals('SELF_TRANSFER'));
      expect(merged.accountId, equals('acc_sbi')); // debit side
      expect(merged.billLink, equals('acc_hdfc')); // credit side

      final updatedSbi = await database.accountDao.getAccountById('acc_sbi');
      final updatedHdfc = await database.accountDao.getAccountById('acc_hdfc');
      expect(updatedSbi!.balance, equals(90000)); // ₹100 deducted from SBI
      expect(updatedHdfc!.balance, equals(60000)); // ₹100 added to HDFC
    });

    test('Scenario 3: Duplicate reference ID check prevents multiple inserts of same reference ID', () async {
      // Create user bank account
      final sbi = Account(
        id: 'acc_sbi',
        userId: userId,
        name: 'SBI Bank',
        type: 'bank',
        balance: 100000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(sbi);

      final tx1 = Transaction(
        id: 'tx_dup_1',
        userId: userId,
        accountId: 'acc_sbi',
        categoryId: 'cat_shopping',
        type: 'expense',
        amount: 5000,
        currency: 'INR',
        description: 'Purchased Starbucks',
        merchant: 'Starbucks',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        referenceNumber: 'REF999',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ledgerAgent.reconcileTransaction(tx1);

      final tx2 = Transaction(
        id: 'tx_dup_2',
        userId: userId,
        accountId: 'acc_sbi',
        categoryId: 'cat_shopping',
        type: 'expense',
        amount: 5000,
        currency: 'INR',
        description: 'Starbucks coffee second sms',
        merchant: 'Starbucks',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        referenceNumber: 'REF999',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final res = await ledgerAgent.reconcileTransaction(tx2);
      expect(res.status, equals(ReconciliationStatus.skipped));

      final allTxs = await database.transactionDao.getTransactionsForUser(userId);
      // Only 1 transaction exists in DB (not 2)
      final ref999Txs = allTxs.where((t) => t.referenceNumber == 'REF999' && t.deletedAt == null);
      expect(ref999Txs.length, equals(1));
    });

    test('Scenario 4: Fallback deduplication checks fuzzy merchant and time windows when reference ID is absent', () async {
      // Create user bank account
      final sbi = Account(
        id: 'acc_sbi',
        userId: userId,
        name: 'SBI Bank',
        type: 'bank',
        balance: 100000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(sbi);

      final tx1 = Transaction(
        id: 'tx_fallback_1',
        userId: userId,
        accountId: 'acc_sbi',
        categoryId: 'cat_shopping',
        type: 'expense',
        amount: 1500,
        currency: 'INR',
        description: 'Purchased coffee',
        merchant: 'Starbucks',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ledgerAgent.reconcileTransaction(tx1);

      final tx2 = Transaction(
        id: 'tx_fallback_2',
        userId: userId,
        accountId: 'acc_sbi',
        categoryId: 'cat_shopping',
        type: 'expense',
        amount: 1500,
        currency: 'INR',
        description: 'Starbucks Alert',
        merchant: 'Starbucks Coffee',
        date: testDate.add(const Duration(minutes: 5)),
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final res = await ledgerAgent.reconcileTransaction(tx2);
      expect(res.status, equals(ReconciliationStatus.merged));
    });

    test('Scenario 5: Different accounts with the same amount and date are NOT duplicates', () async {
      // Create accounts with distinct bankName and last4Digits to ensure unique hash keys
      final sbi = Account(
        id: 'acc_sbi',
        userId: userId,
        name: 'SBI Bank',
        type: 'bank',
        bankName: 'SBI',
        last4Digits: '1234',
        balance: 100000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(sbi);

      final hdfc = Account(
        id: 'acc_hdfc',
        userId: userId,
        name: 'HDFC Bank',
        type: 'bank',
        bankName: 'HDFC',
        last4Digits: '5678',
        balance: 50000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(hdfc);

      final tx1 = Transaction(
        id: 'tx_diff_acc_1',
        userId: userId,
        accountId: 'acc_sbi',
        categoryId: 'cat_shopping',
        type: 'expense',
        amount: 1200,
        currency: 'INR',
        description: 'Uber charge sbi',
        merchant: 'Uber',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ledgerAgent.reconcileTransaction(tx1);

      final tx2 = Transaction(
        id: 'tx_diff_acc_2',
        userId: userId,
        accountId: 'acc_hdfc',
        categoryId: 'cat_shopping',
        type: 'expense',
        amount: 1200,
        currency: 'INR',
        description: 'Uber charge hdfc',
        merchant: 'Uber',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final res = await ledgerAgent.reconcileTransaction(tx2);
      expect(res.status, equals(ReconciliationStatus.inserted));
    });
  });

  group('Self-Transfer Net Worth Exclusions', () {
    test('Scenario 6: Self-transfers do not affect income or expense totals (net 0 impact)', () async {
      final tx = Transaction(
        id: 'tx_self_trans',
        userId: userId,
        accountId: 'acc_sbi',
        categoryId: 'cat_transfer',
        type: 'transfer',
        amount: 5000,
        currency: 'INR',
        description: 'Self transfer',
        merchant: 'To HDFC',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        transactionType: 'SELF_TRANSFER',
        billLink: 'acc_hdfc',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isInc = FinancialCalculationService.isIncome(tx);
      final isExp = FinancialCalculationService.isExpense(tx);

      expect(isInc, isFalse);
      expect(isExp, isFalse);
    });
  });

  group('MIGRATIONS, APPROVALS & EDITS', () {
    test('Scenario 7: Duplicate reference ID repair migration correctly groups, merges, and deletes duplicates', () async {
      // Create user bank accounts
      final sbi = Account(
        id: 'acc_sbi',
        userId: userId,
        name: 'SBI Bank',
        type: 'bank',
        balance: 100000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(sbi);

      final hdfc = Account(
        id: 'acc_hdfc',
        userId: userId,
        name: 'HDFC Bank',
        type: 'bank',
        balance: 50000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(hdfc);

      final tx1 = Transaction(
        id: 'mig_tx_1',
        userId: userId,
        accountId: 'acc_sbi',
        categoryId: 'cat_shopping',
        type: 'expense',
        amount: 3000,
        currency: 'INR',
        description: 'First Starbucks SMS',
        merchant: 'Starbucks',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        referenceNumber: 'REF_MIG_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await database.transactionDao.insertTransaction(tx1);

      final tx2 = Transaction(
        id: 'mig_tx_2',
        userId: userId,
        accountId: 'acc_hdfc',
        categoryId: 'cat_shopping',
        type: 'income',
        amount: 3000,
        currency: 'INR',
        description: 'Second SBI credited alert',
        merchant: 'Starbucks Transfer',
        date: testDate,
        source: 'sms',
        isRecurring: false,
        syncStatus: 'pending',
        referenceNumber: 'REF_MIG_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await database.transactionDao.insertTransaction(tx2);

      // Verify they both exist in database
      final beforeCount = await database.transactionDao.getTransactionsForUser(userId);
      expect(beforeCount.length, equals(2));

      // Run migration helper
      await runDuplicateReferenceRepairTestHelper(database, userId);

      // Verify only 1 remains, it is a SELF_TRANSFER
      final afterCount = await database.transactionDao.getTransactionsForUser(userId);
      expect(afterCount.length, equals(1));
      
      final primary = afterCount.first;
      expect(primary.type, equals('transfer'));
      expect(primary.transactionType, equals('SELF_TRANSFER'));
      expect(primary.accountId, equals('acc_sbi'));
      expect(primary.billLink, equals('acc_hdfc'));
    });

    test('Scenario 8: Draft approvals map reference number and billLink correctly to the final Transaction', () async {
      // Seed accounts
      final sbi = Account(
        id: 'acc_sbi',
        userId: userId,
        name: 'SBI Bank',
        type: 'bank',
        balance: 100000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(sbi);

      final hdfc = Account(
        id: 'acc_hdfc',
        userId: userId,
        name: 'HDFC Bank',
        type: 'bank',
        balance: 50000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(hdfc);

      final draft = TransactionDraft(
        id: 'draft_test_1',
        userId: userId,
        amount: 4000,
        type: 'transfer',
        currency: 'INR',
        merchant: 'Transfer to own account',
        description: 'SMS Alert',
        date: testDate,
        smsSender: 'SBI',
        cardOrAccount: 'XXXX',
        smsBody: 'SBI transfer Rs 40',
        createdAt: DateTime.now(),
        supportingSms: jsonEncode({
          'refNumber': 'UPI_DRAFT_REF',
          'toAccountId': 'acc_hdfc',
        }),
      );
      await database.transactionDraftDao.insertDraft(draft);

      final dbDraft = await database.transactionDraftDao.getDraftById('draft_test_1');
      expect(dbDraft, isNotNull);

      // Approve draft logic mapping refNumber and toAccountId
      final Map<String, dynamic> metadata = jsonDecode(dbDraft!.supportingSms!);
      final toAccountId = metadata['toAccountId'];
      final refNumber = metadata['refNumber'];

      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: 'acc_sbi',
        categoryId: 'cat_transfer',
        paymentMethodId: 'pm_default_123',
        type: 'transfer',
        amount: dbDraft.amount,
        currency: dbDraft.currency,
        description: dbDraft.smsBody ?? 'SMS Transfer',
        merchant: refNumber != null ? 'Ref: $refNumber' : 'SMS Transfer',
        date: dbDraft.date,
        source: 'sms',
        confidenceScore: dbDraft.confidenceScore ?? 1.0,
        isRecurring: false,
        syncStatus: 'pending',
        transactionType: 'SELF_TRANSFER',
        referenceNumber: refNumber,
        billLink: toAccountId,
        supportingSms: dbDraft.supportingSms,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ledgerAgent.reconcileTransaction(tx);
      await database.transactionDraftDao.deleteDraft(dbDraft.id);

      final approvedTxs = await database.transactionDao.getTransactionsForUser(userId);
      final approvedTx = approvedTxs.firstWhere((t) => t.referenceNumber == 'UPI_DRAFT_REF');
      expect(approvedTx.billLink, equals('acc_hdfc'));
      expect(approvedTx.transactionType, equals('SELF_TRANSFER'));
    });

    test('Scenario 9: Background pipeline creates drafts with reference ID and billLink in supportingSms metadata', () async {
      final cleanBody = 'Credit Alert! Rs.100.00 credited to HDFC Bank A/c XX3726 on 26-08-26 from VPA jinumbabu92@oksbi (UPI 623867227567)';
      final result = await smsAgent.processSms(cleanBody, testDate, userId: userId);

      expect(result, isNotNull);
      expect(result!.referenceId, equals('623867227567'));

      final metadata = {
        'refNumber': result.referenceId,
        'toAccountId': null,
      };
      final draft = TransactionDraft(
        id: 'draft_pipeline_test',
        userId: userId,
        amount: (result.amount * 100).round(),
        type: result.transactionType,
        currency: 'INR',
        merchant: result.merchant,
        description: 'SMS Alert: ${result.account}',
        date: result.date,
        smsSender: 'HDFC',
        cardOrAccount: result.accountNumber,
        smsBody: cleanBody,
        originalSmsId: null,
        createdAt: DateTime.now(),
        categoryId: 'cat_shopping',
        category: result.category,
        confidenceScore: result.confidence,
        supportingSms: jsonEncode(metadata),
      );
      await database.transactionDraftDao.insertDraft(draft);

      final dbDraft = await database.transactionDraftDao.getDraftById('draft_pipeline_test');
      expect(dbDraft, isNotNull);
      expect(dbDraft!.supportingSms, isNotNull);
      
      final parsedMetadata = jsonDecode(dbDraft.supportingSms!);
      expect(parsedMetadata['refNumber'], equals('623867227567'));
    });

    test('Scenario 10: Edits to manual transaction retain reference number and preserve it without overwrite', () async {
      // Seed account
      final sbi = Account(
        id: 'acc_sbi',
        userId: userId,
        name: 'SBI Bank',
        type: 'bank',
        balance: 100000,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEstimated: false,
      );
      await database.into(database.accounts).insert(sbi);

      final tx = Transaction(
        id: 'tx_edit_test',
        userId: userId,
        accountId: 'acc_sbi',
        categoryId: 'cat_shopping',
        type: 'expense',
        amount: 8000,
        currency: 'INR',
        description: 'Manual Starbucks entry',
        merchant: 'Starbucks',
        date: testDate,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        referenceNumber: 'MANUAL_REF_123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ledgerAgent.reconcileTransaction(tx);

      final existing = await database.transactionDao.getTransactionById('tx_edit_test');
      expect(existing, isNotNull);
      expect(existing!.referenceNumber, equals('MANUAL_REF_123'));

      final edited = existing.copyWith(
        amount: 9000,
        merchant: const Value('Starbucks Coffee Premium'),
        updatedAt: DateTime.now(),
      );
      await database.transactionDao.updateTransaction(edited);
      await BalanceEngine(database).reconcileOnEdit(existing, edited);

      final updated = await database.transactionDao.getTransactionById('tx_edit_test');
      expect(updated!.referenceNumber, equals('MANUAL_REF_123'));
      expect(updated.amount, equals(9000));
    });
  });
}

Future<void> runDuplicateReferenceRepairTestHelper(AppDatabase db, String userId) async {
  final txs = await (db.select(db.transactions)
    ..where((t) => t.userId.equals(userId) & t.referenceNumber.isNotNull() & t.deletedAt.isNull())
  ).get();
  
  if (txs.isEmpty) return;
  
  final Map<String, List<Transaction>> groups = {};
  for (final tx in txs) {
    final ref = tx.referenceNumber!.trim();
    if (ref.isNotEmpty) {
      groups.putIfAbsent(ref, () => []).add(tx);
    }
  }
  
  for (final ref in groups.keys) {
    final group = groups[ref]!;
    if (group.length < 2) continue;
    
    group.sort((a, b) {
      if (a.source == 'manual' && b.source != 'manual') return -1;
      if (b.source == 'manual' && a.source != 'manual') return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    
    var primary = group[0];
    
    for (int i = 1; i < group.length; i++) {
      final secondary = group[i];
      
      final mergedDesc = primary.description ?? secondary.description;
      final mergedMerchant = primary.merchant ?? secondary.merchant;
      
      List<String> smsList = [];
      String? mergedRefNumber = primary.referenceNumber ?? secondary.referenceNumber;
      String? mergedBillLink = primary.billLink ?? secondary.billLink;
      
      void decodeSms(String? supportingSms) {
        if (supportingSms != null && supportingSms.isNotEmpty) {
          try {
            final parsed = jsonDecode(supportingSms);
            if (parsed is Map) {
              final list = parsed['smsList'] as List?;
              if (list != null) {
                for (final s in list) {
                  final str = s.toString();
                  if (!smsList.contains(str)) smsList.add(str);
                }
              }
            }
          } catch (_) {}
        }
      }
      
      decodeSms(primary.supportingSms);
      decodeSms(secondary.supportingSms);
      
      final accounts = await (db.select(db.accounts)..where((a) => a.userId.equals(userId))).get();
      final accountIds = accounts.map((a) => a.id).toSet();
      
      String finalType = primary.type;
      String? finalTxType = primary.transactionType;
      String? finalAccountId = primary.accountId ?? secondary.accountId;
      String? finalBillLink = mergedBillLink;
      
      final primaryIsCredit = FinancialCalculationService.isCredit(primary, primary.accountId ?? '');
      final primaryIsDebit = FinancialCalculationService.isDebit(primary, primary.accountId ?? '');
      final secondaryIsCredit = FinancialCalculationService.isCredit(secondary, secondary.accountId ?? '');
      final secondaryIsDebit = FinancialCalculationService.isDebit(secondary, secondary.accountId ?? '');
      
      if (primary.accountId != secondary.accountId && 
          primary.accountId != null && 
          secondary.accountId != null &&
          accountIds.contains(primary.accountId) && 
          accountIds.contains(secondary.accountId)) {
        
        finalType = 'transfer';
        finalTxType = 'SELF_TRANSFER';
        
        String? sourceAccId;
        String? destAccId;
        if (primaryIsDebit || secondaryIsCredit) {
          sourceAccId = primary.accountId;
          destAccId = secondary.accountId;
        } else if (secondaryIsDebit || primaryIsCredit) {
          sourceAccId = secondary.accountId;
          destAccId = primary.accountId;
        } else {
          sourceAccId = primary.accountId;
          destAccId = secondary.accountId;
        }
        finalAccountId = sourceAccId;
        finalBillLink = destAccId;
      }
      
      final supportingMetadata = {
        'smsList': smsList,
        'refNumber': mergedRefNumber,
        'toAccountId': finalBillLink,
      };
      
      final ledgerAgent = LedgerAgent(db);
      final newFingerprint = ledgerAgent.generateFingerprint(
        accountId: finalAccountId,
        amount: primary.amount,
        merchant: mergedMerchant ?? 'Merged Merchant',
        date: primary.date,
        referenceNumber: mergedRefNumber,
      );
      
      primary = primary.copyWith(
        accountId: Value(finalAccountId),
        type: finalType,
        transactionType: Value(finalTxType),
        description: Value(mergedDesc),
        merchant: Value(mergedMerchant),
        referenceNumber: Value(mergedRefNumber),
        billLink: Value(finalBillLink),
        fingerprint: Value(newFingerprint),
        supportingSms: Value(jsonEncode(supportingMetadata)),
        updatedAt: DateTime.now(),
      );
      
      await db.transactionDao.updateTransaction(primary);
      await db.transactionDao.hardDeleteTransaction(secondary.id);
    }
  }
}
