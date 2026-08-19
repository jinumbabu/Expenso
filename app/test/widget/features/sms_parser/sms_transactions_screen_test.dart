import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:app/features/sms_parser/presentation/screens/sms_transactions_screen.dart';
import 'package:app/features/sms_parser/presentation/providers/sms_parser_provider.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/core/security/audit_logger.dart';
import 'package:app/features/accounts/presentation/providers/accounts_provider.dart';

class FakeDatabase extends Fake implements AppDatabase {}
class FakeAuthRepository extends Fake implements AuthRepository {}
class FakeAuditLogger extends Fake implements AuditLogger {}
class FakeRef extends Fake implements Ref {}
class FakeAccountsNotifier extends AccountsNotifier {
  FakeAccountsNotifier() : super(db: FakeDatabase(), userId: null) {
    state = const AsyncValue.data([]);
  }

  @override
  void _initStream() {}

  @override
  Future<void> loadAccounts() async {}
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(User user) : super(FakeAuthRepository(), FakeAuditLogger(), FakeRef()) {
    state = AuthState.authenticated(user);
  }

  @override
  Future<void> checkSession() async {}
}

class FakeSmsScannerNotifier extends StateNotifier<SmsScannerState> implements SmsScannerNotifier {
  FakeSmsScannerNotifier() : super(SmsScannerState(
    scannedSmsCount: 248,
    detectedTransactionsCount: 18,
    smsPermissionStatus: PermissionStatus.granted,
  ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> scanInbox({bool silent = false}) async {
    state = state.copyWith(isScanning: true);
    await Future.delayed(const Duration(milliseconds: 10));
    state = state.copyWith(isScanning: false, scannedSmsCount: 250, detectedTransactionsCount: 20);
  }

  @override
  Future<void> requestSmsPermission() async {
    state = state.copyWith(smsPermissionStatus: PermissionStatus.granted);
  }

  @override
  Future<void> checkPermissions() async {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  @override
  Future<Map<String, int>> approveAllDrafts() async {
    return {'imported': 0, 'skipped': 0};
  }

  @override
  Future<void> deleteAllDrafts() async {}

  @override
  Future<void> dismissDraft(String draftId) async {}

  @override
  Future<bool> importMockSms(String sender, String body) async {
    return true;
  }

  @override
  Future<void> linkDraftToManual(String draftId, String manualTxId) async {}

  @override
  Future<void> requestAllPermissions() async {}

  @override
  Future<void> requestNotificationPermission() async {}

  @override
  Future<bool> runPermissionTest() async {
    return true;
  }

  @override
  Future<void> toggleAutoImport(bool value) async {}
}

void main() {
  group('SmsTransactionsScreen Widget Tests', () {
    late User testUser;
    late MockAuthNotifier mockAuth;
    late FakeSmsScannerNotifier fakeScanner;

    setUp(() {
      testUser = User(
        id: 'user-123',
        googleId: 'google-id',
        email: 'test@expenso.ai',
        displayName: 'Test User',
        currency: 'INR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuth = MockAuthNotifier(testUser);
      fakeScanner = FakeSmsScannerNotifier();
    });

    testWidgets('Renders layout elements correctly and handles scan triggers', (tester) async {
      tester.view.physicalSize = const Size(800, 1500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(FakeDatabase()),
            authProvider.overrideWith((ref) => mockAuth),
            categoriesProvider.overrideWith((ref) => Future.value([])),
            paymentMethodsProvider.overrideWith((ref) => Future.value([])),
            accountsProvider.overrideWith((ref) => FakeAccountsNotifier()),
            transactionDraftsStreamProvider.overrideWith((ref) => Stream.value([])),
            savedSmsTransactionsCountProvider.overrideWith((ref) => Future.value(12)),
            smsScannerProvider.overrideWith((ref) => fakeScanner),
          ],
          child: const MaterialApp(
            home: SmsTransactionsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Verify header title
      expect(find.text('SMS Transactions'), findsOneWidget);

      // Verify Scanner control card elements
      expect(find.text('SMS Transaction Scanner'), findsOneWidget);
      expect(find.text('✓ Enabled'), findsOneWidget);
      expect(find.text('Scan SMS'), findsOneWidget);

      // Verify Stats rendering
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('248'), findsOneWidget);
      expect(find.text('Transaction'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('0'), findsOneWidget); // pending count (0 from drafts stream)
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('12'), findsOneWidget); // saved count from future override

      // Tap Scan SMS button
      await tester.tap(find.text('Scan SMS'));
      await tester.pump();

      // Verify scanning progress indicator or text
      expect(find.text('Scanning SMS...'), findsOneWidget);

      // Settle animation and scan async completion
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();

      // Verify updated stats after scanning
      expect(find.text('250'), findsOneWidget); // scannedSmsCount updated to 250
      expect(find.text('20'), findsOneWidget); // detectedTransactionsCount updated to 20
    });
  });
}
