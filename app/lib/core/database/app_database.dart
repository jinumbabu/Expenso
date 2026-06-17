import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../security/secure_storage_service.dart';
import 'tables/users.dart';
import 'tables/accounts.dart';
import 'tables/categories.dart';
import 'tables/payment_methods.dart';
import 'tables/transactions.dart';
import 'tables/budgets.dart';
import 'tables/chat_history.dart';
import 'tables/ai_memories.dart';
import 'tables/audit_logs.dart';

import 'dao/user_dao.dart';
import 'dao/account_dao.dart';
import 'dao/category_dao.dart';
import 'dao/payment_method_dao.dart';
import 'dao/transaction_dao.dart';
import 'dao/budget_dao.dart';
import 'dao/chat_history_dao.dart';
import 'dao/ai_memory_dao.dart';
import 'dao/audit_log_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Accounts,
    Categories,
    PaymentMethods,
    Transactions,
    Budgets,
    ChatHistory,
    AiMemories,
    AuditLogs,
  ],
  daos: [
    UserDao,
    AccountDao,
    CategoryDao,
    PaymentMethodDao,
    TransactionDao,
    BudgetDao,
    ChatHistoryDao,
    AiMemoryDao,
    AuditLogDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();

      final now = DateTime.now();

      // Seed categories: Food, Fuel, Grocery, Utilities, Shopping, Entertainment, Salary, Freelance, Investment, Transfer
      final defaultCategories = [
        {'name': 'Food', 'type': 'expense', 'icon': 'fastfood'},
        {'name': 'Fuel', 'type': 'expense', 'icon': 'local_gas_station'},
        {'name': 'Grocery', 'type': 'expense', 'icon': 'shopping_cart'},
        {'name': 'Utilities', 'type': 'expense', 'icon': 'receipt_long'},
        {'name': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag'},
        {'name': 'Entertainment', 'type': 'expense', 'icon': 'movie'},
        {'name': 'Salary', 'type': 'income', 'icon': 'payments'},
        {'name': 'Freelance', 'type': 'income', 'icon': 'work'},
        {'name': 'Investment', 'type': 'expense', 'icon': 'trending_up'},
        {'name': 'Transfer', 'type': 'transfer', 'icon': 'swap_horiz'},
      ];

      for (var cat in defaultCategories) {
        await into(categories).insert(
          CategoriesCompanion.insert(
            id: const Uuid().v4(),
            userId: 'system',
            name: cat['name']!,
            type: cat['type']!,
            icon: Value(cat['icon']),
            isSystemDefault: const Value(true),
            createdAt: now,
          ),
        );
      }

      // Seed payment methods: Cash, UPI, Credit Card, Debit Card, Net Banking
      final defaultPaymentMethods = [
        {'name': 'Cash', 'type': 'cash'},
        {'name': 'UPI', 'type': 'upi'},
        {'name': 'Credit Card', 'type': 'card'},
        {'name': 'Debit Card', 'type': 'card'},
        {'name': 'Net Banking', 'type': 'bank'},
      ];

      for (var pm in defaultPaymentMethods) {
        await into(paymentMethods).insert(
          PaymentMethodsCompanion.insert(
            id: const Uuid().v4(),
            userId: 'system',
            name: pm['name']!,
            type: pm['type']!,
            createdAt: now,
          ),
        );
      }
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(chatHistory);
        await migrator.createTable(aiMemories);
      }
      if (from < 3) {
        await migrator.createTable(auditLogs);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      if (kIsWeb) {
        return driftDatabase(
          name: 'expenso_database',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        );
      }

      final supportDir = await getApplicationSupportDirectory();
      final file = File(p.join(supportDir.path, 'expenso_database.sqlite'));

      // Resolve key from secure storage
      final secureStorage = SecureStorageService();
      String? key = await secureStorage.getDatabaseKey();
      if (key == null) {
        // Generate a random 32-character key
        final random = Random.secure();
        final values = List<int>.generate(32, (i) => random.nextInt(256));
        key = base64UrlEncode(values);
        await secureStorage.saveDatabaseKey(key);
      }

      return NativeDatabase(
        file,
        setup: (rawDb) {
          rawDb.execute("PRAGMA key = '$key';");
        },
      );
    });
  }
}
