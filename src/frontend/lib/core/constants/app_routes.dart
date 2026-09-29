/// Nombres de rutas de navegación.
///
/// Evita strings mágicos desparramados por la app: la pantalla se pide siempre
/// con [AppRoutes.of] / [AppRoutes.category] y el router de
/// `core/router/app_router.dart` es el único que sabe construirla.
abstract final class AppRoutes {
  static const String home = '/';
  static const String category = '/category';
  static const String settings = '/settings';
  static const String profiles = '/profiles';
}
