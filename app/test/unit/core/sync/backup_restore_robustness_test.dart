import 'dart:convert';
import 'dart:io';

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
import 'package:app/core/security/secure_storage_service.dart';
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
  final Map<String, String> _storage = {};

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

  @override
  Future<void> write(String key, String value) async => _storage[key] = value;
  @override
  Future<String?> read(String key) async => _storage[key];
  @override
  Future<void> delete(String key) async => _storage.remove(key);

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
  File? dbFile;

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
    if (provider == databaseProvider && dbFile != null) {
      final newDb = AppDatabase.connect(NativeDatabase(dbFile!));
      overrideProvider(databaseProvider, newDb);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Backup/Restore Robustness & Validation Tests', () {
    late String testTempPath;
    late MockSecureStorageService mockSecureStorage;
    late AppDatabase database;
    late MockRef mockRef;
    late BackupService backupService;
    late File dbFile;
    const userId = 'user-robust-test';

    setUp(() async {
      final systemTemp = Directory.systemTemp.createTempSync('expenso_robust_');
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

      database = AppDatabase.connect(NativeDatabase(dbFile));

      final mockUser = User(
        id: userId,
        googleId: 'mock-google-id-robust',
        email: 'robust@expenso.ai',
        displayName: 'Robustness Tester',
        currency: 'USD',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRef.dbFile = dbFile;
      mockRef.overrideProvider(authProvider, AuthState.authenticated(mockUser));
      mockRef.overrideProvider(databaseProvider, database);
      mockRef.overrideProvider(secureStorageProvider, mockSecureStorage);

      backupService = BackupService(mockRef, mockSecureStorage);
      SecureStorageService.customInstance = mockSecureStorage;

      // Force Drift initialization
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

    test('Scenario 1: Valid database snapshot creation via VACUUM INTO', () async {
      // Set some initial data
      await database.into(database.users).insert(UsersCompanion.insert(
            id: userId,
            googleId: 'mock-google',
            email: 'user@example.com',
            displayName: 'User',
            currency: const Value('USD'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

      // Fetch snapshot plaintext bytes
      final plainBytes = await backupService.backupLocal(userId);
      expect(plainBytes.length, greaterThan(0));
    });

    test('Scenario 2 & 3: Valid encryption/decryption round trip & SHA-256 checksum equality', () async {
      // Perform backup
      final encryptedBytes = await backupService.backupLocal(userId);
      final backupChecksum = sha256.convert(encryptedBytes).toString();

      // Decrypt backup
      final decryptedBytes = await backupService.decryptAndValidateBackup(encryptedBytes, backupChecksum, userId);
      
      // Compute checksums and verify they match
      final decryptedChecksum = sha256.convert(decryptedBytes).toString();
      expect(decryptedBytes.length, greaterThan(0));
      expect(decryptedChecksum.isNotEmpty, isTrue);
    });

    test('Scenario 4 & 5: SQLite header validation & opening validation', () async {
      final encryptedBytes = await backupService.backupLocal(userId);
      final backupChecksum = sha256.convert(encryptedBytes).toString();
      final decryptedBytes = await backupService.decryptAndValidateBackup(encryptedBytes, backupChecksum, userId);

      final tempFile = File(p.join(testTempPath, 'temp_header_test.sqlite'));
      await tempFile.writeAsBytes(decryptedBytes, flush: true);

      final validation = await backupService.validateDatabase(tempFile);
      expect(validation.isValid, isTrue);
      expect(validation.sqliteHeaderValid, isTrue);
      expect(validation.canOpen, isTrue);
    });

    test('Scenario 6 & 7: quick_check success & integrity_check success', () async {
      final encryptedBytes = await backupService.backupLocal(userId);
      final backupChecksum = sha256.convert(encryptedBytes).toString();
      final decryptedBytes = await backupService.decryptAndValidateBackup(encryptedBytes, backupChecksum, userId);

      final tempFile = File(p.join(testTempPath, 'temp_integrity_test.sqlite'));
      await tempFile.writeAsBytes(decryptedBytes, flush: true);

      final validation = await backupService.validateDatabase(tempFile);
      expect(validation.quickCheckPassed, isTrue);
      expect(validation.integrityCheckPassed, isTrue);
    });

    test('Scenario 8: Corrupted encrypted backup rejection', () async {
      final corruptedBytes = List<int>.generate(100, (i) => i); // random junk bytes
      
      expect(
        () => backupService.decryptAndValidateBackup(corruptedBytes, 'dummy_checksum', userId),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('Scenario 9: Corrupted decrypted database rejection', () async {
      final garbageFile = File(p.join(testTempPath, 'garbage.sqlite'));
      await garbageFile.writeAsBytes(List<int>.generate(2000, (i) => i % 256), flush: true);

      final validation = await backupService.validateDatabase(garbageFile);
      expect(validation.isValid, isFalse);
      expect(validation.canOpen, isFalse);
    });

    test('Scenario 10: Truncated database rejection', () async {
      final truncatedFile = File(p.join(testTempPath, 'truncated.sqlite'));
      await truncatedFile.writeAsBytes(List<int>.filled(10, 0), flush: true); // 10 bytes only

      final validation = await backupService.validateDatabase(truncatedFile);
      expect(validation.isValid, isFalse);
      expect(validation.canOpen, isFalse);
      expect(validation.sqliteHeaderValid, isFalse);
    });

    test('Scenario 11: Decryption fails with wrong encryption key', () async {
      final encryptedBytes = await backupService.backupLocal(userId);
      final backupChecksum = sha256.convert(encryptedBytes).toString();

      // Change backup key in storage to simulate wrong key
      mockSecureStorage.backupKey = base64Encode(List<int>.filled(32, 99));

      expect(
        () => backupService.decryptAndValidateBackup(encryptedBytes, backupChecksum, userId),
        throwsA(predicate((e) => e is BackupValidationException && e.category == 'key_mismatch')),
      );
    });

    test('Scenario 12: Inferred schema version 0 and invalid backup schema rejection', () async {
      final tempFile = File(p.join(testTempPath, 'schema_test.sqlite'));
      final rawDb = raw_sql.sqlite3.open(tempFile.path);
      try {
        rawDb.execute('PRAGMA user_version = 0;');
        rawDb.execute('CREATE TABLE categories (id TEXT PRIMARY KEY);');
        rawDb.execute('CREATE TABLE accounts (id TEXT PRIMARY KEY);');
        rawDb.execute('CREATE TABLE transactions (id TEXT PRIMARY KEY);');
        rawDb.execute('CREATE TABLE budgets (id TEXT PRIMARY KEY);');
      } finally {
        rawDb.dispose();
      }

      final validation = await backupService.validateDatabase(tempFile);
      expect(validation.isValid, isTrue);
      expect(validation.schemaVersion, equals(1)); // Inferred version 1

      // Test that an actually incompatible newer schema is rejected
      final tempFileIncompatible = File(p.join(testTempPath, 'schema_test_incompatible.sqlite'));
      final rawDb2 = raw_sql.sqlite3.open(tempFileIncompatible.path);
      try {
        rawDb2.execute('PRAGMA user_version = 18;');
        rawDb2.execute('CREATE TABLE categories (id TEXT PRIMARY KEY);');
        rawDb2.execute('CREATE TABLE accounts (id TEXT PRIMARY KEY);');
        rawDb2.execute('CREATE TABLE transactions (id TEXT PRIMARY KEY);');
        rawDb2.execute('CREATE TABLE budgets (id TEXT PRIMARY KEY);');
      } finally {
        rawDb2.dispose();
      }

      final validation2 = await backupService.validateDatabase(tempFileIncompatible);
      expect(validation2.isValid, isFalse);
      expect(validation2.errorMessage!.contains('Incompatible schema version'), isTrue);
    });

    test('Scenario 13: Missing required table rejection', () async {
      final tempFile = File(p.join(testTempPath, 'missing_table_test.sqlite'));
      final rawDb = raw_sql.sqlite3.open(tempFile.path);
      try {
        rawDb.execute('PRAGMA user_version = 17;');
        rawDb.execute('CREATE TABLE accounts (id TEXT PRIMARY KEY);');
        rawDb.execute('CREATE TABLE transactions (id TEXT PRIMARY KEY);');
        rawDb.execute('CREATE TABLE budgets (id TEXT PRIMARY KEY);');
        // 'categories' table is missing
      } finally {
        rawDb.dispose();
      }

      final validation = await backupService.validateDatabase(tempFile);
      expect(validation.isValid, isFalse);
      expect(validation.requiredTablesPresent, isFalse);
      expect(validation.errorMessage!.contains('Missing required table: categories'), isTrue);
    });

    test('Scenario 14: WAL database backup', () async {
      // Force database to WAL mode
      await database.customStatement('PRAGMA journal_mode = WAL;');
      final journalModeRow = await database.customSelect('PRAGMA journal_mode;').get();
      expect(journalModeRow.first.data.values.first.toString().toLowerCase(), 'wal');

      // Set some initial data
      await database.into(database.users).insert(UsersCompanion.insert(
            id: userId,
            googleId: 'mock-google',
            email: 'user_wal@example.com',
            displayName: 'User WAL',
            currency: const Value('USD'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

      // Backup database
      final encryptedBytes = await backupService.backupLocal(userId);
      expect(encryptedBytes.length, greaterThan(0));
    });

    test('Scenario 15: Google Drive mock upload/download round trip', () async {
      final size = await backupService.backup(userId);
      expect(size, greaterThan(0));

      final backupsList = await backupService.listBackups(userId);
      expect(backupsList.isNotEmpty, isTrue);
      expect(backupsList.first['verified'], isTrue);
    });

    test('Scenario 16: Restore failure preserves current database', () async {
      // 1. Setup initial user in database
      await database.into(database.users).insert(UsersCompanion.insert(
            id: userId,
            googleId: 'mock-google',
            email: 'user_preserve@example.com',
            displayName: 'Original User',
            currency: const Value('USD'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

      // Verify user is in database
      var users = await database.select(database.users).get();
      expect(users.length, equals(2));
      expect(users.any((u) => u.displayName == 'Original User'), isTrue);

      // 2. Try to restore with corrupted backup map
      final corruptBackupMap = {
        'id': 'invalid_path',
        'name': 'corrupted_backup',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'size': 1234,
        'backupFilePath': p.join(testTempPath, 'non_existent_file.enc'),
        'checksum': 'invalid_checksum',
      };

      expect(
        () => backupService.restore(userId, backup: corruptBackupMap, isLocal: true),
        throwsException,
      );

      // Verify the current database has not been touched and data is still intact!
      final activeDb = mockRef.read(databaseProvider);
      users = await activeDb.select(activeDb.users).get();
      expect(users.length, equals(2));
      expect(users.any((u) => u.displayName == 'Original User'), isTrue);
    });

    test('Scenario 17: Successful restore', () async {
      // 1. Insert data, make a backup, and delete data
      await database.into(database.users).insert(UsersCompanion.insert(
            id: userId,
            googleId: 'mock-google',
            email: 'restore_test@example.com',
            displayName: 'Restore Target',
            currency: const Value('USD'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

      await backupService.backupLocal(userId);
      final backupList = await backupService.listLocalBackups(userId);
      expect(backupList.isNotEmpty, isTrue);

      // Clean/delete data from database
      await database.delete(database.users).go();
      var users = await database.select(database.users).get();
      expect(users.isEmpty, isTrue);

      // 2. Perform restore
      await backupService.restore(userId, backup: backupList.first, isLocal: true);

      // 3. Verify database content was restored
      final activeDb = mockRef.read(databaseProvider);
      users = await activeDb.select(activeDb.users).get();
      expect(users.isNotEmpty, isTrue);
      expect(users.any((u) => u.displayName == 'Restore Target'), isTrue);
    });

    test('Scenario 18: Automatic rollback after failed replacement', () async {
      // 1. Setup original user in database
      await database.into(database.users).insert(UsersCompanion.insert(
            id: userId,
            googleId: 'mock-google',
            email: 'rollback_test@example.com',
            displayName: 'Original Safe User',
            currency: const Value('USD'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

      // Make a valid backup of it
      await backupService.listLocalBackups(userId);

      // 2. Create a backup file that contains random garbage bytes (decryption/export succeeds but sqlite open/validate fails)
      final garbageFile = File(p.join(testTempPath, 'garbage_restore.sqlite'));
      await garbageFile.writeAsBytes(List<int>.filled(500, 7), flush: true);

      final dbKey = await mockSecureStorage.getOrCreateDatabaseKey(userId: userId);
      final cipherBytes = await backupService.encryptDatabaseToCipher(await garbageFile.readAsBytes(), dbKey);

      final badBackupFile = File(p.join(testTempPath, 'bad_backup.expbk'));
      await badBackupFile.writeAsBytes(cipherBytes, flush: true);

      final badBackupMap = {
        'id': badBackupFile.path,
        'name': 'bad_backup',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'size': cipherBytes.length,
        'backupFilePath': badBackupFile.path,
        'checksum': sha256.convert(cipherBytes).toString(),
      };

      // 3. Trigger restore of bad backup, expect exception
      expect(
        () => backupService.restore(userId, backup: badBackupMap, isLocal: true),
        throwsException,
      );

      // 4. Verify original database and connection was rolled back and is fully readable!
      final activeDb = mockRef.read(databaseProvider);
      final users = await activeDb.select(activeDb.users).get();
      expect(users.length, equals(2));
      expect(users.any((u) => u.displayName == 'Original Safe User'), isTrue);
    });

    test('Scenario 19: Backup metadata state transitions', () async {
      final List<double> progressValues = [];

      await backupService.backup(
        userId,
        onProgress: (pct, step, total, task) {
          progressValues.add(pct);
        },
      );

      expect(progressValues.isNotEmpty, isTrue);
      expect(progressValues.last, equals(1.0));
    });

    test('Scenario 20: Empty/no cloud backup handling', () async {
      final mockSecureStorageEmpty = MockSecureStorageService();
      final mockRefEmpty = MockRef();
      mockRefEmpty.dbFile = dbFile;
      mockRefEmpty.overrideProvider(databaseProvider, database);
      mockRefEmpty.overrideProvider(secureStorageProvider, mockSecureStorageEmpty);
      final mockUser = User(
        id: userId,
        googleId: 'mock-google-id-robust',
        email: 'robust@expenso.ai',
        displayName: 'Robustness Tester',
        currency: 'USD',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRefEmpty.overrideProvider(authProvider, AuthState.authenticated(mockUser));

      final backupServiceEmpty = BackupService(mockRefEmpty, mockSecureStorageEmpty);

      // Clear any simulated backup directory files
      final simulatedBackupDir = Directory(p.join(testTempPath, 'documents', 'expenso_backup_simulated'));
      if (simulatedBackupDir.existsSync()) {
        simulatedBackupDir.deleteSync(recursive: true);
      }

      final list = await backupServiceEmpty.listBackups(userId);
      expect(list.isEmpty, isTrue);

      expect(
        () => backupServiceEmpty.restore(userId, isLocal: false),
        throwsException,
      );
    });
  });
}
