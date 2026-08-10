import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as enc;
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import '../../security/secure_storage_service.dart';

bool _isValidSqliteHeader(List<int> bytes) {
  if (bytes.length < 15) return false;
  final header = String.fromCharCodes(bytes.sublist(0, 15));
  return header == 'SQLite format 3';
}

Future<bool> _isValidSqliteFile(File file, String key) async {
  if (!await file.exists()) return false;
  try {
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }
    final db = sqlite3.open(file.path);
    try {
      db.execute("PRAGMA key = '$key';");
      // Execute a quick statement to verify decryption works
      db.execute("SELECT count(*) FROM sqlite_schema;");
      return true;
    } finally {
      db.dispose();
    }
  } catch (e) {
    debugPrint("SQLite Validation Error for file: $e");
    return false;
  }
}

Future<bool> _isValidDatabaseBytes(List<int> bytes, String key) async {
  if (bytes.length < 15) return false;
  
  // Try checking plain sqlite header first (for tests/migration)
  if (_isValidSqliteHeader(bytes)) return true;
  
  // Otherwise try opening it as a database file using a temp file
  final tempDir = await getTemporaryDirectory();
  final tempFile = File(p.join(tempDir.path, 'temp_validate_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
  try {
    await tempFile.writeAsBytes(bytes, flush: true);
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }
    final db = sqlite3.open(tempFile.path);
    try {
      db.execute("PRAGMA key = '$key';");
      db.execute("SELECT count(*) FROM sqlite_schema;");
      return true;
    } finally {
      db.dispose();
    }
  } catch (_) {
    return false;
  } finally {
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }
}

Future<List<int>?> _decryptBackupBytes(File backupFile, SecureStorageService secureStorage, {String? userId}) async {
  try {
    final encryptedBytes = await backupFile.readAsBytes();
    if (encryptedBytes.length <= 16) return null;

    String? base64Key;
    if (userId != null) {
      base64Key = await secureStorage.getBackupEncryptionKey(userId: userId);
    }
    base64Key ??= await secureStorage.getBackupEncryptionKey();
    if (base64Key == null && userId != 'Offline') {
      base64Key = await secureStorage.getBackupEncryptionKey(userId: 'Offline');
    }

    if (base64Key == null) return null;

    final key = enc.Key.fromBase64(base64Key);
    final ivBytes = encryptedBytes.sublist(0, 16);
    final cipherBytes = encryptedBytes.sublist(16);

    final iv = enc.IV(Uint8List.fromList(ivBytes));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final decryptedBytes = encrypter.decryptBytes(
      enc.Encrypted(Uint8List.fromList(cipherBytes)),
      iv: iv,
    );

    final payloadString = utf8.decode(decryptedBytes);
    final payloadMap = jsonDecode(payloadString) as Map<String, dynamic>;
    final dbBase64 = payloadMap['database'] as String;
    final decodedBytes = base64Decode(dbBase64);
    if (decodedBytes.length >= 2 && decodedBytes[0] == 0x1F && decodedBytes[1] == 0x8B) {
      return gzip.decode(decodedBytes);
    } else {
      return decodedBytes;
    }
  } catch (e) {
    debugPrint('Failed to decrypt backup bytes: $e');
    return null;
  }
}

Future<List<int>> _encryptPlainDatabaseToCipher(List<int> plainBytes, String key) async {
  if (Platform.isAndroid) {
    try {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    } catch (_) {}
  }

  final tempDir = await getTemporaryDirectory();
  final tempPlainFile = File(p.join(tempDir.path, 'temp_plain_to_enc_startup_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
  await tempPlainFile.writeAsBytes(plainBytes, flush: true);

  final db = sqlite3.open(tempPlainFile.path);
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

  final tempCipherFile = File(p.join(tempDir.path, 'temp_cipher_to_enc_startup_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
  final dbPlain = sqlite3.open(tempPlainFile.path);
  try {
    dbPlain.execute("ATTACH DATABASE '${tempCipherFile.path}' AS encrypted KEY '$key';");
    try {
      dbPlain.execute("SELECT sqlcipher_export('encrypted');");
    } finally {
      dbPlain.execute("DETACH DATABASE encrypted;");
    }

    if (tempCipherFile.existsSync()) {
      final cipherBytes = await tempCipherFile.readAsBytes();
      return cipherBytes;
    } else {
      throw Exception('SQLCipher export failed to encrypt database.');
    }
  } finally {
    dbPlain.dispose();
    try {
      await tempPlainFile.delete();
    } catch (_) {}
    if (tempCipherFile.existsSync()) {
      try {
        await tempCipherFile.delete();
      } catch (_) {}
    }
  }
}

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }

    final supportDir = await getApplicationSupportDirectory();
    final secureStorage = SecureStorageService();
    final userId = await secureStorage.getUserId();
    final dbName = userId != null ? 'expenso_database_$userId.sqlite' : 'expenso_database.sqlite';
    final file = File(p.join(supportDir.path, dbName));

    // Resolve key from secure storage deterministically using resolved user ID
    final resolvedUserId = userId ?? 'default_offline_user';
    final key = await secureStorage.getOrCreateDatabaseKey(userId: resolvedUserId);

    final docDir = await getApplicationDocumentsDirectory();
    final localBackupDir = Directory(p.join(docDir.path, 'Backups'));
    File? backupFile;
    if (await localBackupDir.exists()) {
      final files = localBackupDir.listSync();
      final backupFiles = <File>[];
      for (var f in files) {
        if (f is File && p.basename(f.path).startsWith('Expenso_Backup_') && f.path.endsWith('.expbk')) {
          backupFiles.add(f);
        }
      }
      if (backupFiles.isNotEmpty) {
        backupFiles.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
        backupFile = backupFiles.first;
      }
    }

    if (backupFile == null) {
      final backupDir = Directory(p.join(docDir.path, 'expenso_backup_simulated'));
      if (await backupDir.exists()) {
        final files = backupDir.listSync();
        final backupFiles = <File>[];
        for (var f in files) {
          if (f is File && p.basename(f.path).startsWith('expenso_backup_') && f.path.endsWith('.enc')) {
            backupFiles.add(f);
          }
        }
        if (backupFiles.isNotEmpty) {
          backupFiles.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
          backupFile = backupFiles.first;
        }
      }
    }

    final fileExists = await file.exists();
    bool isValid = false;

    if (fileExists) {
      isValid = await _isValidSqliteFile(file, key);
      final size = await file.length();
      debugPrint('DATABASE STARTUP LOG:');
      debugPrint(' - Database path: ${file.path}');
      debugPrint(' - Database size: $size bytes');
      debugPrint(' - Validation status: ${isValid ? "VALID" : "INVALID/CORRUPTED"}');

      if (!isValid) {
        debugPrint('CRITICAL: Database file is invalid or corrupted! Initiating recovery flow...');
        final corruptedPath = '${file.path}.corrupted';
        final corruptedFile = File(corruptedPath);
        if (await corruptedFile.exists()) {
          await corruptedFile.delete();
        }
        await file.rename(corruptedPath);
        debugPrint('Renamed corrupted database to: $corruptedPath');

        final corruptedWal = File('${file.path}-wal');
        if (await corruptedWal.exists()) {
          try {
            await corruptedWal.delete();
          } catch (_) {}
        }
        final corruptedShm = File('${file.path}-shm');
        if (await corruptedShm.exists()) {
          try {
            await corruptedShm.delete();
          } catch (_) {}
        }

        // Try to restore from backup
        if (backupFile != null && await backupFile.exists()) {
          final backupSize = await backupFile.length();
          debugPrint('Found backup file:');
          debugPrint(' - Backup path: ${backupFile.path}');
          debugPrint(' - Backup size: $backupSize bytes');
          
          final restoredBytes = await _decryptBackupBytes(backupFile, secureStorage, userId: resolvedUserId);
          if (restoredBytes != null && await _isValidDatabaseBytes(restoredBytes, key)) {
            final cipherBytes = await _encryptPlainDatabaseToCipher(restoredBytes, key);
            await file.writeAsBytes(cipherBytes, flush: true);
            debugPrint(' - SQLite validation result on backup: VALID');
            debugPrint('Recovery successful: Restored last valid backup to production database.');
          } else {
            debugPrint(' - SQLite validation result on backup: INVALID');
            debugPrint('Recovery failed: Backup file is invalid or decryption failed.');
          }
        } else {
          debugPrint('Recovery status: No backup file found. Starting fresh database.');
        }
      }
    } else {
      debugPrint('DATABASE STARTUP LOG: Database file does not exist at ${file.path}. Drift will create a new one.');
    }

    return NativeDatabase(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$key';");
      },
    );
  });
}
