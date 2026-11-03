import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm/app.dart';

import 'helpers/fakes.dart';

Future<void> _goToHome(WidgetTester tester) async {
  await tester.pumpWidget(PictoCommApp(dependencies: fakeDependencies()));
  await tester.enterText(find.byKey(const Key('login_email')), 'casa@pictocomm.app');
  await tester.enterText(find.byKey(const Key('login_password')), 'secreta123');
  await tester.tap(find.text('Iniciar Sesión'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el boton + abre el menu de creacion y un catalogo nuevo aparece en home', (tester) async {
    await _goToHome(tester);

    expect(find.text('Aún no hay pictogramas'), findsOneWidget);

    await tester.tap(find.byTooltip('Agregar catálogo o pictograma'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo catálogo'), findsOneWidget);
    expect(find.text('Nuevo pictograma'), findsOneWidget);

    await tester.tap(find.text('Nuevo catálogo'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bebidas');
    await tester.tap(find.text('Guardar catálogo'));
    await tester.pumpAndSettle();

    expect(find.text('Bebidas'), findsOneWidget);
    expect(find.text('0 pictogramas'), findsOneWidget);
  });

  testWidgets('crear la misma categoria dos veces muestra error de duplicado', (tester) async {
    await _goToHome(tester);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip('Agregar catálogo o pictograma'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nuevo catálogo'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Bebidas');
      await tester.tap(find.text('Guardar catálogo'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Ya existe una categoría con ese nombre'), findsOneWidget);
  });

  testWidgets('el menu permite elegir nuevo pictograma y avisa si no hay categorias', (tester) async {
    await _goToHome(tester);

    await tester.tap(find.byTooltip('Agregar catálogo o pictograma'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo pictograma'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo pictograma'), findsOneWidget);
    expect(find.text('Tocá para elegir una imagen'), findsOneWidget);
    expect(find.text('Primero creá un catálogo para poder guardar pictogramas'), findsOneWidget);
    expect(find.text('Guardar pictograma'), findsOneWidget);
  });
}
