import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../models/analytics_chart_data.dart';

class AnalyticsAggregationService {
  static Color getCategoryColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('food') || n.contains('dining') || n.contains('grocery') || n.contains('groceries')) {
      return const Color(0xFF4CAF50); // Green
    }
    if (n.contains('shop') || n.contains('shopping') || n.contains('clothes')) {
      return const Color(0xFF9C27B0); // Purple
    }
    if (n.contains('bill') || n.contains('utility') || n.contains('utilities') || n.contains('rent')) {
      return const Color(0xFFFF9800); // Orange
    }
    if (n.contains('recharge') || n.contains('mobile') || n.contains('phone')) {
      return const Color(0xFF2196F3); // Blue
    }
    if (n.contains('travel') || n.contains('cab') || n.contains('taxi') || n.contains('transport') || n.contains('flight')) {
      return const Color(0xFF00BCD4); // Cyan
    }
    if (n.contains('entertainment') || n.contains('movie') || n.contains('show') || n.contains('ott') || n.contains('netflix')) {
      return const Color(0xFFE91E63); // Pink
    }
    if (n.contains('fuel') || n.contains('petrol') || n.contains('diesel') || n.contains('gas')) {
      return const Color(0xFFFFEB3B); // Yellow
    }
    if (n.contains('medical') || n.contains('health') || n.contains('doctor') || n.contains('hospital') || n.contains('medicine')) {
      return const Color(0xFFF44336); // Red
    }
    if (n.contains('education') || n.contains('school') || n.contains('college') || n.contains('book')) {
      return const Color(0xFF009688); // Teal
    }
    final hash = name.hashCode.abs();
    final List<Color> palette = [
      const Color(0xFFE57373), const Color(0xFFF06292), const Color(0xFFBA68C8),
      const Color(0xFF9575CD), const Color(0xFF7986CB), const Color(0xFF64B5F6),
      const Color(0xFF4FC3F7), const Color(0xFF4DB6AC), const Color(0xFF81C784),
      const Color(0xFFD4E157), const Color(0xFFFFD54F), const Color(0xFFFFB74D),
    ];
    return palette[hash % palette.length];
  }

  static Color getIncomeSourceColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('salary') || n.contains('wage') || n.contains('paycheck')) {
      return const Color(0xFF4CAF50); // Green
    }
    if (n.contains('business') || n.contains('sales') || n.contains('revenue')) {
      return const Color(0xFFFF9800); // Orange
    }
    if (n.contains('investment') || n.contains('dividend') || n.contains('stock')) {
      return const Color(0xFF9C27B0); // Purple
    }
    if (n.contains('interest') || n.contains('bank') || n.contains('fixed deposit')) {
      return const Color(0xFF00BCD4); // Cyan
    }
    if (n.contains('freelance') || n.contains('gig') || n.contains('contract')) {
      return const Color(0xFF2196F3); // Blue
    }
    if (n.contains('rental') || n.contains('rent')) {
      return const Color(0xFFFFEB3B); // Yellow
    }
    final hash = name.hashCode.abs();
    final List<Color> palette = [
      const Color(0xFF81C784), const Color(0xFFFFB74D), const Color(0xFFBA68C8),
      const Color(0xFF4FC3F7), const Color(0xFF64B5F6), const Color(0xFFFFF176),
    ];
    return palette[hash % palette.length];
  }

  static List<ChartDatum> getCategoryChartData(List<Transaction> txs, List<Category> cats) {
    final Map<String, double> categorySpends = {};
    final Map<String, String> categoryIds = {};
    final Map<String, int> transactionCounts = {};
    double totalExpense = 0;

    for (var tx in txs) {
      if (FinancialCalculationService.isExpense(tx)) {
        final cat = cats.firstWhere(
          (c) => c.id == tx.categoryId,
          orElse: () => Category(
            id: 'unknown_expense',
            userId: '',
            name: 'Others',
            type: 'expense',
            usageCount: 0,
            isSystemDefault: true,
            createdAt: DateTime.now(),
          ),
        );
        categorySpends[cat.name] = (categorySpends[cat.name] ?? 0) + tx.amount / 100.0;
        categoryIds[cat.name] = cat.id;
        transactionCounts[cat.name] = (transactionCounts[cat.name] ?? 0) + 1;
        totalExpense += tx.amount / 100.0;
      }
    }

    final sortedEntries = categorySpends.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((e) {
      final name = e.key;
      final value = e.value;
      final pct = totalExpense > 0 ? (value / totalExpense * 100) : 0.0;
      return ChartDatum(
        id: categoryIds[name] ?? name,
        label: name,
        value: value,
        percentage: pct,
        color: getCategoryColor(name),
        transactionCount: transactionCounts[name] ?? 0,
      );
    }).toList();
  }

  static List<ChartDatum> getIncomeChartData(List<Transaction> txs, List<Category> cats) {
    final Map<String, double> categoryIncomes = {};
    final Map<String, String> categoryIds = {};
    final Map<String, int> transactionCounts = {};
    double totalIncome = 0;

    for (var tx in txs) {
      if (FinancialCalculationService.isIncome(tx)) {
        final cat = cats.firstWhere(
          (c) => c.id == tx.categoryId,
          orElse: () => Category(
            id: 'unknown_income',
            userId: '',
            name: 'Others',
            type: 'income',
            usageCount: 0,
            isSystemDefault: true,
            createdAt: DateTime.now(),
          ),
        );
        categoryIncomes[cat.name] = (categoryIncomes[cat.name] ?? 0) + tx.amount / 100.0;
        categoryIds[cat.name] = cat.id;
        transactionCounts[cat.name] = (transactionCounts[cat.name] ?? 0) + 1;
        totalIncome += tx.amount / 100.0;
      }
    }

    final sortedEntries = categoryIncomes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((e) {
      final name = e.key;
      final value = e.value;
      final pct = totalIncome > 0 ? (value / totalIncome * 100) : 0.0;
      return ChartDatum(
        id: categoryIds[name] ?? name,
        label: name,
        value: value,
        percentage: pct,
        color: getIncomeSourceColor(name),
        transactionCount: transactionCounts[name] ?? 0,
      );
    }).toList();
  }

  static List<ChartDatum> getPaymentChartData(List<Transaction> txs, List<PaymentMethod> pms) {
    final Map<String, double> paymentSpends = {};
    final Map<String, String> paymentIds = {};
    final Map<String, int> transactionCounts = {};
    double totalSpends = 0;

    final idToPmMap = {for (var pm in pms) pm.id: pm};

    for (var tx in txs) {
      if (tx.paymentMethodId != null) {
        final pm = idToPmMap[tx.paymentMethodId] ?? PaymentMethod(
          id: tx.paymentMethodId!,
          userId: '',
          name: 'Other',
          type: 'custom',
          usageCount: 0,
          createdAt: DateTime.now(),
        );
        paymentSpends[pm.name] = (paymentSpends[pm.name] ?? 0) + tx.amount / 100.0;
        paymentIds[pm.name] = pm.id;
        transactionCounts[pm.name] = (transactionCounts[pm.name] ?? 0) + 1;
        totalSpends += tx.amount / 100.0;
      }
    }

    final sortedEntries = paymentSpends.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    Color getPmColor(String name) {
      final n = name.toLowerCase();
      if (n.contains('upi')) return const Color(0xFF0066FF); // UPI -> Blue
      if (n.contains('credit') || n.contains('card')) return const Color(0xFF00BCD4); // Credit Card -> Cyan
      if (n.contains('debit')) return const Color(0xFF4CAF50); // Debit Card -> Green
      if (n.contains('cash')) return const Color(0xFFFF9800); // Cash -> Orange
      if (n.contains('bank') || n.contains('transfer')) return const Color(0xFF9C27B0); // Bank Transfer -> Purple
      final hash = name.hashCode.abs();
      final List<Color> palette = [
        const Color(0xFFBA68C8), const Color(0xFFFFF176), const Color(0xFFFFB74D), const Color(0xFFE57373)
      ];
      return palette[hash % palette.length];
    }

    return sortedEntries.map((e) {
      final name = e.key;
      final value = e.value;
      final pct = totalSpends > 0 ? (value / totalSpends * 100) : 0.0;
      return ChartDatum(
        id: paymentIds[name] ?? name,
        label: name,
        value: value,
        percentage: pct,
        color: getPmColor(name),
        transactionCount: transactionCounts[name] ?? 0,
      );
    }).toList();
  }

  static List<ChartDatum> getAccountChartData(List<Account> accounts) {
    double totalAbsoluteValue = 0;
    for (var acc in accounts) {
      if (acc.isActive == false) continue;
      totalAbsoluteValue += acc.balance.abs() / 100.0;
    }

    final List<ChartDatum> list = [];
    for (var acc in accounts) {
      if (acc.isActive == false) continue;
      final value = acc.balance.abs() / 100.0;
      final pct = totalAbsoluteValue > 0 ? (value / totalAbsoluteValue * 100) : 0.0;

      Color getAccountColor(String type, String name) {
        final t = type.toLowerCase();
        final n = name.toLowerCase();
        if (t.contains('cash') || n.contains('cash')) return const Color(0xFF4CAF50);
        if (t.contains('wallet') || n.contains('wallet') || n.contains('pay')) return const Color(0xFF9C27B0);
        if (t.contains('credit') || n.contains('credit') || n.contains('card')) return const Color(0xFFFF9800);
        if (t.contains('loan') || n.contains('loan')) return const Color(0xFFF44336);
        return const Color(0xFF00BCD4);
      }

      list.add(ChartDatum(
        id: acc.id,
        label: acc.name,
        value: acc.balance / 100.0,
        percentage: pct,
        color: getAccountColor(acc.type, acc.name),
        transactionCount: 0,
      ));
    }
    list.sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    return list;
  }
}
