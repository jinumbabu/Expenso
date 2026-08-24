import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/budget_period_helper.dart';

void main() {
  group('getBudgetPeriodRange tests', () {
    final now = DateTime(2026, 8, 24, 12, 0, 0); // Monday

    test('daily budget period range', () {
      final budget = Budget(
        id: '1',
        userId: 'user-1',
        period: 'daily',
        amount: 1000,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final range = getBudgetPeriodRange(budget, now);
      expect(range.start, equals(DateTime(2026, 8, 24)));
      expect(range.end, equals(DateTime(2026, 8, 24, 23, 59, 59, 999)));
    });

    test('weekly budget period range', () {
      final budget = Budget(
        id: '2',
        userId: 'user-1',
        period: 'weekly',
        amount: 5000,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final range = getBudgetPeriodRange(budget, now);
      // Aug 24 is Monday
      expect(range.start, equals(DateTime(2026, 8, 24)));
      expect(range.end, equals(DateTime(2026, 8, 30, 23, 59, 59, 999)));
    });

    test('monthly budget period range', () {
      final budget = Budget(
        id: '3',
        userId: 'user-1',
        period: 'monthly',
        amount: 20000,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final range = getBudgetPeriodRange(budget, now);
      expect(range.start, equals(DateTime(2026, 8, 1)));
      expect(range.end, equals(DateTime(2026, 9, 1).subtract(const Duration(milliseconds: 1))));
    });

    test('yearly budget period range', () {
      final budget = Budget(
        id: '4',
        userId: 'user-1',
        period: 'yearly',
        amount: 240000,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final range = getBudgetPeriodRange(budget, now);
      expect(range.start, equals(DateTime(2026, 1, 1)));
      expect(range.end, equals(DateTime(2026, 12, 31, 23, 59, 59, 999)));
    });
  });
}
