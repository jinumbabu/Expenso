import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app/firebase_options.dart';

import 'package:app/core/database/app_database.dart';
import 'package:app/core/sync/backup_service.dart';
import 'package:app/features/backup/presentation/providers/backup_provider.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';

Future<void> seedTestData(AppDatabase db, String userId) async {
  await db.clearAllData();
  final now = DateTime.now();

  // Seed User first
  await db.into(db.users).insert(User(
    id: userId,
    googleId: userId,
    email: '$userId@expenso.ai',
    displayName: 'E2E User',
    currency: 'INR',
    createdAt: now,
    updatedAt: now,
  ));

  final List<Account> accountsToInsert = [];
  
  // 5 Bank accounts
  for (int i = 1; i <= 5; i++) {
    accountsToInsert.add(Account(
      id: 'bank-acc-$i',
      userId: userId,
      name: 'Bank Account $i',
      type: 'bank',
      balance: 1000000,
      isDefault: false,
      isEstimated: false,
      bankName: 'Test Bank $i',
      openingBalance: 1000000,
      verifiedBalance: 1000000,
      calculatedBalance: 1000000,
      currency: 'INR',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ));
  }

  // 2 Credit Cards
  for (int i = 1; i <= 2; i++) {
    accountsToInsert.add(Account(
      id: 'cc-acc-$i',
      userId: userId,
      name: 'Credit Card $i',
      type: 'card',
      balance: 0,
      isDefault: false,
      isEstimated: false,
      bankName: 'Credit Provider $i',
      openingBalance: 0,
      verifiedBalance: 0,
      calculatedBalance: 0,
      creditLimit: 5000000,
      availableCredit: 5000000,
      outstandingBalance: 0,
      currency: 'INR',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ));
  }

  // 1 Wallet
  accountsToInsert.add(Account(
    id: 'wallet-acc',
    userId: userId,
    name: 'Cash Wallet',
    type: 'cash',
    balance: 500000,
    isDefault: false,
    isEstimated: false,
    openingBalance: 500000,
    verifiedBalance: 500000,
    calculatedBalance: 500000,
    currency: 'INR',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  ));

  for (var acc in accountsToInsert) {
    await db.into(db.accounts).insert(acc);
  }

  // Seed default Category
  const catId = 'cat-test-default';
  await db.into(db.categories).insert(Category(
    id: catId,
    userId: userId,
    name: 'Food',
    type: 'expense',
    icon: 'fastfood',
    usageCount: 0,
    isSystemDefault: true,
    createdAt: now,
  ));

  // Seed 100 Transactions
  for (int i = 1; i <= 100; i++) {
    final accIndex = i % accountsToInsert.length;
    final account = accountsToInsert[accIndex];
    final isExpense = i % 3 != 0;
    
    await db.into(db.transactions).insert(Transaction(
      id: 'tx-$i',
      userId: userId,
      accountId: account.id,
      type: isExpense ? 'expense' : 'income',
      amount: i * 10000, // i * 100 INR
      currency: 'INR',
      merchant: 'Merchant $i',
      description: 'Transaction Description $i',
      categoryId: catId,
      date: now.subtract(Duration(hours: i)),
      source: 'manual',
      isRecurring: false,
      syncStatus: 'pending',
      createdAt: now,
      updatedAt: now,
    ));
  }

  // Seed Budgets
  for (int i = 1; i <= 3; i++) {
    await db.into(db.budgets).insert(Budget(
      id: 'budget-$i',
      userId: userId,
      categoryId: catId,
      period: 'monthly',
      amount: 2000000,
      startDate: now.subtract(const Duration(days: 10)),
      endDate: now.add(const Duration(days: 20)),
      createdAt: now,
      updatedAt: now,
    ));
  }

  // Seed Goals
  for (int i = 1; i <= 2; i++) {
    await db.into(db.goals).insert(Goal(
      id: 'goal-$i',
      userId: userId,
      title: 'Goal $i',
      targetAmount: 10000000,
      currentAmount: 1000000,
      targetDate: now.add(const Duration(days: 60)),
      createdAt: now,
      updatedAt: now,
    ));
  }
}

