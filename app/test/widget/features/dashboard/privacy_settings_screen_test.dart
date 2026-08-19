import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/dashboard/presentation/screens/privacy_settings_screen.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/database/dao/ai_memory_dao.dart';
import 'package:app/core/database/dao/audit_log_dao.dart';
import 'package:app/core/security/audit_logger.dart';
import 'package:app/core/security/secure_storage_service.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String _tempPath;
  MockPathProviderPlatform(this._tempPath);

  @override
  Future<String?> getApplicationSupportPath() async => _tempPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => _tempPath;
}

class MockSecureStorageService extends Fake implements SecureStorageService {
  String privacyMode = 'hybrid';
  bool hasRequested = false;
  bool autoImport = true;
  DateTime? lastReqTime;
  DateTime? lastSync;
  final Map<String, String> _storage = {};

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
    if (key == 'ai_privacy_mode') {
      privacyMode = value;
    }
  }

  @override
  Future<String?> read(String key) async {
    return _storage[key] ?? (key == 'ai_privacy_mode' ? privacyMode : null);
  }

  @override
  Future<String?> getPrivacyMode() async => privacyMode;

  @override
  Future<String?> getUserId() async => null;

  @override
  Future<void> savePrivacyMode(String mode) async {
    privacyMode = mode;
  }

  @override
  Future<bool> getHasRequestedSmsPermission() async => hasRequested;

  @override
  Future<void> saveHasRequestedSmsPermission(bool value) async {
    hasRequested = value;
  }

  @override
  Future<bool> getAutoImportEnabled() async => autoImport;

  @override
  Future<void> saveAutoImportEnabled(bool value) async {
    autoImport = value;
  }

  @override
  Future<DateTime?> getLastPermissionRequestTime() async => lastReqTime;

  @override
  Future<void> saveLastPermissionRequestTime(DateTime time) async {
    lastReqTime = time;
  }

  @override
  Future<DateTime?> getLastSmsSyncTime() async => lastSync;

  @override
  Future<void> saveLastSmsSyncTime(DateTime time) async {
    lastSync = time;
  }
}

class MockAuditLogger extends Fake implements AuditLogger {
  bool logCalled = false;
  String? loggedEventType;

  @override
  Future<void> logEvent({
    required String? userId,
    required String eventType,
    required String eventCategory,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    logCalled = true;
    loggedEventType = eventType;
  }
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(User user) : super(FakeAuthRepository(), FakeAuditLogger(), FakeRef()) {
    state = AuthState.authenticated(user);
  }

  @override
  Future<void> checkSession() async {}
}

class FakeAuthRepository extends Fake implements AuthRepository {}
class FakeAuditLogger extends Fake implements AuditLogger {}
class FakeRef extends Fake implements Ref {}

class MockAiMemoryDao extends Fake implements AiMemoryDao {
  List<AiMemoryItem> memories = [];

  @override
  Future<List<AiMemoryItem>> getMemories(String userId) async {
    return memories;
  }

  @override
  Future<int> deleteMemory(String id) async {
    memories.removeWhere((item) => item.id == id);
    return 1;
  }

  @override
  Future<int> clearMemories(String userId) async {
    memories.clear();
    return 1;
  }
}

class MockAuditLogDao extends Fake implements AuditLogDao {
  List<AuditLog> logs = [];

  @override
  Future<List<AuditLog>> getLogsForUser(String userId) async {
    return logs;
  }

  @override
  Future<int> clearAllLogs(String userId) async {
    logs.clear();
    return 1;
  }
}

class MockAppDatabase extends Fake implements AppDatabase {
  final MockAiMemoryDao mockAiMemoryDao = MockAiMemoryDao();
  final MockAuditLogDao mockAuditLogDao = MockAuditLogDao();

  @override
  MockAiMemoryDao get aiMemoryDao => mockAiMemoryDao;

  @override
  MockAuditLogDao get auditLogDao => mockAuditLogDao;

