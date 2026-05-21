import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/di/injection.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../../core/models/dining_table.dart';
import '../../../core/models/order_item.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/state_views.dart';

class OrderBuilder extends StatefulWidget {
  const OrderBuilder({
    super.key,
    required this.title,
    required this.onSubmit,
    this.fixedOrderType,
    this.requireTable = false,
    this.showOrderTypeSelector = true,
  });

  final String title;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;
  final String? fixedOrderType;
  final bool requireTable;
  final bool showOrderTypeSelector;

  @override
  State<OrderBuilder> createState() => _OrderBuilderState();
}

class _OrderBuilderState extends State<OrderBuilder> {
  final _api = sl<ApiClient>();
  List<Category> _categories = [];
  List<Product> _products = [];
  List<DiningTable> _tables = [];
  String? _selectedCategoryId;
  String _orderType = 'dine_in';
  String? _tableId;
  String? _customerName;
  final List<CartItem> _cart = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.fixedOrderType != null) _orderType = widget.fixedOrderType!;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cats = await _api.getCategories();
      final tables = await _api.getTables();
      final products = await _api.getProducts();
      setState(() {
        _categories = cats;
        _tables = tables;
        _products = products;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  List<Product> get _filtered {
    if (_selectedCategoryId == null) return _products.where((p) => p.isAvailable).toList();
    return _products.where((p) => p.categoryId == _selectedCategoryId && p.isAvailable).toList();
  }

  double get _taxRate => sl<AppSettings>().taxRate;

  double get _subtotal => _cart.fold(0.0, (s, i) => s + i.lineTotal);
  double get _tax => _subtotal * _taxRate;
  double get _total => _subtotal + _tax;

  void _addProduct(Product p) {
    final matches = _cart.where((c) => c.product.id == p.id);
    final existing = matches.isEmpty ? null : matches.first;
    setState(() {
      if (existing != null) {
        existing.quantity++;
      } else {
        _cart.add(CartItem(product: p.ref));
      }
    });
  }

  Future<void> _submit() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    if (widget.requireTable && _tableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a table')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit({
        'order_type': _orderType,
        if (_tableId != null) 'table_id': _tableId,
        if (_customerName != null && _customerName!.isNotEmpty) 'customer_name': _customerName,
        'items': _cart
            .map((c) => {
                  'product_id': c.product.id,
                  'quantity': c.quantity,
                  if (c.specialInstructions != null) 'special_instructions': c.specialInstructions,
                })
            .toList(),
      });
      setState(() {
        _cart.clear();
        _tableId = null;
        _customerName = null;
        _submitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order created successfully'), backgroundColor: Colors.green));
        await _load();
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));

    if (AppBreakpoints.isMobile(context)) {
      return _buildStackedLayout(context);
    }
    return _buildWideLayout(context);
  }

  Widget _buildOrderOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showOrderTypeSelector)
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'dine_in', label: Text('Dine In'), icon: Icon(Icons.table_restaurant)),
              ButtonSegment(value: 'takeout', label: Text('Takeout'), icon: Icon(Icons.shopping_bag)),
              ButtonSegment(value: 'delivery', label: Text('Delivery'), icon: Icon(Icons.delivery_dining)),
            ],
            selected: {_orderType},
            onSelectionChanged: (s) => setState(() => _orderType = s.first),
          ),
        if (widget.showOrderTypeSelector) const SizedBox(height: 12),
        if (_orderType == 'dine_in' || widget.requireTable)
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _tableId,
            decoration: const InputDecoration(labelText: 'Table', border: OutlineInputBorder()),
            items: _tables
                .map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        '${t.tableNumber}${t.location != null ? ' • ${t.location}' : ''}${t.isOccupied ? ' (busy)' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _tableId = v),
          ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(labelText: 'Customer name (optional)', border: OutlineInputBorder()),
          onChanged: (v) => _customerName = v,
        ),
      ],
    );
  }

  Widget _buildCategoryList(BuildContext context, {bool horizontal = false}) {
    final chipRadius = AppImageSizes.categoryChip(context);
    final listRadius = AppImageSizes.categoryList(context);
    final chips = [
      FilterChip(
        label: const Text('All'),
        selected: _selectedCategoryId == null,
        onSelected: (_) => setState(() => _selectedCategoryId = null),
      ),
      ..._categories.map((c) => FilterChip(
            avatar: CategoryImage(categoryName: c.name, radius: chipRadius, kind: CategoryImageKind.chip),
            label: Text(c.name),
            selected: _selectedCategoryId == c.id,
            onSelected: (_) => setState(() => _selectedCategoryId = c.id),
          )),
    ];

    if (horizontal) {
      return SizedBox(
        height: AppImageSizes.categoryChipBarHeight(context),
        child: ListView(scrollDirection: Axis.horizontal, children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c)).toList()),
      );
    }

    return ListView(
      children: [
        ListTile(
          selected: _selectedCategoryId == null,
          title: const Text('All'),
          onTap: () => setState(() => _selectedCategoryId = null),
        ),
        ..._categories.map((c) => ListTile(
              selected: _selectedCategoryId == c.id,
              title: Text(c.name, overflow: TextOverflow.ellipsis),
              leading: CategoryImage(categoryName: c.name, radius: listRadius, kind: CategoryImageKind.list),
              onTap: () => setState(() => _selectedCategoryId = c.id),
            )),
      ],
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    final columns = AppImageSizes.posGridColumns(context);
    final thumb = AppImageSizes.productThumb(context);
    final labelSize = AppImageSizes.productLabelSize(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: AppImageSizes.posTileAspectRatio(context, columns: columns),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final p = _filtered[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () => _addProduct(p),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: thumb * 0.15, vertical: thumb * 0.1),
              child: Row(
                children: [
                  ProductImage.adaptive(
                    imageUrl: p.imageUrl,
                    sku: p.sku,
                    categoryName: p.categoryName,
                    kind: ImageSizeKind.product,
                  ),
                  SizedBox(width: thumb * 0.15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: labelSize),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        MoneyText(p.price, bold: true, style: TextStyle(fontSize: labelSize)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartPanel(BuildContext context, {bool scrollable = false}) {
    final cartList = _cart.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: EmptyStateView(message: 'Tap a product to add to cart', icon: Icons.shopping_cart_outlined),
          )
        : ListView.builder(
            shrinkWrap: !scrollable,
            physics: scrollable ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: _cart.length,
            itemBuilder: (_, i) {
              final item = _cart[i];
              return ListTile(
                dense: true,
                leading: ProductImage.adaptive(
                  imageUrl: item.product.imageUrl,
                  sku: item.product.sku,
                  categoryName: item.product.categoryName,
                  kind: ImageSizeKind.cart,
                ),
                title: Text(item.product.name, overflow: TextOverflow.ellipsis),
                subtitle: MoneyText(item.lineTotal),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () {
                        setState(() {
                          if (item.quantity > 1) {
                            item.quantity--;
                          } else {
                            _cart.removeAt(i);
                          }
                        });
                      },
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => setState(() => item.quantity++),
                    ),
                  ],
                ),
              );
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Cart (${_cart.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (scrollable) Expanded(child: cartList) else cartList,
        const Divider(),
        _row('Subtotal', _subtotal),
        _row('Tax (${(_taxRate * 100).toStringAsFixed(0)}%)', _tax),
        const Divider(),
        _row('Total', _total, bold: true),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(_submitting ? 'Placing…' : 'Place Order'),
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 180, child: _buildCategoryList(context)),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOrderOptions(),
                const SizedBox(height: 12),
                Expanded(child: _buildProductGrid(context)),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(width: 300, child: Padding(padding: const EdgeInsets.all(12), child: _buildCartPanel(context, scrollable: true))),
      ],
    );
  }

  Widget _buildStackedLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.point_of_sale_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          _buildOrderOptions(),
          const SizedBox(height: 12),
          _buildCategoryList(context, horizontal: true),
          const SizedBox(height: 12),
          _buildProductGrid(context),
          const SizedBox(height: 16),
          _buildCartPanel(context),
        ],
      ),
    );
  }

  Widget _row(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Flexible(child: Text(label)), MoneyText(amount, bold: bold)],
      ),
    );
  }
}
