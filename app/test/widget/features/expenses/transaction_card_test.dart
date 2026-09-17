import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/shared/widgets/transaction_card.dart';

void main() {
  final now = DateTime(2026, 9, 17, 16, 41); // 04:41 PM

  final category = Category(
    id: 'cat1',
    userId: 'u1',
    name: 'Shopping',
    type: 'expense',
    icon: 'shopping_bag',
    isSystemDefault: false,
    usageCount: 0,
    createdAt: now,
  );

  final subcategory = Category(
    id: 'sub1',
    userId: 'u1',
    name: 'Groceries',
    type: 'expense',
    icon: 'shopping_cart',
    isSystemDefault: false,
    usageCount: 0,
    createdAt: now,
  );

  final account = Account(
    id: 'acc1',
    userId: 'u1',
    name: 'HDFC Bank',
    type: 'savings',
    last4Digits: '3726',
    balance: 100000,
    isDefault: false,
    isEstimated: false,
    createdAt: now,
    updatedAt: now,
  );

  final paymentMethod = PaymentMethod(
    id: 'pm1',
    userId: 'u1',
    name: 'UPI',
    type: 'upi',
    usageCount: 0,
    createdAt: now,
  );

  testWidgets('SMS Transaction with Details displays SMS label and Payee', (WidgetTester tester) async {
    final tx = Transaction(
      id: 'tx1',
      userId: 'u1',
      amount: 5000, // ₹50.00
      type: 'expense',
      currency: 'INR',
      date: now,
      source: 'sms',
      createdAt: now,
      updatedAt: now,
      merchant: 'Saranya Sasikumar',
      isRecurring: false,
      syncStatus: 'pending',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: TransactionCard(
                  transaction: tx,
                  category: category,
                  subcategory: subcategory,
                  account: account,
                  paymentMethod: paymentMethod,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Line 1: SMS • Title and Amount
    expect(find.textContaining('SMS'), findsOneWidget);
    expect(find.textContaining('Saranya Sasikumar'), findsOneWidget);
    expect(find.text('-₹50.00'), findsOneWidget);

    // Line 2: Category > Subcategory
    expect(find.text('Shopping > Groceries'), findsOneWidget);

    // Line 3: Time • Account • Payment Method
    expect(find.text('04:41 PM • HDFC 3726 • via UPI'), findsOneWidget);
  });

  testWidgets('SMS Transaction without Details uses SMS Alert description', (WidgetTester tester) async {
    final tx = Transaction(
      id: 'tx2',
      userId: 'u1',
      amount: 5000,
      type: 'expense',
      currency: 'INR',
      date: now,
      source: 'sms',
      createdAt: now,
      updatedAt: now,
      description: 'SMS Alert: HDFC Savings Account debited',
      isRecurring: false,
      syncStatus: 'pending',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: TransactionCard(
                  transaction: tx,
                  category: category,
                  subcategory: subcategory,
                  account: account,
                  paymentMethod: paymentMethod,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('SMS'), findsOneWidget);
    expect(find.textContaining('SMS Alert: HDFC Savings Account debited'), findsOneWidget);
    expect(find.text('-₹50.00'), findsOneWidget);
  });

  testWidgets('SMS Transaction with subcategory fallback when details missing', (WidgetTester tester) async {
    final tx = Transaction(
      id: 'tx3',
      userId: 'u1',
      amount: 5000,
      type: 'expense',
      currency: 'INR',
      date: now,
      source: 'sms',
      createdAt: now,
      updatedAt: now,
      isRecurring: false,
      syncStatus: 'pending',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: TransactionCard(
                  transaction: tx,
                  category: category,
                  subcategory: subcategory,
                  account: account,
                  paymentMethod: paymentMethod,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('SMS'), findsOneWidget);
    expect(find.textContaining('Groceries'), findsWidgets);
  });

  testWidgets('Manual Transaction does NOT display SMS label', (WidgetTester tester) async {
    final tx = Transaction(
      id: 'tx4',
      userId: 'u1',
      amount: 5000,
      type: 'expense',
      currency: 'INR',
      date: now,
      source: 'manual',
      createdAt: now,
      updatedAt: now,
      merchant: 'Saranya Sasikumar',
      isRecurring: false,
      syncStatus: 'pending',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: TransactionCard(
                  transaction: tx,
                  category: category,
                  subcategory: subcategory,
                  account: account,
                  paymentMethod: paymentMethod,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('SMS •'), findsNothing);
    expect(find.text('Saranya Sasikumar'), findsOneWidget);
    expect(find.text('-₹50.00'), findsOneWidget);
  });
}
