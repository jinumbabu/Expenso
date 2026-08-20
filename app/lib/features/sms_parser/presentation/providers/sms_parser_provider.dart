import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'dart:developer' as dev;
import '../../../../core/services/balance_engine.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/dao/transaction_draft_dao.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/services/sms_agent.dart';
import '../../../../core/services/ledger_agent.dart';
import '../../../../core/services/parser_agent.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/sms_account_matcher.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../budgets/presentation/screens/budgets_screen.dart';
import '../../../../core/security/audit_logger.dart';
import '../../../../core/services/sms_background_processor.dart';

final Provider<TransactionDraftDao> transactionDraftDaoProvider = Provider<TransactionDraftDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.transactionDraftDao;
});


// Watch Transaction Drafts Stream Provider
final StreamProvider<List<TransactionDraft>> transactionDraftsStreamProvider = StreamProvider<List<TransactionDraft>>((ref) {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return const Stream.empty();
  final db = ref.watch(databaseProvider);
  return db.transactionDraftDao.watchDraftsForUser(userId);
});

// Watch Unrecognized Messages Stream Provider
final StreamProvider<List<UnrecognizedMessage>> unrecognizedMessagesStreamProvider = StreamProvider<List<UnrecognizedMessage>>((ref) {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return const Stream.empty();
  final db = ref.watch(databaseProvider);
  return db.unrecognizedMessageDao.watchUnrecognizedMessagesForUser(userId);
});

// SMS Scanner State
class SmsScannerState {
  final bool isScanning;
  final String? errorMessage;
  final int newTransactionsCount;
  final int unrecognizedCount;
  final DateTime? lastSyncTime;
  final PermissionStatus smsPermissionStatus;
  final PermissionStatus notificationPermissionStatus;
  final bool autoImportEnabled;
  final bool autoScanNewSms;
  final bool smsNotificationsEnabled;
  final DateTime? lastPermissionRequestTime;
  final bool isInboxAccessible;
  final int scannedSmsCount;
  final int detectedTransactionsCount;
  final int totalBackgroundSms;
  final int autoSavedCount;
  final int duplicateCount;
  final int ignoredCount;
  final int pendingCount;
  final DateTime? lastProcessedTime;
  final String? lastError;
  final String backgroundReceiverStatus;

  SmsScannerState({
    this.isScanning = false,
    this.errorMessage,
    this.newTransactionsCount = 0,
    this.unrecognizedCount = 0,
    this.lastSyncTime,
    this.smsPermissionStatus = PermissionStatus.denied,
    this.notificationPermissionStatus = PermissionStatus.denied,
    this.autoImportEnabled = true,
    this.autoScanNewSms = true,
    this.smsNotificationsEnabled = true,
    this.lastPermissionRequestTime,
    this.isInboxAccessible = false,
    this.scannedSmsCount = 0,
    this.detectedTransactionsCount = 0,
    this.totalBackgroundSms = 0,
    this.autoSavedCount = 0,
    this.duplicateCount = 0,
    this.ignoredCount = 0,
    this.pendingCount = 0,
    this.lastProcessedTime,
    this.lastError,
    this.backgroundReceiverStatus = "READY",
  });

  SmsScannerState copyWith({
    bool? isScanning,
    String? errorMessage,
    int? newTransactionsCount,
    int? unrecognizedCount,
    DateTime? lastSyncTime,
    PermissionStatus? smsPermissionStatus,
    PermissionStatus? notificationPermissionStatus,
    bool? autoImportEnabled,
    bool? autoScanNewSms,
    bool? smsNotificationsEnabled,
    DateTime? lastPermissionRequestTime,
    bool? isInboxAccessible,
    int? scannedSmsCount,
    int? detectedTransactionsCount,
    int? totalBackgroundSms,
    int? autoSavedCount,
    int? duplicateCount,
    int? ignoredCount,
    int? pendingCount,
    DateTime? lastProcessedTime,
    String? lastError,
    String? backgroundReceiverStatus,
  }) {
    return SmsScannerState(
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
      newTransactionsCount: newTransactionsCount ?? this.newTransactionsCount,
      unrecognizedCount: unrecognizedCount ?? this.unrecognizedCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      smsPermissionStatus: smsPermissionStatus ?? this.smsPermissionStatus,
      notificationPermissionStatus: notificationPermissionStatus ?? this.notificationPermissionStatus,
      autoImportEnabled: autoImportEnabled ?? this.autoImportEnabled,
      autoScanNewSms: autoScanNewSms ?? this.autoScanNewSms,
      smsNotificationsEnabled: smsNotificationsEnabled ?? this.smsNotificationsEnabled,
      lastPermissionRequestTime: lastPermissionRequestTime ?? this.lastPermissionRequestTime,
      isInboxAccessible: isInboxAccessible ?? this.isInboxAccessible,
      scannedSmsCount: scannedSmsCount ?? this.scannedSmsCount,
      detectedTransactionsCount: detectedTransactionsCount ?? this.detectedTransactionsCount,
      totalBackgroundSms: totalBackgroundSms ?? this.totalBackgroundSms,
      autoSavedCount: autoSavedCount ?? this.autoSavedCount,
      duplicateCount: duplicateCount ?? this.duplicateCount,
      ignoredCount: ignoredCount ?? this.ignoredCount,
      pendingCount: pendingCount ?? this.pendingCount,
      lastProcessedTime: lastProcessedTime ?? this.lastProcessedTime,
      lastError: lastError ?? this.lastError,
      backgroundReceiverStatus: backgroundReceiverStatus ?? this.backgroundReceiverStatus,
    );
  }
}

// SMS Scanner Notifier
class SmsScannerNotifier extends StateNotifier<SmsScannerState> with WidgetsBindingObserver {
  final AppDatabase _db;
  final String? _userId;
  final SmsAgent _smsAgent;
  final LedgerAgent _ledgerAgent;
  final NotificationService _notificationService;
  final SecureStorageService _secureStorage;
  final Ref _ref;

  final SmsQuery _smsQuery = SmsQuery();
  static const MethodChannel _channel = MethodChannel('com.expenso.ai.app/sms');

