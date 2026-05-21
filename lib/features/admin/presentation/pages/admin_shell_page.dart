import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AdminShellPage extends StatelessWidget {
  const AdminShellPage({super.key, required this.child});
  final Widget child;

  static const _items = [
    _Nav('/admin/dashboard', 'Home', Icons.home_outlined, Icons.home_rounded),
    _Nav('/admin/pos', 'POS', Icons.point_of_sale_outlined, Icons.point_of_sale_rounded),
    _Nav('/admin/kitchen', 'Kitchen', Icons.kitchen_outlined, Icons.kitchen_rounded),
    _Nav('/admin/menu', 'Menu', Icons.restaurant_menu_outlined, Icons.restaurant_menu_rounded),
    _Nav('/admin/tables', 'Tables', Icons.table_restaurant_outlined, Icons.table_restaurant_rounded),
    _Nav('/admin/reports', 'Reports', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
    _Nav('/admin/users', 'Users', Icons.people_outline, Icons.people_rounded),
    _Nav('/admin/settings', 'Settings', Icons.settings_outlined, Icons.settings_rounded),
  ];

  static const _bottomNavPaths = [
    '/admin/dashboard',
    '/admin/pos',
    '/admin/kitchen',
    '/admin/reports',
  ];

  int _bottomIndex(String location) {
    for (var i = 0; i < _bottomNavPaths.length; i++) {
      if (location.startsWith(_bottomNavPaths[i])) return i;
    }
    return 0;
  }

  String _title(String location) {
    for (final i in _items) {
      if (location.startsWith(i.path)) return i.label;
    }
    return 'Restaurant POS';
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final auth = context.watch<AuthBloc>().state;
    final userName = auth is AuthAuthenticated ? auth.user.name : 'User';
    final email = auth is AuthAuthenticated ? auth.user.email : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(location)),
      ),
      drawer: Drawer(
        child: _DrawerContent(location: location, userName: userName, email: email, items: _items),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex(location),
        onDestinationSelected: (i) => context.go(_bottomNavPaths[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale_rounded), label: 'POS'),
          NavigationDestination(icon: Icon(Icons.kitchen_outlined), selectedIcon: Icon(Icons.kitchen_rounded), label: 'Kitchen'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
        ],
      ),
    );
  }
}

class _DrawerContent extends StatelessWidget {
  const _DrawerContent({
    required this.location,
    required this.userName,
    required this.email,
    required this.items,
  });

  final String location;
  final String userName;
  final String email;
  final List<_Nav> items;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: AppImageSizes.drawerAvatar(context),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Text(userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              if (email.isNotEmpty)
                Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text('MENU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1)),
        ),
        ...items.map((i) {
          final selected = location.startsWith(i.path);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: ListTile(
              leading: Icon(selected ? i.selectedIcon : i.icon, color: selected ? AppTheme.primary : null),
              title: Text(i.label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
              selected: selected,
              selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
              onTap: () {
                Scaffold.of(context).closeDrawer();
                context.go(i.path);
              },
            ),
          );
        }),
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            title: const Text('Log out', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            onTap: () {
              Scaffold.of(context).closeDrawer();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              context.go('/login');
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Nav {
  const _Nav(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