Future<void> seedLargeTestData(AppDatabase db, String userId) async {
  await db.clearAllData();
  final now = DateTime.now();

  // Seed User first
  await db.into(db.users).insert(User(
    id: userId,
    googleId: userId,
    email: '$userId@expenso.ai',
    displayName: 'E2E User',
    currency: 'INR',
    createdAt: now,
    updatedAt: now,
  ));

  // 1. Seed 20 Accounts
  for (int i = 1; i <= 20; i++) {
    await db.into(db.accounts).insert(Account(
      id: 'large-acc-$i',
      userId: userId,
      name: 'Large Account $i',
      type: i % 2 == 0 ? 'bank' : 'card',
      balance: 5000000,
      isDefault: false,
      isEstimated: false,
      bankName: 'Large Bank $i',
      openingBalance: 5000000,
      verifiedBalance: 5000000,
      calculatedBalance: 5000000,
      currency: 'INR',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ));
  }

  const catId = 'cat-test-default';
  await db.into(db.categories).insert(Category(
    id: catId,
    userId: userId,
    name: 'Food',
    type: 'expense',
    icon: 'fastfood',
    usageCount: 0,
    isSystemDefault: true,
    createdAt: now,
  ));

  // 2. Seed 10,000 Transactions in batches
  final List<Transaction> batch = [];
  for (int i = 1; i <= 10000; i++) {
    final accId = 'large-acc-${(i % 20) + 1}';
    batch.add(Transaction(
      id: 'large-tx-$i',
      userId: userId,
      accountId: accId,
      type: i % 4 == 0 ? 'income' : 'expense',
      amount: (i % 50) * 10000,
      currency: 'INR',
      merchant: 'Large Merchant $i',
      description: 'Large Tx Description $i',
      categoryId: catId,
      date: now.subtract(Duration(minutes: i)),
      source: 'manual',
      isRecurring: false,
      syncStatus: 'pending',
      createdAt: now,
      updatedAt: now,
    ));

    if (batch.length >= 1000) {
      await db.batch((b) {
        b.insertAll(db.transactions, batch);
      });
      batch.clear();
    }
  }
  if (batch.isNotEmpty) {
    await db.batch((b) {
      b.insertAll(db.transactions, batch);
    });
  }

  // Budgets
  for (int i = 1; i <= 10; i++) {
    await db.into(db.budgets).insert(Budget(
      id: 'large-budget-$i',
      userId: userId,
      categoryId: catId,
      period: 'monthly',
      amount: 50000000,
      startDate: now.subtract(const Duration(days: 15)),
      endDate: now.add(const Duration(days: 15)),
      createdAt: now,
      updatedAt: now,
    ));
  }

  // Goals
  for (int i = 1; i <= 5; i++) {
    await db.into(db.goals).insert(Goal(
      id: 'large-goal-$i',
      userId: userId,
      title: 'Large Goal $i',
      targetAmount: 500000000,
      currentAmount: 50000000,
      targetDate: now.add(const Duration(days: 90)),
      createdAt: now,
      updatedAt: now,
    ));
  }
}

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  group('Google Drive Backup & Restore E2E Integration Tests', () {
    testWidgets('Verify complete E2E backup and restore pipeline', (tester) async {
      final container = ProviderContainer();
      
      // Force user login with a mock- googleId to run in simulated mockMode
      final String testUserId = 'mock-e2e-user';
      print('[E2E Test] Logging in user session offline with mock-e2e-user...');
      await container.read(authProvider.notifier).loginOffline(
        email: 'test-e2e-user@expenso.ai',
        displayName: 'E2E User',
        googleId: testUserId,
      );

      final db = container.read(databaseProvider);
      final backupService = container.read(backupServiceProvider);

      print('[E2E Test] Starting backup & restore pipeline validation...');

      // ==========================================
      // Scenario 1: First Backup Seeding
      // ==========================================
      print('[E2E Test] Seeding first database state...');
      await seedTestData(db, testUserId);

      // Verify original stats
      final origAccounts = await db.select(db.accounts).get();
      final origTxs = await db.select(db.transactions).get();
      final origBudgets = await db.select(db.budgets).get();
      final origGoals = await db.select(db.goals).get();
      final origCategories = await db.select(db.categories).get();

      expect(origAccounts.length, equals(8));
      expect(origTxs.length, equals(100));
      expect(origBudgets.length, equals(3));
      expect(origGoals.length, equals(2));

      // Calculate original net worth
      int origNetWorth = 0;
      for (var acc in origAccounts) {
        origNetWorth += acc.balance;
      }
      for (var tx in origTxs) {
        if (tx.type == 'income') {
          origNetWorth += tx.amount;
        } else if (tx.type == 'expense') {
          origNetWorth -= tx.amount;
        }
      }
      print('[E2E Test] Original Net Worth calculated: $origNetWorth paise');

      // ==========================================
      // Scenario 2: Perform Backup
      // ==========================================
      print('[E2E Test] Creating backup...');
      final int size = await backupService.backup(testUserId);
      expect(size, greaterThan(0));
      print('[E2E Test] Backup created successfully. Size: $size bytes');

      // ==========================================
      // Scenario 3: Clear Database (Simulate New Install / New Device)
      // ==========================================
      print('[E2E Test] Clearing app database to simulate clear data state...');
      await db.clearAllData();

      final emptyAccounts = await db.select(db.accounts).get();
      final emptyTxs = await db.select(db.transactions).get();
      expect(emptyAccounts.isEmpty, isTrue);
      expect(emptyTxs.isEmpty, isTrue);

      // ==========================================
      // Scenario 4: Restore Backup
      // ==========================================
      print('[E2E Test] Restoring backup...');
      await backupService.restore(testUserId);
      print('[E2E Test] Restore complete!');

      // ==========================================
      // Scenario 5: Verification after Restore
      // ==========================================
      // Note: restore closes the previous connection and invalidates the databaseProvider.
      // We must read a fresh reference from the container.
      final restoredDb = container.read(databaseProvider);

      final resAccounts = await restoredDb.select(restoredDb.accounts).get();
      final resTxs = await restoredDb.select(restoredDb.transactions).get();
      final resBudgets = await restoredDb.select(restoredDb.budgets).get();
      final resGoals = await restoredDb.select(restoredDb.goals).get();
      final resCategories = await restoredDb.select(restoredDb.categories).get();

      print('[E2E Test] Verifying database integrity assertions...');
      expect(resAccounts.length, equals(origAccounts.length));
      expect(resTxs.length, equals(origTxs.length));
      expect(resBudgets.length, equals(origBudgets.length));
      expect(resGoals.length, equals(origGoals.length));
      expect(resCategories.length, equals(origCategories.length));

      // Verify no orphan transactions (every transaction references a valid account)
      final accountIds = resAccounts.map((a) => a.id).toSet();
      for (var tx in resTxs) {
        expect(accountIds.contains(tx.accountId), isTrue);
      }

      // Calculate restored net worth
      int resNetWorth = 0;
      for (var acc in resAccounts) {
        resNetWorth += acc.balance;
      }
      for (var tx in resTxs) {
        if (tx.type == 'income') {
          resNetWorth += tx.amount;
        } else if (tx.type == 'expense') {
          resNetWorth -= tx.amount;
        }
      }
      expect(resNetWorth, equals(origNetWorth));
      print('[E2E Test] Restored Net Worth matches original net worth: $resNetWorth paise');

      // ==========================================
      // Scenario 6: Large Database Test (20 Accounts, 10,000 Transactions)
      // ==========================================
      print('[E2E Test] Seeding large database state (20 accounts, 10,000 transactions)...');
      await seedLargeTestData(restoredDb, testUserId);

      final largeOrigAccounts = await restoredDb.select(restoredDb.accounts).get();
      final largeOrigTxs = await restoredDb.select(restoredDb.transactions).get();
      final largeOrigBudgets = await restoredDb.select(restoredDb.budgets).get();
      final largeOrigGoals = await restoredDb.select(restoredDb.goals).get();

      expect(largeOrigAccounts.length, equals(20));
      expect(largeOrigTxs.length, equals(10000));
      expect(largeOrigBudgets.length, equals(10));
      expect(largeOrigGoals.length, equals(5));

      print('[E2E Test] Creating large database backup...');
      final int largeSize = await backupService.backup(testUserId);
      expect(largeSize, greaterThan(0));
      print('[E2E Test] Large database backup created successfully. Size: $largeSize bytes');

      print('[E2E Test] Clearing database...');
      await restoredDb.clearAllData();

      print('[E2E Test] Restoring large database backup...');
      await backupService.restore(testUserId);
      print('[E2E Test] Large database restore complete!');

      // Read a fresh reference after the second restore
      final restoredDbLarge = container.read(databaseProvider);
      final largeResAccounts = await restoredDbLarge.select(restoredDbLarge.accounts).get();
      final largeResTxs = await restoredDbLarge.select(restoredDbLarge.transactions).get();
      
      expect(largeResAccounts.length, equals(20));
      expect(largeResTxs.length, equals(10000));
      print('[E2E Test] Large database assertions passed successfully!');

      print('[E2E Test] E2E Pipeline Validation Completed Successfully!');
    });
  });
}
