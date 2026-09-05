import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:app/core/database/app_database.dart';
import 'package:app/core/services/financial_calculation_service.dart';

void main() {
  group('Pay Card & Credit Card Accounting Tests', () {
    late Account hdfcAccount;
    late Account sbiAccount;
    late Account iciciCardAccount;
    final now = DateTime.now();

    setUp(() {
      hdfcAccount = Account(
        id: 'acc_hdfc',
        userId: 'user1',
        name: 'HDFC 3726',
        type: 'savings',
        balance: 1000000, // ₹10,000.00
        openingBalance: 1000000,
        currency: 'INR',
        isActive: true,
        isDefault: false,
        isEstimated: false,
        createdAt: now,
        updatedAt: now,
      );

      sbiAccount = Account(
        id: 'acc_sbi',
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

      iciciCardAccount = Account(
        id: 'acc_icici_cc',
        userId: 'user1',
        name: 'ICICI Credit Card',
        type: 'credit_card',
        balance: -2144554, // ₹21,445.54 outstanding
        openingBalance: 2144554,
        outstandingBalance: 2144554,
        creditLimit: 5000000, // ₹50,000.00
        currency: 'INR',
        isActive: true,
        isDefault: false,
        isEstimated: false,
        createdAt: now,
        updatedAt: now,
      );
    });

    test('TEST 1 — Normal Expense increases Total Expense', () {
      final expenseTx = Transaction(
        id: 'tx_exp1',
        userId: 'user1',
        accountId: 'acc_hdfc',
        type: 'expense',
        amount: 100000, // ₹1,000.00
        currency: 'INR',
        merchant: 'Supermarket',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      expect(FinancialCalculationService.isExpense(expenseTx), isTrue);
      expect(FinancialCalculationService.isTransfer(expenseTx), isFalse);

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: [expenseTx],
        accounts: [hdfcAccount],
        selectedMonth: now,
      );

      expect(snapshot.expenses, equals(1000.00));
    });

    test('TEST 2 — Normal Income increases Total Income and leaves Total Expense unchanged', () {
      final incomeTx = Transaction(
        id: 'tx_inc1',
        userId: 'user1',
        accountId: 'acc_hdfc',
        type: 'income',
        amount: 500000, // ₹5,000.00
        currency: 'INR',
        merchant: 'Salary Deposit',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      expect(FinancialCalculationService.isIncome(incomeTx), isTrue);
      expect(FinancialCalculationService.isExpense(incomeTx), isFalse);

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: [incomeTx],
        accounts: [hdfcAccount],
        selectedMonth: now,
      );

      expect(snapshot.income, equals(5000.00));
      expect(snapshot.expenses, equals(0.00));
    });

    test('TEST 3 — Normal Transfer updates account balances while leaving Total Expense and Income unchanged', () {
      final transferTx = Transaction(
        id: 'tx_tr1',
        userId: 'user1',
        accountId: 'acc_hdfc',
        billLink: 'acc_sbi',
        type: 'transfer',
        amount: 200000, // ₹2,000.00
        currency: 'INR',
        merchant: 'Self Transfer',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      expect(FinancialCalculationService.isTransfer(transferTx), isTrue);
      expect(FinancialCalculationService.isExpense(transferTx), isFalse);
      expect(FinancialCalculationService.isIncome(transferTx), isFalse);

      final updatedHdfc = FinancialCalculationService.calculateSingleAccountBalance(hdfcAccount, [transferTx]);
      final updatedSbi = FinancialCalculationService.calculateSingleAccountBalance(sbiAccount, [transferTx]);

      expect(updatedHdfc.balance, equals(800000)); // ₹10,000 - ₹2,000 = ₹8,000
      expect(updatedSbi.balance, equals(700000));  // ₹5,000 + ₹2,000 = ₹7,000

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: [transferTx],
        accounts: [hdfcAccount, sbiAccount],
        selectedMonth: now,
      );

      expect(snapshot.expenses, equals(0.00));
      expect(snapshot.income, equals(0.00));
    });

    test('TEST 4 — Pay Card decreases source account balance and CC outstanding without increasing Total Expense or Income', () {
      final payCardTx = Transaction(
        id: 'tx_paycard1',
        userId: 'user1',
        accountId: 'acc_hdfc',
        billLink: 'acc_icici_cc',
        type: 'pay_card',
        amount: 452034, // ₹4,520.34
        currency: 'INR',
        merchant: 'Pay CC: ICICI Credit Card',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      expect(FinancialCalculationService.isTransfer(payCardTx), isTrue);
      expect(FinancialCalculationService.isExpense(payCardTx), isFalse);

      final updatedHdfc = FinancialCalculationService.calculateSingleAccountBalance(hdfcAccount, [payCardTx]);
      final updatedCc = FinancialCalculationService.calculateSingleAccountBalance(iciciCardAccount, [payCardTx]);

      // HDFC balance decreases by ₹4,520.34
      expect(updatedHdfc.balance, equals(1000000 - 452034)); // ₹5,479.66
      // ICICI Credit Card outstanding decreases by ₹4,520.34
      expect(updatedCc.outstandingBalance, equals(2144554 - 452034)); // ₹16,925.20

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: [payCardTx],
        accounts: [hdfcAccount, iciciCardAccount],
        selectedMonth: now,
      );

      expect(snapshot.expenses, equals(0.00));
      expect(snapshot.income, equals(0.00));
    });

    test('TEST 5 — Credit Card Purchase IS an expense and increases CC outstanding', () {
      final ccPurchaseTx = Transaction(
        id: 'tx_cc_purchase1',
        userId: 'user1',
        accountId: 'acc_icici_cc',
        type: 'credit_card_purchase',
        amount: 300000, // ₹3,000.00
        currency: 'INR',
        merchant: 'Electronics Store',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      expect(FinancialCalculationService.isExpense(ccPurchaseTx), isTrue);

      final updatedCc = FinancialCalculationService.calculateSingleAccountBalance(iciciCardAccount, [ccPurchaseTx]);
      expect(updatedCc.outstandingBalance, equals(2144554 + 300000)); // ₹24,445.54

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: [ccPurchaseTx],
        accounts: [iciciCardAccount],
        selectedMonth: now,
      );

      expect(snapshot.expenses, equals(3000.00));
    });

    test('TEST 6 — Pay Card After Purchase keeps Total Expense at purchase amount only', () {
      final purchaseTx = Transaction(
        id: 'tx_purchase',
        userId: 'user1',
        accountId: 'acc_icici_cc',
        type: 'credit_card_purchase',
        amount: 300000, // ₹3,000.00
        currency: 'INR',
        merchant: 'Shopping Mall',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final paymentTx = Transaction(
        id: 'tx_payment',
        userId: 'user1',
        accountId: 'acc_hdfc',
        billLink: 'acc_icici_cc',
        type: 'credit_card_payment',
        amount: 300000, // ₹3,000.00
        currency: 'INR',
        merchant: 'Card Pay',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: [purchaseTx, paymentTx],
        accounts: [hdfcAccount, iciciCardAccount],
        selectedMonth: now,
      );

      // Total Expense MUST be ₹3,000 (NOT ₹6,000!)
      expect(snapshot.expenses, equals(3000.00));

      final updatedCc = FinancialCalculationService.calculateSingleAccountBalance(iciciCardAccount, [purchaseTx, paymentTx]);
      // Outstanding returns to base balance: 2144554 + 300000 - 300000 = 2144554
      expect(updatedCc.outstandingBalance, equals(2144554));
    });

    test('TEST 7 — Edit Pay Card amount recalculates balances while Total Expense remains 0', () {
      final originalTx = Transaction(
        id: 'tx_pay_edit',
        userId: 'user1',
        accountId: 'acc_hdfc',
        billLink: 'acc_icici_cc',
        type: 'pay_card',
        amount: 452034, // ₹4,520.34
        currency: 'INR',
        merchant: 'Pay CC',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final editedTx = originalTx.copyWith(
        amount: 500000, // ₹5,000.00
      );

      final updatedHdfc = FinancialCalculationService.calculateSingleAccountBalance(hdfcAccount, [editedTx]);
      final updatedCc = FinancialCalculationService.calculateSingleAccountBalance(iciciCardAccount, [editedTx]);

      expect(updatedHdfc.balance, equals(1000000 - 500000)); // ₹5,000.00
      expect(updatedCc.outstandingBalance, equals(2144554 - 500000)); // ₹16,445.54

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: [editedTx],
        accounts: [hdfcAccount, iciciCardAccount],
        selectedMonth: now,
      );

      expect(snapshot.expenses, equals(0.00));
    });

    test('TEST 8 — Delete Pay Card restores both account balances and leaves Total Expense unchanged', () {
      final payCardTx = Transaction(
        id: 'tx_pay_del',
        userId: 'user1',
        accountId: 'acc_hdfc',
        billLink: 'acc_icici_cc',
        type: 'pay_card',
        amount: 452034, // ₹4,520.34
        currency: 'INR',
        merchant: 'Pay CC',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final deletedTx = payCardTx.copyWith(
        deletedAt: Value(now),
      );

      final updatedHdfc = FinancialCalculationService.calculateSingleAccountBalance(hdfcAccount, [deletedTx]);
      final updatedCc = FinancialCalculationService.calculateSingleAccountBalance(iciciCardAccount, [deletedTx]);

      // Both balances restored
      expect(updatedHdfc.balance, equals(1000000));
      expect(updatedCc.outstandingBalance, equals(2144554));

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: [deletedTx],
        accounts: [hdfcAccount, iciciCardAccount],
        selectedMonth: now,
      );

      expect(snapshot.expenses, equals(0.00));
    });

    test('TEST 9 — Dashboard snapshot excludes Pay Card from monthly expenses', () {
      final expenseTx = Transaction(
        id: 'tx_real_exp',
        userId: 'user1',
        accountId: 'acc_hdfc',
        type: 'expense',
        amount: 2290199, // ₹22,901.99
        currency: 'INR',
        merchant: 'Rent & Groceries',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final payCardTx = Transaction(
        id: 'tx_cc_pay',
        userId: 'user1',
        accountId: 'acc_hdfc',
        billLink: 'acc_icici_cc',
        type: 'pay_card',
        amount: 452034, // ₹4,520.34
        currency: 'INR',
        merchant: 'Pay CC',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: [expenseTx, payCardTx],
        accounts: [hdfcAccount, iciciCardAccount],
        selectedMonth: now,
      );

      // Expenses must be ₹22,901.99, NOT ₹27,422.33
      expect(snapshot.expenses, equals(22901.99));
    });

    test('TEST 10 — Pay Card is excluded from category totals in analytics snapshot', () {
      final payCardTx = Transaction(
        id: 'tx_pay_cat',
        userId: 'user1',
        accountId: 'acc_hdfc',
        billLink: 'acc_icici_cc',
        categoryId: 'cat_bills',
        type: 'pay_card',
        amount: 452034,
        currency: 'INR',
        merchant: 'Pay CC',
        date: now,
        source: 'manual',
        isRecurring: false,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      final snapshot = FinancialCalculationService.calculateSnapshot(
        transactions: [payCardTx],
        accounts: [hdfcAccount, iciciCardAccount],
        selectedMonth: now,
      );

      expect(snapshot.categoryTotals, isEmpty);
      expect(snapshot.expenseTransactionCount, equals(0));
    });
  });
}
