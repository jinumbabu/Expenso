import 'package:flutter/material.dart';
import '../database/app_database.dart';

DateTimeRange getBudgetPeriodRange(Budget budget, DateTime now) {
  final period = budget.period.toLowerCase();
  DateTime start;
  DateTime end;

  switch (period) {
    case 'daily':
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      break;
    case 'weekly':
      // Start of week (Monday)
      final daysToSubtract = now.weekday - 1;
      start = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
      end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
      break;
    case 'yearly':
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
      break;
    case 'monthly':
    default:
      start = DateTime(now.year, now.month, 1);
      // Last day of month
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      end = nextMonth.subtract(const Duration(milliseconds: 1));
      break;
  }
  return DateTimeRange(start: start, end: end);
}
