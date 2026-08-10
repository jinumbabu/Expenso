import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../../../../core/sync/backup_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_repair_service.dart';
import '../../../../core/security/audit_logger.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../../core/services/settings_provider.dart';
import 'package:drift/drift.dart';

enum LocalBackupStatus { none, creating, validated, failed }
enum CloudUploadStatus { idle, uploading, uploaded, failed }
enum CloudVerificationStatus { pending, verifying, verified, failed }
enum RestoreStatus { none, pending, restoring, successful, failed }

class GoogleDriveDiagnosticReport {
  final String step1SignIn; // 'PENDING', 'PASS', 'FAIL'
  final String step1Details;
  final String step2Client;
  final String step2Details;
  final String step3Api;
  final String step3Details;
  final String step4AppData;
  final String step4Details;
  final String step5Upload;
  final String step5Details;
  final String step6Get;
  final String step6Details;
  final String step7Download;
  final String step7Details;
  final String step8Delete;
  final String step8Details;

  final int? lastHttpStatus;
  final String? lastException;
  final String? lastStackTrace;

  GoogleDriveDiagnosticReport({
    this.step1SignIn = 'PENDING',
    this.step1Details = '',
    this.step2Client = 'PENDING',
    this.step2Details = '',
    this.step3Api = 'PENDING',
    this.step3Details = '',
    this.step4AppData = 'PENDING',
    this.step4Details = '',
    this.step5Upload = 'PENDING',
    this.step5Details = '',
    this.step6Get = 'PENDING',
    this.step6Details = '',
    this.step7Download = 'PENDING',
    this.step7Details = '',
    this.step8Delete = 'PENDING',
    this.step8Details = '',
    this.lastHttpStatus,
    this.lastException,
    this.lastStackTrace,
  });

  GoogleDriveDiagnosticReport copyWith({
    String? step1SignIn,
    String? step1Details,
    String? step2Client,
    String? step2Details,
    String? step3Api,
    String? step3Details,
    String? step4AppData,
    String? step4Details,
    String? step5Upload,
    String? step5Details,
    String? step6Get,
    String? step6Details,
    String? step7Download,
    String? step7Details,
    String? step8Delete,
    String? step8Details,
    int? lastHttpStatus,
    String? lastException,
    String? lastStackTrace,
  }) {
    return GoogleDriveDiagnosticReport(
      step1SignIn: step1SignIn ?? this.step1SignIn,
      step1Details: step1Details ?? this.step1Details,
      step2Client: step2Client ?? this.step2Client,
      step2Details: step2Details ?? this.step2Details,
      step3Api: step3Api ?? this.step3Api,
      step3Details: step3Details ?? this.step3Details,
      step4AppData: step4AppData ?? this.step4AppData,
      step4Details: step4Details ?? this.step4Details,
      step5Upload: step5Upload ?? this.step5Upload,
      step5Details: step5Details ?? this.step5Details,
      step6Get: step6Get ?? this.step6Get,
      step6Details: step6Details ?? this.step6Details,
      step7Download: step7Download ?? this.step7Download,
      step7Details: step7Details ?? this.step7Details,
      step8Delete: step8Delete ?? this.step8Delete,
      step8Details: step8Details ?? this.step8Details,
      lastHttpStatus: lastHttpStatus ?? this.lastHttpStatus,
      lastException: lastException ?? this.lastException,
      lastStackTrace: lastStackTrace ?? this.lastStackTrace,
    );
  }
}

class FailureDetails {
  final String exceptionType;
  final String methodName;
  final String fileName;
  final String stackTrace;
  final String stage;
  final DateTime timestamp;

  FailureDetails({
    required this.exceptionType,
    required this.methodName,
    required this.fileName,
    required this.stackTrace,
    required this.stage,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'exceptionType': exceptionType,
    'methodName': methodName,
    'fileName': fileName,
    'stackTrace': stackTrace,
    'stage': stage,
    'timestamp': timestamp.toIso8601String(),
  };

  factory FailureDetails.fromJson(Map<String, dynamic> json) => FailureDetails(
    exceptionType: json['exceptionType'] as String? ?? 'UnknownException',
    methodName: json['methodName'] as String? ?? 'unknownMethod',
    fileName: json['fileName'] as String? ?? 'unknown_file.dart',
    stackTrace: json['stackTrace'] as String? ?? '',
    stage: json['stage'] as String? ?? 'unknown',
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
  );

  static FailureDetails fromError(dynamic error, StackTrace st, String stage) {
    final stackStr = st.toString();
    final lines = stackStr.split('\n');
    String methodName = 'unknownMethod';
    String fileName = 'unknown_file.dart';
    
    if (lines.isNotEmpty && lines.first.startsWith('#0')) {
      final parts = lines.first.split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        methodName = parts[1];
        final filePart = parts[2];
        if (filePart.startsWith('(') && filePart.endsWith(')')) {
          fileName = filePart.substring(1, filePart.length - 1);
        }
      }
    }

    return FailureDetails(
      exceptionType: error.runtimeType.toString(),
      methodName: methodName,
      fileName: fileName,
      stackTrace: stackStr,
      stage: stage,
      timestamp: DateTime.now(),
    );
  }
}

class BackupCancelledException implements Exception {
  @override
  String toString() => 'Backup/Restore cancelled by user.';
}

enum BackupOperationState {
  idle,
  preparing,
  exporting,
  encrypting,
  connecting,
  uploading,
  verifying,
  completed,
  failed,
  cancelled,
}

class DeviceStatus {
  static const _channel = MethodChannel('com.expenso.ai.app/device_status');

