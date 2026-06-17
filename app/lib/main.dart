import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        primaryColor: Colors.teal,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: router,
    );
  }
}
