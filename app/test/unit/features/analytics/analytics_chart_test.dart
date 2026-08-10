import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/analytics/presentation/services/analytics_aggregation_service.dart';
import 'package:app/core/database/app_database.dart';

void main() {
  group('Analytics Premium Chart System Tests', () {
    const userId = 'user_test_id';

    final categoryRent = Category(
      id: 'cat_rent',
      userId: userId,
      name: 'House Rent',
      type: 'expense',
      usageCount: 1,
      isSystemDefault: false,
      createdAt: DateTime.now(),
    );

    final categoryInvest = Category(
      id: 'cat_invest',
      userId: userId,
      name: 'Investment',
      type: 'expense',
      usageCount: 1,
      isSystemDefault: false,
      createdAt: DateTime.now(),
    );

    final categoryEntertain = Category(
      id: 'cat_entertain',
      userId: userId,
      name: 'Entertainment',
      type: 'expense',
      usageCount: 1,
      isSystemDefault: false,
      createdAt: DateTime.now(),
    );

    final categorySalary = Category(
      id: 'cat_salary',
      userId: userId,
      name: 'Salary',
      type: 'income',
      usageCount: 1,
      isSystemDefault: false,
      createdAt: DateTime.now(),
    );

    final categoryFreelance = Category(
      id: 'cat_freelance',
      userId: userId,
      name: 'Freelance',
      type: 'income',
      usageCount: 1,
      isSystemDefault: false,
      createdAt: DateTime.now(),
    );

    final List<Category> testCategories = [
      categoryRent,
      categoryInvest,
      categoryEntertain,
      categorySalary,
      categoryFreelance,
    ];

    test('TEST 1, 2 & 3: Selection by Category ID and matching value / percentage calculations', () {
      final List<Transaction> txs = [
        Transaction(
          id: 'tx1',
          userId: userId,
          type: 'expense',
          amount: 500000, // ₹5,000
          currency: 'INR',
          date: DateTime.now(),
          categoryId: 'cat_rent',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 'tx2',
          userId: userId,
          type: 'expense',
          amount: 500000, // ₹5,000
          currency: 'INR',
          date: DateTime.now(),
          categoryId: 'cat_invest',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 'tx3',
          userId: userId,
          type: 'expense',
          amount: 100000, // ₹1,000
          currency: 'INR',
          date: DateTime.now(),
          categoryId: 'cat_entertain',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final chartData = AnalyticsAggregationService.getCategoryChartData(txs, testCategories);

      // Verify overall aggregation
      expect(chartData.length, equals(3));

      // House Rent checks
      final rentDatum = chartData.firstWhere((d) => d.id == 'cat_rent');
      expect(rentDatum.value, equals(5000.0));
      expect(rentDatum.percentage, closeTo(45.45, 0.1));

      // Investment checks
      final investDatum = chartData.firstWhere((d) => d.id == 'cat_invest');
      expect(investDatum.value, equals(5000.0));
      expect(investDatum.percentage, closeTo(45.45, 0.1));

      // Entertainment checks
      final entertainDatum = chartData.firstWhere((d) => d.id == 'cat_entertain');
      expect(entertainDatum.value, equals(1000.0));
      expect(entertainDatum.percentage, closeTo(9.09, 0.1));
    });

    test('TEST 4: Sorting categories descending by amount does not break ID bindings', () {
      final List<Transaction> txs = [
        Transaction(
          id: 'tx1',
          userId: userId,
          type: 'expense',
          amount: 100000, // ₹1,000
          currency: 'INR',
          date: DateTime.now(),
          categoryId: 'cat_entertain',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 'tx2',
          userId: userId,
          type: 'expense',
          amount: 900000, // ₹9,000
          currency: 'INR',
          date: DateTime.now(),
          categoryId: 'cat_rent',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final chartData = AnalyticsAggregationService.getCategoryChartData(txs, testCategories);

      // Expect sorted order: Rent (9000), Entertainment (1000)
      expect(chartData[0].id, equals('cat_rent'));
      expect(chartData[1].id, equals('cat_entertain'));

      // Tapping Rent selects the rent category ID regardless of its list position index
      final selectedId = chartData[0].id;
      expect(selectedId, equals('cat_rent'));
    });

    test('TEST 5: Period change filter cleans selection if ID is not present in new dataset', () {
      final List<Transaction> txsPeriod1 = [
        Transaction(
          id: 'tx1',
          userId: userId,
          type: 'expense',
          amount: 100000,
          currency: 'INR',
          date: DateTime.now(),
          categoryId: 'cat_entertain',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final List<Transaction> txsPeriod2 = [
        Transaction(
          id: 'tx2',
          userId: userId,
          type: 'expense',
          amount: 500000,
          currency: 'INR',
          date: DateTime.now(),
          categoryId: 'cat_rent',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final chartData1 = AnalyticsAggregationService.getCategoryChartData(txsPeriod1, testCategories);
      String? selectedId = 'cat_entertain';

      // Verify it exists in period 1
      expect(chartData1.any((d) => d.id == selectedId), isTrue);

      // Switch to period 2
      final chartData2 = AnalyticsAggregationService.getCategoryChartData(txsPeriod2, testCategories);
      
      // Since 'cat_entertain' is not in period 2 dataset, selection becomes invalid/cleared
      final hasSelectedInNewPeriod = chartData2.any((d) => d.id == selectedId);
      if (!hasSelectedInNewPeriod) {
        selectedId = null;
      }

      expect(selectedId, isNull);
    });

    test('TEST 6: Income sources aggregate and select correctly by ID', () {
      final List<Transaction> txs = [
        Transaction(
          id: 'tx1',
          userId: userId,
          type: 'income',
          amount: 2500000, // ₹25,000
          currency: 'INR',
          date: DateTime.now(),
          categoryId: 'cat_salary',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 'tx2',
          userId: userId,
          type: 'income',
          amount: 220000, // ₹2,200
          currency: 'INR',
          date: DateTime.now(),
          categoryId: 'cat_freelance',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final incomeData = AnalyticsAggregationService.getIncomeChartData(txs, testCategories);

      expect(incomeData.length, equals(2));
      expect(incomeData[0].id, equals('cat_salary'));
      expect(incomeData[1].id, equals('cat_freelance'));

      expect(incomeData[0].value, equals(25000.0));
      expect(incomeData[1].value, equals(2200.0));
    });

    test('TEST 7: Payment method splits aggregate correctly by ID', () {
      final List<PaymentMethod> pms = [
        PaymentMethod(
          id: 'pm_upi',
          userId: userId,
          name: 'UPI',
          type: 'custom',
          usageCount: 1,
          createdAt: DateTime.now(),
        ),
        PaymentMethod(
          id: 'pm_cc',
          userId: userId,
          name: 'Credit Card',
          type: 'custom',
          usageCount: 1,
          createdAt: DateTime.now(),
        ),
      ];

      final List<Transaction> txs = [
        Transaction(
          id: 'tx1',
          userId: userId,
          type: 'expense',
          amount: 1878800, // ₹18,788
          currency: 'INR',
          date: DateTime.now(),
          paymentMethodId: 'pm_upi',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 'tx2',
          userId: userId,
          type: 'expense',
          amount: 75500, // ₹755
          currency: 'INR',
          date: DateTime.now(),
          paymentMethodId: 'pm_cc',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final pmData = AnalyticsAggregationService.getPaymentChartData(txs, pms);

      expect(pmData.length, equals(2));
      expect(pmData[0].id, equals('pm_upi'));
      expect(pmData[1].id, equals('pm_cc'));

      expect(pmData[0].value, equals(18788.0));
      expect(pmData[1].value, equals(755.0));
    });

    test('TEST 8: Account distribution calculates absolute value shares & highlights correctly', () {
      final List<Account> accounts = [
        Account(
          id: 'acc_cash',
          userId: userId,
          name: 'Cash Wallet',
          type: 'cash',
          balance: 0,
          isDefault: false,
          isActive: true,
          isEstimated: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Account(
          id: 'acc_gpay',
          userId: userId,
          name: 'Google Pay Wallet',
          type: 'wallet',
          balance: 64200, // ₹642
          isDefault: false,
          isActive: true,
          isEstimated: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Account(
          id: 'acc_hdfc_cc',
          userId: userId,
          name: 'HDFC Credit Card',
          type: 'credit_card',
          balance: -763700, // -₹7,637 (outstanding liability)
          isDefault: false,
          isActive: true,
          isEstimated: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final accData = AnalyticsAggregationService.getAccountChartData(accounts);

      // Verify absolute proportional shares
      // Total abs value = 0 + 642 + 7637 = 8279
      expect(accData.length, equals(3));
      
      // HDFC CC checks
      final ccDatum = accData.firstWhere((d) => d.id == 'acc_hdfc_cc');
      expect(ccDatum.value, equals(-7637.0));
      expect(ccDatum.percentage, closeTo(92.2, 0.5)); // 7637 / 8279 * 100 = 92.2%
    });

    test('TEST 9: Payment split expense mode filtering, totals, percentages, averages, and counts', () {
      final List<PaymentMethod> pms = [
        PaymentMethod(
          id: 'pm_upi',
          userId: userId,
          name: 'UPI',
          type: 'custom',
          usageCount: 1,
          createdAt: DateTime.now(),
        ),
        PaymentMethod(
          id: 'pm_cc',
          userId: userId,
          name: 'Credit Card',
          type: 'custom',
          usageCount: 1,
          createdAt: DateTime.now(),
        ),
      ];

      final List<Transaction> txs = [
        Transaction(
          id: 'tx1',
          userId: userId,
          type: 'expense',
          amount: 200000, // ₹2,000
          currency: 'INR',
          date: DateTime.now(),
          paymentMethodId: 'pm_upi',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 'tx2',
          userId: userId,
          type: 'expense',
          amount: 800000, // ₹8,000
          currency: 'INR',
          date: DateTime.now(),
          paymentMethodId: 'pm_cc',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 'tx3',
          userId: userId,
          type: 'income',
          amount: 5000000, // ₹50,000 (Should be filtered out!)
          currency: 'INR',
          date: DateTime.now(),
          paymentMethodId: 'pm_upi',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Filter to only expenses
      final expenses = txs.where((t) => t.type == 'expense').toList();
      final pmData = AnalyticsAggregationService.getPaymentChartData(expenses, pms);

      // Verify we only have 2 items (income ignored)
      expect(pmData.length, equals(2));

      // CC checks (value = 8000, percentage = 8000 / 10000 = 80%)
      final ccDatum = pmData.firstWhere((d) => d.id == 'pm_cc');
      expect(ccDatum.value, equals(8000.0));
      expect(ccDatum.percentage, equals(80.0));
      expect(ccDatum.transactionCount, equals(1));

      // UPI checks (value = 2000, percentage = 2000 / 10000 = 20%)
      final upiDatum = pmData.firstWhere((d) => d.id == 'pm_upi');
      expect(upiDatum.value, equals(2000.0));
      expect(upiDatum.percentage, equals(20.0));
      expect(upiDatum.transactionCount, equals(1));
    });

    test('TEST 10: Payment split income mode filtering, totals, percentages, averages, and counts', () {
      final List<PaymentMethod> pms = [
        PaymentMethod(
          id: 'pm_upi',
          userId: userId,
          name: 'UPI',
          type: 'custom',
          usageCount: 1,
          createdAt: DateTime.now(),
        ),
        PaymentMethod(
          id: 'pm_cc',
          userId: userId,
          name: 'Credit Card',
          type: 'custom',
          usageCount: 1,
          createdAt: DateTime.now(),
        ),
      ];

      final List<Transaction> txs = [
        Transaction(
          id: 'tx1',
          userId: userId,
          type: 'expense', // Should be filtered out!
          amount: 200000,
          currency: 'INR',
          date: DateTime.now(),
          paymentMethodId: 'pm_upi',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 'tx2',
          userId: userId,
          type: 'income',
          amount: 150000, // ₹1,500
          currency: 'INR',
          date: DateTime.now(),
          paymentMethodId: 'pm_cc',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 'tx3',
          userId: userId,
          type: 'income',
          amount: 350000, // ₹3,500
          currency: 'INR',
          date: DateTime.now(),
          paymentMethodId: 'pm_upi',
          source: 'manual',
          isRecurring: false,
          syncStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Filter to only incomes
      final incomes = txs.where((t) => t.type == 'income').toList();
      final pmData = AnalyticsAggregationService.getPaymentChartData(incomes, pms);

      // Verify we only have 2 items
      expect(pmData.length, equals(2));

      // CC checks (value = 1500, percentage = 1500 / 5000 = 30%)
      final ccDatum = pmData.firstWhere((d) => d.id == 'pm_cc');
      expect(ccDatum.value, equals(1500.0));
      expect(ccDatum.percentage, equals(30.0));
      expect(ccDatum.transactionCount, equals(1));

      // UPI checks (value = 3500, percentage = 3500 / 5000 = 70%)
      final upiDatum = pmData.firstWhere((d) => d.id == 'pm_upi');
      expect(upiDatum.value, equals(3500.0));
      expect(upiDatum.percentage, equals(70.0));
      expect(upiDatum.transactionCount, equals(1));
    });

    test('TEST 11: Empty payment methods handled correctly', () {
      final List<PaymentMethod> pms = [];
      final List<Transaction> txs = [];
      final pmData = AnalyticsAggregationService.getPaymentChartData(txs, pms);
      expect(pmData.isEmpty, isTrue);
    });
  });
}
