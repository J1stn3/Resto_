import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/user.dart';
import '../../../../core/widgets/state_views.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _api = sl<ApiClient>();
  List<User> _users = [];
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
      final users = await _api.getUsers();
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addUser() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (c) => const _UserFormDialog(),
    );
    if (result == null) return;
    await _api.createUser({
      'name': result['name'],
      'email': result['email'],
      'password': result['password'],
    });
    await _load();
  }

  Future<void> _editUser(User u) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => _UserFormDialog(user: u),
    );
    if (result == null) return;
    await _api.updateUser(u.id, result);
    await _load();
  }

  Future<void> _toggleActive(User u) async {
    await _api.updateUser(u.id, {'is_active': !u.isActive});
    await _load();
  }

  Future<void> _deleteUser(User u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete ${u.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _api.deleteUser(u.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: _addUser, child: const Icon(Icons.person_add)),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? ErrorStateView(message: _error!, onRetry: _load)
              : _users.isEmpty
                  ? const EmptyStateView(message: 'No users yet')
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (_, i) {
                        final u = _users[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                              child: Text(
                                u.name.isNotEmpty ? u.name[0].toUpperCase() : 'A',
                                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(u.name),
                            subtitle: Text(u.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(u.isActive ? 'Active' : 'Inactive'),
                                  backgroundColor: u.isActive ? Colors.green.shade100 : Colors.grey.shade300,
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _editUser(u);
                                    if (v == 'toggle') _toggleActive(u);
                                    if (v == 'delete') _deleteUser(u);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'toggle', child: Text(u.isActive ? 'Deactivate' : 'Activate')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({this.user});
  final User? user;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user?.name ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.user != null;
    return AlertDialog(
      title: Text(editing ? 'Edit User' : 'New User'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            TextField(
              controller: _password,
              decoration: InputDecoration(labelText: editing ? 'New password (optional)' : 'Password'),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final data = <String, dynamic>{
              'name': _name.text.trim(),
              'email': _email.text.trim(),
            };
            if (_password.text.isNotEmpty) data['password'] = _password.text;
            if (editing && _password.text.isEmpty) {
              data.remove('password');
            } else if (!editing && _password.text.isEmpty) {
              return;
            }
            Navigator.pop(context, data);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
