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
    // REQ-CAT-02 (RF-3.15): filtro por pertenencia — un picto
    // multicategoría aparece en cada una de sus categorías.
    return pictos.where((picto) => picto.belongsTo(categoryId)).toList();
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

  /// RF3.8: borra un picto personalizado y recarga. Con sesión activa, el
  /// repositorio valida que el picto sea del chico activo.
  Future<void> deletePicto(String id) async {
    await pictoRepository.deletePicto(id, childProfileId: sessionProvider.activeChild?.id);
    await _refreshAfterDelete();
  }

  /// RF3.9: borra categoría custom (cascada solo de los pictos del chico
  /// activo) y recarga.
  Future<void> deleteCategory(String id) async {
    await categoryRepository.deleteCategory(id, childProfileId: sessionProvider.activeChild?.id);
    await _refreshAfterDelete();
  }

  /// REQ-CAT-02 (RF-3.16): edita un picto custom y refresca las vistas.
  Future<void> updatePicto(Picto picto) async {
    await pictoRepository.updatePicto(picto, childProfileId: sessionProvider.activeChild?.id);
    await refresh();
  }

  /// REQ-CAT-02 (RF-3.17): renombra/recolorea una categoría custom y
  /// refresca las vistas.
  Future<void> updateCategory(Category category) async {
    await categoryRepository.updateCategory(category);
    await refresh();
  }

  /// Refresca este provider y el catálogo compartido (conteos del home).
  /// Lo usan el borrado y la edición: los números del home viven en otra
  /// pantalla del mismo árbol.
  Future<void> refresh() async {
    await load();
    if (catalogRefresher != null) {
      await catalogRefresher!.load();
    }
  }

  /// REQ-CAT-02 (RF-3.20): impacto del borrado de una categoría custom —
  /// cuántos pictos custom se ELIMINAN (quedan sin ninguna categoría y son
  /// del chico activo, o sin dueño) y cuántos solo PIERDEN esa membresía.
  /// Mismo criterio que la cascada del datasource (misma regla, dos lados).
  Future<({int toDelete, int toKeep})> deletionImpact(String categoryId) async {
    final all = await pictoRepository.getPictos();
    final activeChildId = sessionProvider.activeChild?.id;
    var toDelete = 0;
    var toKeep = 0;
    for (final picto in all) {
      if (picto.source != PictoSource.custom || !picto.belongsTo(categoryId)) {
        continue;
      }
      final remaining = picto.categoryIds.where((id) => id != categoryId).length;
      final belongsToActiveChild = activeChildId == null || picto.childProfileId == null || picto.childProfileId == activeChildId;
      if (remaining == 0 && belongsToActiveChild) {
        toDelete++;
      } else {
        toKeep++;
      }
    }
    return (toDelete: toDelete, toKeep: toKeep);
  }

  Future<void> _refreshAfterDelete() async {
    await refresh();
  }
}
