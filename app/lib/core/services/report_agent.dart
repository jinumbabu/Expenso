import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:developer' as dev;
import '../database/app_database.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class ReportAgent {
  final AppDatabase _db;

  ReportAgent(this._db);

  /// Generates a comprehensive financial report (daily, weekly, or monthly)
  /// and exports it to local storage.
  Future<FinancialReport> generateReport(String userId, String type) async {
    dev.log('ReportAgent: Generating $type report for user $userId');
    final now = DateTime.now();
    DateTime startDate;

    if (type == 'daily') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (type == 'weekly') {
      startDate = now.subtract(const Duration(days: 7));
    } else {
      // monthly
      startDate = DateTime(now.year, now.month, 1);
    }

    // Fetch transactions
    final allTxs = await _db.transactionDao.getTransactionsForUser(userId);
    final reportTxs = allTxs.where((tx) => tx.date.isAfter(startDate) || tx.date.isAtSameMomentAs(startDate)).toList();

    // Fetch Categories
    final categories = await _db.categoryDao.getCategoriesForUser(userId);
    final categoriesMap = {for (var c in categories) c.id: c};

    // Calculate metrics
    int income = 0;
    int expenses = 0;
    Transaction? largestExpense;
    final Map<String, int> categoryAnalysis = {};

    for (var tx in reportTxs) {
      if (tx.type == 'income') {
        income += tx.amount;
      } else if (tx.type == 'expense') {
        expenses += tx.amount;
        if (largestExpense == null || tx.amount > largestExpense.amount) {
          largestExpense = tx;
        }

        final catName = categoriesMap[tx.categoryId]?.name ?? 'Uncategorized';
        categoryAnalysis[catName] = (categoryAnalysis[catName] ?? 0) + tx.amount;
      }
    }

    final netBalance = income - expenses;
    final double incomeVal = income / 100.0;
    final double expensesVal = expenses / 100.0;
    final double netVal = netBalance / 100.0;

    // Build JSON payload & Summary Text
    final Map<String, dynamic> jsonPayload = {
      'income': income,
      'expenses': expenses,
      'netBalance': netBalance,
      'largestExpense': largestExpense == null ? null : {
        'id': largestExpense.id,
        'amount': largestExpense.amount,
        'merchant': largestExpense.merchant ?? 'General Merchant',
        'date': largestExpense.date.toIso8601String(),
      },
      'categoryAnalysis': categoryAnalysis,
      'transactionCount': reportTxs.length,
    };

    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('  EXPENDO FINANCIAL EXECUTIVE REPORT - ${type.toUpperCase()}');
    buffer.writeln('  Generated on: ${now.toIso8601String().substring(0, 10)}');
    buffer.writeln('========================================');
    buffer.writeln('- Total Income: ₹${incomeVal.toStringAsFixed(2)}');
    buffer.writeln('- Total Expenses: ₹${expensesVal.toStringAsFixed(2)}');
    buffer.writeln('- Net Cashflow: ₹${netVal.toStringAsFixed(2)}');
    buffer.writeln('- Transactions Tracked: ${reportTxs.length}');

    if (largestExpense != null) {
      final double lrgVal = largestExpense.amount / 100.0;
      buffer.writeln('- Largest Expense: ₹${lrgVal.toStringAsFixed(2)} at ${largestExpense.merchant ?? "General Merchant"}');
    }

    buffer.writeln('\nCategory Breakdown:');
    if (categoryAnalysis.isEmpty) {
      buffer.writeln('  No expenses recorded.');
    } else {
      categoryAnalysis.forEach((cat, val) {
        buffer.writeln('  * $cat: ₹${(val / 100.0).toStringAsFixed(2)}');
      });
    }

    // Export formats
    String? exportedPath;
    try {
      final tempDir = await getTemporaryDirectory();
      final reportDir = Directory(p.join(tempDir.path, 'reports'));
      if (!await reportDir.exists()) {
        await reportDir.create(recursive: true);
      }

      // 1. Export CSV File
      final csvFile = File(p.join(reportDir.path, 'report_${type}_${now.millisecondsSinceEpoch}.csv'));
      final csvBuffer = StringBuffer();
      csvBuffer.writeln('Date,Merchant,Category,Type,Amount (₹)');
      for (var tx in reportTxs) {
        final catName = categoriesMap[tx.categoryId]?.name ?? 'Uncategorized';
        final amt = tx.amount / 100.0;
        final dateStr = tx.date.toIso8601String().substring(0, 10);
        csvBuffer.writeln('"$dateStr","${tx.merchant ?? ''}","$catName","${tx.type}",$amt');
      }
      await csvFile.writeAsString(csvBuffer.toString());
      exportedPath = csvFile.path;

      // 2. Mock PDF Text Summary file (to support pdf export option)
      final pdfFile = File(p.join(reportDir.path, 'report_${type}_${now.millisecondsSinceEpoch}.pdf'));
      await pdfFile.writeAsString(buffer.toString());
    } catch (e) {
      dev.log('ReportAgent: Failed to export physical files: $e');
    }

    final report = FinancialReport(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      summaryText: buffer.toString(),
      jsonPayload: jsonEncode(jsonPayload),
      exportedFilePath: exportedPath,
      createdAt: now,
    );

    // Save to DB
    await _db.reportDao.insertReport(report);

    // Log Agent Action
    await _db.agentLogDao.insertLog(
      AgentLog(
        id: const Uuid().v4(),
        agentName: 'Report Generator Agent',
        actionType: 'REPORT_GENERATED',
        decisionDescription: 'Generated $type report. Total Income: ₹${incomeVal.toStringAsFixed(2)}, Total Expenses: ₹${expensesVal.toStringAsFixed(2)}. Exported CSV path: $exportedPath',
        confidenceScore: 1.0,
        timestamp: now,
      ),
    );

    return report;
  }
}

final Provider<ReportAgent> reportAgentProvider = Provider<ReportAgent>((ref) {
  final db = ref.watch(databaseProvider);
  return ReportAgent(db);
});
