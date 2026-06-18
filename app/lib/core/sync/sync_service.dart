import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:dio/dio.dart';

import '../database/app_database.dart';
import '../sync/backup_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class SyncConflict {
  final Transaction local;
  final Transaction remote;

  SyncConflict({
    required this.local,
    required this.remote,
  });
}

class SyncResult {
  final List<SyncConflict> conflicts;
  final int insertedCount;
  final int updatedCount;

  SyncResult({
    required this.conflicts,
    required this.insertedCount,
    required this.updatedCount,
  });
}

class SyncService {
  final Ref _ref;
  final BackupService _backupService;

  SyncService(this._ref, this._backupService);

  // Perform a bidirectional sync of local database with Google Drive backup.
  // Returns conflicts that need manual user resolution.
  Future<SyncResult> sync(String userId, {String? googleAccessToken}) async {
    final metadata = await _backupService.getBackupMetadata(googleAccessToken: googleAccessToken);
    if (metadata == null) {
      // No cloud backup exists yet. We perform a backup now to establish the initial cloud copy.
      final size = await _backupService.backup(userId, googleAccessToken: googleAccessToken);
      debugPrint('SyncService: No remote backup found. Created initial backup of size $size bytes.');
      return SyncResult(conflicts: [], insertedCount: 0, updatedCount: 0);
    }

    // 1. Download the remote database file to a temporary location
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'remote_sync_${DateTime.now().millisecondsSinceEpoch}.sqlite'));

    // Download logic
    List<int> encryptedData;
    final isMock = googleAccessToken == null || googleAccessToken.startsWith('mock-') || googleAccessToken == 'google-id-token';
    
    if (isMock) {
      // Retrieve from simulated local backup path
      final docDir = await getApplicationDocumentsDirectory();
      final backupFile = File(p.join(docDir.path, 'expenso_backup_simulated', 'expenso_backup_v1.enc'));
      if (!await backupFile.exists()) {
        // Fallback to uploading
        await _backupService.backup(userId, googleAccessToken: googleAccessToken);
        return SyncResult(conflicts: [], insertedCount: 0, updatedCount: 0);
      }
      encryptedData = await backupFile.readAsBytes();
    } else {
      // Downloader method from Google Drive (accessed indirectly by invoking restore's download logic)
      // We can invoke _backupService restore or download
      // Since _downloadFromGoogleDrive is private in BackupService, we can read it using a custom HTTP request 
      // or we can invoke a reflection of it. But wait, BackupService has:
      // Future<void> restore(String userId, {String? googleAccessToken})
      // If we don't want to overwrite local DB during download, we can expose a download function or 
      // replicate the download logic.
      // Replicating download from backup service is extremely simple:
      final fileId = metadata['file_id'] as String;
      final dio = Dio();
      final response = await dio.get<ResponseBody>(
        'https://www.googleapis.com/drive/v3/files/$fileId',
        queryParameters: {'alt': 'media'},
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Authorization': 'Bearer $googleAccessToken'},
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final builder = BytesBuilder();
        await for (final chunk in response.data!.stream) {
          builder.add(chunk);
        }
        encryptedData = builder.toBytes();
      } else {
        throw Exception('Failed to download sync database: HTTP ${response.statusCode}');
      }
    }

    // Decrypt the remote database bytes
    // Since _decryptDatabase is private in BackupService, let's extract the decryption logic:
    // It reads the key from secure storage, gets the first 16 bytes for IV, and decrypts using AES/CBC.
    final decryptedBytes = await _decryptRemoteBytes(encryptedData);
    await tempFile.writeAsBytes(decryptedBytes, flush: true);

    // 2. Open both local and remote databases
    final localDb = _ref.read(databaseProvider);
    final remoteDb = AppDatabase.connect(NativeDatabase(tempFile));

    final List<SyncConflict> conflicts = [];
    int insertedCount = 0;
    int updatedCount = 0;

    try {
      // Read all transactions from both databases
      final localTxs = await localDb.transactionDao.getTransactionsForUser(userId);
      final remoteTxs = await remoteDb.transactionDao.getTransactionsForUser(userId);

      final Map<String, Transaction> localMap = {for (var tx in localTxs) tx.id: tx};
      final Map<String, Transaction> remoteMap = {for (var tx in remoteTxs) tx.id: tx};

      // Two-Way Merge logic:
      // Iterate through remote transactions
      for (final remoteTx in remoteTxs) {
        final localTx = localMap[remoteTx.id];

        if (localTx == null) {
          // Transaction exists in remote but not locally.
          // Check if it was hard-deleted locally (not soft deleted).
          // For MVP, if it doesn't exist locally at all, we assume it's new from remote and insert it.
          await localDb.transactionDao.insertTransaction(remoteTx.copyWith(syncStatus: 'synced'));
          insertedCount++;
        } else {
          // Transaction exists in both. Compare fields and timestamps.
          if (localTx.syncStatus == 'conflict') {
            // Already flagged as conflict, collect it again to let user resolve.
            conflicts.add(SyncConflict(local: localTx, remote: remoteTx));
            continue;
          }

          final datesEqual = localTx.updatedAt.isAtSameMomentAs(remoteTx.updatedAt);
          if (datesEqual) {
            // No changes, make sure local syncStatus is synced if it matches remote
            if (localTx.syncStatus == 'pending') {
              await localDb.transactionDao.updateTransaction(localTx.copyWith(syncStatus: 'synced'));
            }
            continue;
          }

          if (remoteTx.updatedAt.isAfter(localTx.updatedAt)) {
            // Remote is newer.
            if (localTx.syncStatus == 'pending') {
              // CONFLICT: Both sides updated since last sync, and remote has a newer timestamp but local has pending changes.
              // We check if content is actually different before flagging a conflict.
              final contentDiffers = localTx.amount != remoteTx.amount ||
                  localTx.merchant != remoteTx.merchant ||
                  localTx.description != remoteTx.description ||
                  localTx.categoryId != remoteTx.categoryId ||
                  localTx.paymentMethodId != remoteTx.paymentMethodId ||
                  localTx.date != remoteTx.date ||
                  localTx.type != remoteTx.type ||
                  localTx.deletedAt != remoteTx.deletedAt;

              if (contentDiffers) {
                // Mark local as conflict
                final conflictedTx = localTx.copyWith(syncStatus: 'conflict');
                await localDb.transactionDao.updateTransaction(conflictedTx);
                conflicts.add(SyncConflict(local: conflictedTx, remote: remoteTx));
              } else {
                // Content is identical, just update timestamp and status
                await localDb.transactionDao.updateTransaction(remoteTx.copyWith(syncStatus: 'synced'));
                updatedCount++;
              }
            } else {
              // Remote is newer and local is already synced or not modified. Overwrite local.
              await localDb.transactionDao.updateTransaction(remoteTx.copyWith(syncStatus: 'synced'));
              updatedCount++;
            }
          } else {
            // Local is newer.
            if (localTx.syncStatus == 'pending') {
              // Local is newer and has pending changes. This will be uploaded to remote.
              // Do nothing, local is kept and remains 'pending'.
            } else {
              // Local has newer timestamp but is marked synced (shouldn't happen often).
              // We keep local as is.
            }
          }
        }
      }

      // Check for local transactions that don't exist in remote
      for (final localTx in localTxs) {
        if (!remoteMap.containsKey(localTx.id)) {
          // Exists locally but not in remote.
          // This is a new transaction created offline. It remains 'pending' and will be uploaded.
        }
      }

    } finally {
      // Close the temporary remote database connection
      await remoteDb.close();
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint('SyncService: Failed to delete temp sqlite file: $e');
      }
    }

    // 3. If there are no conflicts, we upload the merged local database to cloud
    if (conflicts.isEmpty) {
      // Update all local pending transactions to synced status before backup,
      // so the uploaded backup file reflects everything as synced.
      final localTxs = await localDb.transactionDao.getTransactionsForUser(userId);
      for (final tx in localTxs) {
        if (tx.syncStatus == 'pending') {
          await localDb.transactionDao.updateTransaction(tx.copyWith(syncStatus: 'synced'));
        }
      }

      // Perform backup upload
      await _backupService.backup(userId, googleAccessToken: googleAccessToken);
      debugPrint('SyncService: Sync complete. Merged database uploaded successfully.');
    } else {
      debugPrint('SyncService: Sync completed with ${conflicts.length} conflicts.');
    }

    return SyncResult(
      conflicts: conflicts,
      insertedCount: insertedCount,
      updatedCount: updatedCount,
    );
  }

  // Decryption helper using the master key from secure storage
  Future<List<int>> _decryptRemoteBytes(List<int> encryptedBytes) async {
    final secureStorage = _ref.read(secureStorageProvider);
    final base64Key = await secureStorage.getBackupEncryptionKey();
    if (base64Key == null) {
      throw Exception('Backup encryption key not found.');
    }

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
    return base64Decode(dbBase64);
  }
}

// Add Dio dependency import
final Provider<Dio> dioProvider = Provider<Dio>((ref) => Dio());

// Riverpod Provider
final Provider<SyncService> syncServiceProvider = Provider<SyncService>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return SyncService(ref, backupService);
});
