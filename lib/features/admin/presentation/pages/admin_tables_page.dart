import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/dining_table.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/state_views.dart';

class AdminTablesPage extends StatefulWidget {
  const AdminTablesPage({super.key});

  @override
  State<AdminTablesPage> createState() => _AdminTablesPageState();
}

class _AdminTablesPageState extends State<AdminTablesPage> {
  final _api = sl<ApiClient>();
  List<DiningTable> _tables = [];
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
    await _load();
  }

  Future<void> _deleteTable(DiningTable t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete table ${t.tableNumber}?'),
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
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(), child: const Icon(Icons.add)),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? ErrorStateView(message: _error!, onRetry: _load)
              : _tables.isEmpty
                  ? const EmptyStateView(message: 'No tables configured')
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: AppBreakpoints.gridColumns(context, mobile: 2, desktop: 3),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _tables.length,
                      itemBuilder: (_, i) {
                        final t = _tables[i];
                        final occupied = t.isOccupied;
                        final statusColor = occupied ? AppTheme.warning : AppTheme.accent;
                        return Card(
                          child: InkWell(
                            onTap: () => _showForm(table: t),
                            onLongPress: () => _deleteTable(t),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(t.tableNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(occupied ? Icons.person_rounded : Icons.event_seat_rounded, color: statusColor),
                                      ),
                                    ],
                                  ),
                                  Text(t.location ?? 'Main Floor'),
                                  const Spacer(),
                                  Text('${t.seatingCapacity} seats'),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      occupied ? 'Occupied' : 'Available',
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
  late final TextEditingController _number;
  late final TextEditingController _location;
  late final TextEditingController _capacity;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(text: widget.table?.tableNumber ?? '');
    _location = TextEditingController(text: widget.table?.location ?? 'Main Floor');
    _capacity = TextEditingController(text: '${widget.table?.seatingCapacity ?? 4}');
  }

  @override
  void dispose() {
    _number.dispose();
    _location.dispose();
    _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.table == null ? 'Add Table' : 'Edit Table'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _number, decoration: const InputDecoration(labelText: 'Table number')),
            TextField(controller: _location, decoration: const InputDecoration(labelText: 'Location / zone')),
            TextField(controller: _capacity, decoration: const InputDecoration(labelText: 'Seating capacity'), keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final cap = int.tryParse(_capacity.text) ?? 4;
            Navigator.pop(context, {
              'table_number': _number.text.trim(),
              'location': _location.text.trim(),
              'seating_capacity': cap,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
