import 'package:flutter/material.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/category.dart';
import '../../../../core/models/product.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/state_views.dart';

class AdminMenuPage extends StatefulWidget {
  const AdminMenuPage({super.key});

  @override
  State<AdminMenuPage> createState() => _AdminMenuPageState();
}

class _AdminMenuPageState extends State<AdminMenuPage> with SingleTickerProviderStateMixin {
  final _api = sl<ApiClient>();
  late TabController _tabs;
  List<Category> _categories = [];
  List<Product> _products = [];
  bool _loading = true;
  String _search = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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
      final cats = await _api.getAdminCategories();
      final prods = await _api.getAdminProducts(search: _search.isEmpty ? null : _search);
      setState(() {
        _categories = cats;
        _products = prods;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    if (_search.isEmpty) return _products;
    final q = _search.toLowerCase();
    return _products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _addCategory() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _CategoryFormDialog(),
    );
    if (result == null) return;
    await _api.createCategory({
      'name': result['name'],
      if (result['description']?.isNotEmpty == true) 'description': result['description'],
      'sort_order': _categories.length,
    });
    await _load();
  }

  Future<void> _editCategory(Category c) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _CategoryFormDialog(initial: c),
    );
    if (result == null) return;
    await _api.updateCategory(c.id, {
      'name': result['name'],
      'description': result['description'],
    });
    await _load();
  }

  Future<void> _addProduct() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a category first')));
      return;
    }
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ProductFormDialog(categories: _categories),
    );
    if (result == null) return;
    await _api.createProduct(result);
    await _load();
  }

  Future<void> _editProduct(Product p) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ProductFormDialog(categories: _categories, product: p),
    );
    if (result == null) return;
    await _api.updateProduct(p.id, result);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            isScrollable: AppBreakpoints.isPhone(context),
            tabs: const [Tab(text: 'Products'), Tab(text: 'Categories')],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabs.index == 0 ? _addProduct() : _addCategory(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    return _loading
          ? const AppLoadingView()
          : _error != null
              ? ErrorStateView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: AppBreakpoints.pagePadding(context),
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Search products',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => setState(() => _search = v),
                            onSubmitted: (_) => _load(),
                          ),
                        ),
                        Expanded(
                          child: _filteredProducts.isEmpty
                              ? const EmptyStateView(message: 'No products found')
                              : ListView.builder(
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (_, i) {
                                    final p = _filteredProducts[i];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      child: ListTile(
                                        leading: ProductImage.adaptive(
                                          imageUrl: p.imageUrl,
                                          sku: p.sku,
                                          categoryName: p.categoryName,
                                          kind: ImageSizeKind.list,
                                        ),
                                        title: Text(p.name),
                                        subtitle: Text('${p.categoryName ?? ''} • ${p.sku ?? '—'} • ${p.isAvailable ? 'Available' : 'Unavailable'}'),
                                        trailing: MoneyText(p.price, bold: true),
                                        onTap: () => _editProduct(p),
                                        onLongPress: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              title: Text('Delete ${p.name}?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                                FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                                              ],
                                            ),
                                          );
                                          if (ok == true) {
                                            await _api.deleteProduct(p.id);
                                            await _load();
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                    _categories.isEmpty
                        ? EmptyStateView(message: 'No categories yet', actionLabel: 'Add category', onAction: _addCategory)
                        : ListView.builder(
                            itemCount: _categories.length,
                            itemBuilder: (_, i) {
                              final c = _categories[i];
                              return ListTile(
                                leading: CategoryImage(
                                  categoryName: c.name,
                                  kind: CategoryImageKind.list,
                                ),
                                title: Text(c.name),
                                subtitle: Text(c.description ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('Delete ${c.name}?'),
                                        content: const Text('Products in this category may be affected.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      await _api.deleteCategory(c.id);
                                      await _load();
                                    }
                                  },
                                ),
                                onTap: () => _editCategory(c),
                              );
                            },
                          ),
                  ],
                );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.initial});
  final Category? initial;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _desc;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _desc = TextEditingController(text: widget.initial?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'New Category' : 'Edit Category'),
      content: SizedBox(
        width: AppBreakpoints.dialogContentWidth(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {'name': _name.text.trim(), 'description': _desc.text.trim()}),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({required this.categories, this.product});
  final List<Category> categories;
  final Product? product;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _desc;
  late final TextEditingController _sku;
  late String _categoryId;
  late bool _available;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p?.price.toStringAsFixed(2) ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _categoryId = p?.categoryId ?? widget.categories.first.id;
    _available = p?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _desc.dispose();
    _sku.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'New Product' : 'Edit Product'),
      content: SizedBox(
        width: AppBreakpoints.dialogContentWidth(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: _price, decoration: const InputDecoration(labelText: 'Price (₱)'), keyboardType: TextInputType.number),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _categoryId = v!),
              ),
              TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: _sku, decoration: const InputDecoration(labelText: 'SKU')),
              SwitchListTile(
                title: const Text('Available'),
                value: _available,
                onChanged: (v) => setState(() => _available = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final price = double.tryParse(_price.text);
            if (_name.text.trim().isEmpty || price == null) return;
            Navigator.pop(context, {
              'name': _name.text.trim(),
              'price': price,
              'category_id': _categoryId,
              'description': _desc.text.trim(),
              'sku': _sku.text.trim(),
              'is_available': _available,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
