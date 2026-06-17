import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../security/secure_storage_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class BackupService {
  final Ref _ref;
  final SecureStorageService _secureStorage;

  BackupService(this._ref, this._secureStorage);

  // Checks whether the user is logged in using a mock token
  bool get _isMockMode {
    final authState = _ref.read(authProvider);
    final googleId = authState.user?.googleId;
    if (googleId == null) return true;
    return googleId.startsWith('mock-') || googleId == 'google-id-token';
  }

  // Locates the database file path
  Future<File?> _getDatabaseFile() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file1 = File(p.join(docDir.path, 'expenso_database.sqlite'));
      if (await file1.exists()) return file1;

      final supportDir = await getApplicationSupportDirectory();
      final file2 = File(p.join(supportDir.path, 'expenso_database.sqlite'));
      if (await file2.exists()) return file2;

      final file3 = File(p.join(docDir.path, 'expenso_database'));
      if (await file3.exists()) return file3;

      final file4 = File(p.join(supportDir.path, 'expenso_database'));
      if (await file4.exists()) return file4;
    } catch (e) {
      debugPrint('Error locating database file: $e');
    }
    return null;
  }

  // Retrieves or generates the 256-bit AES master key
  Future<enc.Key> _getOrCreateEncryptionKey() async {
    String? base64Key = await _secureStorage.getBackupEncryptionKey();
    if (base64Key == null) {
      final newKey = enc.Key.fromSecureRandom(32);
      await _secureStorage.saveBackupEncryptionKey(newKey.base64);
      return newKey;
    }
    return enc.Key.fromBase64(base64Key);
  }

  // Encrypts database bytes and forms backup JSON
  Future<List<int>> _encryptDatabase(List<int> dbBytes, String userId) async {
    final key = await _getOrCreateEncryptionKey();
    
    // Package into JSON metadata
    final dbBase64 = base64Encode(dbBytes);
    final payloadMap = {
      'database': dbBase64,
      'version': '1.0',
      'metadata': {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'deviceId': 'flutter-device',
        'backupSize': dbBytes.length,
        'userId': userId,
      }
    };
    
    final payloadString = jsonEncode(payloadMap);
    final payloadBytes = utf8.encode(payloadString);

    // AES encryption
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(payloadBytes, iv: iv);

    // Prepend IV (16 bytes) to the encrypted payload
    final output = BytesBuilder()
      ..add(iv.bytes)
      ..add(encrypted.bytes);
    
    return output.toBytes();
  }

  // Decrypts the backup bytes and returns the SQLite database file bytes
  Future<List<int>> _decryptDatabase(List<int> encryptedBytes) async {
    if (encryptedBytes.length <= 16) {
      throw Exception('Invalid encrypted backup payload: too short');
    }

    final key = await _getOrCreateEncryptionKey();
    
    // Extract IV (first 16 bytes) and ciphertext
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
    return base64Decode(dbBase64);
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

  // Performs a backup. Returns size of backup in bytes
  Future<int> backup(String userId, {String? googleAccessToken}) async {
    final dbFile = await _getDatabaseFile();
    if (dbFile == null) {
      throw Exception('Database file not found on disk. Please create some transactions first.');
    }

    final dbBytes = await dbFile.readAsBytes();
    final encryptedData = await _encryptDatabase(dbBytes, userId);

    if (_isMockMode) {
      // 1. Simulated Cloud Mode
      final backupDir = await _getSimulatedBackupDir();
      final backupFile = File(p.join(backupDir.path, 'expenso_backup_v1.enc'));
      await backupFile.writeAsBytes(encryptedData);

      // Write separate metadata file for fast query
      final metaFile = File(p.join(backupDir.path, 'expenso_backup_metadata.json'));
      final metadata = {
        'last_backup_date': DateTime.now().toIso8601String(),
        'backup_size': encryptedData.length,
      };
      await metaFile.writeAsString(jsonEncode(metadata));
      
      return encryptedData.length;
    } else {
      // 2. Real Google Drive Integration
      if (googleAccessToken == null) {
        throw Exception('Google Access Token is missing for real drive sync.');
      }
      return await _uploadToGoogleDrive(encryptedData, googleAccessToken);
    }
  }

  // Restores a backup. Closes the DB, overwrites the SQLite file, and reopens it.
  Future<void> restore(String userId, {String? googleAccessToken}) async {
    List<int> encryptedData;

    if (_isMockMode) {
      // 1. Simulated Cloud Mode
      final backupDir = await _getSimulatedBackupDir();
      final backupFile = File(p.join(backupDir.path, 'expenso_backup_v1.enc'));
      if (!await backupFile.exists()) {
        throw Exception('No backup file found in simulated cloud storage.');
      }
      encryptedData = await backupFile.readAsBytes();
    } else {
      // 2. Real Google Drive Integration
      if (googleAccessToken == null) {
        throw Exception('Google Access Token is missing for real drive sync.');
      }
      encryptedData = await _downloadFromGoogleDrive(googleAccessToken);
    }

    final dbBytes = await _decryptDatabase(encryptedData);

    // Safely overwrite SQLite file
    final dbFile = await _getDatabaseFile();
    if (dbFile == null) {
      throw Exception('Failed to resolve local database file path for restoration.');
    }

    // 1. Close current database connection
    final db = _ref.read(databaseProvider);
    await db.close();

    // 2. Write decrypted bytes to SQLite database file
    await dbFile.writeAsBytes(dbBytes, flush: true);

    // 3. Force Riverpod to recreate AppDatabase with fresh connection
    _ref.invalidate(databaseProvider);
  }

  // Fetch simulated cloud backup metadata
  Future<Map<String, dynamic>?> getBackupMetadata({String? googleAccessToken}) async {
    if (_isMockMode) {
      final backupDir = await _getSimulatedBackupDir();
      final metaFile = File(p.join(backupDir.path, 'expenso_backup_metadata.json'));
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
      return null;
    } else {
      if (googleAccessToken == null) return null;
      try {
        final dio = Dio();
        final response = await dio.get(
          'https://www.googleapis.com/drive/v3/files',
          queryParameters: {
            'spaces': 'appDataFolder',
            'q': "name = 'expenso_backup_v1.enc'",
            'fields': 'files(id, name, size, modifiedTime)',
          },
          options: Options(headers: {
            'Authorization': 'Bearer $googleAccessToken',
          }),
        );
        final files = response.data['files'] as List;
        if (files.isNotEmpty) {
          final file = files.first;
          return {
            'last_backup_date': file['modifiedTime'],
            'backup_size': int.tryParse(file['size']?.toString() ?? '0') ?? 0,
            'file_id': file['id'],
          };
        }
      } catch (e) {
        debugPrint('Failed to fetch Google Drive backup metadata: $e');
      }
      return null;
    }
  }

  // Deletes the backup file
  Future<void> deleteBackup({String? googleAccessToken}) async {
    if (_isMockMode) {
      final backupDir = await _getSimulatedBackupDir();
      final backupFile = File(p.join(backupDir.path, 'expenso_backup_v1.enc'));
      final metaFile = File(p.join(backupDir.path, 'expenso_backup_metadata.json'));
      if (await backupFile.exists()) await backupFile.delete();
      if (await metaFile.exists()) await metaFile.delete();
    } else {
      if (googleAccessToken == null) return;
      final meta = await getBackupMetadata(googleAccessToken: googleAccessToken);
      final fileId = meta?['file_id'] as String?;
      if (fileId != null) {
        final dio = Dio();
        await dio.delete(
          'https://www.googleapis.com/drive/v3/files/$fileId',
          options: Options(headers: {
            'Authorization': 'Bearer $googleAccessToken',
          }),
        );
      }
    }
  }

  // --- Real Google Drive API Helper Operations ---

  Future<int> _uploadToGoogleDrive(List<int> bytes, String token) async {
    final dio = Dio();
    
    // Check if file already exists to update it, or create a new one
    final meta = await getBackupMetadata(googleAccessToken: token);
    final existingFileId = meta?['file_id'] as String?;

    if (existingFileId != null) {
      // Update existing backup file content
      await dio.patch(
        'https://www.googleapis.com/upload/drive/v3/files/$existingFileId?uploadType=media',
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/octet-stream',
          },
        ),
      );
      return bytes.length;
    } else {
      // Create new backup file using multipart upload
      const boundary = 'expenso_multipart_boundary';
      final metadataJson = jsonEncode({
        'name': 'expenso_backup_v1.enc',
        'parents': ['appDataFolder'],
      });

      final multipartBody = BytesBuilder();
      multipartBody.add(utf8.encode('--$boundary\r\n'));
      multipartBody.add(utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'));
      multipartBody.add(utf8.encode('$metadataJson\r\n'));
      multipartBody.add(utf8.encode('--$boundary\r\n'));
      multipartBody.add(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'));
      multipartBody.add(bytes);
      multipartBody.add(utf8.encode('\r\n--$boundary--\r\n'));

      await dio.post(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
        data: Stream.fromIterable([multipartBody.toBytes()]),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
        ),
      );
      return bytes.length;
    }
  }

  Future<List<int>> _downloadFromGoogleDrive(String token) async {
    final meta = await getBackupMetadata(googleAccessToken: token);
    final fileId = meta?['file_id'] as String?;
    if (fileId == null) {
      throw Exception('No backup file found in Google Drive appDataFolder.');
    }

    final dio = Dio();
    final response = await dio.get<ResponseBody>(
      'https://www.googleapis.com/drive/v3/files/$fileId',
      queryParameters: {'alt': 'media'},
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final builder = BytesBuilder();
      await for (final chunk in response.data!.stream) {
        builder.add(chunk);
      }
      return builder.toBytes();
    }
    throw Exception('Failed to download backup: HTTP ${response.statusCode}');
  }
}

// Provider definition
final Provider<BackupService> backupServiceProvider = Provider<BackupService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return BackupService(ref, secureStorage);
});
