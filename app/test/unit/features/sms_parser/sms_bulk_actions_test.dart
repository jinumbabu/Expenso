import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/sms_agent.dart';
import 'package:app/core/services/ledger_agent.dart';
import 'package:app/core/services/notification_service.dart';
import 'package:app/core/security/secure_storage_service.dart';
import 'package:app/features/sms_parser/presentation/providers/sms_parser_provider.dart';

// Use Fake instead of Mockito to avoid implementation boilerplates
class FakeRef extends Fake implements Ref {
  @override
  void invalidate(ProviderOrFamily provider) {}
}

class FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<void> sendProactiveAlert(
    String userId, {
    required String title,
    required String body,
    required String priority,
  }) async {}
}

class FakeSecureStorageService extends Fake implements SecureStorageService {
  @override
  Future<DateTime?> getLastSmsSyncTime() async => null;
  @override
  Future<bool> getHasRequestedSmsPermission() async => true;
  @override
  Future<bool> getAutoImportEnabled() async => false;
  @override
  Future<double?> getAutoImportThreshold() async => 0.90;
  @override
  Future<DateTime?> getLastPermissionRequestTime() async => null;
  @override
  Future<void> saveLastPermissionRequestTime(DateTime time) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late SmsAgent smsAgent;
  late LedgerAgent ledgerAgent;
  late SmsScannerNotifier notifier;
  
  const userId = 'user_bulk_123';
  final testDate = DateTime(2026, 6, 28);

  setUp(() async {
    database = AppDatabase.connect(NativeDatabase.memory());
    smsAgent = SmsAgent(database);
    ledgerAgent = LedgerAgent(database);
    
    // Seed default categories
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

    // Seed default payment method
    await database.into(database.paymentMethods).insert(
      PaymentMethod(
        id: 'pm_upi',
        userId: userId,
        name: 'UPI',
        type: 'upi',
        usageCount: 0,
        createdAt: DateTime.now(),
      ),
    );

    // Seed account
    await database.into(database.accounts).insert(
      Account(
        id: 'acc_sbi',
        userId: userId,
        name: 'SBI A/c 1234',
        type: 'savings',
        balance: 100000,
        isDefault: true,
        isEstimated: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    notifier = SmsScannerNotifier(
      db: database,
      userId: userId,
      smsAgent: smsAgent,
      ledgerAgent: ledgerAgent,
      notificationService: FakeNotificationService(),
      secureStorage: FakeSecureStorageService(),
      ref: FakeRef(),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('SMS Bulk Actions Tests', () {
    test('deleteAllDrafts clears all drafts in database', () async {
      // 1. Insert drafts
      await database.transactionDraftDao.insertDraft(
        TransactionDraft(
          id: 'draft_1',
          userId: userId,
          amount: 50000,
          type: 'expense',
          currency: 'INR',
          merchant: 'Starbucks',
          description: 'SMS Alert',
          date: testDate,
          createdAt: DateTime.now(),
        ),
      );

      var drafts = await database.transactionDraftDao.getDraftsForUser(userId);
      expect(drafts, hasLength(1));

      // 2. Call deleteAllDrafts
      await notifier.deleteAllDrafts();

      // 3. Verify drafts list is empty
      drafts = await database.transactionDraftDao.getDraftsForUser(userId);
      expect(drafts, isEmpty);
    });

    test('approveAllDrafts imports drafts and clears them from drafts list', () async {
      // 1. Insert a draft representing "Starbucks A/c 1234"
      await database.transactionDraftDao.insertDraft(
        TransactionDraft(
          id: 'draft_2',
          userId: userId,
          amount: 25000, // ₹250
          type: 'expense',
          currency: 'INR',
          merchant: 'Starbucks',
          description: 'Starbucks coffee spend',
          smsBody: 'Rs 250.00 debited from A/c XX1234 on 28-Jun-26 towards Starbucks.',
          cardOrAccount: '1234',
          date: testDate,
          createdAt: DateTime.now(),
          category: 'Shopping',
        ),
      );

      var drafts = await database.transactionDraftDao.getDraftsForUser(userId);
      expect(drafts, hasLength(1));

      // 2. Approve all drafts
      final result = await notifier.approveAllDrafts();

      expect(result['imported'], equals(1));
      expect(result['skipped'], equals(0));

      // 3. Verify draft is removed
      drafts = await database.transactionDraftDao.getDraftsForUser(userId);
      expect(drafts, isEmpty);

      // 4. Verify transaction is inserted
      final txs = await database.select(database.transactions).get();
      expect(txs, hasLength(1));
      expect(txs.first.merchant, equals('Starbucks'));
      expect(txs.first.accountId, equals('acc_sbi')); // auto-detected SBI account from XX1234
    });
  });
}