  SmsScannerNotifier({
    required AppDatabase db,
    required String? userId,
    required SmsAgent smsAgent,
    required LedgerAgent ledgerAgent,
    required NotificationService notificationService,
    required SecureStorageService secureStorage,
    required Ref ref,
  })  : _db = db,
        _userId = userId,
        _smsAgent = smsAgent,
        _ledgerAgent = ledgerAgent,
        _notificationService = notificationService,
        _secureStorage = secureStorage,
        _ref = ref,
        super(SmsScannerState()) {
    WidgetsBinding.instance.addObserver(this);
    _initChannel();
    _loadLastSyncTime();
    _loadStats();
    _runStartupSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkPermissions().then((_) {
        if (this.state.smsPermissionStatus.isGranted && this.state.autoImportEnabled) {
          scanInbox(silent: true);
        }
      });
    }
  }

  Future<void> _loadStats() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final scannedResult = await _db.customSelect('SELECT COUNT(*) as c FROM raw_sms').getSingleOrNull();
      final scanned = scannedResult?.read<int>('c') ?? 0;

      final drafts = await _db.transactionDraftDao.getDraftsForUser(userId);
      final pending = drafts.length;

      final savedResult = await _db.customSelect(
        'SELECT COUNT(*) as c FROM transactions WHERE user_id = ? AND source = ? AND deleted_at IS NULL',
        variables: [Variable<String>(userId), Variable<String>('sms')],
      ).getSingleOrNull();
      final saved = savedResult?.read<int>('c') ?? 0;

      // Load background stats from secure storage
      final totalScannedStr = await _secureStorage.read('sms_stats_total_scanned') ?? '0';
      final autoSavedStr = await _secureStorage.read('sms_stats_auto_saved_count') ?? '0';
      final dupStr = await _secureStorage.read('sms_stats_duplicate_count') ?? '0';
      final ignStr = await _secureStorage.read('sms_stats_ignored_count') ?? '0';
      final pendStr = await _secureStorage.read('sms_stats_pending_count') ?? '0';
      final lastProcStr = await _secureStorage.read('sms_stats_last_processed_time');
      final lastErr = await _secureStorage.read('sms_stats_last_error');

      DateTime? lastProc;
      if (lastProcStr != null) {
        lastProc = DateTime.tryParse(lastProcStr);
      }

      state = state.copyWith(
        scannedSmsCount: scanned,
        detectedTransactionsCount: pending + saved,
        totalBackgroundSms: int.tryParse(totalScannedStr) ?? 0,
        autoSavedCount: int.tryParse(autoSavedStr) ?? 0,
        duplicateCount: int.tryParse(dupStr) ?? 0,
        ignoredCount: int.tryParse(ignStr) ?? 0,
        pendingCount: int.tryParse(pendStr) ?? 0,
        lastProcessedTime: lastProc,
        lastError: lastErr,
        backgroundReceiverStatus: "READY",
      );
    } catch (e) {
      dev.log("SmsScannerNotifier: Error loading stats: $e");
    }
  }

  Future<void> _loadLastSyncTime() async {
    final lastTime = await _secureStorage.getLastSmsSyncTime();
    if (lastTime != null) {
      state = state.copyWith(lastSyncTime: lastTime);
    }
  }

  Future<void> _runStartupSync() async {
    // Wait slightly for app to complete layout, unless in test environment
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    await checkPermissions();

    final hasRequested = await _secureStorage.getHasRequestedSmsPermission();
    final autoImport = state.autoImportEnabled;
    final userId = _userId;

    if (!state.smsPermissionStatus.isGranted && !hasRequested) {
      await requestAllPermissions();
      await _secureStorage.saveHasRequestedSmsPermission(true);
    } else if (state.smsPermissionStatus.isGranted && autoImport) {
      await scanInbox(silent: true);
    } else if (!state.smsPermissionStatus.isGranted && autoImport && hasRequested && userId != null) {
      // SMS permission is missing, notify the user
      await _notificationService.sendProactiveAlert(
        userId,
        title: 'SMS Permission Required ⚠️',
        body: 'Expenso needs SMS permission to automatically import bank alerts.',
        priority: 'medium',
      );
    }
  }

  Future<void> checkPermissions() async {
    PermissionStatus smsStatus = PermissionStatus.denied;
    PermissionStatus notifStatus = PermissionStatus.denied;

    try {
      smsStatus = await Permission.sms.status;
      notifStatus = await Permission.notification.status;
    } catch (e) {
      dev.log("SmsScannerNotifier: Error checking permissions status: $e");
    }

    final autoImport = await _secureStorage.getAutoImportEnabled();
    final autoScan = await _secureStorage.getAutoScanNewSms() ?? true;
    final smsNotifs = await _secureStorage.getSmsNotificationsEnabled() ?? true;
    final lastReq = await _secureStorage.getLastPermissionRequestTime();
    
    bool inboxOk = false;
    if (smsStatus.isGranted) {
      try {
        await _smsQuery.querySms(kinds: [SmsQueryKind.inbox], count: 1);
        inboxOk = true;
      } catch (e) {
        dev.log("SmsScannerNotifier: Inbox test query failed: $e");
      }
    }

    state = state.copyWith(
      smsPermissionStatus: smsStatus,
      notificationPermissionStatus: notifStatus,
      autoImportEnabled: autoImport,
      autoScanNewSms: autoScan,
      smsNotificationsEnabled: smsNotifs,
      lastPermissionRequestTime: lastReq,
      isInboxAccessible: inboxOk,
    );
  }

  Future<void> requestSmsPermission() async {
    final now = DateTime.now();
    await _secureStorage.saveLastPermissionRequestTime(now);
    
    final auditLogger = _ref.read(auditLoggerProvider);
    await auditLogger.logEvent(
      userId: _userId,
      eventType: 'sms_permission_request_attempt',
      eventCategory: 'security',
      description: 'Attempting to request SMS runtime permission.',
    );

    PermissionStatus status = PermissionStatus.denied;
    try {
      status = await Permission.sms.request();
    } catch (e) {
      dev.log("SmsScannerNotifier: Error requesting SMS permission: $e");
    }

    await auditLogger.logEvent(
      userId: _userId,
      eventType: 'sms_permission_updated',
      eventCategory: 'security',
      description: 'SMS permission request completed. New status: ${status.toString()}',
      metadata: {'status': status.toString()},
    );

    await checkPermissions();

    if (status.isGranted && state.autoImportEnabled) {
      await scanInbox(silent: true);
    }
  }

  Future<void> requestNotificationPermission() async {
    final now = DateTime.now();
    await _secureStorage.saveLastPermissionRequestTime(now);

    final auditLogger = _ref.read(auditLoggerProvider);
    await auditLogger.logEvent(
      userId: _userId,
      eventType: 'notification_permission_request_attempt',
      eventCategory: 'security',
      description: 'Attempting to request Notification runtime permission.',
    );

    PermissionStatus status = PermissionStatus.denied;
    try {
      status = await Permission.notification.request();
    } catch (e) {
      dev.log("SmsScannerNotifier: Error requesting notification permission: $e");
    }

    await auditLogger.logEvent(
      userId: _userId,
      eventType: 'notification_permission_updated',
      eventCategory: 'security',
      description: 'Notification permission request completed. New status: ${status.toString()}',
      metadata: {'status': status.toString()},
    );

    await checkPermissions();
  }

  Future<void> requestAllPermissions() async {
    final now = DateTime.now();
    await _secureStorage.saveLastPermissionRequestTime(now);

    final auditLogger = _ref.read(auditLoggerProvider);
    await auditLogger.logEvent(
      userId: _userId,
      eventType: 'all_permissions_request_attempt',
      eventCategory: 'security',
      description: 'Attempting to request SMS and Notification runtime permissions.',
    );

    try {
      final statuses = await [
        Permission.sms,
        Permission.notification,
      ].request();

      final smsStatus = statuses[Permission.sms] ?? PermissionStatus.denied;
      final notifStatus = statuses[Permission.notification] ?? PermissionStatus.denied;

      await auditLogger.logEvent(
        userId: _userId,
        eventType: 'permissions_updated',
        eventCategory: 'security',
        description: 'Runtime permissions requested. SMS: $smsStatus, Notification: $notifStatus',
        metadata: {'smsStatus': smsStatus.toString(), 'notificationStatus': notifStatus.toString()},
      );
    } catch (e) {
      dev.log("SmsScannerNotifier: Error requesting all permissions: $e");
    }

    await checkPermissions();

    if (state.smsPermissionStatus.isGranted && state.autoImportEnabled) {
      await scanInbox(silent: true);
    }
  }

  Future<void> toggleAutoImport(bool value) async {
    await _secureStorage.saveAutoImportEnabled(value);
    
    final auditLogger = _ref.read(auditLoggerProvider);
    await auditLogger.logEvent(
      userId: _userId,
      eventType: 'auto_import_toggled',
      eventCategory: 'security',
      description: 'Auto-import SMS preference updated to $value.',
      metadata: {'autoImport': value},
    );

    await checkPermissions();

    if (value && state.smsPermissionStatus.isGranted) {
      await scanInbox(silent: true);
    }
  }

  Future<void> toggleAutoScanNewSms(bool value) async {
    await _secureStorage.saveAutoScanNewSms(value);
    
    final auditLogger = _ref.read(auditLoggerProvider);
    await auditLogger.logEvent(
      userId: _userId,
      eventType: 'sms_auto_scan_toggled',
      eventCategory: 'security',
      description: 'Auto-scan new SMS preference updated to $value.',
      metadata: {'autoScan': value},
    );

    await checkPermissions();
  }

  Future<void> toggleSmsNotificationsEnabled(bool value) async {
    await _secureStorage.saveSmsNotificationsEnabled(value);
    
    final auditLogger = _ref.read(auditLoggerProvider);
    await auditLogger.logEvent(
      userId: _userId,
      eventType: 'sms_notifications_toggled',
      eventCategory: 'security',
      description: 'SMS notifications preference updated to $value.',
      metadata: {'notificationsEnabled': value},
    );

    await checkPermissions();
  }

  Future<bool> runPermissionTest() async {
    final auditLogger = _ref.read(auditLoggerProvider);
    await auditLogger.logEvent(
      userId: _userId,
      eventType: 'permission_test_run',
      eventCategory: 'security',
      description: 'Running manual permission test for SMS inbox accessibility.',
    );

    bool success = false;
    try {
      await _smsQuery.querySms(kinds: [SmsQueryKind.inbox], count: 1);
      success = true;
      dev.log("SmsScannerNotifier: SMS inbox test succeeded.");
    } catch (e) {
      dev.log("SmsScannerNotifier: SMS inbox test failed: $e");
    }

    await auditLogger.logEvent(
      userId: _userId,
      eventType: 'permission_test_result',
      eventCategory: 'security',
      description: 'Permission test completed. Success: $success',
      metadata: {'success': success},
    );

    await checkPermissions();
    return success;
  }

  void _initChannel() {
    _channel.setMethodCallHandler((call) async {
      dev.log("SmsScannerNotifier: Method channel call received: ${call.method}");
      if (call.method == 'onSmsReceived') {
        final args = Map<String, dynamic>.from(call.arguments);
        final String? sender = args['sender'];
        final String? body = args['body'];
        final int? timestamp = args['timestamp'];
        if (body != null) {
          final date = timestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(timestamp)
              : DateTime.now();
          await _handleIncomingSms(sender, body, date);
        }
      }
    });
  }

  Future<void> _handleIncomingSms(String? sender, String body, DateTime date) async {
    final userId = _userId;
    if (userId == null) return;
    if (!state.autoImportEnabled) {
      dev.log("SmsScannerNotifier: SMS Processing is disabled. Skipping incoming message.");
      return;
    }
    if (!state.autoScanNewSms) {
      dev.log("SmsScannerNotifier: Automatic SMS Scanning is disabled. Skipping incoming message.");
      return;
    }
    try {
      dev.log("SmsScannerNotifier: Delegating incoming SMS to SmsBackgroundProcessor");
      await SmsBackgroundProcessor.processIncomingSms(
        sender: sender,
        body: body,
        date: date,
        userId: userId,
        db: _db,
        smsAgent: _smsAgent,
        ledgerAgent: _ledgerAgent,
        notificationService: _notificationService,
        secureStorage: _secureStorage,
        onUiInvalidate: () {
          _ref.invalidate(transactionDraftsStreamProvider);
          _invalidateUi();
        },
      );
    } catch (e) {
      dev.log("SmsScannerNotifier: Error handling incoming SMS: $e");
    }
  }

  bool _isTransactionKeywordsMatch(String body) {
    final lower = body.toLowerCase();
    return lower.contains('debited') ||
        lower.contains('credited') ||
        lower.contains('spent') ||
        lower.contains('withdrawn') ||
        lower.contains('deposited');
  }

  Future<void> scanInbox({bool silent = false}) async {
    final userId = _userId;
    if (userId == null) {
      if (!silent) {
        state = state.copyWith(errorMessage: 'User not authenticated.');
      }
      return;
    }

    if (!state.autoImportEnabled && silent) {
      dev.log("SmsScannerNotifier: SMS Auto-Import is disabled. Aborting background/startup scan.");
      return;
    }

    if (!silent) {
      state = state.copyWith(isScanning: true, errorMessage: null);
    }

    try {
      final permission = await Permission.sms.status;
      if (!permission.isGranted) {
        if (silent) return; // Do not prompt on silent scans
        final now = DateTime.now();
        await _secureStorage.saveLastPermissionRequestTime(now);
        final auditLogger = _ref.read(auditLoggerProvider);
        await auditLogger.logEvent(
          userId: userId,
          eventType: 'sms_permission_request_attempt',
          eventCategory: 'security',
          description: 'Attempting to request SMS runtime permission during manual scan.',
        );
        final request = await Permission.sms.request();
        await auditLogger.logEvent(
          userId: userId,
          eventType: 'sms_permission_updated',
          eventCategory: 'security',
          description: 'SMS permission request completed during manual scan. New status: ${request.toString()}',
          metadata: {'status': request.toString()},
        );
        await checkPermissions();
        if (!request.isGranted) {
          state = state.copyWith(
            isScanning: false,
            errorMessage: 'SMS permission denied.',
            smsPermissionStatus: request,
          );
          if (request.isPermanentlyDenied) {
            openAppSettings();
          }
          return;
        }
      }

      // Query historical messages since lastSyncTime, default to last 30 days
      final lastSync = await _secureStorage.getLastSmsSyncTime();
      final DateTime fetchSince = lastSync ?? DateTime.now().subtract(const Duration(days: 30));

      final messages = await _smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
      );

      final accounts = await (_db.select(_db.accounts)..where((a) => a.userId.equals(userId))).get();
      final paymentMethods = await (_db.select(_db.paymentMethods)..where((pm) => pm.userId.equals(userId) | pm.userId.equals('system'))).get();
      final categories = await _db.categoryDao.getCategoriesForUser(userId);

      final lastFewDays = DateTime.now().subtract(const Duration(days: 3));
      final existingTransactions = await (_db.select(_db.transactions)
        ..where((t) => t.userId.equals(userId) & t.date.isBiggerOrEqualValue(lastFewDays) & t.deletedAt.isNull())
      ).get();

      bool isSelfTransferPair(SmsAgentResult debit, SmsAgentResult credit, String? userName) {
        if ((debit.amount - credit.amount).abs() > 0.01) return false;
        if (debit.date.difference(credit.date).inMinutes.abs() > 35) return false;
        
        final hasSameRef = debit.referenceId != null && 
                           credit.referenceId != null && 
                           debit.referenceId == credit.referenceId;
        if (!hasSameRef) return false;
        if (debit.account == credit.account) return false;
        return true;
      }

      int addedCount = 0;
      int unrecognizedCount = 0;
      int scannedCount = 0;

      final List<_ParsedMsg> candidates = [];

      for (final msg in messages) {
        if (msg.body == null || msg.id == null) continue;
        final msgDate = msg.date ?? DateTime.now();

        // Skip messages older than our fetch threshold
        if (msgDate.isBefore(fetchSince)) continue;

        scannedCount++;

        final result = await _smsAgent.processSms(msg.body!, msgDate, userId: userId, sender: msg.sender);
        if (result != null) {
          candidates.add(_ParsedMsg(message: msg, result: result));
        } else {
          // If keywords match but failed parsing
          if (_isTransactionKeywordsMatch(msg.body!)) {
            // Check if already in unrecognized table
            final unrecognizedList = await _db.unrecognizedMessageDao.getUnrecognizedMessagesForUser(userId);
            final alreadyLogged = unrecognizedList.any((m) => m.body == msg.body);
            if (!alreadyLogged) {
              final unrecognized = UnrecognizedMessage(
                id: const Uuid().v4(),
                userId: userId,
                sender: msg.sender,
                body: msg.body!,
                date: msgDate,
                failureReason: 'Failed to parse details in batch sync',
                createdAt: DateTime.now(),
              );
              await _db.unrecognizedMessageDao.insertUnrecognizedMessage(unrecognized);
              unrecognizedCount++;
            }
          }
        }
      }

      final Set<int> matchedIndices = {};
      final List<TransactionDraft> draftsToInsert = [];

      final user = _ref.read(authProvider).user;
      final userName = user?.displayName;

      // 1. Match intra-batch pairs (debit + credit candidates matching Ref ID, date/time, amount, different accounts)
      for (int i = 0; i < candidates.length; i++) {
        if (matchedIndices.contains(i)) continue;
        final candA = candidates[i];

        int? matchIndex;
        for (int j = 0; j < candidates.length; j++) {
          if (i == j || matchedIndices.contains(j)) continue;
          final candB = candidates[j];

          final isDebitA = candA.result.transactionType == 'expense' || candA.result.category == 'Internal Transfer';
          final isDebitB = candB.result.transactionType == 'income' || candB.result.category == 'Internal Transfer';

          if (isDebitA != isDebitB) {
            final debitCand = isDebitA ? candA : candB;
            final creditCand = isDebitA ? candB : candA;

            if (isSelfTransferPair(debitCand.result, creditCand.result, userName)) {
              matchIndex = j;
              break;
            }
          }
        }

        if (matchIndex != null) {
          matchedIndices.add(i);
          matchedIndices.add(matchIndex);

          final debitCand = candidates[i].result.transactionType == 'expense' || candidates[i].result.category == 'Internal Transfer'
              ? candidates[i] 
              : candidates[matchIndex];
          final creditCand = candidates[i].result.transactionType == 'income' || candidates[i].result.category == 'Internal Transfer'
              ? candidates[i] 
              : candidates[matchIndex];

          final sourceMatch = SmsAccountMatcher.matchAccount(
            smsText: debitCand.result.account,
            existingAccounts: accounts,
            cardOrAccount: debitCand.result.accountNumber,
            sender: debitCand.message.sender,
          );
          final destMatch = SmsAccountMatcher.matchAccount(
            smsText: creditCand.result.account,
            existingAccounts: accounts,
            cardOrAccount: creditCand.result.accountNumber,
            sender: creditCand.message.sender,
          );

          final sourceAcc = sourceMatch.matchedAccount;
          final destAcc = destMatch.matchedAccount;

          final sourceName = sourceMatch.displayTitle;
          final destName = destMatch.displayTitle;
          final metadata = {
            'fromAccountId': sourceAcc?.id,
            'toAccountId': destAcc?.id,
            'fromAccountName': sourceName,
            'toAccountName': destName,
            'refNumber': debitCand.result.referenceId,
          };

          draftsToInsert.add(TransactionDraft(
            id: const Uuid().v4(),
            userId: userId,
            amount: (debitCand.result.amount * 100).round(),
            type: 'transfer',
            currency: 'INR',
            merchant: destName,
            description: 'SMS Transfer: $sourceName to $destName',
            date: debitCand.result.date,
            smsSender: debitCand.message.sender,
            cardOrAccount: sourceAcc?.last4Digits ?? debitCand.result.accountNumber,
            smsBody: debitCand.message.body,
            originalSmsId: null,
            createdAt: DateTime.now(),
            categoryId: null,
            category: 'Transfer',
            confidenceScore: (sourceAcc != null && destAcc != null) ? 0.95 : 0.85,
            supportingSms: jsonEncode(metadata),
          ));
          unrecognizedCount++;
        }
      }

      // 2. Match incoming candidates with the opposite side from recently stored transactions (last 3 days)
      for (int i = 0; i < candidates.length; i++) {
        if (matchedIndices.contains(i)) continue;
        final cand = candidates[i];
        final isDebit = cand.result.transactionType == 'expense' || cand.result.category == 'Internal Transfer';

        Transaction? matchingTx;
        for (var tx in existingTransactions) {
          final isTxDebit = tx.type == 'expense' || tx.type == 'transfer_debit';
          if (isDebit != isTxDebit) {
            final hasSameRef = cand.result.referenceId != null && 
                               tx.referenceNumber != null && 
                               cand.result.referenceId == tx.referenceNumber;
            final sameAmount = (cand.result.amount * 100).round() == tx.amount;
            final closeTime = cand.result.date.difference(tx.date).inMinutes.abs() <= 35;

            if (hasSameRef && sameAmount && closeTime) {
              matchingTx = tx;
              break;
            }
          }
        }

        if (matchingTx != null) {
          matchedIndices.add(i);

          final currentAccMatch = SmsAccountMatcher.matchAccount(
            smsText: cand.result.account,
            existingAccounts: accounts,
            cardOrAccount: cand.result.accountNumber,
            sender: cand.message.sender,
          );

          var currentAcc = currentAccMatch.matchedAccount;
          if (currentAcc == null) {
            final type = currentAccMatch.accountType;
            final name = currentAccMatch.displayTitle;
            final isCC = type == 'credit_card';
            final newId = const Uuid().v4();
            final now = DateTime.now();
            final newAcc = Account(
              id: newId,
              userId: userId,
              name: name,
              type: type,
              balance: 0,
              isDefault: false,
              isEstimated: false,
              createdAt: now,
              updatedAt: now,
              bankName: currentAccMatch.bankName,
              currency: 'INR',
              colorTheme: isCC ? '0xFFFF3B30' : '0xFF0066FF',
              icon: isCC ? 'credit_card' : 'account_balance',
              isActive: true,
              last4Digits: currentAccMatch.last4,
            );
            await _db.into(_db.accounts).insert(newAcc);
            currentAcc = newAcc;
          }

          final debitAccId = isDebit ? currentAcc.id : matchingTx.accountId;
          final creditAccId = isDebit ? matchingTx.accountId : currentAcc.id;

          if (debitAccId != null && creditAccId != null) {
            final sourceName = isDebit ? currentAccMatch.displayTitle : matchingTx.merchant ?? 'Account';
            final destName = isDebit ? matchingTx.merchant ?? 'Account' : currentAccMatch.displayTitle;

            final updatedTx = matchingTx.copyWith(
              type: 'transfer',
              accountId: Value(debitAccId),
              referenceNumber: Value(creditAccId),
              description: Value('SMS Transfer: $sourceName to $destName'),
              updatedAt: DateTime.now(),
            );
            await _db.transactionDao.updateTransaction(updatedTx);
            await BalanceEngine(_db).reconcileOnEdit(matchingTx, updatedTx);
            addedCount++;
          }
        }
      }

      // 3. Match single candidates indicating own-account transfers (using keywords/user display name)
      for (int i = 0; i < candidates.length; i++) {
        if (matchedIndices.contains(i)) continue;
        final cand = candidates[i];
        final lowerBody = cand.message.body!.toLowerCase();

        final isSelfTransferText = 
            lowerBody.contains('transfer to self') ||
            lowerBody.contains('self transfer') ||
            lowerBody.contains('transfer to own') ||
            lowerBody.contains('own account transfer') ||
            lowerBody.contains('transferred to own account') ||
            (lowerBody.contains('transfer') && lowerBody.contains('own a/c')) ||
            (cand.result.category == 'Internal Transfer') ||
            (userName != null && lowerBody.contains(userName.toLowerCase()));

        if (isSelfTransferText) {
          matchedIndices.add(i);

          final sourceMatch = SmsAccountMatcher.matchAccount(
            smsText: cand.result.account,
            existingAccounts: accounts,
            cardOrAccount: cand.result.accountNumber,
            sender: cand.message.sender,
          );
          final sourceAcc = sourceMatch.matchedAccount;

          Account? destAcc;
          for (var acc in accounts) {
            if (sourceAcc != null && acc.id == sourceAcc.id) continue;
            final cleanBank = (acc.bankName ?? '').toLowerCase();
            final last4 = acc.last4Digits;

            if (cleanBank.isNotEmpty && lowerBody.contains(cleanBank)) {
              destAcc = acc;
              break;
            }
            if (last4 != null && last4.isNotEmpty && lowerBody.contains(last4)) {
              destAcc = acc;
              break;
            }
          }

          final sourceName = sourceMatch.displayTitle;
          final destName = destAcc?.name ?? cand.result.merchant ?? 'Unknown Destination';

          final metadata = {
            'fromAccountId': sourceAcc?.id,
            'toAccountId': destAcc?.id,
            'fromAccountName': sourceName,
            'toAccountName': destName,
            'refNumber': cand.result.referenceId,
          };

          draftsToInsert.add(TransactionDraft(
            id: const Uuid().v4(),
            userId: userId,
            amount: (cand.result.amount * 100).round(),
            type: 'transfer',
            currency: 'INR',
            merchant: destName,
            description: 'SMS Transfer: $sourceName to $destName',
            date: cand.result.date,
            smsSender: cand.message.sender,
            cardOrAccount: sourceAcc?.last4Digits ?? cand.result.accountNumber,
            smsBody: cand.message.body,
            originalSmsId: null,
            createdAt: DateTime.now(),
            categoryId: null,
            category: 'Transfer',
            confidenceScore: (sourceAcc != null && destAcc != null) ? 0.95 : 0.85,
            supportingSms: jsonEncode(metadata),
          ));
          unrecognizedCount++;
        }
      }

      // 4. Normal processing for remaining candidates
      for (int i = 0; i < candidates.length; i++) {
        if (matchedIndices.contains(i)) continue;
        final cand = candidates[i];
        final result = cand.result;

        final categoryId = result.categoryOverrideId ?? await _resolveCategoryId(result.merchant, result.transactionType, userId, classifiedCategory: result.category);
        final paymentMethodId = await _resolvePaymentMethodId(result.paymentMode ?? 'UPI', userId);

        if (result.confidence < 0.90) {
          final existingDrafts = await _db.transactionDraftDao.getDraftsForUser(userId);
          final alreadyLogged = existingDrafts.any((d) => d.smsBody == cand.message.body);
          if (!alreadyLogged) {
            final draft = TransactionDraft(
              id: const Uuid().v4(),
              userId: userId,
              amount: (result.amount * 100).round(),
              type: result.transactionType,
              currency: 'INR',
              merchant: result.merchant,
              description: 'SMS Alert: ${result.account}',
              date: result.date,
              smsSender: cand.message.sender,
              cardOrAccount: result.accountNumber,
              smsBody: cand.message.body,
              originalSmsId: null,
              createdAt: DateTime.now(),
              categoryId: categoryId,
              category: result.category,
              confidenceScore: result.confidence,
            );
            await _db.transactionDraftDao.insertDraft(draft);
            unrecognizedCount++;
          }
        } else {
          final tx = Transaction(
            id: const Uuid().v4(),
            userId: userId,
            accountId: null,
            categoryId: categoryId,
            paymentMethodId: paymentMethodId,
            type: result.transactionType,
            amount: (result.amount * 100).round(),
            currency: 'INR',
            description: 'SMS Alert: ${result.account}',
            merchant: result.merchant,
            date: result.date,
            source: 'sms',
            confidenceScore: result.confidence,
            isRecurring: false,
            syncStatus: 'pending',
            transactionType: result.category,
            accountType: result.accountType,
            billStatus: result.billStatus,
            dueDate: result.dueDate,
            referenceNumber: result.referenceId,
            aiClassification: result.category,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final reconciliationResult = await _ledgerAgent.reconcileTransaction(
            tx, 
            confidence: result.confidence,
            importedBalance: result.balance != null ? (result.balance! * 100).round() : null,
          );
          if (reconciliationResult.status == ReconciliationStatus.matchingManual) {
            final draft = TransactionDraft(
              id: const Uuid().v4(),
              userId: userId,
              amount: (result.amount * 100).round(),
              type: result.transactionType,
              currency: 'INR',
              merchant: result.merchant,
              description: 'SMS Alert: ${result.account}',
              date: result.date,
              smsSender: cand.message.sender,
              cardOrAccount: result.accountNumber,
              smsBody: cand.message.body,
              originalSmsId: null,
              createdAt: DateTime.now(),
              categoryId: categoryId,
              category: result.category,
              confidenceScore: result.confidence,
              matchingTransactionId: reconciliationResult.matchingManualId,
            );
            await _db.transactionDraftDao.insertDraft(draft);
            unrecognizedCount++;
          } else if (reconciliationResult.status == ReconciliationStatus.inserted) {
            addedCount++;
          }
        }
      }

      for (final draft in draftsToInsert) {
        final existingDrafts = await _db.transactionDraftDao.getDraftsForUser(userId);
        final alreadyLogged = existingDrafts.any((d) => d.smsBody == draft.smsBody);
        if (!alreadyLogged) {
          await _db.transactionDraftDao.insertDraft(draft);
        }
      }

      final now = DateTime.now();
      await _secureStorage.saveLastSmsSyncTime(now);

      await BalanceEngine(_db).validateAndSelfHeal();

      if (addedCount > 0 || unrecognizedCount > 0) {
        _invalidateUi();
      }

      state = state.copyWith(
        isScanning: false,
        newTransactionsCount: addedCount,
        unrecognizedCount: unrecognizedCount,
        scannedSmsCount: scannedCount,
        detectedTransactionsCount: addedCount + unrecognizedCount,
        lastSyncTime: now,
      );

      if (addedCount > 0) {
        await _notificationService.sendProactiveAlert(
          userId,
          title: 'Transactions Sync Completed! 💸',
          body: 'Imported $addedCount new transaction(s) from your SMS bank alerts.',
          priority: 'high',
        );
      }
    } catch (e) {
      dev.log("SmsScannerNotifier: Error scanning inbox: $e");
      if (!silent) {
        state = state.copyWith(isScanning: false, errorMessage: 'Error scanning inbox: $e');
      } else {
        // Send a notification indicating sync failed
        await _notificationService.sendProactiveAlert(
          userId,
          title: 'SMS Sync Failed ⚠️',
          body: 'An error occurred during background SMS synchronization.',
          priority: 'low',
        );
      }
    }
  }

  Future<void> dismissDraft(String draftId) async {
    await _db.transactionDraftDao.deleteDraft(draftId);
    await _invalidateUi();
  }

  Future<bool> approveDraft(TransactionDraft draft, {bool invalidate = true}) async {
    final userId = _userId;
    if (userId == null) return false;

    final accounts = await (_db.select(_db.accounts)..where((a) => a.userId.equals(userId))).get();
    final paymentMethods = await (_db.select(_db.paymentMethods)..where((pm) => pm.userId.equals(userId) | pm.userId.equals('system'))).get();
    final categories = await _db.categoryDao.getCategoriesForUser(userId);

    String? accountId;
    String? pmId;
    String? categoryId;

    if (draft.type == 'transfer') {
      String? fromAccountId;
      String? toAccountId;
      String? refNumber;
      
      if (draft.supportingSms != null && draft.supportingSms!.startsWith('{')) {
        try {
          final Map<String, dynamic> metadata = jsonDecode(draft.supportingSms!);
          fromAccountId = metadata['fromAccountId'];
          toAccountId = metadata['toAccountId'];
          refNumber = metadata['refNumber'];
        } catch (_) {}
      }

      if (fromAccountId == null) {
        final matchResult = SmsAccountMatcher.matchAccount(
          smsText: draft.smsBody ?? '',
          existingAccounts: accounts,
          cardOrAccount: draft.cardOrAccount,
          sender: draft.smsSender,
        );
        fromAccountId = matchResult.matchedAccount?.id;
      }

      final transferCat = categories.firstWhere(
        (c) => c.name.toLowerCase().contains('transfer'),
        orElse: () => categories.firstWhere((c) => c.parentId == null),
      );
      categoryId = transferCat.id;

      final matchedPm = paymentMethods.firstWhere(
        (pm) => pm.name.toLowerCase().contains('upi') || pm.name.toLowerCase().contains('transfer'),
        orElse: () => paymentMethods.first,
      );
      pmId = matchedPm.id;

      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: fromAccountId,
        categoryId: categoryId,
        paymentMethodId: pmId,
        type: 'transfer',
        amount: draft.amount,
        currency: draft.currency,
        description: draft.smsBody ?? 'SMS Transfer',
        merchant: refNumber != null ? 'Ref: $refNumber' : 'SMS Transfer',
        date: draft.date,
        source: 'sms',
        confidenceScore: draft.confidenceScore ?? 1.0,
        isRecurring: false,
        syncStatus: 'pending',
        transactionType: 'Transfer',
        referenceNumber: toAccountId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await _ledgerAgent.reconcileTransaction(tx, confidence: tx.confidenceScore ?? 1.0);
        await _db.transactionDraftDao.deleteDraft(draft.id);
        if (invalidate) {
          await _invalidateUi();
        }
        return true;
      } catch (e) {
        dev.log('SmsScannerNotifier: Error approving transfer draft: $e');
        return false;
      }
    } else {
      final catId = draft.categoryId ?? await _resolveCategoryId(
        draft.merchant ?? 'General Merchant', 
        draft.type, 
        userId, 
        classifiedCategory: draft.category,
      );

      final matchResult = SmsAccountMatcher.matchAccount(
        smsText: draft.smsBody ?? draft.description ?? '',
        existingAccounts: accounts,
        cardOrAccount: draft.cardOrAccount,
        sender: draft.smsSender,
      );
      accountId = matchResult.matchedAccount?.id;

      final pmName = matchResult.paymentMethod;
      final matchedPm = paymentMethods.firstWhere(
        (pm) => pm.name.toLowerCase() == pmName.toLowerCase() || pm.name.toLowerCase().contains(pmName.toLowerCase()),
        orElse: () => paymentMethods.firstWhere((pm) => pm.name.toLowerCase() == 'upi', orElse: () => paymentMethods.first),
      );
      pmId = matchedPm.id;

      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: accountId,
        categoryId: catId,
        paymentMethodId: pmId,
        type: draft.type,
        amount: draft.amount,
        currency: draft.currency,
        description: draft.description ?? 'SMS Alert',
        merchant: draft.merchant ?? 'General Merchant',
        date: draft.date,
        source: 'sms',
        confidenceScore: draft.confidenceScore ?? 1.0,
        isRecurring: false,
        syncStatus: 'pending',
        transactionType: draft.category ?? draft.type,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await _ledgerAgent.reconcileTransaction(tx, confidence: tx.confidenceScore ?? 1.0);
        await _db.transactionDraftDao.deleteDraft(draft.id);
        if (invalidate) {
          await _invalidateUi();
        }
        return true;
      } catch (e) {
        dev.log('SmsScannerNotifier: Error approving draft: $e');
        return false;
      }
    }
  }

  Future<Map<String, int>> approveAllDrafts() async {
    final userId = _userId;
    if (userId == null) return {'imported': 0, 'skipped': 0};

    final drafts = await _db.transactionDraftDao.getDraftsForUser(userId);
    if (drafts.isEmpty) return {'imported': 0, 'skipped': 0};

    int imported = 0;
    int skipped = 0;

    for (final draft in drafts) {
      final success = await approveDraft(draft, invalidate: false);
      if (success) {
        imported++;
      } else {
        skipped++;
      }
    }

    _invalidateUi();
    return {'imported': imported, 'skipped': skipped};
  }

  Future<void> linkDraftToManual(String draftId, String manualTxId) async {
    final draft = await _db.transactionDraftDao.getDraftById(draftId);
    if (draft == null) return;

    final manualTx = await (_db.select(_db.transactions)..where((t) => t.id.equals(manualTxId))).getSingleOrNull();
    if (manualTx != null) {
      // Merge
      final mergedDesc = _mergeStrings(manualTx.description, draft.description);
      final mergedMerchant = _mergeStrings(manualTx.merchant, draft.merchant) ?? 'Merged Merchant';

      // Merge supporting SMS lists
      List<String> smsList = [];
      if (manualTx.supportingSms != null && manualTx.supportingSms!.isNotEmpty) {
        try {
          smsList = List<String>.from(jsonDecode(manualTx.supportingSms!));
        } catch (_) {}
      }
      if (manualTx.description != null && !smsList.contains(manualTx.description)) {
        smsList.add(manualTx.description!);
      }
      final newSmsText = draft.smsBody ?? draft.description ?? 'SMS Alert';
      if (!smsList.contains(newSmsText)) {
        smsList.add(newSmsText);
      }

      final mergedRef = (manualTx.referenceNumber == null || manualTx.referenceNumber!.isEmpty)
          ? draft.originalSmsId // or ref
          : manualTx.referenceNumber;

      // Re-generate fingerprint
      final fingerprint = _ledgerAgent.generateFingerprint(
        accountId: manualTx.accountId,
        amount: manualTx.amount,
        merchant: mergedMerchant,
        date: manualTx.date,
        referenceNumber: mergedRef,
      );

      final mergedTx = manualTx.copyWith(
        description: Value(mergedDesc),
        merchant: Value(mergedMerchant),
        categoryId: Value(manualTx.categoryId ?? draft.categoryId),
        referenceNumber: Value(mergedRef),
        fingerprint: Value(fingerprint),
        supportingSms: Value(jsonEncode(smsList)),
        updatedAt: DateTime.now(),
      );

      await _db.transactionDao.updateTransaction(mergedTx);
      
      final auditLogger = _ref.read(auditLoggerProvider);
      await auditLogger.logEvent(
        userId: _userId,
        eventType: 'draft_linked_to_manual',
        eventCategory: 'ledger',
        description: 'Linked and approved draft transaction $draftId to manual transaction $manualTxId.',
      );
    }

    await _db.transactionDraftDao.deleteDraft(draftId);
    await BalanceEngine(_db).recalculateAllBalances();
    _invalidateUi();
  }

  String _mergeStrings(String? a, String? b) {
    if (a == null || a.isEmpty) return b ?? '';
    if (b == null || b.isEmpty) return a;
    if (a.toLowerCase().contains(b.toLowerCase())) return a;
    if (b.toLowerCase().contains(a.toLowerCase())) return b;
    if (a.startsWith('SMS Alert:') && b.startsWith('SMS Alert:')) return a;
    return '$a / $b';
  }

  Future<void> deleteAllDrafts() async {
    final userId = _userId;
    if (userId == null) return;
    await _db.transactionDraftDao.clearAllDraftsForUser(userId);
    _invalidateUi();
  }

  Future<void> _invalidateUi() async {
    _ref.invalidate(expenseListNotifierProvider);
    _ref.invalidate(accountsProvider);
    _ref.invalidate(budgetStatusProviderList);
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(unrecognizedMessagesStreamProvider);
    _ref.invalidate(transactionDraftsStreamProvider);
    _ref.invalidate(savedSmsTransactionsCountProvider);
    dev.log('[Dashboard Refresh] Status: Refreshed (Invalidated UI state providers)');
    await _loadStats();
  }

  Future<String?> _resolveCategoryId(String merchant, String type, String userId, {String? classifiedCategory}) async {
    String catName = classifiedCategory ?? (type == 'income' ? 'Salary' : 'Shopping');
    
    // Normalise name mapping if needed
    if (catName == 'General Income') {
      catName = 'General Income';
    } else if (catName == 'Personal Transfer') {
      catName = 'Personal Transfer';
    }
    
    if (classifiedCategory == null) {
      final lowerMerchant = merchant.toLowerCase();
      for (final entry in ParserAgent.keywordToCategory.entries) {
        if (lowerMerchant.contains(entry.key)) {
          catName = entry.value;
          break;
        }
      }
    }

    var cat = await (_db.select(_db.categories)
          ..where((t) => t.name.equals(catName) & (t.userId.equals(userId) | t.isSystemDefault.equals(true)))
          ..limit(1))
        .getSingleOrNull();

    if (cat == null) {
      final id = const Uuid().v4();
      final now = DateTime.now();
      await _db.into(_db.categories).insert(
        CategoriesCompanion.insert(
          id: id,
          userId: userId,
          name: catName,
          type: type,
          isSystemDefault: const Value(false),
          createdAt: now,
          icon: Value(type == 'income' ? 'payments' : 'shopping_bag'),
          color: Value(type == 'income' ? '0xFF00FF88' : '0xFF8A2BE2'),
        ),
      );
      cat = await (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
    }

    return cat?.id;
  }

  Future<String?> _resolvePaymentMethodId(String mode, String userId) async {
    String queryMode = mode;
    if (mode == 'IMPS' || mode == 'NEFT' || mode == 'RTGS') {
      queryMode = 'Net Banking';
    }
    final pm = await (_db.select(_db.paymentMethods)
          ..where((t) => t.name.equals(queryMode) & (t.userId.equals(userId) | t.userId.equals('system')))
          ..limit(1))
        .getSingleOrNull();
    return pm?.id;
  }

  /// Helper for manual mock testing of SMS parsing
  Future<bool> importMockSms(String sender, String body) async {
    final userId = _userId;
    if (userId == null) return false;
    final parsed = await _smsAgent.processSms(body, DateTime.now(), userId: userId);
    if (parsed == null) {
      // Log to Unrecognized Messages table
      final unrecognized = UnrecognizedMessage(
        id: const Uuid().v4(),
        userId: userId,
        sender: sender,
        body: body,
        date: DateTime.now(),
        failureReason: 'Manual simulation parsing failed',
        createdAt: DateTime.now(),
      );
      await _db.unrecognizedMessageDao.insertUnrecognizedMessage(unrecognized);
      _ref.invalidate(unrecognizedMessagesStreamProvider);
      return false;
    }

    final categoryId = parsed.categoryOverrideId ?? await _resolveCategoryId(parsed.merchant, parsed.transactionType, userId, classifiedCategory: parsed.category);
    final paymentMethodId = await _resolvePaymentMethodId(parsed.paymentMode ?? 'UPI', userId);

    if (parsed.confidence < 0.90) {
      final draft = TransactionDraft(
        id: const Uuid().v4(),
        userId: userId,
        amount: (parsed.amount * 100).round(),
        type: parsed.transactionType,
        currency: 'INR',
        merchant: parsed.merchant,
        description: 'Mock SMS Alert: ${parsed.account}',
        date: parsed.date,
        smsSender: sender,
        cardOrAccount: parsed.accountNumber,
        smsBody: body,
        originalSmsId: null,
        createdAt: DateTime.now(),
        categoryId: categoryId,
        category: parsed.category,
        confidenceScore: parsed.confidence,
      );
      await _db.transactionDraftDao.insertDraft(draft);
      _ref.invalidate(transactionDraftsStreamProvider);
      _invalidateUi();
      return true;
    }

    final tx = Transaction(
      id: const Uuid().v4(),
      userId: userId,
      accountId: null,
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      type: parsed.transactionType,
      amount: (parsed.amount * 100).round(),
      currency: 'INR',
      description: 'Mock SMS Alert: ${parsed.account}',
      merchant: parsed.merchant,
      date: parsed.date,
      source: 'sms',
      confidenceScore: parsed.confidence,
      isRecurring: false,
      syncStatus: 'pending',
      transactionType: parsed.category,
      accountType: parsed.accountType,
      billStatus: parsed.billStatus,
      dueDate: parsed.dueDate,
      referenceNumber: parsed.referenceId,
      aiClassification: parsed.category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _ledgerAgent.reconcileTransaction(
      tx, 
      confidence: parsed.confidence,
      importedBalance: parsed.balance != null ? (parsed.balance! * 100).round() : null,
    );
    _invalidateUi();
    return true;
  }
}

// SMS Scanner Provider
final StateNotifierProvider<SmsScannerNotifier, SmsScannerState> smsScannerProvider =
    StateNotifierProvider<SmsScannerNotifier, SmsScannerState>((ref) {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  final smsAgent = ref.watch(smsAgentProvider);
  final ledgerAgent = ref.watch(ledgerAgentProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);

  return SmsScannerNotifier(
    db: db,
    userId: userId,
    smsAgent: smsAgent,
    ledgerAgent: ledgerAgent,
    notificationService: notificationService,
    secureStorage: secureStorage,
    ref: ref,
  );
});

// Saved SMS Transactions Count Provider
final savedSmsTransactionsCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return 0;
  final result = await db.customSelect(
    'SELECT COUNT(*) as c FROM transactions WHERE user_id = ? AND source = ? AND deleted_at IS NULL',
    variables: [Variable<String>(userId), Variable<String>('sms')],
  ).getSingle();
  return result.read<int>('c');
});

class _ParsedMsg {
  final SmsMessage message;
  final SmsAgentResult result;
  _ParsedMsg({required this.message, required this.result});
}
