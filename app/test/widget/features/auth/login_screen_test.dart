import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/auth/presentation/screens/login_screen.dart';

import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/core/security/audit_logger.dart';

class FakeAuthRepository extends Fake implements AuthRepository {}
class FakeAuditLogger extends Fake implements AuditLogger {}

class MockAuthNotifier extends AuthNotifier {
  bool loginCalled = false;
  String? lastToken;

  MockAuthNotifier() : super(FakeAuthRepository(), FakeAuditLogger()) {
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
      expect(find.text('Expenso AI'), findsOneWidget);
      expect(find.text('Your Intelligent Financial Assistant'), findsOneWidget);
      expect(find.text('Secure Sign In'), findsOneWidget);

      // Verify TextField and Google sign in button exist
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Sign In with Google'), findsOneWidget);
    });

    testWidgets('Tapping Sign In triggers login action with token', (tester) async {
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

      // Tap Google sign-in button
      await tester.tap(find.text('Sign In with Google'));
      await tester.pump();

      // Check if notifier received the login call
      expect(mockAuthNotifier.loginCalled, isTrue);
      expect(mockAuthNotifier.lastToken, equals('mock-google-id-token'));
    });

    testWidgets('Renders error banner when error state occurs', (tester) async {
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
