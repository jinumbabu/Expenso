import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/expenses/presentation/widgets/amount_calculator_sheet.dart';

void main() {
  group('CalculatorEngine Unit Tests', () {
    test('1. 100 + 200 = 300', () {
      final res = CalculatorEngine.evaluate('100 + 200');
      expect(res.isValid, isTrue);
      expect(res.value, equals(300.0));
      expect(CalculatorEngine.formatDisplay(res.value!), equals('300'));
    });

    test('2. 1000 - 250 = 750', () {
      final res = CalculatorEngine.evaluate('1000 - 250');
      expect(res.isValid, isTrue);
      expect(res.value, equals(750.0));
      expect(CalculatorEngine.formatDisplay(res.value!), equals('750'));
    });

    test('3. 25 × 4 = 100', () {
      final res = CalculatorEngine.evaluate('25 × 4');
      expect(res.isValid, isTrue);
      expect(res.value, equals(100.0));
    });

    test('4. 1000 ÷ 4 = 250', () {
      final res = CalculatorEngine.evaluate('1000 ÷ 4');
      expect(res.isValid, isTrue);
      expect(res.value, equals(250.0));
    });

    test('5. 100.50 + 25.25 = 125.75', () {
      final res = CalculatorEngine.evaluate('100.50 + 25.25');
      expect(res.isValid, isTrue);
      expect(res.value, equals(125.75));
      expect(CalculatorEngine.formatDisplay(res.value!), equals('125.75'));
    });

    test('6. 100 ÷ 0 -> Cannot divide by zero error', () {
      final res = CalculatorEngine.evaluate('100 ÷ 0');
      expect(res.isValid, isFalse);
      expect(res.error, contains('Cannot divide by zero'));
    });

    test('Complex expression: 1250 + 350 + 99 = 1699', () {
      final res = CalculatorEngine.evaluate('1250 + 350 + 99');
      expect(res.isValid, isTrue);
      expect(res.value, equals(1699.0));
    });

    test('Operator precedence: 500 × 2 - 100 = 900', () {
      final res = CalculatorEngine.evaluate('500 × 2 - 100');
      expect(res.isValid, isTrue);
      expect(res.value, equals(900.0));
    });
  });

  group('AmountCalculatorSheet Widget & User Flow Tests', () {
    testWidgets('Renders calculator sheet with keypad and performs calculation flow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      double? returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedResult = await showModalBottomSheet<double?>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AmountCalculatorSheet(
                      initialAmountText: '500',
                    ),
                  );
                },
                child: const Text('Open Calculator'),
              ),
            ),
          ),
        ),
      );

      // 1. Open calculator sheet
      await tester.tap(find.text('Open Calculator'));
      await tester.pumpAndSettle();

      expect(find.text('Calculator'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Initial amount 500 is pre-loaded
      expect(find.text('500'), findsWidgets);

      // Tap + operator
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      // Tap 2
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      // Tap 5
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      // Tap 0
      await tester.tap(find.text('0').first);
      await tester.pumpAndSettle();

      // Tap =
      await tester.tap(find.text('='));
      await tester.pumpAndSettle();

      // Result should be 750 (500 + 250)
      expect(find.text('750'), findsWidgets);

      // Tap Done button
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Sheet closes and returns 750.0
      expect(returnedResult, equals(750.0));
    });

    testWidgets('Clear button resets state and Backspace removes last digit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmountCalculatorSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 1, 2, 3
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      expect(find.text('123'), findsWidgets);

      // Tap Backspace icon
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pumpAndSettle();

      expect(find.text('12'), findsWidgets);

      // Tap C (Clear)
      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);
    });
  });
}
