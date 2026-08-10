import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class DatabaseRepairReport {
  final bool initialIntegrityPass;
  final bool initialFkPass;
  final List<String> violationsFound;
  final List<String> actionsTaken;
  final int bytesSaved;
  final bool finalIntegrityPass;
  final bool finalFkPass;

  DatabaseRepairReport({
    required this.initialIntegrityPass,
    required this.initialFkPass,
    required this.violationsFound,
    required this.actionsTaken,
    required this.bytesSaved,
    required this.finalIntegrityPass,
    required this.finalFkPass,
  });

  Map<String, dynamic> toJson() {
    return {
      'initialIntegrityPass': initialIntegrityPass,
      'initialFkPass': initialFkPass,
      'violationsFound': violationsFound,
      'actionsTaken': actionsTaken,
      'bytesSaved': bytesSaved,
      'finalIntegrityPass': finalIntegrityPass,
      'finalFkPass': finalFkPass,
    };
  }

  @override
  String toString() {
    return 'Database Repair Report:\n'
        '- Initial Integrity Check: ${initialIntegrityPass ? "PASS" : "FAIL"}\n'
        '- Initial Foreign Key Check: ${initialFkPass ? "PASS" : "FAIL"}\n'
        '- Violations Detected: ${violationsFound.length}\n'
        '${violationsFound.map((v) => '  • $v').join('\n')}\n'
        '- Actions Performed: ${actionsTaken.length}\n'
        '${actionsTaken.map((a) => '  • $a').join('\n')}\n'
        '- Space Recovered: $bytesSaved bytes\n'
        '- Final Integrity Check: ${finalIntegrityPass ? "PASS" : "FAIL"}\n'
        '- Final Foreign Key Check: ${finalFkPass ? "PASS" : "FAIL"}\n';
  }
}

class DatabaseRepairService {
  final AppDatabase _db;

  DatabaseRepairService(this._db);

  Future<File?> _getDatabaseFile() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file1 = File(p.join(docDir.path, 'expenso_database.sqlite'));
      if (await file1.exists()) return file1;

      final supportDir = await getApplicationSupportDirectory();
      final file2 = File(p.join(supportDir.path, 'expenso_database.sqlite'));
      if (await file2.exists()) return file2;

      final file3 = File(p.join(docDir.path, 'expenso_database'));
      if (await file3.exists()) return file3;

      final file4 = File(p.join(supportDir.path, 'expenso_database'));
      if (await file4.exists()) return file4;

