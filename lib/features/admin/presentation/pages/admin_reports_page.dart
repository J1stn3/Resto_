import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/sales_chart.dart';
import '../../../../core/utils/parse_utils.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/state_views.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> with SingleTickerProviderStateMixin {
  final _api = sl<ApiClient>();
  late TabController _tabs;
  String _period = 'today';
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _income;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sales = await _api.getSalesReport(_period);
      final orders = await _api.getOrdersReport();
      final income = await _api.getIncomeReport(_period);
      setState(() {
        _sales = sales;
        _orders = orders;
        _income = income;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = (_income?['summary'] as Map<String, dynamic>?) ?? {};
    final totalRevenue = _sales.fold<double>(0, (s, r) => s + toJsonDouble(r['revenue']));

    return Column(
      children: [
        Padding(
          padding: AppBreakpoints.pagePadding(context).copyWith(top: 8, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _period,
                  decoration: const InputDecoration(labelText: 'Period', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'today', child: Text('Today')),
                    DropdownMenuItem(value: 'week', child: Text('This Week')),
                    DropdownMenuItem(value: 'month', child: Text('This Month')),
                  ],
                  onChanged: (v) {
                    setState(() => _period = v!);
                    _load();
                  },
                ),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: AppBreakpoints.isPhone(context),
          tabs: const [Tab(text: 'Sales'), Tab(text: 'Orders'), Tab(text: 'Income')],
        ),
        Expanded(
          child: _loading
          ? const AppLoadingView(message: 'Loading reports…')
          : _error != null
              ? ErrorStateView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    ListView(
                      padding: AppBreakpoints.pagePadding(context),
                      children: [
                        Card(
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.trending_up_rounded, color: AppTheme.accent),
                            ),
                            title: const Text('Total revenue (period)'),
                            trailing: MoneyText(totalRevenue, bold: true, style: Theme.of(context).textTheme.titleLarge),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(child: Padding(padding: const EdgeInsets.all(16), child: SalesBarChart(data: _sales))),
                        const SizedBox(height: 16),
                        ..._sales.map((r) => Card(
                              child: ListTile(
                                title: Text('${r['date'] ?? r['hour'] ?? '—'}'),
                                trailing: MoneyText(toJsonDouble(r['revenue']), bold: true),
                                subtitle: Text('${r['order_count'] ?? 0} orders'),
                              ),
                            )),
                        if (_sales.isEmpty) const EmptyStateView(message: 'No sales data for this period'),
                      ],
                    ),
                    ListView(
                      padding: AppBreakpoints.pagePadding(context),
                      children: [
                        const Text('Orders by status (today)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        ..._orders.map((r) => Card(
                              child: ListTile(
                                title: Text('${r['status']}'),
                                trailing: Text('${r['count']} orders', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: MoneyText(toJsonDouble(r['avg_amount'])),
                              ),
                            )),
                        if (_orders.isEmpty) const EmptyStateView(message: 'No order breakdown data'),
                      ],
                    ),
                    ListView(
                      padding: AppBreakpoints.pagePadding(context),
                      children: [
                        IncomeSummaryCard(summary: summary),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _row('Total Orders', '${summary['total_orders'] ?? 0}'),
                                _row('Average per Order', null, amount: _avgOrder(summary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  double _avgOrder(Map<String, dynamic> summary) {
    final orders = toJsonInt(summary['total_orders']);
    final gross = toJsonDouble(summary['gross_income']);
    return orders > 0 ? gross / orders : 0;
  }

  Widget _row(String label, String? text, {double? amount}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          amount != null ? MoneyText(amount, bold: true) : Text(text ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