  @override
  Future<void> close() async {}
}

void main() {
  group('PrivacySettingsScreen Widget Tests', () {
    late String testTempPath;
    late MockAppDatabase database;
    late MockSecureStorageService mockSecureStorage;
    late MockAuditLogger mockAuditLogger;
    late MockAuthNotifier mockAuthNotifier;
    late User testUser;

    setUp(() async {
      final systemTemp = Directory.systemTemp.createTempSync('expenso_test_');
      testTempPath = systemTemp.path;
      PathProviderPlatform.instance = MockPathProviderPlatform(testTempPath);

      database = MockAppDatabase();
      mockSecureStorage = MockSecureStorageService();
      mockAuditLogger = MockAuditLogger();

      testUser = User(
        id: 'user-privacy-123',
        googleId: 'google-privacy-id',
        email: 'privacy@expenso.ai',
        displayName: 'Privacy User',
        currency: 'INR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthNotifier = MockAuthNotifier(testUser);
    });

    tearDown(() async {
      await database.close();
      try {
        final dir = Directory(testTempPath);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    testWidgets('Renders all initial widgets correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            authProvider.overrideWith((ref) => mockAuthNotifier),
            secureStorageProvider.overrideWithValue(mockSecureStorage),
            auditLoggerProvider.overrideWithValue(mockAuditLogger),
          ],
          child: const MaterialApp(
            home: PrivacySettingsScreen(),
          ),
        ),
      );

      // Verify Screen Title
      expect(find.text('Settings & Security'), findsOneWidget);

      // Verify AI Privacy Mode exists
      expect(find.text('Hybrid (Recommended)'), findsOneWidget);

      // Verify section titles
      expect(find.text('SECURITY'), findsOneWidget);
      expect(find.text('AI PRIVACY & SETTINGS'), findsOneWidget);
      expect(find.text('DATA & BACKUP'), findsOneWidget);

      // Verify database details
      expect(find.text('Database Storage Footprint'), findsOneWidget);
    });

    testWidgets('Toggling privacy mode updates state and logs audit event', (tester) async {
      tester.view.physicalSize = const Size(800, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            authProvider.overrideWith((ref) => mockAuthNotifier),
            secureStorageProvider.overrideWithValue(mockSecureStorage),
            auditLoggerProvider.overrideWithValue(mockAuditLogger),
          ],
          child: const MaterialApp(
            home: PrivacySettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.text('Hybrid (Recommended)'));
      await tester.pumpAndSettle();

      // Select Local (Device)
      await tester.tap(find.text('Local (Device)').last);
      await tester.pumpAndSettle();

      // Verify storage updated
      expect(mockSecureStorage.privacyMode, equals('local'));

      // Verify audit log logged
      expect(mockAuditLogger.logCalled, isTrue);
      expect(mockAuditLogger.loggedEventType, equals('privacy_mode_changed'));
    });

    testWidgets('Switch / Manage Accounts bottom sheet renders custom Row layout with ellipsis and checkmark/Switch buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAccounts = [
        {'id': 'user-privacy-123', 'displayName': 'Privacy User', 'email': 'privacy@expenso.ai'},
        {'id': 'user-other', 'displayName': 'HappinessHypothesis', 'email': 'happinesshypothesis1@gmail.com'},
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            authProvider.overrideWith((ref) => mockAuthNotifier),
            secureStorageProvider.overrideWithValue(mockSecureStorage),
            auditLoggerProvider.overrideWithValue(mockAuditLogger),
            registeredAccountsProvider.overrideWith((ref) => Future.value(mockAccounts)),
          ],
          child: const MaterialApp(
            home: PrivacySettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Open the bottom sheet by tapping "Switch / Manage Accounts"
      await tester.tap(find.text('Switch / Manage Accounts'));
      await tester.pumpAndSettle();

      // 2. Verify sheet is opened and header is rendered
      expect(find.text('REGISTERED ACCOUNTS'), findsOneWidget);

      // 3. Verify display names and emails are rendered
      expect(find.text('Privacy User'), findsNWidgets(2));
      expect(find.text('privacy@expenso.ai'), findsNWidgets(2));
      expect(find.text('HappinessHypothesis'), findsOneWidget);
      expect(find.text('happinesshypothesis1@gmail.com'), findsOneWidget);

      // 4. Verify that the active account has checkmark icon, and inactive has 'Switch' text
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Switch'), findsOneWidget);

      // 5. Verify the profile initial letter avatar is rendered
      expect(find.text('P'), findsOneWidget);
      expect(find.text('H'), findsOneWidget);
    });
  });
}
