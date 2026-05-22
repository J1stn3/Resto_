import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/parse_utils.dart';
import 'money_text.dart';
import 'responsive.dart';

class SalesBarChart extends StatelessWidget {
  const SalesBarChart({super.key, required this.data, this.caption});

  final List<Map<String, dynamic>> data;
  final String? caption;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (caption != null) ...[
          Text(caption!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          const SizedBox(height: 12),
        ],
        SizedBox(
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
    ),
      ],
    );
  }
}

class IncomeSummaryCard extends StatelessWidget {
  const IncomeSummaryCard({super.key, required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final gross = toJsonDouble(summary['gross_income']);
    final tax = toJsonDouble(summary['tax_collected']);
    final net = toJsonDouble(summary['net_income']);
    final orders = summary['total_orders'];
    final orderLabel = orders != null ? '$orders completed orders' : null;

    final cols = [
      _col(context, 'Gross', gross, Icons.account_balance_wallet_outlined, const Color(0xFF2563EB)),
      _col(context, 'Tax', tax, Icons.receipt_long_outlined, const Color(0xFFF59E0B)),
      _col(context, 'Net', net, Icons.savings_outlined, const Color(0xFF10B981)),
    ];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppBreakpoints.isPhone(context) ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (orderLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(orderLabel, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
              ),
            if (AppBreakpoints.isPhone(context))
              ...cols.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c))
            else
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(child: cols[0]),
                    VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
                    Expanded(child: cols[1]),
                    VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
                    Expanded(child: cols[2]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _col(BuildContext context, String label, double amount, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 6),
          MoneyText(amount, bold: true, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
