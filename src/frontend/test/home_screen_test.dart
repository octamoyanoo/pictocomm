import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm/app.dart';
import 'package:pictocomm/features/catalog/domain/entities/category.dart';
import 'package:pictocomm/features/catalog/domain/entities/picto.dart';
import 'package:pictocomm/features/catalog/presentation/widgets/empty_catalog_view.dart';

import 'helpers/fakes.dart';

Category _category(String id, String name) => Category(id: id, name: name);

Picto _picto(String id, String categoryId, String label) => Picto(
      id: id,
      label: label,
      categoryId: categoryId,
      source: PictoSource.bundled,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );

Future<void> _goToHome(WidgetTester tester, PictoCommApp app) async {
  await tester.pumpWidget(app);
  await tester.enterText(find.byKey(const Key('login_email')), 'casa@pictocomm.app');
  await tester.enterText(find.byKey(const Key('login_password')), 'secreta123');
  await tester.tap(find.text('Iniciar Sesión'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home muestra saludo, busqueda, seccion y bottom nav', (tester) async {
    await _goToHome(
      tester,
      PictoCommApp(
        dependencies: fakeDependencies(
          categories: [
            _category('alimentos', 'Alimentos'),
            _category('emociones', 'Emociones'),
            _category('juguetes', 'Juguetes'),
          ],
          pictos: [
            _picto('alimentos-1', 'alimentos', 'Manzana'),
            _picto('alimentos-2', 'alimentos', 'Banana'),
            _picto('emociones-1', 'emociones', 'Feliz'),
          ],
        ),
      ),
    );

    expect(find.text('Hola 👋'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.text('Mis Catálogos'), findsOneWidget);
    expect(find.text('Ver todos'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('home lista categorias con conteo de pictogramas', (tester) async {
    await _goToHome(
      tester,
      PictoCommApp(
        dependencies: fakeDependencies(
          categories: [
            _category('alimentos', 'Alimentos'),
            _category('emociones', 'Emociones'),
          ],
          pictos: [
            _picto('alimentos-1', 'alimentos', 'Manzana'),
            _picto('alimentos-2', 'alimentos', 'Banana'),
            _picto('emociones-1', 'emociones', 'Feliz'),
          ],
        ),
      ),
    );

    expect(find.text('Alimentos'), findsOneWidget);
    expect(find.text('2 pictogramas'), findsOneWidget);
    expect(find.text('Emociones'), findsOneWidget);
    expect(find.text('1 pictograma'), findsOneWidget);
  });

  testWidgets('home filtra categorias por busqueda y muestra vacio si no hay match', (tester) async {
    await _goToHome(
      tester,
      PictoCommApp(
        dependencies: fakeDependencies(
          categories: [_category('alimentos', 'Alimentos'), _category('emociones', 'Emociones')],
          pictos: [_picto('alimentos-1', 'alimentos', 'Manzana')],
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'ali');
    await tester.pump();

    expect(find.text('Alimentos'), findsOneWidget);
    expect(find.text('Emociones'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    expect(find.text('Sin resultados para "zzz"'), findsOneWidget);
  });

  testWidgets('home sin categorias muestra estado vacio', (tester) async {
    await _goToHome(tester, PictoCommApp(dependencies: fakeDependencies()));

    expect(find.byType(EmptyCatalogView), findsOneWidget);
    expect(find.text('Aún no hay pictogramas'), findsOneWidget);
  });
}
