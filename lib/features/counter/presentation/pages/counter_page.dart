import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/order.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/utils/parse_utils.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../ordering/widgets/order_builder.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> with SingleTickerProviderStateMixin {
  final _api = sl<ApiClient>();
  final _paymentTabKey = GlobalKey<_PaymentTabState>();
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  void _goToPayment(String orderId) {
    _tabs.animateTo(1);
    void select() => _paymentTabKey.currentState?.reloadAndSelect(orderId);
    if (_paymentTabKey.currentState != null) {
      select();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => select());
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: AppBreakpoints.isPhone(context),
          tabs: [
            Tab(
              text: 'Create Order',
              icon: AppBreakpoints.isPhone(context) ? null : const Icon(Icons.add_shopping_cart),
            ),
            Tab(
              text: 'Payment',
              icon: AppBreakpoints.isPhone(context) ? null : const Icon(Icons.payment),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              OrderBuilder(
                title: 'Counter',
                onSubmit: (body) => _api.createOrder(body),
                onOrderPlaced: _goToPayment,
              ),
              _PaymentTab(key: _paymentTabKey),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentTab extends StatefulWidget {
  const _PaymentTab({super.key});

  @override
  State<_PaymentTab> createState() => _PaymentTabState();
}

class _PaymentTabState extends State<_PaymentTab> {
  final _api = sl<ApiClient>();
  List<Order> _orders = [];
  Order? _selected;
  Map<String, dynamic>? _summary;
  String _method = 'cash';
  final _amountCtrl = TextEditingController();
  bool _loading = true;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> reload() => _load();

  Future<void> reloadAndSelect(String orderId) async {
    await _load();
    Order? match;
    for (final o in _orders) {
      if (o.id == orderId) {
        match = o;
        break;
      }
    }
    if (match != null) {
      await _selectOrder(match);
      return;
    }
    try {
      final o = await _api.getOrder(orderId);
      if (!mounted) return;
      if (!['completed', 'cancelled'].contains(o.status)) {
        await _selectOrder(o);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _api.getOrders();
      if (!mounted) return;
      setState(() {
        final open = all.where((o) => !['completed', 'cancelled'].contains(o.status)).toList();
        open.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        _orders = open;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectOrder(Order o) async {
    setState(() {
      _selected = o;
      _summary = null;
    });
    try {
      final full = await _api.getOrder(o.id);
      final summary = await _api.getPaymentSummary(o.id);
      if (mounted) {
        setState(() {
          _selected = full;
          _summary = summary;
          final remaining = toJsonDouble(summary['remaining_amount'], full.totalAmount);
          _amountCtrl.text = remaining.toStringAsFixed(2);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _pay({bool fullRemaining = false}) async {
    if (_selected == null) return;
    final remaining = toJsonDouble(_summary?['remaining_amount'], _selected!.totalAmount);
    final amount = fullRemaining ? remaining : (double.tryParse(_amountCtrl.text) ?? remaining);
    if (amount <= 0) return;

    setState(() => _paying = true);
    try {
      await _api.processPayment(_selected!.id, _method, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment processed'), backgroundColor: Colors.green),
        );
        _selected = null;
        _summary = null;
        _amountCtrl.clear();
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);

    if (_orders.isEmpty) {
      return const EmptyStateView(message: 'No orders awaiting payment', icon: Icons.receipt_long);
    }

    return Column(
      children: [
        if (_selected != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _selected = null;
                _summary = null;
              }),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to orders'),
            ),
          ),
        if (_selected == null)
          Expanded(
            child: ListView.builder(
              padding: AppBreakpoints.pagePadding(context),
              itemCount: _orders.length,
              itemBuilder: (_, i) {
                final o = _orders[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 22),
                    ),
                    title: Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: AppBreakpoints.isPhone(context)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${o.orderType} • Table ${o.tableNumber ?? '—'}'),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  MoneyText(o.totalAmount, bold: true),
                                  const SizedBox(width: 8),
                                  StatusBadge(o.status),
                                ],
                              ),
                            ],
                          )
                        : Text('${o.orderType} • Table ${o.tableNumber ?? '—'}'),
                    trailing: AppBreakpoints.isPhone(context)
                        ? const Icon(Icons.chevron_right)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              MoneyText(o.totalAmount, bold: true),
                              StatusBadge(o.status),
                            ],
                          ),
                    onTap: () => _selectOrder(o),
                  ),
                );
              },
            ),
          )
        else
          Expanded(child: SingleChildScrollView(padding: AppBreakpoints.pagePadding(context), child: _buildPaymentPanel())),
      ],
    );
  }

  Widget _buildPaymentPanel() {
    final o = _selected!;
    final total = toJsonDouble(_summary?['total_amount'], o.totalAmount);
    final paid = toJsonDouble(_summary?['paid_amount']);
    final remaining = toJsonDouble(_summary?['remaining_amount'], total);
    final fullyPaid = _summary?['is_fully_paid'] == true;

    return Padding(
      padding: AppBreakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(o.orderNumber, style: Theme.of(context).textTheme.titleLarge),
              ),
              StatusBadge(o.status),
            ],
          ),
          Text('${o.orderType} • ${o.customerName ?? 'Walk-in'} • Table ${o.tableNumber ?? '—'}'),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Order items', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...o.items.map(
                  (item) => ListTile(
                    dense: true,
                    title: Text('${item.quantity}x ${item.productName ?? 'Item'}'),
                    trailing: MoneyText(item.totalPrice),
                  ),
                ),
                if (o.items.isEmpty) const ListTile(title: Text('No line items loaded')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _payRow('Order total', total),
                  _payRow('Paid', paid, color: Colors.green),
                  _payRow('Remaining', remaining, bold: true, color: remaining > 0 ? Colors.orange : Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!fullyPaid) ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _method,
              decoration: const InputDecoration(labelText: 'Payment method', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                DropdownMenuItem(value: 'debit_card', child: Text('Debit Card')),
                DropdownMenuItem(value: 'digital_wallet', child: Text('Digital Wallet')),
              ],
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Payment amount (₱)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _paying ? null : () => _pay(fullRemaining: true),
                child: const Text('Pay Remaining'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _paying ? null : () => _pay(),
                child: _paying
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Process Payment'),
              ),
            ),
          ] else
            const Card(
              color: Color(0xFFE8F5E9),
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('This order is fully paid'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _payRow(String label, double amount, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          MoneyText(amount, bold: bold, style: TextStyle(color: color, fontSize: bold ? 18 : 14)),
        ],
      ),
    );
  }
}
