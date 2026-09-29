import 'picto.dart';
import 'picto_source.dart';

/// Contrato de acceso a los pictos (las imágenes que toca el niño).
///
/// Incluye escritura porque los pictos propios de la familia son datos
/// editables. Las operaciones sobre `PictoSource.bundled` lanzan
/// `ValidationException`: vienen dentro de la app y no se pueden modificar.
abstract interface class PictoRepository {
  /// Pictos de una categoría, filtrables.
  ///
  /// [source] filtra por origen; [favoritesOnly] reduce el resultado a los
  /// marcados como favoritos (lo usan el tablero de inicio y el constructor de
  /// frases).
  Future<List<Picto>> getPictos({
    required String categoryId,
    PictoSource? source,
    bool favoritesOnly = false,
  });

  /// Inserta o actualiza un picto. El `id` decide cuál de las dos.
  ///
  /// Lanza `ValidationException` sobre pictos empaquetados y
  /// `StorageException` si no se puede persistir.
  Future<Picto> savePicto(Picto picto);

  /// Elimina un picto propio. Lanza `NotFoundException` si no existe.
  Future<void> deletePicto(String id);

  /// Marca o desmarca como favorito y devuelve el estado resultante.
  Future<bool> toggleFavorite(String id);
}
