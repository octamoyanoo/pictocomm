import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm_app/core/error/app_exception.dart';
import 'package:pictocomm_app/features/catalog/domain/picto.dart';
import 'package:pictocomm_app/features/catalog/domain/picto_repository.dart';
import 'package:pictocomm_app/features/catalog/domain/picto_source.dart';

import '../helpers/fakes.dart';

void main() {
  const Picto custom = Picto(
    id: 'custom-1',
    label: 'mi primo',
    categoryId: 'comida',
    imagePath: '/tmp/primo.jpg',
    source: PictoSource.custom,
  );

  late PictoRepository repo;

  setUp(() {
    repo = fakeRepositories(pictos: <Picto>[custom]).picto;
  });

  test('filtra por origen', () async {
    final List<Picto> all = await repo.getPictos(categoryId: 'comida');
    final List<Picto> onlyCustom = await repo.getPictos(
      categoryId: 'comida',
      source: PictoSource.custom,
    );

    expect(all, <Picto>[custom]);
    expect(onlyCustom, <Picto>[custom]);
  });

  test('excluye cuando el origen no coincide', () async {
    expect(
      await repo.getPictos(categoryId: 'comida', source: PictoSource.bundled),
      isEmpty,
    );
  });

  test('toggleFavorite alterna el estado', () async {
    expect(await repo.toggleFavorite(custom.id), isTrue);
    expect(await repo.toggleFavorite(custom.id), isFalse);
  });

  test('filtra por favorito', () async {
    expect(
      await repo.getPictos(categoryId: 'comida', favoritesOnly: true),
      isEmpty,
    );

    await repo.toggleFavorite(custom.id);

    final List<Picto> favorites =
        await repo.getPictos(categoryId: 'comida', favoritesOnly: true);

    expect(favorites.map((Picto p) => p.id), <String>[custom.id]);
    expect(favorites.single.isFavorite, isTrue);
  });

  test('toggleFavorite sobre un picto ausente devuelve false', () async {
    expect(await repo.toggleFavorite('no-existe'), isFalse);
  });

  test('rechaza guardar un picto empaquetado', () async {
    await expectLater(
      repo.savePicto(
        const Picto(
          id: 'p9',
          label: 'x',
          categoryId: 'comida',
          imagePath: 'x.png',
          source: PictoSource.bundled,
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('elimina un picto propio', () async {
    await repo.deletePicto(custom.id);

    expect(
      await repo.getPictos(categoryId: 'comida'),
      isNot(contains(custom)),
    );
  });

  test('eliminar algo inexistente lanza NotFoundException', () async {
    await expectLater(
      repo.deletePicto('no-existe'),
      throwsA(isA<NotFoundException>()),
    );
  });
}
