import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'config/theme.dart';
import 'core/di/injection.dart';
import 'core/settings/app_settings.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  sl<AuthBloc>().add(const AuthCheckRequested());
  final router = AppRouter.create();
  runApp(RestoPosApp(router: router));
}

class RestoPosApp extends StatelessWidget {
  const RestoPosApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final settings = sl<AppSettings>();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return BlocProvider.value(
          value: sl<AuthBloc>(),
          child: MaterialApp.router(
            title: settings.restaurantName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            routerConfig: router,
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          ),
        );
      },
    );
  }
}

