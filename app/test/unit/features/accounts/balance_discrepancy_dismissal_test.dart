import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:uuid/uuid.dart';

import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/ledger_agent.dart';
import 'package:app/core/services/balance_engine.dart';

void main() {
  late AppDatabase database;
  late LedgerAgent ledgerAgent;
  const userId = 'user_discrepancy_test';

  setUp(() async {
    database = AppDatabase.connect(NativeDatabase.memory());
    ledgerAgent = LedgerAgent(database);

    // Seed test user
    await database.customStatement(
      'INSERT INTO users (id, google_id, email, display_name, created_at, updated_at) '
      'VALUES (?, ?, "discrepancy@test.com", "Discrepancy User", 1719532800, 1719532800);',
      [userId, userId],
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('Balance Discrepancy Flow & Persistent Dismissal Tests', () async {
    // Seed HDFC Account
    final hdfcAccount = Account(
      id: 'hdfc-savings',
      userId: userId,
      name: 'HDFC Account',
      type: 'savings',
      balance: 100000, // ₹1000.00
      isDefault: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      bankName: 'HDFC Bank',
      openingBalance: 100000,
      currency: 'INR',
      colorTheme: '0xFF0066FF',
      icon: 'account_balance',
      isActive: true,
      isEstimated: false,
    );

    // Seed SBI Account
    final sbiAccount = Account(
      id: 'sbi-savings',
      userId: userId,
      name: 'SBI Account',
      type: 'savings',
      balance: 100000, // ₹1000.00
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      bankName: 'SBI Bank',
      openingBalance: 100000,
      currency: 'INR',
      colorTheme: '0xFF00E5FF',
      icon: 'account_balance',
      isActive: true,
      isEstimated: false,
    );

    await database.into(database.accounts).insert(hdfcAccount);
    await database.into(database.accounts).insert(sbiAccount);

    // Create a transaction that causes discrepancy
    final t1 = Transaction(
      id: const Uuid().v4(),
      userId: userId,
      accountId: 'hdfc-savings',
      type: 'expense',
      amount: 10000, // ₹100
      currency: 'INR',
      description: 'Discrepancy Trigger',
      merchant: 'Zara',
      date: DateTime.now(),
      source: 'sms',
      isRecurring: false,
      syncStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Reconcile with an importedBalance that has a discrepancy of > ₹500
    // Expected balance after ₹100 expense is ₹900 (90000 cents).
    // Let's pass importedBalance of ₹300 (30000 cents), which creates discrepancy of ₹600.
    await ledgerAgent.reconcileTransaction(t1, importedBalance: 30000);

    // Test 1: Discrepancy detected -> check hasMismatch field (Card appears in UI)
    var updatedHdfc = await (database.select(database.accounts)..where((a) => a.id.equals('hdfc-savings'))).getSingle();
    expect(updatedHdfc.hasMismatch, isTrue);
    expect(updatedHdfc.mismatchExpected, equals(90000));
    expect(updatedHdfc.mismatchImported, equals(30000));
    expect(updatedHdfc.balanceDiscrepancyDismissed, isNot(isTrue));

    // Test 10: Count current transactions on HDFC
    final countBefore = await (database.select(database.transactions)..where((t) => t.accountId.equals('hdfc-savings') & t.deletedAt.isNull())).get();
    
    // Test 2: Tap Accept SMS Balance -> SMS balance becomes account balance.
    await ledgerAgent.acceptImportedBalance('hdfc-savings');
    updatedHdfc = await (database.select(database.accounts)..where((a) => a.id.equals('hdfc-savings'))).getSingle();
    
    expect(updatedHdfc.verifiedBalance, equals(30000));
    expect(updatedHdfc.hasMismatch, isFalse);
    expect(updatedHdfc.mismatchExpected, isNull);
    expect(updatedHdfc.mismatchImported, isNull);

    // Test 3: Tap Accept SMS Balance -> no adjustment transaction is created.
    // Test 10: Accept SMS Balance -> transaction history remains unchanged.
    final countAfterAccept = await (database.select(database.transactions)..where((t) => t.accountId.equals('hdfc-savings') & t.deletedAt.isNull())).get();
    expect(countAfterAccept.length, equals(countBefore.length));

    // Reset mismatch state on HDFC to test Cancel behavior
    await database.accountDao.updateAccount(updatedHdfc.copyWith(
      balance: 90000,
      verifiedBalance: const Value(null),
      hasMismatch: const Value(true),
      mismatchExpected: const Value(90000),
      mismatchImported: const Value(30000),
    ));

    final expectedHdfcBalance = 90000;

    // Test 4: Tap Cancel -> current account balance remains unchanged.
    // Test 5: Tap Cancel -> discrepancy card/warning flags disappear.
    await ledgerAgent.dismissDiscrepancy('hdfc-savings');

    updatedHdfc = await (database.select(database.accounts)..where((a) => a.id.equals('hdfc-savings'))).getSingle();
    expect(updatedHdfc.balance, equals(expectedHdfcBalance));
    expect(updatedHdfc.hasMismatch, isFalse);
    expect(updatedHdfc.balanceDiscrepancyDismissed, isTrue);

    // Test 8: Cancel HDFC discrepancy -> SBI discrepancy detection still works.
    // Let's trigger a discrepancy on SBI
    final t2 = Transaction(
      id: const Uuid().v4(),
      userId: userId,
      accountId: 'sbi-savings',
      type: 'expense',
      amount: 10000, // ₹100
      currency: 'INR',
      description: 'SBI Trigger',
      merchant: 'Starbucks',
      date: DateTime.now(),
      source: 'sms',
      isRecurring: false,
      syncStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ledgerAgent.reconcileTransaction(t2, importedBalance: 30000);

    final updatedSbi = await (database.select(database.accounts)..where((a) => a.id.equals('sbi-savings'))).getSingle();
    expect(updatedSbi.hasMismatch, isTrue);
    expect(updatedSbi.balanceDiscrepancyDismissed, isNot(isTrue));

    // Test 9: Cancel discrepancy -> SMS importing continues normally.
    // Let's import a new SMS transaction for HDFC and verify it succeeds
    final t3 = Transaction(
      id: const Uuid().v4(),
      userId: userId,
      accountId: 'hdfc-savings',
      type: 'expense',
      amount: 5000, // ₹50
      currency: 'INR',
      description: 'HDFC New Expense',
      merchant: 'Uber',
      date: DateTime.now(),
      source: 'sms',
      isRecurring: false,
      syncStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    // Even with a new balance mismatch in the SMS, HDFC should NOT set hasMismatch = true
    await ledgerAgent.reconcileTransaction(t3, importedBalance: 10000);

    updatedHdfc = await (database.select(database.accounts)..where((a) => a.id.equals('hdfc-savings'))).getSingle();
    expect(updatedHdfc.hasMismatch, isFalse); // warning suppressed!
    
    // Verify the transaction was successfully imported
    final t3Fetched = await (database.select(database.transactions)..where((t) => t.id.equals(t3.id))).getSingleOrNull();
    expect(t3Fetched, isNotNull);
  });
}
