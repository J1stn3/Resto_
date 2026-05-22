import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key, required this.child});
  final Widget child;

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
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

  bool _sidebarCollapsed = false;
  int _activeOrders = 0;
  Timer? _metricsTimer;

  @override
  void initState() {
    super.initState();
    _refreshMetrics();
    _metricsTimer = Timer.periodic(const Duration(seconds: 45), (_) => _refreshMetrics());
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshMetrics() async {
    try {
      final stats = await sl<ApiClient>().getDashboardStats();
      if (!mounted) return;
      setState(() => _activeOrders = (stats['active_orders'] as num?)?.toInt() ?? 0);
    } catch (_) {}
  }

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

  String? _parentCrumb(String location) {
    if (location.startsWith('/admin/dashboard')) return null;
    return 'Home';
  }

  Map<String, int> _navBadges() {
    if (_activeOrders <= 0) return {};
    return {'/admin/kitchen': _activeOrders};
  }

  /// Closes the drawer without popping GoRouter routes (Navigator.pop breaks on web).
  void _closeDrawerIfOpen(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen == true) {
      scaffold!.closeDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final auth = context.watch<AuthBloc>().state;
    final userName = auth is AuthAuthenticated ? auth.user.name : 'User';
    final email = auth is AuthAuthenticated ? auth.user.email : '';
    final useDrawer = AppBreakpoints.useDrawerNav(context);
    final useBottom = AppBreakpoints.useBottomNav(context);
    final restaurantName = sl<AppSettings>().restaurantName;
    final sidebarWidth = _sidebarCollapsed ? 76.0 : 272.0;

    final sidebar = _AdminSidebar(
      location: location,
      userName: userName,
      email: email,
      restaurantName: restaurantName,
      items: _items,
      collapsed: _sidebarCollapsed && !useDrawer,
      badges: _navBadges(),
      onToggleCollapse: useDrawer
          ? null
          : () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
      onNavigate: (path) {
        if (useDrawer) _closeDrawerIfOpen(context);
        context.go(path);
      },
      onLogout: () {
        if (useDrawer) _closeDrawerIfOpen(context);
        context.read<AuthBloc>().add(const AuthLogoutRequested());
        context.go('/login');
      },
    );

    return Scaffold(
      appBar: useDrawer
          ? _MobileAppBar(restaurantName: restaurantName, title: _title(location))
          : null,
      drawer: useDrawer ? Drawer(width: AppBreakpoints.drawerWidth(context), child: sidebar) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!useDrawer)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: sidebarWidth,
              child: sidebar,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!useDrawer)
                  _DesktopTopBar(
                    title: _title(location),
                    parentLabel: _parentCrumb(location),
                    onHome: () => context.go('/admin/dashboard'),
                  ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: useBottom
          ? NavigationBar(
              selectedIndex: _bottomIndex(location),
              onDestinationSelected: (i) => context.go(_bottomNavPaths[i]),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale_rounded),
                  label: 'POS',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: _activeOrders > 0,
                    label: Text('$_activeOrders'),
                    child: const Icon(Icons.kitchen_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: _activeOrders > 0,
                    label: Text('$_activeOrders'),
                    child: const Icon(Icons.kitchen_rounded),
                  ),
                  label: 'Kitchen',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Reports',
                ),
              ],
            )
          : null,
    );
  }
}

class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MobileAppBar({required this.restaurantName, required this.title});

  final String restaurantName;
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurantName,
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500),
          ),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DesktopTopBar extends StatefulWidget {
  const _DesktopTopBar({
    required this.title,
    required this.parentLabel,
    required this.onHome,
  });

  final String title;
  final String? parentLabel;
  final VoidCallback onHome;

  @override
  State<_DesktopTopBar> createState() => _DesktopTopBarState();
}

class _DesktopTopBarState extends State<_DesktopTopBar> {
  late Timer _clockTimer;
  String _timeLabel = '';

