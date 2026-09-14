import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/features/expenses/presentation/widgets/searchable_category_bottom_sheet.dart';
import 'package:app/features/expenses/presentation/providers/expense_provider.dart';

void main() {
  group('SearchableCategoryBottomSheet Promotion Widget Tests', () {
    final now = DateTime.now();

    final shoppingMainCategory = Category(
      id: 'cat_shopping',
      userId: 'user1',
      name: 'Shopping',
      type: 'expense',
      parentId: null,
      icon: 'shopping_bag',
      color: '0xFF0066FF',
      isSystemDefault: false,
      createdAt: now,
      usageCount: 10,
    );

    final flipkartSubcategory = Category(
      id: 'cat_flipkart',
      userId: 'user1',
      name: 'Flipkart',
      type: 'expense',
      parentId: 'cat_shopping',
      icon: 'store',
      color: '0xFF00E5FF',
      isSystemDefault: false,
      createdAt: now,
      usageCount: 5,
    );

    testWidgets('Subcategory management sheet displays Move to Main Categories and confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProvider.overrideWith(
              (ref) => [shoppingMainCategory, flipkartSubcategory],
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SearchableCategoryBottomSheet(
                transactionType: 'expense',
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on Shopping to open subcategories view
      expect(find.text('Shopping'), findsWidgets);
      await tester.tap(find.text('Shopping').last);
      await tester.pumpAndSettle();

      // Verify Flipkart is listed as subcategory
      expect(find.text('Flipkart'), findsOneWidget);

      // Long press Flipkart to open management bottom sheet
      await tester.longPress(find.text('Flipkart'));
      await tester.pumpAndSettle();

      // Verify management bottom sheet title and options
      expect(find.text('Manage "Flipkart"'), findsOneWidget);
      expect(find.text('Edit Details'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Move to Another Parent'), findsOneWidget);
      expect(find.text('Move to Main Categories'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Move to Main Categories
      await tester.tap(find.text('Move to Main Categories'));
      await tester.pumpAndSettle();

      // Verify exact Confirmation Dialog Title, Message, and Actions
      expect(find.text('Move "Flipkart" to Main Categories?'), findsOneWidget);
      expect(
        find.text('Flipkart will become a main category. Existing transactions will not be changed.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Move'), findsOneWidget);

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Move "Flipkart" to Main Categories?'), findsNothing);
    });
  });
}
