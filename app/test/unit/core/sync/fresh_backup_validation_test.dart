import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart' as raw_sql;

import 'package:app/core/sync/backup_service.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/database/connection/native.dart';
import 'package:app/core/security/secure_storage_service.dart';
import 'package:app/core/database/database_repair_service.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';

// Mock path provider
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String _tempPath;
  MockPathProviderPlatform(this._tempPath);

  @override
  Future<String?> getApplicationSupportPath() async => p.join(_tempPath, 'support');
  @override
  Future<String?> getApplicationDocumentsPath() async => p.join(_tempPath, 'documents');
  @override
  Future<String?> getTemporaryPath() async => p.join(_tempPath, 'temp');
}

// Mock secure storage
class MockSecureStorageService implements SecureStorageService {
  String? backupKey;
  String? dbKey;
  String? privacyMode;
  String? googleToken;

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

  @override
  Future<String?> getGoogleAccessToken() async => googleToken;
  @override
  Future<void> saveGoogleAccessToken(String token) async => googleToken = token;
  @override
  Future<void> deleteGoogleAccessToken() async => googleToken = null;

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

  group('Fresh Backup E2E Pipeline Verification', () {
    late String testTempPath;
    late MockSecureStorageService mockSecureStorage;
    late AppDatabase database;
    late MockRef mockRef;
    late BackupService backupService;
    late File dbFile;
    const userId = 'user-E2E-test';

    setUp(() async {
      final systemTemp = Directory.systemTemp.createTempSync('expenso_e2e_');
      testTempPath = systemTemp.path;

      PathProviderPlatform.instance = MockPathProviderPlatform(testTempPath);

      mockSecureStorage = MockSecureStorageService();
      mockRef = MockRef();

      final supportDir = Directory(p.join(testTempPath, 'support'));
      if (!supportDir.existsSync()) {
        supportDir.createSync(recursive: true);
      }

      final tempDir = Directory(p.join(testTempPath, 'temp'));
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }
      dbFile = File(p.join(supportDir.path, 'expenso_database.sqlite'));

      // Initialize AppDatabase using connection to physical file
      database = AppDatabase.connect(NativeDatabase(dbFile));

      // Mock Riverpod providers
      final mockUser = User(
        id: userId,
        googleId: 'mock-google-id-E2E',
        email: 'e2e@expenso.ai',
        displayName: 'E2E Validator',
        currency: 'INR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRef.overrideProvider(authProvider, AuthState.authenticated(mockUser));
      mockRef.overrideProvider(databaseProvider, database);
      mockRef.overrideProvider(secureStorageProvider, mockSecureStorage);

      backupService = BackupService(mockRef, mockSecureStorage);
      SecureStorageService.customInstance = mockSecureStorage;

      // Force Drift to run migrations and initialize tables
      await database.customSelect('SELECT 1;').get();
    });

    tearDown(() async {
      await database.close();
      SecureStorageService.customInstance = null;
      try {
        final dir = Directory(testTempPath);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('Runs repair, creates backup, deletes old cloud backups, downloads, decrypts, and opens sqlite db', () async {
      // 1. Introduce Foreign Key Violations
      await database.customStatement('PRAGMA foreign_keys = OFF;');

      const String orphanAccountId = 'non-existent-account-id';
      const String orphanCategoryId = 'non-existent-category-id';
      final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      const String invalidUserId = 'non-existent-user-id';

      // Insert an orphaned transaction referencing non-existent account and category
      final txId1 = 'tx-E2E-1';
      await database.customStatement(
        'INSERT INTO transactions (id, user_id, account_id, category_id, type, amount, currency, source, created_at, updated_at, date) '
        'VALUES (?, "system", ?, ?, "expense", 100, "USD", "test", ?, ?, ?);',
        [txId1, orphanAccountId, orphanCategoryId, nowSecs, nowSecs, nowSecs],
      );

      // Insert an account referencing non-existent user
      final accId1 = 'acc-E2E-1';
      await database.customStatement(
        'INSERT INTO accounts (id, user_id, name, type, balance, is_default, created_at, updated_at, is_active, is_estimated) '
        'VALUES (?, ?, "Corrupted Account", "card", 500, 0, ?, ?, 1, 0);',
        [accId1, invalidUserId, nowSecs, nowSecs],
      );

      // Re-enable foreign keys
      await database.customStatement('PRAGMA foreign_keys = ON;');

      // Verify that PRAGMA foreign_key_check initially FAILS (returns rows)
      var fkRows = await database.customSelect('PRAGMA foreign_key_check;').get();
      expect(fkRows.isNotEmpty, isTrue, reason: 'Must start with FK violations');

      // 2. Perform Database Repair
      final repairService = DatabaseRepairService(database);
      final repairReport = await repairService.runRepair(currentUserId: userId);
      expect(repairReport.finalFkPass, isTrue, reason: 'FK check must pass after repair');

      // Verify that PRAGMA foreign_key_check is clean now
      fkRows = await database.customSelect('PRAGMA foreign_key_check;').get();
      expect(fkRows.isEmpty, isTrue, reason: 'FK check returned rows after repair');

      // 3. Delete existing cloud backups
      final backupDir = Directory(p.join(testTempPath, 'documents', 'expenso_backup_simulated'));
      if (backupDir.existsSync()) {
        backupDir.deleteSync(recursive: true);
      }

      // 4. Create and upload a brand-new backup
      final backupSize = await backupService.backup(userId);
      expect(backupSize, greaterThan(0));

      // 5. Download the backup immediately
      final list = await backupService.listBackups(userId);
      expect(list.isNotEmpty, isTrue);
      final latestBackup = list.first;

      final backupFilePath = latestBackup['backupFilePath'] as String;
      final encryptedBytes = await File(backupFilePath).readAsBytes();

      final localChecksum = sha256.convert(encryptedBytes).toString();
      final expectedChecksum = latestBackup['checksum'] as String;

      // 6. Decrypt and Validate the downloaded backup
      final decryptedBytes = await backupService.decryptAndValidateBackup(encryptedBytes, expectedChecksum, userId);

      // Verify decrypted file starts with the SQLite header
      final hasValidHeader = decryptedBytes.length >= 15 &&
          String.fromCharCodes(decryptedBytes.sublist(0, 15)) == 'SQLite format 3';
      expect(hasValidHeader, isTrue, reason: 'Header validation must match SQLite format 3');

      // 7. Open decrypted database and verify user version / query compatibility
      final tempDecryptedFile = File(p.join(testTempPath, 'temp_decrypted_db.sqlite'));
      await tempDecryptedFile.writeAsBytes(decryptedBytes, flush: true);

      final openDb = raw_sql.sqlite3.open(tempDecryptedFile.path);
      int schemaVersion = 0;
      try {
        final versionRes = openDb.select('PRAGMA user_version;');
        schemaVersion = versionRes.first.columnAt(0) as int;
        
        final testQuery = openDb.select('SELECT count(*) FROM categories;');
        expect(testQuery.isNotEmpty, isTrue);
      } finally {
        openDb.dispose();
      }

      expect(schemaVersion, equals(17), reason: 'Schema version must be 17');

      // Output Detailed E2E Report
      print('\n==================================================');
      print('          FRESH BACKUP VALIDATION REPORT          ');
      print('==================================================');
      print('• Local Backup Checksum:   $localChecksum');
      print('• Uploaded Checksum:       $expectedChecksum');
      print('• Downloaded Checksum:     $localChecksum');
      print('• SQLite Header Status:    ${hasValidHeader ? "PASS" : "FAIL"} (SQLite format 3)');
      print('• Database Open Test:      PASS (Query execution verified)');
      print('• DB Schema Version:       $schemaVersion');
      print('• Validation Status:       SUCCESS');
      print('==================================================\n');
    });
  });
}
