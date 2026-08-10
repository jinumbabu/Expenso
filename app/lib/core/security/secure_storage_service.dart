import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static SecureStorageService? _customInstance;
  static set customInstance(SecureStorageService? instance) => _customInstance = instance;

  factory SecureStorageService({FlutterSecureStorage? storage}) {
    if (_customInstance != null) {
      return _customInstance!;
    }
    return SecureStorageService._internal(storage ?? const FlutterSecureStorage());
  }

  SecureStorageService._internal(this._storage);

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _backupEncryptionKey = 'backup_encryption_key';
  static const String _dbEncryptionKey = 'db_encryption_key';
  static const String _privacyModeKey = 'privacy_mode';
  static const String _googleAccessTokenKey = 'google_access_token';

  Future<void> saveGoogleAccessToken(String token) async {
    await _storage.write(key: _googleAccessTokenKey, value: token);
  }

  Future<String?> getGoogleAccessToken() async {
    return await _storage.read(key: _googleAccessTokenKey);
  }

  Future<void> deleteGoogleAccessToken() async {
    await _storage.delete(key: _googleAccessTokenKey);
  }

  Future<void> savePrivacyMode(String mode) async {
    await _storage.write(key: _privacyModeKey, value: mode);
  }

  Future<String?> getPrivacyMode() async {
    return await _storage.read(key: _privacyModeKey);
  }

  Future<void> saveBackupEncryptionKey(String key, {String? userId}) async {
    final storageKey = userId != null ? '${_backupEncryptionKey}_$userId' : _backupEncryptionKey;
    await _storage.write(key: storageKey, value: key);
  }

  Future<String?> getBackupEncryptionKey({String? userId}) async {
    final storageKey = userId != null ? '${_backupEncryptionKey}_$userId' : _backupEncryptionKey;
    return await _storage.read(key: storageKey);
  }

  Future<void> deleteBackupEncryptionKey({String? userId}) async {
    final storageKey = userId != null ? '${_backupEncryptionKey}_$userId' : _backupEncryptionKey;
    await _storage.delete(key: storageKey);
  }

  Future<void> saveDatabaseKey(String key, {String? userId}) async {
    final storageKey = userId != null ? '${_dbEncryptionKey}_$userId' : _dbEncryptionKey;
    await _storage.write(key: storageKey, value: key);
  }

  Future<String?> getDatabaseKey({String? userId}) async {
    final storageKey = userId != null ? '${_dbEncryptionKey}_$userId' : _dbEncryptionKey;
    return await _storage.read(key: storageKey);
  }

  Future<void> deleteDatabaseKey({String? userId}) async {
    final storageKey = userId != null ? '${_dbEncryptionKey}_$userId' : _dbEncryptionKey;
    await _storage.delete(key: storageKey);
  }

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

  Future<String> getOrCreateBackupEncryptionKey({required String userId, String? googleAccount}) async {
    final suffix = googleAccount != null && googleAccount.isNotEmpty ? googleAccount : userId;
    String? key = await getBackupEncryptionKey(userId: suffix);
    if (key == null || key.isEmpty) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      key = base64Encode(bytes);
      await saveBackupEncryptionKey(key, userId: suffix);
    }
    return key;
  }

  Future<void> saveCustomDisplayName(String name, {required String userId}) async {
    await _storage.write(key: 'custom_display_name_$userId', value: name);
  }

  Future<String?> getCustomDisplayName({required String userId}) async {
    return await _storage.read(key: 'custom_display_name_$userId');
  }

  Future<void> deleteCustomDisplayName({required String userId}) async {
    await _storage.delete(key: 'custom_display_name_$userId');
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

  static const String _lastSmsSyncTimeKey = 'last_sms_sync_time';

  Future<void> saveLastSmsSyncTime(DateTime time) async {
    await _storage.write(key: _lastSmsSyncTimeKey, value: time.toIso8601String());
  }

  Future<DateTime?> getLastSmsSyncTime() async {
    final val = await _storage.read(key: _lastSmsSyncTimeKey);
    if (val == null) return null;
    return DateTime.tryParse(val);
  }

  static const String _autoImportEnabledKey = 'auto_import_enabled';
  static const String _hasRequestedSmsPermissionKey = 'has_requested_sms_permission';
  static const String _lastPermissionRequestTimeKey = 'last_permission_request_time';

  Future<void> saveHasRequestedSmsPermission(bool value) async {
    await _storage.write(key: _hasRequestedSmsPermissionKey, value: value.toString());
  }

  Future<bool> getHasRequestedSmsPermission() async {
    final val = await _storage.read(key: _hasRequestedSmsPermissionKey);
    return val == 'true';
  }

  Future<void> saveAutoImportEnabled(bool value) async {
    await _storage.write(key: _autoImportEnabledKey, value: value.toString());
  }

  Future<bool> getAutoImportEnabled() async {
    final val = await _storage.read(key: _autoImportEnabledKey);
    return val != 'false';
  }

  Future<void> saveLastPermissionRequestTime(DateTime time) async {
    await _storage.write(key: _lastPermissionRequestTimeKey, value: time.toIso8601String());
  }

  Future<DateTime?> getLastPermissionRequestTime() async {
    final val = await _storage.read(key: _lastPermissionRequestTimeKey);
    if (val == null) return null;
    return DateTime.tryParse(val);
  }

  // --- AI Provider Settings & Keys Keys ---
  static const String _aiModeKey = 'ai_mode';
  static const String _aiProviderKey = 'ai_provider';
  static const String _aiModelPrefix = 'ai_model_';
  static const String _apiKeyPrefix = 'api_key_';

  Future<void> saveAiMode(String mode) async {
    await _storage.write(key: _aiModeKey, value: mode);
  }

  Future<String?> getAiMode() async {
    return await _storage.read(key: _aiModeKey);
  }

  Future<void> saveAiProvider(String provider) async {
    await _storage.write(key: _aiProviderKey, value: provider);
  }

  Future<String?> getAiProvider() async {
    return await _storage.read(key: _aiProviderKey);
  }

  Future<void> saveAiModel(String provider, String model) async {
    await _storage.write(key: '$_aiModelPrefix$provider', value: model);
  }

  Future<String?> getAiModel(String provider) async {
    return await _storage.read(key: '$_aiModelPrefix$provider');
  }

  Future<void> saveApiKey(String provider, String key) async {
    await _storage.write(key: '$_apiKeyPrefix$provider', value: key);
  }

  Future<String?> getApiKey(String provider) async {
    return await _storage.read(key: '$_apiKeyPrefix$provider');
  }

  Future<void> deleteApiKey(String provider) async {
    await _storage.delete(key: '$_apiKeyPrefix$provider');
  }

  Future<void> deleteAiModel(String provider) async {
    await _storage.delete(key: '$_aiModelPrefix$provider');
  }

  // --- Multiple API Keys Management ---
  static const String _apiKeysListPrefix = 'api_keys_list_';
  static const String _activeKeyIdPrefix = 'active_key_id_';

  Future<void> saveSavedApiKeysJson(String provider, String jsonStr) async {
    await _storage.write(key: '$_apiKeysListPrefix$provider', value: jsonStr);
  }

  Future<String?> getSavedApiKeysJson(String provider) async {
    return await _storage.read(key: '$_apiKeysListPrefix$provider');
  }

  Future<void> deleteSavedApiKeysJson(String provider) async {
    await _storage.delete(key: '$_apiKeysListPrefix$provider');
  }

  Future<void> saveActiveKeyId(String provider, String keyId) async {
    await _storage.write(key: '$_activeKeyIdPrefix$provider', value: keyId);
  }

  Future<String?> getActiveKeyId(String provider) async {
    return await _storage.read(key: '$_activeKeyIdPrefix$provider');
  }

  Future<void> deleteActiveKeyId(String provider) async {
    await _storage.delete(key: '$_activeKeyIdPrefix$provider');
  }

  static const String _accountSortByPrefix = 'account_sort_by_';

  Future<void> saveAccountSortBy(String userId, String sortBy) async {
    await _storage.write(key: '$_accountSortByPrefix$userId', value: sortBy);
  }

  Future<String?> getAccountSortBy(String userId) async {
    return await _storage.read(key: '$_accountSortByPrefix$userId');
  }

  static const String _backupScheduleKey = 'backup_schedule';
  static const String _backupWifiOnlyKey = 'backup_wifi_only';
  static const String _backupChargingOnlyKey = 'backup_charging_only';
  static const String _lastLocalBackupDateKey = 'last_local_backup_date';
  static const String _lastCloudBackupDateKey = 'last_cloud_backup_date';
  static const String _lastLocalBackupSizeKey = 'last_local_backup_size';
  static const String _lastCloudBackupSizeKey = 'last_cloud_backup_size';
  static const String _googleDriveBackupEnabledKey = 'google_drive_backup_enabled';

  Future<void> saveBackupSchedule(String schedule) async {
    await _storage.write(key: _backupScheduleKey, value: schedule);
  }

  Future<String?> getBackupSchedule() async {
    return await _storage.read(key: _backupScheduleKey);
  }

  Future<void> saveBackupWifiOnly(bool value) async {
    await _storage.write(key: _backupWifiOnlyKey, value: value.toString());
  }

  Future<bool?> getBackupWifiOnly() async {
    final val = await _storage.read(key: _backupWifiOnlyKey);
    if (val == null) return null;
    return val == 'true';
  }

  Future<void> saveBackupChargingOnly(bool value) async {
    await _storage.write(key: _backupChargingOnlyKey, value: value.toString());
  }

  Future<bool?> getBackupChargingOnly() async {
    final val = await _storage.read(key: _backupChargingOnlyKey);
    if (val == null) return null;
    return val == 'true';
  }

  Future<void> saveLastLocalBackupDate(String date) async {
    await _storage.write(key: _lastLocalBackupDateKey, value: date);
  }

  Future<String?> getLastLocalBackupDate() async {
    return await _storage.read(key: _lastLocalBackupDateKey);
  }

  Future<void> saveLastCloudBackupDate(String date, {String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? '${_lastCloudBackupDateKey}_$googleAccount'
        : _lastCloudBackupDateKey;
    await _storage.write(key: key, value: date);
  }

  Future<String?> getLastCloudBackupDate({String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? '${_lastCloudBackupDateKey}_$googleAccount'
        : _lastCloudBackupDateKey;
    return await _storage.read(key: key);
  }

  static const String _lastLocalPlaintextDbSizeKey = 'last_local_plaintext_db_size';

  Future<void> saveLastLocalPlaintextDbSize(int size) async {
    await _storage.write(key: _lastLocalPlaintextDbSizeKey, value: size.toString());
  }

  Future<int?> getLastLocalPlaintextDbSize() async {
    final val = await _storage.read(key: _lastLocalPlaintextDbSizeKey);
    if (val == null) return null;
    return int.tryParse(val);
  }

  Future<void> saveLastLocalBackupSize(int size) async {
    await _storage.write(key: _lastLocalBackupSizeKey, value: size.toString());
  }

  Future<int?> getLastLocalBackupSize() async {
    final val = await _storage.read(key: _lastLocalBackupSizeKey);
    if (val == null) return null;
    return int.tryParse(val);
  }

  Future<void> saveLastCloudBackupSize(int size, {String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? '${_lastCloudBackupSizeKey}_$googleAccount'
        : _lastCloudBackupSizeKey;
    await _storage.write(key: key, value: size.toString());
  }

  Future<int?> getLastCloudBackupSize({String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? '${_lastCloudBackupSizeKey}_$googleAccount'
        : _lastCloudBackupSizeKey;
    final val = await _storage.read(key: key);
    if (val == null) return null;
    return int.tryParse(val);
  }

  Future<void> saveGoogleDriveBackupEnabled(bool value) async {
    await _storage.write(key: _googleDriveBackupEnabledKey, value: value.toString());
  }

  Future<bool?> getGoogleDriveBackupEnabled() async {
    final val = await _storage.read(key: _googleDriveBackupEnabledKey);
    if (val == null) return null;
    return val == 'true';
  }

  Future<void> saveLastBackupStatus(String status, {String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_backup_status_$googleAccount'
        : 'last_backup_status';
    await _storage.write(key: key, value: status);
  }

  Future<String?> getLastBackupStatus({String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_backup_status_$googleAccount'
        : 'last_backup_status';
    return await _storage.read(key: key);
  }

  Future<void> saveLastRestoreStatus(String status, {String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_restore_status_$googleAccount'
        : 'last_restore_status';
    await _storage.write(key: key, value: status);
  }

  Future<String?> getLastRestoreStatus({String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_restore_status_$googleAccount'
        : 'last_restore_status';
    return await _storage.read(key: key);
  }

  Future<void> saveLastBackupError(String? errorJson, {String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_backup_error_$googleAccount'
        : 'last_backup_error';
    if (errorJson == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: errorJson);
    }
  }

  Future<String?> getLastBackupError({String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_backup_error_$googleAccount'
        : 'last_backup_error';
    return await _storage.read(key: key);
  }

  Future<void> saveLastRestoreError(String? errorJson, {String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_restore_error_$googleAccount'
        : 'last_restore_error';
    if (errorJson == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: errorJson);
    }
  }

  Future<String?> getLastRestoreError({String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_restore_error_$googleAccount'
        : 'last_restore_error';
    return await _storage.read(key: key);
  }

  Future<void> saveLastVerifiedDriveFileId(String fileId, {String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_verified_drive_file_id_$googleAccount'
        : 'last_verified_drive_file_id';
    await _storage.write(key: key, value: fileId);
  }

  Future<String?> getLastVerifiedDriveFileId({String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_verified_drive_file_id_$googleAccount'
        : 'last_verified_drive_file_id';
    return await _storage.read(key: key);
  }

  Future<void> saveLastCloudBackupSha256(String sha, {String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_cloud_backup_sha256_$googleAccount'
        : 'last_cloud_backup_sha256';
    await _storage.write(key: key, value: sha);
  }

  Future<String?> getLastCloudBackupSha256({String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_cloud_backup_sha256_$googleAccount'
        : 'last_cloud_backup_sha256';
    return await _storage.read(key: key);
  }

  Future<void> saveLastCloudBackupId(String backupId, {String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_cloud_backup_id_$googleAccount'
        : 'last_cloud_backup_id';
    await _storage.write(key: key, value: backupId);
  }

  Future<String?> getLastCloudBackupId({String? googleAccount}) async {
    final key = googleAccount != null && googleAccount.isNotEmpty
        ? 'last_cloud_backup_id_$googleAccount'
        : 'last_cloud_backup_id';
    return await _storage.read(key: key);
  }

  static const String _lastRestoreDateKey = 'last_restore_date';
  static const String _lastSyncDurationKey = 'last_sync_duration';
  static const String _developerModeKey = 'developer_mode_enabled';

  Future<void> saveLastRestoreDate(String date) async {
    await _storage.write(key: _lastRestoreDateKey, value: date);
  }

  Future<String?> getLastRestoreDate() async {
    return await _storage.read(key: _lastRestoreDateKey);
  }

  Future<void> saveLastSyncDuration(int seconds) async {
    await _storage.write(key: _lastSyncDurationKey, value: seconds.toString());
  }

  Future<int?> getLastSyncDuration() async {
    final val = await _storage.read(key: _lastSyncDurationKey);
    if (val == null) return null;
    return int.tryParse(val);
  }

  Future<void> saveDeveloperModeEnabled(bool value) async {
    await _storage.write(key: _developerModeKey, value: value.toString());
  }

  Future<bool> getDeveloperModeEnabled() async {
    final val = await _storage.read(key: _developerModeKey);
    return val == 'true';
  }

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});


