import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _backupEncryptionKey = 'backup_encryption_key';
  static const String _dbEncryptionKey = 'db_encryption_key';

  Future<void> saveBackupEncryptionKey(String key) async {
    await _storage.write(key: _backupEncryptionKey, value: key);
  }

  Future<String?> getBackupEncryptionKey() async {
    return await _storage.read(key: _backupEncryptionKey);
  }

  Future<void> deleteBackupEncryptionKey() async {
    await _storage.delete(key: _backupEncryptionKey);
  }

  Future<void> saveDatabaseKey(String key) async {
    await _storage.write(key: _dbEncryptionKey, value: key);
  }

  Future<String?> getDatabaseKey() async {
    return await _storage.read(key: _dbEncryptionKey);
  }

  Future<void> deleteDatabaseKey() async {
    await _storage.delete(key: _dbEncryptionKey);
  }

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
