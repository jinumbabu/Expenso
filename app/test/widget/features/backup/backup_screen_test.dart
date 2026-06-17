import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/backup/presentation/providers/backup_provider.dart';
import 'package:app/features/backup/presentation/screens/backup_screen.dart';

import 'package:app/core/database/app_database.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/core/security/audit_logger.dart';
import 'package:app/core/sync/backup_service.dart';

class FakeBackupService extends Fake implements BackupService {}
class FakeAuditLogger extends Fake implements AuditLogger {}
class FakeRef extends Fake implements Ref {}
class FakeAuthRepository extends Fake implements AuthRepository {}

class MockBackupNotifier extends BackupNotifier {
  bool backupCalled = false;
  bool restoreCalled = false;

  MockBackupNotifier() : super(FakeBackupService(), FakeAuditLogger(), FakeRef());

  void setBackupState(BackupState newState) {
    state = newState;
  }

  @override
  Future<void> loadBackupInfo() async {
    // Prevent loadBackupInfo from running real operations on initialization
  }

  @override
  Future<void> createBackup() async {
    backupCalled = true;
  }

  @override
  Future<void> restoreBackup() async {
    restoreCalled = true;
  }
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(User user) : super(FakeAuthRepository(), FakeAuditLogger()) {
    state = AuthState.authenticated(user);
  }

  @override
  Future<void> checkSession() async {
    // Prevent checkSession from running real operations on initialization
  }
}

void main() {
  group('BackupScreen Widget Tests', () {
    late MockBackupNotifier mockBackupNotifier;
    late MockAuthNotifier mockAuthNotifier;
    late User testUser;

    setUp(() {
      testUser = User(
        id: 'user-123',
        googleId: 'mock-google-id',
        email: 'tester@expenso.ai',
        displayName: 'Test User',
        currency: 'INR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockBackupNotifier = MockBackupNotifier();
      mockAuthNotifier = MockAuthNotifier(testUser);
    });

    testWidgets('Renders layout and initial state correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupNotifierProvider.overrideWith((ref) => mockBackupNotifier),
            authProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: BackupScreen(),
          ),
        ),
      );

      // Verify titles and key elements
      expect(find.text('Sync & Backup'), findsOneWidget);
      expect(find.text('Secure Cloud Backups'), findsOneWidget);
      expect(find.text('Never Backed Up'), findsOneWidget);
      expect(find.text('0 KB'), findsOneWidget);
      expect(find.text('AES-256 (Local Key)'), findsOneWidget);

      // Verify primary action buttons exist
      expect(find.text('Backup Now'), findsOneWidget);
      expect(find.text('Restore Backup'), findsOneWidget);
    });

    testWidgets('Displays formatted metadata (date & size) when loaded', (tester) async {
      mockBackupNotifier.setBackupState(BackupState(
        isLoading: false,
        lastBackupDate: DateTime(2026, 6, 17, 14, 30),
        backupSize: 5120, // 5 KB
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupNotifierProvider.overrideWith((ref) => mockBackupNotifier),
            authProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: BackupScreen(),
          ),
        ),
      );

      await tester.pump();

      // Check formatted size and date
      expect(find.text('5.0 KB'), findsOneWidget);
      expect(find.textContaining('Jun 17, 2026'), findsOneWidget);
    });

    testWidgets('Tapping Backup Now triggers notifier action', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupNotifierProvider.overrideWith((ref) => mockBackupNotifier),
            authProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: BackupScreen(),
          ),
        ),
      );

      final buttonFinder = find.text('Backup Now');
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();

      await tester.tap(buttonFinder);
      await tester.pump();

      expect(mockBackupNotifier.backupCalled, isTrue);
    });

    testWidgets('Restore Backup button is disabled when no backup exists', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupNotifierProvider.overrideWith((ref) => mockBackupNotifier),
            authProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: BackupScreen(),
          ),
        ),
      );

      final buttonFinder = find.byWidgetPredicate((widget) => widget is OutlinedButton);
      final OutlinedButton button = tester.widget<OutlinedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('Tapping Restore Backup shows warning popup and triggers restore', (tester) async {
      mockBackupNotifier.setBackupState(BackupState(
        isLoading: false,
        lastBackupDate: DateTime.now(),
        backupSize: 1024,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupNotifierProvider.overrideWith((ref) => mockBackupNotifier),
            authProvider.overrideWith((ref) => mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: BackupScreen(),
          ),
        ),
      );

      await tester.pump();

      final buttonFinder = find.text('Restore Backup');
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();

      // Tap restore button
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Verify Dialog opens
      expect(find.text('Restore Cancel'), findsNothing); // Cancel button is styled "Cancel"
      expect(find.text('Restore Now'), findsOneWidget);

      // Confirm dialog
      await tester.tap(find.text('Restore Now'));
      await tester.pump();

      expect(mockBackupNotifier.restoreCalled, isTrue);
    });
  });
}
