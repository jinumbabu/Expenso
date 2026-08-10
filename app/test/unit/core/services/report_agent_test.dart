import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/report_agent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late AppDatabase database;
  late ReportAgent reportAgent;

  setUp(() {
    database = AppDatabase.connect(NativeDatabase.memory());
    reportAgent = ReportAgent(database);

    // Mock Path Provider Method Channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getTemporaryDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('ReportAgent Generation & CSV Export Tests', () {
    final testDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    test('generateReport correctly sums totals and writes report to DB', () async {
      // 1. Setup seed categories
      final catId1 = const Uuid().v4();
      final catId2 = const Uuid().v4();
      
      await database.into(database.categories).insert(
        CategoriesCompanion.insert(
          id: catId1,
          userId: 'user-1',
          name: 'Food',
          type: 'expense',
          createdAt: DateTime.now(),
        ),
      );

      await database.into(database.categories).insert(
        CategoriesCompanion.insert(
          id: catId2,
          userId: 'user-1',
          name: 'Salary',
          type: 'income',
          createdAt: DateTime.now(),
        ),
      );

      // 2. Setup transactions
      final tx1 = Transaction(
        id: const Uuid().v4(),
        userId: 'user-1',
        type: 'expense',
        amount: 25000, // ₹250
        currency: 'INR',
        merchant: 'Zomato',
        categoryId: catId1,
        date: testDate,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tx2 = Transaction(
        id: const Uuid().v4(),
        userId: 'user-1',
        type: 'income',
        amount: 1000000, // ₹10,000
        currency: 'INR',
        merchant: 'Employer Inc',
        categoryId: catId2,
        date: testDate,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await database.transactionDao.insertTransaction(tx1);
      await database.transactionDao.insertTransaction(tx2);

      // 3. Generate report
      final report = await reportAgent.generateReport('user-1', 'daily');


      expect(report, isNotNull);
      expect(report.type, equals('daily'));
      expect(report.summaryText, contains('Income: ₹10000.00'));
      expect(report.summaryText, contains('Expenses: ₹250.00'));
      expect(report.summaryText, contains('Net Cashflow: ₹9750.00'));
      
      // Verify DB record
      final dbReports = await database.reportDao.getReportsForUser('user-1');
      expect(dbReports.length, equals(1));
      
      final payload = jsonDecode(dbReports.first.jsonPayload);
      expect(payload['income'], equals(1000000));
      expect(payload['expenses'], equals(25000));
      
      // Verify exported CSV exists
      final csvPath = dbReports.first.exportedFilePath;
      expect(csvPath, isNotNull);
      
      final csvFile = File(csvPath!);
      expect(await csvFile.exists(), isTrue);
      final csvContent = await csvFile.readAsString();
      expect(csvContent, contains('Zomato'));
      expect(csvContent, contains('Employer Inc'));
      
      // Clean up temp file
      if (await csvFile.exists()) {
        await csvFile.delete();
      }
    });
  });
}
