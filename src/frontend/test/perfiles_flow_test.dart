import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm/app.dart';
import 'package:pictocomm/features/profiles/presentation/widgets/child_avatar.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> goToPerfil(WidgetTester tester) async {
    await tester.pumpWidget(PictoCommApp(dependencies: fakeDependencies()));
    await tester.enterText(find.byKey(const Key('login_email')), 'casa@pictocomm.app');
    await tester.enterText(find.byKey(const Key('login_password')), 'secreta123');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();
    // Selector vacío (sin perfiles) → acceso directo a crear el primer perfil.
    await tester.tap(find.text('Crear perfil'));
    await tester.pumpAndSettle();
  }

  testWidgets('crear perfil aparece en la lista de niños', (tester) async {
    await goToPerfil(tester);

    expect(find.text('No hay niños cargados todavía'), findsOneWidget);

    await tester.tap(find.byTooltip('Agregar niño'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Nina');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.text('Nina'), findsOneWidget);
    expect(find.byType(ChildAvatar), findsOneWidget);
  });

  testWidgets('borrar perfil exige doble confirmación', (tester) async {
    await goToPerfil(tester);

    await tester.tap(find.byTooltip('Agregar niño'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nina');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eliminar perfil'));
    await tester.pumpAndSettle();

    // Paso 1: advertencia con consecuencias.
    expect(find.text('¿Eliminar a Nina?'), findsOneWidget);
    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();

    // Paso 2: confirmación final irreversible.
    expect(find.text('¿Confirmar el borrado?'), findsOneWidget);
    await tester.tap(find.text('Conservar'));
    await tester.pumpAndSettle();

    // Cancelar en el paso 2 conserva el perfil.
    expect(find.text('Nina'), findsOneWidget);

    await tester.tap(find.byTooltip('Eliminar perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar definitivamente'));
    await tester.pumpAndSettle();

    expect(find.text('Nina'), findsNothing);
    expect(find.text('No hay niños cargados todavía'), findsOneWidget);
  });
}
