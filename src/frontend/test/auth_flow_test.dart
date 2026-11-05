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

  testWidgets('login con datos validos navega al selector de chico', (tester) async {
    await tester.pumpWidget(PictoCommApp(dependencies: fakeDependencies()));

    await tester.enterText(find.byKey(const Key('login_email')), 'casa@pictocomm.app');
    await tester.enterText(find.byKey(const Key('login_password')), 'secreta123');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    // RF2: la sesión de comunicación arranca eligiendo chico, no en home.
    expect(find.text('¿Quién se comunica hoy?'), findsOneWidget);
    expect(find.text('Todavía no hay perfiles de niño'), findsOneWidget);
  });

  testWidgets('elegir perfil en selector entra a la sesion del chico', (tester) async {
    await tester.pumpWidget(
      PictoCommApp(
        dependencies: fakeDependencies(
          children: [testChildProfile()],
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('login_email')), 'casa@pictocomm.app');
    await tester.enterText(find.byKey(const Key('login_password')), 'secreta123');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nina'));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyCatalogView), findsOneWidget);
    expect(find.text('Hola, Nina 👋'), findsOneWidget);
  });

  testWidgets('signup rechaza contrasenas distintas', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(PictoCommApp(dependencies: fakeDependencies()));

    await tester.tap(find.byKey(const Key('login_register_link')));
    await tester.pumpAndSettle();

    expect(find.text('Crear Cuenta'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('signup_name')), 'Nico');
    await tester.enterText(find.byKey(const Key('signup_email')), 'casa@pictocomm.app');
    await tester.enterText(find.byKey(const Key('signup_password')), 'secreta123');
    await tester.enterText(find.byKey(const Key('signup_confirm_password')), 'otraclave99');
    await tester.tap(find.text('Crear Cuenta'));
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(find.text('Crear Cuenta'), findsOneWidget);
  });

  testWidgets('signup con datos validos navega al selector de chico', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(PictoCommApp(dependencies: fakeDependencies()));

    await tester.tap(find.byKey(const Key('login_register_link')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('signup_name')), 'Nico');
    await tester.enterText(find.byKey(const Key('signup_email')), 'casa@pictocomm.app');
    await tester.enterText(find.byKey(const Key('signup_password')), 'secreta123');
    await tester.enterText(find.byKey(const Key('signup_confirm_password')), 'secreta123');
    await tester.tap(find.text('Crear Cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('¿Quién se comunica hoy?'), findsOneWidget);
    expect(find.text('Todavía no hay perfiles de niño'), findsOneWidget);
  });
}
