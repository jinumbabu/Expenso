import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/auth/presentation/screens/login_screen.dart';
import 'package:app/shared/widgets/brand_logo.dart';

import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/core/security/audit_logger.dart';

class FakeAuthRepository extends Fake implements AuthRepository {}
class FakeAuditLogger extends Fake implements AuditLogger {}

class FakeRef extends Fake implements Ref {}

class MockAuthNotifier extends AuthNotifier {
  bool loginCalled = false;
  String? lastToken;

  MockAuthNotifier() : super(FakeAuthRepository(), FakeAuditLogger(), FakeRef()) {
    state = AuthState.unauthenticated();
  }

  @override
  Future<void> checkSession() async {
    // Prevent real session check on initialization
  }

  @override
  Future<void> loginWithGoogle(String token) async {
    loginCalled = true;
    lastToken = token;
    state = AuthState.loading();
  }

  void setError(String error) {
    state = AuthState.unauthenticated(error: error);
  }
}

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthNotifier mockAuthNotifier;

    setUp(() {
      mockAuthNotifier = MockAuthNotifier();
    });

    testWidgets('Renders all initial widgets correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify branding and title renders
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(find.byType(BrandWordmark), findsOneWidget);
      expect(find.text('AI Powered Personal Finance'), findsOneWidget);
      expect(find.text('Secure'), findsOneWidget);

      // Verify TextField and Google sign in button exist
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('Tapping Sign In triggers login action with token', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Tap privacy acceptance checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Tap Google sign-in button
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      // Check if notifier received the login call
      expect(mockAuthNotifier.loginCalled, isTrue);
      expect(mockAuthNotifier.lastToken, equals('mock-google-id-token'));
    });

    testWidgets('Renders error banner when error state occurs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockAuthNotifier.setError('Authentication failed, please try again.');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Pump to ensure layout completes
      await tester.pump();

      // Verify error message exists on UI
      expect(find.text('Authentication failed, please try again.'), findsOneWidget);
    });
  });
}
