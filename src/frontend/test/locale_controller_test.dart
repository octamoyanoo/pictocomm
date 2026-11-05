import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm/core/i18n/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RF4.4/4.5: el idioma arranca en el guardado; sin config, sistema/es.
/// RF4.2 (persistencia): elegir otro idioma lo guarda en el dispositivo.
void main() {
  group('LocaleController', () {
    test('sin idioma guardado y sin sistema soportado, cae a español', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = LocaleController(
        preferences: await SharedPreferences.getInstance(),
        systemLocale: const Locale('fr'),
      );
      expect(controller.languageCode, 'es');
    });

    test('sin idioma guardado, hereda el idioma del sistema si está soportado', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = LocaleController(
        preferences: await SharedPreferences.getInstance(),
        systemLocale: const Locale('pt', 'BR'),
      );
      expect(controller.languageCode, 'pt');
    });

    test('arranca en el idioma guardado (RF4.4)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{'pictocomm.ui_locale': 'en'});
      final controller = LocaleController(
        preferences: await SharedPreferences.getInstance(),
        systemLocale: const Locale('fr'),
      );
      expect(controller.languageCode, 'en');
    });

    test('setLanguage persiste en prefs y notifica listeners (RF4.2/4.3)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = LocaleController(preferences: prefs, systemLocale: const Locale('es'));

      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setLanguage('pt');
      controller.setLanguage('es');
      controller.setLanguage('zz'); // no soportado: ignorado
      controller.setLanguage('es'); // sin cambio: no notifica

      expect(notifications, 2);
      expect(prefs.getString('pictocomm.ui_locale'), 'es');
      expect(controller.languageCode, 'es');
    });
  });
}
