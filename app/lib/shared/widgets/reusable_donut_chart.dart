import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../features/analytics/presentation/models/analytics_chart_data.dart';

class ReusableDonutChart extends StatelessWidget {
  final List<ChartDatum> data;
  final String? selectedId;
  final Function(String id) onSelected;
  final String centerTitle;
  final double centerValue;
  final bool isPrivate;

  const ReusableDonutChart({
    super.key,
    required this.data,
    required this.selectedId,
    required this.onSelected,
    required this.centerTitle,
    required this.centerValue,
    required this.isPrivate,
  });

  String _formatMoneyDouble(double amountInCents) {
    final double amount = amountInCents / 100.0;
    return NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, color: Colors.white24, size: 48),
            SizedBox(height: 12),
            Text(
              'No expenses in this period',
              style: TextStyle(color: Colors.white30, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final List<PieChartSectionData> sections = [];
    
    for (int i = 0; i < data.length; i++) {
      final datum = data[i];
      final isSelected = selectedId == datum.id;
      final baseColor = datum.color;
      
      Color sectionColor;
      if (selectedId != null && selectedId!.isNotEmpty) {
        sectionColor = isSelected ? baseColor : baseColor.withOpacity(0.3);
      } else {
        sectionColor = baseColor;
      }

      final double radius = isSelected ? 48.0 : 38.0;

      sections.add(PieChartSectionData(
        color: sectionColor,
        value: datum.value,
        title: isSelected 
            ? (isPrivate ? '**%' : '${datum.percentage.toStringAsFixed(0)}%')
            : '',
        radius: radius,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ));
    }

    final centerDatum = (selectedId != null && selectedId!.isNotEmpty) 
        ? data.firstWhere((d) => d.id == selectedId, orElse: () => data.first) 
        : null;
    final String label = centerDatum != null ? centerDatum.label.toUpperCase() : centerTitle.toUpperCase();
    final String amount = isPrivate 
        ? '₹••••' 
        : (centerDatum != null ? _formatMoneyDouble(centerDatum.value) : _formatMoneyDouble(centerValue));
    final String? pctText = (centerDatum != null && !isPrivate) ? '${centerDatum.percentage.toStringAsFixed(1)}%' : null;

    final pieChartWidget = PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 46,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            if (event is FlTapUpEvent) {
              if (response == null || response.touchedSection == null) {
                onSelected('');
                return;
              }
              final touchedIdx = response.touchedSection!.touchedSectionIndex;
              if (touchedIdx >= 0 && touchedIdx < data.length) {
                onSelected(data[touchedIdx].id);
              } else {
                onSelected('');
              }
            }
          },
        ),
      ),
    );

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          pieChartWidget,
          IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (pctText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    pctText,
                    style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
