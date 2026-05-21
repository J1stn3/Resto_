import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/parse_utils.dart';
import '../widgets/money_text.dart';

class SalesBarChart extends StatelessWidget {
  const SalesBarChart({super.key, required this.data});

  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No sales data for this period', style: TextStyle(color: Colors.grey))),
      );
    }

    final revenues = data.map((r) => toJsonDouble(r['revenue'])).toList();
    final maxY = revenues.isEmpty ? 1.0 : revenues.reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 100 : maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  final raw = data[i]['date'] ?? data[i]['hour'] ?? data[i]['period'] ?? '${i + 1}';
                  final label = raw.toString();
                  final short = label.length > 8 ? label.substring(label.length - 8) : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(short, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(
            data.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: revenues[i],
                  color: Theme.of(context).colorScheme.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IncomeSummaryCard extends StatelessWidget {
  const IncomeSummaryCard({super.key, required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _col(context, 'Gross', toJsonDouble(summary['gross_income'])),
            _col(context, 'Tax', toJsonDouble(summary['tax_collected'])),
            _col(context, 'Net', toJsonDouble(summary['net_income'])),
          ],
        ),
      ),
    );
  }

  Widget _col(BuildContext context, String label, double amount) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        MoneyText(amount, bold: true, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
