import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/sync/backup_service.dart';
import '../../../../core/security/audit_logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';

class BackupState {
  final bool isLoading;
  final DateTime? lastBackupDate;
  final int? backupSize;
  final String? errorMessage;
  final String? successMessage;

  BackupState({
    required this.isLoading,
    this.lastBackupDate,
    this.backupSize,
    this.errorMessage,
    this.successMessage,
  });

  factory BackupState.initial() => BackupState(isLoading: false);

  BackupState copyWith({
    bool? isLoading,
    DateTime? lastBackupDate,
    int? backupSize,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return BackupState(
      isLoading: isLoading ?? this.isLoading,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      backupSize: backupSize ?? this.backupSize,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class BackupNotifier extends StateNotifier<BackupState> {
  final BackupService _backupService;
  final AuditLogger _auditLogger;
  final Ref _ref;

  BackupNotifier(this._backupService, this._auditLogger, this._ref) : super(BackupState.initial()) {
    loadBackupInfo();
  }

  Future<void> loadBackupInfo() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final googleToken = await _getGoogleAccessToken();
      final meta = await _backupService.getBackupMetadata(googleAccessToken: googleToken);
      if (meta != null) {
        final lastBackupStr = meta['last_backup_date'] as String?;
        final size = meta['backup_size'] as int?;
        state = state.copyWith(
          isLoading: false,
          lastBackupDate: lastBackupStr != null ? DateTime.parse(lastBackupStr) : null,
          backupSize: size,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to retrieve backup info: ${e.toString()}',
      );
    }
  }

  Future<void> createBackup() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final auth = _ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) {
        throw Exception('User not authenticated.');
      }

      final googleToken = await _getGoogleAccessToken();
      final size = await _backupService.backup(userId, googleAccessToken: googleToken);
      
      state = state.copyWith(
        isLoading: false,
        lastBackupDate: DateTime.now(),
        backupSize: size,
        successMessage: 'Backup completed successfully!',
      );

      await _auditLogger.logEvent(
        userId: userId,
        eventType: 'backup_created',
        eventCategory: 'backup',
        description: 'Successfully created encrypted database backup.',
        metadata: {'backup_size': size, 'mode': googleToken == null ? 'mock_simulated' : 'google_drive'},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Backup failed: ${e.toString()}',
      );
      
      final auth = _ref.read(authProvider);
      await _auditLogger.logEvent(
        userId: auth.user?.id,
        eventType: 'backup_failed',
        eventCategory: 'backup',
        description: 'Database backup failed: ${e.toString()}',
      );
    }
  }

  Future<void> restoreBackup() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final auth = _ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) {
        throw Exception('User not authenticated.');
      }

      final googleToken = await _getGoogleAccessToken();
      await _backupService.restore(userId, googleAccessToken: googleToken);

      // Reload transactions to refresh UI immediately
      await _ref.read(expenseListNotifierProvider.notifier).loadTransactions();

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Database restored successfully! App database reloaded.',
      );

      await _auditLogger.logEvent(
        userId: userId,
        eventType: 'backup_restored',
        eventCategory: 'backup',
        description: 'Successfully decrypted and restored database backup.',
      );

      // Reload backup info after restoration to sync metadata state
      await loadBackupInfo();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Restore failed: ${e.toString()}',
      );

      final auth = _ref.read(authProvider);
      await _auditLogger.logEvent(
        userId: auth.user?.id,
        eventType: 'backup_restore_failed',
        eventCategory: 'backup',
        description: 'Database backup restoration failed: ${e.toString()}',
      );
    }
  }

  Future<void> deleteBackup() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final auth = _ref.read(authProvider);
      final userId = auth.user?.id;
      
      final googleToken = await _getGoogleAccessToken();
      await _backupService.deleteBackup(googleAccessToken: googleToken);
      
      state = BackupState.initial().copyWith(
        successMessage: 'Cloud backup deleted successfully.',
      );

      await _auditLogger.logEvent(
        userId: userId,
        eventType: 'backup_deleted',
        eventCategory: 'backup',
        description: 'Successfully deleted cloud database backup.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Delete failed: ${e.toString()}',
      );
    }
  }

  // Returns Google Access Token if stored, or null.
  // Note: Since we are using mock login in dev, this can retrieve a placeholder or be null.
  Future<String?> _getGoogleAccessToken() async {
    final secureStorage = _ref.read(secureStorageProvider);
    // Since Google Token is used directly, if we don't have it explicitly stored,
    // we fallback to looking at what the auth remote source is using.
    // In MVP, since Google token isn't fully persisted yet, we can return null,
    // and BackupService will detect that we're in mock mode and trigger the mock filesystem backup.
    return await secureStorage.getAccessToken(); // Return access token as placeholder
  }
}

final StateNotifierProvider<BackupNotifier, BackupState> backupNotifierProvider =
    StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  final auditLogger = ref.watch(auditLoggerProvider);
  return BackupNotifier(backupService, auditLogger, ref);
});
