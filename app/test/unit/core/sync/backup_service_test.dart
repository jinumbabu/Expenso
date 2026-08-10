import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path/path.dart' as p;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart' as raw_sql;

import 'package:app/core/sync/backup_service.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/database/connection/native.dart';
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

// Mock database
class MockDatabase extends Fake implements AppDatabase {
  bool closed = false;
  
  @override
  Future<void> close() async {
    closed = true;
  }

  @override
  Future<List<dynamic>> customStatement(String statement, [List<dynamic>? args]) async {
    return [];
  }

  @override
  Selectable<QueryRow> customSelect(String query, {List<Variable> variables = const [], Set<ResultSetImplementation> readsFrom = const {}}) {
    if (query.contains('integrity_check')) {
      return MockSelectable<QueryRow>([
        MockQueryRow({'integrity_check': 'ok'})
      ]);
    }
    return MockSelectable<QueryRow>([]);
  }
}

class MockQueryRow extends Fake implements QueryRow {
  @override
  final Map<String, dynamic> data;

  MockQueryRow(this.data);
}

class MockSelectable<T> extends Selectable<T> {
  final List<T> _results;
  MockSelectable(this._results);

  @override
  Future<List<T>> get() async => _results;

  @override
  Stream<List<T>> watch() => Stream.value(_results);
}

