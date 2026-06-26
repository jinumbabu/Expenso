import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/auth/presentation/screens/biometric_lock_screen.dart';

void main() {
  group('BiometricLockScreen Widget Tests', () {
    late GoRouter testRouter;

    setUp(() {
      testRouter = GoRouter(
        initialLocation: '/lock',
        routes: [
          GoRoute(
            path: '/lock',
            builder: (context, state) => const BiometricLockScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const Scaffold(
              body: Text('Dashboard Screen'),
            ),
          ),
        ],
      );
    });

    testWidgets('Renders keypad and lock header correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      // Verify header text
      expect(find.text('SECURITY LOCK'), findsOneWidget);
      expect(find.text('Enter PIN to unlock Expenso'), findsOneWidget);

      // Verify digits 0-9 are present
      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('Entering correct PIN (1234) routes to dashboard', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      // Tap digits 1, 2, 3, 4
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      // Check if we navigated to dashboard
      expect(find.text('Dashboard Screen'), findsOneWidget);
    });

    testWidgets('Entering incorrect PIN triggers error snackbar and resets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      // Tap digits 1, 1, 1, 1 (incorrect PIN)
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // Should display incorrect PIN SnackBar
      expect(find.text('Incorrect PIN! Try "1234"'), findsOneWidget);
    });

    testWidgets('Backspace key removes last digit', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      // Tap '1', '2'
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();

      // Tap Backspace icon button
      final backspaceFinder = find.byIcon(Icons.backspace_outlined);
      expect(backspaceFinder, findsOneWidget);
      await tester.tap(backspaceFinder);
      await tester.pump();

      // Tap '3', '4' (if backspace worked, the pin so far is 1, so 1+3+4 = 134, which is incorrect and won't unlock. If it didn't work, it is 1234 and will unlock)
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      // Verify we are NOT on the dashboard screen
      expect(find.text('Dashboard Screen'), findsNothing);
    });
  });
}
