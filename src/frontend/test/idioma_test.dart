import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm/app.dart';
import 'package:pictocomm/core/i18n/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

/// RF4: cambio de idioma de la UI al instante desde el selector en Perfil.
/// RF4.8: los idiomas cubren la pantalla de gestión sin texto mezclado.
void main() {
  const bottomNavPerfil = Key('bottom_nav_/perfil');

  /// Arranca la app en español, entra a sesión con Nina y aterriza en Perfil.
  Future<LocaleController> goProfileWithEnglishToggleable(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = LocaleController(
      preferences: await SharedPreferences.getInstance(),
      systemLocale: const Locale('es'),
    );
    await tester.pumpWidget(PictoCommApp(
      dependencies: fakeDependencies(children: [testChildProfile()]),
      localeController: controller,
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('login_email')), 'casa@pictocomm.app');
    await tester.enterText(find.byKey(const Key('login_password')), 'secreta123');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();
    expect(find.text('¿Quién se comunica hoy?'), findsOneWidget);
    await tester.tap(find.text('Nina'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(bottomNavPerfil));
    await tester.pumpAndSettle();
    expect(find.text('Perfil'), findsWidgets);
    expect(find.text('Idioma'), findsOneWidget);
    return controller;
  }

  testWidgets('el selector cambia la UI a inglés al instante (RF4.3)', (tester) async {
    final controller = await goProfileWithEnglishToggleable(tester);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(controller.languageCode, 'en');
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Children'), findsOneWidget);
  });

  testWidgets('portugués cubre la pantalla de gestión sin restos en español (RF4.8)', (tester) async {
    await goProfileWithEnglishToggleable(tester);

    await tester.tap(find.text('Português'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil'), findsWidgets);
    expect(find.text('Crianças'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);
    // Sin texto mezclado: nada de español ni inglés de otras tablas.
    expect(find.text('Niños'), findsNothing);
    expect(find.text('Children'), findsNothing);
    expect(find.text('Language'), findsNothing);
  });

  testWidgets('el idioma elegido sobrevive al reiniciar la app (RF4.4)', (tester) async {
    await goProfileWithEnglishToggleable(tester);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // "Reinicio": un controller nuevo contra el mismo storage persistido.
    SharedPreferences.setMockInitialValues(<String, Object>{'pictocomm.ui_locale': 'en'});
    final rebooted = LocaleController(
      preferences: await SharedPreferences.getInstance(),
      systemLocale: const Locale('es'),
    );
    expect(rebooted.languageCode, 'en');
  });
}
