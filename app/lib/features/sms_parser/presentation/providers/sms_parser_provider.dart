import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'dart:developer' as dev;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/dao/transaction_draft_dao.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/services/sms_agent.dart';
import '../../../../core/services/ledger_agent.dart';
import '../../../../core/services/parser_agent.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../budgets/presentation/screens/budgets_screen.dart';

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

  SmsScannerState({
    this.isScanning = false,
    this.errorMessage,
    this.newTransactionsCount = 0,
    this.unrecognizedCount = 0,
    this.lastSyncTime,
  });

  SmsScannerState copyWith({
    bool? isScanning,
    String? errorMessage,
    int? newTransactionsCount,
    int? unrecognizedCount,
    DateTime? lastSyncTime,
  }) {
    return SmsScannerState(
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
      newTransactionsCount: newTransactionsCount ?? this.newTransactionsCount,
      unrecognizedCount: unrecognizedCount ?? this.unrecognizedCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
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
      scanInbox(silent: true);
    }
  }

  Future<void> _loadLastSyncTime() async {
    final lastTime = await _secureStorage.getLastSmsSyncTime();
    if (lastTime != null) {
      state = state.copyWith(lastSyncTime: lastTime);
    }
  }

  Future<void> _runStartupSync() async {
    // Wait slightly for app to complete layout
    await Future.delayed(const Duration(milliseconds: 500));
    final permission = await Permission.sms.status;
    if (permission.isGranted) {
      await scanInbox(silent: true);
    }
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
    try {
      dev.log("SmsScannerNotifier: Processing incoming SMS: $body");
      final result = await _smsAgent.processSms(body, date);
      if (result != null) {
        // Resolve Category and Payment Method IDs
        final categoryId = await _resolveCategoryId(result.merchant, result.transactionType, userId);
        final paymentMethodId = await _resolvePaymentMethodId(result.paymentMode ?? 'UPI', userId);

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
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Reconcile and save transaction (natively handles duplicate merge)
        await _ledgerAgent.reconcileTransaction(tx, confidence: result.confidence);

        // Invalidate UI providers
        _invalidateUi();

        // Push Local Notification
        final formattedAmount = (result.amount).toStringAsFixed(2);
        await _notificationService.sendProactiveAlert(
          userId,
          title: 'Transaction Imported! 💸',
          body: '${result.transactionType == 'expense' ? 'Spent' : 'Received'} ₹$formattedAmount at ${result.merchant} via ${result.account}.',
          priority: 'high',
        );
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
        final request = await Permission.sms.request();
        if (!request.isGranted) {
          state = state.copyWith(
            isScanning: false,
            errorMessage: 'SMS permission denied.',
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
        final result = await _smsAgent.processSms(msg.body!, msgDate);
        if (result != null) {
          // Construct transaction
          final categoryId = await _resolveCategoryId(result.merchant, result.transactionType, userId);
          final paymentMethodId = await _resolvePaymentMethodId(result.paymentMode ?? 'UPI', userId);

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
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _ledgerAgent.reconcileTransaction(tx, confidence: result.confidence);
          addedCount++;
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

      if (addedCount > 0 || unrecognizedCount > 0) {
        _invalidateUi();
      }

      state = state.copyWith(
        isScanning: false,
        newTransactionsCount: addedCount,
        unrecognizedCount: unrecognizedCount,
        lastSyncTime: now,
      );
    } catch (e) {
      dev.log('SmsScannerNotifier: Error scanning SMS: $e');
      if (!silent) {
        state = state.copyWith(isScanning: false, errorMessage: 'Error scanning inbox: $e');
      }
    }
  }

  Future<void> dismissDraft(String draftId) async {
    await _db.transactionDraftDao.deleteDraft(draftId);
  }

  void _invalidateUi() {
    _ref.invalidate(expenseListNotifierProvider);
    _ref.invalidate(budgetStatusProviderList);
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(unrecognizedMessagesStreamProvider);
  }

  Future<String?> _resolveCategoryId(String merchant, String type, String userId) async {
    String catName = type == 'income' ? 'Salary' : 'Shopping';
    final lowerMerchant = merchant.toLowerCase();
    for (final entry in ParserAgent.keywordToCategory.entries) {
      if (lowerMerchant.contains(entry.key)) {
        catName = entry.value;
        break;
      }
    }

    final cat = await (_db.select(_db.categories)
          ..where((t) => t.name.equals(catName) & (t.userId.equals(userId) | t.isSystemDefault.equals(true)))
          ..limit(1))
        .getSingleOrNull();

    return cat?.id;
  }

  Future<String?> _resolvePaymentMethodId(String mode, String userId) async {
    final pm = await (_db.select(_db.paymentMethods)
          ..where((t) => t.name.equals(mode) & (t.userId.equals(userId) | t.userId.equals('system')))
          ..limit(1))
        .getSingleOrNull();
    return pm?.id;
  }

  /// Helper for manual mock testing of SMS parsing
  Future<bool> importMockSms(String sender, String body) async {
    final userId = _userId;
    if (userId == null) return false;
    final parsed = await _smsAgent.processSms(body, DateTime.now());
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

    final tx = Transaction(
      id: const Uuid().v4(),
      userId: userId,
      accountId: null,
      categoryId: await _resolveCategoryId(parsed.merchant, parsed.transactionType, userId),
      paymentMethodId: await _resolvePaymentMethodId(parsed.paymentMode ?? 'UPI', userId),
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _ledgerAgent.reconcileTransaction(tx, confidence: parsed.confidence);
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
