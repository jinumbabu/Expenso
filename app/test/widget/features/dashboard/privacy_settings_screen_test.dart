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

  @override
  Future<String?> getPrivacyMode() async => privacyMode;

  @override
  Future<void> savePrivacyMode(String mode) async {
    privacyMode = mode;
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
  MockAuthNotifier(User user) : super(FakeAuthRepository(), FakeAuditLogger()) {
    state = AuthState.authenticated(user);
  }

  @override
  Future<void> checkSession() async {}
}

class FakeAuthRepository extends Fake implements AuthRepository {}
class FakeAuditLogger extends Fake implements AuditLogger {}

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
      expect(find.text('PRIVACY & SECURITY'), findsOneWidget);

      // Verify AI Privacy Modes exist
      expect(find.text('Local (Private)'), findsOneWidget);
      expect(find.text('Hybrid (Recommended)'), findsOneWidget);
      expect(find.text('Cloud (Gemini)'), findsOneWidget);

      // Verify section titles
      expect(find.text('AI PRIVACY MODE'), findsOneWidget);
      expect(find.text('AI MEMORY TRANSPARENCY'), findsOneWidget);
      expect(find.text('DATA METRICS & AUDIT LOGS'), findsOneWidget);

      // Verify database details
      expect(find.text('Database Encryption'), findsOneWidget);
    });

    testWidgets('Toggling privacy mode updates state and logs audit event', (tester) async {
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

      // Tap on Local (Private) mode card
      final localModeFinder = find.text('Local (Private)');
      await tester.tap(localModeFinder);
      await tester.pumpAndSettle();

      // Verify storage updated
      expect(mockSecureStorage.privacyMode, equals('local'));

      // Verify audit log logged
      expect(mockAuditLogger.logCalled, isTrue);
      expect(mockAuditLogger.loggedEventType, equals('privacy_mode_changed'));
    });
  });
}
