import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/dashboard/presentation/screens/quick_add_notepad_screen.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/core/security/audit_logger.dart';
import 'package:app/core/services/quick_add_notepad_service.dart';
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

class MockQuickAddNotepadService extends QuickAddNotepadService {
  MockQuickAddNotepadService(super.ref);

  @override
  List<ParsedLine> parseDocument(String documentText, [List<Account>? accounts]) {
    return [
      ParsedLine(rawText: 'Food 250', amount: 250.0, category: 'Food', merchant: 'Food', type: 'expense', accountName: 'Cash', accountType: 'cash'),
    ];
  }

  @override
  Future<List<ParsedLine>> detectDuplicates(List<ParsedLine> lines, String userId) async {
    return lines;
  }

  @override
  Future<Map<String, int>> saveAll(List<ParsedLine> lines, String userId) async {
    return {'parsed': 1, 'saved': 1, 'failed': 0, 'skipped': 0};
  }
}

void main() {
  group('QuickAddNotepadScreen Widget Tests', () {
    late User testUser;
    late MockAuthNotifier mockAuth;

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
    });

    testWidgets('Renders layout elements correctly', (tester) async {
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
            quickAddNotepadServiceProvider.overrideWith((ref) => MockQuickAddNotepadService(ref)),
          ],
          child: const MaterialApp(
            home: QuickAddNotepadScreen(),
          ),
        ),
      );

      // Verify title and subtitle
      expect(find.text('Quick Add AI'), findsOneWidget);
      expect(find.text('Add multiple transactions at once'), findsOneWidget);

      // Verify buttons
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Notepad'), findsOneWidget);
      expect(find.text('Preview Table'), findsOneWidget);

      // Verify default text is present in the editor field
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Tapping Preview Table switches tab views', (tester) async {
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
            categoriesProvider.overrideWith((ref) => Future.value([
              Category(id: 'cat-1', userId: 'user-123', name: 'Food', type: 'expense', icon: 'fastfood', usageCount: 0, isSystemDefault: true, createdAt: DateTime.now()),
            ])),
            paymentMethodsProvider.overrideWith((ref) => Future.value([
              PaymentMethod(id: 'pm-1', userId: 'user-123', name: 'Cash', type: 'cash', usageCount: 0, createdAt: DateTime.now()),
            ])),
            accountsProvider.overrideWith((ref) => FakeAccountsNotifier()),
            quickAddNotepadServiceProvider.overrideWith((ref) => MockQuickAddNotepadService(ref)),
          ],
          child: const MaterialApp(
            home: QuickAddNotepadScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Enter text to trigger parsing and populate lines
      await tester.enterText(find.byType(TextField), 'Food 250');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
 
      // Tap on Preview Table button
      await tester.tap(find.text('Preview Table'));
      await tester.pumpAndSettle();

      // Verify the tab changed by looking for EDIT / REVIEW BEFORE SAVING text
      expect(find.text('EDIT / REVIEW BEFORE SAVING'), findsOneWidget);
    });
  });
}
