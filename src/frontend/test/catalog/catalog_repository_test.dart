import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm_app/core/error/app_exception.dart';
import 'package:pictocomm_app/features/catalog/domain/category.dart';
import '../helpers/fakes.dart';

void main() {
  test('devuelve las categorías que tiene el datasource', () async {
    final fake = fakeRepositories();

    expect(await fake.catalog.getCategories(), <Category>[testCategory]);
  });

  test('getCategory devuelve null para un id desconocido', () async {
    expect(await fakeRepositories().catalog.getCategory('no-existe'), isNull);
  });

  test('propaga el error del datasource', () async {
    final fake = fakeRepositories();
    fake.data.failWith = const StorageException('disco lleno');

    await expectLater(
      fake.catalog.getCategories(),
      throwsA(isA<StorageException>()),
    );
  });
}
