import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pictocomm/core/error/app_exception.dart';
import 'package:pictocomm/features/catalog/data/datasources/custom_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/datasources/local_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/datasources/remote_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/repositories/local_picto_repository.dart';
import 'package:pictocomm/features/catalog/domain/entities/category.dart';
import 'package:pictocomm/features/catalog/domain/entities/picto.dart';

/// REQ-CAT-02: pictos multicategoría (RF-3.13 a RF-3.15) y edición de
/// custom (RF-3.16 a RF-3.20).
///
/// Repositorio real con SharedPreferences simulado y `remote` intacto:
/// si algún camino de lectura tocara el remoto, el test rompe (local-first).
void main() {
  final repository = LocalPictoRepository(
    localDataSource: const LocalCatalogDataSource(),
    customDataSource: CustomCatalogDataSource(),
    remoteDataSource: const UnimplementedRemoteCatalogDataSource(),
  );

  Picto draftPicto(String label, List<String> categoryIds, {String? childId, String? id, String? imageUrl}) {
    final now = DateTime.now().toUtc();
    return Picto(
      id: id ?? '',
      label: label,
      categoryIds: categoryIds,
      source: PictoSource.custom,
      imageUrl: imageUrl ?? 'data:image/png;base64,iVBORw0KGgo=',
      childProfileId: childId,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('RF-3.13/CA-3.11: un picto con dos categorías aparece en ambas y una vez en el total', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final created = await repository.createPicto(draftPicto('leche', ['alimentos', 'rutina'], childId: 'nina'));

    final alimentos = await repository.getPictos(categoryId: 'alimentos');
    final rutina = await repository.getPictos(categoryId: 'rutina');
    final todos = await repository.getPictos();

    expect(alimentos.map((p) => p.id), contains(created.id));
    expect(rutina.map((p) => p.id), contains(created.id));
    expect(todos.where((p) => p.id == created.id), hasLength(1));
    expect(created.categoryIds, ['alimentos', 'rutina']);
  });

  test('RF-3.13/CA-3.13: crear sin categorías se rechaza', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await expectLater(
      repository.createPicto(draftPicto('sin categoria', [], childId: 'nina')),
      throwsA(isA<DataSourceException>()),
    );
  });

  test('RF-3.16/CA-3.14: editar el nombre actualiza el picto y avanza updatedAt', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final created = await repository.createPicto(draftPicto('agua', ['alimentos'], childId: 'nina'));
    final updated = await repository.updatePicto(
      created.copyWith(label: 'agua helada', categoryIds: ['alimentos', 'bebidas']),
      childProfileId: 'nina',
    );

    expect(updated.label, 'agua helada');
    expect(updated.id, created.id);
    expect(updated.categoryIds, ['alimentos', 'bebidas']);
    expect(updated.updatedAt.isAfter(created.updatedAt), isTrue);
    // El nombre editado se ve en la pertenencia nueva y la vieja.
    expect((await repository.getPictos(categoryId: 'bebidas')).map((p) => p.id), contains(created.id));
  });

  test('RF-3.18/CA-3.15: bundled no se edita y el picto de otro chico tampoco', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final created = await repository.createPicto(draftPicto('tren', ['juguetes'], childId: 'nina'));
    final now = DateTime.now().toUtc();

    // Un id que no existe en custom (por ejemplo, de un picto bundled).
    await expectLater(
      repository.updatePicto(
        Picto(
          id: 'assets/images/alimentos/agua.png',
          label: 'agua',
          categoryIds: ['alimentos'],
          source: PictoSource.custom,
          imageUrl: 'data:image/png;base64,iVBORw0KGgo=',
          createdAt: now,
          updatedAt: now,
        ),
        childProfileId: 'nina',
      ),
      throwsA(isA<DataSourceException>()),
    );
    await expectLater(
      repository.updatePicto(created, childProfileId: 'benja'),
      throwsA(isA<DataSourceException>()),
    );
  });

  test('RF-3.19/CA-3.16: un legacy sin dueño puede asignarse a un chico al editar', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final created = await repository.createPicto(draftPicto('viejo-sin-dueno', ['alimentos']));

    // Sin sesión (gestión): la edición asigna dueño.
    final assigned = await repository.updatePicto(created.copyWith(childProfileId: 'nina'));

    expect(assigned.childProfileId, 'nina');
    // RF-3.6: ya no es visible para otro chico.
    final nina = await repository.getPictos(childProfileId: 'nina');
    final benja = await repository.getPictos(childProfileId: 'benja');
    expect(nina.map((p) => p.id), contains(assigned.id));
    expect(benja.map((p) => p.id), isNot(contains(assigned.id)));
  });

  test('RF-3.20/CA-3.17: borrar categoría conserva los pictos con otra categoría y elimina los que quedan sin ninguna', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final verano = await repository.createCategory(const Category(id: '', name: 'Verano'));
    final invierno = await repository.createCategory(const Category(id: '', name: 'Invierno'));

    // Solo vive en Verano → lo elimina la cascada del chico activo.
    await repository.createPicto(draftPicto('pileta', [verano.id], childId: 'nina'));
    // Vive en Verano e Invierno → sobrevive sin Verano.
    final compartido = await repository.createPicto(draftPicto('abrigo', [verano.id, invierno.id], childId: 'nina'));

    await repository.deleteCategory(verano.id, childProfileId: 'nina');

    final pictos = await repository.getPictos();
    expect(pictos.any((p) => p.label == 'pileta'), isFalse, reason: 'quedó sin ninguna categoría: cascada');
    final survivor = pictos.where((p) => p.id == compartido.id).single;
    expect(survivor.categoryIds, [invierno.id], reason: 'pierde la membresía pero conserva la otra');
    // Ningún picto apunta a un id de categoría borrado.
    for (final picto in pictos) {
      expect(picto.categoryIds.contains(verano.id), isFalse);
    }
  });

  test('RF-3.20: los pictos de otro chico sobreviven huérfanos (sin categorías) tras la cascada', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final verano = await repository.createCategory(const Category(id: '', name: 'Verano2'));
    await repository.createPicto(draftPicto('de-benja', [verano.id], childId: 'benja'));

    await repository.deleteCategory(verano.id, childProfileId: 'nina');

    final pictos = await repository.getPictos();
    final orphan = pictos.where((p) => p.label == 'de-benja').single;
    expect(orphan.categoryIds, isEmpty, reason: 'sobrevive pero invisible en las grillas de categoría');
  });

  test('RF-3.17/CA-3.19: renombrar categoría conserva el id y la pertenencia', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final category = await repository.createCategory(const Category(id: '', name: 'Verano3', color: Color(0xFF4CAF50)));
    final created = await repository.createPicto(draftPicto('pelota', [category.id], childId: 'nina'));

    final renamed = await repository.updateCategory(
      Category(id: category.id, name: 'Verano en la pileta', color: const Color(0xFFE91E63), custom: true),
    );

    expect(renamed.id, category.id);
    expect(renamed.name, 'Verano en la pileta');
    final pictos = await repository.getPictos(categoryId: category.id);
    expect(pictos.map((p) => p.id), contains(created.id));
  });

  test('RF-3.17: renombrar a un nombre que colisiona con otra categoría se rechaza', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final first = await repository.createCategory(const Category(id: '', name: 'Deportes'));
    final second = await repository.createCategory(const Category(id: '', name: 'Juguetes'));

    await expectLater(
      repository.updateCategory(Category(id: second.id, name: 'Deportes', custom: true)),
      throwsA(isA<DuplicateCatalogException>()),
    );
    // Sin cambios.
    final categories = await repository.getCategories();
    expect(categories.firstWhere((c) => c.id == first.id).name, 'Deportes');
  });
}