      return file2;
    } catch (_) {}
    return null;
  }

  Future<DatabaseRepairReport> runRepair({String? currentUserId}) async {
    final actionsTaken = <String>[];
    final violationsFound = <String>[];

    debugPrint('DatabaseRepairService: Starting repair engine...');

    // 1. Initial Checks
    bool initialIntegrityPass = false;
    try {
      final integrityRows = await _db.customSelect('PRAGMA integrity_check;').get();
      initialIntegrityPass = integrityRows.isNotEmpty && integrityRows.first.data.values.first == 'ok';
    } catch (e) {
      violationsFound.add('Initial integrity check exception: $e');
    }

    final initialFkRows = await _db.customSelect('PRAGMA foreign_key_check;').get();
    final bool initialFkPass = initialFkRows.isEmpty;

    for (var row in initialFkRows) {
      final childTable = row.read<String>('table');
      final rowId = row.read<int>('rowid');
      final parentTable = row.read<String>('parent');
      final fkid = row.read<int>('fkid');

      String fromCol = 'Unknown';
      String missingVal = 'Unknown';
      try {
        final fkList = await _db.customSelect('PRAGMA foreign_key_list($childTable);').get();
        final match = fkList.firstWhere((item) => item.read<int>('id') == fkid);
        fromCol = match.read<String>('from');

        final childRow = await _db.customSelect('SELECT $fromCol FROM $childTable WHERE rowid = ?;', variables: [Variable<int>(rowId)]).get();
        if (childRow.isNotEmpty) {
          missingVal = childRow.first.data.values.first?.toString() ?? 'null';
        }
      } catch (_) {}

      violationsFound.add('FK Violation in $childTable (rowid: $rowId) referencing parent $parentTable: missing key $fromCol = $missingVal');
    }

    // 2. Perform Repairs inside a Transaction
    await _db.transaction(() async {
      await _db.customStatement('PRAGMA foreign_keys = OFF;');

      final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Ensure 'system' user exists in the users table
      final systemUserRes = await _db.customSelect(
        'SELECT id FROM users WHERE id = "system" LIMIT 1;'
      ).get();
      if (systemUserRes.isEmpty) {
        await _db.customStatement(
          'INSERT INTO users (id, google_id, email, display_name, created_at, updated_at) '
          'VALUES ("system", "system_google_id", "system@test.com", "System User", ?, ?);',
          [nowSecs, nowSecs],
        );
        actionsTaken.add('Created default system user');
      }

      // Ensure current logged in user exists in the users table
      if (currentUserId != null && currentUserId != 'system') {
        final currentUserRes = await _db.customSelect(
          'SELECT id FROM users WHERE id = ? LIMIT 1;',
          variables: [Variable<String>(currentUserId)],
        ).get();
        if (currentUserRes.isEmpty) {
          await _db.customStatement(
            'INSERT INTO users (id, google_id, email, display_name, created_at, updated_at) '
            'VALUES (?, ?, "user@test.com", "Active User", ?, ?);',
            [currentUserId, currentUserId, nowSecs, nowSecs],
          );
          actionsTaken.add('Created missing active user: $currentUserId');
        }
      }

      // A. Recreate missing default categories
      final defaultCategories = [
        {'name': 'Food', 'type': 'expense', 'icon': 'fastfood', 'color': '0xFFFFA500'},
        {'name': 'Travel', 'type': 'expense', 'icon': 'flight', 'color': '0xFF0066FF'},
        {'name': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag', 'color': '0xFF8A2BE2'},
        {'name': 'Utilities', 'type': 'expense', 'icon': 'receipt_long', 'color': '0xFFFFB703'},
        {'name': 'Entertainment', 'type': 'expense', 'icon': 'movie', 'color': '0xFFFF3B30'},
        {'name': 'Salary', 'type': 'income', 'icon': 'payments', 'color': '0xFF00FF88'},
        {'name': 'Freelance', 'type': 'income', 'icon': 'work', 'color': '0xFF00FF88'},
        {'name': 'Investment', 'type': 'expense', 'icon': 'trending_up', 'color': '0xFF00E5FF'},
        {'name': 'Transfer', 'type': 'transfer', 'icon': 'swap_horiz', 'color': '0xFF6366F1'},
      ];

      for (var cat in defaultCategories) {
        final existing = await _db.customSelect(
          'SELECT id FROM categories WHERE name = ? AND is_system_default = 1 LIMIT 1;',
          variables: [Variable<String>(cat['name'] as String)],
        ).get();
        if (existing.isEmpty) {
          final newId = const Uuid().v4();
          await _db.customStatement(
            'INSERT INTO categories (id, user_id, name, type, icon, color, is_system_default, created_at) '
            'VALUES (?, "system", ?, ?, ?, ?, 1, ?);',
            [newId, cat['name'], cat['type'], cat['icon'], cat['color'], nowSecs],
          );
          actionsTaken.add('Recreated missing system default category: ${cat['name']}');
        }
      }

      // Ensure "Uncategorized" category exists
      final uncategorizedRes = await _db.customSelect(
        'SELECT id FROM categories WHERE name = "Uncategorized" LIMIT 1;'
      ).get();
      final String uncategorizedId;
      if (uncategorizedRes.isEmpty) {
        uncategorizedId = 'uncategorized_category_id';
        await _db.customStatement(
          'INSERT INTO categories (id, user_id, name, type, icon, color, is_system_default, created_at) '
          'VALUES (?, "system", "Uncategorized", "expense", "help_outline", "0xFF9E9E9E", 1, ?);',
          [uncategorizedId, nowSecs],
        );
        actionsTaken.add('Created default Uncategorized category');
      } else {
        uncategorizedId = uncategorizedRes.first.read<String>('id');
      }

      // Ensure "Unknown Account" exists
      final unknownAccountRes = await _db.customSelect(
        'SELECT id FROM accounts WHERE name = "Unknown Account" LIMIT 1;'
      ).get();
      final String unknownAccountId;
      if (unknownAccountRes.isEmpty) {
        unknownAccountId = 'unknown_account_id';
        await _db.customStatement(
          'INSERT INTO accounts (id, user_id, name, type, balance, is_default, created_at, updated_at, is_active, is_estimated) '
          'VALUES (?, "system", "Unknown Account", "cash", 0, 0, ?, ?, 0, 0);',
          [unknownAccountId, nowSecs, nowSecs],
        );
        actionsTaken.add('Created default Unknown Account');
      } else {
        unknownAccountId = unknownAccountRes.first.read<String>('id');
      }

      // B. Loop to resolve any foreign key check violations dynamically (up to 3 passes)
      for (int attempt = 1; attempt <= 3; attempt++) {
        final fkRows = await _db.customSelect('PRAGMA foreign_key_check;').get();
        if (fkRows.isEmpty) break;

        for (var row in fkRows) {
          final childTable = row.read<String>('table');
          final rowId = row.read<int>('rowid');
          final parentTable = row.read<String>('parent');
          final fkid = row.read<int>('fkid');

          String fromCol = '';
          try {
            final fkList = await _db.customSelect('PRAGMA foreign_key_list($childTable);').get();
            final match = fkList.firstWhere((item) => item.read<int>('id') == fkid);
            fromCol = match.read<String>('from');
          } catch (_) {}

          if (fromCol.isEmpty) continue;

          // Fetch current violating value
          String? missingVal;
          try {
            final childRow = await _db.customSelect('SELECT $fromCol FROM $childTable WHERE rowid = ?;', variables: [Variable<int>(rowId)]).get();
            if (childRow.isNotEmpty) {
              missingVal = childRow.first.data.values.first?.toString();
            }
          } catch (_) {}

          if (childTable == 'accounts') {
            if (fromCol == 'user_id') {
              final targetUserId = currentUserId ?? 'system';
              await _db.customStatement(
                'UPDATE accounts SET user_id = ? WHERE rowid = ?;',
                [targetUserId, rowId],
              );
              actionsTaken.add('Updated missing user_id on account (rowid: $rowId)');
              if (targetUserId == 'system') {
                await _db.customStatement(
                  'UPDATE accounts SET is_active = 0 WHERE rowid = ?;',
                  [rowId],
                );
                actionsTaken.add('Archived invalid account with system owner (rowid: $rowId)');
              }
            } else {
              await _db.customStatement(
                'UPDATE accounts SET is_active = 0 WHERE rowid = ?;',
                [rowId],
              );
              actionsTaken.add('Archived invalid account (rowid: $rowId)');
            }
          } else if (childTable == 'categories' && fromCol == 'parent_id') {
            await _db.customStatement(
              'UPDATE categories SET parent_id = NULL WHERE rowid = ?;',
              [rowId],
            );
            actionsTaken.add('Reset missing parent_id to NULL on category (rowid: $rowId)');
          } else if (parentTable == 'users') {
            final targetUserId = currentUserId ?? 'system';
            await _db.customStatement(
              'UPDATE $childTable SET $fromCol = ? WHERE rowid = ?;',
              [targetUserId, rowId],
            );
            actionsTaken.add('Updated invalid user_id to "$targetUserId" on $childTable (rowid: $rowId)');
          } else if (parentTable == 'accounts') {
            await _db.customStatement(
              'UPDATE $childTable SET $fromCol = ? WHERE rowid = ?;',
              [unknownAccountId, rowId],
            );
            actionsTaken.add('Moved orphan $childTable reference in $fromCol (rowid: $rowId) to Unknown Account');
          } else if (parentTable == 'categories') {
            await _db.customStatement(
              'UPDATE $childTable SET $fromCol = ? WHERE rowid = ?;',
              [uncategorizedId, rowId],
            );
            actionsTaken.add('Moved orphan $childTable reference in $fromCol (rowid: $rowId) to Uncategorized category');
          } else {
            // General fallback: if nullable, set to NULL; otherwise delete
            bool isNullable = true;
            try {
              final tableInfo = await _db.customSelect('PRAGMA table_info($childTable);').get();
              final colInfo = tableInfo.firstWhere((col) => col.read<String>('name') == fromCol);
              isNullable = colInfo.read<int>('notnull') == 0;
            } catch (_) {}

            if (isNullable) {
              await _db.customStatement(
                'UPDATE $childTable SET $fromCol = NULL WHERE rowid = ?;',
                [rowId],
              );
              actionsTaken.add('Set invalid reference $fromCol to NULL on $childTable (rowid: $rowId)');
            } else {
              await _db.customStatement(
                'DELETE FROM $childTable WHERE rowid = ?;',
                [rowId],
              );
              actionsTaken.add('Deleted orphan row from $childTable (rowid: $rowId) due to invalid reference in non-nullable column $fromCol ($missingVal)');
            }
          }
        }
      }

      await _db.customStatement('PRAGMA foreign_keys = ON;');
    });

    // 3. Rebuild Indexes
    try {
      await _db.customStatement('REINDEX;');
      actionsTaken.add('Rebuild database indexes (REINDEX)');
    } catch (e) {
      actionsTaken.add('Failed to run REINDEX: $e');
    }

    // 4. Run VACUUM & check size difference
    int bytesSaved = 0;
    final dbFile = await _getDatabaseFile();
    if (dbFile != null && await dbFile.exists()) {
      final sizeBefore = await dbFile.length();
      try {
        await _db.customStatement('VACUUM;');
        actionsTaken.add('Cleaned up unused pages (VACUUM)');
        final sizeAfter = await dbFile.length();
        bytesSaved = (sizeBefore - sizeAfter).clamp(0, sizeBefore);
      } catch (e) {
        actionsTaken.add('Failed to run VACUUM: $e');
      }
    } else {
      // Just run VACUUM if file not located on disk
      try {
        await _db.customStatement('VACUUM;');
      } catch (_) {}
    }

    // 5. Re-run checks to verify
    bool finalIntegrityPass = false;
    try {
      final integrityRows = await _db.customSelect('PRAGMA integrity_check;').get();
      finalIntegrityPass = integrityRows.isNotEmpty && integrityRows.first.data.values.first == 'ok';
    } catch (_) {}

    final finalFkRows = await _db.customSelect('PRAGMA foreign_key_check;').get();
    final bool finalFkPass = finalFkRows.isEmpty;

    final report = DatabaseRepairReport(
      initialIntegrityPass: initialIntegrityPass,
      initialFkPass: initialFkPass,
      violationsFound: violationsFound,
      actionsTaken: actionsTaken,
      bytesSaved: bytesSaved,
      finalIntegrityPass: finalIntegrityPass,
      finalFkPass: finalFkPass,
    );

    debugPrint('DatabaseRepairService: Repair finished.\n$report');
    return report;
  }

  Future<Map<String, bool>> checkDatabaseHealth() async {
    final status = {
      'SQLite Integrity': true,
      'Foreign Keys': true,
      'Accounts': true,
      'Categories': true,
      'Transactions': true,
      'Budgets': true,
      'Credit Cards': true,
      'Loans': true,
      'Goals': true,
      'SMS Drafts': true,
    };

    try {
      // 1. SQLite integrity
      final integrityRows = await _db.customSelect('PRAGMA integrity_check;').get();
      status['SQLite Integrity'] = integrityRows.isNotEmpty && integrityRows.first.data.values.first == 'ok';

      // 2. Foreign keys general check
      final fkRows = await _db.customSelect('PRAGMA foreign_key_check;').get();
      status['Foreign Keys'] = fkRows.isEmpty;

      // 3. Table specific checks
      for (var row in fkRows) {
        final table = row.read<String>('table');
        final rowId = row.read<int>('rowid');

        if (table == 'transactions') {
          status['Transactions'] = false;
        } else if (table == 'categories') {
          status['Categories'] = false;
        } else if (table == 'budgets') {
          status['Budgets'] = false;
        } else if (table == 'goals') {
          status['Goals'] = false;
        } else if (table == 'transaction_drafts') {
          status['SMS Drafts'] = false;
        } else if (table == 'accounts') {
          // Check type of account
          try {
            final accRes = await _db.customSelect('SELECT type FROM accounts WHERE rowid = ?;', variables: [Variable<int>(rowId)]).get();
            if (accRes.isNotEmpty) {
              final type = accRes.first.read<String>('type');
              if (type == 'card') {
                status['Credit Cards'] = false;
              } else if (type == 'loan') {
                status['Loans'] = false;
              } else {
                status['Accounts'] = false;
              }
            } else {
              status['Accounts'] = false;
            }
          } catch (_) {
            status['Accounts'] = false;
          }
        }
      }
    } catch (_) {
      // If query fails, mark all as FAIL
      status.updateAll((key, value) => false);
    }

    return status;
  }
}

final databaseRepairServiceProvider = Provider<DatabaseRepairService>((ref) {
  final db = ref.watch(databaseProvider);
  return DatabaseRepairService(db);
});
