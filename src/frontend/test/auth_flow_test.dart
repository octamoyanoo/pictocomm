import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm/app.dart';
import 'package:pictocomm/features/catalog/presentation/widgets/empty_catalog_view.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('login rechaza submit sin datos y no navega', (tester) async {
    await tester.pumpWidget(PictoCommApp(dependencies: fakeDependencies()));

    expect(find.text('PictoComm'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);

    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump();

    expect(find.text('Ingresá tu correo'), findsOneWidget);
    expect(find.text('PictoComm'), findsOneWidget);
  });

  testWidgets('login con datos validos navega a home con catalogo vacio', (tester) async {
    await tester.pumpWidget(PictoCommApp(dependencies: fakeDependencies()));

    await tester.enterText(find.byKey(const Key('login_email')), 'casa@pictocomm.app');
    await tester.enterText(find.byKey(const Key('login_password')), 'secreta123');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyCatalogView), findsOneWidget);
    expect(find.text('Aún no hay pictogramas'), findsOneWidget);
  });
}
