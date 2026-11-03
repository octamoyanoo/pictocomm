import 'package:flutter/foundation.dart' hide Category;

import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/picto_repository.dart';

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

final class PictosProvider extends ChangeNotifier {
  PictosProvider({required this.categoryRepository, required this.pictoRepository});

  final CategoryRepository categoryRepository;
  final PictoRepository pictoRepository;

  PictosState _state = const PictosLoadingState();

  PictosState get state => _state;

  Future<void> load() async {
    _state = const PictosLoadingState();
    notifyListeners();
    try {
      final categories = await categoryRepository.getCategories();
      final pictos = await pictoRepository.getPictos();
      _state = PictosLoadedState(categories: categories, pictos: pictos);
    } on Object catch (error) {
      _state = PictosFailureState(error.toString());
    }
    notifyListeners();
  }
}
