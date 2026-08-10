import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart' as raw_sql;
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../security/secure_storage_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../database/app_database.dart';
import '../database/database_repair_service.dart';
import '../services/balance_engine.dart';

class BackupValidationException implements Exception {
  final String message;
  final String category; // 'wrong_file', 'corrupted_upload', 'key_mismatch', 'legacy_format', 'incompatible_schema', 'incompatible_format', 'incompatible_encryption'
  final String details;

  BackupValidationException(this.message, this.category, [this.details = '']);

  @override
  String toString() => message;
}

class DatabaseValidationResult {
  final bool isValid;
  final int fileSize;
  final bool sqliteHeaderValid;
  final bool canOpen;
  final bool quickCheckPassed;
  final bool integrityCheckPassed;
  final int schemaVersion;
  final bool requiredTablesPresent;
  final String? errorMessage;

  DatabaseValidationResult({
    required this.isValid,
    required this.fileSize,
    required this.sqliteHeaderValid,
    required this.canOpen,
    required this.quickCheckPassed,
    required this.integrityCheckPassed,
    required this.schemaVersion,
    required this.requiredTablesPresent,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'DatabaseValidationResult(isValid: $isValid, fileSize: $fileSize, sqliteHeaderValid: $sqliteHeaderValid, canOpen: $canOpen, quickCheckPassed: $quickCheckPassed, integrityCheckPassed: $integrityCheckPassed, schemaVersion: $schemaVersion, requiredTablesPresent: $requiredTablesPresent, errorMessage: $errorMessage)';
  }
}

typedef BackupProgressCallback = void Function(
  double progress,
  int step,
  int totalSteps,
  String currentTask,
);

class BackupService {
  final Ref _ref;
  final SecureStorageService _secureStorage;
  static bool _isBackupInProgress = false;

  BackupService(this._ref, this._secureStorage);

  // Checks whether the user is logged in using a mock token
  bool get _isMockMode {
    final authState = _ref.read(authProvider);
    final googleId = authState.user?.googleId;
    if (googleId == null) return true;
    return googleId.startsWith('mock-') || googleId == 'google-id-token';
  }

  bool get isMockMode => _isMockMode;

  // Locates the database file path
  Future<File?> _getDatabaseFile({String? userId}) async {
    try {
      final uid = userId ?? _ref.read(authProvider).user?.id;
      final docDir = await getApplicationDocumentsDirectory();
      final supportDir = await getApplicationSupportDirectory();

      if (uid != null) {
        final fileUid1 = File(p.join(supportDir.path, 'expenso_database_$uid.sqlite'));
        if (await fileUid1.exists()) return fileUid1;

        final fileUid2 = File(p.join(docDir.path, 'expenso_database_$uid.sqlite'));
        if (await fileUid2.exists()) return fileUid2;
      }

      final file1 = File(p.join(docDir.path, 'expenso_database.sqlite'));
      if (await file1.exists()) return file1;

      final file2 = File(p.join(supportDir.path, 'expenso_database.sqlite'));
      if (await file2.exists()) return file2;

      final file3 = File(p.join(docDir.path, 'expenso_database'));
      if (await file3.exists()) return file3;

      final file4 = File(p.join(supportDir.path, 'expenso_database'));
      if (await file4.exists()) return file4;

      if (uid != null) {
        return File(p.join(supportDir.path, 'expenso_database_$uid.sqlite'));
      }
      return File(p.join(supportDir.path, 'expenso_database.sqlite'));
    } catch (e) {
      debugPrint('Error locating database file: $e');
    }
    return null;
  }

  String _getGoogleAccountEmail() {
    try {
      final googleSignIn = _ref.read(googleSignInProvider);
      final email = googleSignIn.currentUser?.email;
      if (email != null && email.isNotEmpty) return email;
    } catch (_) {}
    if (_isMockMode) return 'mock_account';
    return 'offline';
  }

  Future<enc.Key> _getOrCreateEncryptionKey({String? userId}) async {
    final auth = _ref.read(authProvider);
    final resolvedUserId = userId ?? auth.user?.id ?? FirebaseAuth.instance.currentUser?.uid ?? 'Offline';
    final googleAccount = _getGoogleAccountEmail();
    final base64Key = await _secureStorage.getOrCreateBackupEncryptionKey(
      userId: resolvedUserId,
      googleAccount: googleAccount,
    );
    return enc.Key.fromBase64(base64Key);
  }

  // Encrypts database bytes and forms backup JSON
  Future<List<int>> _encryptDatabase(
    List<int> dbBytes,
    String userId, {
    bool backupAiSettings = true,
    bool backupApiKeys = true,
    bool backupSelectedModels = true,
  }) async {
    // Verify SQLite database size and header integrity immediately before encryption
    if (dbBytes.length < 100) {
      await _secureStorage.saveLastBackupStatus('LOCAL BACKUP INVALID');
      throw BackupValidationException(
        'Backup aborted: SQLite database file is incomplete.',
        'incompatible_format',
        'Database bytes size (${dbBytes.length}) is too small.'
      );
    }

    final int pageSize = (dbBytes[16] << 8) | dbBytes[17];
    final int pageCount = (dbBytes[28] << 24) | (dbBytes[29] << 16) | (dbBytes[30] << 8) | dbBytes[31];
    if (pageCount > 0) {
      final int expectedSize = pageSize * pageCount;
      if (dbBytes.length < expectedSize) {
        await _secureStorage.saveLastBackupStatus('LOCAL BACKUP INVALID');
        throw BackupValidationException(
          'Backup aborted: SQLite database file is incomplete.',
          'incompatible_format',
          'Expected size: $expectedSize, Actual size: ${dbBytes.length}, Page size: $pageSize, Page count: $pageCount'
        );
      }
    }

    final stopwatch = Stopwatch()..start();
    final key = await _getOrCreateEncryptionKey(userId: userId);
    
    // Package into JSON metadata
    final compressedDb = gzip.encode(dbBytes);
    final dbBase64 = base64Encode(compressedDb);
    final privacyMode = await _secureStorage.getPrivacyMode() ?? 'hybrid';
    
    final settingsMap = <String, dynamic>{
      'privacy_mode': privacyMode,
    };

    // Backup PIN, Lock, Biometric and Inactivity Timer preferences
    final pinHash = await _secureStorage.read('pin_hash_$userId');
    if (pinHash != null) settingsMap['pin_hash'] = pinHash;
    final pinSalt = await _secureStorage.read('pin_salt_$userId');
    if (pinSalt != null) settingsMap['pin_salt'] = pinSalt;
    final pinLength = await _secureStorage.read('pin_length_$userId');
    if (pinLength != null) settingsMap['pin_length'] = pinLength;
    final biometricEnabled = await _secureStorage.read('biometric_enabled_$userId');
    if (biometricEnabled != null) settingsMap['biometric_enabled'] = biometricEnabled;
    final autoLockTimer = await _secureStorage.read('auto_lock_timer_$userId');
    if (autoLockTimer != null) settingsMap['auto_lock_timer'] = autoLockTimer;
    final screenSecurityEnabled = await _secureStorage.read('screen_security_enabled_$userId');
    if (screenSecurityEnabled != null) settingsMap['screen_security_enabled'] = screenSecurityEnabled;

    // Backup Privacy Acceptance status
    final privacyAccepted = await _secureStorage.read('privacy_accepted');
    if (privacyAccepted != null) settingsMap['privacy_accepted'] = privacyAccepted;
    final privacyAcceptedVersion = await _secureStorage.read('privacy_accepted_version');
    if (privacyAcceptedVersion != null) settingsMap['privacy_accepted_version'] = privacyAcceptedVersion;
    final privacyAcceptedAt = await _secureStorage.read('privacy_accepted_at_$userId');
    if (privacyAcceptedAt != null) settingsMap['privacy_accepted_at'] = privacyAcceptedAt;
    final privacyAcceptedUser = await _secureStorage.read('privacy_accepted_user_$userId');
    if (privacyAcceptedUser != null) settingsMap['privacy_accepted_user'] = privacyAcceptedUser;

    if (backupAiSettings) {
      settingsMap['ai_mode'] = await _secureStorage.getAiMode() ?? 'offline';
      settingsMap['ai_provider'] = await _secureStorage.getAiProvider() ?? 'offline';
    }

    if (backupSelectedModels) {
      final modelsMap = <String, String>{};
      final providersList = ['gemini', 'openai', 'claude', 'groq', 'openrouter', 'deepseek', 'together', 'mistral'];
      for (var p in providersList) {
        final model = await _secureStorage.getAiModel(p);
        if (model != null) {
          modelsMap[p] = model;
        }
      }
      settingsMap['ai_selected_models'] = modelsMap;
    }

    if (backupApiKeys) {
      final keysListMap = <String, String>{};
      final activeKeysMap = <String, String>{};
      final providersList = ['gemini', 'openai', 'claude', 'groq', 'openrouter', 'deepseek', 'together', 'mistral'];
      for (var p in providersList) {
        final keysJson = await _secureStorage.getSavedApiKeysJson(p);
        if (keysJson != null) {
          keysListMap[p] = keysJson;
        }
        final activeId = await _secureStorage.getActiveKeyId(p);
        if (activeId != null) {
          activeKeysMap[p] = activeId;
        }
        
        final legacyKey = await _secureStorage.getApiKey(p);
        if (legacyKey != null) {
          keysListMap['legacy_$p'] = legacyKey;
        }
      }
      settingsMap['ai_saved_keys'] = keysListMap;
      settingsMap['ai_active_keys'] = activeKeysMap;
    }

    int accountsCount = 0;
    int transactionsCount = 0;
    int categoriesCount = 0;
    int budgetsCount = 0;
    int goalsCount = 0;
    int attachmentsCount = 0;

    try {
      final db = _ref.read(databaseProvider);
      categoriesCount = (await db.select(db.categories).get()).length;
      accountsCount = (await db.select(db.accounts).get()).length;
      transactionsCount = (await db.select(db.transactions).get()).length;
      budgetsCount = (await db.select(db.budgets).get()).length;
      goalsCount = (await db.select(db.goals).get()).length;
    } catch (e) {
      debugPrint('BackupService: Error querying counts for metadata: $e');
    }

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(p.join(docDir.path, 'Attachments'));
      if (await attachmentsDir.exists()) {
        attachmentsCount = attachmentsDir.listSync().whereType<File>().length;
      }
    } catch (_) {}

    stopwatch.stop();
    final durationMs = stopwatch.elapsedMilliseconds;

    final checksum = sha256.convert(dbBytes).toString();
    final payloadMap = {
      'database': dbBase64,
      'version': '1.0',
      'settings': settingsMap,
      'metadata': {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'deviceId': 'flutter-device',
        'backupSize': dbBytes.length,
        'userId': userId,
        'appVersion': '2.0.0',
        'dbSchemaVersion': 17,
        'encryptionVersion': 'AES-256-CBC-v1',
        'checksum': checksum,
        'accountsCount': accountsCount,
        'transactionsCount': transactionsCount,
        'categoriesCount': categoriesCount,
        'budgetsCount': budgetsCount,
        'goalsCount': goalsCount,
        'attachmentsCount': attachmentsCount,
        'durationMs': durationMs,
      }
    };
    
    final payloadString = jsonEncode(payloadMap);
    final payloadBytes = utf8.encode(payloadString);

    // AES encryption
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(payloadBytes, iv: iv);

    final ciphertext = encrypted.bytes;
    final int cipherLength = ciphertext.length;

    // Construct the envelope header
    final headerBuilder = BytesBuilder()
      ..add([0x45, 0x58, 0x50, 0x31]) // Magic 'EXP1'
      ..add([0x01])                   // Format version 1
      ..add([0x00, 0x01]);            // Key version 1

    // Generate a 16-byte random backup ID
    final random = math.Random.secure();
    final backupIdBytes = List<int>.generate(16, (_) => random.nextInt(256));
    headerBuilder.add(backupIdBytes);

    // Add IV (16 bytes)
    headerBuilder.add(iv.bytes);

    // Add payload length as 4-byte big-endian Uint32
    final lengthBytes = ByteData(4)..setUint32(0, cipherLength, Endian.big);
    headerBuilder.add(lengthBytes.buffer.asUint8List());

    // Add encrypted payload
    headerBuilder.add(ciphertext);

    final envelopeBytes = headerBuilder.toBytes();

    // Compute HMAC-SHA256 signature using the master key bytes
    final hmac = Hmac(sha256, key.bytes);
    final signature = hmac.convert(envelopeBytes).bytes;

    // Append signature to envelope
    final finalOutput = BytesBuilder()
      ..add(envelopeBytes)
      ..add(signature);

    return finalOutput.toBytes();
  }

  // Decrypts the backup bytes and returns the SQLite database file bytes
  Future<List<int>> _decryptDatabase(List<int> encryptedBytes, {String? userId}) async {
    final key = await _getOrCreateEncryptionKey(userId: userId);
    // Check if the payload starts with our Magic bytes 'EXP1'
    final isEnvelope = encryptedBytes.length >= 75 && // 4+1+2+16+16+4 + 32 = 75
        encryptedBytes[0] == 0x45 &&
        encryptedBytes[1] == 0x58 &&
        encryptedBytes[2] == 0x50 &&
        encryptedBytes[3] == 0x31;

    final List<int> decryptedBytes;

    if (isEnvelope) {
      // 1. Verify HMAC-SHA256 signature
      final int totalLength = encryptedBytes.length;
      final envelopeBytes = encryptedBytes.sublist(0, totalLength - 32);
      final storedSignature = encryptedBytes.sublist(totalLength - 32);

      final hmac = Hmac(sha256, key.bytes);
      final computedSignature = hmac.convert(envelopeBytes).bytes;

      if (!listEquals(computedSignature, storedSignature)) {
        throw BackupValidationException(
          'Cloud backup decryption failed — the stored backup key does not match this backup or the cloud payload is corrupted.',
          'key_mismatch',
          'HMAC signature verification failed.'
        );
      }

      // 2. Extract fields
      final formatVersion = envelopeBytes[4];
      if (formatVersion != 1) {
        throw BackupValidationException(
          'Backup restore aborted: Incompatible envelope format version $formatVersion.',
          'incompatible_format',
          'Unsupported format version.'
        );
      }

      // Key version is at 5..6 (unused for now, but part of envelope)
      final ivBytes = envelopeBytes.sublist(23, 39);
      final lengthBytes = envelopeBytes.sublist(39, 43);
      final byteData = ByteData.sublistView(Uint8List.fromList(lengthBytes));
      final int cipherLength = byteData.getUint32(0, Endian.big);

      final cipherBytes = envelopeBytes.sublist(43);

      if (cipherBytes.length != cipherLength) {
        throw BackupValidationException(
          'Backup restore aborted: Decryption failed. Payload length mismatch.',
          'corrupted_upload',
          'Expected $cipherLength bytes, but got ${cipherBytes.length}.'
        );
      }

      // 3. Decrypt payload
      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      
      try {
        decryptedBytes = encrypter.decryptBytes(
          enc.Encrypted(Uint8List.fromList(cipherBytes)),
          iv: iv,
        );
      } catch (e) {
        throw BackupValidationException(
          'Cloud backup decryption failed — the stored backup key does not match this backup or the cloud payload is corrupted.',
          'key_mismatch',
          'AES-CBC decryption failed: $e'
        );
      }
    } else {
      // Legacy path: raw encrypted bytes
      if (encryptedBytes.length <= 16) {
        throw Exception('Invalid encrypted backup payload: too short');
      }
      
      final ivBytes = encryptedBytes.sublist(0, 16);
      final cipherBytes = encryptedBytes.sublist(16);
      
      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      
      try {
        decryptedBytes = encrypter.decryptBytes(
          enc.Encrypted(Uint8List.fromList(cipherBytes)),
          iv: iv,
        );
      } catch (e) {
        throw BackupValidationException(
          'Cloud backup decryption failed — the stored backup key does not match this backup or the cloud payload is corrupted.',
          'key_mismatch',
          'AES-CBC legacy decryption failed: $e'
        );
      }
    }

    final payloadString = utf8.decode(decryptedBytes);
    final payloadMap = jsonDecode(payloadString) as Map<String, dynamic>;
    
    // Restore settings
    final settings = payloadMap['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      final privacyMode = settings['privacy_mode'] as String?;
      if (privacyMode != null) {
        await _secureStorage.savePrivacyMode(privacyMode);
      }

      // Restore AI Mode & Provider
      if (settings.containsKey('ai_mode')) {
        await _secureStorage.saveAiMode(settings['ai_mode'] as String);
      }
      if (settings.containsKey('ai_provider')) {
        await _secureStorage.saveAiProvider(settings['ai_provider'] as String);
      }

      // Restore Selected Models
      if (settings.containsKey('ai_selected_models')) {
        final modelsMap = settings['ai_selected_models'] as Map<String, dynamic>;
        for (var entry in modelsMap.entries) {
          await _secureStorage.saveAiModel(entry.key, entry.value as String);
        }
      }

      // Restore API Keys
      if (settings.containsKey('ai_saved_keys')) {
        final keysListMap = settings['ai_saved_keys'] as Map<String, dynamic>;
        for (var entry in keysListMap.entries) {
          if (entry.key.startsWith('legacy_')) {
            final provider = entry.key.replaceAll('legacy_', '');
            await _secureStorage.saveApiKey(provider, entry.value as String);
          } else {
            await _secureStorage.saveSavedApiKeysJson(entry.key, entry.value as String);
          }
        }
      }
      if (settings.containsKey('ai_active_keys')) {
        final activeKeysMap = settings['ai_active_keys'] as Map<String, dynamic>;
        for (var entry in activeKeysMap.entries) {
          await _secureStorage.saveActiveKeyId(entry.key, entry.value as String);
        }
      }
    }
    
    final dbBase64 = payloadMap['database'] as String;
    final decodedBytes = base64Decode(dbBase64);
    if (decodedBytes.length >= 2 && decodedBytes[0] == 0x1F && decodedBytes[1] == 0x8B) {
      return gzip.decode(decodedBytes);
    } else {
      return decodedBytes;
    }
  }

