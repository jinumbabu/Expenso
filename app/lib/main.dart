import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'firebase_options.dart';
import 'core/routes/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/sms_background_processor.dart';
import 'core/services/sms_agent.dart';
import 'core/services/ledger_agent.dart';
import 'core/database/app_database.dart';
import 'core/security/secure_storage_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('NotificationService initialization failed: $e');
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://expenso-placeholder-dsn@sentry.io/12345';
      options.tracesSampleRate = 1.0;
      options.enableUserInteractionTracing = true;
    },
    appRunner: () => runApp(
      const ProviderScope(
        child: ExpensoApp(),
      ),
    ),
  );
}

class ExpensoApp extends ConsumerWidget {
  const ExpensoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Expenso AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: const Color(0xFF0066FF),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
          primary: const Color(0xFF0066FF),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF050505),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF050505),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}

@pragma('vm:entry-point')
void backgroundSmsCallback() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    try {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    } catch (_) {}
  }

  const channel = MethodChannel('com.expenso.ai.app/sms_background');
  channel.setMethodCallHandler((call) async {
    debugPrint("backgroundSmsCallback: method call received: ${call.method}");
    if (call.method == 'onBackgroundSmsReceived') {
      try {
        final args = Map<String, dynamic>.from(call.arguments);
        final String? sender = args['sender'];
        final String? body = args['body'];
        final int? timestamp = args['timestamp'];
        if (body != null) {
          final date = timestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(timestamp)
              : DateTime.now();

          // Initialize Firebase if not initialized
          try {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          } catch (_) {}

          final container = ProviderContainer();

          final secureStorage = container.read(secureStorageProvider);
          final autoImport = await secureStorage.getAutoImportEnabled();
          final autoScan = await secureStorage.getAutoScanNewSms() ?? true;

          if (autoImport && autoScan) {
            final userId = await secureStorage.getUserId();
            if (userId != null) {
              final db = container.read(databaseProvider);
              final smsAgent = container.read(smsAgentProvider);
              final ledgerAgent = container.read(ledgerAgentProvider);
              final notificationService = container.read(notificationServiceProvider);

              await SmsBackgroundProcessor.processIncomingSms(
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
            }
          } else {
            // Log ignored diagnostics if disabled
            try {
              final ignStr = await secureStorage.read('sms_stats_ignored_count') ?? '0';
              await secureStorage.write('sms_stats_ignored_count', (int.parse(ignStr) + 1).toString());
            } catch (_) {}
          }
          container.dispose();
        }
      } catch (e) {
        debugPrint('Error in background SMS callback: $e');
        try {
          final secureStorage = SecureStorageService();
          await secureStorage.write('sms_stats_last_error', e.toString());
        } catch (_) {}
      } finally {
        await channel.invokeMethod('onBackgroundProcessingFinished');
      }
    }
  });

  // Notify native side that the channel is ready to receive
  channel.invokeMethod('onBackgroundEngineReady');
}

