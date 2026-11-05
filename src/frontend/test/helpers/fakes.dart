import 'package:pictocomm/core/di/injector.dart';
import 'package:pictocomm/core/error/app_exception.dart';
import 'package:pictocomm/features/catalog/data/datasources/remote_catalog_data_source.dart';import 'package:pictocomm/features/catalog/data/models/category_model.dart';
import 'package:pictocomm/features/catalog/data/models/picto_model.dart';
import 'package:pictocomm/features/catalog/domain/entities/category.dart';
import 'package:pictocomm/features/catalog/domain/entities/picto.dart';
import 'package:pictocomm/features/catalog/domain/repositories/category_repository.dart';
import 'package:pictocomm/features/catalog/domain/repositories/picto_repository.dart';
import 'package:pictocomm/features/voice/domain/voice_provider.dart';

final class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository({List<Category> categories = const <Category>[]}) : _categories = [...categories];

  final List<Category> _categories;

  List<Category> get categories => List.unmodifiable(_categories);

  @override
  Future<List<Category>> getCategories() async => _categories;

  @override
  Future<Category> createCategory(Category category) async {
    final name = category.name.trim();
    for (final stored in _categories) {
      if (stored.name.toLowerCase() == name.toLowerCase()) {
        throw DuplicateCatalogException('Ya existe una categoría "$name"');
      }
    }
    final persisted = Category(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      color: category.color,
      icon: category.icon,
    );
    _categories.add(persisted);
    return persisted;
  }
}

final class FakePictoRepository implements PictoRepository {
  FakePictoRepository({List<Picto> pictos = const <Picto>[]}) : _pictos = [...pictos];

  final List<Picto> _pictos;

  List<Picto> get pictos => List.unmodifiable(_pictos);

  @override
  Future<List<Picto>> getPictos({String? categoryId}) async {
    if (categoryId == null) {
      return _pictos;
    }
    return _pictos.where((p) => p.categoryId == categoryId).toList();
  }

  @override
  Future<Picto?> getPicto(String id) async {
    for (final picto in _pictos) {
      if (picto.id == id) {
        return picto;
      }
    }
    return null;
  }

  @override
  Future<Picto> createPicto(Picto picto) async {
    final label = picto.label.trim();
    if (label.isEmpty) {
      throw const DataSourceException('El nombre del pictograma no puede estar vacío');
    }
    if (picto.imageUrl == null || picto.imageUrl!.isEmpty) {
      throw const DataSourceException('Elegí una imagen para el pictograma');
    }
    final now = DateTime.now().toUtc();
    final persisted = Picto(
      id: 'custom-${now.microsecondsSinceEpoch}',
      label: picto.label,
      categoryId: picto.categoryId,
      source: PictoSource.custom,
      imageUrl: picto.imageUrl,
      createdAt: now,
      updatedAt: now,
    );
    _pictos.add(persisted);
    return persisted;
  }
}

final class ExplodingRemoteDataSource implements RemoteCatalogDataSource {
  const ExplodingRemoteDataSource();

  @override
  Future<List<CategoryModel>> getCategories() async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: la app no debe tocar el remoto en lectura');
  }

  @override
  Future<List<PictoModel>> getPictos({String? categoryId, DateTime? since, int limit = 100}) async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: la app no debe tocar el remoto en lectura');
  }

  @override
  Future<PictoModel> getPicto(String id) async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: la app no debe tocar el remoto en lectura');
  }
}

/// Voz "en silencio" para tests: respeta el contrato (speak completa solo
/// cuando la palabra "terminó de sonar") pero no pronuncia nada. Registra
/// lo pedido para que los tests puedan verificar qué se quiso reproducir.
final class FakeVoiceProvider implements VoiceProvider {
  FakeVoiceProvider({List<String> words = const <String>[]}) : _words = [...words];

  final List<String> _words;

  /// Palabras pedidas a `speak`, en orden.
  List<String> get spokenWords => List.unmodifiable(_words);

  bool _stopped = false;

  /// `true` si se llamó `stop` al menos una vez.
  bool get isStopped => _stopped;

  @override
  Future<void> speak(String word) async {
    if (word.trim().isEmpty) {
      throw const VoiceException('No se puede pronunciar un texto vacío');
    }
    _words.add(word);
  }

  @override
  Future<void> stop() async {
    _stopped = true;
  }

  @override
  Future<void> dispose() async {}
}

AppDependencies fakeDependencies({List<Category> categories = const <Category>[], List<Picto> pictos = const <Picto>[]}) {
  return AppDependencies(
    categoryRepository: FakeCategoryRepository(categories: categories),
    pictoRepository: FakePictoRepository(pictos: pictos),
    voiceProvider: FakeVoiceProvider(),
  );
}
