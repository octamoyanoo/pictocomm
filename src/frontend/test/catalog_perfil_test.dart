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

  Picto childPicto(String label, String categoryId, String? childId) {
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

  test('RF3.9: la cascada por chico solo borra los pictos DE ESE niño', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final category = await repository.createCategory(const Category(id: '', name: 'Verano'));
    await repository.createPicto(childPicto('pileta', category.id, 'nina'));
    await repository.createPicto(childPicto('helado-nina', category.id, 'nina'));
    // Otro chico con pictos en la MISMA categoría, y un legacy sin dueño.
    await repository.createPicto(childPicto('caramelo-benja', category.id, 'benja'));
    await repository.createPicto(childPicto('changuito-viejo', category.id, null));

    // El adulto borra el catálogo con la sesión de nina activa.
    await repository.deleteCategory(category.id, childProfileId: 'nina');

    // La categoría sale del listado...
    final categories = await repository.getCategories();
    expect(categories.any((stored) => stored.id == category.id), isFalse);
    // ...los pictos PROPIOS de nina de esa categoría se purgan...
    final ninaPictos = await repository.getPictos(childProfileId: 'nina');
    expect(ninaPictos.any((picto) => picto.label == 'pileta'), isFalse);
    expect(ninaPictos.any((picto) => picto.label == 'helado-nina'), isFalse);
    // ...y lo ajeno no se toca: el de benja y el legacy sigue visible (RF3.7).
    expect(ninaPictos.any((picto) => picto.label == 'changuito-viejo'), isTrue);
    expect((await repository.getPictos(childProfileId: 'benja')).any((picto) => picto.label == 'caramelo-benja'), isTrue);
    expect((await repository.getPictos(childProfileId: 'benja')).any((picto) => picto.label == 'changuito-viejo'), isTrue);
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

  test('RF3.8: con sesión activa no se puede borrar el picto de otro chico', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final created = await repository.createPicto(childPicto('banana-casa-nina', 'alimentos', 'nina'));

    // Sesión de benja: el picto de nina no se toca.
    await expectLater(
      repository.deletePicto(created.id, childProfileId: 'benja'),
      throwsA(isA<DataSourceException>()),
    );
    expect((await repository.getPictos(childProfileId: 'nina')), hasLength(1));

    // Sesión correcta: borra normal.
    await repository.deletePicto(created.id, childProfileId: 'nina');
    expect(await repository.getPictos(childProfileId: 'nina'), isEmpty);
  });
}