  static Future<bool> isCharging() async {
    try {
      if (!Platform.isAndroid) return true;
      final bool? charging = await _channel.invokeMethod<bool>('isCharging');
      return charging ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> isWifi() async {
    try {
      if (!Platform.isAndroid) return true;
      final bool? wifi = await _channel.invokeMethod<bool>('isWifi');
      return wifi ?? true;
    } catch (_) {
      return true;
    }
  }
}

class BackupState {
  final bool isLoading;
  final DateTime? lastBackupDate; // for compatibility
  final int? backupSize; // for compatibility
  final DateTime? lastLocalBackupDate;
  final int? lastLocalBackupSize;
  final int? lastLocalPlaintextDbSize;
  final DateTime? lastCloudBackupDate;
  final int? lastCloudBackupSize;
  final String? errorMessage;
  final String? successMessage;
  final List<SyncConflict> conflicts;
  final List<Map<String, dynamic>> backups; // Cloud backups
  final List<Map<String, dynamic>> localBackups;
  final List<Map<String, dynamic>> allAppDataFiles;
  final String backupSchedule; // 'manual', 'daily', 'weekly', 'monthly'
  final bool backupWifiOnly;
  final bool backupChargingOnly;
  final bool googleDriveBackupEnabled;
  final bool isBackingUp;
  final bool isRestoring;
  final bool isSyncing;
  final String? currentStatus;

  // Cloud Credentials & Profile details
  final String? googleAccount;
  final String? googleDisplayName;
  final String? googlePhotoUrl;
  final String? authStatus;
  final String? accessTokenStatus;
  final String? refreshTokenStatus;
  final List<String> grantedScopes;
  final String? driveConnectionStatus;
  final String? appDataFolderStatus;
  
  // Real-time Backup & Sync details
  final DateTime? lastSyncTime;
  final String? lastBackupFileName;
  final String? lastBackupFileId;
  final int? lastBackupSize;
  final String? lastError;

  // Real-time progress trackers
  final bool isProgressVisible;
  final String progressTitle;
  final double progressPercentage;
  final int progressStep;
  final int progressTotalSteps;
  final String progressCurrentTask;
  final int progressElapsedTime;
  final int progressEstimatedRemaining;
  final bool isCancelled;
  final BackupOperationState operationState;

  // Detailed statuses
  final String? lastBackupStatus;
  final String? lastRestoreStatus;
  final String? lastBackupError;
  final String? lastRestoreError;

  final LocalBackupStatus localBackupStatus;
  final CloudUploadStatus cloudUploadStatus;
  final CloudVerificationStatus cloudVerificationStatus;
  final RestoreStatus restoreStatus;

  // Health and repairs
  final Map<String, bool> dbHealthStatus;
  final DatabaseRepairReport? lastRepairReport;
  final List<String> activeFkViolations;

  BackupState({
    required this.isLoading,
    this.lastBackupDate,
    this.backupSize,
    this.lastLocalBackupDate,
    this.lastLocalBackupSize,
    this.lastLocalPlaintextDbSize,
    this.lastCloudBackupDate,
    this.lastCloudBackupSize,
    this.errorMessage,
    this.successMessage,
    this.conflicts = const [],
    this.backups = const [],
    this.localBackups = const [],
    this.allAppDataFiles = const [],
    this.backupSchedule = 'manual',
    this.backupWifiOnly = false,
    this.backupChargingOnly = false,
    this.googleDriveBackupEnabled = false,
    this.isBackingUp = false,
    this.isRestoring = false,
    this.isSyncing = false,
    this.currentStatus,
    this.googleAccount,
    this.googleDisplayName,
    this.googlePhotoUrl,
    this.authStatus,
    this.accessTokenStatus,
    this.refreshTokenStatus,
    this.grantedScopes = const [],
    this.driveConnectionStatus,
    this.appDataFolderStatus,
    this.lastSyncTime,
    this.lastBackupFileName,
    this.lastBackupFileId,
    this.lastBackupSize,
    this.lastError,
    this.isProgressVisible = false,
    this.progressTitle = '',
    this.progressPercentage = 0.0,
    this.progressStep = 0,
    this.progressTotalSteps = 0,
    this.progressCurrentTask = '',
    this.progressElapsedTime = 0,
    this.progressEstimatedRemaining = 0,
    this.isCancelled = false,
    this.operationState = BackupOperationState.idle,
    this.lastBackupStatus,
    this.lastRestoreStatus,
    this.lastBackupError,
    this.lastRestoreError,
    this.dbHealthStatus = const {},
    this.lastRepairReport,
    this.activeFkViolations = const [],
    this.googleDriveDiagnosticReport,
    this.isDiagnosticsRunning = false,
    this.lastRestoreDate,
    this.lastSyncDuration,
    this.developerModeEnabled = false,
    this.localBackupStatus = LocalBackupStatus.none,
    this.cloudUploadStatus = CloudUploadStatus.idle,
    this.cloudVerificationStatus = CloudVerificationStatus.pending,
    this.restoreStatus = RestoreStatus.none,
  });

  // Google Drive Diagnostics fields
  final GoogleDriveDiagnosticReport? googleDriveDiagnosticReport;
  final bool isDiagnosticsRunning;

  // Added for production user-friendly dashboard and security gate
  final DateTime? lastRestoreDate;
  final Duration? lastSyncDuration;
  final bool developerModeEnabled;

  factory BackupState.initial() => BackupState(
        isLoading: false,
        conflicts: const [],
        backups: const [],
        localBackups: const [],
        allAppDataFiles: const [],
        backupSchedule: 'manual',
        backupWifiOnly: false,
        backupChargingOnly: false,
        googleDriveBackupEnabled: false,
        isProgressVisible: false,
        progressTitle: '',
        progressPercentage: 0.0,
        progressStep: 0,
        progressTotalSteps: 0,
        progressCurrentTask: '',
        progressElapsedTime: 0,
        progressEstimatedRemaining: 0,
        isCancelled: false,
        operationState: BackupOperationState.idle,
        dbHealthStatus: const {},
        lastRepairReport: null,
        activeFkViolations: const [],
        googleDriveDiagnosticReport: null,
        isDiagnosticsRunning: false,
        lastRestoreDate: null,
        lastSyncDuration: null,
        developerModeEnabled: false,
        localBackupStatus: LocalBackupStatus.none,
        cloudUploadStatus: CloudUploadStatus.idle,
        cloudVerificationStatus: CloudVerificationStatus.pending,
        restoreStatus: RestoreStatus.none,
      );

  BackupState copyWith({
    bool? isLoading,
    DateTime? lastBackupDate,
    int? backupSize,
    DateTime? lastLocalBackupDate,
    int? lastLocalBackupSize,
    int? lastLocalPlaintextDbSize,
    DateTime? lastCloudBackupDate,
    int? lastCloudBackupSize,
    String? errorMessage,
    String? successMessage,
    List<SyncConflict>? conflicts,
    List<Map<String, dynamic>>? backups,
    List<Map<String, dynamic>>? localBackups,
    List<Map<String, dynamic>>? allAppDataFiles,
    String? backupSchedule,
    bool? backupWifiOnly,
    bool? backupChargingOnly,
    bool? googleDriveBackupEnabled,
    bool? isBackingUp,
    bool? isRestoring,
    bool? isSyncing,
    String? currentStatus,
    String? googleAccount,
    String? googleDisplayName,
    String? googlePhotoUrl,
    String? authStatus,
    String? accessTokenStatus,
    String? refreshTokenStatus,
    List<String>? grantedScopes,
    String? driveConnectionStatus,
    String? appDataFolderStatus,
    DateTime? lastSyncTime,
    String? lastBackupFileName,
    String? lastBackupFileId,
    int? lastBackupSize,
    String? lastError,
    bool clearMessages = false,
    bool? isProgressVisible,
    String? progressTitle,
    double? progressPercentage,
    int? progressStep,
    int? progressTotalSteps,
    String? progressCurrentTask,
    int? progressElapsedTime,
    int? progressEstimatedRemaining,
    bool? isCancelled,
    BackupOperationState? operationState,
    String? lastBackupStatus,
    String? lastRestoreStatus,
    String? lastBackupError,
    String? lastRestoreError,
    Map<String, bool>? dbHealthStatus,
    DatabaseRepairReport? lastRepairReport,
    List<String>? activeFkViolations,
    GoogleDriveDiagnosticReport? googleDriveDiagnosticReport,
    bool? isDiagnosticsRunning,
    DateTime? lastRestoreDate,
    Duration? lastSyncDuration,
    bool? developerModeEnabled,
    LocalBackupStatus? localBackupStatus,
    CloudUploadStatus? cloudUploadStatus,
    CloudVerificationStatus? cloudVerificationStatus,
    RestoreStatus? restoreStatus,
  }) {
    return BackupState(
      isLoading: isLoading ?? this.isLoading,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      backupSize: backupSize ?? this.backupSize,
      lastLocalBackupDate: lastLocalBackupDate ?? this.lastLocalBackupDate,
      lastLocalBackupSize: lastLocalBackupSize ?? this.lastLocalBackupSize,
      lastLocalPlaintextDbSize: lastLocalPlaintextDbSize ?? this.lastLocalPlaintextDbSize,
      lastCloudBackupDate: lastCloudBackupDate ?? this.lastCloudBackupDate,
      lastCloudBackupSize: lastCloudBackupSize ?? this.lastCloudBackupSize,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      conflicts: conflicts ?? this.conflicts,
      backups: backups ?? this.backups,
      localBackups: localBackups ?? this.localBackups,
      allAppDataFiles: allAppDataFiles ?? this.allAppDataFiles,
      backupSchedule: backupSchedule ?? this.backupSchedule,
      backupWifiOnly: backupWifiOnly ?? this.backupWifiOnly,
      backupChargingOnly: backupChargingOnly ?? this.backupChargingOnly,
      googleDriveBackupEnabled: googleDriveBackupEnabled ?? this.googleDriveBackupEnabled,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
      isSyncing: isSyncing ?? this.isSyncing,
      currentStatus: clearMessages ? null : (currentStatus ?? this.currentStatus),
      googleAccount: googleAccount ?? this.googleAccount,
      googleDisplayName: googleDisplayName ?? this.googleDisplayName,
      googlePhotoUrl: googlePhotoUrl ?? this.googlePhotoUrl,
      authStatus: authStatus ?? this.authStatus,
      accessTokenStatus: accessTokenStatus ?? this.accessTokenStatus,
      refreshTokenStatus: refreshTokenStatus ?? this.refreshTokenStatus,
      grantedScopes: grantedScopes ?? this.grantedScopes,
      driveConnectionStatus: driveConnectionStatus ?? this.driveConnectionStatus,
      appDataFolderStatus: appDataFolderStatus ?? this.appDataFolderStatus,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastBackupFileName: lastBackupFileName ?? this.lastBackupFileName,
      lastBackupFileId: lastBackupFileId ?? this.lastBackupFileId,
      lastBackupSize: lastBackupSize ?? this.lastBackupSize,
      lastError: clearMessages ? null : (lastError ?? this.lastError),
      isProgressVisible: isProgressVisible ?? this.isProgressVisible,
      progressTitle: progressTitle ?? this.progressTitle,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      progressStep: progressStep ?? this.progressStep,
      progressTotalSteps: progressTotalSteps ?? this.progressTotalSteps,
      progressCurrentTask: progressCurrentTask ?? this.progressCurrentTask,
      progressElapsedTime: progressElapsedTime ?? this.progressElapsedTime,
      progressEstimatedRemaining: progressEstimatedRemaining ?? this.progressEstimatedRemaining,
      isCancelled: isCancelled ?? this.isCancelled,
      operationState: operationState ?? this.operationState,
      lastBackupStatus: lastBackupStatus ?? this.lastBackupStatus,
      lastRestoreStatus: lastRestoreStatus ?? this.lastRestoreStatus,
      lastBackupError: lastBackupError ?? this.lastBackupError,
      lastRestoreError: lastRestoreError ?? this.lastRestoreError,
      dbHealthStatus: dbHealthStatus ?? this.dbHealthStatus,
      lastRepairReport: lastRepairReport ?? this.lastRepairReport,
      activeFkViolations: activeFkViolations ?? this.activeFkViolations,
      googleDriveDiagnosticReport: googleDriveDiagnosticReport ?? this.googleDriveDiagnosticReport,
      isDiagnosticsRunning: isDiagnosticsRunning ?? this.isDiagnosticsRunning,
      lastRestoreDate: lastRestoreDate ?? this.lastRestoreDate,
      lastSyncDuration: lastSyncDuration ?? this.lastSyncDuration,
      developerModeEnabled: developerModeEnabled ?? this.developerModeEnabled,
      localBackupStatus: localBackupStatus ?? this.localBackupStatus,
      cloudUploadStatus: cloudUploadStatus ?? this.cloudUploadStatus,
      cloudVerificationStatus: cloudVerificationStatus ?? this.cloudVerificationStatus,
      restoreStatus: restoreStatus ?? this.restoreStatus,
    );
  }
}

class BackupNotifier extends StateNotifier<BackupState> {
  final BackupService _backupService;
  final AuditLogger _auditLogger;
  final Ref _ref;
  Timer? _progressTimer;

  BackupNotifier(this._backupService, this._auditLogger, this._ref)
      : super(BackupState.initial()) {
    _ref.listen<AppSettingsState>(appSettingsProvider, (previous, next) {
      if (previous == null || 
          previous.googleDriveBackupEnabled != next.googleDriveBackupEnabled ||
          previous.backupWifiOnly != next.backupWifiOnly ||
          previous.backupChargingOnly != next.backupChargingOnly ||
          previous.backupSchedule != next.backupSchedule) {
        state = state.copyWith(
          googleDriveBackupEnabled: next.googleDriveBackupEnabled,
          backupWifiOnly: next.backupWifiOnly,
          backupChargingOnly: next.backupChargingOnly,
          backupSchedule: next.backupSchedule,
        );
      }
    }, fireImmediately: true);
    loadBackupInfo();
  }

  SecureStorageService get _secureStorage => _ref.read(secureStorageProvider);

  Future<void> _handleErrorAndReauth(Object e, String contextMessage) async {
    final errStr = e.toString().toLowerCase();
    if (e is BackupCancelledException || errStr.contains('cancelled') || errStr.contains('canceled')) {
      state = state.copyWith(
        isLoading: false,
        isBackingUp: false,
        isRestoring: false,
        isSyncing: false,
        isProgressVisible: false,
        errorMessage: 'Backup/Restore cancelled by user.',
      );
      return;
    }

    bool isAuthError = errStr.contains('permission denied') || 
                       errStr.contains('401') || 
                       errStr.contains('403') ||
                       errStr.contains('unauthorized') ||
                       errStr.contains('sign in again');

    if (e is drive.DetailedApiRequestError) {
      if (e.status == 401 || e.status == 403) {
        isAuthError = true;
      }
    }

    if (isAuthError && !_backupService.isMockMode) {
      debugPrint('BackupNotifier: Auth error detected during $contextMessage. Requesting interactive sign in...');
      await signInWithGoogleInteractive();
    } else {
      state = state.copyWith(
        isLoading: false,
        isBackingUp: false,
        isRestoring: false,
        isSyncing: false,
        isProgressVisible: false,
        errorMessage: '$contextMessage: ${_backupService.getReadableError(e)}',
      );
    }
  }

  Future<void> loadBackupInfo() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final auth = _ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      Map<String, bool> dbHealth = {
        'SQLite Integrity': true,
        'Foreign Keys': true,
        'Accounts': true,
        'Categories': true,
        'Transactions': true,
        'Budgets': true,
        'Credit Cards': true,
        'Loans': true,
        'Goals': true,
        'SMS Drafts': true,
      };
      final List<String> fkViolationsList = [];
      try {
        final repairService = _ref.read(databaseRepairServiceProvider);
        dbHealth = await repairService.checkDatabaseHealth();

        final db = _ref.read(databaseProvider);
        final fkRows = await db.customSelect('PRAGMA foreign_key_check;').get();
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
          } catch (_) {}

          fkViolationsList.add('Child: $childTable (rowid: $rowId), Parent: $parentTable, Missing Key ($fromCol): $missingVal');
        }
      } catch (e) {
        debugPrint('BackupNotifier: Database health check failed: $e');
      }

