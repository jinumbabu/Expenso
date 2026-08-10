import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/chat/presentation/screens/chat_screen.dart';
import 'package:app/features/chat/presentation/providers/chat_provider.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/core/security/audit_logger.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/chat/domain/repositories/chat_repository.dart';

class FakeChatRepository extends Fake implements ChatRepository {
  final List<ChatHistoryItem> messages = [];

  @override
  Future<List<ChatHistoryItem>> getChatHistory(String userId) async {
    return messages;
  }

  @override
  Future<void> saveMessage({
    required String userId,
    required String role,
    required String message,
    required String aiMode,
  }) async {
    messages.add(
      ChatHistoryItem(
        id: (messages.length + 1).toString(),
        userId: userId,
        role: role,
        message: message,
        createdAt: DateTime.now(),
        aiMode: aiMode,
      ),
    );
  }

  @override
  Future<void> clearHistory(String userId) async {
    messages.clear();
  }
}

class FakeRef extends Fake implements Ref {}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier() : super(FakeAuthRepository(), FakeAuditLogger(), FakeRef()) {
    state = AuthState.authenticated(
      User(
        id: 'user1',
        googleId: 'g1',
        email: 'jinu@expenso.ai',
        displayName: 'Jinu',
        currency: 'INR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> checkSession() async {}
}

class FakeAuthRepository extends Fake implements AuthRepository {}
class FakeAuditLogger extends Fake implements AuditLogger {}

void main() {
  group('ChatScreen Widget Tests', () {
    testWidgets('Renders ChatGPT style input with placeholder and opens bottom sheet on More Details tap', (tester) async {
      tester.view.physicalSize = const Size(800, 1500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepository = FakeChatRepository();
      
      fakeRepository.messages.addAll([
        ChatHistoryItem(
          id: '1',
          userId: 'user1',
          role: 'user',
          message: 'Analyze my spending',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          aiMode: 'Offline AI',
        ),
        ChatHistoryItem(
          id: '2',
          userId: 'user1',
          role: 'model',
          message: 'Health Score: 85. Monthly expenses: ₹20000. Food: ₹5000. Tips: Try reducing dining out.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
          aiMode: 'Offline AI',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
          ],
          child: const MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify modern text input composer with placeholder is rendered
      expect(find.text('Ask anything about your finances...'), findsOneWidget);

      // 2. Verify More Details compact action button is visible on AI response
      expect(find.text('More Details'), findsOneWidget);

      // 3. Verify that details are initially NOT visible (as they are in the bottom sheet now)
      expect(find.text('FINANCIAL HEALTH SCORE'), findsNothing);

      // 4. Tap "More Details" to open bottom sheet
      await tester.tap(find.text('More Details'));
      await tester.pumpAndSettle();

      // 5. Verify bottom sheet content is shown
      expect(find.text('Financial Insights & Tools'), findsOneWidget);
      expect(find.text('FINANCIAL HEALTH SCORE'), findsOneWidget);
      expect(find.text('AI ASSISTANT TOOLS'), findsOneWidget);
      expect(find.text('View Analytics'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
      expect(find.text('Budget Planner'), findsOneWidget);
      expect(find.text('Savings Tips'), findsOneWidget);
      expect(find.text('Spending Trends'), findsOneWidget);
      expect(find.text('Income Analysis'), findsOneWidget);
      expect(find.text('Cash Flow'), findsOneWidget);
      expect(find.text('Budget Insights'), findsOneWidget);
      expect(find.text('Monthly Report'), findsOneWidget);
    });

    testWidgets('ChatGPT scrolling and simulated streaming test', (tester) async {
      tester.view.physicalSize = const Size(800, 1500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepository = FakeChatRepository();
      
      fakeRepository.messages.addAll([
        ChatHistoryItem(
          id: '1',
          userId: 'user1',
          role: 'user',
          message: 'Analyze my spending',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          aiMode: 'Offline AI',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
          ],
          child: const MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial message is displayed
      expect(find.text('Analyze my spending'), findsOneWidget);

      // Now add a model message representing the streaming response
      final newMsg = ChatHistoryItem(
        id: '2',
        userId: 'user1',
        role: 'model',
        message: 'This is a long financial recommendation response that will stream word by word.',
        createdAt: DateTime.now(),
        aiMode: 'Offline AI',
      );
      
      // Inject to repository
      fakeRepository.messages.add(newMsg);

      // Invalidate provider using the Container
      final container = ProviderScope.containerOf(tester.element(find.byType(ChatScreen)));
      container.invalidate(chatHistoryProvider('user1'));

      // Pump to trigger riverpod listener
      await tester.pump();
      
      // Since it streams character-by-character every 20ms:
      // After 100ms, the text should be partially revealed
      await tester.pump(const Duration(milliseconds: 100));
      
      // The full text should NOT be fully visible yet, but a prefix should be
      expect(find.text('This is a long financial recommendation response that will stream word by word.'), findsNothing);

      // Let's advance by 500ms to complete the streaming
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // The full text should be visible now
      expect(find.text('This is a long financial recommendation response that will stream word by word.'), findsOneWidget);
    });
  });
}
