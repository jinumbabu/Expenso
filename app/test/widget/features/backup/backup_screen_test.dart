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
class FakeRef extends Fake implements Ref {
  @override
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    return FakeProviderSubscription<T>();
  }
}

class FakeProviderSubscription<T> extends Fake implements ProviderSubscription<T> {
  @override
  void close() {}
}

class FakeAuthRepository extends Fake implements AuthRepository {}

class MockBackupNotifier extends BackupNotifier {
  bool backupCalled = false;
  bool restoreCalled = false;
  bool dismissCalled = false;

  MockBackupNotifier() : super(FakeBackupService(), FakeAuditLogger(), FakeRef());

  void setBackupState(BackupState newState) {
    state = newState;
  }

  @override
  Future<void> loadBackupInfo() async {
    // Prevent loadBackupInfo from running real operations on initialization
  }

  @override
  Future<void> createBackup({
    bool backupAiSettings = false,
    bool backupApiKeys = false,
    bool backupSelectedModels = false,
  }) async {
    backupCalled = true;
  }

  @override
  Future<void> restoreBackup([Map<String, dynamic>? selectedBackup, bool isLocal = false]) async {
    restoreCalled = true;
  }

  @override
  void dismissProgressDialog() {
    dismissCalled = true;
  }
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(User user) : super(FakeAuthRepository(), FakeAuditLogger(), FakeRef()) {
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
      tester.view.physicalSize = const Size(800, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
      expect(find.text('Sync & Backup Settings'), findsOneWidget);
      expect(find.text('CLOUD PROFILE'), findsOneWidget);
      expect(find.text('Never'), findsNWidgets(3));
      expect(find.text('0 KB'), findsNWidgets(3));
      expect(find.text('Simulated Local Storage'), findsOneWidget);

      // Verify primary action buttons exist
      expect(find.text('Sync Now'), findsOneWidget);
      expect(find.text('Backup Now'), findsOneWidget);
      expect(find.text('Restore Backup'), findsOneWidget);
    });

    testWidgets('Displays formatted metadata (date & size) when loaded', (tester) async {
      tester.view.physicalSize = const Size(800, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockBackupNotifier.setBackupState(BackupState(
        isLoading: false,
        lastBackupDate: DateTime(2026, 6, 17, 14, 30),
        backupSize: 5120, // 5 KB
        lastLocalBackupDate: DateTime(2026, 6, 17, 14, 30),
        lastLocalBackupSize: 5120,
        lastCloudBackupDate: DateTime(2026, 6, 17, 14, 30),
        lastCloudBackupSize: 5120,
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
      expect(find.text('5.0 KB'), findsNWidgets(2));
      expect(find.textContaining('17 Jun 2026'), findsAtLeastNWidgets(1));
    });

    testWidgets('Tapping Backup Now triggers notifier action', (tester) async {
      tester.view.physicalSize = const Size(800, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(mockBackupNotifier.backupCalled, isTrue);
    });

    testWidgets('Restore Backup button is disabled when no backup exists', (tester) async {
      tester.view.physicalSize = const Size(800, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      final restoreButtonFinder = find.ancestor(
        of: find.text('Restore Backup'),
        matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
      );
      final OutlinedButton restoreButton = tester.widget<OutlinedButton>(restoreButtonFinder);
      expect(restoreButton.onPressed, isNull);
    });

    testWidgets('Tapping Restore Backup shows warning popup and triggers restore', (tester) async {
      tester.view.physicalSize = const Size(800, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Verify Dialog opens
      expect(find.text('Restore Cancel'), findsNothing); // Cancel button is styled "Cancel"
      expect(find.text('Restore'), findsOneWidget);

      // Confirm dialog
      await tester.tap(find.text('Restore'));
      await tester.pump();

      expect(mockBackupNotifier.restoreCalled, isTrue);
    });

    testWidgets('Progress dialog shows success checkmark and Done button when completed', (tester) async {
      tester.view.physicalSize = const Size(800, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockBackupNotifier.setBackupState(BackupState(
        isLoading: false,
        isProgressVisible: true,
        progressTitle: 'Backing Up to Google Drive',
        progressPercentage: 1.0,
        progressStep: 7,
        progressTotalSteps: 7,
        progressCurrentTask: 'Backup completed successfully.',
        progressElapsedTime: 12,
        progressEstimatedRemaining: 0,
        operationState: BackupOperationState.completed,
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

      // Check for green checkmark icon
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Check Done button is shown instead of Cancel
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);

      // Check estimated remaining time is 00:00
      expect(find.text('00:00'), findsOneWidget);

      // Tap Done and verify dismissal action triggered
      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(mockBackupNotifier.dismissCalled, isTrue);
    });
  });
}
