import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/dining_table.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/table_status_card.dart';

class AdminTablesPage extends StatefulWidget {
  const AdminTablesPage({super.key});

  @override
  State<AdminTablesPage> createState() => _AdminTablesPageState();
}

class _AdminTablesPageState extends State<AdminTablesPage> {
  final _api = sl<ApiClient>();
  final _searchCtrl = TextEditingController();
  List<DiningTable> _tables = [];
  String _statusFilter = 'all';
  String? _locationFilter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tables = await _api.getAdminTables();
      setState(() {
        _tables = tables;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<DiningTable> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _tables.where((t) {
      if (_statusFilter == 'available' && t.isOccupied) return false;
      if (_statusFilter == 'occupied' && !t.isOccupied) return false;
      if (_locationFilter != null && t.zoneLabel != _locationFilter) return false;
      if (q.isEmpty) return true;
      return t.displayName.toLowerCase().contains(q) ||
          t.tableNumber.toLowerCase().contains(q) ||
          t.zoneLabel.toLowerCase().contains(q);
    }).toList();
  }

  List<String> get _locations {
    final set = <String>{};
    for (final t in _tables) {
      set.add(t.zoneLabel);
    }
    final list = set.toList()..sort();
    return list;
  }

  int get _availableCount => _tables.where((t) => t.isAvailable).length;
  int get _occupiedCount => _tables.where((t) => t.isOccupied).length;
  int get _totalSeats => _tables.fold(0, (s, t) => s + t.seatingCapacity);
  int get _seatsAvailable => _tables.fold(0, (s, t) => s + t.seatsAvailable);

  Future<void> _showForm({DiningTable? table}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _TableFormDialog(table: table),
    );
    if (result == null) return;
    if (table == null) {
      await _api.createTable(result);
    } else {
      await _api.updateTable(table.id, result);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(table == null ? 'Table added' : 'Table updated'), backgroundColor: Colors.green),
      );
    }
    await _load();
  }

  Future<void> _releaseTable(DiningTable t) async {
    if (!t.isOccupied) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Mark ${t.displayName} available?'),
        content: Text(
          'This clears the occupied flag for table #${t.tableNumber}. '
          'Close or complete the linked order in POS if it is still open.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Mark available')),
        ],
      ),
    );
    if (ok == true) {
      await _api.updateTable(t.id, {'is_occupied': false});
      await _load();
    }
  }

  Future<void> _showTableActions(DiningTable t) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit table'),
              onTap: () => Navigator.pop(c, 'edit'),
            ),
            if (t.isOccupied)
              ListTile(
                leading: const Icon(Icons.event_available_rounded),
                title: const Text('Mark as available'),
                onTap: () => Navigator.pop(c, 'release'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.danger),
              title: const Text('Delete table', style: TextStyle(color: AppTheme.danger)),
              onTap: () => Navigator.pop(c, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'edit') await _showForm(table: t);
    if (action == 'release') await _releaseTable(t);
    if (action == 'delete') await _deleteTable(t);
  }

  Future<void> _deleteTable(DiningTable t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete ${t.displayName}?'),
        content: Text('Table #${t.tableNumber} will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _api.deleteTable(t.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add table'),
      ),
      body: _loading
          ? const AppLoadingView(message: 'Loading tables…')
          : _error != null
              ? ErrorStateView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: AppBreakpoints.pagePadding(context).copyWith(top: 12, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const PageSectionTitle(
                                'Dining tables',
                                subtitle: 'Name, number, seats, and live availability',
                              ),
                              const SizedBox(height: 14),
                              _SummaryRow(
                                total: _tables.length,
                                available: _availableCount,
                                occupied: _occupiedCount,
                                seatsAvailable: _seatsAvailable,
                                totalSeats: _totalSeats,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _searchCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Search name, number, or zone…',
                                  prefixIcon: const Icon(Icons.search),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: _searchCtrl.text.isEmpty
                                      ? null
                                      : IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            setState(() {});
                                          },
                                        ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _FilterChip(
                                    label: 'All (${_tables.length})',
                                    selected: _statusFilter == 'all',
                                    onSelected: () => setState(() => _statusFilter = 'all'),
                                  ),
                                  _FilterChip(
                                    label: 'Available ($_availableCount)',
                                    selected: _statusFilter == 'available',
                                    color: AppTheme.accent,
                                    onSelected: () => setState(() => _statusFilter = 'available'),
                                  ),
                                  _FilterChip(
                                    label: 'Occupied ($_occupiedCount)',
                                    selected: _statusFilter == 'occupied',
                                    color: AppTheme.warning,
                                    onSelected: () => setState(() => _statusFilter = 'occupied'),
                                  ),
                                ],
                              ),
                              if (_locations.length > 1) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _FilterChip(
                                      label: 'All zones',
                                      selected: _locationFilter == null,
                                      onSelected: () => setState(() => _locationFilter = null),
                                    ),
                                    ..._locations.map(
                                      (loc) => _FilterChip(
                                        label: loc,
                                        selected: _locationFilter == loc,
                                        onSelected: () => setState(() => _locationFilter = loc),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_filtered.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateView(
                            message: 'No tables match your filters',
                            icon: Icons.table_restaurant_outlined,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: AppBreakpoints.pagePadding(context).copyWith(top: 8, bottom: 88),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: AppBreakpoints.gridColumns(context, phoneCols: 1, tabletCols: 2, desktopCols: 3),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: AppBreakpoints.isPhone(context) ? 1.15 : 1.05,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final t = _filtered[i];
                                return TableStatusCard(
                                  table: t,
                                  onTap: () => _showForm(table: t),
                                  onLongPress: () => _showTableActions(t),
                                );
                              },
                              childCount: _filtered.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.total,
    required this.available,
    required this.occupied,
    required this.seatsAvailable,
    required this.totalSeats,
  });

  final int total;
  final int available;
  final int occupied;
  final int seatsAvailable;
  final int totalSeats;

  @override
  Widget build(BuildContext context) {
    final cols = AppBreakpoints.gridColumns(context, phoneCols: 2, tabletCols: 4, desktopCols: 4);
    final items = [
      _SummaryTile('Total tables', '$total', Icons.table_restaurant_rounded, AppTheme.primary),
      _SummaryTile('Available', '$available', Icons.check_circle_outline_rounded, AppTheme.accent),
      _SummaryTile('Occupied', '$occupied', Icons.person_rounded, AppTheme.warning),
      _SummaryTile('Seats free', '$seatsAvailable / $totalSeats', Icons.event_seat_rounded, const Color(0xFF8B5CF6)),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: cols,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: AppBreakpoints.isPhone(context) ? 1.6 : 2.2,
      children: items,
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: (color ?? AppTheme.primary).withValues(alpha: 0.18),
      checkmarkColor: color ?? AppTheme.primary,
    );
  }
}

