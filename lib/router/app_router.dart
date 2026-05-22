import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/admin/presentation/pages/admin_shell_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/admin/presentation/pages/admin_menu_page.dart';
import '../features/admin/presentation/pages/admin_users_page.dart';
import '../features/admin/presentation/pages/admin_tables_page.dart';
import '../features/admin/presentation/pages/admin_reports_page.dart';
import '../features/admin/presentation/pages/admin_settings_page.dart';
import '../features/counter/presentation/pages/counter_page.dart';
import '../features/kitchen/presentation/pages/kitchen_page.dart';

class AppRouter {
  static GoRouter create() {
    final authBloc = sl<AuthBloc>();

    return GoRouter(
      initialLocation: '/login',
      refreshListenable: _AuthRefresh(authBloc),
      redirect: (context, state) {
        final authState = authBloc.state;
        final onAuthScreen = state.matchedLocation == '/login';

        if (authState is AuthInitial || authState is AuthLoading) return null;

        if (authState is AuthError) return onAuthScreen ? null : '/login';

        if (authState is! AuthAuthenticated) {
          return onAuthScreen ? null : '/login';
        }

        if (onAuthScreen) return '/admin/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        ShellRoute(
          builder: (_, __, child) => AdminShellPage(child: child),
          routes: [
            GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardPage()),
            GoRoute(path: '/admin/pos', builder: (_, __) => const CounterPage()),
            GoRoute(path: '/admin/kitchen', builder: (_, __) => const KitchenPage()),
            GoRoute(path: '/admin/menu', builder: (_, __) => const AdminMenuPage()),
            GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersPage()),
            GoRoute(path: '/admin/tables', builder: (_, __) => const AdminTablesPage()),
            GoRoute(path: '/admin/reports', builder: (_, __) => const AdminReportsPage()),
            GoRoute(path: '/admin/settings', builder: (_, __) => const AdminSettingsPage()),
          ],
        ),
      ],
    );
  }
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this.bloc) {
    _sub = bloc.stream.listen((_) => notifyListeners());
  }
  final AuthBloc bloc;
  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
