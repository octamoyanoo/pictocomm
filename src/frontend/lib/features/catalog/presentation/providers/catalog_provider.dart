// `Category` choca con la anotación homónima de flutter/foundation.dart.
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:provider/provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/category.dart';
import '../../domain/picto.dart';
import '../../domain/picto_repository.dart';

/// Estado de la pantalla principal y del tablero de una categoría.
///
/// Un provider por feature: cada uno expone solo lo que su pantalla necesita,
/// y `notifyListeners` no redibuja de más.
class CatalogProvider extends ChangeNotifier {
  CatalogProvider({
    required CatalogRepository catalogRepository,
    required PictoRepository pictoRepository,
  })  // Los parámetros son interfaces públicas y los campos privados, así que
      // el initializing formal no aplica.
      // ignore: prefer_initializing_formals
      : _catalogRepository = catalogRepository,
        // ignore: prefer_initializing_formals
        _pictoRepository = pictoRepository;

  final CatalogRepository _catalogRepository;
  final PictoRepository _pictoRepository;

  List<Category> _categories = <Category>[];
  List<Picto> _pictos = <Picto>[];
  Category? _selectedCategory;
  bool _isLoading = true;
  AppException? _error;

  List<Category> get categories => _categories;

  /// Pictos de [selectedCategory].
  List<Picto> get pictos => _pictos;

  Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  AppException? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await _catalogRepository.getCategories();
      _categories.sort(
        (Category a, Category b) => a.sortOrder.compareTo(b.sortOrder),
      );
    } on AppException catch (e) {
      _error = e;
    } on Object catch (e) {
      _error = StorageException(
        'No se pudieron cargar las categorías',
        cause: e,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(Category category) async {
    _selectedCategory = category;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _pictos = await _pictoRepository.getPictos(categoryId: category.id);
    } on AppException catch (e) {
      _error = e;
    } on Object catch (e) {
      _error = StorageException('No se pudieron cargar los pictos', cause: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Se llama al tocar un picto. Hoy solo es feedback; el registro de la
  /// interacción y la reproducción de audio entran con esas features.
  void onPictoTap(Picto picto) {
    debugPrint('Picto tocado: ${picto.id} (${picto.label})');
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}

extension CatalogContext on BuildContext {
  /// Acceso para disparar acciones: `context.catalog.selectCategory(c)`.
  CatalogProvider get catalog => read<CatalogProvider>();

  /// Acceso para redibujar: `context.catalogWatch.categories`.
  CatalogProvider get catalogWatch => watch<CatalogProvider>();
}
