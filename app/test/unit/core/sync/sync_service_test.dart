import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:drift/native.dart';

import 'package:app/core/sync/sync_service.dart';
import 'package:app/core/sync/backup_service.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/security/secure_storage_service.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';

// Mock path provider
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String _tempPath;
  MockPathProviderPlatform(this._tempPath);

  @override
  Future<String?> getApplicationSupportPath() async => _tempPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => _tempPath;
  @override
  Future<String?> getTemporaryPath() async => _tempPath;
}

// Mock secure storage
class MockSecureStorageService implements SecureStorageService {
  String? backupKey;
  String? dbKey;

  @override
  Future<String?> getBackupEncryptionKey() async => backupKey;
  @override
  Future<void> saveBackupEncryptionKey(String key) async => backupKey = key;
  @override
  Future<void> deleteBackupEncryptionKey() async => backupKey = null;

  @override
  Future<String?> getDatabaseKey() async => dbKey;
  @override
  Future<void> saveDatabaseKey(String key) async => dbKey = key;
  @override
  Future<void> deleteDatabaseKey() async => dbKey = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock Ref
class MockRef implements Ref {
  final Map<dynamic, dynamic> _providers = {};

  void overrideProvider(dynamic provider, dynamic value) {
    _providers[provider] = value;
  }

  @override
  T read<T>(ProviderListenable<T> provider) {
    if (_providers.containsKey(provider)) {
      return _providers[provider] as T;
    }
    throw Exception('Provider not mocked: $provider');
  }

