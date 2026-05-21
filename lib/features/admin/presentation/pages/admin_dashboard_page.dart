import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/sales_chart.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/utils/parse_utils.dart';
import '../../../../core/widgets/state_views.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _api = sl<ApiClient>();
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _income;
  List<Map<String, dynamic>> _salesToday = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await _api.getDashboardStats();
      final income = await _api.getIncomeReport('today');
      final sales = await _api.getSalesReport('today');
      setState(() {
        _stats = stats;
        _income = income;
        _salesToday = sales;
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
    if (_loading) return const AppLoadingView(message: 'Loading dashboard…');
    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _load);
    }

    final s = _stats ?? {};
    final summary = (_income?['summary'] as Map<String, dynamic>?) ?? {};
    final cols = AppBreakpoints.isMobile(context) ? 2 : 4;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: AppBreakpoints.pagePadding(context),
        children: [
          const PageSectionTitle('Quick actions', subtitle: 'Jump to common tasks'),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: [
              QuickActionCard(label: 'New Order', icon: Icons.add_shopping_cart_rounded, color: AppTheme.primary, onTap: () => context.go('/admin/pos')),
              QuickActionCard(label: 'Kitchen', icon: Icons.kitchen_rounded, color: AppTheme.warning, onTap: () => context.go('/admin/kitchen')),
              QuickActionCard(label: 'Payments', icon: Icons.payments_rounded, color: AppTheme.accent, onTap: () => context.go('/admin/pos')),
              QuickActionCard(label: 'Reports', icon: Icons.insights_rounded, color: const Color(0xFF8B5CF6), onTap: () => context.go('/admin/reports')),
            ],
          ),
          const SizedBox(height: 28),
          const PageSectionTitle('Overview', subtitle: 'Today at a glance'),
          const SizedBox(height: 14),
          MetricCard(title: 'Today Orders', value: '${s['today_orders'] ?? 0}', icon: Icons.receipt_long_rounded, color: AppTheme.primary),
          const SizedBox(height: 10),
          MetricCard(
            title: 'Today Revenue',
            amount: toJsonDouble(s['today_revenue']),
            icon: Icons.payments_rounded,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 10),
          MetricCard(title: 'Active Orders', value: '${s['active_orders'] ?? 0}', icon: Icons.pending_actions_rounded, color: AppTheme.warning),
          const SizedBox(height: 10),
          MetricCard(title: 'Occupied Tables', value: '${s['occupied_tables'] ?? 0}', icon: Icons.table_restaurant_rounded, color: const Color(0xFF8B5CF6)),
          const SizedBox(height: 28),
          const PageSectionTitle("Today's sales"),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: SalesBarChart(data: _salesToday))),
          const SizedBox(height: 24),
          const PageSectionTitle('Today income'),
          const SizedBox(height: 12),
          IncomeSummaryCard(summary: summary),
        ],
      ),
    );
  }
}