// Mock QueryExecutorUser for Drift connection test
class MockQueryExecutorUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 9;
  
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

  group('BackupService Tests', () {
    late String testTempPath;
    late MockSecureStorageService mockSecureStorage;
    late MockDatabase mockDatabase;
    late MockRef mockRef;
    late BackupService backupService;
    late File dbFile;

    Future<void> writeValidSqliteDb(File file) async {
      final rawDb = raw_sql.sqlite3.open(file.path);
      try {
        rawDb.execute('PRAGMA user_version = 17;');
        rawDb.execute('CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY);');
        rawDb.execute('CREATE TABLE IF NOT EXISTS accounts (id TEXT PRIMARY KEY);');
        rawDb.execute('CREATE TABLE IF NOT EXISTS categories (id TEXT PRIMARY KEY);');
        rawDb.execute('CREATE TABLE IF NOT EXISTS payment_methods (id TEXT PRIMARY KEY);');
        rawDb.execute('CREATE TABLE IF NOT EXISTS transactions (id TEXT PRIMARY KEY);');
        rawDb.execute('CREATE TABLE IF NOT EXISTS budgets (id TEXT PRIMARY KEY);');
      } finally {
        rawDb.dispose();
      }
    }

    setUp(() async {
      // Create temporary directories
      final systemTemp = Directory.systemTemp.createTempSync('expenso_test_');
      testTempPath = systemTemp.path;

      // Register mock path provider
      PathProviderPlatform.instance = MockPathProviderPlatform(testTempPath);

      mockSecureStorage = MockSecureStorageService();
      mockDatabase = MockDatabase();
      mockRef = MockRef();

      // Setup mock providers
      final mockUser = User(
        id: 'user-123',
        googleId: 'mock-google-id',
        email: 'tester@expenso.ai',
        displayName: 'Test User',
        currency: 'INR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRef.overrideProvider(authProvider, AuthState.authenticated(mockUser));
      mockRef.overrideProvider(databaseProvider, mockDatabase);
      mockRef.overrideProvider(secureStorageProvider, mockSecureStorage);

      backupService = BackupService(mockRef, mockSecureStorage);
      SecureStorageService.customInstance = mockSecureStorage;

      // Create valid database file
      final supportDir = Directory(p.join(testTempPath, 'support'));
      if (!supportDir.existsSync()) {
        supportDir.createSync(recursive: true);
      }
      dbFile = File(p.join(supportDir.path, 'expenso_database.sqlite'));
      await writeValidSqliteDb(dbFile);

      // Create doc directory structure
      final docDir = Directory(p.join(testTempPath, 'documents'));
      if (!docDir.existsSync()) {
        docDir.createSync(recursive: true);
      }

      // Create temp directory structure
      final tempDir = Directory(p.join(testTempPath, 'temp'));
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }
    });

    tearDown(() {
      SecureStorageService.customInstance = null;
      try {
        final dir = Directory(testTempPath);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('Locate database file and execute local backup successfully', () async {
      expect(await dbFile.exists(), isTrue);

      final size = await backupService.backup('user-123');
      expect(size, greaterThan(0));

      final backupDir = Directory(p.join(testTempPath, 'documents', 'expenso_backup_simulated'));
      final files = backupDir.listSync();
      final backupFiles = files.where((f) => p.basename(f.path).startsWith('expenso_backup_') && f.path.endsWith('.enc')).toList();
      final metaFiles = files.where((f) => p.basename(f.path).startsWith('metadata_') && f.path.endsWith('.json')).toList();
      
      expect(backupFiles.length, equals(1));
      expect(metaFiles.length, equals(1));

      final metaContent = await File(metaFiles.first.path).readAsString();
      final metaJson = jsonDecode(metaContent) as Map<String, dynamic>;
      expect(metaJson['size'], equals(size));
      expect(metaJson['backupDate'], isNotNull);
    });

    test('Fetch backup metadata successfully', () async {
      await backupService.backup('user-123');
      
      final meta = await backupService.getBackupMetadata();
      expect(meta, isNotNull);
      expect(meta!['size'], greaterThan(0));
      expect(meta['backupDate'], isNotNull);
    });

    test('Restore database backup successfully', () async {
      await writeValidSqliteDb(dbFile);
      await backupService.backup('user-123');

      // Clear database content
      await dbFile.writeAsString('CORRUPTED CONTENT');

      await backupService.restore('user-123');

      expect(mockDatabase.closed, isTrue);

      final restoredBytes = await dbFile.readAsBytes();
      final bool hasValidHeader = restoredBytes.length >= 15 &&
          String.fromCharCodes(restoredBytes.sublist(0, 15)) == 'SQLite format 3';
      expect(hasValidHeader, isTrue);
    });

    test('Restore database rejects invalid backup due to checksum mismatch', () async {
      await writeValidSqliteDb(dbFile);
      await backupService.backup('user-123');

      final base64Key = await mockSecureStorage.getBackupEncryptionKey();
      expect(base64Key, isNotNull);
      final key = enc.Key.fromBase64(base64Key!);

      // Write garbage data that does NOT have the SQLite format 3 header inside the encrypted JSON
      final payloadMap = {
        'database': base64Encode(utf8.encode('NOT A VALID SQLITE DATABASE FILE')),
        'version': '1.0',
        'metadata': {'timestamp': 123456}
      };
      final payloadString = jsonEncode(payloadMap);
      final payloadBytes = utf8.encode(payloadString);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encryptBytes(payloadBytes, iv: iv);
      final output = BytesBuilder()..add(iv.bytes)..add(encrypted.bytes);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupDir = Directory(p.join(testTempPath, 'documents', 'expenso_backup_simulated'));
      final garbageBackupFile = File(p.join(backupDir.path, 'expenso_backup_$timestamp.enc'));
      await garbageBackupFile.writeAsBytes(output.toBytes(), flush: true);

      // Create metadata with checksum mismatch
      final metadataMap = {
        'appVersion': '2.0.0',
        'databaseVersion': 9,
        'backupDate': DateTime.now().toIso8601String(),
        'checksum': 'incorrect_checksum',
        'encrypted': true,
        'size': output.toBytes().length,
        'device': 'Test Device',
        'androidVersion': '15',
        'timestamp': timestamp,
      };
      final garbageMetaFile = File(p.join(backupDir.path, 'metadata_$timestamp.json'));
      await garbageMetaFile.writeAsString(jsonEncode(metadataMap), flush: true);

      await dbFile.writeAsString('SQLite format 3 LIVE DB STATE');

      expect(
        () => backupService.restore('user-123'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('checksum verification failed'))),
      );

      final currentContent = await dbFile.readAsString();
      expect(currentContent, equals('SQLite format 3 LIVE DB STATE'));
    });

    test('Restore database rejects invalid backup due to validation failure', () async {
      await writeValidSqliteDb(dbFile);
      await backupService.backup('user-123');

      final base64Key = await mockSecureStorage.getBackupEncryptionKey();
      expect(base64Key, isNotNull);
      final key = enc.Key.fromBase64(base64Key!);

      // Write valid encrypted file but with garbage database inside (header check fails)
      final payloadMap = {
        'database': base64Encode(utf8.encode('NOT A VALID SQLITE DATABASE FILE')),
        'version': '1.0',
        'metadata': {'timestamp': 123456}
      };
      final payloadString = jsonEncode(payloadMap);
      final payloadBytes = utf8.encode(payloadString);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encryptBytes(payloadBytes, iv: iv);
      final output = BytesBuilder()..add(iv.bytes)..add(encrypted.bytes);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupDir = Directory(p.join(testTempPath, 'documents', 'expenso_backup_simulated'));
      final garbageBackupFile = File(p.join(backupDir.path, 'expenso_backup_$timestamp.enc'));
      await garbageBackupFile.writeAsBytes(output.toBytes(), flush: true);

      final checksum = sha256.convert(output.toBytes()).toString();
      final metadataMap = {
        'appVersion': '2.0.0',
        'databaseVersion': 9,
        'backupDate': DateTime.now().toIso8601String(),
        'checksum': checksum,
        'encrypted': true,
        'size': output.toBytes().length,
        'device': 'Test Device',
        'androidVersion': '15',
        'timestamp': timestamp,
      };
      final garbageMetaFile = File(p.join(backupDir.path, 'metadata_$timestamp.json'));
      await garbageMetaFile.writeAsString(jsonEncode(metadataMap), flush: true);

      await dbFile.writeAsString('SQLite format 3 LIVE DB STATE');

      expect(
        () => backupService.restore('user-123'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('invalid database file'))),
      );

      final currentContent = await dbFile.readAsString();
      expect(currentContent, equals('SQLite format 3 LIVE DB STATE'));
    });

    test('Restore database rejects truncated backup file (actual size < pageSize * pageCount)', () async {
      await writeValidSqliteDb(dbFile);
      await backupService.backup('user-123');

      final base64Key = await mockSecureStorage.getBackupEncryptionKey();
      expect(base64Key, isNotNull);
      final key = enc.Key.fromBase64(base64Key!);

      // Write a valid SQLite header but with pageCount = 37 and actual bytes size far smaller
      final dbBytes = List<int>.filled(100, 0);
      final sqliteHeaderBytes = utf8.encode('SQLite format 3\0');
      for (int i = 0; i < sqliteHeaderBytes.length; i++) {
        dbBytes[i] = sqliteHeaderBytes[i];
      }
      dbBytes[16] = 0x10;
      dbBytes[17] = 0x00;
      dbBytes[28] = 0x00;
      dbBytes[29] = 0x00;
      dbBytes[30] = 0x00;
      dbBytes[31] = 0x25;

      final payloadMap = {
        'database': base64Encode(dbBytes),
        'version': '1.0',
        'metadata': {
          'timestamp': 123456,
          'backupSize': 100,
        }
      };
      final payloadString = jsonEncode(payloadMap);
      final payloadBytes = utf8.encode(payloadString);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encryptBytes(payloadBytes, iv: iv);
      final output = BytesBuilder()..add(iv.bytes)..add(encrypted.bytes);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupDir = Directory(p.join(testTempPath, 'documents', 'expenso_backup_simulated'));
      final truncatedBackupFile = File(p.join(backupDir.path, 'expenso_backup_$timestamp.enc'));
      await truncatedBackupFile.writeAsBytes(output.toBytes(), flush: true);

      final checksum = sha256.convert(output.toBytes()).toString();
      final metadataMap = {
        'appVersion': '2.0.0',
        'databaseVersion': 9,
        'backupDate': DateTime.now().toIso8601String(),
        'checksum': checksum,
        'encrypted': true,
        'size': output.toBytes().length,
        'device': 'Test Device',
        'androidVersion': '15',
        'timestamp': timestamp,
      };
      final truncatedMetaFile = File(p.join(backupDir.path, 'metadata_$timestamp.json'));
      await truncatedMetaFile.writeAsString(jsonEncode(metadataMap), flush: true);

      await dbFile.writeAsString('SQLite format 3 LIVE DB STATE');

      expect(
        () => backupService.restore('user-123'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('BACKUP FILE IS TRUNCATED'))),
      );

      final currentContent = await dbFile.readAsString();
      expect(currentContent, equals('SQLite format 3 LIVE DB STATE'));
    });

    test('Delete backup successfully', () async {
      await backupService.backup('user-123');
      
      final backupDir = Directory(p.join(testTempPath, 'documents', 'expenso_backup_simulated'));
      var files = backupDir.listSync();
      expect(files.isNotEmpty, isTrue);

      await backupService.deleteBackup();

      files = backupDir.listSync();
      expect(files.isEmpty, isTrue);
    });

    test('Backup history retention policy: daily, weekly, monthly version pruning', () async {
      await writeValidSqliteDb(dbFile);

      final backupDir = Directory(p.join(testTempPath, 'documents', 'expenso_backup_simulated'));
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }
      final now = DateTime.now();
      
      final times = [
        now.millisecondsSinceEpoch, // latest (age = 0)
        now.subtract(const Duration(days: 5)).millisecondsSinceEpoch, // daily (age = 5)
        now.subtract(const Duration(days: 10)).millisecondsSinceEpoch, // weekly week-1 (age = 10)
        now.subtract(const Duration(days: 11)).millisecondsSinceEpoch, // redundant week-1 to prune (age = 11)
        now.subtract(const Duration(days: 14)).millisecondsSinceEpoch, // weekly week-2 (age = 14)
        now.subtract(const Duration(days: 45)).millisecondsSinceEpoch, // monthly (age = 45)
      ];

      for (var ts in times) {
        final checksum = 'checksum-$ts';
        final metadataMap = {
          'appVersion': '2.0.0',
          'databaseVersion': 9,
          'backupDate': DateTime.fromMillisecondsSinceEpoch(ts).toIso8601String(),
          'checksum': checksum,
          'encrypted': true,
          'size': 100,
          'device': 'Test Device',
          'androidVersion': '15',
          'timestamp': ts,
        };
        
        final metaFile = File(p.join(backupDir.path, 'metadata_$ts.json'));
        await metaFile.writeAsString(jsonEncode(metadataMap));

        final backupFile = File(p.join(backupDir.path, 'expenso_backup_$ts.enc'));
        await backupFile.writeAsBytes(utf8.encode('Encrypted Bytes $ts'));
      }

      var files = backupDir.listSync();
      var backupFiles = files.where((f) => p.basename(f.path).startsWith('expenso_backup_')).toList();
      expect(backupFiles.length, equals(6));

      await backupService.pruneOldBackups();

      files = backupDir.listSync();
      backupFiles = files.where((f) => p.basename(f.path).startsWith('expenso_backup_')).toList();
      expect(backupFiles.length, equals(5));
      
      final prunedBackup = File(p.join(backupDir.path, 'expenso_backup_${times[3]}.enc'));
      expect(await prunedBackup.exists(), isFalse);
    });

    test('Recovery Flow: Startup detects corrupted database, renames it, and restores from last valid backup', () async {
      final secureStorage = MockSecureStorageService();
      final masterKey = enc.Key.fromSecureRandom(32);
      await secureStorage.saveBackupEncryptionKey(masterKey.base64);

      final backupDir = Directory(p.join(testTempPath, 'documents', 'expenso_backup_simulated'));
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }

      final tempDbForBytes = File(p.join(testTempPath, 'temp_db_for_bytes.sqlite'));
      await writeValidSqliteDb(tempDbForBytes);
      final dbBytes = await tempDbForBytes.readAsBytes();

      final payloadMap = {
        'database': base64Encode(dbBytes),
        'version': '1.0',
        'metadata': {'timestamp': 12345}
      };
      final payloadBytes = utf8.encode(jsonEncode(payloadMap));
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(masterKey, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encryptBytes(payloadBytes, iv: iv);
      final encryptedData = (BytesBuilder()..add(iv.bytes)..add(encrypted.bytes)).toBytes();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File(p.join(backupDir.path, 'expenso_backup_$timestamp.enc'));
      await backupFile.writeAsBytes(encryptedData, flush: true);

      final supportDir = Directory(p.join(testTempPath, 'support'));
      if (!supportDir.existsSync()) {
        supportDir.createSync(recursive: true);
      }
      final sqliteFile = File(p.join(supportDir.path, 'expenso_database.sqlite'));
      await sqliteFile.writeAsString('CORRUPTED DATABASE BYTES CONTENT');

      SecureStorageService.customInstance = secureStorage;
      final executor = openConnection();
      try {
        await executor.ensureOpen(MockQueryExecutorUser());
      } catch (e, st) {
        print('RECOVERY FLOW TEST EXCEPTION: $e\n$st');
      }

      final corruptedFile = File('${sqliteFile.path}.corrupted');
      expect(await corruptedFile.exists(), isTrue);

      final fileContent = await sqliteFile.readAsBytes();
      final bool hasValidHeader = fileContent.length >= 15 &&
          String.fromCharCodes(fileContent.sublist(0, 15)) == 'SQLite format 3';
      expect(hasValidHeader, isTrue);
    });

    test('Backup progress callback reports steps and percentage', () async {
      await writeValidSqliteDb(dbFile);

      final List<Map<String, dynamic>> progressUpdates = [];
      await backupService.backup(
        'user-123',
        onProgress: (progress, step, totalSteps, task) {
          progressUpdates.add({
            'progress': progress,
            'step': step,
            'totalSteps': totalSteps,
            'task': task,
          });
        },
      );

      expect(progressUpdates.isNotEmpty, isTrue);
      expect(progressUpdates.any((u) => u['step'] == 1), isTrue);
      expect(progressUpdates.any((u) => u['progress'] == 1.0), isTrue);
    });

    test('Restore progress callback reports steps and percentage', () async {
      await writeValidSqliteDb(dbFile);
      await backupService.backupLocal('user-123');

      final locals = await backupService.listLocalBackups('user-123');
      expect(locals.isNotEmpty, isTrue);

      final List<Map<String, dynamic>> progressUpdates = [];
      await backupService.restore(
        'user-123',
        backup: locals.first,
        onProgress: (progress, step, totalSteps, task) {
          progressUpdates.add({
            'progress': progress,
            'step': step,
            'totalSteps': totalSteps,
            'task': task,
          });
        },
      );

      expect(progressUpdates.isNotEmpty, isTrue);
      expect(progressUpdates.any((u) => u['step'] == 1), isTrue);
      expect(progressUpdates.last['progress'], equals(1.0));
    });
  });
}
