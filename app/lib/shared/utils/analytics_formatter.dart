import 'package:intl/intl.dart';

class AnalyticsFormatter {
  static String formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final hasDecimals = (absAmount - absAmount.truncate()).abs() > 0.009;
    final formatter = NumberFormat.simpleCurrency(
      name: 'INR',
      decimalDigits: hasDecimals ? 2 : 0,
    );
    final formattedAbs = formatter.format(absAmount);
    return isNegative ? '-$formattedAbs' : formattedAbs;
  }

  static String formatCompactCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    String suffix = '';
    double value = absAmount;

    if (absAmount >= 1000000) {
      value = absAmount / 1000000.0;
      suffix = 'M';
    } else if (absAmount >= 1000) {
      value = absAmount / 1000.0;
      suffix = 'K';
    } else {
      return formatCurrency(amount);
    }

    final hasFractional = (value - value.truncate()).abs() > 0.09;
    final formatter = NumberFormat.simpleCurrency(
      name: 'INR',
      decimalDigits: hasFractional ? 1 : 0,
    );
    final formattedAbs = formatter.format(value);
    final result = '$formattedAbs$suffix';
    return isNegative ? '-$result' : result;
  }

  static String formatAxisValue(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    if (absAmount == 0) return '0';
    String suffix = '';
    double value = absAmount;

    if (absAmount >= 1000000) {
      value = absAmount / 1000000.0;
      suffix = ' M';
    } else if (absAmount >= 1000) {
      value = absAmount / 1000.0;
      suffix = ' K';
    } else {
      final hasFractional = (absAmount - absAmount.truncate()).abs() > 0.09;
      final formatted = absAmount.toStringAsFixed(hasFractional ? 1 : 0);
      return isNegative ? '-$formatted' : formatted;
    }

    final hasFractional = (value - value.truncate()).abs() > 0.09;
    final formattedValue = value.toStringAsFixed(hasFractional ? 1 : 0);
    final result = '$formattedValue$suffix';
    return isNegative ? '-$result' : result;
  }

  static String formatPercentage(double percentage, {int decimalDigits = 1}) {
    final hasFractional = (percentage - percentage.truncate()).abs() > 0.09;
    final formatted = percentage.toStringAsFixed(hasFractional ? decimalDigits : 0);
    return '$formatted%';
  }
}
