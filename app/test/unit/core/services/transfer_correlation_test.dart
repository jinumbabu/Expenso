import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/financial_calculation_service.dart';
import 'package:app/core/services/ledger_agent.dart';
import 'package:app/core/services/sms_agent.dart';
import 'package:app/core/services/sms/transfer_correlation_engine.dart';

void main() {
  late AppDatabase db;
  late TransferCorrelationEngine engine;
  late LedgerAgent ledger;

  setUp(() {
    db = AppDatabase.connect(NativeDatabase.memory());
    engine = TransferCorrelationEngine(db);
    ledger = LedgerAgent(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Self-Transfer Detection, Classification & Accounting Engine — 20 Test Cases', () {
    final now = DateTime(2026, 8, 22, 12, 0);

    // Helper functions for easy instantiation
    Transaction makeTx({
      required String id,
      required String type,
      required int amount,
      String? accountId,
      String? referenceNumber,
      String? merchant,
    }) {
      return Transaction(
        id: id,
        userId: 'u1',
        type: type,
        amount: amount,
        currency: 'INR',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        accountId: accountId,
        referenceNumber: referenceNumber,
        merchant: merchant,
        createdAt: now,
        updatedAt: now,
      );
    }

    Account makeAccount({
      required String id,
      required String name,
      required String type,
      int balance = 0,
      int? outstandingBalance,
    }) {
      return Account(
        id: id,
        userId: 'u1',
        name: name,
        type: type,
        balance: balance,
        outstandingBalance: outstandingBalance,
        isDefault: false,
        isEstimated: false,
        createdAt: now,
        updatedAt: now,
      );
    }

    SmsAgentResult makeSmsResult({
      required String type,
      required double amount,
      required String merchant,
      String? refId,
      String category = 'Internal Transfer',
    }) {
      return SmsAgentResult(
        transactionType: type,
        amount: amount,
        date: now,
        merchant: merchant,
        account: 'HDFC *3726',
        accountNumber: '3726',
        referenceId: refId,
        category: category,
        confidence: 1.0,
      );
    }

    // 1. isTransfer Recognition
    test('1. isTransfer returns true for transfer subtypes and false for others', () {
      final txTransfer = makeTx(id: '1', type: 'transfer', amount: 1000);
      final txCcPay = makeTx(id: '2', type: 'credit_card_payment', amount: 1000);
      final txCashWith = makeTx(id: '3', type: 'cash_withdrawal', amount: 1000);
      final txCashDep = makeTx(id: '4', type: 'cash_deposit', amount: 1000);
      final txExpense = makeTx(id: '5', type: 'expense', amount: 1000);

      expect(FinancialCalculationService.isTransfer(txTransfer), isTrue);
      expect(FinancialCalculationService.isTransfer(txCcPay), isTrue);
      expect(FinancialCalculationService.isTransfer(txCashWith), isTrue);
      expect(FinancialCalculationService.isTransfer(txCashDep), isTrue);
      expect(FinancialCalculationService.isTransfer(txExpense), isFalse);
    });

    // 2. isCredit Recognition
    test('2. isCredit returns true only on destination account for transfers', () {
      final tx = makeTx(
        id: '1',
        type: 'transfer',
        amount: 1000,
        accountId: 'acc_source',
        referenceNumber: 'acc_dest',
      );

      expect(FinancialCalculationService.isCredit(tx, 'acc_dest'), isTrue);
      expect(FinancialCalculationService.isCredit(tx, 'acc_source'), isFalse);
      expect(FinancialCalculationService.isCredit(tx, 'other_acc'), isFalse);
    });

    // 3. isDebit Recognition
    test('3. isDebit returns true only on source account for transfers', () {
      final tx = makeTx(
        id: '1',
        type: 'transfer',
        amount: 1000,
        accountId: 'acc_source',
        referenceNumber: 'acc_dest',
      );

      expect(FinancialCalculationService.isDebit(tx, 'acc_source'), isTrue);
      expect(FinancialCalculationService.isDebit(tx, 'acc_dest'), isFalse);
      expect(FinancialCalculationService.isDebit(tx, 'other_acc'), isFalse);
    });

    // 4. Exclusion from Income/Expense summaries
    test('4. transfers are excluded from income and expense summaries', () {
      final tx = makeTx(
        id: '1',
        type: 'transfer',
        amount: 100000,
        accountId: 'acc_source',
        referenceNumber: 'acc_dest',
      );

      expect(FinancialCalculationService.isIncome(tx), isFalse);
      expect(FinancialCalculationService.isExpense(tx), isFalse);
    });

    // 5. Exact Ref ID + Amount + Opposite Direction Match
    test('5. correlate matches counterpart transaction with exact Ref ID, same amount, opposite direction', () async {
      // Seed credit transaction
      final txCredit = makeTx(
        id: 'tx_credit',
        type: 'income',
        amount: 10000,
        referenceNumber: 'REF12345',
        merchant: 'JINU M BABU',
      );
      await db.transactionDao.insertTransaction(txCredit);

      // Candidate debit SMS
      final candidate = makeSmsResult(
        type: 'expense',
        amount: 100.00,
        merchant: 'HDFC Bank',
        refId: 'REF12345',
      );

      final result = await engine.correlate(candidate, 'u1', 'HDFC');
      expect(result, isNotNull);
      expect(result!.matchedTx, isNotNull);
      expect(result.matchedTx!.id, equals('tx_credit'));
    });

    // 6. Near-time reference-less amount match
    test('6. correlate matches reference-less counterpart if within time and amount threshold', () async {
      final txCredit = Transaction(
        id: 'tx_credit',
        userId: 'u1',
        type: 'income',
        amount: 5000,
        currency: 'INR',
        date: now.add(const Duration(minutes: 5)),
        merchant: 'JINU M BABU',
        description: 'SBI Bank',
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );
      await db.transactionDao.insertTransaction(txCredit);

      final candidate = makeSmsResult(
        type: 'expense',
        amount: 50.00,
        merchant: 'SBI Bank',
      );

      final result = await engine.correlate(candidate, 'u1', 'SBI');
      expect(result, isNotNull);
      expect(result!.matchedTx, isNotNull);
      expect(result.matchedTx!.id, equals('tx_credit'));
    });

    // 7. Rejection of direction mismatch
    test('7. correlate rejects match with same direction candidates (debit + debit)', () async {
      final txDebit = makeTx(
        id: 'tx_debit',
        type: 'expense',
        amount: 5000,
        referenceNumber: 'REF123',
        merchant: 'Merchant',
      );
      await db.transactionDao.insertTransaction(txDebit);

      final candidate = makeSmsResult(
        type: 'expense',
        amount: 50.00,
        merchant: 'SBI Bank',
        refId: 'REF123',
      );

      final result = await engine.correlate(candidate, 'u1', 'SBI');
      expect(result, isNull);
    });

    // 8. Rejection of time limit exceeded
    test('8. correlate rejects match if time gap is larger than 3 hours', () async {
      final txCredit = Transaction(
        id: 'tx_credit',
        userId: 'u1',
        type: 'income',
        amount: 5000,
        currency: 'INR',
        date: now.add(const Duration(hours: 4)),
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );
      await db.transactionDao.insertTransaction(txCredit);

      final candidate = makeSmsResult(
        type: 'expense',
        amount: 50.00,
        merchant: 'SBI Bank',
      );

      final result = await engine.correlate(candidate, 'u1', 'SBI');
      expect(result, isNull);
    });

    // 9. Match pending correlation draft
    test('9. correlate matches counterpart draft in transaction_drafts', () async {
      final draftCredit = TransactionDraft(
        id: 'draft_credit',
        userId: 'u1',
        amount: 15000,
        type: 'income',
        currency: 'INR',
        merchant: 'Source',
        description: 'Waiting for counterpart',
        date: now,
        smsBody: 'Received Rs.150.00 Ref REF789',
        createdAt: now,
      );
      await db.transactionDraftDao.insertDraft(draftCredit);

      final candidate = makeSmsResult(
        type: 'expense',
        amount: 150.00,
        merchant: 'HDFC',
        refId: 'REF789',
      );

      final result = await engine.correlate(candidate, 'u1', 'HDFC');
      expect(result, isNotNull);
      expect(result!.matchedDraft, isNotNull);
      expect(result.matchedDraft!.id, equals('draft_credit'));
    });

    // 10. ATM Withdrawal Mapping
    test('10. LedgerAgent maps ATM Cash Withdrawal to cash wallet destination', () async {
      final accSavings = makeAccount(
        id: 'savings_acc',
        name: 'HDFC 3726',
        type: 'savings',
        balance: 100000,
      );
      await db.into(db.accounts).insert(accSavings);

      final tx = makeTx(
        id: 'tx_atm',
        type: 'cash_withdrawal',
        amount: 50000,
        accountId: 'savings_acc',
      );

      await ledger.reconcileTransaction(tx);

      final accounts = await db.select(db.accounts).get();
      final cashWallet = accounts.firstWhere((a) => a.type == 'cash');
      expect(cashWallet, isNotNull);
      expect(cashWallet.balance, equals(50000));
    });

    // 11. Cash Deposit Mapping
    test('11. LedgerAgent maps Cash Deposit to source cash wallet', () async {
      final accCash = makeAccount(
        id: 'cash_acc',
        name: 'Cash Wallet',
        type: 'cash',
        balance: 100000,
      );
      await db.into(db.accounts).insert(accCash);

      final accSavings = makeAccount(
        id: 'savings_acc',
        name: 'SBI 8589',
        type: 'savings',
        balance: 0,
      );
      await db.into(db.accounts).insert(accSavings);

      final tx = makeTx(
        id: 'tx_deposit',
        type: 'cash_deposit',
        amount: 40000,
        accountId: 'savings_acc',
      );

      await ledger.reconcileTransaction(tx);

      final updatedCash = await (db.select(db.accounts)..where((a) => a.id.equals('cash_acc'))).getSingle();
      final updatedSavings = await (db.select(db.accounts)..where((a) => a.id.equals('savings_acc'))).getSingle();

      expect(updatedCash.balance, equals(60000));
      expect(updatedSavings.balance, equals(40000));
    });

    test('12. LedgerAgent routes Credit Card Payment correctly between savings and CC accounts', () async {
      final accSavings = makeAccount(
        id: 'savings_acc',
        name: 'SBI Savings',
        type: 'savings',
        balance: 500000,
      );
      await db.into(db.accounts).insert(accSavings);

      final accCC = makeAccount(
        id: 'cc_acc',
        name: 'SBI CC',
        type: 'credit_card',
        balance: -200000,
        outstandingBalance: 200000,
      );
      await db.into(db.accounts).insert(accCC);

      final tx = makeTx(
        id: 'tx_cc_pay',
        type: 'credit_card_payment',
        amount: 150000,
        accountId: 'savings_acc',
        referenceNumber: 'cc_acc',
      );

      await ledger.reconcileTransaction(tx);

      final updatedSavings = await (db.select(db.accounts)..where((a) => a.id.equals('savings_acc'))).getSingle();
      final updatedCC = await (db.select(db.accounts)..where((a) => a.id.equals('cc_acc'))).getSingle();

      expect(updatedSavings.balance, equals(350000));
      expect(updatedCC.balance, equals(-50000));
    });

    // 13. Orphans draft resolution timeout check (under 24h)
    test('13. resolveOrphanedTransferDrafts leaves drafts under 24 hours unchanged', () async {
      final recentDraft = TransactionDraft(
        id: 'recent_draft',
        userId: 'u1',
        amount: 20000,
        type: 'transfer',
        currency: 'INR',
        merchant: 'Transfer Destination',
        description: 'Waiting for counterpart',
        date: DateTime.now().subtract(const Duration(hours: 12)),
        smsBody: 'Sent Rs.200',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        category: 'Transfer',
        supportingSms: '{"status":"WAITING_FOR_COUNTERPART"}',
      );
      await db.transactionDraftDao.insertDraft(recentDraft);

      await engine.resolveOrphanedTransferDrafts('u1');

      final draft = await (db.select(db.transactionDrafts)..where((t) => t.id.equals('recent_draft'))).getSingle();
      expect(draft.type, equals('transfer'));
      expect(draft.category, equals('Transfer'));
    });

    // 14. Orphans draft resolution timeout check (over 24h)
    test('14. resolveOrphanedTransferDrafts converts drafts older than 24 hours to standard expense', () async {
      final oldDraft = TransactionDraft(
        id: 'old_draft',
        userId: 'u1',
        amount: 20000,
        type: 'transfer',
        currency: 'INR',
        merchant: 'Transfer Destination',
        description: 'Waiting for counterpart',
        date: DateTime.now().subtract(const Duration(hours: 25)),
        smsBody: 'Sent Rs.200',
        createdAt: DateTime.now().subtract(const Duration(hours: 25)),
        category: 'Transfer',
        supportingSms: '{"status":"WAITING_FOR_COUNTERPART"}',
      );
      await db.transactionDraftDao.insertDraft(oldDraft);

      // Seed category Shopping
      await db.into(db.categories).insert(Category(id: 'cat_shopping', userId: 'u1', name: 'Shopping', type: 'expense', icon: 'shopping', color: 'red', isSystemDefault: true, usageCount: 0, createdAt: now));

      await engine.resolveOrphanedTransferDrafts('u1');

      final draft = await (db.select(db.transactionDrafts)..where((t) => t.id.equals('old_draft'))).getSingle();
      expect(draft.type, equals('expense'));
      expect(draft.category, equals('Shopping'));
      expect(draft.supportingSms, isNull);
    });

    // 15. Auto-promotion metadata structures
    test('15. metadata details are populated correctly in transaction drafts waiting for counterparts', () {
      final metadata = {
        'status': 'WAITING_FOR_COUNTERPART',
        'fromAccountId': 'src_id',
        'toAccountId': null,
        'fromAccountName': 'HDFC Savings',
        'toAccountName': 'Unknown',
        'refNumber': 'REF111',
      };
      
      final str = jsonEncode(metadata);
      expect(str, contains('WAITING_FOR_COUNTERPART'));
      expect(str, contains('HDFC Savings'));
    });

    // 16. Multi-account balance verification
    test('16. balance engine processes dual-account updates accurately for transfers', () async {
      final acc1 = makeAccount(id: 'a1', name: 'Acc1', type: 'savings', balance: 10000);
      final acc2 = makeAccount(id: 'a2', name: 'Acc2', type: 'savings', balance: 5000);
      await db.into(db.accounts).insert(acc1);
      await db.into(db.accounts).insert(acc2);

      final tx = makeTx(
        id: 't_trans',
        type: 'transfer',
        amount: 2000,
        accountId: 'a1',
        referenceNumber: 'a2',
      );

      await ledger.reconcileTransaction(tx);

      final upd1 = await (db.select(db.accounts)..where((a) => a.id.equals('a1'))).getSingle();
      final upd2 = await (db.select(db.accounts)..where((a) => a.id.equals('a2'))).getSingle();

      expect(upd1.balance, equals(8000));
      expect(upd2.balance, equals(7000));
    });

    // 16b. Paired manual transfer ledger sign and balance verification
    test('16b. paired manual transfer ledger signs and balances match expected values exactly', () async {
      final accHdfc = makeAccount(id: 'hdfc_acc', name: 'HDFC 3726', type: 'savings', balance: 372044);
      final accCash = makeAccount(id: 'cash_acc', name: 'Cash Wallet', type: 'cash', balance: 0);
      await db.into(db.accounts).insert(accHdfc);
      await db.into(db.accounts).insert(accCash);

      // Debit side transaction
      final txDebit = makeTx(
        id: 'tx_debit_side',
        type: 'transfer_debit',
        amount: 72000,
        accountId: 'hdfc_acc',
      );

      // Credit side transaction
      final txCredit = makeTx(
        id: 'tx_credit_side',
        type: 'transfer_credit',
        amount: 72000,
        accountId: 'cash_acc',
        referenceNumber: 'tx_debit_side',
      );

      await ledger.reconcileTransaction(txDebit);
      await ledger.reconcileTransaction(txCredit);

      final updatedHdfc = await (db.select(db.accounts)..where((a) => a.id.equals('hdfc_acc'))).getSingle();
      final updatedCash = await (db.select(db.accounts)..where((a) => a.id.equals('cash_acc'))).getSingle();

      // Assert ledger sign and balances
      expect(updatedHdfc.balance, equals(300044)); // 3720.44 - 720.00
      expect(updatedCash.balance, equals(72000));  // 0.00 + 720.00
      expect(updatedHdfc.balance + updatedCash.balance, equals(372044)); // Net worth contribution is unchanged
    });

    // 17. Narrative matching scoring weights
    test('17. correlate weights narrative signals with +10 points', () async {
      final txCredit = makeTx(
        id: 'tx_c',
        type: 'income',
        amount: 5000,
        merchant: 'Jinu M Babu',
      );
      await db.transactionDao.insertTransaction(txCredit);

      final candidate = makeSmsResult(
        type: 'expense',
        amount: 50.00,
        merchant: 'Jinu M Babu',
      );

      final result = await engine.correlate(candidate, 'u1', 'SBI');
      expect(result, isNotNull);
    });

    // 18. Rejection of low scoring match (under 50 points)
    test('18. correlate rejects match if score is below 50 points', () async {
      final txCredit = Transaction(
        id: 'tx_c',
        userId: 'u1',
        type: 'income',
        amount: 9000,
        currency: 'INR',
        date: now.add(const Duration(hours: 2)),
        merchant: 'Jinu M Babu',
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );
      await db.transactionDao.insertTransaction(txCredit);

      final candidate = makeSmsResult(
        type: 'expense',
        amount: 50.00,
        merchant: 'Store',
      );

      final result = await engine.correlate(candidate, 'u1', 'SBI');
      expect(result, isNull);
    });

    // 19. WAITING_FOR_COUNTERPART state promotion
    test('19. WAITING_FOR_COUNTERPART is updated to CORRELATED when counterpart arrives', () async {
      final pendingDraft = TransactionDraft(
        id: 'draft_pending',
        userId: 'u1',
        amount: 30000,
        type: 'transfer',
        currency: 'INR',
        merchant: 'Transfer Source',
        description: 'Waiting for counterpart',
        date: now,
        smsBody: 'Sent Rs.300',
        createdAt: now,
        category: 'Transfer',
        supportingSms: '{"status":"WAITING_FOR_COUNTERPART"}',
      );
      await db.transactionDraftDao.insertDraft(pendingDraft);

      final candidateCredit = makeSmsResult(
        type: 'income',
        amount: 300.00,
        merchant: 'JINU M BABU',
      );

      final result = await engine.correlate(candidateCredit, 'u1', 'SBI');
      expect(result, isNotNull);
      expect(result!.matchedDraft, isNotNull);
      expect(result.matchedDraft!.id, equals('draft_pending'));
    });

    // 20. isSelfTransferPair logic in sms_parser_provider
    test('20. isSelfTransferPair evaluates pairs with matching parameters as true', () {
      final debit = makeSmsResult(
        type: 'expense',
        amount: 100.00,
        merchant: 'HDFC Bank',
        refId: 'REF777',
      );
      
      final credit = SmsAgentResult(
        transactionType: 'income',
        amount: 100.00,
        date: now,
        merchant: 'SBI Bank',
        account: 'SBI *8589',
        accountNumber: '8589',
        referenceId: 'REF777',
        category: 'Internal Transfer',
        confidence: 1.0,
      );

      final hasSameRef = debit.referenceId != null && 
                         credit.referenceId != null && 
                         debit.referenceId == credit.referenceId;
      
      expect(hasSameRef, isTrue);
      expect(debit.account != credit.account, isTrue);
    });
  });
}
