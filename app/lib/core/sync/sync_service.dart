import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:googleapis/drive/v3.dart' as drive;
import '../database/app_database.dart';
import '../sync/backup_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../services/balance_engine.dart';

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
  Future<SyncResult> sync(String userId, {drive.DriveApi? driveApi}) async {
    final metadata = await _backupService.getBackupMetadata(userId: userId, driveApi: driveApi);
    if (metadata == null) {
      // No cloud backup exists yet. Update local pending transactions to synced before creating backup.
      final localDb = _ref.read(databaseProvider);
      final localTxs = await localDb.transactionDao.getTransactionsForUser(userId);
      for (final tx in localTxs) {
        if (tx.syncStatus == 'pending') {
          await localDb.transactionDao.updateTransaction(tx.copyWith(syncStatus: 'synced'));
        }
      }
      final size = await _backupService.backup(userId, driveApi: driveApi);
      debugPrint('SyncService: No remote backup found. Created initial backup of size $size bytes.');
      return SyncResult(conflicts: [], insertedCount: 0, updatedCount: 0);
    }

    // 1. Download the remote database file to a temporary location
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'remote_sync_${DateTime.now().millisecondsSinceEpoch}.sqlite'));

    // Download logic
    List<int> encryptedData;
    try {
      encryptedData = await _backupService.downloadLatestBackupBytes(userId, driveApi: driveApi);
    } catch (e) {
      debugPrint('SyncService: No remote backup found or download failed: $e. Creating initial backup...');
      final size = await _backupService.backup(userId, driveApi: driveApi);
      debugPrint('SyncService: Created initial backup of size $size bytes.');
      return SyncResult(conflicts: [], insertedCount: 0, updatedCount: 0);
    }

    // Decrypt the remote database bytes using validation pipeline
    List<int> decryptedBytes;
    try {
      final checksum = metadata['checksum'] as String?;
      decryptedBytes = await _backupService.decryptAndValidateBackup(encryptedData, checksum, userId);
    } catch (e) {
      debugPrint('SyncService: Remote backup validation failed: $e');
      debugPrint('SyncService: Treating remote backup as invalid/obsolete. Deleting from Google Drive and recreating...');

      try {
        await _backupService.deleteBackup(userId: userId, driveApi: driveApi);
        debugPrint('SyncService: Deleted invalid/obsolete remote backup.');
      } catch (err) {
        debugPrint('SyncService: Failed to delete invalid cloud backup: $err');
      }

      final size = await _backupService.backup(userId, driveApi: driveApi);
      debugPrint('SyncService: Uploaded fresh backup of size $size bytes.');
      return SyncResult(conflicts: [], insertedCount: 0, updatedCount: 0);
    }

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
          final txToInsert = remoteTx.copyWith(syncStatus: 'synced');
          await localDb.transactionDao.insertTransaction(txToInsert);
          await BalanceEngine(localDb).reconcileOnAdd(txToInsert);
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
                final txToUpdate = remoteTx.copyWith(syncStatus: 'synced');
                await BalanceEngine(localDb).reconcileOnEdit(localTx, txToUpdate);
                await localDb.transactionDao.updateTransaction(txToUpdate);
                updatedCount++;
              }
            } else {
              // Remote is newer and local is already synced or not modified. Overwrite local.
              final txToUpdate = remoteTx.copyWith(syncStatus: 'synced');
              await BalanceEngine(localDb).reconcileOnEdit(localTx, txToUpdate);
              await localDb.transactionDao.updateTransaction(txToUpdate);
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
      await _backupService.backup(userId, driveApi: driveApi);
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


}

// Riverpod Provider
final Provider<SyncService> syncServiceProvider = Provider<SyncService>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return SyncService(ref, backupService);
});
