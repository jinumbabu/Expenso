import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/core/security/secure_storage_service.dart';
import 'package:app/core/services/sms_agent.dart';
import 'package:app/core/services/ledger_agent.dart';
import 'package:app/core/services/notification_service.dart';
import 'package:app/core/database/app_database.dart';
import 'sms_monitor_state.dart';
import 'sms_permission_manager.dart';
import 'sms_background_manager.dart';
import 'sms_transaction_pipeline.dart';
import 'package:app/features/sms_parser/presentation/providers/sms_parser_provider.dart';


final smsServiceBootstrapProvider = Provider<SmsServiceBootstrap>((ref) {
  final bootstrap = SmsServiceBootstrap(ref);
  // Asynchronously initialize bootstrap
  bootstrap.initialize();
  return bootstrap;
});

class SmsServiceBootstrap with WidgetsBindingObserver {
  final Ref _ref;
  static const MethodChannel _channel = MethodChannel('com.expenso.ai.app/sms');
  bool _initialized = false;

  SmsServiceBootstrap(this._ref);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    debugPrint("SmsServiceBootstrap: Initializing application-level SMS monitoring...");
    
    // Register lifecycle listener
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize the foreground method channel call handler
    _initChannel();

    // Check actual Android permissions and setup the engine state
    await refresh();
  }

  void _initChannel() {
    _channel.setMethodCallHandler((call) async {
      debugPrint("SmsServiceBootstrap: Method channel call received: ${call.method}");
      if (call.method == 'onSmsReceived') {
        final args = Map<String, dynamic>.from(call.arguments);
        final String? sender = args['sender'];
        final String? body = args['body'];
        final int? timestamp = args['timestamp'];
        if (body != null) {
          final date = timestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(timestamp)
              : DateTime.now();
          await handleIncomingSms(sender, body, date);
        }
      } else if (call.method == 'onSmsProcessed') {
        debugPrint("SmsServiceBootstrap: Background SMS processing completed. Refreshing state...");
        await refresh();
        try {
          _ref.read(smsScannerProvider.notifier).loadStats();
          _ref.read(smsScannerProvider.notifier).loadLastSyncTime();
          _ref.invalidate(transactionDraftsStreamProvider);
        } catch (e) {
          debugPrint("SmsServiceBootstrap: Error updating smsScannerProvider on background update: $e");
        }
      }
    });
  }

  Future<void> handleIncomingSms(String? sender, String body, DateTime date) async {
    final secureStorage = _ref.read(secureStorageProvider);
    final autoImport = await secureStorage.getAutoImportEnabled();
    final autoScan = await secureStorage.getAutoScanNewSms() ?? true;

    if (!autoImport || !autoScan) {
      debugPrint("SmsServiceBootstrap: SMS Auto-Import or Auto-Scan is disabled. Ignoring incoming message.");
      return;
    }

    final userId = await secureStorage.getUserId();
    if (userId == null) {
      debugPrint("SmsServiceBootstrap: No active user session. Ignoring incoming message.");
      return;
    }

    final db = _ref.read(databaseProvider);
    final smsAgent = _ref.read(smsAgentProvider);
    final ledgerAgent = _ref.read(ledgerAgentProvider);
    final notificationService = _ref.read(notificationServiceProvider);

    try {
      debugPrint("SmsServiceBootstrap: Delegating SMS to SmsTransactionPipeline");
      await SmsTransactionPipeline.processIncomingSms(
        sender: sender,
        body: body,
        date: date,
        userId: userId,
        db: db,
        smsAgent: smsAgent,
        ledgerAgent: ledgerAgent,
        notificationService: notificationService,
        secureStorage: secureStorage,
      );
      await refresh();
    } catch (e) {
      debugPrint("SmsServiceBootstrap: Error handling incoming SMS: $e");
    }
  }

  Future<void> refresh() async {
    final secureStorage = _ref.read(secureStorageProvider);
    final permissionManager = SmsPermissionManager();
    final backgroundManager = SmsBackgroundManager();

    final status = await permissionManager.checkActualPermissions();
    final autoImport = await secureStorage.getAutoImportEnabled();
    final autoScan = await secureStorage.getAutoScanNewSms() ?? true;
    final receiverAvailable = await backgroundManager.checkReceiverAvailable();

    final lastProcessed = await secureStorage.getLastSmsSyncTime();
    final lastErr = await secureStorage.read('sms_stats_last_error');

    SmsBackgroundMonitorReadyState monitorReadyState;
    if (!status.smsStatus.isGranted) {
      monitorReadyState = SmsBackgroundMonitorReadyState.permissionRequired;
    } else if (!autoImport || !autoScan) {
      monitorReadyState = SmsBackgroundMonitorReadyState.disabled;
    } else {
      monitorReadyState = SmsBackgroundMonitorReadyState.ready;
    }

    final monitorStatus = SmsMonitorStatus(
      smsPermissionStatus: status.smsStatus,
      notificationPermissionStatus: status.notificationStatus,
      automaticDetectionActive: autoImport && autoScan && status.smsStatus.isGranted,
      backgroundMonitorReady: monitorReadyState,
      lastProcessedAt: lastProcessed,
      lastError: lastErr,
      receiverAvailable: receiverAvailable,
    );

    // Update the authoritative status provider
    _ref.read(smsMonitorStatusProvider.notifier).updateStatus(monitorStatus);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
    }
  }
}
