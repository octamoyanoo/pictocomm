import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' hide Category;

import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
import '../../../profiles/domain/entities/child_profile.dart';
import '../../../profiles/domain/repositories/child_profile_repository.dart';
import '../../../profiles/presentation/providers/session_provider.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/picto_repository.dart';

sealed class CatalogState {
  const CatalogState();
}

final class CatalogLoadingState extends CatalogState {
  const CatalogLoadingState();
}

final class CatalogLoadedState extends CatalogState {
  const CatalogLoadedState({required this.categories, required this.pictoCounts});

  final List<Category> categories;

  final Map<String, int> pictoCounts;

  bool get isEmpty => categories.isEmpty;

  int pictoCountOf(String categoryId) => pictoCounts[categoryId] ?? 0;
}

final class CatalogFailureState extends CatalogState {
  const CatalogFailureState(this.message);

  final String message;
}

final class CatalogProvider extends ChangeNotifier {
  CatalogProvider({
    required this.categoryRepository,
    required this.pictoRepository,
    required this.sessionProvider,
    this.childProfileRepository,
  });

  final CategoryRepository categoryRepository;
  final PictoRepository pictoRepository;

  /// RF3.6: los conteos y listados respetan qué pictos ve el chico activo.
  final SessionProvider sessionProvider;

  /// REQ-CAT-02 (RF-3.19): lista de chicos para asignar dueño al editar un
  /// picto legacy sin dueño. Opcional (los tests de flujo no lo necesitan).
  final ChildProfileRepository? childProfileRepository;

  /// RF-3.19: chicos disponibles para la asignación; vacío si no hay repo.
  Future<List<ChildProfile>> childrenForAssignment() async {
    final repository = childProfileRepository;
    if (repository == null) {
      return const [];
    }
    return repository.getChildren();
  }

  CatalogState _state = const CatalogLoadingState();

  CatalogState get state => _state;

  Future<void> load() async {
    _state = const CatalogLoadingState();
    notifyListeners();
    try {
      final categories = await categoryRepository.getCategories();
      final pictos = await pictoRepository.getPictos(childProfileId: sessionProvider.activeChild?.id);
      // REQ-CAT-02 (RF-3.15): un picto multicategoría suma en cada una de
      // sus categorías.
      final pictoCounts = <String, int>{};
      for (final picto in pictos) {
        for (final categoryId in picto.categoryIds) {
          pictoCounts[categoryId] = (pictoCounts[categoryId] ?? 0) + 1;
        }
      }
      _state = CatalogLoadedState(categories: categories, pictoCounts: pictoCounts);
    } on Object catch (error) {
      _state = CatalogFailureState(error.toString());
    }
    notifyListeners();
  }

  Future<Category> createCategory(String name, Color? color) async {
    final created = await categoryRepository.createCategory(Category(id: '', name: name, color: color));
    await load();
    return created;
  }

  Future<Picto> createPicto(Picto picto) async {
    final created = await pictoRepository.createPicto(picto);
    await load();
    return created;
  }

  /// REQ-CAT-02 (RF-3.16): edita un picto custom y recarga los conteos.
  Future<Picto> updatePicto(Picto picto) async {
    final updated = await pictoRepository.updatePicto(picto, childProfileId: sessionProvider.activeChild?.id);
    await load();
    return updated;
  }

  /// REQ-CAT-02 (RF-3.17): renombra/recolorea una categoría custom y recarga.
  Future<Category> updateCategory(Category category) async {
    final updated = await categoryRepository.updateCategory(category);
    await load();
    return updated;
  }

  /// RF3.8: borra un picto personalizado y recarga los conteos. Con sesión
  /// activa, el repositorio valida que el picto sea del chico activo.
  Future<void> deletePicto(String id) async {
    await pictoRepository.deletePicto(id, childProfileId: sessionProvider.activeChild?.id);
    await load();
  }

  /// RF3.9: borra una categoría personalizada (cascada del chico activo) y
  /// recarga.
  Future<void> deleteCategory(String id) async {
    await categoryRepository.deleteCategory(id, childProfileId: sessionProvider.activeChild?.id);
    await load();
  }
}
