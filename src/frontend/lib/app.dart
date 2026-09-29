import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_routes.dart';
import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'features/catalog/presentation/providers/catalog_provider.dart';
import 'features/catalog/presentation/screens/category_screen.dart';
import 'features/catalog/presentation/screens/home_screen.dart';
import 'features/profiles/presentation/providers/profiles_provider.dart';

/// Raíz de la aplicación.
///
/// Recibe [AppDependencies] por parámetro en vez de construirlas internamente:
/// los tests pueden inyectar repositorios falsos sin tocar la UI.
class PictoCommApp extends StatelessWidget {
  const PictoCommApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CatalogProvider>(
          create: (_) => CatalogProvider(
            catalogRepository: dependencies.catalogRepository,
            pictoRepository: dependencies.pictoRepository,
          )..loadCategories(),
        ),
        ChangeNotifierProvider<ProfilesProvider>(
          create: (_) => ProfilesProvider(dependencies.profileRepository)..load(),
        ),
      ],
      child: MaterialApp(
        title: 'PictoComm',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}

/// Fábrica central de rutas.
///
/// Agregar una pantalla es: una constante en `AppRoutes` + un caso acá.
abstract final class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget screen;
    switch (settings.name) {
      case AppRoutes.home:
        screen = const HomeScreen();
      case AppRoutes.category:
        screen = const CategoryScreen();
      case AppRoutes.profiles:
        // TODO: selección de niño. Requiere la feature de perfiles completa.
        screen = const HomeScreen();
      case AppRoutes.settings:
        // TODO: ajustes (volumen, tamaño de tarjetas, tema).
        screen = const HomeScreen();
      default:
        screen = const HomeScreen();
    }

    return MaterialPageRoute<dynamic>(
      builder: (_) => screen,
      settings: settings,
    );
  }
}
