import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pictocomm/core/error/app_exception.dart';
import 'package:pictocomm/features/catalog/data/datasources/custom_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/datasources/local_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/datasources/remote_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/repositories/local_picto_repository.dart';
import 'package:pictocomm/features/catalog/domain/entities/category.dart';
import 'package:pictocomm/features/catalog/domain/entities/picto.dart';

/// RF3: catálogo personalizado por perfil + borrados.
///
/// Repositorio real con SharedPreferences simulado y `remote` intacto:
/// si algún camino de lectura tocara el remoto, el test rompe (local-first).
void main() {
  final repository = LocalPictoRepository(
    localDataSource: const LocalCatalogDataSource(),
    customDataSource: CustomCatalogDataSource(),
    remoteDataSource: const UnimplementedRemoteCatalogDataSource(),
  );

  Picto childPicto(String label, String categoryId, String childId) {
    final now = DateTime.now().toUtc();
    return Picto(
      id: '',
      label: label,
      categoryId: categoryId,
      source: PictoSource.custom,
      imageUrl: 'data:image/png;base64,iVBORw0KGgo=',
      childProfileId: childId,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('RF3.4/RF3.6: pictos de otro niño no pasan el filtro del chico', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await repository.createPicto(childPicto('banana-casa', 'alimentos', 'nina'));
    await repository.createPicto(childPicto('tren-casa', 'juguetes', 'benja'));

    final ninaPictos = await repository.getPictos(childProfileId: 'nina');
    final benjaPictos = await repository.getPictos(childProfileId: 'benja');

    expect(ninaPictos.any((picto) => picto.label == 'banana-casa'), isTrue);
    expect(ninaPictos.any((picto) => picto.label == 'tren-casa'), isFalse);
    expect(benjaPictos.any((picto) => picto.label == 'banana-casa'), isFalse);
    expect(benjaPictos.any((picto) => picto.label == 'tren-casa'), isTrue);
  });

  test('RF3.9: borrar categoría custom hace cascada de sus pictos', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final category = await repository.createCategory(const Category(id: '', name: 'Verano'));
    await repository.createPicto(childPicto('pileta', category.id, 'nina'));
    await repository.createPicto(childPicto('helado', category.id, 'nina'));

    await repository.deleteCategory(category.id);

    final categories = await repository.getCategories();
    expect(categories.any((stored) => stored.id == category.id), isFalse);
    final pictos = await repository.getPictos(childProfileId: 'nina');
    expect(pictos.isEmpty, isTrue);
  });

  test('RF3.8: el pictograma incluido no se puede borrar', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await expectLater(
      repository.deletePicto('assets/images/alimentos/banana.png'),
      throwsA(isA<DataSourceException>()),
    );
  });

  test('RF3.9: el catálogo incluido no se puede borrar', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await expectLater(
      repository.deleteCategory('alimentos'),
      throwsA(isA<DataSourceException>()),
    );
  });

  test('RF3.8: borrar picto personalizado lo saca del listado', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final created = await repository.createPicto(childPicto('pelota-casa', 'juguetes', 'nina'));

    expect((await repository.getPictos(childProfileId: 'nina')), hasLength(1));

    await repository.deletePicto(created.id);

    expect(await repository.getPictos(childProfileId: 'nina'), isEmpty);
  });
}
