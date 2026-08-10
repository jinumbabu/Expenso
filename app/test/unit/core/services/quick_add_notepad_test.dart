import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/quick_add_notepad_service.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';

class FakeDatabase extends Fake implements AppDatabase {}

void main() {
  group('Smart Quick Add Notepad Service Tests', () {
    late ProviderContainer container;
    late QuickAddNotepadService service;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(FakeDatabase()),
        ],
      );
      service = container.read(quickAddNotepadServiceProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('parseLine parses standard expense: Food 250', () {
      final result = service.parseLine('Food 250');
      expect(result.error, isNull);
      expect(result.amount, equals(250.0));
      expect(result.type, equals('expense'));
      expect(result.category, equals('Food'));
      expect(result.merchant, equals('Food'));
    });

    test('parseLine parses expense with "using" clause: Amazon 1200 using ICICI Credit Card', () {
      final result = service.parseLine('Amazon 1200 using ICICI Credit Card');
      expect(result.error, isNull);
      expect(result.amount, equals(1200.0));
      expect(result.type, equals('expense'));
      expect(result.category, equals('Shopping'));
      expect(result.merchant, equals('Amazon'));
      expect(result.accountName, equals('ICICI Credit Card'));
      expect(result.accountType, equals('credit_card'));
    });

    test('parseLine parses credit card statement: ICICI Statement Rs 1707 Due 08-Jul', () {
      final result = service.parseLine('ICICI Statement Rs 1707 Due 08-Jul');
      expect(result.error, isNull);
      expect(result.amount, equals(1707.0));
      expect(result.type, equals('upcoming_bill'));
      expect(result.merchant, equals('ICICI Statement'));
      expect(result.category, equals('Utilities'));
      expect(result.dueDate, isNotNull);
      expect(result.dueDate!.month, equals(7));
      expect(result.dueDate!.day, equals(8));
    });

    test('parseLine parses credit card payment: Credit Card Payment 5000', () {
      final result = service.parseLine('Credit Card Payment 5000');
      expect(result.error, isNull);
      expect(result.amount, equals(5000.0));
      expect(result.type, equals('credit_card_payment'));
      expect(result.merchant, equals('Credit Card Payment'));
      expect(result.category, equals('Transfer'));
    });

    test('parseLine parses internal transfer: Transfer to SBI 3000', () {
      final result = service.parseLine('Transfer to SBI 3000');
      expect(result.error, isNull);
      expect(result.amount, equals(3000.0));
      expect(result.type, equals('transfer'));
      expect(result.merchant, equals('SBI'));
      expect(result.accountName, equals('Bank Account'));
    });

    test('parseLine parses subcategory for Amazon: Amazon 1200', () {
      final result = service.parseLine('Amazon 1200');
      expect(result.error, isNull);
      expect(result.category, equals('Shopping'));
      expect(result.subcategory, equals('Amazon'));
    });

    test('parseLine parses subcategory for Electricity Bill: Paid EB bill 1200', () {
      final result = service.parseLine('Paid EB bill 1200');
      expect(result.error, isNull);
      expect(result.category, equals('Utilities'));
      expect(result.subcategory, equals('Electricity Bill'));
    });

    test('parseLine parses subcategory for Pizza Hut: Pizza Hut 650', () {
      final result = service.parseLine('Pizza Hut 650');
      expect(result.error, isNull);
      expect(result.category, equals('Food'));
      expect(result.subcategory, equals('Restaurant'));
    });

    test('parseLine rejects line with invalid amount', () {
      final result = service.parseLine('Lunch at office');
      expect(result.error, equals('Invalid amount'));
      expect(result.amount, isNull);
    });
  });
}
