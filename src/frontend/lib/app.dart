import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_routes.dart';
import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/catalog/presentation/providers/catalog_provider.dart';
import 'features/catalog/presentation/screens/home_screen.dart';

final class AppRouter {
  const AppRouter(this._dependencies);

  final AppDependencies _dependencies;

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute<void>(builder: (_) => const LoginScreen());
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<CatalogProvider>(
            create: (_) => CatalogProvider(
              categoryRepository: _dependencies.categoryRepository,
              pictoRepository: _dependencies.pictoRepository,
            )..load(),
            child: const HomeScreen(),
          ),
        );
      default:
        return MaterialPageRoute<void>(builder: (_) => const _RouteNotFoundScreen());
    }
  }
}

final class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Ruta no encontrada', style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

final class PictoCommApp extends StatelessWidget {
  const PictoCommApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter(dependencies);
    return MaterialApp(
      title: 'PictoComm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.login,
      onGenerateRoute: appRouter.onGenerateRoute,
    );
  }
}
