import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/dining_table.dart';
import '../../../../core/models/order.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/sales_chart.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/utils/parse_utils.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/table_status_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _api = sl<ApiClient>();
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _income;
  List<Map<String, dynamic>> _salesToday = [];
  List<Order> _liveOrders = [];
  List<DiningTable> _tables = [];
  bool _loading = true;
  String? _error;
  DateTime? _lastUpdated;

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
      final results = await Future.wait([
        _api.getDashboardStats(),
        _api.getSalesReport('today'),
        _api.getIncomeReport('today'),
        _api.getOrders(),
        _api.getTables(),
      ]);
      final orders = results[3] as List<Order>;
      final active = orders
          .where((o) => !['completed', 'cancelled'].contains(o.status))
          .toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _salesToday = results[1] as List<Map<String, dynamic>>;
        _income = results[2] as Map<String, dynamic>;
        _liveOrders = active.take(5).toList();
        _tables = results[4] as List<DiningTable>;
        _loading = false;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('ApiException: ', '');
        _loading = false;
      });
    }
  }

  double _salesRevenueTotal() =>
      _salesToday.fold(0.0, (sum, row) => sum + toJsonDouble(row['revenue']));

  int _salesOrderTotal() =>
      _salesToday.fold<int>(0, (sum, row) => sum + toJsonInt(row['order_count']));

  String? _chartCaption() {
    if (_salesToday.isEmpty) return null;
    return '${formatPeso(_salesRevenueTotal())} across ${_salesOrderTotal()} orders · hourly breakdown';
  }

  String? _peakHourLabel() {
    if (_salesToday.isEmpty) return null;
    var best = _salesToday.first;
    var bestRev = toJsonDouble(best['revenue']);
    for (final row in _salesToday.skip(1)) {
      final rev = toJsonDouble(row['revenue']);
      if (rev > bestRev) {
        bestRev = rev;
        best = row;
      }
    }
    if (bestRev <= 0) return null;
    final raw = best['date'] ?? best['hour'] ?? best['period'];
    if (raw == null) return null;
    final text = raw.toString();
    try {
      final dt = DateTime.parse(text.replaceFirst(' ', 'T'));
      return 'Busiest around ${DateFormat.jm().format(dt)}';
    } catch (_) {
      return 'Busiest period: $text';
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
    final settings = sl<AppSettings>();
    final auth = context.watch<AuthBloc>().state;
    final userName = auth is AuthAuthenticated ? auth.user.name : 'Admin';
    final isWide = !AppBreakpoints.isMobile(context);
    final metricCols = AppBreakpoints.gridColumns(context, phoneCols: 2, tabletCols: 2, desktopCols: 4);

    final todayOrders = toJsonInt(s['today_orders']);
    final todayRevenue = toJsonDouble(s['today_revenue']);
    final activeOrders = toJsonInt(s['active_orders']);
    final totalTables = toJsonInt(s['total_tables'], _tables.length);
    final occupiedTables = toJsonInt(s['occupied_tables']);
    final availableTables = toJsonInt(s['available_tables'], totalTables - occupiedTables);
    final avgOrder = todayOrders > 0 ? todayRevenue / todayOrders : 0.0;
    final netIncome = toJsonDouble(summary['net_income']);
    final peakLabel = _peakHourLabel();

    return RefreshIndicator(
      onRefresh: _load,
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 400),
        child: ListView(
          padding: AppBreakpoints.pagePadding(context),
          children: [
            _DashboardWelcomeHeader(
              restaurantName: settings.restaurantName,
              userName: userName,
              lastUpdated: _lastUpdated,
              onRefresh: _load,
            ),
            const SizedBox(height: 20),
            _RevenueHeroCard(
              revenue: todayRevenue,
              orders: todayOrders,
              avgOrder: avgOrder,
              netIncome: netIncome,
            ),
            if (activeOrders > 0) ...[
              const SizedBox(height: 14),
              _OperationsStrip(
                activeOrders: activeOrders,
                occupiedTables: occupiedTables,
              ),
            ],
            const SizedBox(height: 24),
            const PageSectionTitle('Overview', subtitle: 'Key metrics for today'),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: metricCols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: AppBreakpoints.isPhone(context) ? 1.05 : (isWide ? 1.35 : 1.15),
              children: [
                CompactMetricTile(
                  title: 'Today\'s orders',
                  value: '$todayOrders',
                  icon: Icons.receipt_long_rounded,
                  color: AppTheme.primary,
                  subtitle: activeOrders > 0 ? '$activeOrders in progress' : 'All caught up',
                ),
                CompactMetricTile(
                  title: 'Active orders',
                  value: '$activeOrders',
                  icon: Icons.pending_actions_rounded,
                  color: AppTheme.warning,
                  subtitle: activeOrders > 0 ? 'Kitchen or payment' : 'None waiting',
                ),
                CompactMetricTile(
                  title: 'Tables available',
                  value: totalTables > 0 ? '$availableTables / $totalTables' : '$availableTables',
                  icon: Icons.table_restaurant_rounded,
                  color: const Color(0xFF8B5CF6),
                  subtitle: occupiedTables > 0 ? '$occupiedTables occupied' : 'All tables free',
                ),
                CompactMetricTile(
                  title: 'Avg. ticket',
                  amount: avgOrder,
                  icon: Icons.analytics_outlined,
                  color: AppTheme.accent,
                  subtitle: todayOrders > 0 ? 'Per completed order' : 'No orders yet',
                ),
              ],
            ),
            if (_tables.isNotEmpty) ...[
              const SizedBox(height: 28),
              _DashboardTablesSection(tables: _tables),
            ],
            if (_liveOrders.isNotEmpty) ...[
              const SizedBox(height: 28),
              _LiveOrdersSection(orders: _liveOrders),
            ],
            const SizedBox(height: 28),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _SalesSection(
                      data: _salesToday,
                      caption: _chartCaption(),
                      peakLabel: peakLabel,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _IncomeSection(summary: summary),
                  ),
                ],
              )
            else ...[
              _SalesSection(
                data: _salesToday,
                caption: _chartCaption(),
                peakLabel: peakLabel,
              ),
              const SizedBox(height: 20),
              _IncomeSection(summary: summary),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DashboardWelcomeHeader extends StatelessWidget {
  const _DashboardWelcomeHeader({
    required this.restaurantName,
    required this.userName,
    required this.lastUpdated,
    required this.onRefresh,
  });

  final String restaurantName;
  final String userName;
  final DateTime? lastUpdated;
  final VoidCallback onRefresh;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final updated = lastUpdated != null ? DateFormat.jm().format(lastUpdated!) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurantName,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_greeting()}, $userName',
                style: (AppBreakpoints.isPhone(context)
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineSmall)
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(dateLabel, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              if (updated != null) ...[
                const SizedBox(height: 4),
                Text('Updated $updated', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh dashboard',
        ),
      ],
    );
  }
}