class _TableFormDialog extends StatefulWidget {
  const _TableFormDialog({this.table});
  final DiningTable? table;

  @override
  State<_TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends State<_TableFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _number;
  late final TextEditingController _location;
  late final TextEditingController _capacity;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.table?.tableName ?? widget.table?.displayName ?? '');
    _number = TextEditingController(text: widget.table?.tableNumber ?? '');
    _location = TextEditingController(text: widget.table?.location ?? 'Main Floor');
    _capacity = TextEditingController(text: '${widget.table?.seatingCapacity ?? 4}');
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _location.dispose();
    _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.table != null;
    return AlertDialog(
      title: Text(editing ? 'Edit table' : 'Add table'),
      content: SizedBox(
        width: AppBreakpoints.dialogContentWidth(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Table name',
                  hintText: 'e.g. Window Booth A',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _number,
                decoration: const InputDecoration(
                  labelText: 'Table number',
                  hintText: 'e.g. T01',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Zone / location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _capacity,
                decoration: const InputDecoration(
                  labelText: 'Seats (sets)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final number = _number.text.trim();
            if (number.isEmpty) return;
            final cap = int.tryParse(_capacity.text) ?? 4;
            Navigator.pop(context, {
              'table_name': _name.text.trim(),
              'table_number': number,
              'location': _location.text.trim(),
              'seating_capacity': cap < 1 ? 1 : cap,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
