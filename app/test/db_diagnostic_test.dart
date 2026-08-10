import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;
import 'package:app/core/security/secure_storage_service.dart';

void main() {
  test('Run SQLite Database Diagnostics', () async {
    final searchDirs = [
      'C:\\Users\\jinum\\AppData\\Roaming',
      'C:\\Users\\jinum\\AppData\\Local',
    ];
    
    File? dbFile;
    for (var dirPath in searchDirs) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        try {
          final list = await dir.list(recursive: false).toList();
          print('Top-level in $dirPath:');
          for (var item in list) {
            final name = p.basename(item.path).toLowerCase();
            if (name.contains('expenso') || name.contains('jinum') || name.contains('app') || name.contains('flutter') || name.contains('local')) {
              print('  - ${item.path}');
              if (item is Directory) {
                // List children
                try {
                  final children = await item.list(recursive: true).toList();
                  for (var child in children) {
                    print('    * ${child.path}');
                    if (p.basename(child.path) == 'expenso_database.sqlite' || child.path.endsWith('.sqlite')) {
                      dbFile = child as File;
                      print('Found database child: ${child.path}');
                    }
                  }
                } catch (e) {
                  print('    Error listing ${item.path}: $e');
                }
              }
            }
          }
        } catch (e) {
          print('Error listing $dirPath: $e');
        }
      }
      if (dbFile != null) break;
    }
    
    if (dbFile == null) {
      print('CRITICAL ERROR: expenso_database.sqlite not found in AppData!');
      return;
    }
    
    print('Database File Size: ${await dbFile.length()} bytes');
    
    final secureStorage = SecureStorageService();
    final key = await secureStorage.getDatabaseKey();
    print('Database Key: $key');
    
    if (key != null) {
      try {
        final db = sqlite3.open(dbFile.path);
        db.execute("PRAGMA key = '$key';");
        
        final tables = db.select("SELECT name FROM sqlite_master WHERE type='table';");
        print('Tables in Database: ${tables.map((row) => row['name']).toList()}');
        
        final users = db.select("SELECT id, google_id, email, display_name FROM users;");
        print('Users Count: ${users.length}');
        for (var u in users) {
          print('  User: id=${u['id']}, email=${u['email']}, name=${u['display_name']}');
        }
        
        final accounts = db.select("SELECT id, user_id, name, type, balance, outstanding_balance, verified_balance, has_mismatch FROM accounts;");
        print('Accounts Count: ${accounts.length}');
        for (var a in accounts) {
          print('  Account: id=${a['id']}, userId=${a['user_id']}, name=${a['name']}, type=${a['type']}, balance=${a['balance']}, outstanding=${a['outstanding_balance']}, verified=${a['verified_balance']}, hasMismatch=${a['has_mismatch']}');
        }
        
        final txsCount = db.select("SELECT COUNT(*) as c FROM transactions;");
        print('Total Transactions: ${txsCount.first['c']}');
        
        final txs = db.select("SELECT id, user_id, account_id, reference_number, type, amount, merchant, date, deleted_at FROM transactions LIMIT 20;");
        for (var tx in txs) {
          print('  Tx: id=${tx['id']}, userId=${tx['user_id']}, accountId=${tx['account_id']}, ref=${tx['reference_number']}, type=${tx['type']}, amount=${tx['amount']}, merchant=${tx['merchant']}, date=${tx['date']}, deletedAt=${tx['deleted_at']}');
        }
        
        db.dispose();
      } catch (e) {
        print('Error opening or querying database: $e');
      }
    }
  });
}
