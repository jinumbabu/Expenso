import 'package:flutter/material.dart';

class ChartDatum {
  final String id;
  final String label;
  final double value;
  final double percentage;
  final Color color;
  final int transactionCount;

  ChartDatum({
    required this.id,
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
    required this.transactionCount,
  });

  @override
  String toString() {
    return 'ChartDatum(id: $id, label: $label, value: $value, percentage: $percentage)';
  }
}
