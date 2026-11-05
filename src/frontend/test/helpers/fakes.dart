import 'package:pictocomm/core/di/injector.dart';
import 'package:pictocomm/core/theme/app_theme.dart';
import 'package:pictocomm/core/error/app_exception.dart';
import 'package:pictocomm/features/catalog/data/datasources/remote_catalog_data_source.dart';import 'package:pictocomm/features/catalog/data/models/category_model.dart';
import 'package:pictocomm/features/catalog/data/models/picto_model.dart';
import 'package:pictocomm/features/catalog/domain/entities/category.dart';
import 'package:pictocomm/features/catalog/domain/entities/picto.dart';
import 'package:pictocomm/features/catalog/domain/repositories/category_repository.dart';
import 'package:pictocomm/features/catalog/domain/repositories/picto_repository.dart';
import 'package:pictocomm/features/profiles/domain/entities/child_profile.dart';
import 'package:pictocomm/features/profiles/domain/repositories/child_profile_repository.dart';
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
      custom: true,
    );
    _categories.add(persisted);
    return persisted;
  }

  /// RF3.9: borra la categoría solo si es custom (en fakes, todo lo de la
  /// lista lo es, salvo las seeded explicitas con custom false). El
  /// [childProfileId] se ignora a proposito: la cascada por chico vive en el
  /// datasource real (los fakes no comparten storage con pictos).
  @override
  Future<void> deleteCategory(String id, {String? childProfileId}) async {
    final stored = _categories.where((category) => category.id == id).firstOrNull;
    if (stored == null || !stored.custom) {
      throw const DataSourceException('La categoría no es borrable o no existe');
    }
    _categories.removeWhere((category) => category.id == id);
  }
}

final class FakePictoRepository implements PictoRepository {
  FakePictoRepository({List<Picto> pictos = const <Picto>[]}) : _pictos = [...pictos];

  final List<Picto> _pictos;

  List<Picto> get pictos => List.unmodifiable(_pictos);

  @override
  Future<List<Picto>> getPictos({String? categoryId, String? childProfileId}) async {
    // RF3.6: con chico activo, los custom sin dueño siguen visibles (RF3.7);
    // los owned solo su dueño. Sin filtro, la gestión ve todo.
    final visible = childProfileId == null
        ? _pictos
        : _pictos.where((picto) => picto.source == PictoSource.bundled || picto.childProfileId == null || picto.childProfileId == childProfileId).toList();
    if (categoryId == null) {
      return visible;
    }
    return visible.where((p) => p.categoryId == categoryId).toList();
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
      childProfileId: picto.childProfileId,
      createdAt: now,
      updatedAt: now,
    );
    _pictos.add(persisted);
    return persisted;
  }

  /// RF3.8: solo custom y, con dueño, solo el chico activo lo borra.
  @override
  Future<void> deletePicto(String id, {String? childProfileId}) async {
    final stored = _pictos.where((picto) => picto.id == id).firstOrNull;
    if (stored == null || stored.source != PictoSource.custom) {
      throw const DataSourceException('Solo se pueden borrar pictogramas personalizados');
    }
    if (childProfileId != null && stored.childProfileId != null && stored.childProfileId != childProfileId) {
      throw const DataSourceException('El pictograma pertenece a otro chico');
    }
    _pictos.removeWhere((picto) => picto.id == id);
  }

  /// RF2.7: purge de todos los pictos del chico. Registra los purgados para
  /// que los tests puedan asertar la cascada.
  @override
  Future<void> deletePictosForChild(String childProfileId) async {
    _purgedChildIds.add(childProfileId);
    _pictos.removeWhere((picto) => picto.childProfileId == childProfileId);
  }

  final List<String> _purgedChildIds = [];

  /// Ids de chicos pasados por `deletePictosForChild`, en orden.
  List<String> get purgedChildIds => List.unmodifiable(_purgedChildIds);
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

final class FakeChildProfileRepository implements ChildProfileRepository {
  FakeChildProfileRepository({
    List<ChildProfile> children = const <ChildProfile>[],
    this.purgePictosForChild,
  }) : _children = [...children];

  final List<ChildProfile> _children;

  /// RF2.7: cascada inyectada, igual que el repo real (misma firma).
  final Future<void> Function(String childId)? purgePictosForChild;

  List<ChildProfile> get children => List.unmodifiable(_children);

  @override
  Future<List<ChildProfile>> getChildren() async => _children;

  @override
  Future<ChildProfile> createChild(ChildProfile child) async {
    final name = child.name.trim();
    if (name.isEmpty) {
      throw const DataSourceException('El nombre del niño no puede estar vacío');
    }
    final persisted = ChildProfile(
      id: 'child-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      age: child.age,
      avatarColor: child.avatarColor,
      // El contrato real persiste la foto (RF3.11); el fake también.
      photoUrl: child.photoUrl,
    );
    _children.add(persisted);
    return persisted;
  }

  @override
  Future<ChildProfile> updateChild(ChildProfile child) async {
    final index = _children.indexWhere((element) => element.id == child.id);
    if (index < 0) {
      throw const DataSourceException('El perfil del niño no existe');
    }
    _children[index] = child;
    return child;
  }

  @override
  Future<void> deleteChild(String id) async {
    _children.removeWhere((child) => child.id == id);
    // RF2.7: cascada espejo del repo real.
    await purgePictosForChild?.call(id);
  }
}

/// Perfil de chico de prueba: los tests de flujo entran a sesión a traves del
/// selector (RF2.1) tocando su tarjeta.
ChildProfile testChildProfile() => ChildProfile(
  id: 'test-nina',
  name: 'Nina',
  avatarColor: AppColors.avatarPalette.first,
);

AppDependencies fakeDependencies({
  List<Category> categories = const <Category>[],
  List<Picto> pictos = const <Picto>[],
  List<ChildProfile> children = const <ChildProfile>[],
  VoiceProvider? voiceProvider,
}) {
  return AppDependencies(
    categoryRepository: FakeCategoryRepository(categories: categories),
    pictoRepository: FakePictoRepository(pictos: pictos),
    childProfileRepository: FakeChildProfileRepository(children: children),
    voiceProvider: voiceProvider ?? FakeVoiceProvider(),
  );
}
