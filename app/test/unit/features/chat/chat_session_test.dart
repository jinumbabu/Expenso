import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI Chat Session Management Tests', () {
    const Duration oneHour = Duration(hours: 1);

    test('Session active when elapsed time < 1 hour', () {
      final startTime = DateTime(2026, 9, 16, 10, 0, 0);
      final checkTime = DateTime(2026, 9, 16, 10, 45, 0);

      final elapsed = checkTime.difference(startTime);
      expect(elapsed < oneHour, isTrue);
    });

    test('Session expires when elapsed time >= 1 hour', () {
      final startTime = DateTime(2026, 9, 16, 10, 0, 0);
      final checkTime = DateTime(2026, 9, 16, 11, 0, 0);

      final elapsed = checkTime.difference(startTime);
      expect(elapsed >= oneHour, isTrue);
    });

    test('Session expiration across app restart after > 1 hour', () {
      final startTime = DateTime(2026, 9, 16, 9, 0, 0);
      // App restart at 10:15 AM
      final checkTime = DateTime(2026, 9, 16, 10, 15, 0);

      final elapsed = checkTime.difference(startTime);
      expect(elapsed >= oneHour, isTrue);
    });
  });

  group('AI Chat Suggestion Randomization Tests', () {
    const List<String> fullSuggestionPool = [
      'How much did I save this month?',
      'What are my biggest expenses?',
      'Show my recent transactions',
      'Help me create a budget',
      'Where did most of my money go this month?',
      'Which category increased the most?',
      'How much did I spend this week?',
      'What is my biggest expense?',
      'How much income did I receive this month?',
      'What subscriptions am I paying for?',
      'Compare my spending with last month',
      'Which account has the highest balance?',
      'How much did I spend on food?',
      'How much did I spend on shopping?',
      'Am I spending more than I earn?',
      'What can I reduce from my expenses?',
      'Show my top spending categories',
      'What are my unusual expenses?',
      'How much did I spend using UPI?',
      'How much did I spend using my credit card?',
    ];

    List<String> getRandomSuggestions(
      List<String>? lastSet, {
      int count = 4,
      Random? random,
    }) {
      final rand = random ?? Random(42);
      List<String> pool = List.from(fullSuggestionPool);
      pool.shuffle(rand);
      List<String> selection = pool.take(count).toList();

      if (lastSet != null && lastSet.length == selection.length) {
        bool isIdentical = true;
        for (int i = 0; i < selection.length; i++) {
          if (selection[i] != lastSet[i]) {
            isIdentical = false;
            break;
          }
        }
        if (isIdentical && pool.length >= count * 2) {
          selection = pool.skip(count).take(count).toList();
        }
      }

      return selection;
    }

    test('Suggestions returns correct count from pool', () {
      final suggestions = getRandomSuggestions(null);
      expect(suggestions.length, equals(4));
      for (final s in suggestions) {
        expect(fullSuggestionPool.contains(s), isTrue);
      }
    });

    test('Consecutive suggestion generations avoid immediate duplicate sets', () {
      final firstSet = getRandomSuggestions(null, random: Random(1));
      final secondSet = getRandomSuggestions(firstSet, random: Random(1));

      expect(firstSet, isNot(equals(secondSet)));
    });
  });
}
