import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm_app/core/di/injector.dart';
import 'package:pictocomm_app/core/error/app_exception.dart';
import 'package:pictocomm_app/features/catalog/data/datasources/catalog_local_data_source.dart';
import 'package:pictocomm_app/features/catalog/data/datasources/remote_catalog_data_source.dart';
import 'package:pictocomm_app/features/catalog/data/repositories/local_catalog_repository.dart';
import 'package:pictocomm_app/features/catalog/data/repositories/local_picto_repository.dart';
import 'package:pictocomm_app/features/catalog/domain/catalog_repository.dart';
import 'package:pictocomm_app/features/catalog/domain/category.dart';
import 'package:pictocomm_app/features/catalog/domain/picto.dart';
import 'package:pictocomm_app/features/catalog/domain/picto_repository.dart';
import 'package:pictocomm_app/features/catalog/domain/picto_source.dart';
import 'package:pictocomm_app/features/profiles/data/repositories/in_memory_profile_repository.dart';
import 'package:pictocomm_app/features/profiles/domain/child_profile.dart';

/// Fakes en memoria para tests.
///
/// Existen para probar pantallas y repositorios sin tocar `AssetManifest`: todo
/// pide interfaces, así que un test inyecta estos fakes en vez de las
/// implementaciones reales. Si mañana una pantalla mostrara datos hardcodeados
/// en vez de los del repositorio, estos tests lo detectarían.

class FakeCatalogLocalDataSource implements CatalogLocalDataSource {
  FakeCatalogLocalDataSource({
    List<Category> categories = const <Category>[],
    List<Picto> pictos = const <Picto>[],
  })  : categories = List<Category>.from(categories),
        pictos = List<Picto>.from(pictos);

  final List<Category> categories;
  final List<Picto> pictos;

  /// Si se setea, todo método lanza esta excepción. Sirve para probar la
  /// pantalla de error.
  Object? failWith;

  void _maybeFail() {
    if (failWith != null) throw failWith!;
  }

  @override
  Future<List<Category>> getCategories() async {
    _maybeFail();
    return List<Category>.from(categories);
  }

  @override
  Future<List<Picto>> getPictosByCategory(String categoryId) async {
    _maybeFail();
    return pictos.where((Picto p) => p.categoryId == categoryId).toList();
  }

  @override
  Future<Picto> saveCustomPicto(Picto picto) async {
    _maybeFail();
    final int idx = pictos.indexWhere((Picto p) => p.id == picto.id);
    if (idx == -1) {
      pictos.add(picto);
    } else {
      pictos[idx] = picto;
    }
    return picto;
  }

  @override
  Future<void> deleteCustomPicto(String id) async {
    _maybeFail();
    final int idx = pictos.indexWhere((Picto p) => p.id == id);
    if (idx == -1) {
      // Mismo contrato que la implementación real.
      throw NotFoundException('No existe el picto $id');
    }
    pictos.removeAt(idx);
  }

  @override
  Future<bool> toggleFavorite(String id) async {
    _maybeFail();
    final int idx = pictos.indexWhere((Picto p) => p.id == id);
    if (idx == -1) return false;
    final bool next = !pictos[idx].isFavorite;
    pictos[idx] = pictos[idx].copyWith(isFavorite: next);
    return next;
  }
}

/// Datasource remoto que falla ruidosamente si alguien lo usa.
///
/// La app es local-first: ningún camino de lectura debe tocar el remoto. Si un
/// test lo dispara, la excepción delata el bug en vez de devolver datos falsos.
class ExplodingRemoteDataSource extends RemoteCatalogDataSource {
  const ExplodingRemoteDataSource();

  @override
  Future<List<Category>> getCategories() => _explode();

  @override
  Future<List<Picto>> getPictosByCategory(String categoryId) => _explode();

  Never _explode() => throw const UnimplementedFeatureException(
        'El test intentó usar el datasource remoto. La app debe ser local-first.',
      );
}

const RemoteCatalogDataSource throwNeverCalled = ExplodingRemoteDataSource();

const Category testCategory = Category(
  id: 'comida',
  name: 'Comida',
  assetFolder: 'comida',
  color: Color(0xFF4CAF50),
);

const Picto testPicto = Picto(
  id: 'assets/images/comida/manzana.png',
  label: 'manzana',
  categoryId: 'comida',
  imagePath: 'assets/images/comida/manzana.png',
  source: PictoSource.bundled,
);

const ChildProfile testProfile = ChildProfile(
  id: 'nino-1',
  name: 'Milo',
  color: Color(0xFF6C5CE7),
);

/// Repositorios reales sobre un datasource fake.
///
/// Prueba una capa real de la arquitectura sin assets ni red.
({
  CatalogRepository catalog,
  PictoRepository picto,
  FakeCatalogLocalDataSource data,
}) fakeRepositories({
  List<Category> categories = const <Category>[testCategory],
  List<Picto> pictos = const <Picto>[testPicto],
}) {
  final FakeCatalogLocalDataSource data = FakeCatalogLocalDataSource(
    categories: categories,
    pictos: pictos,
  );
  return (
    catalog: LocalCatalogRepository(data),
    picto: LocalPictoRepository(data, throwNeverCalled),
    data: data,
  );
}

/// [AppDependencies] listas para un widget test.
AppDependencies fakeDependencies({
  FakeCatalogLocalDataSource? local,
  List<ChildProfile> profiles = const <ChildProfile>[testProfile],
}) {
  final FakeCatalogLocalDataSource ds = local ??
      FakeCatalogLocalDataSource(
        categories: <Category>[testCategory],
        pictos: <Picto>[testPicto],
      );

  final CatalogRepository catalogRepository = LocalCatalogRepository(ds);
  final PictoRepository pictoRepository =
      LocalPictoRepository(ds, throwNeverCalled);

  return AppDependencies(
    catalogRepository: catalogRepository,
    pictoRepository: pictoRepository,
    profileRepository: InMemoryProfileRepository(seed: profiles),
  );
}
