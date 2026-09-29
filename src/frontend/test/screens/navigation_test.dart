import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm_app/app.dart';
import 'package:pictocomm_app/core/error/app_exception.dart';
import 'package:pictocomm_app/features/catalog/domain/category.dart';

import '../helpers/fakes.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('muestra las categorías del repositorio', (tester) async {
      await tester.pumpWidget(PictoCommApp(dependencies: fakeDependencies()));
      await tester.pumpAndSettle();

      expect(find.text('PictoComm'), findsOneWidget);
      expect(find.text('Comida'), findsOneWidget);
    });

    testWidgets('muestra estado vacío si no hay categorías', (tester) async {
      await tester.pumpWidget(
        PictoCommApp(
          dependencies: fakeDependencies(
            local: FakeCatalogLocalDataSource(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Todavía no hay categorías'), findsOneWidget);
    });

    testWidgets('muestra error y reintenta', (tester) async {
      final fake = FakeCatalogLocalDataSource(
        categories: <Category>[testCategory],
      )..failWith = const StorageException('no se pudo leer');

      await tester.pumpWidget(
        PictoCommApp(dependencies: fakeDependencies(local: fake)),
      );
      await tester.pumpAndSettle();

      expect(find.text('no se pudo leer'), findsOneWidget);

      // El botón de reintentar debe volver a pedir los datos.
      fake.failWith = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Comida'), findsOneWidget);
    });
  });

  group('navegación', () {
    testWidgets('tocar una categoría abre su tablero', (tester) async {
      await tester.pumpWidget(PictoCommApp(dependencies: fakeDependencies()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();

      expect(find.text('manzana'), findsOneWidget);
      // El título del AppBar pasa a ser el de la categoría.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Comida'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('volver de la categoría regresa al inicio', (tester) async {
      await tester.pumpWidget(PictoCommApp(dependencies: fakeDependencies()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();

      expect(find.text('manzana'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('PictoComm'),
        ),
        findsOneWidget,
      );
    });
  });
}
