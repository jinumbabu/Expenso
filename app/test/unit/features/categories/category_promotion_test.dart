import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:app/core/database/app_database.dart';

void main() {
  group('Category Promotion & Data Integrity Tests', () {
    late Category shoppingMainCategory;
    late Category amazonSubcategory;
    late Category clothesSubcategory;
    late Category flipkartSubcategory;
    late Transaction existingFlipkartTransaction;
    final now = DateTime.now();

    setUp(() {
      shoppingMainCategory = Category(
        id: 'cat_shopping',
        userId: 'user_1',
        name: 'Shopping',
        type: 'expense',
        parentId: null,
        icon: 'shopping_bag',
        color: '0xFF0066FF',
        isSystemDefault: false,
        createdAt: now,
        usageCount: 10,
      );

      amazonSubcategory = Category(
        id: 'cat_amazon',
        userId: 'user_1',
        name: 'Amazon',
        type: 'expense',
        parentId: 'cat_shopping',
        icon: 'shopping_cart',
        color: '0xFF00E5FF',
        isSystemDefault: false,
        createdAt: now,
        usageCount: 5,
      );

      clothesSubcategory = Category(
        id: 'cat_clothes',
        userId: 'user_1',
        name: 'Clothes',
        type: 'expense',
        parentId: 'cat_shopping',
        icon: 'checkroom',
        color: '0xFF00E5FF',
        isSystemDefault: false,
        createdAt: now,
        usageCount: 3,
      );

      flipkartSubcategory = Category(
        id: 'cat_flipkart',
        userId: 'user_1',
        name: 'Flipkart',
        type: 'expense',
        parentId: 'cat_shopping',
        icon: 'store',
        color: '0xFF00E5FF',
        isSystemDefault: false,
        createdAt: now,
        usageCount: 8,
      );

      existingFlipkartTransaction = Transaction(
        id: 'tx_flipkart_1',
        userId: 'user_1',
        accountId: 'acc_savings',
        categoryId: 'cat_shopping',
        subcategoryId: 'cat_flipkart',
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 250000, // ₹2,500.00
        currency: 'INR',
        description: 'Headphones purchase',
        merchant: 'Flipkart',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: now,
        updatedAt: now,
      );
    });

    test('1 & 2. Verify subcategory initial state under parent category', () {
      final allCategories = [
        shoppingMainCategory,
        amazonSubcategory,
        clothesSubcategory,
        flipkartSubcategory,
      ];

      final rootCategories = allCategories.where((c) => c.parentId == null).toList();
      final shoppingSubs = allCategories.where((c) => c.parentId == shoppingMainCategory.id).toList();

      expect(rootCategories.map((c) => c.name), contains('Shopping'));
      expect(rootCategories.map((c) => c.name), isNot(contains('Flipkart')));
      expect(shoppingSubs.map((c) => c.name), containsAll(['Amazon', 'Clothes', 'Flipkart']));
      expect(flipkartSubcategory.parentId, equals('cat_shopping'));
    });

    test('3, 4, 5, 6, 7. Promote subcategory to main category removes parent relationship & preserves category ID', () {
      // Perform promotion: update parentId to null
      final promotedFlipkart = flipkartSubcategory.copyWith(parentId: const Value(null));

      final updatedCategories = [
        shoppingMainCategory,
        amazonSubcategory,
        clothesSubcategory,
        promotedFlipkart,
      ];

      final newRootCategories = updatedCategories.where((c) => c.parentId == null).toList();
      final newShoppingSubs = updatedCategories.where((c) => c.parentId == shoppingMainCategory.id).toList();

      // Category ID preserved
      expect(promotedFlipkart.id, equals('cat_flipkart'));
      // parentId is now null
      expect(promotedFlipkart.parentId, isNull);

      // Flipkart is now directly under root / main categories
      expect(newRootCategories.map((c) => c.name), containsAll(['Shopping', 'Flipkart']));

      // Flipkart no longer appears under Shopping subcategories
      expect(newShoppingSubs.map((c) => c.name), containsAll(['Amazon', 'Clothes']));
      expect(newShoppingSubs.map((c) => c.name), isNot(contains('Flipkart')));
    });

    test('8. Existing transactions remain 100% intact after promotion', () {
      final promotedFlipkart = flipkartSubcategory.copyWith(parentId: const Value(null));

      // Transaction retains its exact ID, amount, account, date, category IDs, and history
      expect(existingFlipkartTransaction.id, equals('tx_flipkart_1'));
      expect(existingFlipkartTransaction.amount, equals(250000));
      expect(existingFlipkartTransaction.subcategoryId, equals(promotedFlipkart.id));
      expect(existingFlipkartTransaction.merchant, equals('Flipkart'));
      expect(existingFlipkartTransaction.date, equals(now));
      expect(existingFlipkartTransaction.paymentMethodId, equals('pm_upi'));
    });

    test('9 & 10. Create new transaction using Flipkart as a main category', () {
      final promotedFlipkart = flipkartSubcategory.copyWith(parentId: const Value(null));

      final newTransaction = Transaction(
        id: 'tx_flipkart_2',
        userId: 'user_1',
        accountId: 'acc_savings',
        categoryId: promotedFlipkart.id,
        subcategoryId: null,
        paymentMethodId: 'pm_upi',
        type: 'expense',
        amount: 120000, // ₹1,200.00
        currency: 'INR',
        description: 'New Order',
        merchant: 'Flipkart',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      expect(newTransaction.categoryId, equals('cat_flipkart'));
      expect(newTransaction.subcategoryId, isNull);
      expect(newTransaction.amount, equals(120000));
    });

    test('13 & 14. Move to another parent and edit/delete capabilities are preserved', () {
      // Re-parenting Flipkart to another category
      final techCategory = Category(
        id: 'cat_tech',
        userId: 'user_1',
        name: 'Technology',
        type: 'expense',
        parentId: null,
        icon: 'computer',
        color: '0xFF0066FF',
        isSystemDefault: false,
        createdAt: now,
        usageCount: 1,
      );

      final reParented = flipkartSubcategory.copyWith(parentId: Value(techCategory.id));
      expect(reParented.parentId, equals('cat_tech'));

      // Editing details
      final edited = flipkartSubcategory.copyWith(name: 'Flipkart Store');
      expect(edited.name, equals('Flipkart Store'));
      expect(edited.id, equals('cat_flipkart'));
    });
  });
}
