import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/database/database_repair_service.dart';

void main() {
  late AppDatabase database;
  late DatabaseRepairService repairService;

  setUp(() {
    database = AppDatabase.connect(NativeDatabase.memory());
    repairService = DatabaseRepairService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('DatabaseRepairService detects and repairs database constraint violations', () async {
    // 1. Seed initial users/defaults (in-memory db onCreate seeds default categories)
    // Insert valid 'system' user so referenced categories/accounts can be inserted successfully
    await database.customStatement(
      'INSERT OR IGNORE INTO users (id, google_id, email, display_name, created_at, updated_at) '
      'VALUES ("system", "system_google_id", "system@test.com", "System User", "2026-07-25T00:00:00", "2026-07-25T00:00:00");'
    );
    
    // Let's verify default categories are created
    final initialCats = await database.customSelect('SELECT COUNT(*) FROM categories;').get();
    final initialCatsCount = initialCats.first.data.values.first as int;
    expect(initialCatsCount, greaterThan(0));

    // 2. Turn off foreign keys temporarily to insert corrupted/orphaned rows
    await database.customStatement('PRAGMA foreign_keys = OFF;');

    const String orphanAccountId = 'non-existent-account-id';
    const String orphanCategoryId = 'non-existent-category-id';
    const String invalidUserId = 'non-existent-user-id';

    // Insert an orphaned transaction referencing non-existent account and category
    final txId1 = const Uuid().v4();
    await database.customStatement(
      'INSERT INTO transactions (id, user_id, account_id, category_id, type, amount, currency, source, created_at, updated_at, date) '
      'VALUES (?, "system", ?, ?, "expense", 100, "USD", "test", "2026-07-25T00:00:00", "2026-07-25T00:00:00", "2026-07-25T00:00:00");',
      [txId1, orphanAccountId, orphanCategoryId],
    );

    // Insert an orphaned subcategory referencing non-existent parent category
    final catId1 = const Uuid().v4();
    await database.customStatement(
      'INSERT INTO categories (id, user_id, name, type, parent_id, is_system_default, created_at) '
      'VALUES (?, "system", "Orphan Subcat", "expense", ?, 0, "2026-07-25T00:00:00");',
      [catId1, orphanCategoryId],
    );

    // Insert an account referencing non-existent user
    final accId1 = const Uuid().v4();
    await database.customStatement(
      'INSERT INTO accounts (id, user_id, name, type, balance, is_default, created_at, updated_at, is_active, is_estimated) '
      'VALUES (?, ?, "Corrupted Account", "card", 500, 0, "2026-07-25T00:00:00", "2026-07-25T00:00:00", 1, 0);',
      [accId1, invalidUserId],
    );

    // Re-enable foreign keys
    await database.customStatement('PRAGMA foreign_keys = ON;');

    // 3. Verify health checker reports issues
    final initialHealth = await repairService.checkDatabaseHealth();
    expect(initialHealth['SQLite Integrity'], isTrue);
    expect(initialHealth['Foreign Keys'], isFalse);
    expect(initialHealth['Transactions'], isFalse);
    expect(initialHealth['Categories'], isFalse);
    expect(initialHealth['Credit Cards'], isFalse); // Corrupted Account has type "card" (Credit Cards)

    // 4. Run Repair
    final report = await repairService.runRepair(currentUserId: 'system');

    // 5. Verify Repair report outcomes
    expect(report.initialFkPass, isFalse);
    expect(report.violationsFound.length, equals(4)); // 2 from transactions (account & category), 1 from categories (parent), 1 from accounts (user_id)
    expect(report.actionsTaken, contains(contains('Created default Uncategorized category')));
    expect(report.actionsTaken, contains(contains('Created default Unknown Account')));
    expect(report.actionsTaken, contains(contains('Moved orphan transaction')));
    expect(report.actionsTaken, contains(contains('Reset missing parent_id to NULL')));
    expect(report.actionsTaken, contains(contains('Archived invalid account')));
    expect(report.finalFkPass, isTrue);

    // 6. Verify health checker reports PASS after repair
    final finalHealth = await repairService.checkDatabaseHealth();
    expect(finalHealth['SQLite Integrity'], isTrue);
    expect(finalHealth['Foreign Keys'], isTrue);
    expect(finalHealth['Transactions'], isTrue);
    expect(finalHealth['Categories'], isTrue);
    expect(finalHealth['Credit Cards'], isTrue);

    // 7. Verify data values are repaired correctly in DB
    final txRes = await database.customSelect(
      'SELECT account_id, category_id FROM transactions WHERE id = ?;',
      variables: [Variable<String>(txId1)],
    ).get();
    expect(txRes.first.read<String>('account_id'), equals('unknown_account_id'));
    expect(txRes.first.read<String>('category_id'), equals('uncategorized_category_id'));

    final catRes = await database.customSelect(
      'SELECT parent_id FROM categories WHERE id = ?;',
      variables: [Variable<String>(catId1)],
    ).get();
    expect(catRes.first.read<String?>('parent_id'), equals(null));

    final accRes = await database.customSelect(
      'SELECT is_active FROM accounts WHERE id = ?;',
      variables: [Variable<String>(accId1)],
    ).get();
    expect(accRes.first.read<int>('is_active'), equals(0)); // Archived!
  });

  test('DatabaseRepairService preserves active state when account is mapped to currentUserId', () async {
    // 1. Turn off foreign keys temporarily to insert corrupted/orphaned rows
    await database.customStatement('PRAGMA foreign_keys = OFF;');

    const String invalidUserId = 'non-existent-user-id';
    const String activeUserId = 'user-123';

    // Insert an account referencing non-existent user
    final accId1 = const Uuid().v4();
    await database.customStatement(
      'INSERT INTO accounts (id, user_id, name, type, balance, is_default, created_at, updated_at, is_active, is_estimated) '
      'VALUES (?, ?, "Test Account", "savings", 500, 0, "2026-07-25T00:00:00", "2026-07-25T00:00:00", 1, 0);',
      [accId1, invalidUserId],
    );

    // Re-enable foreign keys
    await database.customStatement('PRAGMA foreign_keys = ON;');

    // 2. Run Repair passing activeUserId
    final report = await repairService.runRepair(currentUserId: activeUserId);

    // 3. Verify it was repaired and remains active
    expect(report.finalFkPass, isTrue);

    final accRes = await database.customSelect(
      'SELECT user_id, is_active FROM accounts WHERE id = ?;',
      variables: [Variable<String>(accId1)],
    ).get();
    expect(accRes.first.read<String>('user_id'), equals(activeUserId));
    expect(accRes.first.read<int>('is_active'), equals(1)); // Should remain active!
  });
}