      String? googleAccount;
      String? googleDisplayName;
      String? googlePhotoUrl;
      String authStatus = 'Signed Out';
      String accessTokenStatus = 'Missing';
      String refreshTokenStatus = 'Missing';
      List<String> grantedScopes = [];
      String driveConnectionStatus = 'Disconnected';
      String appDataFolderStatus = 'Inaccessible';
      
      DateTime? lastLocalBackupTime;
      int? lastLocalBackupSize;
      int? lastLocalPlaintextDbSize;
      DateTime? lastCloudBackupTime;
      int? lastCloudBackupSize;
      
      String? lastError;

      // 1. Fetch settings from central appSettingsProvider
      final settings = _ref.read(appSettingsProvider);
      final schedule = settings.backupSchedule;
      final wifiOnly = settings.backupWifiOnly;
      final chargingOnly = settings.backupChargingOnly;
      final driveEnabled = settings.googleDriveBackupEnabled;

      // 2. Setup Google sign-in details first to resolve the current account
      final googleSignIn = _ref.read(googleSignInProvider);
      GoogleSignInAccount? currentUser = googleSignIn.currentUser;
      if (currentUser == null && driveEnabled) {
        try {
          currentUser = await googleSignIn.signInSilently(
            reAuthenticate: false,
            suppressErrors: true,
          );
        } catch (_) {}
      }
      if (currentUser != null) {
        googleAccount = currentUser.email;
        googleDisplayName = currentUser.displayName;
        googlePhotoUrl = currentUser.photoUrl;
        authStatus = 'Signed In';
        refreshTokenStatus = 'Available (Managed by OS/SDK)';
        grantedScopes = googleSignIn.scopes;
      }

      final lastLocalStr = await _secureStorage.getLastLocalBackupDate();
      if (lastLocalStr != null) {
        lastLocalBackupTime = DateTime.tryParse(lastLocalStr);
      }
      lastLocalBackupSize = await _secureStorage.getLastLocalBackupSize();
      lastLocalPlaintextDbSize = await _secureStorage.getLastLocalPlaintextDbSize();

      final lastCloudStr = await _secureStorage.getLastCloudBackupDate(googleAccount: googleAccount);
      if (lastCloudStr != null) {
        lastCloudBackupTime = DateTime.tryParse(lastCloudStr);
      }
      lastCloudBackupSize = await _secureStorage.getLastCloudBackupSize(googleAccount: googleAccount);

      final lastBackupStatus = await _secureStorage.getLastBackupStatus(googleAccount: googleAccount);
      final lastRestoreStatus = await _secureStorage.getLastRestoreStatus(googleAccount: googleAccount);
      final lastBackupError = await _secureStorage.getLastBackupError(googleAccount: googleAccount);
      final lastRestoreError = await _secureStorage.getLastRestoreError(googleAccount: googleAccount);

      final devMode = await _secureStorage.getDeveloperModeEnabled();
      DateTime? lastRestoreDate;
      final lastRestoreStr = await _secureStorage.getLastRestoreDate();
      if (lastRestoreStr != null) {
        lastRestoreDate = DateTime.tryParse(lastRestoreStr);
      }
      Duration? lastSyncDuration;
      final lastSyncSec = await _secureStorage.getLastSyncDuration();
      if (lastSyncSec != null) {
        lastSyncDuration = Duration(seconds: lastSyncSec);
      }

      // 2. Fetch last error from audit logs
      try {
        final db = _ref.read(databaseProvider);
        final logs = await db.auditLogDao.getLogsForUser(userId);
        final syncLogs = logs.where((log) => log.eventCategory == 'sync' || log.eventCategory == 'backup').toList();
        if (syncLogs.isNotEmpty) {
          syncLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final latestLog = syncLogs.first;
          if (latestLog.eventType.contains('failed')) {
            lastError = latestLog.description;
          } else {
            // The last operation was successful, so clear the last sync error!
            lastError = null;
          }
        }
      } catch (e) {
        debugPrint('BackupNotifier: Failed to fetch last error from logs: $e');
      }

      // Setup Google sign-in details resolved at start of loadBackupInfo

      // 4. Fetch local backups list
      final localBackups = await _backupService.listLocalBackups(userId);
      if (localBackups.isNotEmpty) {
        final latestLocal = localBackups.first;
        lastLocalBackupTime = DateTime.fromMillisecondsSinceEpoch(latestLocal['timestamp'] as int);
        lastLocalBackupSize = latestLocal['size'] as int;
      } else {
        lastLocalBackupTime = null;
        lastLocalBackupSize = null;
      }

      final isMockMode = _backupService.isMockMode;
      final isCloudMetadataValid = (isMockMode || (googleAccount != null && driveEnabled));

