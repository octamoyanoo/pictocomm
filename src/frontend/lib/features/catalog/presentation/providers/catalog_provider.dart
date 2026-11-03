import 'package:flutter/foundation.dart' hide Category;

import '../../domain/entities/category.dart';
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
  CatalogProvider({required this.categoryRepository, required this.pictoRepository});

  final CategoryRepository categoryRepository;
  final PictoRepository pictoRepository;

  CatalogState _state = const CatalogLoadingState();

  CatalogState get state => _state;

  Future<void> load() async {
    _state = const CatalogLoadingState();
    notifyListeners();
    try {
      final categories = await categoryRepository.getCategories();
      final pictos = await pictoRepository.getPictos();
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
}
