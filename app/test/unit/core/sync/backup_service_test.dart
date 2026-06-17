import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path/path.dart' as p;

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

// Mock database
class MockDatabase extends Fake implements AppDatabase {
  bool closed = false;
  @override
  Future<void> close() async {
    closed = true;
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

  group('BackupService Tests', () {
    late String testTempPath;
    late MockSecureStorageService mockSecureStorage;
    late MockDatabase mockDatabase;
    late MockRef mockRef;
    late BackupService backupService;
    late File dbFile;

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

      backupService = BackupService(mockRef, mockSecureStorage);

      // Create dummy database file to backup
      dbFile = File(p.join(testTempPath, 'expenso_database.sqlite'));
      await dbFile.writeAsString('SQLITE DUMMY DATABASE BYTES CONTENT');
    });

    tearDown(() {
      try {
        final dir = Directory(testTempPath);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('Locate database file and execute local backup successfully', () async {
      expect(await dbFile.exists(), isTrue);

      // Verify backup returns length of encrypted file
      final size = await backupService.backup('user-123');
      expect(size, greaterThan(0));

      // Verify backup files exist locally in mock cloud
      final backupFile = File(p.join(testTempPath, 'expenso_backup_simulated', 'expenso_backup_v1.enc'));
      final metaFile = File(p.join(testTempPath, 'expenso_backup_simulated', 'expenso_backup_metadata.json'));
      
      expect(await backupFile.exists(), isTrue);
      expect(await metaFile.exists(), isTrue);

      // Read backup metadata
      final metaContent = await metaFile.readAsString();
      final metaJson = jsonDecode(metaContent) as Map<String, dynamic>;
      expect(metaJson['backup_size'], equals(size));
      expect(metaJson['last_backup_date'], isNotNull);
    });

    test('Fetch backup metadata successfully', () async {
      await backupService.backup('user-123');
      
      final meta = await backupService.getBackupMetadata();
      expect(meta, isNotNull);
      expect(meta!['backup_size'], greaterThan(0));
      expect(meta['last_backup_date'], isNotNull);
    });

    test('Restore database backup successfully', () async {
      // 1. Perform backup of original content
      await backupService.backup('user-123');

      // 2. Clear database content (simulating local database corruption/deletion)
      await dbFile.writeAsString('CORRUPTED CONTENT');

      // 3. Trigger restore
      await backupService.restore('user-123');

      // 4. Verify database provider is closed
      expect(mockDatabase.closed, isTrue);

      // 5. Verify database file content is correctly decrypted and restored
      final restoredContent = await dbFile.readAsString();
      expect(restoredContent, equals('SQLITE DUMMY DATABASE BYTES CONTENT'));
    });

    test('Delete backup successfully', () async {
      await backupService.backup('user-123');
      
      final backupFile = File(p.join(testTempPath, 'expenso_backup_simulated', 'expenso_backup_v1.enc'));
      final metaFile = File(p.join(testTempPath, 'expenso_backup_simulated', 'expenso_backup_metadata.json'));
      
      expect(await backupFile.exists(), isTrue);

      await backupService.deleteBackup();

      expect(await backupFile.exists(), isFalse);
      expect(await metaFile.exists(), isFalse);
    });
  });
}
