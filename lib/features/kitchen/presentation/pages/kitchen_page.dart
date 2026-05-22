import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/order.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';

class KitchenPage extends StatefulWidget {
  const KitchenPage({super.key});

  @override
  State<KitchenPage> createState() => _KitchenPageState();
}

class _KitchenPageState extends State<KitchenPage> {
  final _api = sl<ApiClient>();
  List<Order> _orders = [];
  Timer? _timer;
  bool _autoRefresh = true;
  String _statusFilter = 'all';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_autoRefresh) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _error = null);
    try {
      final orders = await _api.getKitchenOrders();
      if (mounted) setState(() => _orders = orders);
    } catch (e) {
      if (mounted && !silent) setState(() => _error = e.toString());
    }
  }

  List<Order> get _filtered {
    if (_statusFilter == 'all') return _orders;
    return _orders.where((o) => o.status == _statusFilter).toList();
  }

  Future<void> _setOrderStatus(Order o, String status) async {
    await _api.updateOrderStatus(o.id, status);
    await _load(silent: true);
  }

  Future<void> _setItemStatus(Order o, String itemId, String status) async {
    await _api.updateItemStatus(o.id, itemId, status);
    await _load(silent: true);
  }

  int _gridColumns(BuildContext context) {
    if (AppBreakpoints.isPhone(context)) return 1;
    if (AppBreakpoints.isMobile(context)) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final cols = _gridColumns(context);
    final aspect = AppBreakpoints.isPhone(context) ? 0.85 : 0.75;

    return ColoredBox(
      color: AppTheme.darkBg,
      child: Column(
        children: [
          Material(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: AppBreakpoints.pagePadding(context).copyWith(top: 8, bottom: 8),
              child: AppBreakpoints.isPhone(context)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.kitchen_rounded, color: AppTheme.accent, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Kitchen Display',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                              onPressed: () => _load(),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Auto-refresh', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          value: _autoRefresh,
                          onChanged: (v) => setState(() => _autoRefresh = v),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.kitchen_rounded, color: AppTheme.accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Kitchen Display',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                        const Text('Auto-refresh', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Switch(value: _autoRefresh, onChanged: (v) => setState(() => _autoRefresh = v)),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          onPressed: () => _load(),
                        ),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in ['all', 'confirmed', 'preparing', 'ready'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1)),
                        selected: _statusFilter == f,
                        onSelected: (_) => setState(() => _statusFilter = f),
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(color: _statusFilter == f ? Colors.white : Colors.white70),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _error != null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : _filtered.isEmpty
              ? const EmptyStateView(
                  message: 'No active kitchen orders',
                  icon: Icons.restaurant,
                )
              : GridView.builder(
                  padding: AppBreakpoints.pagePadding(context),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: aspect,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _KitchenCard(
                    order: _filtered[i],
                    onOrderStatus: _setOrderStatus,
                    onItemStatus: _setItemStatus,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _KitchenCard extends StatelessWidget {
  const _KitchenCard({required this.order, required this.onOrderStatus, required this.onItemStatus});
  final Order order;
  final Future<void> Function(Order, String) onOrderStatus;
  final Future<void> Function(Order, String, String) onItemStatus;

  static const _itemStatuses = ['pending', 'preparing', 'ready'];

  @override
  Widget build(BuildContext context) {
    final waitMin = order.createdAt != null ? DateTime.now().difference(order.createdAt!).inMinutes : 0;
    final urgent = waitMin > 15;

    return Card(
      color: urgent ? const Color(0xFF7F1D1D) : AppTheme.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: urgent ? AppTheme.danger : AppTheme.darkCard, width: urgent ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                StatusBadge(order.status),
              ],
            ),
            Text(
              '${order.orderType.replaceAll('_', ' ')} • Table ${order.tableNumber ?? '—'} • ${waitMin}m wait',
              style: TextStyle(color: urgent ? Colors.white : Colors.white70),
            ),
            if (order.notes != null && order.notes!.isNotEmpty)
              Text('Note: ${order.notes}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView(
                children: order.items.map((item) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${item.quantity}x ${item.productName ?? 'Item'}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(item.status, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
                      onSelected: (s) => onItemStatus(order, item.id, s),
                      itemBuilder: (_) => _itemStatuses
                          .map((s) => PopupMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1))))
                          .toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
            Row(
              children: [
                if (order.status == 'confirmed')
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: () => onOrderStatus(order, 'preparing'),
                      child: const Text('Start Prep'),
                    ),
                  ),
                if (order.status == 'preparing') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                      onPressed: () => onOrderStatus(order, 'ready'),
                      child: const Text('Order Ready'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
