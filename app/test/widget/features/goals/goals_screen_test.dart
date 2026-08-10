import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/goals/presentation/providers/goals_provider.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/core/security/audit_logger.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/goals/presentation/screens/goals_screen.dart';

class FakeRef extends Fake implements Ref {}

class MockGoalsListNotifier extends GoalsListNotifier {
  MockGoalsListNotifier(List<Goal> initialGoals) : super(FakeRef()) {
    state = initialGoals;
  }

  @override
  Future<void> loadGoals() async {}
}

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
  group('GoalsScreen Widget Tests', () {
    late List<Goal> mockGoals;

    setUp(() {
      mockGoals = [
        Goal(
          id: 'goal1',
          userId: 'user1',
          title: 'Car Fund',
          targetAmount: 10000000, // ₹1,00,000 (cents)
          currentAmount: 4000000,  // ₹40,000 (cents)
          targetDate: DateTime.now().add(const Duration(days: 90)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    testWidgets('Renders goals lists and progress percentages correctly', (tester) async {
      final fakeGoalsNotifier = MockGoalsListNotifier(mockGoals);
      final fakeAuthNotifier = FakeAuthNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalsListNotifierProvider.overrideWith((ref) => fakeGoalsNotifier),
            authProvider.overrideWith((ref) => fakeAuthNotifier),
          ],
          child: const MaterialApp(
            home: GoalsScreen(),
          ),
        ),
      );

      // Verify header title
      expect(find.text('Goals & Savings'), findsOneWidget);

      // Verify mock goal renders title
      expect(find.text('Car Fund'), findsOneWidget);

      // Verify saved amount and target amount
      expect(find.text('Saved: ₹40,000'), findsOneWidget);
      expect(find.text('Target: ₹100,000'), findsOneWidget);

      // Verify savings percentage (40,000 / 100,000 = 40%)
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('Displays empty state card when there are no goals', (tester) async {
      final fakeGoalsNotifier = MockGoalsListNotifier([]);
      final fakeAuthNotifier = FakeAuthNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalsListNotifierProvider.overrideWith((ref) => fakeGoalsNotifier),
            authProvider.overrideWith((ref) => fakeAuthNotifier),
          ],
          child: const MaterialApp(
            home: GoalsScreen(),
          ),
        ),
      );

      // Verify empty state text
      expect(find.text('No active savings targets'), findsOneWidget);
      expect(find.text('Create a target goal (e.g. Emergency reserve, holiday trip) and lock your savings away to track your progress.'), findsOneWidget);
    });
  });
}
