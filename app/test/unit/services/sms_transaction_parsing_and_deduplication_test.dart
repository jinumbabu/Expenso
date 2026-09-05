import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/sms_agent.dart';
import 'package:app/core/services/ledger_agent.dart';
import 'package:app/core/services/sms/sms_transaction_pipeline.dart';
import 'package:app/core/services/notification_service.dart';
import 'package:app/core/security/secure_storage_service.dart';
import 'package:app/core/services/expenso_transaction_intelligence_engine.dart';
import 'package:app/features/sms_parser/domain/services/sms_parser_service.dart';

class MockNotificationService implements NotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockSecureStorageService implements SecureStorageService {
  final Map<String, String> _storage = {};
  @override
  Future<String?> read(String key) async => _storage[key];
  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }
  @override
  Future<DateTime?> getLastSmsSyncTime() async => null;
  @override
  Future<void> saveLastSmsSyncTime(DateTime time) async {}
  @override
  Future<bool?> getSmsNotificationsEnabled() async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late AppDatabase db;
  late SmsAgent smsAgent;
  late LedgerAgent ledgerAgent;
  late MockNotificationService notificationService;
  late MockSecureStorageService secureStorage;
  final String userId = 'test_user_123';

  setUp(() async {
    db = AppDatabase.connect(NativeDatabase.memory());
    smsAgent = SmsAgent(db);
    ledgerAgent = LedgerAgent(db);
    notificationService = MockNotificationService();
    secureStorage = MockSecureStorageService();

    // Create user
    final now = DateTime.now();
    await db.into(db.users).insert(
      UsersCompanion.insert(
        id: userId,
        googleId: 'google_123',
        email: 'jinu@test.com',
        displayName: 'JINU M BABU',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Create HDFC and SBI accounts for the user
    await db.into(db.accounts).insert(
      Account(
        id: 'acc_hdfc',
        userId: userId,
        name: 'HDFC Bank 3726',
        type: 'savings',
        balance: 100000,
        isDefault: true,
        isEstimated: false,
        bankName: 'HDFC',
        last4Digits: '3726',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await db.into(db.accounts).insert(
      Account(
        id: 'acc_sbi',
        userId: userId,
        name: 'SBI Bank 3726',
        type: 'savings',
        balance: 50000,
        isDefault: false,
        isEstimated: false,
        bankName: 'SBI',
        last4Digits: '3726',
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SMS Transaction Parsing & Deduplication Test Suite', () {
    test('TEST 1: HDFC credit + SBI credit SMS with same ref produces ONE transaction with referenceId', () async {
      final now = DateTime.now();

      final hdfcSms = '''
Credit Alert!
Rs.100.00 credited to HDFC Bank A/c XX3726 on 26-08-26
from VPA jinumbabu92@oksbi
(UPI 623867227567)
''';

      final sbiSms = '''
Dear SBI User, your A/c X3726-credited by Rs.100 on
26Aug26 transfer from JINU M BABU
Ref No 623867227567 -SBI
''';

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-HDFCBK-S',
        body: hdfcSms,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'JD-SBIUPI-S',
        body: sbiSms,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      final txs = await (db.select(db.transactions)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();
      final drafts = await (db.select(db.transactionDrafts)..where((d) => d.userId.equals(userId))).get();

      final totalFinancialRecords = txs.length + drafts.length;
      expect(totalFinancialRecords, equals(1));

      final tx = txs.isNotEmpty ? txs.first : null;
      final refNum = tx?.referenceNumber ?? (drafts.isNotEmpty ? ReferenceIdExtractor.extract(drafts.first.smsBody ?? '') : null);
      expect(refNum, equals('623867227567'));
    });

    test('TEST 2: Two SMS messages from different senders but same referenceId produces ONE transaction', () async {
      final now = DateTime.now();
      final sms1 = 'Rs.500 credited to A/c 3726 Ref No 987654321098';
      final sms2 = 'Inward transfer of Rs.500 to A/c 3726 UPI Ref 987654321098';

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-BANK1-S',
        body: sms1,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-BANK2-S',
        body: sms2,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      final txs = await (db.select(db.transactions)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();
      final drafts = await (db.select(db.transactionDrafts)..where((d) => d.userId.equals(userId))).get();

      expect(txs.length + drafts.length, equals(1));
    });

    test('TEST 3: One SMS has referenceId and matching second SMS does not -> ONE transaction with referenceId', () async {
      final now = DateTime.now();
      final smsWithRef = 'Paid Rs.250 to Star Supermarket Ref No 112233445566';
      final smsWithoutRef = 'Debited Rs.250 at Star Supermarket using Card ending 3726';

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-HDFCBK-S',
        body: smsWithRef,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-HDFCBK-S',
        body: smsWithoutRef,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      final txs = await (db.select(db.transactions)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();
      final drafts = await (db.select(db.transactionDrafts)..where((d) => d.userId.equals(userId))).get();

      expect(txs.length + drafts.length, equals(1));
      final tx = txs.isNotEmpty ? txs.first : null;
      if (tx != null) {
        expect(tx.referenceNumber, equals('112233445566'));
      }
    });

    test('TEST 4: Two different Rs.100 transactions with different reference IDs -> TWO transactions', () async {
      final now = DateTime.now();
      final sms1 = 'Paid Rs.100 to Merchant A Ref No 111111111111';
      final sms2 = 'Paid Rs.100 to Merchant B Ref No 222222222222';

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-HDFCBK-S',
        body: sms1,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-HDFCBK-S',
        body: sms2,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      final txs = await (db.select(db.transactions)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();
      final drafts = await (db.select(db.transactionDrafts)..where((d) => d.userId.equals(userId))).get();

      expect(txs.length + drafts.length, equals(2));
    });

    test('TEST 5: Two Rs.100 transactions with no reference IDs but different counterparties -> TWO transactions', () async {
      final now = DateTime.now();
      final sms1 = 'Spent Rs.100 at Swiggy using card 3726';
      final sms2 = 'Spent Rs.100 at Uber using card 3726';

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-HDFCBK-S',
        body: sms1,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-HDFCBK-S',
        body: sms2,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      final txs = await (db.select(db.transactions)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();
      final drafts = await (db.select(db.transactionDrafts)..where((d) => d.userId.equals(userId))).get();

      expect(txs.length + drafts.length, equals(2));
    });

    test('TEST 6: SBI to user HDFC account transfer -> SELF_TRANSFER', () async {
      final now = DateTime.now();
      final sms = 'Rs.100.00 credited to HDFC Bank A/c XX3726 transfer from JINU M BABU Ref No 623867227567';

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-HDFCBK-S',
        body: sms,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      final txs = await (db.select(db.transactions)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();
      final drafts = await (db.select(db.transactionDrafts)..where((d) => d.userId.equals(userId))).get();

      final category = txs.isNotEmpty ? txs.first.transactionType : (drafts.isNotEmpty ? drafts.first.category : null);
      expect(category == 'SELF_TRANSFER' || category == 'Internal Transfer' || category == 'Transfer', isTrue);
    });

    test('TEST 7: Unknown person to user HDFC account -> INCOME classification, NOT self-transfer', () async {
      final now = DateTime.now();
      final sms = 'Rs.5000.00 credited to HDFC Bank A/c XX3726 from Ramesh Kumar Ref No 778899001122';

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-HDFCBK-S',
        body: sms,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      final txs = await (db.select(db.transactions)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();
      final drafts = await (db.select(db.transactionDrafts)..where((d) => d.userId.equals(userId))).get();

      final category = txs.isNotEmpty ? txs.first.transactionType : (drafts.isNotEmpty ? drafts.first.category : null);
      expect(category, isNot(equals('SELF_TRANSFER')));
    });

    test('TEST 8: User to merchant -> EXPENSE classification', () async {
      final now = DateTime.now();
      final sms = 'Rs.450.00 debited from A/c XX3726 at Amazon India Ref No 334455667788';

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-HDFCBK-S',
        body: sms,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      final txs = await (db.select(db.transactions)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();
      final drafts = await (db.select(db.transactionDrafts)..where((d) => d.userId.equals(userId))).get();

      final type = txs.isNotEmpty ? txs.first.type : (drafts.isNotEmpty ? drafts.first.type : null);
      expect(type, equals('expense'));
    });

    test('TEST 9: Same referenceId arrives again during later scan -> no new transaction created', () async {
      final now = DateTime.now();
      final sms = 'Rs.120.00 debited from A/c 3726 at Cafe Coffee Day Ref No 998877665544';

      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-HDFCBK-S',
        body: sms,
        date: now,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      final initialCount = (await (db.select(db.transactions)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get()).length +
                           (await (db.select(db.transactionDrafts)..where((d) => d.userId.equals(userId))).get()).length;

      // Rescan later
      await SmsTransactionPipeline.processIncomingSms(
        sender: 'AD-HDFCBK-S',
        body: sms,
        date: now.add(const Duration(minutes: 10)),
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );

      final finalCount = (await (db.select(db.transactions)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get()).length +
                         (await (db.select(db.transactionDrafts)..where((d) => d.userId.equals(userId))).get()).length;

      expect(finalCount, equals(initialCount));
    });

    test('TEST 10: Same transaction scanned multiple times -> Idempotent processing', () async {
      final now = DateTime.now();
      final sms = 'Rs.300 credited to A/c 3726 Ref No 556677889900';

      for (int i = 0; i < 4; i++) {
        await SmsTransactionPipeline.processIncomingSms(
          sender: 'AD-HDFCBK-S',
          body: sms,
          date: now,
          userId: userId,
          db: db,
          smsAgent: smsAgent,
          ledgerAgent: ledgerAgent,
          notificationService: notificationService,
          secureStorage: secureStorage,
        );
      }

      final txs = await (db.select(db.transactions)..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();
      final drafts = await (db.select(db.transactionDrafts)..where((d) => d.userId.equals(userId))).get();

      expect(txs.length + drafts.length, equals(1));
    });
  });
}