      if (isCloudMetadataValid) {
        // 5. Fetch cloud backups list using retry executor
        await _executeWithRetry((driveApi) async {
          if (driveApi != null && driveEnabled) {
            // Execute real API call to verify connection
            await driveApi.files.list(
              spaces: 'appDataFolder',
              pageSize: 1,
            );
            driveConnectionStatus = 'Connected';
            accessTokenStatus = 'Active';
            appDataFolderStatus = 'Verified / Accessible';
          }

          final cloudBackups = await _backupService.listCloudBackups(userId, driveApi: driveApi);
          
          final List<Map<String, dynamic>> allFiles;
          if (isMockMode) {
            allFiles = await _backupService.listAllSimulatedAppDataFiles();
          } else if (driveApi != null) {
            allFiles = await _backupService.listAllAppDataFiles(driveApi);
          } else {
            allFiles = [];
          }

          debugPrint('==================================================');
          debugPrint('GOOGLE DRIVE APPDATA FILE LISTING (loadBackupInfo):');
          for (var f in allFiles) {
            debugPrint('• File ID:      ${f['id']}');
            debugPrint('  Name:         ${f['name']}');
            debugPrint('  Size:         ${f['size']} bytes');
            debugPrint('  Created Time: ${f['createdTime']}');
            debugPrint('  Modified Time:${f['modifiedTime']}');
            debugPrint('  Checksum:     ${f['checksum']}');
            debugPrint('--------------------------------------------------');
          }
          debugPrint('==================================================');

          String? updatedBackupStatus = lastBackupStatus;

          if (cloudBackups.isNotEmpty) {
            final latest = cloudBackups.first;
            lastCloudBackupTime = DateTime.fromMillisecondsSinceEpoch(latest['timestamp'] as int);
            lastCloudBackupSize = latest['size'] as int?;

            final latestFileId = latest['id'] as String?;
            final verifiedFileId = await _secureStorage.getLastVerifiedDriveFileId(googleAccount: googleAccount);
            if (latestFileId != null && latestFileId != verifiedFileId) {
              debugPrint('BackupNotifier: Detected unverified latest backup $latestFileId. Running verification...');
              try {
                final result = await _backupService.verifyBackupFileOnDemand(
                  fileId: latestFileId,
                  driveApi: driveApi,
                );
                if (result['status'] == 'Verified') {
                  final checksum = result['checksum'] as String?;
                  final backupIdHex = latest['backupId'] ?? latest['id'];
                  await _secureStorage.saveLastVerifiedDriveFileId(latestFileId, googleAccount: googleAccount);
                  await _secureStorage.saveLastBackupStatus('UPLOAD VERIFIED', googleAccount: googleAccount);
                  if (checksum != null) {
                    await _secureStorage.saveLastCloudBackupSha256(checksum, googleAccount: googleAccount);
                  }
                  debugPrint('BackupNotifier: Verification succeeded for $latestFileId');
                } else {
                  await _secureStorage.saveLastBackupStatus('DATABASE INTEGRITY FAILED', googleAccount: googleAccount);
                  debugPrint('BackupNotifier: Verification failed for $latestFileId: ${result['error']}');
                }
              } catch (e) {
                await _secureStorage.saveLastBackupStatus('DATABASE INTEGRITY FAILED', googleAccount: googleAccount);
                debugPrint('BackupNotifier: Auto-verification failed: $e');
              }
              updatedBackupStatus = await _secureStorage.getLastBackupStatus(googleAccount: googleAccount);
            }
          } else {
            lastCloudBackupTime = null;
            lastCloudBackupSize = null;
            if (googleAccount != null) {
              await _secureStorage.saveLastVerifiedDriveFileId('', googleAccount: googleAccount);
              if (updatedBackupStatus == 'DATABASE INTEGRITY FAILED' || updatedBackupStatus == 'UPLOAD VERIFIED') {
                await _secureStorage.saveLastBackupStatus('LOCAL BACKUP CREATED', googleAccount: googleAccount);
                updatedBackupStatus = 'LOCAL BACKUP CREATED';
              }
            }
          }

          LocalBackupStatus localStatus = LocalBackupStatus.none;
          if (localBackups.isNotEmpty) {
            localStatus = (updatedBackupStatus == 'LOCAL BACKUP INVALID' || updatedBackupStatus == 'LOCAL BACKUP CORRUPTED') 
                ? LocalBackupStatus.failed 
                : LocalBackupStatus.validated;
          }

          CloudUploadStatus uploadStatus = CloudUploadStatus.idle;
          if (cloudBackups.isNotEmpty) {
            uploadStatus = (updatedBackupStatus == 'UPLOAD FAILED') 
                ? CloudUploadStatus.failed 
                : CloudUploadStatus.uploaded;
          } else if (updatedBackupStatus == 'UPLOAD FAILED') {
            uploadStatus = CloudUploadStatus.failed;
          }

          CloudVerificationStatus verificationStatus = CloudVerificationStatus.pending;
          if (cloudBackups.isNotEmpty) {
            if (updatedBackupStatus == 'UPLOAD VERIFIED' || updatedBackupStatus == 'Successful') {
              verificationStatus = CloudVerificationStatus.verified;
            } else if (updatedBackupStatus == 'DATABASE INTEGRITY FAILED') {
              verificationStatus = CloudVerificationStatus.failed;
            }
          }

          RestoreStatus restStatus = RestoreStatus.none;
          if (lastRestoreStatus == 'Successful' || lastRestoreStatus == 'RESTORE SUCCESSFUL') {
            restStatus = RestoreStatus.successful;
          } else if (lastRestoreStatus == 'Failed') {
            restStatus = RestoreStatus.failed;
          }

          state = state.copyWith(
            isLoading: false,
            lastBackupDate: lastCloudBackupTime ?? lastLocalBackupTime,
            backupSize: lastCloudBackupSize ?? lastLocalBackupSize,
            lastLocalBackupDate: lastLocalBackupTime,
            lastLocalBackupSize: lastLocalBackupSize,
            lastLocalPlaintextDbSize: lastLocalPlaintextDbSize,
            lastCloudBackupDate: lastCloudBackupTime,
            lastCloudBackupSize: lastCloudBackupSize,
            backups: cloudBackups,
            localBackups: localBackups,
            allAppDataFiles: allFiles,
            backupSchedule: schedule,
            backupWifiOnly: wifiOnly,
            backupChargingOnly: chargingOnly,
            googleDriveBackupEnabled: driveEnabled,
            googleAccount: googleAccount,
            googleDisplayName: googleDisplayName,
            googlePhotoUrl: googlePhotoUrl,
            authStatus: authStatus,
            accessTokenStatus: accessTokenStatus,
            refreshTokenStatus: refreshTokenStatus,
            grantedScopes: grantedScopes,
            driveConnectionStatus: driveConnectionStatus,
            appDataFolderStatus: appDataFolderStatus,
            lastSyncTime: lastCloudBackupTime ?? lastLocalBackupTime,
            lastBackupFileName: cloudBackups.isNotEmpty ? cloudBackups.first['name'] as String? : null,
            lastBackupFileId: cloudBackups.isNotEmpty ? cloudBackups.first['id'] as String? : null,
            lastBackupSize: lastCloudBackupSize,
            lastError: lastError,
            lastBackupStatus: updatedBackupStatus,
            lastRestoreStatus: lastRestoreStatus,
            lastBackupError: lastBackupError,
            lastRestoreError: lastRestoreError,
            dbHealthStatus: dbHealth,
            activeFkViolations: fkViolationsList,
            lastRestoreDate: lastRestoreDate,
            lastSyncDuration: lastSyncDuration,
            developerModeEnabled: devMode,
            localBackupStatus: localStatus,
            cloudUploadStatus: uploadStatus,
            cloudVerificationStatus: verificationStatus,
            restoreStatus: restStatus,
          );
        });
      } else {
        // Cloud backup is not configured/authenticated: clear all cloud variables
        LocalBackupStatus localStatus = LocalBackupStatus.none;
        if (localBackups.isNotEmpty) {
          localStatus = (lastBackupStatus == 'LOCAL BACKUP INVALID' || lastBackupStatus == 'LOCAL BACKUP CORRUPTED')
              ? LocalBackupStatus.failed
              : LocalBackupStatus.validated;
        }

        RestoreStatus restStatus = RestoreStatus.none;
        if (lastRestoreStatus == 'Successful' || lastRestoreStatus == 'RESTORE SUCCESSFUL') {
          restStatus = RestoreStatus.successful;
        } else if (lastRestoreStatus == 'Failed') {
          restStatus = RestoreStatus.failed;
        }

        state = state.copyWith(
          isLoading: false,
          lastBackupDate: lastLocalBackupTime,
          backupSize: lastLocalBackupSize,
          lastLocalBackupDate: lastLocalBackupTime,
          lastLocalBackupSize: lastLocalBackupSize,
          lastLocalPlaintextDbSize: lastLocalPlaintextDbSize,
          lastCloudBackupDate: null,
          lastCloudBackupSize: null,
          backups: [],
          localBackups: localBackups,
          allAppDataFiles: [],
          backupSchedule: schedule,
          backupWifiOnly: wifiOnly,
          backupChargingOnly: chargingOnly,
          googleDriveBackupEnabled: driveEnabled,
          googleAccount: googleAccount,
          googleDisplayName: googleDisplayName,
          googlePhotoUrl: googlePhotoUrl,
          authStatus: googleAccount != null ? 'Signed In' : 'Not Linked',
          accessTokenStatus: 'Inactive',
          refreshTokenStatus: 'Unavailable',
          grantedScopes: [],
          driveConnectionStatus: 'Disconnected',
          appDataFolderStatus: 'Not Verified',
          lastSyncTime: lastLocalBackupTime,
          lastBackupFileName: null,
          lastBackupFileId: null,
          lastBackupSize: null,
          lastError: lastError,
          lastBackupStatus: lastBackupStatus,
          lastRestoreStatus: lastRestoreStatus,
          lastBackupError: lastBackupError,
          lastRestoreError: lastRestoreError,
          dbHealthStatus: dbHealth,
          activeFkViolations: fkViolationsList,
          lastRestoreDate: lastRestoreDate,
          lastSyncDuration: lastSyncDuration,
          developerModeEnabled: devMode,
          localBackupStatus: localStatus,
          cloudUploadStatus: CloudUploadStatus.idle,
          cloudVerificationStatus: CloudVerificationStatus.pending,
          restoreStatus: restStatus,
        );
      }
    } catch (e) {
      await _handleErrorAndReauth(e, 'Failed to retrieve backup info');
    }
  }

  Future<void> setDeveloperModeEnabled(bool enabled) async {
    await _secureStorage.saveDeveloperModeEnabled(enabled);
    state = state.copyWith(developerModeEnabled: enabled);
  }

  Future<DatabaseRepairReport?> runDatabaseRepair() async {
    state = state.copyWith(isLoading: true);
    try {
      final repairService = _ref.read(databaseRepairServiceProvider);
      final report = await repairService.runRepair(currentUserId: _ref.read(authProvider).user?.id);
      
      // Re-load health info after repair
      final newHealth = await repairService.checkDatabaseHealth();
      final List<String> fkViolationsList = [];
      try {
        final db = _ref.read(databaseProvider);
        final fkRows = await db.customSelect('PRAGMA foreign_key_check;').get();
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
          } catch (_) {}

          fkViolationsList.add('Child: $childTable (rowid: $rowId), Parent: $parentTable, Missing Key ($fromCol): $missingVal');
        }
      } catch (_) {}
      
      state = state.copyWith(
        isLoading: false,
        dbHealthStatus: newHealth,
        lastRepairReport: report,
        activeFkViolations: fkViolationsList,
      );
      
      return report;
    } catch (e) {
      debugPrint('BackupNotifier: runDatabaseRepair failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Database repair failed: $e',
      );
      return null;
    }
  }

  Future<void> checkDbHealth() async {
    try {
      final repairService = _ref.read(databaseRepairServiceProvider);
      final newHealth = await repairService.checkDatabaseHealth();
      final List<String> fkViolationsList = [];
      try {
        final db = _ref.read(databaseProvider);
        final fkRows = await db.customSelect('PRAGMA foreign_key_check;').get();
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
          } catch (_) {}

          fkViolationsList.add('Child: $childTable (rowid: $rowId), Parent: $parentTable, Missing Key ($fromCol): $missingVal');
        }
      } catch (_) {}
      state = state.copyWith(
        dbHealthStatus: newHealth,
        activeFkViolations: fkViolationsList,
      );
    } catch (e) {
      debugPrint('BackupNotifier: checkDbHealth failed: $e');
    }
  }

  // Backup configuration settings setters
  Future<void> setBackupSchedule(String schedule) async {
    await _ref.read(appSettingsProvider.notifier).setSetting('backupSchedule', schedule);
  }

  Future<void> setBackupWifiOnly(bool value) async {
    await _ref.read(appSettingsProvider.notifier).setSetting('backupWifiOnly', value);
  }

  Future<void> setBackupChargingOnly(bool value) async {
    await _ref.read(appSettingsProvider.notifier).setSetting('backupChargingOnly', value);
  }

  Future<void> setGoogleDriveBackupEnabled(bool value) async {
    await _ref.read(appSettingsProvider.notifier).setSetting('googleDriveBackupEnabled', value);
  }

  // Google Sign-In account switches
  Future<void> switchGoogleAccount() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final googleSignIn = _ref.read(googleSignInProvider);
      
      await googleSignIn.signOut();
      await _secureStorage.deleteGoogleAccessToken();

      final account = await googleSignIn.signIn();
      if (account != null) {
        final auth = await account.authentication;
        if (auth.accessToken != null) {
          await _secureStorage.saveGoogleAccessToken(auth.accessToken!);
        }
        await _secureStorage.saveGoogleDriveBackupEnabled(true);
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Switched to account: ${account.email}',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Account switch cancelled.',
        );
      }
      await loadBackupInfo();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to switch account: $e',
      );
    }
  }

  Future<void> disconnectGoogleAccount() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final googleSignIn = _ref.read(googleSignInProvider);
      await googleSignIn.signOut();
      await _secureStorage.deleteGoogleAccessToken();
      await _secureStorage.saveGoogleDriveBackupEnabled(false);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Disconnected Google account successfully.',
      );
      await loadBackupInfo();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to disconnect account: $e',
      );
    }
  }

  Future<void> reconnectGoogleAccount() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final googleSignIn = _ref.read(googleSignInProvider);
      final account = googleSignIn.currentUser ?? await googleSignIn.signInSilently(
        reAuthenticate: false,
        suppressErrors: true,
      );
      if (account == null) {
        await signInWithGoogleInteractive();
      } else {
        final auth = await account.authentication;
        if (auth.accessToken != null) {
          await _secureStorage.saveGoogleAccessToken(auth.accessToken!);
        }
        await _secureStorage.saveGoogleDriveBackupEnabled(true);
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Reconnected account: ${account.email}',
        );
        await loadBackupInfo();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to reconnect account: $e',
      );
    }
  }

  // Periodic automatic scheduling routine
  Future<void> checkAndRunScheduledBackup() async {
    final auth = _ref.read(authProvider);
    final userId = auth.user?.id;
    if (userId == null) return;

    final schedule = await _secureStorage.getBackupSchedule() ?? 'manual';
    if (schedule == 'manual') return;

    final lastLocalStr = await _secureStorage.getLastLocalBackupDate();
    DateTime? lastLocal;
    if (lastLocalStr != null) {
      lastLocal = DateTime.tryParse(lastLocalStr);
    }

    if (lastLocal == null) {
      final localList = await _backupService.listLocalBackups(userId);
      if (localList.isNotEmpty) {
        final ts = localList.first['timestamp'] as int;
        lastLocal = DateTime.fromMillisecondsSinceEpoch(ts);
        await _secureStorage.saveLastLocalBackupDate(lastLocal.toIso8601String());
        await _secureStorage.saveLastLocalBackupSize(localList.first['size'] as int);
      }
    }

    if (lastLocal == null) {
      debugPrint('No local backup exists. Running initial scheduled backup...');
      await _runScheduledBackup(userId);
      return;
    }

    final now = DateTime.now();
    bool isDue = false;
    if (schedule == 'daily') {
      isDue = now.difference(lastLocal).inDays >= 1;
    } else if (schedule == 'weekly') {
      isDue = now.difference(lastLocal).inDays >= 7;
    } else if (schedule == 'monthly') {
      isDue = now.difference(lastLocal).inDays >= 30;
    }

    if (isDue) {
      final settings = _ref.read(appSettingsProvider);
      final wifiOnly = settings.backupWifiOnly;
      if (wifiOnly) {
        final isWifi = await DeviceStatus.isWifi();
        if (!isWifi) {
          debugPrint('Scheduled backup deferred: Not on Wi-Fi.');
          return;
        }
      }

      final chargingOnly = settings.backupChargingOnly;
      if (chargingOnly) {
        final isCharging = await DeviceStatus.isCharging();
        if (!isCharging) {
          debugPrint('Scheduled backup deferred: Device not charging.');
          return;
        }
      }

      debugPrint('Scheduled backup is due. Running backup...');
      await _runScheduledBackup(userId);
    }
  }

  Future<void> _runScheduledBackup(String userId) async {
    try {
      final driveEnabled = await _secureStorage.getGoogleDriveBackupEnabled() ?? false;
      drive.DriveApi? driveApi;
      if (driveEnabled) {
        driveApi = await _getDriveApi();
      }

      await _backupService.backup(userId, driveApi: driveApi);
      await loadBackupInfo();
    } catch (e) {
      debugPrint('Scheduled backup failed: $e');
    }
  }

  // Backup creation
  Future<void> createBackup({
    bool backupAiSettings = true,
    bool backupApiKeys = true,
    bool backupSelectedModels = true,
  }) async {
    final startTime = DateTime.now();
    final driveEnabled = !_backupService.isMockMode && (await _secureStorage.getGoogleDriveBackupEnabled() ?? false);
    final isCloud = driveEnabled || _backupService.isMockMode;
    final totalSteps = isCloud ? 7 : 4;
    final title = isCloud ? 'Backing Up to Google Drive' : 'Backing Up Locally';

    _progressTimer?.cancel();
    state = state.copyWith(
      isLoading: true,
      isBackingUp: true,
      isProgressVisible: true,
      isCancelled: false,
      progressTitle: title,
      progressPercentage: 0.0,
      progressStep: 1,
      progressTotalSteps: totalSteps,
      progressCurrentTask: 'Preparing backup...',
      progressElapsedTime: 0,
      progressEstimatedRemaining: isCloud ? 12 : 5,
      operationState: BackupOperationState.preparing,
      clearMessages: true,
    );

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final isRunning = state.isProgressVisible &&
          state.operationState != BackupOperationState.completed &&
          state.operationState != BackupOperationState.failed &&
          state.operationState != BackupOperationState.cancelled;

      if (isRunning) {
        final elapsed = state.progressElapsedTime + 1;
        final pct = state.progressPercentage;
        int remaining = 0;
        if (pct > 0.0 && pct < 1.0) {
          remaining = ((elapsed * (1.0 - pct)) / pct).round();
        } else if (pct == 0.0) {
          remaining = isCloud ? 12 : 5;
        }
        state = state.copyWith(
          progressElapsedTime: elapsed,
          progressEstimatedRemaining: remaining,
        );
      } else {
        timer.cancel();
      }
    });

    try {
      final auth = _ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) {
        throw Exception('User not authenticated.');
      }

      int size = 0;
      await _executeWithRetry((driveApi) async {
        if (state.isCancelled) throw BackupCancelledException();

        size = await _backupService.backup(
          userId,
          driveApi: driveApi,
          googleAccount: state.googleAccount,
          onProgress: (pct, step, total, task) {
            if (state.isCancelled) throw BackupCancelledException();

            BackupOperationState opState = BackupOperationState.preparing;
            LocalBackupStatus localStatus = state.localBackupStatus;
            CloudUploadStatus uploadStatus = state.cloudUploadStatus;
            CloudVerificationStatus verificationStatus = state.cloudVerificationStatus;

            if (pct >= 1.0) {
              opState = BackupOperationState.completed;
              localStatus = LocalBackupStatus.validated;
              if (isCloud) {
                uploadStatus = CloudUploadStatus.uploaded;
                verificationStatus = CloudVerificationStatus.verified;
              }
            } else if (step == 1) {
              opState = BackupOperationState.preparing;
            } else if (step == 2) {
              opState = BackupOperationState.exporting;
              localStatus = LocalBackupStatus.creating;
            } else if (step == 3) {
              opState = BackupOperationState.encrypting;
              localStatus = LocalBackupStatus.validated;
            } else if (step == 4) {
              opState = isCloud ? BackupOperationState.connecting : BackupOperationState.completed;
              if (!isCloud) {
                localStatus = LocalBackupStatus.validated;
              }
            } else if (step == 5) {
              opState = BackupOperationState.uploading;
              uploadStatus = CloudUploadStatus.uploading;
            } else if (step == 6) {
              opState = BackupOperationState.verifying;
              uploadStatus = CloudUploadStatus.uploaded;
              verificationStatus = CloudVerificationStatus.verifying;
            } else if (step == 7) {
              opState = BackupOperationState.completed;
              localStatus = LocalBackupStatus.validated;
              if (isCloud) {
                uploadStatus = CloudUploadStatus.uploaded;
                verificationStatus = CloudVerificationStatus.verified;
              }
            }

            state = state.copyWith(
              progressPercentage: pct,
              progressStep: step,
              progressTotalSteps: total,
              progressCurrentTask: task,
              operationState: opState,
              localBackupStatus: localStatus,
              cloudUploadStatus: uploadStatus,
              cloudVerificationStatus: verificationStatus,
            );
          },
        );
        
        try {
          if (state.isCancelled) throw BackupCancelledException();
          final firestoreSync = _ref.read(firestoreSyncServiceProvider);
          await firestoreSync.syncLocalToCloud(userId);
        } catch (e) {
          if (e is BackupCancelledException) rethrow;
          debugPrint('BackupNotifier: Firestore Sync failed: $e');
        }

        await _auditLogger.logEvent(
          userId: userId,
          eventType: 'backup_created',
          eventCategory: 'backup',
          description: 'Successfully created encrypted database backup.',
          metadata: {'backup_size': size, 'mode': driveApi == null ? 'mock_simulated' : 'google_drive'},
        );
      });
      
      final duration = DateTime.now().difference(startTime);
      await _secureStorage.saveLastSyncDuration(duration.inSeconds);

      final googleAcc = state.googleAccount;
      final currentBackupStatus = await _secureStorage.getLastBackupStatus(googleAccount: googleAcc);
      if (currentBackupStatus == null || currentBackupStatus == 'Successful' || currentBackupStatus == 'Failed') {
        await _secureStorage.saveLastBackupStatus('Successful', googleAccount: googleAcc);
      }
      if (!isCloud) {
        if (currentBackupStatus == 'DATABASE INTEGRITY FAILED' || currentBackupStatus == 'UPLOAD FAILED' || currentBackupStatus == 'Failed') {
          await _secureStorage.saveLastBackupStatus('LOCAL BACKUP CREATED', googleAccount: googleAcc);
        }
      }
      await _secureStorage.saveLastBackupError(null, googleAccount: googleAcc);

      _progressTimer?.cancel();
      state = state.copyWith(
        progressPercentage: 1.0,
        progressStep: totalSteps,
        progressCurrentTask: 'Backup completed successfully.',
        progressEstimatedRemaining: 0,
        operationState: BackupOperationState.completed,
        successMessage: 'Backup completed successfully.',
        localBackupStatus: LocalBackupStatus.validated,
        cloudUploadStatus: isCloud ? CloudUploadStatus.uploaded : CloudUploadStatus.idle,
        cloudVerificationStatus: isCloud ? CloudVerificationStatus.verified : CloudVerificationStatus.pending,
      );

      await loadBackupInfo();

      await Future.delayed(const Duration(seconds: 2));
      if (state.isProgressVisible && state.operationState == BackupOperationState.completed) {
        state = state.copyWith(
          isLoading: false,
          isBackingUp: false,
          isProgressVisible: false,
        );
      }
    } catch (e, st) {
      _progressTimer?.cancel();
      LocalBackupStatus localStatus = state.localBackupStatus;
      CloudUploadStatus uploadStatus = state.cloudUploadStatus;
      CloudVerificationStatus verificationStatus = state.cloudVerificationStatus;

      if (e is! BackupCancelledException) {
        if (state.operationState == BackupOperationState.preparing ||
            state.operationState == BackupOperationState.exporting) {
          localStatus = LocalBackupStatus.failed;
        } else if (state.operationState == BackupOperationState.uploading) {
          uploadStatus = CloudUploadStatus.failed;
        } else if (state.operationState == BackupOperationState.verifying) {
          verificationStatus = CloudVerificationStatus.failed;
        }
      }

      state = state.copyWith(
        isLoading: false,
        isBackingUp: false,
        progressEstimatedRemaining: 0,
        operationState: e is BackupCancelledException ? BackupOperationState.cancelled : BackupOperationState.failed,
        localBackupStatus: localStatus,
        cloudUploadStatus: uploadStatus,
        cloudVerificationStatus: verificationStatus,
      );

      final googleAcc = state.googleAccount;
      if (e is! BackupCancelledException) {
        final failure = FailureDetails.fromError(e, st, state.operationState.name);
        final currentBackupStatus = await _secureStorage.getLastBackupStatus(googleAccount: googleAcc);
        if (currentBackupStatus == null || currentBackupStatus == 'Successful' || currentBackupStatus == 'Failed') {
          await _secureStorage.saveLastBackupStatus('Failed', googleAccount: googleAcc);
        }
        await _secureStorage.saveLastBackupError(jsonEncode(failure.toJson()), googleAccount: googleAcc);
      }

      await _handleErrorAndReauth(e, 'Backup failed');
      
      final auth = _ref.read(authProvider);
      await _auditLogger.logEvent(
        userId: auth.user?.id,
        eventType: 'backup_failed',
        eventCategory: 'backup',
        description: 'Database backup failed: ${e.toString()}',
      );
    }
  }

  // Restore backup supporting local restore
  Future<void> restoreBackup([Map<String, dynamic>? selectedBackup, bool isLocal = false]) async {
    final bool resolvedIsLocal = isLocal || (selectedBackup != null && selectedBackup.containsKey('backupFilePath') && !selectedBackup.containsKey('backupFileId'));
    final isCloud = !resolvedIsLocal;
    final totalSteps = isCloud ? 7 : 6;
    final title = isCloud ? 'Restoring from Google Drive' : 'Restoring from Local Storage';

    _progressTimer?.cancel();
    state = state.copyWith(
      isLoading: true,
      isRestoring: true,
      isProgressVisible: true,
      isCancelled: false,
      progressTitle: title,
      progressPercentage: 0.0,
      progressStep: 1,
      progressTotalSteps: totalSteps,
      progressCurrentTask: 'Checking backup...',
      progressElapsedTime: 0,
      progressEstimatedRemaining: isCloud ? 15 : 8,
      operationState: BackupOperationState.preparing,
      clearMessages: true,
      restoreStatus: RestoreStatus.pending,
    );

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final isRunning = state.isProgressVisible &&
          state.operationState != BackupOperationState.completed &&
          state.operationState != BackupOperationState.failed &&
          state.operationState != BackupOperationState.cancelled;

      if (isRunning) {
        final elapsed = state.progressElapsedTime + 1;
        final pct = state.progressPercentage;
        int remaining = 0;
        if (pct > 0.0 && pct < 1.0) {
          remaining = ((elapsed * (1.0 - pct)) / pct).round();
        } else if (pct == 0.0) {
          remaining = isCloud ? 15 : 8;
        }
        state = state.copyWith(
          progressElapsedTime: elapsed,
          progressEstimatedRemaining: remaining,
        );
      } else {
        timer.cancel();
      }
    });

    try {
      final auth = _ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) {
        throw Exception('User not authenticated.');
      }

      await _executeWithRetry((driveApi) async {
        if (state.isCancelled) throw BackupCancelledException();

        Map<String, dynamic> targetBackup;
        if (selectedBackup != null) {
          targetBackup = selectedBackup;
        } else {
          if (resolvedIsLocal) {
            final locals = await _backupService.listLocalBackups(userId);
            if (locals.isEmpty) throw Exception('No local backup found.');
            targetBackup = locals.first;
          } else {
            final backups = await _backupService.listBackups(userId, driveApi: driveApi);
            if (backups.isEmpty) {
              throw Exception('No backup found in Google Drive appDataFolder.');
            }
            targetBackup = backups.first;
          }
        }

        await _backupService.restore(
          userId,
          backup: targetBackup,
          driveApi: driveApi,
          isLocal: resolvedIsLocal,
          onProgress: (pct, step, total, task) {
            if (state.isCancelled) throw BackupCancelledException();

            BackupOperationState opState = BackupOperationState.preparing;
            if (pct >= 1.0) {
              opState = BackupOperationState.completed;
            } else if (step == 1) {
              opState = BackupOperationState.preparing;
            } else if (step == 2) {
              opState = isCloud ? BackupOperationState.uploading : BackupOperationState.encrypting;
            } else if (step == 3) {
              opState = isCloud ? BackupOperationState.encrypting : BackupOperationState.verifying;
            } else if (step == 4) {
              opState = isCloud ? BackupOperationState.verifying : BackupOperationState.exporting;
            } else if (step == 5) {
              opState = isCloud ? BackupOperationState.exporting : BackupOperationState.verifying;
            } else if (step == 6) {
              opState = isCloud ? BackupOperationState.verifying : BackupOperationState.completed;
            } else if (step == 7) {
              opState = BackupOperationState.completed;
            }

            RestoreStatus restStatus = RestoreStatus.restoring;
            if (pct >= 1.0 || opState == BackupOperationState.completed) {
              restStatus = RestoreStatus.successful;
            }

            state = state.copyWith(
              progressPercentage: pct,
              progressStep: step,
              progressTotalSteps: total,
              progressCurrentTask: task,
              operationState: opState,
              restoreStatus: restStatus,
            );
          },
        );

        if (state.isCancelled) throw BackupCancelledException();
        await _ref.read(expenseListNotifierProvider.notifier).loadTransactions();

        await _auditLogger.logEvent(
          userId: userId,
          eventType: 'backup_restored',
          eventCategory: 'backup',
          description: 'Successfully decrypted and restored database backup.',
        );
      });

      await _secureStorage.saveLastRestoreDate(DateTime.now().toIso8601String());
      final googleAcc = state.googleAccount;
      final currentRestoreStatus = await _secureStorage.getLastRestoreStatus(googleAccount: googleAcc);
      if (currentRestoreStatus == null || currentRestoreStatus == 'Successful' || currentRestoreStatus == 'Failed') {
        await _secureStorage.saveLastRestoreStatus('Successful', googleAccount: googleAcc);
      }
      await _secureStorage.saveLastRestoreError(null, googleAccount: googleAcc);

      _progressTimer?.cancel();
      state = state.copyWith(
        progressPercentage: 1.0,
        progressStep: totalSteps,
        progressCurrentTask: 'Restore completed successfully.',
        progressEstimatedRemaining: 0,
        operationState: BackupOperationState.completed,
        successMessage: 'Database restored successfully! App database reloaded.',
        restoreStatus: RestoreStatus.successful,
      );

      await loadBackupInfo();

      await Future.delayed(const Duration(seconds: 2));
      if (state.isProgressVisible && state.operationState == BackupOperationState.completed) {
        state = state.copyWith(
          isLoading: false,
          isRestoring: false,
          isProgressVisible: false,
        );
      }
    } catch (e, st) {
      _progressTimer?.cancel();
      state = state.copyWith(
        isLoading: false,
        isRestoring: false,
        progressEstimatedRemaining: 0,
        operationState: e is BackupCancelledException ? BackupOperationState.cancelled : BackupOperationState.failed,
        restoreStatus: e is BackupCancelledException ? RestoreStatus.none : RestoreStatus.failed,
      );

      final googleAcc = state.googleAccount;
      if (e is! BackupCancelledException) {
        final failure = FailureDetails.fromError(e, st, state.operationState.name);
        final currentRestoreStatus = await _secureStorage.getLastRestoreStatus(googleAccount: googleAcc);
        if (currentRestoreStatus == null || currentRestoreStatus == 'Successful' || currentRestoreStatus == 'Failed') {
          await _secureStorage.saveLastRestoreStatus('Failed', googleAccount: googleAcc);
        }
        await _secureStorage.saveLastRestoreError(jsonEncode(failure.toJson()), googleAccount: googleAcc);
      }

      await _handleErrorAndReauth(e, 'Restore failed');

      final auth = _ref.read(authProvider);
      await _auditLogger.logEvent(
        userId: auth.user?.id,
        eventType: 'backup_restore_failed',
        eventCategory: 'backup',
        description: 'Database backup restoration failed: ${e.toString()}',
      );
    }
  }

  void cancelOperation() {
    _progressTimer?.cancel();
    state = state.copyWith(
      isCancelled: true,
      isProgressVisible: false,
      isLoading: false,
      isBackingUp: false,
      isRestoring: false,
      currentStatus: null,
      operationState: BackupOperationState.cancelled,
      errorMessage: 'Backup/Restore cancelled by user.',
    );
  }

  void dismissProgressDialog() {
    _progressTimer?.cancel();
    state = state.copyWith(
      isProgressVisible: false,
      isLoading: false,
      isBackingUp: false,
      isRestoring: false,
    );
  }

  Future<void> deleteBackup() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final auth = _ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) {
        throw Exception('User not authenticated.');
      }
      
      await _executeWithRetry((driveApi) async {
        await _backupService.deleteBackup(userId: userId, driveApi: driveApi);
        
        await _auditLogger.logEvent(
          userId: userId,
          eventType: 'backup_deleted',
          eventCategory: 'backup',
          description: 'Successfully deleted cloud database backup.',
        );
      });
      
      state = BackupState.initial().copyWith(
        successMessage: 'Cloud backup deleted successfully.',
      );

      await loadBackupInfo();
    } catch (e) {
      await _handleErrorAndReauth(e, 'Delete failed');
    }
  }

  Future<void> syncDatabase() async {
    final startTime = DateTime.now();
    state = state.copyWith(
      isLoading: true,
      isSyncing: true,
      currentStatus: 'Syncing with Google Drive...',
      clearMessages: true,
    );
    try {
      final auth = _ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) {
        throw Exception('User not authenticated.');
      }

      await _executeWithRetry((driveApi) async {
        final syncService = _ref.read(syncServiceProvider);
        final result = await syncService.sync(userId, driveApi: driveApi);

        try {
          final firestoreSync = _ref.read(firestoreSyncServiceProvider);
          await firestoreSync.syncLocalToCloud(userId);
          await firestoreSync.syncCloudToLocal(userId);
        } catch (e) {
          debugPrint('BackupNotifier: Firestore Sync failed: $e');
        }

        if (result.conflicts.isNotEmpty) {
          state = state.copyWith(
            isLoading: false,
            isSyncing: false,
            currentStatus: null,
            conflicts: result.conflicts,
            errorMessage: 'Sync complete with ${result.conflicts.length} conflict(s) requiring resolution.',
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            isSyncing: false,
            currentStatus: null,
            conflicts: [],
            successMessage: 'Backup completed successfully.',
          );
          await _ref.read(expenseListNotifierProvider.notifier).loadTransactions();
        }

        await _auditLogger.logEvent(
          userId: userId,
          eventType: 'database_sync',
          eventCategory: 'sync',
          description: 'Synchronized database. Conflicts found: ${result.conflicts.length}.',
          metadata: {'inserted': result.insertedCount, 'updated': result.updatedCount, 'conflicts': result.conflicts.length},
        );
      });

      final duration = DateTime.now().difference(startTime);
      await _secureStorage.saveLastSyncDuration(duration.inSeconds);

      await loadBackupInfo();
    } catch (e) {
      await _handleErrorAndReauth(e, 'Sync failed');
    }
  }

  Future<void> resolveConflict(String transactionId, Transaction chosenTx) async {
    state = state.copyWith(isLoading: true);
    try {
      final localDb = _ref.read(databaseProvider);
      await localDb.transactionDao.updateTransaction(chosenTx.copyWith(syncStatus: 'synced'));
      final newConflicts = state.conflicts.where((c) => c.local.id != transactionId).toList();
      
      state = state.copyWith(
        isLoading: false,
        conflicts: newConflicts,
      );

      if (newConflicts.isEmpty) {
        final auth = _ref.read(authProvider);
        final userId = auth.user?.id;
        if (userId != null) {
          final driveApi = await _getDriveApi();
          final localTxs = await localDb.transactionDao.getTransactionsForUser(userId);
          for (final tx in localTxs) {
            if (tx.syncStatus == 'pending' || tx.syncStatus == 'conflict') {
              await localDb.transactionDao.updateTransaction(tx.copyWith(syncStatus: 'synced'));
            }
          }
          await _backupService.backup(userId, driveApi: driveApi);
          state = state.copyWith(
            successMessage: 'All conflicts resolved! Database uploaded successfully.',
          );
        }
      }

      await _ref.read(expenseListNotifierProvider.notifier).loadTransactions();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Conflict resolution failed: ${e.toString()}',
      );
    }
  }

  Future<drive.DriveApi?> _getDriveApi({
    bool forceInteractive = false,
    bool forceRefresh = false,
  }) async {
    if (_backupService.isMockMode) return null;
    try {
      final googleSignIn = _ref.read(googleSignInProvider);
      
      GoogleSignInAccount? account;
      if (forceInteractive) {
        account = await googleSignIn.signIn();
      } else {
        if (forceRefresh) {
          account = await googleSignIn.signInSilently(
            reAuthenticate: false,
            suppressErrors: false,
          );
        } else {
          account = googleSignIn.currentUser ?? await googleSignIn.signInSilently(
            reAuthenticate: false,
            suppressErrors: true,
          );
        }
      }
      
      if (account != null) {
        final client = await googleSignIn.authenticatedClient();
        if (client != null) {
          return drive.DriveApi(client);
        }
      }
    } catch (e) {
      debugPrint('BackupNotifier: Google login failed: $e');
      rethrow;
    }
    return null;
  }

  Future<T> _executeWithRetry<T>(Future<T> Function(drive.DriveApi? driveApi) operation) async {
    if (_backupService.isMockMode) {
      return await operation(null);
    }

    drive.DriveApi? driveApi;
    try {
      driveApi = await _getDriveApi(forceRefresh: false);
    } catch (e) {
      debugPrint('BackupNotifier: Standard DriveApi acquisition failed. Retrying silent...');
    }

    if (driveApi == null) {
      try {
        driveApi = await _getDriveApi(forceRefresh: true);
      } catch (e) {
        throw Exception('Google Drive permission denied or authentication expired. Please sign in again.');
      }
      if (driveApi == null) {
        throw Exception('Google Drive permission denied or authentication expired. Please sign in again.');
      }
    }

    try {
      return await operation(driveApi);
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      bool isAuthError = errStr.contains('permission denied') ||
          errStr.contains('401') ||
          errStr.contains('403') ||
          errStr.contains('unauthorized') ||
          errStr.contains('sign in again');

      if (e is drive.DetailedApiRequestError && (e.status == 401 || e.status == 403)) {
        isAuthError = true;
      }

      if (isAuthError) {
        debugPrint('BackupNotifier: Auth error. Retrying with silent token refresh...');
        try {
          driveApi = await _getDriveApi(forceRefresh: true);
        } catch (refreshError) {
          throw Exception('Google Drive permission denied or authentication expired. Please sign in again.');
        }

        if (driveApi != null) {
          return await operation(driveApi);
        } else {
          throw Exception('Google Drive permission denied or authentication expired. Please sign in again.');
        }
      } else {
        rethrow;
      }
    }
  }

  Future<void> signInWithGoogleInteractive() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    drive.DriveApi? driveApi;
    try {
      driveApi = await _getDriveApi(forceInteractive: true);
    } catch (e) {
      debugPrint('BackupNotifier: Interactive sign in failed: $e');
    }
    
    if (driveApi != null) {
      await _secureStorage.saveGoogleDriveBackupEnabled(true);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Google Drive authorization successful!',
      );
      await loadBackupInfo();
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google Drive authorization failed or cancelled.',
      );
    }
  }

  Future<void> deleteSingleBackup(Map<String, dynamic> backup) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final auth = _ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) throw Exception('User not authenticated.');

      final isLocal = backup['isLocal'] as bool? ?? (backup.containsKey('backupFilePath') && !backup.containsKey('backupFileId'));
      if (isLocal) {
        final path = backup['backupFilePath'] as String;
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } else {
        await _executeWithRetry((driveApi) async {
          await _backupService.deleteSingleBackupFile(backup, driveApi);
        });
      }
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Backup deleted successfully.',
      );
      await loadBackupInfo();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete backup: $e',
      );
    }
  }

  Future<void> shareLocalBackup(String path) async {
    try {
      await Clipboard.setData(ClipboardData(text: path));
      state = state.copyWith(
        successMessage: 'Local backup path copied to clipboard: $path',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to copy path: $e',
      );
    }
  }

  Future<Map<String, dynamic>> getBackupDetails(Map<String, dynamic> backup) async {
    Map<String, dynamic>? details;
    await _executeWithRetry((driveApi) async {
      details = await _backupService.getBackupDetails(backup, driveApi: driveApi);
    });
    return details ?? {};
  }

  Future<Map<String, dynamic>> verifyBackupOnDemand(Map<String, dynamic> fileItem) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      Map<String, dynamic> result = {};
      final isLocal = fileItem['mimeType'] == 'application/json' || 
                      fileItem['name'].startsWith('metadata_') || 
                      (fileItem['id'] as String).contains('\\') || 
                      (fileItem['id'] as String).contains('/');
      
      if (isLocal) {
        result = await _backupService.verifyBackupFileOnDemand(filePath: fileItem['id'] as String);
      } else {
        await _executeWithRetry((driveApi) async {
          result = await _backupService.verifyBackupFileOnDemand(
            fileId: fileItem['id'] as String,
            driveApi: driveApi,
          );
        });
      }

      final isError = result['error'] != null || result['status'] == 'Corrupted';
      state = state.copyWith(
        isLoading: false,
        successMessage: isError ? null : 'File verification check: ${result['status']}',
        errorMessage: isError ? 'Verification failed: ${result['error'] ?? "Checksum mismatch"}' : null,
      );
      await loadBackupInfo();
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Verification failed: ${e.toString()}',
      );
      return {'status': 'Corrupted', 'error': e.toString()};
    }
  }

  Future<void> runGoogleDriveDiagnostics() async {
    if (state.isDiagnosticsRunning) return;
    
    state = state.copyWith(
      isDiagnosticsRunning: true,
      googleDriveDiagnosticReport: GoogleDriveDiagnosticReport(),
    );

    GoogleDriveDiagnosticReport report = GoogleDriveDiagnosticReport();
    
    // STEP 1: Google Sign-In
    try {
      final googleSignIn = _ref.read(googleSignInProvider);
      
      GoogleSignInAccount? account = googleSignIn.currentUser;
      if (account == null) {
        account = await googleSignIn.signInSilently(
          reAuthenticate: false,
          suppressErrors: true,
        );
      }

      if (account != null) {
        report = report.copyWith(
          step1SignIn: 'PASS',
          step1Details: 'Google Account: ${account.email}\nDisplay Name: ${account.displayName}\nID: ${account.id}\nRequested Scopes: email, profile, openid, drive.appdata\nGranted Scopes: ${googleSignIn.scopes.join(', ')}',
        );
      } else {
        throw Exception('Google Sign-In failed: No current user or silent sign-in returned null.');
      }
    } catch (e, st) {
      report = report.copyWith(
        step1SignIn: 'FAIL',
        step1Details: 'Error: $e',
        lastException: e.toString(),
        lastStackTrace: st.toString(),
      );
      state = state.copyWith(
        isDiagnosticsRunning: false,
        googleDriveDiagnosticReport: report,
      );
      return;
    }

    state = state.copyWith(googleDriveDiagnosticReport: report);

    // STEP 2: Authenticated HTTP Client
    late dynamic client;
    try {
      final googleSignIn = _ref.read(googleSignInProvider);
      
      debugPrint('GoogleSignIn.currentUser: ${googleSignIn.currentUser}');
      debugPrint('requested scopes: ${googleSignIn.scopes}');
      
      GoogleSignInAccount? account = googleSignIn.currentUser;
      if (account == null) {
        debugPrint('currentUser is null, trying signInSilently...');
        account = await googleSignIn.signInSilently(
          reAuthenticate: false,
          suppressErrors: true,
        );
        debugPrint('signInSilently result: $account');
      }
      
      if (account == null) {
        debugPrint('currentUser still null, trying interactive signIn...');
        account = await googleSignIn.signIn();
        debugPrint('interactive signIn result: $account');
      }

      if (account == null) {
        throw Exception('Google Sign-In Account is required to create authenticated client, but currentUser is null.');
      }

      debugPrint('currentUser email: ${account.email}');
      debugPrint('currentUser id: ${account.id}');
      debugPrint('isSignedIn(): ${await googleSignIn.isSignedIn()}');

      client = await googleSignIn.authenticatedClient();
      if (client == null) {
        throw Exception(
          'authenticatedClient() returned null.\n'
          'GoogleSignIn.currentUser: ${googleSignIn.currentUser}\n'
          'requested scopes: ${googleSignIn.scopes}\n'
          'isSignedIn(): ${await googleSignIn.isSignedIn()}'
        );
      }
      
      final credentials = client.credentials;
      final accessToken = credentials.accessToken.data;
      final expiry = credentials.accessToken.expiry;
      
      report = report.copyWith(
        step2Client: 'PASS',
        step2Details: 'OAuth Token Available: ${accessToken.isNotEmpty ? "Yes" : "No"}\nToken Expiry: ${expiry.toIso8601String()}',
      );
    } catch (e, st) {
      report = report.copyWith(
        step2Client: 'FAIL',
        step2Details: 'Error: $e',
        lastException: e.toString(),
        lastStackTrace: st.toString(),
      );
      state = state.copyWith(
        isDiagnosticsRunning: false,
        googleDriveDiagnosticReport: report,
      );
      return;
    }

    state = state.copyWith(googleDriveDiagnosticReport: report);

    // STEP 3: Drive API Creation
    late drive.DriveApi driveApi;
    try {
      driveApi = drive.DriveApi(client);
      report = report.copyWith(
        step3Api: 'PASS',
        step3Details: 'Drive API client successfully created.',
      );
    } catch (e, st) {
      report = report.copyWith(
        step3Api: 'FAIL',
        step3Details: 'Error: $e',
        lastException: e.toString(),
        lastStackTrace: st.toString(),
      );
      state = state.copyWith(
        isDiagnosticsRunning: false,
        googleDriveDiagnosticReport: report,
      );
      return;
    }

    state = state.copyWith(googleDriveDiagnosticReport: report);

    // STEP 4: Google Drive AppData Verification
    try {
      final allFiles = await _backupService.listAllAppDataFiles(driveApi);

      debugPrint('==================================================');
      debugPrint('GOOGLE DRIVE APPDATA FILE LISTING (Diagnostics):');
      for (var f in allFiles) {
        debugPrint('• File ID:      ${f['id']}');
        debugPrint('  Name:         ${f['name']}');
        debugPrint('  Size:         ${f['size']} bytes');
        debugPrint('  Created Time: ${f['createdTime']}');
        debugPrint('  Modified Time:${f['modifiedTime']}');
        debugPrint('  Checksum:     ${f['checksum']}');
        debugPrint('--------------------------------------------------');
      }
      debugPrint('==================================================');

      final buffer = StringBuffer();
      buffer.writeln('AppData Folder accessible. Found ${allFiles.length} files:');
      for (var f in allFiles) {
        buffer.writeln('• ID: ${f['id']}\n  Name: ${f['name']}\n  Size: ${f['size']} bytes\n  Modified: ${f['modifiedTime']}\n  Checksum: ${f['checksum']}\n');
      }

      report = report.copyWith(
        step4AppData: 'PASS',
        step4Details: buffer.toString(),
      );
    } catch (e, st) {
      int? status;
      if (e is drive.DetailedApiRequestError) {
        status = e.status;
      }
      report = report.copyWith(
        step4AppData: 'FAIL',
        step4Details: 'Error: $e',
        lastHttpStatus: status,
        lastException: e.toString(),
        lastStackTrace: st.toString(),
      );
      state = state.copyWith(
        isDiagnosticsRunning: false,
        googleDriveDiagnosticReport: report,
      );
      return;
    }

    state = state.copyWith(googleDriveDiagnosticReport: report);

    // STEP 5: Create Temporary Test File
    late String testFileId;
    final auth = _ref.read(authProvider);
    final userId = auth.user?.id ?? 'unknown_user';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testFileName = 'expenso_diagnostics_backup_test_${userId}_$timestamp.expbk';
    late List<int> testData;
    try {
      // 1. Create a real encrypted backup
      testData = await _backupService.backupLocal(userId);

      final fileMetadata = drive.File()
        ..name = testFileName
        ..parents = ['appDataFolder']
        ..mimeType = 'application/octet-stream'
        ..appProperties = {
          'test_diagnostics': 'true',
          'checksum': sha256.convert(testData).toString(),
        };

      final media = drive.Media(
        Stream.value(testData),
        testData.length,
      );

      final startTime = DateTime.now();
      final uploadedFile = await driveApi.files.create(fileMetadata, uploadMedia: media) as drive.File;
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      testFileId = uploadedFile.id ?? '';
      if (testFileId.isEmpty) {
        throw Exception('Upload completed but Google returned no file ID.');
      }

      report = report.copyWith(
        step5Upload: 'PASS',
        step5Details: 'File Uploaded Successfully!\nFile ID: $testFileId\nName: $testFileName\nSize: ${testData.length} bytes\nDuration: ${duration}ms\nHTTP Status Code: 200 (Success)',
      );
    } catch (e, st) {
      int? status;
      if (e is drive.DetailedApiRequestError) {
        status = e.status;
      }
      report = report.copyWith(
        step5Upload: 'FAIL',
        step5Details: 'Error: $e',
        lastHttpStatus: status,
        lastException: e.toString(),
        lastStackTrace: st.toString(),
      );
      state = state.copyWith(
        isDiagnosticsRunning: false,
        googleDriveDiagnosticReport: report,
      );
      return;
    }

    state = state.copyWith(googleDriveDiagnosticReport: report);

    // STEP 6: Upload Verification
    try {
      final verifiedFile = await driveApi.files.get(
        testFileId,
        $fields: 'id, name, mimeType, size, parents, appProperties',
      ) as drive.File;

      report = report.copyWith(
        step6Get: 'PASS',
        step6Details: 'File verified exists in AppData!\nFile ID: ${verifiedFile.id}\nName: ${verifiedFile.name}\nParents: ${verifiedFile.parents?.join(', ')}\nHTTP Status Code: 200 (Success)',
      );
    } catch (e, st) {
      int? status;
      if (e is drive.DetailedApiRequestError) {
        status = e.status;
      }
      report = report.copyWith(
        step6Get: 'FAIL',
        step6Details: 'Error: $e',
        lastHttpStatus: status,
        lastException: e.toString(),
        lastStackTrace: st.toString(),
      );
      state = state.copyWith(
        isDiagnosticsRunning: false,
        googleDriveDiagnosticReport: report,
      );
      return;
    }

    state = state.copyWith(googleDriveDiagnosticReport: report);

    // STEP 7: Download Verification
    try {
      final downloadStartTime = DateTime.now();
      final downloadRes = await driveApi.files.get(
        testFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      if (downloadRes is! drive.Media) {
        throw Exception('Download response is not a Media object.');
      }

      final builder = BytesBuilder();
      await for (final chunk in downloadRes.stream) {
        builder.add(chunk);
      }
      final downloadedBytes = builder.toBytes();
      final downloadDuration = DateTime.now().difference(downloadStartTime).inMilliseconds;
      final downloadedChecksum = sha256.convert(downloadedBytes).toString();
      final sourceChecksum = sha256.convert(testData).toString();

      if (downloadedBytes.length != testData.length) {
        throw Exception('Size mismatch: expected ${testData.length} bytes, got ${downloadedBytes.length} bytes.');
      }
      if (downloadedChecksum != sourceChecksum) {
        throw Exception('Checksum mismatch.');
      }

      report = report.copyWith(
        step7Download: 'PASS',
        step7Details: 'File downloaded successfully!\nVerified Checksum: $downloadedChecksum\nVerified Size: ${downloadedBytes.length} bytes\nDuration: ${downloadDuration}ms\nHTTP Status Code: 200 (Success)',
      );
    } catch (e, st) {
      int? status;
      if (e is drive.DetailedApiRequestError) {
        status = e.status;
      }
      report = report.copyWith(
        step7Download: 'FAIL',
        step7Details: 'Error: $e',
        lastHttpStatus: status,
        lastException: e.toString(),
        lastStackTrace: st.toString(),
      );
      state = state.copyWith(
        isDiagnosticsRunning: false,
        googleDriveDiagnosticReport: report,
      );
      return;
    }

    state = state.copyWith(googleDriveDiagnosticReport: report);

    // STEP 8: Delete Temporary File
    try {
      await driveApi.files.delete(testFileId);
      report = report.copyWith(
        step8Delete: 'PASS',
        step8Details: 'Temporary test file deleted successfully from AppData folder.\nHTTP Status Code: 200 (Success)',
      );
    } catch (e, st) {
      int? status;
      if (e is drive.DetailedApiRequestError) {
        status = e.status;
      }
      report = report.copyWith(
        step8Delete: 'FAIL',
        step8Details: 'Error: $e',
        lastHttpStatus: status,
        lastException: e.toString(),
        lastStackTrace: st.toString(),
      );
    }

    state = state.copyWith(
      isDiagnosticsRunning: false,
      googleDriveDiagnosticReport: report,
    );
  }
}

final StateNotifierProvider<BackupNotifier, BackupState> backupNotifierProvider =
    StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  final auditLogger = ref.watch(auditLoggerProvider);
  return BackupNotifier(backupService, auditLogger, ref);
});
