import 'package:flutter/foundation.dart' hide Category;

import '../../../profiles/presentation/providers/session_provider.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/picto_repository.dart';
import 'catalog_provider.dart';

sealed class PictosState {
  const PictosState();
}

final class PictosLoadingState extends PictosState {
  const PictosLoadingState();
}

final class PictosLoadedState extends PictosState {
  const PictosLoadedState({required this.categories, required this.pictos});

  final List<Category> categories;
  final List<Picto> pictos;

  List<Picto> pictosOf(String categoryId) {
    return pictos.where((picto) => picto.categoryId == categoryId).toList();
  }

  Category? categoryOf(String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }
}

final class PictosFailureState extends PictosState {
  const PictosFailureState(this.message);

  final String message;
}

/// Un único PictosProvider compartido por el router: como las rutas son
/// stacks separados, un provider por ruta quedaría desactualizado cada vez
/// que otra pestaña borra o crea pictos. Con la instancia compartida, el
/// `watch` de cada pantalla siempre refleja el último `load()`.
final class PictosProvider extends ChangeNotifier {
  PictosProvider({
    required this.categoryRepository,
    required this.pictoRepository,
    required this.sessionProvider,
    this.catalogRefresher,
  });

  final CategoryRepository categoryRepository;
  final PictoRepository pictoRepository;

  /// RF3.6: el chico activo define qué pictos personalizados se ven.
  final SessionProvider sessionProvider;

  /// Después de un borrado, el home (conteos) también vive en otra pantalla
  /// del mismo árbol: recargarlo mantiene los números sincronizados.
  final CatalogProvider? catalogRefresher;

  PictosState _state = const PictosLoadingState();

  PictosState get state => _state;

  Future<void> load() async {
    _state = const PictosLoadingState();
    notifyListeners();
    try {
      final categories = await categoryRepository.getCategories();
      final pictos = await pictoRepository.getPictos(childProfileId: sessionProvider.activeChild?.id);
      _state = PictosLoadedState(categories: categories, pictos: pictos);
    } on Object catch (error) {
      _state = PictosFailureState(error.toString());
    }
    notifyListeners();
  }

  /// RF3.8: borra un picto personalizado y recarga.
  Future<void> deletePicto(String id) async {
    await pictoRepository.deletePicto(id);
    await _refreshAfterDelete();
  }

  /// RF3.9: borra categoría custom (cascada de sus pictos) y recarga.
  Future<void> deleteCategory(String id) async {
    await categoryRepository.deleteCategory(id);
    await _refreshAfterDelete();
  }

  Future<void> _refreshAfterDelete() async {
    await load();
    if (catalogRefresher != null) {
      await catalogRefresher!.load();
    }
  }
}
