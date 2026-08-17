import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'connection/connection.dart';
import 'tables/users.dart';
import 'tables/accounts.dart';
import 'tables/categories.dart';
import 'tables/payment_methods.dart';
import 'tables/transactions.dart';
import 'tables/budgets.dart';
import 'tables/chat_history.dart';
import 'tables/ai_memories.dart';
import 'tables/audit_logs.dart';
import 'tables/transaction_drafts.dart';
import 'tables/goals.dart';
import 'tables/subscriptions.dart';
import 'tables/reports.dart';
import 'tables/agent_logs.dart';
import 'tables/predictions.dart';
import 'tables/notifications.dart';
import 'tables/unrecognized_messages.dart';
import 'tables/raw_sms.dart';
import 'tables/parsed_sms.dart';
import 'tables/bills.dart';
import 'tables/merchants.dart';
import 'tables/ai_learnings.dart';
import 'tables/duplicate_hashes.dart';

import 'dao/user_dao.dart';
import 'dao/account_dao.dart';
import 'dao/category_dao.dart';
import 'dao/payment_method_dao.dart';
import 'dao/transaction_dao.dart';
import 'dao/budget_dao.dart';
import 'dao/chat_history_dao.dart';
import 'dao/ai_memory_dao.dart';
import 'dao/audit_log_dao.dart';
import 'dao/transaction_draft_dao.dart';
import 'dao/goal_dao.dart';
import 'dao/subscription_dao.dart';
import 'dao/report_dao.dart';
import 'dao/agent_log_dao.dart';
import 'dao/prediction_dao.dart';
import 'dao/notification_dao.dart';
import 'dao/unrecognized_message_dao.dart';

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
    TransactionDrafts,
    Goals,
    Subscriptions,
    FinancialReports,
    AgentLogs,
    FinancialPredictions,
    AppNotifications,
    UnrecognizedMessages,
    RawSms,
    ParsedSms,
    Bills,
    Merchants,
    AiLearnings,
    DuplicateHashes,
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
    TransactionDraftDao,
    GoalDao,
    SubscriptionDao,
    ReportDao,
    AgentLogDao,
    PredictionDao,
    NotificationDao,
    UnrecognizedMessageDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.connect(super.connection);

  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();

      final now = DateTime.now();

      // Seed 'system' user
      await into(users).insert(
        UsersCompanion.insert(
          id: 'system',
          googleId: 'system_google_id',
          email: 'system@test.com',
          displayName: 'System User',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Seed categories: Food, Travel, Shopping, Utilities, Entertainment, Salary, Freelance, Investment, Transfer
      final parentCategories = [
        {'id': const Uuid().v4(), 'name': 'Food', 'type': 'expense', 'icon': 'fastfood', 'color': '0xFFFFA500'},
        {'id': const Uuid().v4(), 'name': 'Travel', 'type': 'expense', 'icon': 'flight', 'color': '0xFF0066FF'},
        {'id': const Uuid().v4(), 'name': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag', 'color': '0xFF8A2BE2'},
        {'id': const Uuid().v4(), 'name': 'Utilities', 'type': 'expense', 'icon': 'receipt_long', 'color': '0xFFFFB703'},
        {'id': const Uuid().v4(), 'name': 'Entertainment', 'type': 'expense', 'icon': 'movie', 'color': '0xFFFF3B30'},
        {'id': const Uuid().v4(), 'name': 'Salary', 'type': 'income', 'icon': 'payments', 'color': '0xFF00FF88'},
        {'id': const Uuid().v4(), 'name': 'Freelance', 'type': 'income', 'icon': 'work', 'color': '0xFF00FF88'},
        {'id': const Uuid().v4(), 'name': 'Investment', 'type': 'expense', 'icon': 'trending_up', 'color': '0xFF00E5FF'},
        {'id': const Uuid().v4(), 'name': 'Transfer', 'type': 'transfer', 'icon': 'swap_horiz', 'color': '0xFF6366F1'},
      ];

      for (var parent in parentCategories) {
        await into(categories).insert(
          CategoriesCompanion.insert(
            id: parent['id']!,
            userId: 'system',
            name: parent['name']!,
            type: parent['type']!,
            icon: Value(parent['icon']),
            color: Value(parent['color']),
            isSystemDefault: const Value(true),
            createdAt: now,
          ),
        );
      }

      String parentId(String name) => parentCategories.firstWhere((p) => p['name'] == name)['id']!;

      final subcategoriesData = [
        {'name': 'Restaurant', 'parent': 'Food', 'type': 'expense', 'icon': 'restaurant', 'color': '0xFFFFA500'},
        {'name': 'Cafe', 'parent': 'Food', 'type': 'expense', 'icon': 'coffee', 'color': '0xFFFFA500'},
        {'name': 'Snacks', 'parent': 'Food', 'type': 'expense', 'icon': 'bakery', 'color': '0xFFFFA500'},
        {'name': 'Fruits', 'parent': 'Food', 'type': 'expense', 'icon': 'spa', 'color': '0xFFFFA500'},
        
        {'name': 'Fuel', 'parent': 'Travel', 'type': 'expense', 'icon': 'local_gas_station', 'color': '0xFF0066FF'},
        {'name': 'Hotel', 'parent': 'Travel', 'type': 'expense', 'icon': 'hotel', 'color': '0xFF0066FF'},
        {'name': 'Flight', 'parent': 'Travel', 'type': 'expense', 'icon': 'flight', 'color': '0xFF0066FF'},
        {'name': 'Taxi', 'parent': 'Travel', 'type': 'expense', 'icon': 'local_taxi', 'color': '0xFF0066FF'},

        {'name': 'Grocery', 'parent': 'Shopping', 'type': 'expense', 'icon': 'shopping_cart', 'color': '0xFF8A2BE2'},
        {'name': 'Amazon', 'parent': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag', 'color': '0xFF8A2BE2'},
        {'name': 'Flipkart', 'parent': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag', 'color': '0xFF8A2BE2'},
        {'name': 'Clothes', 'parent': 'Shopping', 'type': 'expense', 'icon': 'checkroom', 'color': '0xFF8A2BE2'},

        {'name': 'Electricity Bill', 'parent': 'Utilities', 'type': 'expense', 'icon': 'electric_bolt', 'color': '0xFFFFB703'},
        {'name': 'Water Bill', 'parent': 'Utilities', 'type': 'expense', 'icon': 'water_drop', 'color': '0xFFFFB703'},
        {'name': 'Mobile Recharge', 'parent': 'Utilities', 'type': 'expense', 'icon': 'phone_android', 'color': '0xFFFFB703'},
        {'name': 'Internet', 'parent': 'Utilities', 'type': 'expense', 'icon': 'wifi', 'color': '0xFFFFB703'},
        {'name': 'Gas Bill', 'parent': 'Utilities', 'type': 'expense', 'icon': 'local_fire_department', 'color': '0xFFFFB703'},
      ];

      for (var sub in subcategoriesData) {
        await into(categories).insert(
          CategoriesCompanion.insert(
            id: const Uuid().v4(),
            userId: 'system',
            name: sub['name']!,
            type: sub['type']!,
            parentId: Value(parentId(sub['parent']!)),
            icon: Value(sub['icon']),
            color: Value(sub['color']),
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
      if (from < 4) {
        await migrator.createTable(transactionDrafts);
      }
      if (from < 5) {
        await migrator.createTable(goals);
      }
      if (from < 6) {
        await migrator.createTable(subscriptions);
        await migrator.createTable(financialReports);
        await migrator.createTable(agentLogs);
        await migrator.createTable(financialPredictions);
        await migrator.createTable(appNotifications);
      }
      if (from < 7) {
        await migrator.createTable(unrecognizedMessages);
      }
      if (from < 8) {
        await migrator.addColumn(users, users.photoUrl);
        await migrator.addColumn(users, users.lastLogin);
      }
      if (from < 9) {
        await migrator.addColumn(transactions, transactions.transactionType);
        await migrator.addColumn(transactions, transactions.accountType);
        await migrator.addColumn(transactions, transactions.billStatus);
        await migrator.addColumn(transactions, transactions.dueDate);
        await migrator.addColumn(transactions, transactions.referenceNumber);
        await migrator.addColumn(transactions, transactions.aiClassification);
      }
      if (from < 10) {
        await migrator.addColumn(accounts, accounts.bankName);
        await migrator.addColumn(accounts, accounts.openingBalance);
        await migrator.addColumn(accounts, accounts.currency);
        await migrator.addColumn(accounts, accounts.colorTheme);
        await migrator.addColumn(accounts, accounts.icon);
        await migrator.addColumn(accounts, accounts.notes);
        await migrator.addColumn(accounts, accounts.isActive);
        await migrator.addColumn(accounts, accounts.creditLimit);
        await migrator.addColumn(accounts, accounts.availableCredit);
        await migrator.addColumn(accounts, accounts.outstandingBalance);
        await migrator.addColumn(accounts, accounts.statementDate);
        await migrator.addColumn(accounts, accounts.paymentDueDate);
        await migrator.addColumn(accounts, accounts.minAmountDue);
        await migrator.addColumn(accounts, accounts.totalAmountDue);
        await migrator.addColumn(accounts, accounts.lastPayment);
        await migrator.addColumn(accounts, accounts.nextDueDate);
        await migrator.addColumn(accounts, accounts.paymentStatus);
        await migrator.addColumn(accounts, accounts.autoPay);
      }
      if (from < 11) {
        await migrator.addColumn(transactions, transactions.receiptUrl);
        await migrator.addColumn(transactions, transactions.billLink);
        await migrator.addColumn(transactions, transactions.tags);
      }
      if (from < 12) {
        await migrator.addColumn(categories, categories.parentId);
        await migrator.addColumn(categories, categories.color);
        await migrator.addColumn(transactions, transactions.subcategoryId);
      }
      if (from < 13) {
        await migrator.addColumn(accounts, accounts.isEstimated);
        await migrator.addColumn(transactionDrafts, transactionDrafts.categoryId);
        await migrator.addColumn(transactionDrafts, transactionDrafts.category);
        await migrator.addColumn(transactionDrafts, transactionDrafts.confidenceScore);
      }
      if (from < 14) {
        await migrator.addColumn(accounts, accounts.last4Digits);
        await migrator.addColumn(accounts, accounts.statementCycle);
        await migrator.addColumn(accounts, accounts.enableBillReminder);
        await migrator.addColumn(accounts, accounts.enableSmsTracking);
      }
      if (from < 15) {
        await migrator.addColumn(transactions, transactions.fingerprint);
        await migrator.addColumn(transactions, transactions.supportingSms);
        await migrator.addColumn(transactionDrafts, transactionDrafts.matchingTransactionId);
        await migrator.addColumn(transactionDrafts, transactionDrafts.supportingSms);
      }
      if (from < 16) {
        await migrator.createTable(rawSms);
        await migrator.createTable(parsedSms);
        await migrator.createTable(bills);
        await migrator.createTable(merchants);
        await migrator.createTable(aiLearnings);
        await migrator.createTable(duplicateHashes);
      }
      if (from < 17) {
        await migrator.addColumn(accounts, accounts.verifiedBalance);
        await migrator.addColumn(accounts, accounts.calculatedBalance);
        await migrator.addColumn(accounts, accounts.importedBalance);
        await migrator.addColumn(accounts, accounts.lastSyncedBalance);
        await migrator.addColumn(accounts, accounts.verifiedAt);
        await migrator.addColumn(accounts, accounts.hasMismatch);
        await migrator.addColumn(accounts, accounts.mismatchExpected);
        await migrator.addColumn(accounts, accounts.mismatchImported);
        await migrator.addColumn(accounts, accounts.sortOrder);
      }
      if (from < 18) {
        await migrator.addColumn(accounts, accounts.balanceDiscrepancyDismissed);
      }
    },
  );

  Future<void> clearAllData() async {
    await transaction(() async {
      await customStatement('PRAGMA foreign_keys = OFF;');
      for (final table in allTables) {
        await delete(table).go();
      }
      await customStatement('PRAGMA foreign_keys = ON;');
    });
  }
}