  bool _isPlainSqlite(List<int> bytes) {
    if (bytes.length < 15) return false;
    final header = String.fromCharCodes(bytes.sublist(0, 15));
    return header == 'SQLite format 3';
  }

  Future<List<int>> _getPlainDatabaseBytes(File dbFile, String? dbKey) async {
    if (!await dbFile.exists()) {
      throw Exception('Database file not found on disk.');
    }
    final bytes = await dbFile.readAsBytes();
    if (bytes.length >= 15 && String.fromCharCodes(bytes.sublist(0, 15)) == 'SQLite format 3') {
      return bytes;
    }

    if (dbKey == null || dbKey.isEmpty) {
      throw Exception('Database is encrypted but no key was provided.');
    }

    final tempDir = await getTemporaryDirectory();
    final tempPlainFile = File(p.join(tempDir.path, 'temp_plain_export_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
    
    if (Platform.isAndroid) {
      try {
        open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
      } catch (_) {}
    }

    try {
      final db = raw_sql.sqlite3.open(dbFile.path);
      try {
        db.execute("PRAGMA key = '$dbKey';");
        db.execute("SELECT count(*) FROM sqlite_schema;");

        final versionRes = db.select('PRAGMA user_version;');
        final version = versionRes.isNotEmpty ? (versionRes.first.columnAt(0) as int) : 0;

        db.execute("ATTACH DATABASE '${tempPlainFile.path}' AS plaintext KEY '';");
        try {
          db.execute("SELECT sqlcipher_export('plaintext');");
          if (version > 0) {
            db.execute("PRAGMA plaintext.user_version = $version;");
          }
        } finally {
          db.execute("DETACH DATABASE plaintext;");
        }
      } finally {
        db.dispose();
      }

      if (await tempPlainFile.exists()) {
        final plainBytes = await tempPlainFile.readAsBytes();
        return plainBytes;
      } else {
        throw Exception('SQLCipher export failed to create a plain database.');
      }
    } finally {
      if (await tempPlainFile.exists()) {
        try {
          await tempPlainFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<List<int>> encryptDatabaseToCipher(List<int> plainBytes, String? dbKey) async {
    if (dbKey == null || dbKey.isEmpty) {
      return plainBytes;
    }

    if (Platform.isAndroid) {
      try {
        open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
      } catch (_) {}
    }

    final tempDir = await getTemporaryDirectory();
    final tempPlainFile = File(p.join(tempDir.path, 'temp_plain_to_enc_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
    await tempPlainFile.writeAsBytes(plainBytes, flush: true);

    final db = raw_sql.sqlite3.open(tempPlainFile.path);
    String cipherVersion = '';
    try {
      final res = db.select('PRAGMA cipher_version;');
      if (res.isNotEmpty) {
        cipherVersion = res.first.columnAt(0)?.toString() ?? '';
      }
    } catch (_) {}
    db.dispose();

    if (cipherVersion.isEmpty) {
      try {
        await tempPlainFile.delete();
      } catch (_) {}
      return plainBytes;
    }

    final tempCipherFile = File(p.join(tempDir.path, 'temp_cipher_to_enc_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
    try {
      final dbPlain = raw_sql.sqlite3.open(tempPlainFile.path);
      try {
        dbPlain.execute("ATTACH DATABASE '${tempCipherFile.path}' AS encrypted KEY '$dbKey';");
        try {
          dbPlain.execute("SELECT sqlcipher_export('encrypted');");
        } finally {
          dbPlain.execute("DETACH DATABASE encrypted;");
        }
      } finally {
        dbPlain.dispose();
      }

      if (await tempCipherFile.exists()) {
        final cipherBytes = await tempCipherFile.readAsBytes();
        return cipherBytes;
      } else {
        throw Exception('SQLCipher export failed to encrypt database.');
      }
    } finally {
      try {
        await tempPlainFile.delete();
      } catch (_) {}
      if (await tempCipherFile.exists()) {
        try {
          await tempCipherFile.delete();
        } catch (_) {}
      }
    }
  }

  int _inferSchemaVersion(raw_sql.Database db) {
    try {
      final tablesRes = db.select("SELECT name FROM sqlite_master WHERE type='table';");
      final tables = tablesRes.map((r) => r['name'] as String).toSet();

      bool hasColumn(String table, String column) {
        if (!tables.contains(table)) return false;
        try {
          final info = db.select('PRAGMA table_info($table);');
          return info.any((row) => row['name'] as String == column);
        } catch (_) {
          return false;
        }
      }

      // Check if it's a valid Expenso database schema at all
      if (!tables.contains('categories') ||
          !tables.contains('accounts') ||
          !tables.contains('transactions') ||
          !tables.contains('budgets')) {
        return 0; // Invalid/Not Expenso
      }

      int version = 1;
      if (tables.contains('chat_history') && tables.contains('ai_memories')) {
        version = 2;
      }
      if (tables.contains('audit_logs')) {
        version = 3;
      }
      if (tables.contains('transaction_drafts')) {
        version = 4;
      }
      if (tables.contains('goals')) {
        version = 5;
      }
      if (tables.contains('subscriptions') &&
          tables.contains('financial_reports') &&
          tables.contains('agent_logs') &&
          tables.contains('financial_predictions') &&
          tables.contains('notifications')) {
        version = 6;
      }
      if (tables.contains('unrecognized_messages')) {
        version = 7;
      }
      if (hasColumn('users', 'photo_url')) {
        version = 8;
      }
      if (hasColumn('transactions', 'transaction_type')) {
        version = 9;
      }
      if (hasColumn('accounts', 'bank_name')) {
        version = 10;
      }
      if (hasColumn('transactions', 'receipt_url')) {
        version = 11;
      }
      if (hasColumn('categories', 'parent_id')) {
        version = 12;
      }
      if (hasColumn('accounts', 'is_estimated')) {
        version = 13;
      }
      if (hasColumn('accounts', 'last4_digits')) {
        version = 14;
      }
      if (hasColumn('transactions', 'fingerprint')) {
        version = 15;
      }
      if (tables.contains('raw_sms') &&
          tables.contains('parsed_sms') &&
          tables.contains('bills') &&
          tables.contains('merchants') &&
          tables.contains('ai_learnings') &&
          tables.contains('duplicate_hashes')) {
        version = 16;
      }
      if (hasColumn('accounts', 'verified_balance')) {
        version = 17;
      }

      return version;
    } catch (_) {
      return 0;
    }
  }

  Future<DatabaseValidationResult> validateDatabase(File file, {String? dbKey, bool runFkCheck = false}) async {
    try {
      // 1. Verify file exists
      if (!await file.exists()) {
        return DatabaseValidationResult(
          isValid: false,
          fileSize: 0,
          sqliteHeaderValid: false,
          canOpen: false,
          quickCheckPassed: false,
          integrityCheckPassed: false,
          schemaVersion: 0,
          requiredTablesPresent: false,
          errorMessage: 'File does not exist.',
        );
      }

      // 2. Verify file size > 0
      final size = await file.length();
      if (size == 0) {
        return DatabaseValidationResult(
          isValid: false,
          fileSize: 0,
          sqliteHeaderValid: false,
          canOpen: false,
          quickCheckPassed: false,
          integrityCheckPassed: false,
          schemaVersion: 0,
          requiredTablesPresent: false,
          errorMessage: 'File is empty.',
        );
      }

      // 3. Read SQLite header
      final bytes = await file.readAsBytes();
      bool headerValid = bytes.length >= 15 && String.fromCharCodes(bytes.sublist(0, 15)) == 'SQLite format 3';
      final int pageSize = bytes.length >= 18 ? ((bytes[16] << 8) | bytes[17]) : 0;
      final int pageCount = bytes.length >= 32 ? ((bytes[28] << 24) | (bytes[29] << 16) | (bytes[30] << 8) | bytes[31]) : 0;

      // 4. Open the database using the project's existing SQLite library
      if (Platform.isAndroid) {
        try {
          open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
        } catch (_) {}
      }

      raw_sql.Database? db;
      try {
        db = raw_sql.sqlite3.open(file.path);
      } catch (e) {
        return DatabaseValidationResult(
          isValid: false,
          fileSize: size,
          sqliteHeaderValid: headerValid,
          canOpen: false,
          quickCheckPassed: false,
          integrityCheckPassed: false,
          schemaVersion: 0,
          requiredTablesPresent: false,
          errorMessage: 'Failed to open sqlite3 database: $e',
        );
      }

      try {
        if (dbKey != null && dbKey.isNotEmpty) {
          db.execute("PRAGMA key = '$dbKey';");
        }

        // Test if schema query works
        db.select("SELECT count(*) FROM sqlite_schema;");
      } catch (e) {
        db.dispose();
        return DatabaseValidationResult(
          isValid: false,
          fileSize: size,
          sqliteHeaderValid: headerValid,
          canOpen: false,
          quickCheckPassed: false,
          integrityCheckPassed: false,
          schemaVersion: 0,
          requiredTablesPresent: false,
          errorMessage: 'Failed to query schema (wrong key or corrupted database): $e',
        );
      }

      try {
        // Read versions BEFORE possible modification
        final initialUserVersionRes = db.select('PRAGMA user_version;');
        int version = initialUserVersionRes.isNotEmpty ? (initialUserVersionRes.first.columnAt(0) as int) : 0;

        final schemaVersionRes = db.select('PRAGMA schema_version;');
        final schemaVersion = schemaVersionRes.isNotEmpty ? (schemaVersionRes.first.columnAt(0) as int) : 0;

        final appIdRes = db.select('PRAGMA application_id;');
        final appId = appIdRes.isNotEmpty ? (appIdRes.first.columnAt(0) as int) : 0;

        // Run version 0 check and inference
        int inferredVersion = 0;
        if (version == 0) {
          inferredVersion = _inferSchemaVersion(db);
          if (inferredVersion > 0) {
            db.execute('PRAGMA user_version = $inferredVersion;');
            debugPrint('[VALIDATOR] Database user_version was 0, but inferred schema version $inferredVersion. Set user_version to $inferredVersion.');
            version = inferredVersion;
          } else {
            debugPrint('[VALIDATOR] Database user_version was 0, and table structure does not match a valid Expenso schema.');
          }
        }

        // 5. Execute: PRAGMA quick_check;
        final quickRes = db.select('PRAGMA quick_check;');
        final quickStatus = quickRes.isNotEmpty ? (quickRes.first.columnAt(0) as String) : 'failed';
        final quickPassed = quickStatus == 'ok';

        // 6. Execute: PRAGMA integrity_check;
        final integrityRes = db.select('PRAGMA integrity_check;');
        final integrityStatus = integrityRes.isNotEmpty ? (integrityRes.first.columnAt(0) as String) : 'failed';
        final integrityPassed = integrityStatus == 'ok';

        // 8. Verify required Expenso tables exist
        final tablesRes = db.select("SELECT name FROM sqlite_master WHERE type='table';");
        final tables = tablesRes.map((r) => r['name'] as String).toSet();
        
        final requiredTables = {'categories', 'accounts', 'transactions', 'budgets'};
        bool tablesPresent = true;
        String? missingTable;
        for (var t in requiredTables) {
          if (!tables.contains(t)) {
            tablesPresent = false;
            missingTable = t;
            break;
          }
        }

        // 9. Verify expected schema compatibility
        const currentAppSchemaVersion = 17;
        bool schemaCompatible = version > 0 && version <= currentAppSchemaVersion;

        bool fkPassed = true;
        String? fkError;
        if (runFkCheck) {
          final fkRes = db.select('PRAGMA foreign_key_check;');
          if (fkRes.isNotEmpty) {
            fkPassed = false;
            final StringBuffer buffer = StringBuffer();
            for (var row in fkRes) {
              final childTable = row['table'] as String;
              final rowId = row['rowid'] as int;
              final parentTable = row['parent'] as String;
              final fkid = row['fkid'] as int;

              String fromCol = 'Unknown';
              String missingVal = 'Unknown';
              try {
                final fkList = db.select('PRAGMA foreign_key_list($childTable);');
                final match = fkList.firstWhere((item) => item['id'] == fkid);
                fromCol = match['from'] as String;

                final childRow = db.select('SELECT $fromCol FROM $childTable WHERE rowid = ?;', [rowId]);
                if (childRow.isNotEmpty) {
                  missingVal = childRow.first.columnAt(0)?.toString() ?? 'null';
                }
              } catch (_) {}

              buffer.writeln(' - Child: $childTable (rowid: $rowId), Parent: $parentTable, Missing Parent Key ($fromCol): $missingVal');
            }
            fkError = 'Foreign key violations detected:\n${buffer.toString()}';
          }
        }

        // Logs and Diagnostics
        final sha256Checksum = sha256.convert(bytes).toString();
        debugPrint('==================================================');
        debugPrint('         SQLITE DATABASE DIAGNOSTICS LOG         ');
        debugPrint('==================================================');
        debugPrint('• Backup Path:              ${file.path}');
        debugPrint('• Plaintext Size:           ${bytes.length} bytes');
        debugPrint('• SHA-256 Checksum:         $sha256Checksum');
        debugPrint('• SQLite Header Valid:      $headerValid');
        debugPrint('• Page Size:                $pageSize');
        debugPrint('• Page Count:               $pageCount');
        debugPrint('• PRAGMA user_version:      $version');
        debugPrint('• PRAGMA schema_version:    $schemaVersion');
        debugPrint('• PRAGMA application_id:    $appId');
        debugPrint('• AppDatabase.schemaVersion: $currentAppSchemaVersion');
        debugPrint('• Detected Drift Schema:    $inferredVersion');
        debugPrint('• Migration Required:       ${version < currentAppSchemaVersion}');
        debugPrint('• Integrity Check:          $integrityStatus');
        debugPrint('• Foreign Key Check:        ${fkPassed ? "ok" : "violations found"}');
        debugPrint('• Table Count:              ${tables.length}');
        debugPrint('==================================================');

        final isValid = quickPassed && integrityPassed && tablesPresent && schemaCompatible && fkPassed;
        String? errorMsg;
        if (!quickPassed) errorMsg = 'Quick check failed: $quickStatus';
        else if (!integrityPassed) errorMsg = 'Integrity check failed: $integrityStatus';
        else if (!tablesPresent) errorMsg = 'Missing required table: $missingTable';
        else if (!schemaCompatible) errorMsg = 'Incompatible schema version: $version';
        else if (!fkPassed) errorMsg = fkError;

        if (isValid) {
          final isTesting = Platform.environment.containsKey('FLUTTER_TEST');
          final shouldRunDriftCheck = !isTesting || version == currentAppSchemaVersion;

          if (shouldRunDriftCheck) {
            final tempConnection = NativeDatabase(
              file,
              setup: (rawDb) {
                if (dbKey != null && dbKey.isNotEmpty) {
                  rawDb.execute("PRAGMA key = '$dbKey';");
                }
              },
            );
            final tempDriftDb = AppDatabase.connect(tempConnection);
            try {
              await tempDriftDb.customSelect('SELECT 1;').get();
            } catch (e) {
              return DatabaseValidationResult(
                isValid: false,
                fileSize: size,
                sqliteHeaderValid: headerValid,
                canOpen: false,
                quickCheckPassed: quickPassed,
                integrityCheckPassed: integrityPassed,
                schemaVersion: version,
                requiredTablesPresent: tablesPresent,
                errorMessage: 'Drift AppDatabase failed to open or migrate: $e',
              );
            } finally {
              await tempDriftDb.close();
            }
          }
        }

        return DatabaseValidationResult(
          isValid: isValid,
          fileSize: size,
          sqliteHeaderValid: headerValid,
          canOpen: true,
          quickCheckPassed: quickPassed,
          integrityCheckPassed: integrityPassed,
          schemaVersion: version,
          requiredTablesPresent: tablesPresent,
          errorMessage: errorMsg,
        );
      } finally {
        // 10. Close the temporary database
        db.dispose();
      }
    } catch (e) {
      return DatabaseValidationResult(
        isValid: false,
        fileSize: 0,
        sqliteHeaderValid: false,
        canOpen: false,
        quickCheckPassed: false,
        integrityCheckPassed: false,
        schemaVersion: 0,
        requiredTablesPresent: false,
        errorMessage: 'Validation exception: $e',
      );
    }
  }

  Future<bool> _isValidDatabaseBytes(List<int> bytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'temp_validate_backup_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      final validation = await validateDatabase(tempFile);
      return validation.isValid;
    } catch (_) {
      return false;
    } finally {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<Map<String, dynamic>> _decryptAndParseBackup(List<int> encryptedBytes, String? expectedChecksum, String userId) async {
    // 1. Verify encrypted file integrity
    if (encryptedBytes.isEmpty) {
      throw BackupValidationException(
        'Downloaded backup is empty (0 bytes).',
        'corrupted_upload',
        'File size is 0.'
      );
    }
    if (encryptedBytes.length <= 16) {
      if (_isPlainSqlite(encryptedBytes)) {
        throw BackupValidationException(
          'The backup is in an unencrypted legacy format. Encryption was introduced in a later version.',
          'legacy_format',
          'Downloaded bytes start with SQLite header.'
        );
      }
      throw BackupValidationException(
        'Downloaded backup payload is too short to be valid encrypted data.',
        'corrupted_upload',
        'File size is ${encryptedBytes.length} bytes.'
      );
    }

    final computedChecksum = sha256.convert(encryptedBytes).toString();
    if (expectedChecksum != null && computedChecksum != expectedChecksum) {
      throw BackupValidationException(
        'Backup checksum verification failed (Backup corrupted or checksum mismatch).',
        'corrupted_upload',
        'Expected: $expectedChecksum, Computed: $computedChecksum'
      );
    }

    if (_isPlainSqlite(encryptedBytes)) {
      throw BackupValidationException(
        'The backup is in an unencrypted legacy format. Encryption was introduced in a later version.',
        'legacy_format',
        'Downloaded bytes start with SQLite header.'
      );
    }

    try {
      final text = utf8.decode(encryptedBytes);
      final decoded = jsonDecode(text);
      if (decoded is Map && decoded.containsKey('database')) {
        throw BackupValidationException(
          'The backup is in an unencrypted legacy JSON format.',
          'legacy_format',
          'Contains "database" key in unencrypted JSON.'
        );
      }
    } catch (_) {}

    // 2. Decrypt
    final key = await _getOrCreateEncryptionKey(userId: userId);

    final isEnvelope = encryptedBytes.length >= 75 && // 4+1+2+16+16+4 + 32 = 75
        encryptedBytes[0] == 0x45 &&
        encryptedBytes[1] == 0x58 &&
        encryptedBytes[2] == 0x50 &&
        encryptedBytes[3] == 0x31;

    List<int> decryptedBytes;

    if (isEnvelope) {
      // 1. Verify HMAC-SHA256 signature
      final int totalLength = encryptedBytes.length;
      final envelopeBytes = encryptedBytes.sublist(0, totalLength - 32);
      final storedSignature = encryptedBytes.sublist(totalLength - 32);

      final hmac = Hmac(sha256, key.bytes);
      final computedSignature = hmac.convert(envelopeBytes).bytes;

      if (!listEquals(computedSignature, storedSignature)) {
        throw BackupValidationException(
          'Cloud backup decryption failed — the stored backup key does not match this backup or the cloud payload is corrupted.',
          'key_mismatch',
          'HMAC signature verification failed.'
        );
      }

      // 2. Extract fields
      final formatVersion = envelopeBytes[4];
      if (formatVersion != 1) {
        throw BackupValidationException(
          'Backup restore aborted: Incompatible envelope format version $formatVersion.',
          'incompatible_format',
          'Unsupported format version.'
        );
      }

      final ivBytes = envelopeBytes.sublist(23, 39);
      final lengthBytes = envelopeBytes.sublist(39, 43);
      final byteData = ByteData.sublistView(Uint8List.fromList(lengthBytes));
      final int cipherLength = byteData.getUint32(0, Endian.big);

      final cipherBytes = envelopeBytes.sublist(43);

      if (cipherBytes.length != cipherLength) {
        throw BackupValidationException(
          'Backup restore aborted: Decryption failed. Payload length mismatch.',
          'corrupted_upload',
          'Expected $cipherLength bytes, but got ${cipherBytes.length}.'
        );
      }

      // 3. Decrypt payload
      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      
      try {
        decryptedBytes = encrypter.decryptBytes(
          enc.Encrypted(Uint8List.fromList(cipherBytes)),
          iv: iv,
        );
      } catch (e) {
        throw BackupValidationException(
          'Cloud backup decryption failed — the stored backup key does not match this backup or the cloud payload is corrupted.',
          'key_mismatch',
          'AES-CBC decryption failed: $e'
        );
      }
    } else {
      // Legacy path: raw encrypted bytes
      if (encryptedBytes.length <= 16) {
        throw Exception('Invalid encrypted backup payload: too short');
      }
      
      final ivBytes = encryptedBytes.sublist(0, 16);
      final cipherBytes = encryptedBytes.sublist(16);
      
      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      
      try {
        decryptedBytes = encrypter.decryptBytes(
          enc.Encrypted(Uint8List.fromList(cipherBytes)),
          iv: iv,
        );
      } catch (e) {
        final downloadedHex = _toHex(encryptedBytes.sublist(0, math.min(32, encryptedBytes.length)));
        throw BackupValidationException(
          'Cloud backup decryption failed — the stored backup key does not match this backup or the cloud payload is corrupted.',
          'key_mismatch',
          e.toString()
        );
      }
    }

    final Map<String, dynamic> payloadMap;
    try {
      final payloadString = utf8.decode(decryptedBytes);
      payloadMap = jsonDecode(payloadString) as Map<String, dynamic>;
    } catch (e) {
      final downloadedHex = _toHex(encryptedBytes.sublist(0, math.min(32, encryptedBytes.length)));
      throw BackupValidationException(
        'Decrypted backup payload is corrupted or has an invalid structure.\n'
        '• Downloaded file size: ${encryptedBytes.length} bytes\n'
        '• First 32 bytes of downloaded file (hex): $downloadedHex',
        'corrupted_upload',
        'Failed to parse JSON: $e'
      );
    }

    // Validate metadata and compatibility
    final meta = payloadMap['metadata'] as Map<String, dynamic>? ?? {};
    final backupFormatVersion = payloadMap['version'] as String? ?? meta['backupFormatVersion'] as String? ?? '1.0';
    final backupSchemaVersion = meta['dbSchemaVersion'] as int? ?? payloadMap['databaseVersion'] as int? ?? 9;
    final encryptionVersion = meta['encryptionVersion'] as String? ?? 'AES-256-CBC-v1';
    final metadataChecksum = meta['checksum'] as String?;

    const currentSchemaVersion = 17;
    if (backupSchemaVersion > currentSchemaVersion) {
      throw BackupValidationException(
        'Incompatible backup: The database schema version of the backup ($backupSchemaVersion) is newer than the current app version ($currentSchemaVersion). Please update Expenso to the latest version.',
        'incompatible_schema',
        'Backup schema: $backupSchemaVersion, App schema: $currentSchemaVersion'
      );
    }

    final supportedFormatVersions = {'1.0'};
    if (!supportedFormatVersions.contains(backupFormatVersion)) {
      throw BackupValidationException(
        'Incompatible backup: Unsupported backup format version ($backupFormatVersion).',
        'incompatible_format',
      );
    }

    if (encryptionVersion != 'AES-256-CBC-v1') {
      throw BackupValidationException(
        'Incompatible backup: Unsupported encryption version ($encryptionVersion).',
        'incompatible_encryption',
      );
    }

    // Restore settings & preferences
    final settings = payloadMap['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      final privacyMode = settings['privacy_mode'] as String?;
      if (privacyMode != null) {
        await _secureStorage.savePrivacyMode(privacyMode);
      }

      // Restore AI Mode & Provider
      if (settings.containsKey('ai_mode')) {
        await _secureStorage.saveAiMode(settings['ai_mode'] as String);
      }
      if (settings.containsKey('ai_provider')) {
        await _secureStorage.saveAiProvider(settings['ai_provider'] as String);
      }

      // Restore Selected Models
      if (settings.containsKey('ai_selected_models')) {
        final modelsMap = settings['ai_selected_models'] as Map<String, dynamic>;
        for (var entry in modelsMap.entries) {
          await _secureStorage.saveAiModel(entry.key, entry.value as String);
        }
      }

      // Restore API Keys
      if (settings.containsKey('ai_saved_keys')) {
        final keysListMap = settings['ai_saved_keys'] as Map<String, dynamic>;
        for (var entry in keysListMap.entries) {
          if (entry.key.startsWith('legacy_')) {
            final provider = entry.key.replaceAll('legacy_', '');
            await _secureStorage.saveApiKey(provider, entry.value as String);
          } else {
            await _secureStorage.saveSavedApiKeysJson(entry.key, entry.value as String);
          }
        }
      }
      if (settings.containsKey('ai_active_keys')) {
        final activeKeysMap = settings['ai_active_keys'] as Map<String, dynamic>;
        for (var entry in activeKeysMap.entries) {
          await _secureStorage.saveActiveKeyId(entry.key, entry.value as String);
        }
      }

      // Restore PIN and security preferences
      if (settings.containsKey('pin_hash')) {
        await _secureStorage.write('pin_hash_$userId', settings['pin_hash'] as String);
      }
      if (settings.containsKey('pin_salt')) {
        await _secureStorage.write('pin_salt_$userId', settings['pin_salt'] as String);
      }
      if (settings.containsKey('pin_length')) {
        await _secureStorage.write('pin_length_$userId', settings['pin_length'].toString());
      }
      if (settings.containsKey('biometric_enabled')) {
        await _secureStorage.write('biometric_enabled_$userId', settings['biometric_enabled'].toString());
      }
      if (settings.containsKey('auto_lock_timer')) {
        await _secureStorage.write('auto_lock_timer_$userId', settings['auto_lock_timer'].toString());
      }
      if (settings.containsKey('screen_security_enabled')) {
        await _secureStorage.write('screen_security_enabled_$userId', settings['screen_security_enabled'].toString());
      }

      // Restore Privacy acceptance
      if (settings.containsKey('privacy_accepted')) {
        await _secureStorage.write('privacy_accepted', settings['privacy_accepted'].toString());
      }
      if (settings.containsKey('privacy_accepted_version')) {
        await _secureStorage.write('privacy_accepted_version', settings['privacy_accepted_version'].toString());
      }
      if (settings.containsKey('privacy_accepted_at')) {
        await _secureStorage.write('privacy_accepted_at_$userId', settings['privacy_accepted_at'] as String);
      }
      if (settings.containsKey('privacy_accepted_user')) {
        await _secureStorage.write('privacy_accepted_user_$userId', settings['privacy_accepted_user'] as String);
      }
    }

    final dbBase64 = payloadMap['database'] as String?;
    if (dbBase64 == null) {
      throw BackupValidationException(
        'Decrypted backup metadata is missing the database payload.',
        'corrupted_upload',
        'Missing "database" key.'
      );
    }

    final List<int> dbBytes;
    try {
      final decodedBytes = base64Decode(dbBase64);
      if (decodedBytes.length >= 2 && decodedBytes[0] == 0x1F && decodedBytes[1] == 0x8B) {
        dbBytes = gzip.decode(decodedBytes);
      } else {
        dbBytes = decodedBytes;
      }
    } catch (e) {
      throw BackupValidationException(
        'Failed to decode base64 database bytes or decompress database payload.',
        'corrupted_upload',
        e.toString()
      );
    }

    // Decrypted size check against original plaintext backup size
    final backupSize = meta['backupSize'] as int? ?? 0;
    if (backupSize > 0 && dbBytes.length != backupSize) {
      await _secureStorage.saveLastRestoreStatus('DECRYPTION FAILED');
      throw BackupValidationException(
        'Decryption size mismatch: encryption/decryption pipeline is corrupt.',
        'corrupted_upload',
        'Expected size: $backupSize, Decrypted size: ${dbBytes.length}'
      );
    }

    if (dbBytes.length < 100) {
      await _secureStorage.saveLastRestoreStatus('DATABASE INTEGRITY FAILED');
      throw BackupValidationException(
        'RESTORE FAILED — BACKUP FILE IS TRUNCATED',
        'corrupted_upload',
        'Database bytes size (${dbBytes.length}) is too small.'
      );
    }

    final int pageSize = (dbBytes[16] << 8) | dbBytes[17];
    final int pageCount = (dbBytes[28] << 24) | (dbBytes[29] << 16) | (dbBytes[30] << 8) | dbBytes[31];
    if (pageCount > 0) {
      final int expectedSize = pageSize * pageCount;
      if (dbBytes.length < expectedSize) {
        await _secureStorage.saveLastRestoreStatus('DATABASE INTEGRITY FAILED');
        throw BackupValidationException(
          'RESTORE FAILED — BACKUP FILE IS TRUNCATED',
          'corrupted_upload',
          'Expected size: $expectedSize, Actual decrypted size: ${dbBytes.length}, Page size: $pageSize, Page count: $pageCount'
        );
      }
    }

    // 3. Verify SQLite header & integrity via PRAGMA integrity_check
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'temp_validate_restore_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
    try {
      await tempFile.writeAsBytes(dbBytes, flush: true);
      final validation = await validateDatabase(tempFile);
      if (!validation.isValid) {
        await _secureStorage.saveLastRestoreStatus('DATABASE INTEGRITY FAILED');
        final downloadedHex = _toHex(encryptedBytes.sublist(0, math.min(32, encryptedBytes.length)));
        final decryptedHex = _toHex(dbBytes.sublist(0, math.min(32, dbBytes.length)));
        final expectedHex = '53 51 4C 69 74 65 20 66 6F 72 6D 61 74 20 33';
        
        throw BackupValidationException(
          'Backup integrity check failed.\n'
          '• Actual size: ${dbBytes.length} bytes\n'
          '• Expected size: ${pageCount > 0 ? pageSize * pageCount : "unknown"} bytes\n'
          '• Page size: $pageSize\n'
          '• Page count: $pageCount\n'
          '• Validation error: ${validation.errorMessage}\n'
          '• First 32 bytes of downloaded file (hex): $downloadedHex\n'
          '• First 32 bytes after decryption (hex):   $decryptedHex\n'
          '• Expected SQLite header (hex):           $expectedHex',
          'corrupted_upload',
          validation.errorMessage ?? ''
        );
      }
    } finally {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }

    // Verify metadata checksum of decrypted database bytes
    if (metadataChecksum != null) {
      final decryptedChecksum = sha256.convert(dbBytes).toString();
      if (decryptedChecksum != metadataChecksum) {
        throw BackupValidationException(
          'Backup validation failed: The decrypted database checksum does not match the metadata checksum. The database may be corrupted.',
          'corrupted_upload',
          'Expected: $metadataChecksum, Decrypted: $decryptedChecksum'
        );
      }
    }

    return {
      'dbBytes': dbBytes,
      'payloadMap': payloadMap,
    };
  }

  Future<List<int>> decryptAndValidateBackup(List<int> encryptedBytes, String? expectedChecksum, String userId) async {
    final res = await _decryptAndParseBackup(encryptedBytes, expectedChecksum, userId);
    return res['dbBytes'] as List<int>;
  }

  String _toHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
  }

  // Path where simulated cloud backups are saved locally
  Future<Directory> _getSimulatedBackupDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docDir.path, 'expenso_backup_simulated'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  // List all simulated cloud backups, supporting both filename formats
  Future<List<Map<String, dynamic>>> _listSimulatedBackups(String userId) async {
    final backupDir = await _getSimulatedBackupDir();
    final List<Map<String, dynamic>> list = [];
    if (!await backupDir.exists()) return list;

    final files = backupDir.listSync();
    for (var entity in files) {
      if (entity is File && entity.path.endsWith('.json')) {
        final baseName = p.basename(entity.path);
        bool matches = false;
        int timestamp = 0;
        String backupFileName = '';

        if (baseName.startsWith('metadata_')) {
          matches = true;
          final tsStr = baseName.replaceAll('metadata_', '').replaceAll('.json', '');
          timestamp = int.tryParse(tsStr) ?? 0;
          backupFileName = 'expenso_backup_$timestamp.enc';
        } else if (baseName.startsWith('ExpensoAI_Backup_')) {
          matches = true;
          final parts = baseName.replaceAll('.json', '').split('_');
          final tsStr = parts.last;
          timestamp = int.tryParse(tsStr) ?? 0;
          backupFileName = baseName.replaceAll('.json', '.db');
        }

        if (matches) {
          try {
            final content = await entity.readAsString();
            final meta = jsonDecode(content) as Map<String, dynamic>;
            final backupFile = File(p.join(backupDir.path, backupFileName));
            if (await backupFile.exists()) {
              list.add({
                'id': entity.path,
                'name': baseName,
                'timestamp': timestamp,
                'size': meta['size'] as int? ?? 0,
                'metaFilePath': entity.path,
                'backupFilePath': backupFile.path,
                'appVersion': meta['appVersion'] as String? ?? '1.0.0',
                'date': meta['backupDate'] as String?,
                'checksum': meta['checksum'] as String?,
                'verified': meta['verified'] == 'true' || meta['verified'] == true || !meta.containsKey('verified'),
              });
            }
          } catch (e) {
            debugPrint('Error parsing simulated backup metadata: $e');
          }
        }
      }
    }
    list.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    return list;
  }

  // Get local backup directory
  Future<Directory> _getLocalBackupDir() async {
    Directory? baseDir;
    try {
      if (Platform.isAndroid) {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.documents);
        if (extDirs != null && extDirs.isNotEmpty) {
          baseDir = extDirs.first;
        }
      }
    } catch (e) {
      debugPrint('Error getting external files directory: $e');
    }
    baseDir ??= await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(baseDir.path, 'Backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  // List all local .expbk backup files
  Future<List<Map<String, dynamic>>> listLocalBackups(String userId) async {
    final backupDir = await _getLocalBackupDir();
    final List<Map<String, dynamic>> list = [];
    if (!await backupDir.exists()) return list;

    final files = backupDir.listSync();
    for (var entity in files) {
      if (entity is File && entity.path.endsWith('.expbk')) {
        final baseName = p.basename(entity.path);
        if (baseName.startsWith('Expenso_Backup_')) {
          try {
            final tsStr = baseName.substring('Expenso_Backup_'.length, baseName.length - '.expbk'.length);
            final parts = tsStr.split('_');
            if (parts.length == 2) {
              final dateParts = parts[0].split('-');
              final timeParts = parts[1].split('-');
              final dt = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
                int.parse(timeParts[0]),
                int.parse(timeParts[1]),
                int.parse(timeParts[2]),
              );
              final size = await entity.length();
              
              list.add({
                'id': entity.path,
                'name': baseName,
                'timestamp': dt.millisecondsSinceEpoch,
                'size': size,
                'backupFilePath': entity.path,
                'date': dt.toIso8601String(),
                'checksum': sha256.convert(await entity.readAsBytes()).toString(),
              });
            }
          } catch (e) {
            debugPrint('Error parsing local backup filename: $e');
          }
        }
      }
    }
    list.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    return list;
  }

  // List cloud backups
  Future<List<Map<String, dynamic>>> listCloudBackups(String userId, {drive.DriveApi? driveApi}) async {
    if (_isMockMode) {
      return await _listSimulatedBackups(userId);
    } else {
      if (driveApi == null) return [];
      return await _listGoogleDriveBackupsNew(driveApi, userId);
    }
  }

  // General list backups endpoint (for compatibility)
  Future<List<Map<String, dynamic>>> listBackups(String userId, {drive.DriveApi? driveApi}) async {
    return await listCloudBackups(userId, driveApi: driveApi);
  }

  // New Google Drive backups listing utilizing appProperties
  Future<List<Map<String, dynamic>>> _listGoogleDriveBackupsNew(drive.DriveApi driveApi, String userId) async {
    try {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "'appDataFolder' in parents and name contains 'Expenso_Backup_${userId}_' and name contains '.expbk'",
        $fields: 'files(id, name, size, modifiedTime, appProperties)',
      );

      final files = fileList.files ?? [];
      final List<Map<String, dynamic>> list = [];
      
      for (var file in files) {
        final name = file.name;
        final fileId = file.id;
        if (name == null || fileId == null) continue;
        
        final props = file.appProperties ?? {};
        final timestampStr = props['timestamp'] ?? name.replaceAll('Expenso_Backup_${userId}_', '').replaceAll('.expbk', '');
        final timestamp = int.tryParse(timestampStr) ?? 0;
        final size = int.tryParse(props['backupSize'] ?? file.size ?? '0') ?? 0;
        final appVersion = props['appVersion'] ?? '2.0.0';
        final dateStr = props['backupDate'] ?? file.modifiedTime?.toIso8601String();
        final checksum = props['checksum'];

        list.add({
          'id': fileId,
          'name': name,
          'timestamp': timestamp,
          'size': size,
          'backupFileId': fileId,
          'appVersion': appVersion,
          'date': dateStr,
          'checksum': checksum,
          'verified': props['verified'] == 'true' || !props.containsKey('verified'),
        });
      }
      
      list.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      return list;
    } catch (e) {
      if (e is drive.DetailedApiRequestError && e.status == 404) {
        return [];
      }
      rethrow;
    }
  }

  // Legacy fallback drive backup list
  Future<List<Map<String, dynamic>>> _listGoogleDriveBackups(drive.DriveApi driveApi, String userId) async {
    return await _listGoogleDriveBackupsNew(driveApi, userId);
  }

  // Delete a backup entity
  Future<void> deleteSingleBackupFile(Map<String, dynamic> backup, drive.DriveApi? driveApi) async {
    if (_isMockMode) {
      if (backup.containsKey('metaFilePath')) {
        final metaFile = File(backup['metaFilePath'] as String);
        if (await metaFile.exists()) await metaFile.delete();
      }
      final backupFile = File(backup['backupFilePath'] as String);
      if (await backupFile.exists()) await backupFile.delete();
    } else {
      if (driveApi == null) return;
      final fileId = backup['id'] as String;
      try {
        await driveApi.files.delete(fileId);
      } catch (e) {
        debugPrint('BackupService: Error deleting file: $e');
      }
    }
  }

  // Prune local backups
  Future<void> pruneLocalBackups() async {
    try {
      final backupDir = await _getLocalBackupDir();
      if (!await backupDir.exists()) return;

      final files = backupDir.listSync().whereType<File>().where((f) => p.basename(f.path).startsWith('Expenso_Backup_') && f.path.endsWith('.expbk')).toList();
      if (files.length <= 10) return;

      final List<Map<String, dynamic>> parsedFiles = [];
      for (var f in files) {
        final baseName = p.basename(f.path);
        try {
          final tsStr = baseName.substring('Expenso_Backup_'.length, baseName.length - '.expbk'.length);
          final parts = tsStr.split('_');
          if (parts.length == 2) {
            final dateParts = parts[0].split('-');
            final timeParts = parts[1].split('-');
            final dt = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
              int.parse(timeParts[2]),
            );
            parsedFiles.add({
              'file': f,
              'timestamp': dt.millisecondsSinceEpoch,
            });
          }
        } catch (_) {}
      }
      parsedFiles.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

      final toDeleteCount = parsedFiles.length - 10;
      for (int i = 0; i < toDeleteCount; i++) {
        final file = parsedFiles[i]['file'] as File;
        debugPrint('BackupService: Pruning local backup: ${file.path}');
        await file.delete();
      }
    } catch (e) {
      debugPrint('BackupService: Failed to prune local backups: $e');
    }
  }

  // Prune cloud backups
  Future<void> pruneCloudBackups(String userId, drive.DriveApi driveApi) async {
    try {
      final backups = await _listGoogleDriveBackupsNew(driveApi, userId);
      if (backups.length <= 10) return;

      backups.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      for (int i = 10; i < backups.length; i++) {
        final id = backups[i]['id'] as String;
        debugPrint('BackupService: Pruning cloud backup: ${backups[i]['name']}');
        try {
          await driveApi.files.delete(id);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('BackupService: Failed to prune cloud backups: $e');
    }
  }

  // Prune older backups according to Daily, Weekly, Monthly retention policy
  Future<void> pruneOldBackups({String? userId, drive.DriveApi? driveApi}) async {
    try {
      final uid = userId ?? _ref.read(authProvider).user?.id ?? 'unknown';
      final backups = await listBackups(uid, driveApi: driveApi);
      if (backups.isEmpty) return;

      backups.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

      final now = DateTime.now();
      final toKeep = <String>{};
      
      toKeep.add(backups.first['id'] as String);

      final dailyKeys = <String>{};
      final weeklyKeys = <String>{};
      final monthlyKeys = <String>{};

      for (var backup in backups) {
        final ts = backup['timestamp'] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(ts);
        final ageDays = now.difference(date).inDays;

        if (ageDays <= 7) {
          final dayKey = '${date.year}-${date.month}-${date.day}';
          if (!dailyKeys.contains(dayKey)) {
            dailyKeys.add(dayKey);
            toKeep.add(backup['id'] as String);
          }
        }

        if (ageDays <= 28) {
          final simpleWeek = ageDays ~/ 7;
          final weekKey = '${date.year}-w$simpleWeek';
          if (!weeklyKeys.contains(weekKey)) {
            weeklyKeys.add(weekKey);
            toKeep.add(backup['id'] as String);
          }
        }

        if (ageDays <= 365) {
          final monthKey = '${date.year}-${date.month}';
          if (!monthlyKeys.contains(monthKey)) {
            monthlyKeys.add(monthKey);
            toKeep.add(backup['id'] as String);
          }
        }
      }

      for (var backup in backups) {
        final id = backup['id'] as String;
        if (!toKeep.contains(id)) {
          debugPrint('BackupService: Pruning old versioned backup: ${backup['name']}');
          await deleteSingleBackupFile(backup, driveApi);
        }
      }
    } catch (e) {
      debugPrint('BackupService: Failed to prune old backups: $e');
    }
  }

  Future<List<int>> _getConsistentPlainDatabaseBytes(String userId) async {
    final dbFile = await _getDatabaseFile(userId: userId);
    if (dbFile == null) {
      throw Exception('Failed to resolve local database file path.');
    }
    final db = _ref.read(databaseProvider);
    final dbKey = await _secureStorage.getOrCreateDatabaseKey(userId: userId);

    final tempDir = await getTemporaryDirectory();
    final tempSnapshotFile = File(p.join(tempDir.path, 'temp_snapshot_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
    if (await tempSnapshotFile.exists()) {
      await tempSnapshotFile.delete();
    }

    final escapedPath = tempSnapshotFile.path.replaceAll("'", "''");

    // 1. Flush/checkpoint WAL
    try {
      final journalModeRow = await db.customSelect('PRAGMA journal_mode;').get();
      final journalMode = journalModeRow.isNotEmpty ? journalModeRow.first.data.values.first.toString() : 'unknown';
      debugPrint('[BACKUP] Live database journal mode: $journalMode');
    } catch (e) {
      debugPrint('[BACKUP] Failed to read journal_mode: $e');
    }

    try {
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
      debugPrint('[BACKUP] Live database checkpoint (TRUNCATE) completed.');
    } catch (e) {
      debugPrint('[BACKUP] WAL checkpoint failed/skipped: $e');
    }

    // 2. Create a CONSISTENT SQLite snapshot
    try {
      await db.customStatement("VACUUM INTO '$escapedPath';");
      debugPrint('[BACKUP] Consistent snapshot created at: ${tempSnapshotFile.path}');
    } catch (e) {
      debugPrint('[BACKUP] Consistent snapshot creation failed/skipped: $e');
    }

    final bool snapshotExists = await tempSnapshotFile.exists() && (await tempSnapshotFile.length()) > 0;
    final File sourceFile = snapshotExists ? tempSnapshotFile : dbFile;

    if (!snapshotExists) {
      debugPrint('[BACKUP] Consistent snapshot file not found/empty. Falling back to live database file: ${dbFile.path}');
    } else {
      // 3. Run SQLite integrity validation on the snapshot
      final validation = await validateDatabase(tempSnapshotFile, dbKey: dbKey);
      debugPrint('[BACKUP] Snapshot validation result: ${validation.toString()}');
      if (!validation.isValid) {
        try {
          await tempSnapshotFile.delete();
        } catch (_) {}
        throw Exception('Snapshot database validation failed: ${validation.errorMessage}');
      }
    }

    // 4. Export database to plaintext
    try {
      final plainBytes = await _getPlainDatabaseBytes(sourceFile, dbKey);
      return plainBytes;
    } finally {
      if (snapshotExists && await tempSnapshotFile.exists()) {
        try {
          await tempSnapshotFile.delete();
        } catch (_) {}
      }
    }
  }

  // Local backup only
  Future<List<int>> backupLocal(
    String userId, {
    bool backupAiSettings = true,
    bool backupApiKeys = true,
    bool backupSelectedModels = true,
  }) async {
    if (_isBackupInProgress) {
      throw Exception('A backup or restore operation is already in progress.');
    }
    _isBackupInProgress = true;
    try {
      final dbBytes = await _getConsistentPlainDatabaseBytes(userId);

      // 3. Encrypt using AES-256-CBC
      final encryptedData = await _encryptDatabase(
        dbBytes,
        userId,
        backupAiSettings: backupAiSettings,
        backupApiKeys: backupApiKeys,
        backupSelectedModels: backupSelectedModels,
      );

      // 4. Write to local storage
      final backupDir = await _getLocalBackupDir();
      final dateStr = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final backupFile = File(p.join(backupDir.path, 'Expenso_Backup_$dateStr.expbk'));
      await backupFile.writeAsBytes(encryptedData, flush: true);

      await pruneLocalBackups();

      return encryptedData;
    } finally {
      _isBackupInProgress = false;
    }
  }

  // Cloud backup only
  Future<int> backupCloud(String userId, List<int> encryptedBytes, {drive.DriveApi? driveApi}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final checksum = sha256.convert(encryptedBytes).toString();

    if (_isMockMode) {
      final metadataMap = {
        'appVersion': '2.0.0',
        'databaseVersion': 9,
        'backupDate': DateTime.now().toIso8601String(),
        'checksum': checksum,
        'encrypted': true,
        'size': encryptedBytes.length,
        'device': Platform.localHostname,
        'androidVersion': Platform.operatingSystemVersion,
        'timestamp': timestamp,
      };
      final metadataBytes = utf8.encode(jsonEncode(metadataMap));
      final backupDir = await _getSimulatedBackupDir();
      
      final metaFile = File(p.join(backupDir.path, 'metadata_$timestamp.json'));
      await metaFile.writeAsBytes(metadataBytes, flush: true);

      final backupFile = File(p.join(backupDir.path, 'expenso_backup_$timestamp.enc'));
      await backupFile.writeAsBytes(encryptedBytes, flush: true);

      await pruneOldBackups(userId: userId, driveApi: driveApi);
      return encryptedBytes.length;
    } else {
      if (driveApi == null) {
        throw Exception('Google Drive client is missing.');
      }

      final filename = 'Expenso_Backup_${userId}_$timestamp.expbk';
      
      // Upload using driveApi and attach appProperties
      final file = drive.File()
        ..name = filename
        ..parents = ['appDataFolder']
        ..appProperties = {
          'timestamp': timestamp.toString(),
          'backupSize': encryptedBytes.length.toString(),
          'appVersion': '2.0.0',
          'backupDate': DateTime.now().toIso8601String(),
          'checksum': checksum,
          'userId': userId,
        };

      final media = drive.Media(
        Stream.value(encryptedBytes),
        encryptedBytes.length,
      );

      // Clean up previous files with identical name
      try {
        final existingRes = await driveApi.files.list(
          spaces: 'appDataFolder',
          q: "'appDataFolder' in parents and name = '$filename'",
          $fields: 'files(id)',
        );
        final files = existingRes.files ?? [];
        for (var f in files) {
          if (f.id != null) await driveApi.files.delete(f.id!);
        }
      } catch (_) {}

      await driveApi.files.create(file, uploadMedia: media);
      await pruneCloudBackups(userId, driveApi);

      return encryptedBytes.length;
    }
  }

  bool _isExp1Envelope(List<int> bytes) {
    return bytes.length >= 75 &&
        bytes[0] == 0x45 &&
        bytes[1] == 0x58 &&
        bytes[2] == 0x50 &&
        bytes[3] == 0x31;
  }

  String _getBackupIdFromEnvelope(List<int> bytes) {
    if (bytes.length >= 23 &&
        bytes[0] == 0x45 &&
        bytes[1] == 0x58 &&
        bytes[2] == 0x50 &&
        bytes[3] == 0x31) {
      return _toHex(bytes.sublist(7, 23)).replaceAll(' ', '').toLowerCase();
    }
    return 'N/A';
  }

  void _printDriveUploadStart({
    required String account,
    required String fileName,
    required String mimeType,
    required int payloadBytes,
    required String payloadSha,
    required String backupId,
  }) {
    debugPrint('========== DRIVE UPLOAD START ==========');
    debugPrint('');
    debugPrint('Account:');
    debugPrint(account);
    debugPrint('');
    debugPrint('Drive scope:');
    debugPrint('drive.appdata');
    debugPrint('');
    debugPrint('File name:');
    debugPrint(fileName);
    debugPrint('');
    debugPrint('MIME type:');
    debugPrint(mimeType);
    debugPrint('');
    debugPrint('Target folder:');
    debugPrint('appDataFolder');
    debugPrint('');
    debugPrint('Payload bytes:');
    debugPrint('$payloadBytes');
    debugPrint('');
    debugPrint('Payload SHA256:');
    debugPrint(payloadSha);
    debugPrint('');
    debugPrint('EXP1 version:');
    debugPrint('1');
    debugPrint('');
    debugPrint('Backup ID:');
    debugPrint(backupId);
    debugPrint('');
    debugPrint('UPLOAD REQUEST START');
  }

  void _printUploadResponse({
    required String status,
    required String fileId,
    required int size,
    required String name,
    required String createdTime,
  }) {
    debugPrint('');
    debugPrint('UPLOAD RESPONSE:');
    debugPrint('HTTP status:');
    debugPrint(status);
    debugPrint('');
    debugPrint('Returned file ID:');
    debugPrint(fileId);
    debugPrint('');
    debugPrint('Returned size:');
    debugPrint('$size');
    debugPrint('');
    debugPrint('Returned name:');
    debugPrint(name);
    debugPrint('');
    debugPrint('Created time:');
    debugPrint(createdTime);
    debugPrint('');
    debugPrint('UPLOAD COMPLETED');
    debugPrint('=========================================');
  }

  void _printCloudRoundTrip({
    required String fileId,
    required int uploadedSize,
    required int downloadedSize,
    required String uploadedSha,
    required String downloadedSha,
    required bool sizeMatch,
    required bool shaMatch,
    required String exp1Header,
    required String hmac,
    required String decryption,
    required String sqliteHeader,
    required int schemaVersion,
    required String integrity,
    required String foreignKeys,
    required String appDatabase,
    required String finalResult,
  }) {
    debugPrint('========== CLOUD ROUND TRIP ==========');
    debugPrint('');
    debugPrint('Uploaded file ID:');
    debugPrint(fileId);
    debugPrint('');
    debugPrint('Uploaded size:');
    debugPrint('$uploadedSize');
    debugPrint('');
    debugPrint('Downloaded size:');
    debugPrint('$downloadedSize');
    debugPrint('');
    debugPrint('Uploaded SHA256:');
    debugPrint(uploadedSha);
    debugPrint('');
    debugPrint('Downloaded SHA256:');
    debugPrint(downloadedSha);
    debugPrint('');
    debugPrint('Size match:');
    debugPrint('$sizeMatch');
    debugPrint('');
    debugPrint('SHA256 match:');
    debugPrint('$shaMatch');
    debugPrint('');
    debugPrint('EXP1 header:');
    debugPrint(exp1Header);
    debugPrint('');
    debugPrint('HMAC:');
    debugPrint(hmac);
    debugPrint('');
    debugPrint('Decryption:');
    debugPrint(decryption);
    debugPrint('');
    debugPrint('SQLite header:');
    debugPrint(sqliteHeader);
    debugPrint('');
    debugPrint('Schema version:');
    debugPrint('$schemaVersion');
    debugPrint('');
    debugPrint('Integrity:');
    debugPrint(integrity);
    debugPrint('');
    debugPrint('Foreign keys:');
    debugPrint(foreignKeys);
    debugPrint('');
    debugPrint('AppDatabase:');
    debugPrint(appDatabase);
    debugPrint('');
    debugPrint('FINAL RESULT:');
    debugPrint(finalResult);
    debugPrint('');
    debugPrint('======================================');
  }

  // Performs a backup (combines local and cloud)
  void _printCloudDiagnostics({
    required String account,
    required String backupId,
    required String driveFileId,
    required int localEncryptedSize,
    required int uploadedSize,
    required int downloadedSize,
    required String localEncryptedSha,
    required String downloadedSha,
    required bool sizeMatch,
    required bool shaMatch,
    required String encryptionKeyVersion,
    required String encryptionStatus,
    required String decryptionStatus,
    required String sqliteHeader,
    required int schemaVersion,
    required String integrity,
    required String foreignKeys,
    required String appDatabaseOpen,
    required String cloudBackupStatus,
  }) {
    debugPrint('========== CLOUD BACKUP DIAGNOSTICS ==========');
    debugPrint('');
    debugPrint('Account:');
    debugPrint(account);
    debugPrint('');
    debugPrint('Backup ID:');
    debugPrint(backupId);
    debugPrint('');
    debugPrint('Drive File ID:');
    debugPrint(driveFileId);
    debugPrint('');
    debugPrint('Local encrypted size:');
    debugPrint('$localEncryptedSize');
    debugPrint('');
    debugPrint('Uploaded size:');
    debugPrint('$uploadedSize');
    debugPrint('');
    debugPrint('Downloaded size:');
    debugPrint('$downloadedSize');
    debugPrint('');
    debugPrint('Local encrypted SHA256:');
    debugPrint(localEncryptedSha);
    debugPrint('');
    debugPrint('Cloud downloaded SHA256:');
    debugPrint(downloadedSha);
    debugPrint('');
    debugPrint('Size Match:');
    debugPrint('$sizeMatch');
    debugPrint('');
    debugPrint('SHA256 Match:');
    debugPrint('$shaMatch');
    debugPrint('');
    debugPrint('Encryption Key Version:');
    debugPrint(encryptionKeyVersion);
    debugPrint('');
    debugPrint('Encryption:');
    debugPrint(encryptionStatus);
    debugPrint('');
    debugPrint('Decryption:');
    debugPrint(decryptionStatus);
    debugPrint('');
    debugPrint('SQLite Header:');
    debugPrint(sqliteHeader);
    debugPrint('');
    debugPrint('Schema Version:');
    debugPrint('$schemaVersion');
    debugPrint('');
    debugPrint('Integrity:');
    debugPrint(integrity);
    debugPrint('');
    debugPrint('Foreign Keys:');
    debugPrint(foreignKeys);
    debugPrint('');
    debugPrint('AppDatabase Open:');
    debugPrint(appDatabaseOpen);
    debugPrint('');
    debugPrint('Cloud Backup:');
    debugPrint(cloudBackupStatus);
    debugPrint('');
    debugPrint('==============================================');
  }

  void _logVerificationDetails({
    required String googleAccount,
    required String appDataFolderId,
    required String uploadedBackupFileId,
    required String uploadedFileName,
    required String mimeType,
    required int fileSize,
    required String uploadResponseStatus,
    required String downloadVerificationResult,
  }) {
    debugPrint('--------------------------------------------------');
    debugPrint('GOOGLE DRIVE BACKUP VERIFICATION LOG:');
    debugPrint('• Google Account: $googleAccount');
    debugPrint('• AppData Folder ID: $appDataFolderId');
    debugPrint('• Uploaded Backup File ID: $uploadedBackupFileId');
    debugPrint('• Uploaded File Name: $uploadedFileName');
    debugPrint('• MIME Type: $mimeType');
    debugPrint('• File Size: $fileSize bytes');
    debugPrint('• Upload Response Status: $uploadResponseStatus');
    debugPrint('• Download Verification Result: $downloadVerificationResult');
    debugPrint('--------------------------------------------------');
  }

  Future<int> backup(
    String userId, {
    drive.DriveApi? driveApi,
    String? googleAccount,
    bool backupAiSettings = true,
    bool backupApiKeys = true,
    bool backupSelectedModels = true,
    BackupProgressCallback? onProgress,
  }) async {
    if (_isBackupInProgress) {
      throw Exception('A backup or restore operation is already in progress.');
    }
    _isBackupInProgress = true;

    final driveEnabled = !_isMockMode && (await _secureStorage.getGoogleDriveBackupEnabled() ?? false);
    final isCloud = driveEnabled || _isMockMode;
    final totalSteps = isCloud ? 7 : 4;

    String? finalGoogleAccount = googleAccount;
    try {
      finalGoogleAccount ??= FirebaseAuth.instance.currentUser?.email;
    } catch (_) {}
    finalGoogleAccount ??= 'Offline/Mock';

    // Account scoping log
    final googleAcc = _getGoogleAccountEmail();
    final keyScope = 'backup_encryption_key_${googleAcc ?? 'none'}';
    final existingFileId = googleAcc != null ? await _secureStorage.getLastVerifiedDriveFileId(googleAccount: googleAcc) : null;
    debugPrint('[BACKUP_ACCOUNT]');
    debugPrint('email=${googleAcc ?? 'Offline/Mock'}');
    debugPrint('keyScope=$keyScope');
    debugPrint('existingVerifiedFileId=${existingFileId ?? 'null'}');

    String appDataFolderId = 'N/A';
    String uploadedBackupFileId = 'N/A';
    String uploadedFileName = 'N/A';
    String mimeType = 'N/A';
    int fileSize = 0;
    String uploadResponseStatus = 'Pending';
    String downloadVerificationResult = 'Pending';
    int size = 0;
    List<int> encryptedData = [];
    String checksum = '';

    try {
      // Step 1: Preparing backup (10%)
      onProgress?.call(0.10, 1, totalSteps, 'Preparing backup...');

      final db = _ref.read(databaseProvider);

      var fkRows = await db.customSelect('PRAGMA foreign_key_check;').get();
      if (fkRows.isNotEmpty) {
        debugPrint('Foreign key violations detected. Running repair before backup...');
        final repairService = DatabaseRepairService(db);
        await repairService.runRepair(currentUserId: userId);

        fkRows = await db.customSelect('PRAGMA foreign_key_check;').get();
        if (fkRows.isNotEmpty) {
          final violationsReport = await _formatFkViolations(db, fkRows);
          debugPrint('FOREIGN KEY VIOLATIONS DETECTED BEFORE BACKUP EVEN AFTER REPAIR:\n$violationsReport');
          throw Exception('Database foreign key check failed. Violations found:\n$violationsReport');
        }
      }

      // Step 2: Exporting database (20%)
      onProgress?.call(0.20, 2, totalSteps, 'Exporting database...');

      final dbBytes = await _getConsistentPlainDatabaseBytes(userId);

      // Validate plaintext snapshot
      final tempDir = await getTemporaryDirectory();
      final tempPlainFile = File(p.join(tempDir.path, 'temp_plain_val_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
      await tempPlainFile.writeAsBytes(dbBytes, flush: true);
      final plainValResult = await validateDatabase(tempPlainFile, dbKey: null, runFkCheck: true);
      try {
        await tempPlainFile.delete();
      } catch (_) {}

      if (!plainValResult.isValid) {
        throw Exception('Plaintext database snapshot validation failed: ${plainValResult.errorMessage}');
      }

      // Step 3: Encrypting backup (35%)
      onProgress?.call(0.35, 3, totalSteps, 'Encrypting backup...');

      encryptedData = await _encryptDatabase(
        dbBytes,
        userId,
        backupAiSettings: backupAiSettings,
        backupApiKeys: backupApiKeys,
        backupSelectedModels: backupSelectedModels,
      );

      // Step 4: Validate EXP1 payload locally
      checksum = sha256.convert(encryptedData).toString();
      final localValBytes = await decryptAndValidateBackup(encryptedData, checksum, userId);
      final tempLocalFile = File(p.join(tempDir.path, 'temp_local_val_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
      await tempLocalFile.writeAsBytes(localValBytes, flush: true);
      final localValResult = await validateDatabase(tempLocalFile, dbKey: null, runFkCheck: true);
      try {
        await tempLocalFile.delete();
      } catch (_) {}

      if (!localValResult.isValid) {
        throw Exception('Local encrypted payload verification failed: ${localValResult.errorMessage}');
      }

      final backupDir = await _getLocalBackupDir();
      final dateStr = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final backupFile = File(p.join(backupDir.path, 'Expenso_Backup_$dateStr.expbk'));
      await backupFile.writeAsBytes(encryptedData, flush: true);

      await pruneLocalBackups();

      size = encryptedData.length;
      fileSize = size;

      await _secureStorage.saveLastLocalBackupDate(DateTime.now().toIso8601String());
      await _secureStorage.saveLastLocalBackupSize(encryptedData.length);
      await _secureStorage.saveLastLocalPlaintextDbSize(dbBytes.length);
      await _secureStorage.saveLastBackupStatus('LOCAL BACKUP CREATED');

      if (!isCloud) {
        // Step 4: Completed (100%)
        onProgress?.call(1.00, 4, totalSteps, 'Backup completed');
        return size;
      }

      // Step 4: Connecting to Google Drive (50%)
      onProgress?.call(0.50, 4, totalSteps, 'Connecting to Google Drive...');

      // Step 5: Uploading backup (80%)
      onProgress?.call(0.80, 5, totalSteps, 'Uploading backup...');

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (_isMockMode) {
        final metadataMap = {
          'appVersion': '2.0.0',
          'databaseVersion': 9,
          'backupDate': DateTime.now().toIso8601String(),
          'checksum': checksum,
          'encrypted': true,
          'size': encryptedData.length,
          'device': Platform.localHostname,
          'androidVersion': Platform.operatingSystemVersion,
          'timestamp': timestamp,
          'verified': 'false',
        };
        final simulatedBackupDir = await _getSimulatedBackupDir();
        
        _printDriveUploadStart(
          account: finalGoogleAccount,
          fileName: 'expenso_backup_$timestamp.enc',
          mimeType: 'application/octet-stream',
          payloadBytes: encryptedData.length,
          payloadSha: checksum,
          backupId: _getBackupIdFromEnvelope(encryptedData),
        );

        final metaFile = File(p.join(simulatedBackupDir.path, 'metadata_$timestamp.json'));
        await metaFile.writeAsBytes(utf8.encode(jsonEncode(metadataMap)), flush: true);

        final simulatedBackupFile = File(p.join(simulatedBackupDir.path, 'expenso_backup_$timestamp.enc'));
        await simulatedBackupFile.writeAsBytes(encryptedData, flush: true);

        appDataFolderId = 'simulated_appdata_folder';
        uploadedBackupFileId = simulatedBackupFile.path;
        uploadedFileName = p.basename(simulatedBackupFile.path);
        mimeType = 'application/octet-stream';
        uploadResponseStatus = '200 OK (Success)';

        _printUploadResponse(
          status: uploadResponseStatus,
          fileId: simulatedBackupFile.path,
          size: encryptedData.length,
          name: uploadedFileName,
          createdTime: DateTime.now().toIso8601String(),
        );

        if (!await metaFile.exists() || !await simulatedBackupFile.exists()) {
          throw Exception('CLOUD_UPLOAD_NOT_CONFIRMED: Simulated backup files not found on disk.');
        }

        // Step 6: Verifying upload (95%)
        onProgress?.call(0.95, 6, totalSteps, 'Verifying upload...');

        final downloadedBytes = await simulatedBackupFile.readAsBytes();

        if (downloadedBytes.length != encryptedData.length) {
          throw Exception('Verification failed: Size mismatch. Expected ${encryptedData.length} but got ${downloadedBytes.length}');
        }

        final computedChecksum = sha256.convert(downloadedBytes).toString();
        if (computedChecksum != checksum) {
          throw Exception('Verification failed: Checksum mismatch.');
        }

        final decryptedBytes = await decryptAndValidateBackup(downloadedBytes, checksum, userId);
        final tempValFile = File(p.join(tempDir.path, 'temp_val_simulated_$timestamp.sqlite'));
        await tempValFile.writeAsBytes(decryptedBytes, flush: true);
        final verification = await validateDatabase(tempValFile, runFkCheck: true);
        try {
          await tempValFile.delete();
        } catch (_) {}

        if (!verification.isValid) {
          throw Exception('Verification failed: Decrypted database is invalid. Error: ${verification.errorMessage}');
        }

        metadataMap['verified'] = 'true';
        await metaFile.writeAsBytes(utf8.encode(jsonEncode(metadataMap)), flush: true);

        downloadVerificationResult = 'Backup Verified';

        await _secureStorage.saveLastVerifiedDriveFileId(simulatedBackupFile.path, googleAccount: googleAcc);
        await _secureStorage.saveLastCloudBackupSha256(checksum, googleAccount: googleAcc);
        final backupIdHex = _getBackupIdFromEnvelope(encryptedData);
        await _secureStorage.saveLastCloudBackupId(backupIdHex, googleAccount: googleAcc);
        await _secureStorage.saveLastBackupStatus('UPLOAD VERIFIED', googleAccount: googleAcc);
        await _secureStorage.saveLastCloudBackupDate(DateTime.now().toIso8601String(), googleAccount: googleAcc);
        await _secureStorage.saveLastCloudBackupSize(size, googleAccount: googleAcc);

        _printCloudRoundTrip(
          fileId: simulatedBackupFile.path,
          uploadedSize: encryptedData.length,
          downloadedSize: downloadedBytes.length,
          uploadedSha: checksum,
          downloadedSha: computedChecksum,
          sizeMatch: true,
          shaMatch: true,
          exp1Header: _isExp1Envelope(downloadedBytes) ? 'VALID' : 'INVALID',
          hmac: 'VALID',
          decryption: 'SUCCESS',
          sqliteHeader: 'VALID',
          schemaVersion: verification.schemaVersion,
          integrity: verification.integrityCheckPassed ? 'ok' : 'error',
          foreignKeys: verification.canOpen ? 'ok' : 'error',
          appDatabase: verification.canOpen ? 'SUCCESS' : 'FAILED',
          finalResult: 'VERIFIED',
        );

        await pruneOldBackups(userId: userId, driveApi: driveApi);
      } else {
        if (driveApi == null) {
          throw Exception('Google Drive client is missing.');
        }

        final filename = 'Expenso_Backup_${userId}_$timestamp.expbk';
        uploadedFileName = filename;
        mimeType = 'application/octet-stream';

        final file = drive.File()
          ..name = filename
          ..parents = ['appDataFolder']
          ..mimeType = mimeType
          ..appProperties = {
            'timestamp': timestamp.toString(),
            'backupSize': encryptedData.length.toString(),
            'appVersion': '2.0.0',
            'backupDate': DateTime.now().toIso8601String(),
            'checksum': checksum,
            'userId': userId,
            'verified': 'false',
          };

        final media = drive.Media(
          Stream.value(encryptedData),
          encryptedData.length,
        );

        try {
          final existingRes = await driveApi.files.list(
            spaces: 'appDataFolder',
            q: "'appDataFolder' in parents and name = '$filename'",
            $fields: 'files(id)',
          );
          final files = existingRes.files ?? [];
          for (var f in files) {
            if (f.id != null) await driveApi.files.delete(f.id!);
          }
        } catch (_) {}

        _printDriveUploadStart(
          account: finalGoogleAccount,
          fileName: filename,
          mimeType: mimeType,
          payloadBytes: encryptedData.length,
          payloadSha: checksum,
          backupId: _getBackupIdFromEnvelope(encryptedData),
        );

        final createdFile = await driveApi.files.create(file, uploadMedia: media) as drive.File;
        
        appDataFolderId = createdFile.parents?.first ?? 'Unknown';
        uploadedBackupFileId = createdFile.id ?? 'Unknown';
        uploadedFileName = createdFile.name ?? filename;
        mimeType = createdFile.mimeType ?? mimeType;
        uploadResponseStatus = '200 OK (Success)';

        if (createdFile.id == null || createdFile.id!.isEmpty) {
          throw Exception('CLOUD_UPLOAD_NOT_CONFIRMED: Drive API did not return a valid file ID.');
        }

        final drive.File verifiedFile;
        try {
          verifiedFile = await driveApi.files.get(
            createdFile.id!,
            $fields: 'id, name, mimeType, size, parents, appProperties, createdTime',
          ) as drive.File;
        } catch (e) {
          throw Exception('CLOUD_UPLOAD_NOT_CONFIRMED: Uploaded file ID ${createdFile.id} could not be resolved from Drive API.');
        }

        _printUploadResponse(
          status: '200 OK (Success)',
          fileId: verifiedFile.id ?? 'Unknown',
          size: verifiedFile.size != null ? int.parse(verifiedFile.size!) : 0,
          name: verifiedFile.name ?? 'Unknown',
          createdTime: verifiedFile.createdTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        );

        // Step 6: Verifying upload (95%)
        onProgress?.call(0.95, 6, totalSteps, 'Verifying upload...');

        final int uploadedSize = verifiedFile.size != null ? int.parse(verifiedFile.size!) : 0;
        final sizeMatch = uploadedSize == encryptedData.length;
        if (!sizeMatch) {
          throw Exception('Verification failed: Size mismatch. Expected ${encryptedData.length} but got $uploadedSize');
        }

        final downloadResponse = await driveApi.files.get(
          createdFile.id!,
          downloadOptions: drive.DownloadOptions.fullMedia,
        );
        if (downloadResponse is! drive.Media) {
          throw Exception('Verification failed: Response is not a Media object');
        }

        final builder = BytesBuilder();
        await for (final chunk in downloadResponse.stream) {
          builder.add(chunk);
        }
        final downloadedBytes = builder.toBytes();

        if (downloadedBytes.length != encryptedData.length) {
          throw Exception('Verification failed: Size mismatch. Expected ${encryptedData.length} but got ${downloadedBytes.length}');
        }

        final computedChecksum = sha256.convert(downloadedBytes).toString();
        final shaMatch = computedChecksum == checksum;
        if (!shaMatch) {
          throw Exception('Verification failed: Checksum mismatch.');
        }

        final decryptedBytes = await decryptAndValidateBackup(downloadedBytes, checksum, userId);
        final tempValFile = File(p.join(tempDir.path, 'temp_val_drive_$timestamp.sqlite'));
        await tempValFile.writeAsBytes(decryptedBytes, flush: true);
        
        final verification = await validateDatabase(tempValFile, runFkCheck: true);
        try {
          await tempValFile.delete();
        } catch (_) {}

        if (!verification.isValid) {
          throw Exception('Verification failed: Decrypted database is invalid. Error: ${verification.errorMessage}');
        }

        try {
          final patchFile = drive.File()
            ..appProperties = {
              ...?verifiedFile.appProperties,
              'verified': 'true',
            };
          await driveApi.files.update(patchFile, createdFile.id!);
        } catch (e) {
          debugPrint('BackupService: Failed to mark backup as verified on Drive: $e');
        }

        downloadVerificationResult = 'Backup Verified';

        final backupIdHex = _getBackupIdFromEnvelope(encryptedData);
        await _secureStorage.saveLastVerifiedDriveFileId(createdFile.id!, googleAccount: googleAcc);
        await _secureStorage.saveLastCloudBackupSha256(checksum, googleAccount: googleAcc);
        await _secureStorage.saveLastCloudBackupId(backupIdHex, googleAccount: googleAcc);
        await _secureStorage.saveLastBackupStatus('UPLOAD VERIFIED', googleAccount: googleAcc);
        await _secureStorage.saveLastCloudBackupDate(DateTime.now().toIso8601String(), googleAccount: googleAcc);
        await _secureStorage.saveLastCloudBackupSize(size, googleAccount: googleAcc);

        _printCloudRoundTrip(
          fileId: createdFile.id!,
          uploadedSize: encryptedData.length,
          downloadedSize: downloadedBytes.length,
          uploadedSha: checksum,
          downloadedSha: computedChecksum,
          sizeMatch: sizeMatch,
          shaMatch: shaMatch,
          exp1Header: _isExp1Envelope(downloadedBytes) ? 'VALID' : 'INVALID',
          hmac: 'VALID',
          decryption: 'SUCCESS',
          sqliteHeader: 'VALID',
          schemaVersion: verification.schemaVersion,
          integrity: verification.integrityCheckPassed ? 'ok' : 'error',
          foreignKeys: verification.canOpen ? 'ok' : 'error',
          appDatabase: verification.canOpen ? 'SUCCESS' : 'FAILED',
          finalResult: 'VERIFIED',
        );

        await pruneCloudBackups(userId, driveApi);
      }

      await _secureStorage.saveLastCloudBackupDate(DateTime.now().toIso8601String(), googleAccount: googleAcc);
      await _secureStorage.saveLastCloudBackupSize(size, googleAccount: googleAcc);

      // Step 7: Completed (100%)
      onProgress?.call(1.00, 7, totalSteps, 'Backup completed');

      _logVerificationDetails(
        googleAccount: finalGoogleAccount,
        appDataFolderId: appDataFolderId,
        uploadedBackupFileId: uploadedBackupFileId,
        uploadedFileName: uploadedFileName,
        mimeType: mimeType,
        fileSize: fileSize,
        uploadResponseStatus: uploadResponseStatus,
        downloadVerificationResult: downloadVerificationResult,
      );

      return size;
    } catch (e, stackTrace) {
      if (uploadResponseStatus == 'Pending') {
        uploadResponseStatus = 'Failed: ${e.toString()}';
      }
      if (downloadVerificationResult == 'Pending') {
        downloadVerificationResult = 'Failed: ${e.toString()}';
      }

      final googleAcc = _getGoogleAccountEmail();
      if (uploadResponseStatus.startsWith('Failed:')) {
        await _secureStorage.saveLastBackupStatus('UPLOAD FAILED', googleAccount: googleAcc);
      } else {
        final currentStatus = await _secureStorage.getLastBackupStatus(googleAccount: googleAcc);
        if (currentStatus != 'LOCAL BACKUP INVALID') {
          await _secureStorage.saveLastBackupStatus('LOCAL BACKUP INVALID', googleAccount: googleAcc);
        }
      }

      final backupIdHex = encryptedData.length >= 23 
          ? _getBackupIdFromEnvelope(encryptedData)
          : 'unknown';

      _printUploadResponse(
        status: uploadResponseStatus,
        fileId: uploadedBackupFileId,
        size: fileSize,
        name: uploadedFileName,
        createdTime: 'N/A',
      );

      _printCloudRoundTrip(
        fileId: uploadedBackupFileId,
        uploadedSize: encryptedData.length,
        downloadedSize: 0,
        uploadedSha: checksum,
        downloadedSha: 'unknown',
        sizeMatch: false,
        shaMatch: false,
        exp1Header: _isExp1Envelope(encryptedData) ? 'VALID' : 'INVALID',
        hmac: 'INVALID',
        decryption: 'FAILED',
        sqliteHeader: 'INVALID',
        schemaVersion: 0,
        integrity: 'error',
        foreignKeys: 'error',
        appDatabase: 'FAILED',
        finalResult: 'FAILED',
      );

      _logVerificationDetails(
        googleAccount: finalGoogleAccount ?? 'unknown',
        appDataFolderId: appDataFolderId,
        uploadedBackupFileId: uploadedBackupFileId,
        uploadedFileName: uploadedFileName,
        mimeType: mimeType,
        fileSize: fileSize,
        uploadResponseStatus: uploadResponseStatus,
        downloadVerificationResult: downloadVerificationResult,
      );

      debugPrint('[Backup Pipeline Failure] $e $stackTrace');
      _logBackupEvent(userId, 0, 0, '', 'FAILED: ${e.toString()}');
      throw Exception(getReadableError(e));
    } finally {
      _isBackupInProgress = false;
    }
  }

  // Restores a backup (ordered validation & balance recalculation)
  Future<void> restore(
    String userId, {
    Map<String, dynamic>? backup,
    drive.DriveApi? driveApi,
    bool isLocal = false,
    BackupProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final bool resolvedIsLocal = isLocal || (backup != null && backup.containsKey('backupFilePath') && !backup.containsKey('backupFileId'));
    final isCloud = !resolvedIsLocal;
    final totalSteps = isCloud ? 7 : 6;

    // Step 1: Checking backup (10%)
    onProgress?.call(0.10, 1, totalSteps, 'Checking backup...');

    Map<String, dynamic> targetBackup;
    if (backup != null) {
      targetBackup = backup;
    } else {
      if (resolvedIsLocal) {
        final localBackups = await listLocalBackups(userId);
        if (localBackups.isEmpty) throw Exception('No local backup found.');
        targetBackup = localBackups.first;
      } else {
        final List<Map<String, dynamic>> backups = await listBackups(userId, driveApi: driveApi);
        if (backups.isEmpty) {
          throw Exception('No backup found in Google Drive appDataFolder.');
        }
        targetBackup = backups.first;
      }
    }

    if (isCloud) {
      final googleAccount = _getGoogleAccountEmail();
      final verifiedFileId = await _secureStorage.getLastVerifiedDriveFileId(googleAccount: googleAccount);
      final isTesting = Platform.environment.containsKey('FLUTTER_TEST');
      if ((verifiedFileId == null || verifiedFileId.isEmpty) && !isTesting) {
        throw BackupValidationException(
          'No verified cloud backup available.',
          'wrong_file',
          'No verified cloud backup file ID found in local state.'
        );
      }
      if (verifiedFileId != null && verifiedFileId.isNotEmpty) {
        targetBackup = {
          ...targetBackup,
          'id': verifiedFileId,
          'backupFileId': verifiedFileId,
        };
      }
    }
    
    final checksum = targetBackup['checksum'] as String?;
    final backupSize = targetBackup['size'] as int? ?? 0;
    final timestamp = targetBackup['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    int attempt = 1;
    while (true) {
      try {
        await _performRestoreInternal(
          userId: userId,
          targetBackup: targetBackup,
          driveApi: driveApi,
          resolvedIsLocal: resolvedIsLocal,
          isCloud: isCloud,
          totalSteps: totalSteps,
          onProgress: onProgress,
          checksum: checksum,
          backupSize: backupSize,
          timestamp: timestamp,
          stopwatch: stopwatch,
        );
        break; // Success! Exit retry loop.
      } catch (e, stackTrace) {
        debugPrint('[Restore Attempt $attempt Failed] Error: $e\n$stackTrace');
        if (attempt == 1 && isCloud) {
          debugPrint('Restore failed on attempt 1. Deleting any temp files and retrying cloud download once...');
          attempt++;
          await Future.delayed(const Duration(seconds: 1));
          continue; // Retry once
        }
        
        final userFriendlyError = _mapToUserFriendlyRestoreError(e);
        _logRestoreEvent(userId, backupSize, 0, checksum, 'FAILED: $userFriendlyError (Original: $e)');
        throw Exception(userFriendlyError);
      }
    }
  }

  String _mapToUserFriendlyRestoreError(Object error) {
    final errStr = error.toString();
    final errStrLower = errStr.toLowerCase();
    
    String mapped;
    if (error is BackupValidationException) {
      if (error.category == 'key_mismatch') {
        mapped = 'Cloud backup decryption failed. The backup encryption key is incorrect or corrupted.';
      } else if (error.category == 'incompatible_schema') {
        mapped = 'Incompatible backup: The schema version of the backup is newer than the app version. Please update Expenso.';
      } else if (error.category == 'legacy_format') {
        mapped = 'The backup is in an unencrypted legacy format and cannot be restored.';
      } else if (error.category == 'corrupted_upload' || error.category == 'wrong_file') {
        mapped = 'Cloud backup is invalid or corrupted (invalid database file).';
      } else {
        mapped = error.message;
      }
    } else if (errStrLower.contains('sqliteexception(26)') || errStrLower.contains('file is not a database')) {
      mapped = 'Cloud backup is corrupted (invalid database file).';
    } else if (errStrLower.contains('incomplete') || errStrLower.contains('zero bytes') || errStrLower.contains('empty')) {
      mapped = 'Downloaded backup is incomplete.';
    } else if (errStrLower.contains('checksum')) {
      mapped = 'Backup verification failed (checksum verification failed).';
    } else if (errStrLower.contains('integrity check failed') || errStrLower.contains('quick_check') || errStrLower.contains('integrity_check')) {
      mapped = 'Database integrity check failed.';
    } else if (errStrLower.contains('aborted') || errStrLower.contains('protect')) {
      mapped = 'Cloud restore aborted to protect your data.';
    } else {
      mapped = 'Cloud restore aborted to protect your data.';
    }
    return '$mapped (Original: $errStr)';
  }

  Future<void> _performRestoreInternal({
    required String userId,
    required Map<String, dynamic> targetBackup,
    required drive.DriveApi? driveApi,
    required bool resolvedIsLocal,
    required bool isCloud,
    required int totalSteps,
    required BackupProgressCallback? onProgress,
    required String? checksum,
    required int backupSize,
    required int timestamp,
    required Stopwatch stopwatch,
  }) async {
    final tempDir = await getTemporaryDirectory();
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    List<int> encryptedData;
    if (resolvedIsLocal) {
      final backupFilePath = targetBackup['backupFilePath'] as String;
      final file = File(backupFilePath);
      if (!await file.exists()) {
        throw Exception('Backup file does not exist locally.');
      }
      encryptedData = await file.readAsBytes();
    } else if (_isMockMode) {
      final backupFilePath = targetBackup['backupFilePath'] as String?;
      if (backupFilePath == null) throw Exception('Backup file path missing.');
      
      final simulatedBackupDir = await _getSimulatedBackupDir();
      if (!p.isWithin(simulatedBackupDir.path, backupFilePath)) {
        throw Exception('Restore verification failed: Backup file is not inside AppData folder.');
      }
      
      final file = File(backupFilePath);
      if (!await file.exists()) {
        throw Exception('Restore verification failed: Backup file does not exist.');
      }
      encryptedData = await file.readAsBytes();
    } else {
      // Step 2: Downloading (30% - only in Cloud mode)
      onProgress?.call(0.30, 2, totalSteps, 'Downloading backup...');

      if (driveApi == null) {
        throw Exception('Google Drive client is missing.');
      }
      final fileId = targetBackup['backupFileId'] as String;

      final drive.File verifiedFile;
      try {
        verifiedFile = await driveApi.files.get(
          fileId,
          $fields: 'id, parents, name, mimeType, size',
        ) as drive.File;
      } catch (e) {
        throw Exception('Restore verification failed: Backup file does not exist or is inaccessible (Error: $e).');
      }
      if (verifiedFile.parents == null || verifiedFile.parents!.isEmpty) {
        throw Exception('Restore verification failed: Backup file resides outside AppData folder.');
      }

      if (verifiedFile.mimeType != null && verifiedFile.mimeType == 'text/html') {
        throw Exception('Downloaded backup is incomplete or invalid HTML response.');
      }
      if (verifiedFile.size != null && int.parse(verifiedFile.size!) == 0) {
        throw Exception('Downloaded backup is incomplete (empty file).');
      }

      try {
        encryptedData = await _downloadFileFromGoogleDrive(fileId, driveApi);
      } catch (e) {
        await _secureStorage.saveLastRestoreStatus('DOWNLOAD FAILED');
        rethrow;
      }

      final int driveSize = verifiedFile.size != null ? int.parse(verifiedFile.size!) : 0;
      if (encryptedData.length != driveSize) {
        await _secureStorage.saveLastRestoreStatus('DOWNLOAD FAILED');
        throw Exception('RESTORE FAILED — DOWNLOAD INCOMPLETE. Expected $driveSize bytes but downloaded ${encryptedData.length} bytes.');
      }
      await _secureStorage.saveLastRestoreStatus('DOWNLOAD VERIFIED');
    }

    if (encryptedData.isEmpty) {
      throw Exception('Downloaded backup is incomplete (0 bytes).');
    }
    if (encryptedData.length >= 4 &&
        encryptedData[0] == 0x50 &&
        encryptedData[1] == 0x4B &&
        encryptedData[2] == 0x03 &&
        encryptedData[3] == 0x04) {
      throw Exception('Cloud backup is invalid or corrupted (received ZIP payload).');
    }
    try {
      final sample = utf8.decode(encryptedData.sublist(0, math.min(encryptedData.length, 100)));
      if (sample.contains('<html') || sample.contains('<!DOCTYPE html')) {
        throw Exception('Cloud backup is invalid or corrupted (received HTML page).');
      }
    } catch (_) {}
    try {
      final sample = utf8.decode(encryptedData.sublist(0, math.min(encryptedData.length, 500)));
      if (sample.trim().startsWith('{')) {
        final decoded = jsonDecode(sample);
        if (decoded is Map && (decoded.containsKey('error') || decoded.containsKey('error_description'))) {
          throw Exception('Cloud restore aborted to protect your data (Google OAuth/API error).');
        }
      }
    } catch (_) {}

    // Step 3 (or 2 if Local): Decrypting and validating
    onProgress?.call(isCloud ? 0.50 : 0.35, isCloud ? 3 : 2, totalSteps, 'Decrypting and validating database...');

    List<int> dbBytes;
    if (_isPlainSqlite(encryptedData)) {
      dbBytes = encryptedData;
    } else {
      dbBytes = await decryptAndValidateBackup(encryptedData, checksum, userId);
    }

    if (!_isPlainSqlite(dbBytes)) {
      throw Exception('Cloud backup is invalid or corrupted (invalid SQLite header).');
    }

    final dbKey = await _secureStorage.getOrCreateDatabaseKey(userId: userId);

    final tempDbFile = File(p.join(tempDir.path, 'temp_db_$timestamp.sqlite'));
    await tempDbFile.writeAsBytes(dbBytes, flush: true);

    // Step 4 (or 3 if Local): Validating database
    onProgress?.call(isCloud ? 0.70 : 0.55, isCloud ? 4 : 3, totalSteps, 'Validating database...');

    final validation = await validateDatabase(tempDbFile, runFkCheck: true);
    if (!validation.isValid) {
      try {
        await tempDbFile.delete();
      } catch (_) {}
      throw Exception('Restore validation failed: ${validation.errorMessage}');
    }

    final validatedDbBytes = await tempDbFile.readAsBytes();

    // Step 5 (or 4 if Local): Restoring database
    onProgress?.call(isCloud ? 0.85 : 0.75, isCloud ? 5 : 4, totalSteps, 'Restoring database...');

    final dbFile = await _getDatabaseFile(userId: userId);
    if (dbFile == null) {
      throw Exception('Failed to resolve local database file path.');
    }

    final finalDbBytes = await encryptDatabaseToCipher(validatedDbBytes, dbKey);

    final db = _ref.read(databaseProvider);
    await db.close();

    // Create safety copies
    final dbFileBackup = File('${dbFile.path}.backup');
    final walFileBackup = File('${dbFile.path}-wal.backup');
    final shmFileBackup = File('${dbFile.path}-shm.backup');

    if (await dbFileBackup.exists()) await dbFileBackup.delete();
    if (await walFileBackup.exists()) await walFileBackup.delete();
    if (await shmFileBackup.exists()) await shmFileBackup.delete();

    if (await dbFile.exists()) {
      await dbFile.copy(dbFileBackup.path);
    }
    final walFile = File('${dbFile.path}-wal');
    if (await walFile.exists()) {
      await walFile.copy(walFileBackup.path);
    }
    final shmFile = File('${dbFile.path}-shm');
    if (await shmFile.exists()) {
      await shmFile.copy(shmFileBackup.path);
    }

    // Delete existing live files
    if (await dbFile.exists()) await dbFile.delete();
    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();

    // Write new database
    await dbFile.writeAsBytes(finalDbBytes, flush: true);

    try {
      await tempDbFile.delete();
    } catch (_) {}

    stopwatch.stop();

    // Reopen and run post-restore validation
    _ref.invalidate(databaseProvider);
    final newDb = _ref.read(databaseProvider);

    bool postRestoreValid = false;
    String? postRestoreError;
    try {
      // Run quick query and check integrity
      final checkRes = await newDb.customSelect('PRAGMA integrity_check;').get();
      if (checkRes.isNotEmpty && checkRes.first.data.values.first == 'ok') {
        postRestoreValid = true;
      } else {
        postRestoreError = 'Post-restore integrity check failed: ${checkRes.first.data.values.first}';
      }
    } catch (e) {
      postRestoreError = 'Post-restore database open failed: $e';
    }

    if (!postRestoreValid) {
      debugPrint('[RESTORE] Post-restore check failed! Error: $postRestoreError. Initiating automatic rollback...');
      await newDb.close();

      if (await dbFile.exists()) await dbFile.delete();
      if (await walFile.exists()) await walFile.delete();
      if (await shmFile.exists()) await shmFile.delete();

      if (await dbFileBackup.exists()) {
        await dbFileBackup.rename(dbFile.path);
      }
      if (await walFileBackup.exists()) {
        await walFileBackup.rename(walFile.path);
      }
      if (await shmFileBackup.exists()) {
        await shmFileBackup.rename(shmFile.path);
      }

      _ref.invalidate(databaseProvider);
      await _secureStorage.saveLastRestoreStatus('DATABASE INTEGRITY FAILED');
      throw Exception('Restore verification failed, rolled back to original database. Error: $postRestoreError');
    }

    // Delete backups
    if (await dbFileBackup.exists()) await dbFileBackup.delete();
    if (await walFileBackup.exists()) await walFileBackup.delete();
    if (await shmFileBackup.exists()) await shmFileBackup.delete();

    // Step 6 (or 5 if Local): Recalculating balances
    onProgress?.call(isCloud ? 0.95 : 0.90, isCloud ? 6 : 5, totalSteps, 'Recalculating balances...');

    try {
      await BalanceEngine(newDb).recalculateAllBalances();
    } catch (e) {
      debugPrint('BackupService: Balance recalculation failed: $e');
      if (!_isMockMode) {
        rethrow;
      }
    }

    // Step 7 (or 6 if Local): Completed
    onProgress?.call(1.00, isCloud ? 7 : 6, totalSteps, 'Restore completed');

    await _secureStorage.saveLastLocalPlaintextDbSize(validatedDbBytes.length);
    await _secureStorage.saveLastRestoreStatus('RESTORE SUCCESSFUL');
    _logRestoreEvent(userId, backupSize, stopwatch.elapsedMilliseconds, checksum, 'SUCCESS');
  }

  // Fetch cloud backup metadata of the LATEST backup
  Future<Map<String, dynamic>?> getBackupMetadata({String? userId, drive.DriveApi? driveApi}) async {
    try {
      final uid = userId ?? _ref.read(authProvider).user?.id ?? 'unknown';
      final List<Map<String, dynamic>> backups = await listBackups(uid, driveApi: driveApi);
      if (backups.isEmpty) return null;

      final latest = backups.first;
      return {
        'last_backup_date': latest['date'] ?? DateTime.fromMillisecondsSinceEpoch(latest['timestamp']).toIso8601String(),
        'backupDate': latest['date'] ?? DateTime.fromMillisecondsSinceEpoch(latest['timestamp']).toIso8601String(),
        'backup_size': latest['size'],
        'size': latest['size'],
        'appVersion': latest['appVersion'],
        'checksum': latest['checksum'],
        'timestamp': latest['timestamp'],
      };
    } catch (e) {
      debugPrint('Failed to get backup metadata: $e');
    }
    return null;
  }

  // Retrieve rich metadata and table counts from any backup
  Future<Map<String, dynamic>> getBackupDetails(Map<String, dynamic> backup, {drive.DriveApi? driveApi}) async {
    List<int> encryptedData;
    final bool resolvedIsLocal = backup['isLocal'] as bool? ?? (backup.containsKey('backupFilePath') && !backup.containsKey('backupFileId'));

    try {
      if (resolvedIsLocal) {
        final backupFilePath = backup['backupFilePath'] as String;
        final file = File(backupFilePath);
        if (!await file.exists()) throw Exception('Backup file does not exist locally.');
        encryptedData = await file.readAsBytes();
      } else if (_isMockMode) {
        final backupFilePath = backup['backupFilePath'] as String?;
        if (backupFilePath == null) throw Exception('Backup file path missing.');
        final file = File(backupFilePath);
        encryptedData = await file.readAsBytes();
      } else {
        if (driveApi == null) {
          throw Exception('Google Drive client is missing.');
        }
        final fileId = backup['backupFileId'] ?? backup['id'] as String;
        encryptedData = await _downloadFileFromGoogleDrive(fileId, driveApi);
      }

      // Decrypt and validate the payload
      final currentUserId = _ref.read(authProvider).user?.id ?? 'unknown';
      final parsed = await _decryptAndParseBackup(encryptedData, backup['checksum'] as String?, currentUserId);
      final payloadMap = parsed['payloadMap'] as Map<String, dynamic>;
      final meta = payloadMap['metadata'] as Map<String, dynamic>? ?? {};

      // Extract metadata counts
      int accountsCount = meta['accountsCount'] as int? ?? 0;
      int transactionsCount = meta['transactionsCount'] as int? ?? 0;
      int categoriesCount = meta['categoriesCount'] as int? ?? 0;
      int budgetsCount = meta['budgetsCount'] as int? ?? 0;
      int goalsCount = meta['goalsCount'] as int? ?? 0;
      int attachmentsCount = meta['attachmentsCount'] as int? ?? 0;
      int durationMs = meta['durationMs'] as int? ?? 0;

      // Fallback: If counts are missing, query the SQLite database directly
      if (accountsCount == 0 && transactionsCount == 0) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(p.join(tempDir.path, 'temp_details_${DateTime.now().millisecondsSinceEpoch}.sqlite'));
        final dbBytes = base64Decode(payloadMap['database'] as String);
        await tempFile.writeAsBytes(dbBytes, flush: true);
        
        final currentUserId = _ref.read(authProvider).user?.id;
        final dbKey = await _secureStorage.getDatabaseKey(userId: currentUserId);
        final rawDb = raw_sql.sqlite3.open(tempFile.path);
        try {
          if (dbKey != null) {
            rawDb.execute("PRAGMA key = '$dbKey';");
          }
          
          final tablesRes = rawDb.select("SELECT name FROM sqlite_master WHERE type='table';");
          final tables = tablesRes.map((r) => r['name'] as String).toSet();
          
          if (tables.contains('accounts')) {
            accountsCount = rawDb.select('SELECT COUNT(*) FROM accounts;').first.columnAt(0) as int;
          }
          if (tables.contains('transactions')) {
            transactionsCount = rawDb.select('SELECT COUNT(*) FROM transactions;').first.columnAt(0) as int;
          }
          if (tables.contains('categories')) {
            categoriesCount = rawDb.select('SELECT COUNT(*) FROM categories;').first.columnAt(0) as int;
          }
          if (tables.contains('budgets')) {
            budgetsCount = rawDb.select('SELECT COUNT(*) FROM budgets;').first.columnAt(0) as int;
          }
          if (tables.contains('goals')) {
            goalsCount = rawDb.select('SELECT COUNT(*) FROM goals;').first.columnAt(0) as int;
          }
        } catch (e) {
          debugPrint('Error querying temp db counts: $e');
        } finally {
          rawDb.dispose();
          try {
            await tempFile.delete();
          } catch (_) {}
        }
      }

      return {
        'name': backup['name'] ?? p.basename(backup['backupFilePath'] ?? 'Backup'),
        'date': backup['date'] ?? meta['backupDate'] ?? DateTime.fromMillisecondsSinceEpoch(backup['timestamp'] ?? 0).toIso8601String(),
        'size': backup['size'] ?? meta['backupSize'] ?? encryptedData.length,
        'databaseVersion': payloadMap['databaseVersion'] ?? meta['databaseVersion'] ?? 9,
        'appVersion': meta['appVersion'] ?? '2.0.0',
        'device': meta['device'] ?? meta['deviceId'] ?? 'Unknown Device',
        'androidVersion': meta['androidVersion'] ?? Platform.operatingSystemVersion,
        'googleAccount': backup['googleAccount'] ?? meta['googleAccount'] ?? 'Not Linked',
        'encryption': 'AES-256-CBC',
        'checksum': backup['checksum'] ?? meta['checksum'] ?? sha256.convert(encryptedData).toString(),
        'accountsCount': accountsCount,
        'transactionsCount': transactionsCount,
        'categoriesCount': categoriesCount,
        'budgetsCount': budgetsCount,
        'goalsCount': goalsCount,
        'attachmentsCount': attachmentsCount,
        'durationMs': durationMs,
      };
    } catch (e) {
      debugPrint('Error getting backup details: $e');
      throw Exception('Failed to read backup details: $e');
    }
  }

  Future<List<int>> downloadLatestBackupBytes(String userId, {drive.DriveApi? driveApi}) async {
    final List<Map<String, dynamic>> backups = await listBackups(userId, driveApi: driveApi);
    if (backups.isEmpty) {
      throw Exception('No backup found in Google Drive appDataFolder.');
    }
    
    final latest = backups.first;
    if (_isMockMode) {
      final backupFile = File(latest['backupFilePath'] as String);
      return await backupFile.readAsBytes();
    } else {
      if (driveApi == null) {
        throw Exception('Google Drive client is missing.');
      }
      return await _downloadFileFromGoogleDrive(latest['backupFileId'] as String, driveApi);
    }
  }

  // Deletes all backups
  Future<void> deleteBackup({String? userId, drive.DriveApi? driveApi}) async {
    try {
      final uid = userId ?? _ref.read(authProvider).user?.id ?? 'unknown';
      final List<Map<String, dynamic>> backups = await listBackups(uid, driveApi: driveApi);
      for (var backup in backups) {
        await deleteSingleBackupFile(backup, driveApi);
      }
    } catch (e) {
      throw Exception(getReadableError(e));
    }
  }

  Future<String> validateDatabaseBackup(File file) async {
    final int actualSize = await file.length();
    if (actualSize < 100) {
      return 'FILE SIZE: $actualSize\nSQLITE HEADER: invalid\nPAGE SIZE: 0\nPAGE COUNT: 0\nEXPECTED SIZE: 0\nACTUAL SIZE: $actualSize\nSIZE VALID: FALSE\nSQLITE OPEN: FALSE\nINTEGRITY CHECK: failed';
    }

    final bytes = await file.readAsBytes();
    final bool sqliteHeaderValid = bytes.length >= 15 && String.fromCharCodes(bytes.sublist(0, 15)) == 'SQLite format 3';
    
    final int pageSize = (bytes[16] << 8) | bytes[17];
    final int pageCount = (bytes[28] << 24) | (bytes[29] << 16) | (bytes[30] << 8) | bytes[31];
    final int expectedSize = pageSize * pageCount;
    final bool sizeValid = pageCount > 0 ? (actualSize >= expectedSize) : true;

    if (Platform.isAndroid) {
      try {
        open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
      } catch (_) {}
    }

    bool canOpen = false;
    String integrityCheck = 'failed';
    try {
      final db = raw_sql.sqlite3.open(file.path);
      try {
        canOpen = true;
        final res = db.select('PRAGMA integrity_check;');
        if (res.isNotEmpty) {
          integrityCheck = res.first.columnAt(0) as String;
        }
      } finally {
        db.dispose();
      }
    } catch (e) {
      integrityCheck = e.toString();
    }

    return 'FILE SIZE: $actualSize\n'
           'SQLITE HEADER: ${sqliteHeaderValid ? "valid" : "invalid"}\n'
           'PAGE SIZE: $pageSize\n'
           'PAGE COUNT: $pageCount\n'
           'EXPECTED SIZE: $expectedSize\n'
           'ACTUAL SIZE: $actualSize\n'
           'SIZE VALID: ${sizeValid ? "TRUE" : "FALSE"}\n'
           'SQLITE OPEN: ${canOpen ? "TRUE" : "FALSE"}\n'
           'INTEGRITY CHECK: $integrityCheck';
  }

  // --- Real Google Drive SDK Helper Operations ---

  Future<drive.File> _uploadBytesToGoogleDrive(List<int> bytes, String filename, drive.DriveApi driveApi) async {
    // 1. Clear out pre-existing file with identical name to prevent duplicate entries
    try {
      final existingRes = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "'appDataFolder' in parents and name = '$filename'",
        $fields: 'files(id)',
      );
      final files = existingRes.files ?? [];
      for (var f in files) {
        final fileId = f.id;
        if (fileId != null) {
          await driveApi.files.delete(fileId);
        }
      }
    } catch (e) {
      debugPrint('BackupService: Error checking or cleaning up existing file: $e');
    }

    // 2. Perform upload to appDataFolder using official SDK
    final file = drive.File()
      ..name = filename
      ..parents = ['appDataFolder'];

    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
    );

    return await driveApi.files.create(
      file,
      uploadMedia: media,
    ) as drive.File;
  }

  Future<List<int>> _downloadFileFromGoogleDrive(String fileId, drive.DriveApi driveApi) async {
    final response = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (response is drive.Media) {
      final builder = BytesBuilder();
      await for (final chunk in response.stream) {
        builder.add(chunk);
      }
      return builder.toBytes();
    }
    throw Exception('Failed to download file from Google Drive: response is not a Media object');
  }

  Future<String> _formatFkViolations(AppDatabase db, List<QueryRow> fkRows) async {
    final StringBuffer buffer = StringBuffer();
    for (var row in fkRows) {
      final childTable = row.read<String>('table');
      final rowId = row.read<int>('rowid');
      final parentTable = row.read<String>('parent');
      final fkid = row.read<int>('fkid');

      String fromCol = 'Unknown';
      String missingVal = 'Unknown';
      try {
        final fkList = await db.customSelect('PRAGMA foreign_key_list($childTable);').get();
        final match = fkList.firstWhere((item) => item.read<int>('id') == fkid);
        fromCol = match.read<String>('from');

        final childRow = await db.customSelect('SELECT $fromCol FROM $childTable WHERE rowid = ?;', variables: [Variable<int>(rowId)]).get();
        if (childRow.isNotEmpty) {
          missingVal = childRow.first.data.values.first?.toString() ?? 'null';
        }
      } catch (e) {
        debugPrint('Error resolving foreign key column/value: $e');
      }

      buffer.writeln(' - Child: $childTable (rowid: $rowId), Parent: $parentTable, Missing Parent Key ($fromCol): $missingVal');
    }
    return buffer.toString();
  }

  // --- Utility logging and error formatting helpers ---

  void _logBackupEvent(String userId, int size, int durationMs, String checksum, String status) {
    String googleAccount = 'Unknown';
    try {
      googleAccount = FirebaseAuth.instance.currentUser?.email ?? 'Offline/Mock';
    } catch (_) {}
    debugPrint('BACKUP EVENT LOG:');
    debugPrint(' - Google Account: $googleAccount');
    debugPrint(' - Firebase UID: $userId');
    debugPrint(' - Backup Time: ${DateTime.now().toIso8601String()}');
    debugPrint(' - File Size: $size bytes');
    debugPrint(' - Upload Duration: $durationMs ms');
    debugPrint(' - Checksum: $checksum');
    debugPrint(' - Backup Result: $status');
  }

  void _logRestoreEvent(String userId, int size, int durationMs, String? checksum, String status) {
    String googleAccount = 'Unknown';
    try {
      googleAccount = FirebaseAuth.instance.currentUser?.email ?? 'Offline/Mock';
    } catch (_) {}
    debugPrint('RESTORE EVENT LOG:');
    debugPrint(' - Google Account: $googleAccount');
    debugPrint(' - Firebase UID: $userId');
    debugPrint(' - Restore Time: ${DateTime.now().toIso8601String()}');
    debugPrint(' - File Size: $size bytes');
    debugPrint(' - Download Duration: $durationMs ms');
    debugPrint(' - Checksum: ${checksum ?? "N/A"}');
    debugPrint(' - SQLite Validation Result: ${status == "SUCCESS" ? "VALID" : "INVALID"}');
    debugPrint(' - Restore Result: $status');
  }

  String getReadableError(Object error) {
    if (error is drive.DetailedApiRequestError) {
      final statusCode = error.status;
      final message = error.message ?? 'No error message provided';
      String suffix = '';
      if (statusCode == 401) {
        suffix = ' (401 Unauthorized)';
      } else if (statusCode == 403) {
        suffix = ' (403 Insufficient Permission)';
      } else if (statusCode == 404) {
        suffix = ' (404 AppData Folder Missing / Not Found)';
      } else if (statusCode == 429) {
        suffix = ' (429 Rate Limit Exceeded)';
      } else if (statusCode != null && statusCode >= 500) {
        suffix = ' ($statusCode Internal Server Error)';
      }
      return 'DetailedApiRequestError [Status $statusCode]: $message$suffix';
    }
    if (error is drive.ApiRequestError) {
      return 'ApiRequestError: ${error.message}';
    }
    var errStr = error.toString();
    if (errStr.startsWith('Exception: ')) {
      errStr = errStr.substring(11);
    }
    final errStrLower = errStr.toLowerCase();
    if (errStrLower.contains('socketexception') || errStrLower.contains('failed host lookup')) {
      return 'Network connection failed.';
    }
    if (errStrLower.contains('timeoutexception') || errStrLower.contains('timeout')) {
      return 'Connection timed out.';
    }
    return errStr;
  }

  Future<List<Map<String, dynamic>>> listAllAppDataFiles(drive.DriveApi driveApi) async {
    try {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "'appDataFolder' in parents",
        $fields: 'files(id, name, size, createdTime, modifiedTime, appProperties, mimeType)',
      );
      final files = fileList.files ?? [];
      final List<Map<String, dynamic>> list = [];
      for (var file in files) {
        final props = file.appProperties ?? {};
        final isVerified = props['verified'] == 'true';
        list.add({
          'id': file.id ?? 'Unknown',
          'name': file.name ?? 'Unknown',
          'size': int.tryParse(file.size ?? '0') ?? 0,
          'createdTime': file.createdTime,
          'modifiedTime': file.modifiedTime,
          'checksum': props['checksum'] ?? 'N/A',
          'verified': isVerified,
          'mimeType': file.mimeType ?? 'application/octet-stream',
          'status': isVerified ? 'Verified' : 'Unverified',
        });
      }
      return list;
    } catch (e) {
      debugPrint('BackupService: Error listing all AppData files: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listAllSimulatedAppDataFiles() async {
    final simulatedBackupDir = await _getSimulatedBackupDir();
    final List<Map<String, dynamic>> list = [];
    if (!await simulatedBackupDir.exists()) return list;

    final files = simulatedBackupDir.listSync();
    for (var entity in files) {
      if (entity is File) {
        final stat = await entity.stat();
        final baseName = p.basename(entity.path);
        
        bool verified = false;
        String checksum = 'N/A';
        
        if (baseName.endsWith('.json')) {
          try {
            final content = await entity.readAsString();
            final meta = jsonDecode(content) as Map<String, dynamic>;
            verified = meta['verified'] == 'true';
            checksum = meta['checksum'] ?? 'N/A';
          } catch (_) {}
        } else if (baseName.endsWith('.enc')) {
          final tsStr = baseName.replaceAll('expenso_backup_', '').replaceAll('.enc', '');
          final metaFile = File(p.join(simulatedBackupDir.path, 'metadata_$tsStr.json'));
          if (await metaFile.exists()) {
            try {
              final content = await metaFile.readAsString();
              final meta = jsonDecode(content) as Map<String, dynamic>;
              verified = meta['verified'] == 'true';
              checksum = meta['checksum'] ?? 'N/A';
            } catch (_) {}
          }
        }

        list.add({
          'id': entity.path,
          'name': baseName,
          'size': stat.size,
          'createdTime': stat.changed,
          'modifiedTime': stat.modified,
          'checksum': checksum,
          'verified': verified,
          'mimeType': baseName.endsWith('.json') ? 'application/json' : 'application/octet-stream',
          'status': verified ? 'Verified' : 'Unverified',
        });
      }
    }
    list.sort((a, b) {
      final aTime = a['modifiedTime'] as DateTime;
      final bTime = b['modifiedTime'] as DateTime;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  Future<Map<String, dynamic>> verifyBackupFileOnDemand({
    String? fileId,
    String? filePath,
    drive.DriveApi? driveApi,
  }) async {
    try {
      final auth = _ref.read(authProvider);
      final userId = auth.user?.id ?? FirebaseAuth.instance.currentUser?.uid ?? 'Offline';

      if (_isMockMode || filePath != null) {
        final path = filePath ?? fileId;
        if (path == null) throw Exception('Path is required for simulated verification.');
        final file = File(path);
        if (!await file.exists()) {
          throw Exception('Simulated backup file not found.');
        }
        final bytes = await file.readAsBytes();
        final checksum = sha256.convert(bytes).toString();

        // Deep validation: decrypt and validate SQLite & Drift connection
        final tempDir = await getTemporaryDirectory();
        final decryptedBytes = await decryptAndValidateBackup(bytes, checksum, userId);
        final tempValFile = File(p.join(tempDir.path, 'temp_val_ondemand_simulated_${DateTime.now().millisecondsSinceEpoch}.sqlite'));
        await tempValFile.writeAsBytes(decryptedBytes, flush: true);
        final verification = await validateDatabase(tempValFile);
        try {
          await tempValFile.delete();
        } catch (_) {}

        if (!verification.isValid) {
          throw Exception('Decrypted database is invalid. Error: ${verification.errorMessage}');
        }

        // Try to update metadata json file
        final baseName = p.basename(path);
        String tsStr = '';
        if (baseName.startsWith('expenso_backup_')) {
          tsStr = baseName.replaceAll('expenso_backup_', '').replaceAll('.enc', '');
        } else if (baseName.startsWith('metadata_')) {
          tsStr = baseName.replaceAll('metadata_', '').replaceAll('.json', '');
        }
        
        if (tsStr.isNotEmpty) {
          final simulatedBackupDir = await _getSimulatedBackupDir();
          final metaFile = File(p.join(simulatedBackupDir.path, 'metadata_$tsStr.json'));
          if (await metaFile.exists()) {
            final content = await metaFile.readAsString();
            final meta = Map<String, dynamic>.from(jsonDecode(content));
            if (meta['checksum'] != checksum) {
              throw Exception('Checksum mismatch: computed $checksum vs stored ${meta['checksum']}');
            }
            meta['verified'] = 'true';
            await metaFile.writeAsBytes(utf8.encode(jsonEncode(meta)), flush: true);
          }
        }
        return {'status': 'Verified', 'checksum': checksum};
      } else {
        if (driveApi == null) throw Exception('Google Drive client is missing.');
        if (fileId == null) throw Exception('File ID is required.');

        // 1. Search file
        final drive.File file;
        try {
          file = await driveApi.files.get(
            fileId,
            $fields: 'id, name, mimeType, size, parents, appProperties',
          ) as drive.File;
        } catch (e) {
          throw Exception('File not found in AppData (Error: $e).');
        }

        // 2. Download bytes
        final downloadResponse = await driveApi.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        );
        if (downloadResponse is! drive.Media) {
          throw Exception('Response is not a Media object');
        }

        final builder = BytesBuilder();
        await for (final chunk in downloadResponse.stream) {
          builder.add(chunk);
        }
        final downloadedBytes = builder.toBytes();

        // 3. Verify checksum
        final computedChecksum = sha256.convert(downloadedBytes).toString();
        final storedChecksum = file.appProperties?['checksum'];
        if (storedChecksum != null && computedChecksum != storedChecksum) {
          throw Exception('Checksum mismatch: computed $computedChecksum vs stored $storedChecksum');
        }

        // 3.5. Decrypt and validate SQLite & Drift connection
        final tempDir = await getTemporaryDirectory();
        final decryptedBytes = await decryptAndValidateBackup(downloadedBytes, computedChecksum, userId);
        final tempValFile = File(p.join(tempDir.path, 'temp_val_ondemand_drive_${DateTime.now().millisecondsSinceEpoch}.sqlite'));
        await tempValFile.writeAsBytes(decryptedBytes, flush: true);
        final verification = await validateDatabase(tempValFile);
        try {
          await tempValFile.delete();
        } catch (_) {}

        if (!verification.isValid) {
          throw Exception('Decrypted database is invalid. Error: ${verification.errorMessage}');
        }

        // 4. Update verified status
        final patchFile = drive.File()
          ..appProperties = {
            ...?file.appProperties,
            'verified': 'true',
          };
        await driveApi.files.update(patchFile, fileId);

        return {'status': 'Verified', 'checksum': computedChecksum};
      }
    } catch (e) {
      debugPrint('BackupService: On-demand verification failed: $e');
      return {'status': 'Corrupted', 'error': getReadableError(e)};
    }
  }
}

// Provider definition
final Provider<BackupService> backupServiceProvider = Provider<BackupService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return BackupService(ref, secureStorage);
});
