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
  final DateTime? lastPermissionRequestTime;
  final bool isInboxAccessible;

  SmsScannerState({
    this.isScanning = false,
    this.errorMessage,
    this.newTransactionsCount = 0,
    this.unrecognizedCount = 0,
    this.lastSyncTime,
    this.smsPermissionStatus = PermissionStatus.denied,
    this.notificationPermissionStatus = PermissionStatus.denied,
    this.autoImportEnabled = true,
    this.lastPermissionRequestTime,
    this.isInboxAccessible = false,
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
    DateTime? lastPermissionRequestTime,
    bool? isInboxAccessible,
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
      lastPermissionRequestTime: lastPermissionRequestTime ?? this.lastPermissionRequestTime,
      isInboxAccessible: isInboxAccessible ?? this.isInboxAccessible,
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
      dev.log("SmsScannerNotifier: Auto-import is disabled. Skipping incoming message.");
      return;
    }
    try {
      dev.log("SmsScannerNotifier: Processing incoming SMS: $body");
      final result = await _smsAgent.processSms(body, date, userId: userId);
      if (result != null) {
        // Resolve Category and Payment Method IDs
        final categoryId = result.categoryOverrideId ?? await _resolveCategoryId(result.merchant, result.transactionType, userId, classifiedCategory: result.category);
        final paymentMethodId = await _resolvePaymentMethodId(result.paymentMode ?? 'UPI', userId);

        if (result.confidence < 0.90) {
          final draft = TransactionDraft(
            id: const Uuid().v4(),
            userId: userId,
            amount: (result.amount * 100).round(),
            type: result.transactionType,
            currency: 'INR',
            merchant: result.merchant,
            description: 'SMS Alert: ${result.account}',
            date: result.date,
            smsSender: sender,
            cardOrAccount: result.accountNumber,
            smsBody: body,
            originalSmsId: null,
            createdAt: DateTime.now(),
            categoryId: categoryId,
            category: result.category,
            confidenceScore: result.confidence,
          );
          await _db.transactionDraftDao.insertDraft(draft);

          _ref.invalidate(transactionDraftsStreamProvider);
          _invalidateUi();

          await _notificationService.sendProactiveAlert(
            userId,
            title: 'New transaction to review! 📝',
            body: 'Uncertain transaction: ₹${result.amount} via ${result.account}. Please review and approve.',
            priority: 'normal',
          );
          return;
        }

        final tx = Transaction(
          id: const Uuid().v4(),
          userId: userId,
          accountId: null, // Link to account resolved by LedgerAgent
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
            smsSender: sender,
            cardOrAccount: result.accountNumber,
            smsBody: body,
            originalSmsId: null,
            createdAt: DateTime.now(),
            categoryId: categoryId,
            category: result.category,
            confidenceScore: result.confidence,
            matchingTransactionId: reconciliationResult.matchingManualId,
          );
          await _db.transactionDraftDao.insertDraft(draft);

          _ref.invalidate(transactionDraftsStreamProvider);
          _invalidateUi();

          await _notificationService.sendProactiveAlert(
            userId,
            title: 'Matching Manual Entry Found 🔗',
            body: 'An SMS matches your manual entry: ₹${result.amount} at ${result.merchant}. Please review and link them.',
            priority: 'normal',
          );
          return;
        }

        // Invalidate UI providers
        _invalidateUi();

        if (reconciliationResult.status == ReconciliationStatus.inserted) {
          // Push Local Notification
          final formattedAmount = (result.amount).toStringAsFixed(2);
          await _notificationService.sendProactiveAlert(
            userId,
            title: 'Transaction Imported! 💸',
            body: '${result.transactionType == 'expense' ? 'Spent' : 'Received'} ₹$formattedAmount at ${result.merchant} via ${result.account}.',
            priority: 'high',
          );
        }
      } else {
        // If it's a banking transaction but we failed to parse details
        if (_isTransactionKeywordsMatch(body)) {
          final unrecognized = UnrecognizedMessage(
            id: const Uuid().v4(),
            userId: userId,
            sender: sender,
            body: body,
            date: date,
            failureReason: 'Failed to extract banking/amount details',
            createdAt: DateTime.now(),
          );
          await _db.unrecognizedMessageDao.insertUnrecognizedMessage(unrecognized);
          _ref.invalidate(unrecognizedMessagesStreamProvider);
        }
      }
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

      int addedCount = 0;
      int unrecognizedCount = 0;

      for (final msg in messages) {
        if (msg.body == null || msg.id == null) continue;
        final msgDate = msg.date ?? DateTime.now();

        // Skip messages older than our fetch threshold
        if (msgDate.isBefore(fetchSince)) continue;

        // Check if message matches transactional content
        final result = await _smsAgent.processSms(msg.body!, msgDate, userId: userId);
        if (result != null) {
          // Construct transaction
          final categoryId = result.categoryOverrideId ?? await _resolveCategoryId(result.merchant, result.transactionType, userId, classifiedCategory: result.category);
          final paymentMethodId = await _resolvePaymentMethodId(result.paymentMode ?? 'UPI', userId);

          if (result.confidence < 0.90) {
            // Check if draft already exists to avoid duplicates
            final existingDrafts = await _db.transactionDraftDao.getDraftsForUser(userId);
            final alreadyLogged = existingDrafts.any((d) => d.smsBody == msg.body);
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
                smsSender: msg.sender,
                cardOrAccount: result.accountNumber,
                smsBody: msg.body,
                originalSmsId: null,
                createdAt: DateTime.now(),
                categoryId: categoryId,
                category: result.category,
                confidenceScore: result.confidence,
              );
              await _db.transactionDraftDao.insertDraft(draft);
              unrecognizedCount++; // count this in scanning updates as it needs review
            }
            continue;
          }

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
              smsSender: msg.sender,
              cardOrAccount: result.accountNumber,
              smsBody: msg.body,
              originalSmsId: null,
              createdAt: DateTime.now(),
              categoryId: categoryId,
              category: result.category,
              confidenceScore: result.confidence,
              matchingTransactionId: reconciliationResult.matchingManualId,
            );
            await _db.transactionDraftDao.insertDraft(draft);
            unrecognizedCount++; // count in updates for review
          } else if (reconciliationResult.status == ReconciliationStatus.inserted) {
            addedCount++;
          }
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
      dev.log('SmsScannerNotifier: Error scanning SMS: $e');
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
  }

  Future<Map<String, int>> approveAllDrafts() async {
    final userId = _userId;
    if (userId == null) return {'imported': 0, 'skipped': 0};

    final drafts = await _db.transactionDraftDao.getDraftsForUser(userId);
    if (drafts.isEmpty) return {'imported': 0, 'skipped': 0};

    int imported = 0;
    int skipped = 0;

    final accounts = await _db.select(_db.accounts).get();
    final paymentMethods = await _db.select(_db.paymentMethods).get();

    for (final draft in drafts) {
      final categoryId = draft.categoryId ?? await _resolveCategoryId(
        draft.merchant ?? 'General Merchant', 
        draft.type, 
        userId, 
        classifiedCategory: draft.category,
      );

      String? accountId;
      String? pmId;

      final smsRaw = draft.smsBody ?? draft.description ?? '';
      final matchResult = SmsAccountMatcher.matchAccount(
        smsText: smsRaw,
        existingAccounts: accounts,
        cardOrAccount: draft.cardOrAccount,
        sender: draft.smsSender,
      );

      final matchedAccount = matchResult.matchedAccount;
      accountId = matchedAccount?.id;

      final pmName = matchResult.paymentMethod;
      final matchedPm = paymentMethods.firstWhere(
        (pm) => pm.name.toLowerCase() == pmName.toLowerCase() || pm.name.toLowerCase().contains(pmName.toLowerCase()),
        orElse: () => paymentMethods.firstWhere((pm) => pm.name.toLowerCase() == 'upi', orElse: () => paymentMethods.first),
      );
      pmId = matchedPm.id;

      // Construct Transaction
      final tx = Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
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
        final startOfDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        final existingTxs = await (_db.select(_db.transactions)
          ..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.date.isSmallerOrEqualValue(endOfDay))
        ).get();

        bool isDuplicate = false;
        for (var ext in existingTxs) {
          final amountMatches = (ext.amount - tx.amount).abs() < 100;
          if (amountMatches) {
            final extMerchant = (ext.merchant ?? '').toLowerCase();
            final newMerchant = (tx.merchant ?? '').toLowerCase();
            final merchantMatches = extMerchant.contains(newMerchant) || 
                                    newMerchant.contains(extMerchant) ||
                                    (ext.description ?? '').toLowerCase().contains(newMerchant);
            if (merchantMatches && ext.type == tx.type) {
              isDuplicate = true;
              break;
            }
          }
        }

        if (isDuplicate) {
          skipped++;
        } else {
          await _ledgerAgent.reconcileTransaction(tx, confidence: tx.confidenceScore ?? 1.0);
          imported++;
        }
      } catch (e) {
        dev.log('SmsScannerNotifier: Error importing draft ${draft.id}: $e');
        skipped++;
      }

      await _db.transactionDraftDao.deleteDraft(draft.id);
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

  void _invalidateUi() {
    _ref.invalidate(expenseListNotifierProvider);
    _ref.invalidate(accountsProvider);
    _ref.invalidate(budgetStatusProviderList);
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(unrecognizedMessagesStreamProvider);
    _ref.invalidate(transactionDraftsStreamProvider);
    dev.log('[Dashboard Refresh] Status: Refreshed (Invalidated UI state providers)');
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
