import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_routes.dart';
import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/sign_up_screen.dart';
import 'features/catalog/domain/entities/category.dart';
import 'features/catalog/domain/entities/picto.dart';
import 'features/catalog/presentation/providers/catalog_provider.dart';
import 'features/catalog/presentation/providers/pictos_provider.dart';
import 'features/catalog/presentation/screens/add_category_screen.dart';
import 'features/catalog/presentation/screens/add_picto_screen.dart';
import 'features/catalog/presentation/screens/category_screen.dart';
import 'features/catalog/presentation/screens/comunicar_screen.dart';
import 'features/catalog/presentation/screens/home_screen.dart';
import 'features/catalog/presentation/screens/picto_detail_screen.dart';
import 'features/catalog/presentation/screens/pictogramas_screen.dart';
import 'features/profiles/presentation/screens/profile_screen.dart';

final class AppRouter {
  const AppRouter(this._dependencies);

  final AppDependencies _dependencies;

  ChangeNotifierProvider<PictosProvider> _pictosRoute(Widget screen) {
    return ChangeNotifierProvider<PictosProvider>(
      create: (_) => PictosProvider(
        categoryRepository: _dependencies.categoryRepository,
        pictoRepository: _dependencies.pictoRepository,
      )..load(),
      child: screen,
    );
  }

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute<void>(builder: (_) => const LoginScreen());
      case AppRoutes.signup:
        return MaterialPageRoute<void>(builder: (_) => const SignUpScreen());
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
      case AppRoutes.pictogramas:
        return MaterialPageRoute<void>(builder: (_) => _pictosRoute(const PictogramasScreen()));
      case AppRoutes.comunicar:
        return MaterialPageRoute<void>(builder: (_) => _pictosRoute(const ComunicarScreen()));
      case AppRoutes.perfil:
        return MaterialPageRoute<void>(builder: (_) => const ProfileScreen());
      case AppRoutes.category:
        final argument = settings.arguments;
        if (argument is! Category) {
          return MaterialPageRoute<void>(builder: (_) => const _RouteNotFoundScreen());
        }
        return MaterialPageRoute<void>(builder: (_) => _pictosRoute(CategoryScreen(category: argument)));
      case AppRoutes.picto:
        final argument = settings.arguments;
        if (argument is! Picto) {
          return MaterialPageRoute<void>(builder: (_) => const _RouteNotFoundScreen());
        }
        return MaterialPageRoute<void>(builder: (_) => PictoDetailScreen(picto: argument));
      case AppRoutes.addCategory:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<CatalogProvider>(
            create: (_) => CatalogProvider(
              categoryRepository: _dependencies.categoryRepository,
              pictoRepository: _dependencies.pictoRepository,
            )..load(),
            child: const AddCategoryScreen(),
          ),
        );
      case AppRoutes.addPicto:
        return MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<CatalogProvider>(
            create: (_) => CatalogProvider(
              categoryRepository: _dependencies.categoryRepository,
              pictoRepository: _dependencies.pictoRepository,
            )..load(),
            child: const AddPictoScreen(),
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
