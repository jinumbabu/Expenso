import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/financial_calculation_service.dart';
import 'package:app/features/analytics/presentation/models/analytics_chart_data.dart';

void main() {
  group('Account-Wise Donut Analytics Logic Tests', () {
    late Account hdfcAccount;
    late Account sbiAccount;
    final now = DateTime.now();

    setUp(() {
      hdfcAccount = Account(
        id: 'acc_hdfc_3726',
        userId: 'user1',
        name: 'HDFC 3726',
        type: 'savings',
        balance: 1500000, // ₹15,000.00
        openingBalance: 1000000,
        currency: 'INR',
        isActive: true,
        isDefault: false,
        isEstimated: false,
        createdAt: now,
        updatedAt: now,
      );

      sbiAccount = Account(
        id: 'acc_sbi_8589',
        userId: 'user1',
        name: 'SBI 8589',
        type: 'savings',
        balance: 500000, // ₹5,000.00
        openingBalance: 500000,
        currency: 'INR',
        isActive: true,
        isDefault: false,
        isEstimated: false,
        createdAt: now,
        updatedAt: now,
      );
    });

    test('TEST 1 — Filters transactions strictly by account ID and mode (Income vs Expense)', () {
      final hdfcSalary = Transaction(
        id: 'tx_hdfc_inc',
        userId: 'user1',
        accountId: 'acc_hdfc_3726',
        categoryId: 'cat_salary',
        type: 'income',
        amount: 1000000, // ₹10,000.00
        currency: 'INR',
        merchant: 'Salary Credit',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final hdfcGroceries = Transaction(
        id: 'tx_hdfc_exp',
        userId: 'user1',
        accountId: 'acc_hdfc_3726',
        categoryId: 'cat_groceries',
        type: 'expense',
        amount: 200000, // ₹2,000.00
        currency: 'INR',
        merchant: 'Supermarket',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final sbiIncome = Transaction(
        id: 'tx_sbi_inc',
        userId: 'user1',
        accountId: 'acc_sbi_8589',
        categoryId: 'cat_freelance',
        type: 'income',
        amount: 500000, // ₹5,000.00 (Other account)
        currency: 'INR',
        merchant: 'Client Payment',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final allTxs = [hdfcSalary, hdfcGroceries, sbiIncome];

      // HDFC Income Mode
      final hdfcIncomeTxs = allTxs.where((tx) =>
          tx.accountId == hdfcAccount.id &&
          FinancialCalculationService.isCredit(tx, hdfcAccount.id)).toList();

      expect(hdfcIncomeTxs.length, equals(1));
      expect(hdfcIncomeTxs.first.id, equals('tx_hdfc_inc'));
      expect(hdfcIncomeTxs.first.amount, equals(1000000));

      // HDFC Expense Mode
      final hdfcExpenseTxs = allTxs.where((tx) =>
          tx.accountId == hdfcAccount.id &&
          FinancialCalculationService.isDebit(tx, hdfcAccount.id)).toList();

      expect(hdfcExpenseTxs.length, equals(1));
      expect(hdfcExpenseTxs.first.id, equals('tx_hdfc_exp'));
      expect(hdfcExpenseTxs.first.amount, equals(200000));
    });

    test('TEST 2 — Category Aggregation and Percentage Calculation for Selected Account', () {
      final tx1 = Transaction(
        id: 'tx1',
        userId: 'user1',
        accountId: 'acc_hdfc_3726',
        categoryId: 'cat_shopping',
        type: 'expense',
        amount: 600000, // ₹6,000.00
        currency: 'INR',
        merchant: 'Flipkart',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final tx2 = Transaction(
        id: 'tx2',
        userId: 'user1',
        accountId: 'acc_hdfc_3726',
        categoryId: 'cat_shopping',
        type: 'expense',
        amount: 200000, // ₹2,000.00
        currency: 'INR',
        merchant: 'Amazon',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final tx3 = Transaction(
        id: 'tx3',
        userId: 'user1',
        accountId: 'acc_hdfc_3726',
        categoryId: 'cat_food',
        type: 'expense',
        amount: 200000, // ₹2,000.00
        currency: 'INR',
        merchant: 'Restaurant',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final accountTxs = [tx1, tx2, tx3];

      // Calculate totals per category
      final totals = <String, int>{};
      int totalCents = 0;
      for (final tx in accountTxs) {
        final catId = tx.categoryId!;
        totals[catId] = (totals[catId] ?? 0) + tx.amount.toInt();
        totalCents += tx.amount.toInt();
      }

      final totalDouble = totalCents / 100.0;
      expect(totalDouble, equals(10000.0)); // ₹10,000.00 total

      final shoppingPct = ((totals['cat_shopping']! / 100.0) / totalDouble) * 100;
      final foodPct = ((totals['cat_food']! / 100.0) / totalDouble) * 100;

      expect(shoppingPct, equals(80.0)); // 80% Shopping
      expect(foodPct, equals(20.0)); // 20% Food
    });

    test('TEST 3 — Transfer handling isolation per account', () {
      final transferTx = Transaction(
        id: 'tx_transfer',
        userId: 'user1',
        accountId: 'acc_hdfc_3726',
        billLink: 'acc_sbi_8589',
        categoryId: 'cat_transfer',
        type: 'transfer',
        amount: 300000, // ₹3,000.00
        currency: 'INR',
        merchant: 'Self Transfer',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      // For HDFC, this transfer is a debit (Expense mode)
      expect(FinancialCalculationService.isDebit(transferTx, 'acc_hdfc_3726'), isTrue);
      expect(FinancialCalculationService.isCredit(transferTx, 'acc_hdfc_3726'), isFalse);

      // For SBI, this transfer is a credit (Income mode)
      expect(FinancialCalculationService.isCredit(transferTx, 'acc_sbi_8589'), isTrue);
      expect(FinancialCalculationService.isDebit(transferTx, 'acc_sbi_8589'), isFalse);
    });

    test('TEST 4 — Empty state verification when no transactions match selected mode', () {
      final expenseOnlyTx = Transaction(
        id: 'tx_exp_only',
        userId: 'user1',
        accountId: 'acc_hdfc_3726',
        categoryId: 'cat_bills',
        type: 'expense',
        amount: 150000, // ₹1,500.00
        currency: 'INR',
        merchant: 'Electricity Bill',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final accountTxs = [expenseOnlyTx];

      // Income Mode filter on HDFC
      final incomeTxs = accountTxs.where((tx) =>
          FinancialCalculationService.isCredit(tx, 'acc_hdfc_3726')).toList();

      expect(incomeTxs, isEmpty);
    });
  });
}