  @override
  void invalidate(ProviderOrFamily provider) {
    // Do nothing in mock
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncService Tests', () {
    late String testTempPath;
    late MockSecureStorageService mockSecureStorage;
    late MockRef mockRef;
    late BackupService backupService;
    late SyncService syncService;
    late AppDatabase localDb;
    late String userId;

    setUp(() async {
      final systemTemp = Directory.systemTemp.createTempSync('expenso_sync_test_');
      testTempPath = systemTemp.path;

      PathProviderPlatform.instance = MockPathProviderPlatform(testTempPath);

      mockSecureStorage = MockSecureStorageService();
      mockRef = MockRef();
      userId = 'test-user-999';

      // Setup user details
      final mockUser = User(
        id: userId,
        googleId: 'mock-google-id',
        email: 'tester@expenso.ai',
        displayName: 'Test User',
        currency: 'INR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create local DB connection
      final dbFile = File(p.join(testTempPath, 'expenso_database.sqlite'));
      localDb = AppDatabase.connect(NativeDatabase(dbFile));

      // Setup providers
      mockRef.overrideProvider(authProvider, AuthState.authenticated(mockUser));
      mockRef.overrideProvider(databaseProvider, localDb);
      mockRef.overrideProvider(secureStorageProvider, mockSecureStorage);

      backupService = BackupService(mockRef, mockSecureStorage);
      mockRef.overrideProvider(backupServiceProvider, backupService);

      syncService = SyncService(mockRef, backupService);
      mockRef.overrideProvider(syncServiceProvider, syncService);

      // Seed categories locally
      final now = DateTime.now();
      await localDb.categoryDao.insertCategory(Category(
        id: 'cat-food',
        userId: userId,
        name: 'Food',
        type: 'expense',
        usageCount: 0,
        isSystemDefault: false,
        createdAt: now,
      ));
      await localDb.paymentMethodDao.insertPaymentMethod(PaymentMethod(
        id: 'pm-cash',
        userId: userId,
        name: 'Cash',
        type: 'cash',
        usageCount: 0,
        createdAt: now,
      ));
    });

    tearDown(() async {
      await localDb.close();
      try {
        final dir = Directory(testTempPath);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('Bidirectional Sync: Inserts remote-only transaction locally', () async {
      final now = DateTime.now();
      final dbFile = File(p.join(testTempPath, 'expenso_database.sqlite'));
      final localBackupFile = File(p.join(testTempPath, 'expenso_database_local.sqlite'));

      // 1. Close local DB and swap it out
      await localDb.close();
      await dbFile.rename(localBackupFile.path);

      // 2. Setup a remote database at the main database path
      final remoteDb = AppDatabase.connect(NativeDatabase(dbFile));
      final remoteTx = Transaction(
        id: 'tx-remote-only',
        userId: userId,
        categoryId: 'cat-food',
        paymentMethodId: 'pm-cash',
        type: 'expense',
        amount: 25000, // INR 250
        currency: 'INR',
        merchant: 'Remote Store',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      // Seed categories in remote db
      await remoteDb.categoryDao.insertCategory(Category(
        id: 'cat-food',
        userId: userId,
        name: 'Food',
        type: 'expense',
        usageCount: 0,
        isSystemDefault: false,
        createdAt: now,
      ));
      await remoteDb.transactionDao.insertTransaction(remoteTx);
      await remoteDb.close();

      // 3. Encrypt and backup remote DB to mock cloud path
      await backupService.backup(userId);

      // 4. Delete the remote database file and swap the local database back
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      await localBackupFile.rename(dbFile.path);

      // Reopen local DB connection
      localDb = AppDatabase.connect(NativeDatabase(dbFile));
      mockRef.overrideProvider(databaseProvider, localDb);

      // 5. Verify local DB is currently empty of this transaction
      final initialLocalTxs = await localDb.transactionDao.getTransactionsForUser(userId);
      expect(initialLocalTxs.any((t) => t.id == 'tx-remote-only'), isFalse);

      // 6. Run Sync
      final result = await syncService.sync(userId);

      // 7. Verify local DB now contains remote transaction
      final finalLocalTxs = await localDb.transactionDao.getTransactionsForUser(userId);
      expect(finalLocalTxs.any((t) => t.id == 'tx-remote-only'), isTrue);
      expect(result.insertedCount, equals(1));
      expect(result.conflicts, isEmpty);
    });

    test('Bidirectional Sync: Detects conflicts when both sides updated', () async {
      // 1. Insert a transaction locally
      final now = DateTime.now();
      final dbFile = File(p.join(testTempPath, 'expenso_database.sqlite'));
      final localBackupFile = File(p.join(testTempPath, 'expenso_database_local.sqlite'));

      final localTx = Transaction(
        id: 'tx-conflict-id',
        userId: userId,
        categoryId: 'cat-food',
        paymentMethodId: 'pm-cash',
        type: 'expense',
        amount: 10000, // ₹100
        currency: 'INR',
        merchant: 'Local Edit',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 5)),
      );
      await localDb.transactionDao.insertTransaction(localTx);

      // 2. Close local DB and swap it out
      await localDb.close();
      await dbFile.rename(localBackupFile.path);

      // 3. Setup a remote database with same transaction ID but different amount/merchant and newer timestamp
      final remoteDb = AppDatabase.connect(NativeDatabase(dbFile));
      final remoteTx = Transaction(
        id: 'tx-conflict-id',
        userId: userId,
        categoryId: 'cat-food',
        paymentMethodId: 'pm-cash',
        type: 'expense',
        amount: 20000, // ₹200
        currency: 'INR',
        merchant: 'Remote Edit',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 10)), // Newer remote update
      );

      // Seed category in remote
      await remoteDb.categoryDao.insertCategory(Category(
        id: 'cat-food',
        userId: userId,
        name: 'Food',
        type: 'expense',
        usageCount: 0,
        isSystemDefault: false,
        createdAt: now,
      ));
      await remoteDb.transactionDao.insertTransaction(remoteTx);
      await remoteDb.close();

      // 4. Encrypt and backup remote DB
      await backupService.backup(userId);

      // 5. Delete the remote database file and swap the local database back
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      await localBackupFile.rename(dbFile.path);

      // Reopen local DB connection
      localDb = AppDatabase.connect(NativeDatabase(dbFile));
      mockRef.overrideProvider(databaseProvider, localDb);

      // 6. Run Sync
      final result = await syncService.sync(userId);

      // 7. Verify conflict is registered
      expect(result.conflicts, hasLength(1));
      expect(result.conflicts.first.local.merchant, equals('Local Edit'));
      expect(result.conflicts.first.remote.merchant, equals('Remote Edit'));

      // 8. Verify local transaction syncStatus is marked as 'conflict'
      final localConflictTx = await localDb.transactionDao.getTransactionById('tx-conflict-id');
      expect(localConflictTx!.syncStatus, equals('conflict'));
    });
  });
}
