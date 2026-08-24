import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/sms_parser/presentation/providers/sms_parser_provider.dart';
import 'package:app/features/dashboard/presentation/screens/dashboard_summary_screen.dart';

// Minimal mock database and dependencies to satisfy Riverpod
class FakeSmsScannerNotifier extends StateNotifier<SmsScannerState> implements SmsScannerNotifier {
  FakeSmsScannerNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('NotificationBellWithSmsStatus Widget Tests', () {
    testWidgets('Shows normal bell icon when SMS monitoring is disabled/permissions denied', (tester) async {
      final fakeSmsState = SmsScannerState(
        smsPermissionStatus: PermissionStatus.denied,
        autoImportEnabled: false,
        lastSyncTime: DateTime(2026, 8, 24, 12, 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            smsScannerProvider.overrideWith((ref) => FakeSmsScannerNotifier(fakeSmsState)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationBellWithSmsStatus(unreadCount: 2),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should find the bell icon (notifications_none_outlined)
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
      // Should show the unread count badge
      expect(find.text('2'), findsOneWidget);
      // Should NOT find the SMS icon (chat_bubble_outline_rounded)
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    });

    testWidgets('Shows SMS scanning icon and transitions back to bell on timing cycle', (tester) async {
      final fakeSmsState = SmsScannerState(
        smsPermissionStatus: PermissionStatus.granted,
        autoImportEnabled: true,
        lastSyncTime: DateTime(2026, 8, 24, 12, 0),
      );

      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) => const Scaffold(
              body: NotificationBellWithSmsStatus(unreadCount: 0),
            ),
          ),
          GoRoute(
            path: '/sms-transactions',
            builder: (context, state) => const Scaffold(body: Text('SMS Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            smsScannerProvider.overrideWith((ref) => FakeSmsScannerNotifier(fakeSmsState)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Trigger post frame callback
      await tester.pump();

      // Initial state is SMS scanning
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.textContaining('Last scan:'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_outlined), findsNothing);

      // Verify dot animation exists inside SMS icon
      expect(find.byType(AnimatedSmsIcon), findsOneWidget);

      // Fast forward time by 3 seconds
      await tester.pump(const Duration(seconds: 3));

      // Should transition back to Bell
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    });
  });
}
