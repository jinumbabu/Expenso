import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/core/security/secure_storage_service.dart';

class MockFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SecureStorageService Tests', () {
    late MockFlutterSecureStorage mockStorage;
    late SecureStorageService secureStorageService;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      secureStorageService = SecureStorageService(storage: mockStorage);
    });

    test('Access Token operations', () async {
      expect(await secureStorageService.getAccessToken(), isNull);
      await secureStorageService.saveAccessToken('my-access-token');
      expect(await secureStorageService.getAccessToken(), equals('my-access-token'));
      await secureStorageService.deleteAccessToken();
      expect(await secureStorageService.getAccessToken(), isNull);
    });

    test('Refresh Token operations', () async {
      expect(await secureStorageService.getRefreshToken(), isNull);
      await secureStorageService.saveRefreshToken('my-refresh-token');
      expect(await secureStorageService.getRefreshToken(), equals('my-refresh-token'));
      await secureStorageService.deleteRefreshToken();
      expect(await secureStorageService.getRefreshToken(), isNull);
    });

    test('User ID operations', () async {
      expect(await secureStorageService.getUserId(), isNull);
      await secureStorageService.saveUserId('user-123');
      expect(await secureStorageService.getUserId(), equals('user-123'));
      await secureStorageService.deleteUserId();
      expect(await secureStorageService.getUserId(), isNull);
    });

    test('Backup Encryption Key operations', () async {
      expect(await secureStorageService.getBackupEncryptionKey(), isNull);
      await secureStorageService.saveBackupEncryptionKey('backup-key-123');
      expect(await secureStorageService.getBackupEncryptionKey(), equals('backup-key-123'));
      await secureStorageService.deleteBackupEncryptionKey();
      expect(await secureStorageService.getBackupEncryptionKey(), isNull);
    });

    test('Database Encryption Key operations', () async {
      expect(await secureStorageService.getDatabaseKey(), isNull);
      await secureStorageService.saveDatabaseKey('db-key-123');
      expect(await secureStorageService.getDatabaseKey(), equals('db-key-123'));
      await secureStorageService.deleteDatabaseKey();
      expect(await secureStorageService.getDatabaseKey(), isNull);
    });

    test('Clear All operations', () async {
      await secureStorageService.saveAccessToken('access');
      await secureStorageService.saveRefreshToken('refresh');
      await secureStorageService.saveUserId('user');
      
      expect(await secureStorageService.getAccessToken(), equals('access'));
      
      await secureStorageService.clearAll();
      
      expect(await secureStorageService.getAccessToken(), isNull);
      expect(await secureStorageService.getRefreshToken(), isNull);
      expect(await secureStorageService.getUserId(), isNull);
    });
  });
}