  @override
  void initState() {
    super.initState();
    _tick();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _tick() {
    setState(() => _timeLabel = DateFormat('EEE, MMM d · h:mm a').format(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppTheme.darkSurface : AppTheme.surfaceCard,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkCard : AppTheme.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (widget.parentLabel != null) ...[
                  TextButton(
                    onPressed: widget.onHome,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMuted,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(widget.parentLabel!),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(_timeLabel, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.location,
    required this.userName,
    required this.email,
    required this.restaurantName,
    required this.items,
    required this.collapsed,
    required this.badges,
    required this.onNavigate,
    required this.onLogout,
    this.onToggleCollapse,
  });

  final String location;
  final String userName;
  final String email;
  final String restaurantName;
  final List<_Nav> items;
  final bool collapsed;
  final Map<String, int> badges;
  final void Function(String path) onNavigate;
  final VoidCallback onLogout;
  final VoidCallback? onToggleCollapse;

  static const _operationsPaths = [
    '/admin/dashboard',
    '/admin/pos',
    '/admin/kitchen',
  ];

  static const _managementPaths = [
    '/admin/menu',
    '/admin/tables',
    '/admin/reports',
    '/admin/users',
    '/admin/settings',
  ];

  @override
  Widget build(BuildContext context) {
    final navBg = const Color(0xFF1E293B);
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    final operations = items.where((i) => _operationsPaths.contains(i.path)).toList();
    final management = items.where((i) => _managementPaths.contains(i.path)).toList();

    return Material(
      color: navBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarHeader(
            restaurantName: restaurantName,
            userName: userName,
            email: email,
            initial: initial,
            collapsed: collapsed,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(collapsed ? 8 : 12, 16, collapsed ? 8 : 12, 8),
              children: [
                if (!collapsed) const _NavSectionLabel('Operations'),
                ...operations.map((i) => _SidebarNavTile(
                      item: i,
                      selected: location.startsWith(i.path),
                      collapsed: collapsed,
                      badge: badges[i.path],
                      onTap: () => onNavigate(i.path),
                    )),
                SizedBox(height: collapsed ? 12 : 20),
                if (!collapsed) const _NavSectionLabel('Management'),
                ...management.map((i) => _SidebarNavTile(
                      item: i,
                      selected: location.startsWith(i.path),
                      collapsed: collapsed,
                      badge: badges[i.path],
                      onTap: () => onNavigate(i.path),
                    )),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF334155)),
          if (onToggleCollapse != null)
            Padding(
              padding: EdgeInsets.fromLTRB(collapsed ? 8 : 12, 8, collapsed ? 8 : 12, 4),
              child: _SidebarNavTile(
                item: _Nav(
                  '',
                  collapsed ? 'Expand' : 'Collapse',
                  collapsed ? Icons.last_page_rounded : Icons.first_page_rounded,
                  collapsed ? Icons.last_page_rounded : Icons.first_page_rounded,
                ),
                selected: false,
                collapsed: collapsed,
                onTap: onToggleCollapse!,
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(collapsed ? 8 : 12, 4, collapsed ? 8 : 12, collapsed ? 12 : 8),
            child: _SidebarNavTile(
              item: const _Nav('', 'Log out', Icons.logout_rounded, Icons.logout_rounded),
              selected: false,
              collapsed: collapsed,
              isDestructive: true,
              onTap: onLogout,
            ),
          ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'System online',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45)),
                  ),
                  const Spacer(),
                  Text(
                    'v1.0',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.restaurantName,
    required this.userName,
    required this.email,
    required this.initial,
    required this.collapsed,
  });

  final String restaurantName;
  final String userName;
  final String email;
  final String initial;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(collapsed ? 12 : 20, 16, collapsed ? 12 : 20, collapsed ? 16 : 22),
          child: collapsed
              ? Center(
                  child: Tooltip(
                    message: '$restaurantName\n$userName',
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            restaurantName,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Administrator',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _NavSectionLabel extends StatelessWidget {
  const _NavSectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1.1),
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
    this.badge,
    this.isDestructive = false,
  });

  final _Nav item;
  final bool selected;
  final bool collapsed;
  final int? badge;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final accent = isDestructive ? AppTheme.danger : AppTheme.primary;
    final iconColor = isDestructive
        ? AppTheme.danger
        : selected
            ? AppTheme.primary
            : const Color(0xFFCBD5E1);
    final textColor = isDestructive
        ? AppTheme.danger
        : selected
            ? Colors.white
            : const Color(0xFFE2E8F0);

    final icon = Icon(
      selected && !isDestructive ? item.selectedIcon : item.icon,
      size: 22,
      color: iconColor,
    );

    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        hoverColor: Colors.white.withValues(alpha: 0.06),
        splashColor: accent.withValues(alpha: 0.12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            color: selected && !isDestructive ? AppTheme.primary.withValues(alpha: 0.18) : Colors.transparent,
            border: selected && !isDestructive
                ? const Border(left: BorderSide(color: AppTheme.primary, width: 3))
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              selected && !isDestructive ? 9 : (collapsed ? 0 : 12),
              11,
              collapsed ? 0 : 12,
              11,
            ),
            child: collapsed
                ? Center(child: badge != null && badge! > 0 ? Badge(label: Text('$badge'), child: icon) : icon)
                : Row(
                    children: [
                      badge != null && badge! > 0 ? Badge(label: Text('$badge'), child: icon) : icon,
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (selected && !isDestructive)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Tooltip(message: item.label, child: tile),
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: tile);
  }
}

class _Nav {
  const _Nav(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