class _OperationsStrip extends StatelessWidget {
  const _OperationsStrip({required this.activeOrders, required this.occupiedTables});

  final int activeOrders;
  final int occupiedTables;

  @override
  Widget build(BuildContext context) {
    final message =
        '$activeOrders order${activeOrders == 1 ? '' : 's'} in progress'
        '${occupiedTables > 0 ? ' · $occupiedTables table${occupiedTables == 1 ? '' : 's'} busy' : ''}';

    return Card(
      color: AppTheme.warning.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: AppTheme.warning, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

class _RevenueHeroCard extends StatelessWidget {
  const _RevenueHeroCard({
    required this.revenue,
    required this.orders,
    required this.avgOrder,
    required this.netIncome,
  });

  final double revenue;
  final int orders;
  final double avgOrder;
  final double netIncome;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.today_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Today', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (netIncome > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Net ${formatPeso(netIncome)}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Total revenue',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  formatPeso(revenue),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroStatChip(icon: Icons.receipt_long_rounded, label: '$orders orders'),
                  _HeroStatChip(icon: Icons.local_atm_rounded, label: '${formatPeso(avgOrder)} avg'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DashboardTablesSection extends StatelessWidget {
  const _DashboardTablesSection({required this.tables});

  final List<DiningTable> tables;

  @override
  Widget build(BuildContext context) {
    final available = tables.where((t) => t.isAvailable).length;
    final occupied = tables.length - available;
    final preview = tables.take(6).toList();
    final cols = AppBreakpoints.gridColumns(context, phoneCols: 1, tabletCols: 2, desktopCols: 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageSectionTitle(
          'Tables',
          subtitle: '$available available · $occupied occupied · ${tables.length} total',
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: AppBreakpoints.isPhone(context) ? 1.2 : 1.15,
          ),
          itemCount: preview.length,
          itemBuilder: (_, i) => TableStatusCard(table: preview[i], compact: true),
        ),
        if (tables.length > preview.length)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${tables.length - preview.length} more — open Tables in the menu',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
      ],
    );
  }
}

class _LiveOrdersSection extends StatelessWidget {
  const _LiveOrdersSection({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageSectionTitle('Live orders', subtitle: 'Open tickets right now'),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < orders.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _LiveOrderTile(order: orders[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveOrderTile extends StatelessWidget {
  const _LiveOrderTile({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final table = order.tableNumber != null ? 'Table ${order.tableNumber}' : order.orderType;
    final time = order.createdAt != null ? DateFormat.jm().format(order.createdAt!) : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
        child: Text(
          order.orderNumber.length > 3
              ? order.orderNumber.substring(order.orderNumber.length - 3)
              : order.orderNumber,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary),
        ),
      ),
      title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: AppBreakpoints.isPhone(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$table${time.isNotEmpty ? ' · $time' : ''}', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    MoneyText(order.totalAmount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    StatusBadge(order.status),
                  ],
                ),
              ],
            )
          : Text(
              '$table${time.isNotEmpty ? ' · $time' : ''}',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
      trailing: AppBreakpoints.isPhone(context)
          ? StatusBadge(order.status)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(order.totalAmount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                StatusBadge(order.status),
              ],
            ),
    );
  }
}

class _SalesSection extends StatelessWidget {
  const _SalesSection({required this.data, this.caption, this.peakLabel});
  final List<Map<String, dynamic>> data;
  final String? caption;
  final String? peakLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageSectionTitle('Sales activity', subtitle: 'Revenue by hour today'),
        if (peakLabel != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(peakLabel!, style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SalesBarChart(data: data, caption: caption),
          ),
        ),
      ],
    );
  }
}

class _IncomeSection extends StatelessWidget {
  const _IncomeSection({required this.summary});
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageSectionTitle('Income summary', subtitle: 'Completed orders today'),
        const SizedBox(height: 12),
        IncomeSummaryCard(summary: summary),
      ],
    );
  }
}
