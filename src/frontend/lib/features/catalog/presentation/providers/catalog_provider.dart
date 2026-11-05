import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' hide Category;

import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
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
  });

  final CategoryRepository categoryRepository;
  final PictoRepository pictoRepository;

  /// RF3.6: los conteos y listados respetan qué pictos ve el chico activo.
  final SessionProvider sessionProvider;

  CatalogState _state = const CatalogLoadingState();

  CatalogState get state => _state;

  Future<void> load() async {
    _state = const CatalogLoadingState();
    notifyListeners();
    try {
      final categories = await categoryRepository.getCategories();
      final pictos = await pictoRepository.getPictos(childProfileId: sessionProvider.activeChild?.id);
      final pictoCounts = <String, int>{};
      for (final picto in pictos) {
        pictoCounts[picto.categoryId] = (pictoCounts[picto.categoryId] ?? 0) + 1;
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

  /// RF3.8: borra un picto personalizado y recarga los conteos.
  Future<void> deletePicto(String id) async {
    await pictoRepository.deletePicto(id);
    await load();
  }

  /// RF3.9: borra una categoría personalizada (cascada) y recarga.
  Future<void> deleteCategory(String id) async {
    await categoryRepository.deleteCategory(id);
    await load();
  }
}
