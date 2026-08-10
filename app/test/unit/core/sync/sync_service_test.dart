import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
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
  String? privacyMode;

  @override
  Future<String?> getBackupEncryptionKey({String? userId}) async => backupKey;
  @override
  Future<void> saveBackupEncryptionKey(String key, {String? userId}) async => backupKey = key;
  @override
  Future<void> deleteBackupEncryptionKey({String? userId}) async => backupKey = null;

  @override
  Future<String?> getDatabaseKey({String? userId}) async => dbKey;
  @override
  Future<void> saveDatabaseKey(String key, {String? userId}) async => dbKey = key;
  @override
  Future<void> deleteDatabaseKey({String? userId}) async => dbKey = null;

  @override
  Future<String> getOrCreateDatabaseKey({required String userId}) async {
    String? key = await getDatabaseKey(userId: userId);
    if (key == null || key.isEmpty) {
      final bytes = utf8.encode(userId);
      final hash = sha256.convert(bytes);
      key = base64UrlEncode(hash.bytes);
      await saveDatabaseKey(key, userId: userId);
    }
    return key;
  }

  @override
  Future<String> getOrCreateBackupEncryptionKey({required String userId, String? googleAccount}) async {
    final suffix = googleAccount != null && googleAccount.isNotEmpty ? googleAccount : userId;
    String? key = await getBackupEncryptionKey(userId: suffix);
    if (key == null || key.isEmpty) {
      final bytes = utf8.encode('${suffix}_backup_salt');
      final hash = sha256.convert(bytes);
      key = base64Encode(hash.bytes);
      await saveBackupEncryptionKey(key, userId: suffix);
    }
    return key;
  }

  @override
  Future<String?> getPrivacyMode() async => privacyMode;
  @override
  Future<void> savePrivacyMode(String mode) async => privacyMode = mode;

  @override
  Future<String?> getUserId() async => null;

  final Map<String, String> _aiData = {};

  @override
  Future<String?> getAiMode() async => _aiData['ai_mode'];
  @override
  Future<void> saveAiMode(String mode) async => _aiData['ai_mode'] = mode;

  @override
  Future<String?> getAiProvider() async => _aiData['ai_provider'];
  @override
  Future<void> saveAiProvider(String provider) async => _aiData['ai_provider'] = provider;

  @override
  Future<String?> getAiModel(String provider) async => _aiData['ai_model_$provider'];
  @override
  Future<void> saveAiModel(String provider, String model) async => _aiData['ai_model_$provider'] = model;

  @override
  Future<String?> getSavedApiKeysJson(String provider) async => _aiData['api_keys_list_$provider'];
  @override
  Future<void> saveSavedApiKeysJson(String provider, String jsonStr) async => _aiData['api_keys_list_$provider'] = jsonStr;
  @override
  Future<void> deleteSavedApiKeysJson(String provider) async => _aiData.remove('api_keys_list_$provider');

  @override
  Future<String?> getActiveKeyId(String provider) async => _aiData['active_key_id_$provider'];
  @override
  Future<void> saveActiveKeyId(String provider, String keyId) async => _aiData['active_key_id_$provider'] = keyId;
  @override
  Future<void> deleteActiveKeyId(String provider) async => _aiData.remove('active_key_id_$provider');

  @override
  Future<String?> getApiKey(String provider) async => _aiData['api_key_$provider'];
  @override
  Future<void> saveApiKey(String provider, String key) async => _aiData['api_key_$provider'] = key;

  final Map<String, String> _storage = {};

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.contains('save') || name.contains('delete')) {
      return Future<void>.value();
    }
    if (name.contains('get')) {
      if (name.contains('Schedule')) return Future<String?>.value('manual');
      if (name.contains('Wifi') || name.contains('Charging') || name.contains('Enabled')) return Future<bool?>.value(false);
      if (name.contains('Size')) return Future<int?>.value(0);
      return Future<String?>.value(null);
    }
    return super.noSuchMethod(invocation);
  }
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
      final backupDb = AppDatabase.connect(NativeDatabase(dbFile));
      mockRef.overrideProvider(databaseProvider, backupDb);
      await backupService.backup(userId);
      await backupDb.close();

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
      final backupDb = AppDatabase.connect(NativeDatabase(dbFile));
      mockRef.overrideProvider(databaseProvider, backupDb);
      await backupService.backup(userId);
      await backupDb.close();

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

    test('Sync handles corrupted remote backup: deletes it and uploads a fresh local backup successfully', () async {
      // Let's get the simulated directory
      final simulatedDir = Directory(p.join(testTempPath, 'expenso_backup_simulated'));
      if (!simulatedDir.existsSync()) {
        simulatedDir.createSync(recursive: true);
      }
      
      // Seed a corrupted file with invalid format (e.g. just 100 bytes of zero)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final invalidBackupFile = File(p.join(simulatedDir.path, 'expenso_backup_$timestamp.enc'));
      await invalidBackupFile.writeAsBytes(List.generate(100, (index) => 0));
      
      // Create a mock metadata file for it
      final metaFile = File(p.join(simulatedDir.path, 'metadata_$timestamp.json'));
      await metaFile.writeAsString(jsonEncode({
        'timestamp': timestamp,
        'size': 100,
        'checksum': 'invalid_checksum',
        'userId': userId,
      }));
      
      // Verify listing cloud backups lists it
      final list = await backupService.listCloudBackups(userId);
      expect(list, hasLength(1));
      
      // 2. Execute Sync
      final result = await syncService.sync(userId);
      
      // 3. Verify Sync completed successfully, and uploaded a new valid backup, deleting the corrupted one
      expect(result.conflicts, isEmpty);
      
      // Verify files in AppData folder now
      final listAfter = await backupService.listCloudBackups(userId);
      // It should still have 1 backup (the fresh one we just uploaded), but the timestamp should be different
      expect(listAfter, hasLength(1));
      expect(listAfter.first['timestamp'], isNot(equals(timestamp)));
      
      // Validate that the new backup is a valid SQLite DB
      final latestBytes = await backupService.downloadLatestBackupBytes(userId);
      final decrypted = await backupService.decryptAndValidateBackup(latestBytes, listAfter.first['checksum'] as String?, userId);
      expect(decrypted.length, greaterThan(0));
      expect(String.fromCharCodes(decrypted.sublist(0, 15)), equals('SQLite format 3'));
    });
  });
}
