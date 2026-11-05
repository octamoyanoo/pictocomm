import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pictocomm/core/theme/app_theme.dart';
import 'package:pictocomm/features/catalog/data/datasources/custom_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/datasources/local_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/datasources/remote_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/repositories/local_picto_repository.dart';
import 'package:pictocomm/features/catalog/domain/entities/picto.dart';
import 'package:pictocomm/features/profiles/data/datasources/local_child_profile_data_source.dart';
import 'package:pictocomm/features/profiles/data/repositories/local_child_profile_repository.dart';
import 'package:pictocomm/features/profiles/domain/entities/child_profile.dart';

void main() {
  test('repositorio local persiste un perfil creado (SharedPreferences real con mocks)', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    const repository = LocalChildProfileRepository(dataSource: LocalChildProfileDataSource());

    final created = await repository.createChild(
      ChildProfile(
        id: '',
        name: 'Nina',
        avatarColor: AppColors.avatarPalette.first,
      ),
    );

    final children = await repository.getChildren();

    expect(created.name, 'Nina');
    expect(children, hasLength(1));
    expect(children.first.name, 'Nina');
    expect(children.first.id, isNotEmpty);
    // RF3.11: el contrato real persiste la foto del chico.
    expect(created.photoUrl, isNull);
    expect(children.first.photoUrl, isNull);
  });

  test('RF2.7: borrar un perfil purga sus pictos personalizados (cascada)', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final pictoRepository = LocalPictoRepository(
      localDataSource: const LocalCatalogDataSource(),
      customDataSource: CustomCatalogDataSource(),
      remoteDataSource: const UnimplementedRemoteCatalogDataSource(),
    );
    final repository = LocalChildProfileRepository(
      dataSource: LocalChildProfileDataSource(),
      // Mismo wiring que AppDependencies.bootstrap() (RF2.7).
      purgePictosForChild: pictoRepository.deletePictosForChild,
    );

    final nina = await repository.createChild(ChildProfile(id: '', name: 'Nina', avatarColor: AppColors.avatarPalette.first));
    await repository.createChild(ChildProfile(id: '', name: 'Benja', avatarColor: AppColors.avatarPalette[1]));

    await pictoRepository.createPicto(customPicto(label: 'banana-casa-nina', categoryId: 'alimentos', childId: nina.id));
    await pictoRepository.createPicto(customPicto(label: 'banana-casa-benja', categoryId: 'alimentos'));
    await pictoRepository.createPicto(customPicto(label: 'viejo-sin-dueno', categoryId: 'alimentos'));

    await repository.deleteChild(nina.id);

    final pictos = await pictoRepository.getPictos();
    // Cascada: los pictos del borrado (nina) quedan fuera del dispositivo.
    expect(pictos.any((picto) => picto.label == 'banana-casa-nina'), isFalse);
    // El resto no se toca: otro chico y los legacy sin dueño (RF3.7).
    expect(pictos.any((picto) => picto.label == 'banana-casa-benja'), isTrue);
    expect(pictos.any((picto) => picto.label == 'viejo-sin-dueno'), isTrue);
    // El perfil borrado sale de la lista.
    final remaining = await repository.getChildren();
    expect(remaining, hasLength(1));
    expect(remaining.single.name, 'Benja');
  });
}

/// Picto custom para tests de cascada: el id lo resuelve el repositorio.
Picto customPicto({required String label, required String categoryId, String? childId}) {
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
