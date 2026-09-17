import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/shared/widgets/transaction_card.dart';

void main() {
  testWidgets('TransactionCard renders exact 3-line layout for expense', (WidgetTester tester) async {
    final now = DateTime(2026, 9, 17, 16, 41); // 04:41 PM
    final tx = Transaction(
      id: 'tx1',
      userId: 'u1',
      amount: 5000, // ₹50.00
      type: 'expense',
      currency: 'INR',
      date: now,
      source: 'manual',
      createdAt: now,
      updatedAt: now,
      description: 'Saranya Sasikumar',
      isRecurring: false,
      syncStatus: 'pending',
    );

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

    // Line 1: Title and Amount
    expect(find.text('Saranya Sasikumar'), findsOneWidget);
    expect(find.text('-₹50.00'), findsOneWidget);

    // Line 2: Main Category > Sub Category
    expect(find.text('Shopping > Groceries'), findsOneWidget);

    // Line 3: Time • Account • Payment Method
    expect(find.text('04:41 PM • HDFC 3726 • via UPI'), findsOneWidget);
  });

  testWidgets('TransactionCard renders income with cyan color and single category', (WidgetTester tester) async {
    final now = DateTime(2026, 9, 17, 10, 30);
    final tx = Transaction(
      id: 'tx2',
      userId: 'u1',
      amount: 150000, // ₹1,500.00
      type: 'income',
      currency: 'INR',
      date: now,
      source: 'manual',
      createdAt: now,
      updatedAt: now,
      description: 'Freelance Payout',
      isRecurring: false,
      syncStatus: 'pending',
    );

    final category = Category(
      id: 'cat2',
      userId: 'u1',
      name: 'Income',
      type: 'income',
      icon: 'work',
      isSystemDefault: false,
      usageCount: 0,
      createdAt: now,
    );

    final account = Account(
      id: 'acc2',
      userId: 'u1',
      name: 'SBI Bank',
      type: 'savings',
      last4Digits: '8589',
      balance: 500000,
      isDefault: false,
      isEstimated: false,
      createdAt: now,
      updatedAt: now,
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
                  account: account,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Freelance Payout'), findsOneWidget);
    expect(find.text('+₹1,500.00'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('10:30 AM • SBI 8589'), findsOneWidget);
  });
}
